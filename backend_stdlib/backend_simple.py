import base64, json, re, sqlite3, sys, os
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, unquote

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATA_DIR = os.path.join(ROOT, "data"); os.makedirs(DATA_DIR, exist_ok=True)
UPLOADS_DIR = os.path.join(ROOT, "uploads"); os.makedirs(UPLOADS_DIR, exist_ok=True)
DB_PATH = os.path.join(DATA_DIR, "cidesa.db")

def dict_factory(cursor, row):
    return {col[0]: row[idx] for idx, col in enumerate(cursor.description)}

def db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = dict_factory
    conn.execute("PRAGMA foreign_keys = ON")
    return conn

def init_db():
    conn = db(); c = conn.cursor()
    c.execute("""
        CREATE TABLE IF NOT EXISTS ciad99_clientes (
            cliente_id      INTEGER PRIMARY KEY AUTOINCREMENT,
            rfc             TEXT NOT NULL UNIQUE,
            razon_social    TEXT NOT NULL,
            email           TEXT,
            email_principal TEXT,
            telefono        TEXT,
            activo          INTEGER NOT NULL DEFAULT 1,
            observaciones   TEXT,
            created_at      TEXT DEFAULT (datetime('now'))
        )
    """)
    c.execute("""
        CREATE TABLE IF NOT EXISTS ciad99_clientes_contactos (
            contacto_id INTEGER PRIMARY KEY AUTOINCREMENT,
            cliente_id  INTEGER NOT NULL,
            nombre      TEXT NOT NULL,
            email       TEXT,
            telefono    TEXT,
            area        TEXT,
            FOREIGN KEY (cliente_id) REFERENCES ciad99_clientes(cliente_id) ON DELETE CASCADE
        )
    """)
    c.execute("""
        CREATE TABLE IF NOT EXISTS ciad99_clientes_files (
            file_id    INTEGER PRIMARY KEY AUTOINCREMENT,
            cliente_id INTEGER NOT NULL,
            filename   TEXT NOT NULL,
            mime       TEXT DEFAULT 'application/pdf',
            size       INTEGER,
            created_at TEXT DEFAULT (datetime('now')),
            FOREIGN KEY (cliente_id) REFERENCES ciad99_clientes(cliente_id) ON DELETE CASCADE
        )
    """)
    try:
        cols = [r["name"] for r in c.execute("PRAGMA table_info(ciad99_clientes_contactos)")]
        if "area" not in cols:
            c.execute("ALTER TABLE ciad99_clientes_contactos ADD COLUMN area TEXT")
    except Exception:
        pass
    conn.commit(); conn.close()

def validar_rfc(rfc):
    return bool(rfc) and len(rfc.strip().upper()) in (12,13)

def safe_pdf_name(name):
    import re, os
    name = os.path.basename(name or "archivo.pdf").strip()
    name = re.sub(r"[^A-Za-z0-9._-]", "_", name)
    if not name.lower().endswith(".pdf"):
        name += ".pdf"
    return name

def cliente_to_dict(conn, row):
    cur = conn.cursor()
    contactos = list(cur.execute(
        "SELECT contacto_id, nombre, email, telefono, area FROM ciad99_clientes_contactos WHERE cliente_id=? ORDER BY contacto_id ASC",
        (row["cliente_id"],)
    ))
    files = list(cur.execute(
        "SELECT file_id, filename, mime, size, created_at FROM ciad99_clientes_files WHERE cliente_id=? ORDER BY file_id DESC",
        (row["cliente_id"],)
    ))
    return {
        "cliente_id": row["cliente_id"],
        "rfc": row["rfc"],
        "razon_social": row["razon_social"],
        "email": row.get("email"),
        "email_principal": row.get("email_principal"),
        "telefono": row.get("telefono"),
        "activo": bool(row.get("activo",1)),
        "observaciones": row.get("observaciones"),
        "created_at": row.get("created_at"),
        "contactos": contactos,
        "pdfs": [{"filename": f["filename"], "size": f.get("size",0)} for f in files],
    }

