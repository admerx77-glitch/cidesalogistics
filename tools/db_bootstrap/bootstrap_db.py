import os, sys, argparse
from pathlib import Path

def die(code, msg):
    sys.stderr.write(msg + "\n")
    sys.exit(code)

# Elegir driver
driver = None; pg3 = None; pg2 = None
try:
    import psycopg as pg3  # v3
    driver = 'pg3'
except Exception:
    try:
        import psycopg2 as pg2  # v2
        driver = 'pg2'
    except Exception:
        die(1, "[PY ERROR] No hay driver disponible (psycopg ni psycopg2).")

def connect(dbname, host, port, user, pwd):
    if driver == 'pg3':
        return pg3.connect(host=host, port=port, user=user, password=pwd, dbname=dbname, autocommit=True)
    else:
        conn = pg2.connect(host=host, port=port, user=user, password=pwd, dbname=dbname)
        conn.autocommit = True
        return conn

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", required=True)
    ap.add_argument("--port", required=True)
    ap.add_argument("--user", required=True)
    ap.add_argument("--dbname", required=True)
    ap.add_argument("--schema", required=True)
    args = ap.parse_args()

    pwd = os.environ.get("PGPASSWORD", "")

    # 1) Probar servidor y crear DB si no existe
    try:
        with connect("postgres", args.host, args.port, args.user, pwd) as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1 FROM pg_database WHERE datname=%s;", (args.dbname,))
                row = cur.fetchone()
                if not row:
                    cur.execute('CREATE DATABASE "{}"'.format(args.dbname.replace('"','""')))
                    print("[PY OK] BD creada:", args.dbname, flush=True)
                else:
                    print("[PY OK] BD existe:", args.dbname, flush=True)
    except Exception as e:
        die(2, "[PY ERROR] Conexión/creación de BD falló: " + str(e))

    # 2) Leer y aplicar esquema
    try:
        schema = Path(args.schema).read_text(encoding="utf-8")
    except Exception as e:
        die(3, "[PY ERROR] No pude leer el esquema: " + str(e))

    try:
        with connect(args.dbname, args.host, args.port, args.user, pwd) as conn:
            with conn.cursor() as cur:
                cur.execute(schema)
        print("[PY OK] Esquema aplicado sobre", args.dbname, flush=True)
    except Exception as e:
        die(4, "[PY ERROR] Falló aplicar el esquema: " + str(e))

if __name__ == "__main__":
    main()