class Handler(BaseHTTPRequestHandler):
    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, OPTIONS")

    def do_OPTIONS(self):
        self.send_response(204); self._cors(); self.end_headers()

    def _send_json(self, obj, status=200):
        data = json.dumps(obj).encode("utf-8")
        self.send_response(status); self._cors()
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers(); self.wfile.write(data)

    def _read_json(self):
        length = int(self.headers.get("Content-Length", "0") or "0")
        body = self.rfile.read(length) if length>0 else b"{}"
        try: return json.loads(body.decode("utf-8"))
        except Exception: return {}

    # ---------- GET ----------
    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/health":
            return self._send_json({"status":"ok"}, 200)

        if parsed.path in ("/clientes/","/clientes"):
            conn = db()
            rows = list(conn.execute("SELECT * FROM ciad99_clientes ORDER BY cliente_id DESC"))
            out = [cliente_to_dict(conn, r) for r in rows]
            conn.close(); return self._send_json(out, 200)

        m = re.match(r"^/clientes/files/(\d+)$", parsed.path)
        if m:
            cid = int(m.group(1))
            conn = db()
            files = list(conn.execute(
                "SELECT filename, size, created_at FROM ciad99_clientes_files WHERE cliente_id=? ORDER BY file_id DESC", (cid,)
            ))
            conn.close(); return self._send_json(files, 200)

        m = re.match(r"^/clientes/files/(\d+)/(.*)$", parsed.path)
        if m:
            cid = int(m.group(1)); fname = safe_pdf_name(unquote(m.group(2)))
            folder = os.path.join(UPLOADS_DIR, f"cliente_{cid}")
            fpath = os.path.join(folder, fname)
            if not os.path.isfile(fpath):
                return self._send_json({"detail":"Archivo no encontrado"}, 404)
            try:
                with open(fpath, "rb") as f: data = f.read()
                self.send_response(200); self._cors()
                self.send_header("Content-Type","application/pdf")
                self.send_header("Content-Length", str(len(data)))
                self.send_header("Content-Disposition", f'inline; filename="{fname}"')
                self.end_headers(); self.wfile.write(data); return
            except Exception as e:
                return self._send_json({"detail":f"Error leyendo archivo: {e}"}, 500)

        return self._send_json({"detail":"Not found"}, 404)

    # ---------- POST ----------
    def do_POST(self):
        parsed = urlparse(self.path)
        if parsed.path in ("/clientes/","/clientes"):
            p = self._read_json()
            rfc = (p.get("rfc") or "").strip().upper()
            if not validar_rfc(rfc): return self._send_json({"detail":"RFC invalido (12 o 13)"}, 400)
            razon_social = (p.get("razon_social") or "").strip()
            if not razon_social: return self._send_json({"detail":"razon_social requerido"}, 400)

            conn = db(); cur = conn.cursor()
            dup = cur.execute("SELECT 1 FROM ciad99_clientes WHERE UPPER(rfc)=?", (rfc,)).fetchone()
            if dup: conn.close(); return self._send_json({"detail":"RFC duplicado"}, 409)

            cur.execute("""
                INSERT INTO ciad99_clientes (rfc, razon_social, email, email_principal, telefono, activo, observaciones)
                VALUES (?,?,?,?,?,1,?)
            """, (rfc, razon_social, p.get("email"), p.get("email_principal"), p.get("telefono"), p.get("observaciones")))
            cid = cur.lastrowid

            for c in (p.get("contactos") or []):
                nombre = (c.get("nombre") or "").strip()
                if not nombre: continue
                cur.execute("""INSERT INTO ciad99_clientes_contactos (cliente_id, nombre, email, telefono, area)
                               VALUES (?,?,?,?,?)""",
                            (cid, c.get("nombre"), c.get("email"), c.get("telefono"), c.get("area")))

            for a in (p.get("anexos") or []):
                try:
                    fname = safe_pdf_name(a.get("filename") or "archivo.pdf")
                    import base64
                    raw = base64.b64decode(a.get("content") or "", validate=True)
                    folder = os.path.join(UPLOADS_DIR, f"cliente_{cid}"); os.makedirs(folder, exist_ok=True)
                    dest = os.path.join(folder, fname)
                    with open(dest, "wb") as f: f.write(raw)
                    cur.execute("""INSERT INTO ciad99_clientes_files (cliente_id, filename, mime, size)
                                   VALUES (?,?,?,?)""", (cid, fname, "application/pdf", len(raw)))
                except Exception:
                    pass

            conn.commit()
            cli = cur.execute("SELECT * FROM ciad99_clientes WHERE cliente_id=?", (cid,)).fetchone()
            out = cliente_to_dict(conn, cli); conn.close()
            return self._send_json(out, 200)

        return self._send_json({"detail":"Not found"}, 404)

    # ---------- PUT ----------
    def do_PUT(self):
        m = re.match(r"^/clientes/(\d+)$", self.path)
        if not m: return self._send_json({"detail":"Not found"}, 404)
        cid = int(m.group(1))
        p = self._read_json()
        rfc = (p.get("rfc") or "").strip().upper()
        if not validar_rfc(rfc): return self._send_json({"detail":"RFC invalido (12 o 13)"}, 400)
        razon_social = (p.get("razon_social") or "").strip()
        if not razon_social: return self._send_json({"detail":"razon_social requerido"}, 400)

        conn = db(); cur = conn.cursor()
        cli = cur.execute("SELECT * FROM ciad99_clientes WHERE cliente_id=?", (cid,)).fetchone()
        if not cli: conn.close(); return self._send_json({"detail":"Cliente no encontrado"}, 404)

        dup = cur.execute("SELECT 1 FROM ciad99_clientes WHERE UPPER(rfc)=? AND cliente_id<>?", (rfc, cid)).fetchone()
        if dup: conn.close(); return self._send_json({"detail":"RFC duplicado"}, 409)

        cur.execute("""UPDATE ciad99_clientes
                       SET rfc=?, razon_social=?, email=?, email_principal=?, telefono=?, observaciones=?
                       WHERE cliente_id=?""",
                    (rfc, razon_social, p.get("email"), p.get("email_principal"), p.get("telefono"), p.get("observaciones"), cid))

        cur.execute("DELETE FROM ciad99_clientes_contactos WHERE cliente_id=?", (cid,))
        for c in (p.get("contactos") or []):
            nombre = (c.get("nombre") or "").strip()
            if not nombre: continue
            cur.execute("""INSERT INTO ciad99_clientes_contactos (cliente_id, nombre, email, telefono, area)
                           VALUES (?,?,?,?,?)""", (cid, c.get("nombre"), c.get("email"), c.get("telefono"), c.get("area")))

        for a in (p.get("anexos") or []):
            try:
                fname = safe_pdf_name(a.get("filename") or "archivo.pdf")
                import base64
                raw = base64.b64decode(a.get("content") or "", validate=True)
                folder = os.path.join(UPLOADS_DIR, f"cliente_{cid}"); os.makedirs(folder, exist_ok=True)
                dest = os.path.join(folder, fname)
                with open(dest, "wb") as f: f.write(raw)
                cur.execute("""INSERT INTO ciad99_clientes_files (cliente_id, filename, mime, size)
                               VALUES (?,?,?,?)""", (cid, fname, "application/pdf", len(raw)))
            except Exception:
                pass

        conn.commit()
        cli = cur.execute("SELECT * FROM ciad99_clientes WHERE cliente_id=?", (cid,)).fetchone()
        out = cliente_to_dict(conn, cli); conn.close()
        return self._send_json(out, 200)

def run(port):
    init_db()
    httpd = HTTPServer(("127.0.0.1", port), Handler)
    print("[BACKEND STD] http://127.0.0.1:%d" % port, flush=True)
    httpd.serve_forever()

if __name__ == "__main__":
    port = 8000
    if len(sys.argv) >= 3 and sys.argv[1] == "--port":
        try: port = int(sys.argv[2])
        except: pass
    run(port)
