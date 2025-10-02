# patch_clientes.ps1
# Ejecutar en la raíz del proyecto: C:\CIDESA_MVP

Write-Host "=== Generando archivos para módulo CLIENTES ===" -ForegroundColor Cyan

# Crear carpetas si no existen
$paths = @(
    "backend\app",
    "backend\app\routers",
    "frontend_pro"
)
foreach ($p in $paths) {
    if (-not (Test-Path $p)) {
        New-Item -ItemType Directory -Path $p | Out-Null
        Write-Host "Carpeta creada: $p" -ForegroundColor Yellow
    }
}

# ---- backend/app/db.py ----
@"
import os
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+psycopg2://postgres:postgres@localhost:5432/ciad99_db_prod"
)

engine = create_engine(DATABASE_URL, future=True)
SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False, future=True)

def init_db():
    ddl = """
    CREATE TABLE IF NOT EXISTS ciad99_clientes (
        cliente_id SERIAL PRIMARY KEY,
        rfc VARCHAR(13) NOT NULL,
        razon_social VARCHAR(255) NOT NULL,
        email VARCHAR(255),
        telefono VARCHAR(50),
        activo BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW()
    );
    """
    with engine.begin() as conn:
        conn.execute(text(ddl))
"@ | Set-Content backend/app/db.py -Encoding UTF8

# ---- backend/app/deps.py ----
@"
from .db import SessionLocal
from sqlalchemy.orm import Session

def get_session():
    db: Session = SessionLocal()
    try:
        yield db
    finally:
        db.close()
"@ | Set-Content backend/app/deps.py -Encoding UTF8

# ---- backend/app/routers/clientes.py ----
@"
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field, EmailStr
from sqlalchemy import text
from sqlalchemy.orm import Session
from typing import Optional, List
from ..deps import get_session

router = APIRouter(prefix="/api/clientes", tags=["clientes"])

class ClienteIn(BaseModel):
    rfc: str = Field(..., min_length=10, max_length=13)
    razon_social: str = Field(..., min_length=2, max_length=255)
    email: Optional[EmailStr] = None
    telefono: Optional[str] = None
    activo: Optional[bool] = True

class ClienteOut(BaseModel):
    cliente_id: int
    rfc: Optional[str]
    razon_social: Optional[str]
    email: Optional[str]
    telefono: Optional[str]
    activo: Optional[bool]

@router.get("", response_model=List[ClienteOut])
def listar_clientes(
    q: Optional[str] = Query(None, description="RFC o Razón Social"),
    db: Session = Depends(get_session)
):
    if q:
        qry = text("""
            SELECT cliente_id, rfc, razon_social, email, telefono, activo
            FROM ciad99_clientes
            WHERE rfc ILIKE :q OR razon_social ILIKE :q
            ORDER BY cliente_id DESC
        """)
        rows = db.execute(qry, {"q": f"%{q}%"}).mappings().all()
    else:
        qry = text("""
            SELECT cliente_id, rfc, razon_social, email, telefono, activo
            FROM ciad99_clientes
            ORDER BY cliente_id DESC
        """)
        rows = db.execute(qry).mappings().all()
    return [ClienteOut(**row) for row in rows]

@router.post("", response_model=ClienteOut)
def crear_cliente(data: ClienteIn, db: Session = Depends(get_session)):
    ins = text("""
        INSERT INTO ciad99_clientes (rfc, razon_social, email, telefono, activo)
        VALUES (:rfc, :razon_social, :email, :telefono, :activo)
        RETURNING cliente_id, rfc, razon_social, email, telefono, activo
    """)
    row = db.execute(ins, data.model_dump()).mappings().first()
    db.commit()
    return ClienteOut(**row)

@router.delete("/{cliente_id}")
def borrar_cliente(cliente_id: int, db: Session = Depends(get_session)):
    delqry = text("DELETE FROM ciad99_clientes WHERE cliente_id = :id")
    res = db.execute(delqry, {"id": cliente_id})
    if res.rowcount == 0:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    db.commit()
    return {"ok": True}
"@ | Set-Content backend/app/routers/clientes.py -Encoding UTF8

# ---- backend/app/main.py ----
@"
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .db import init_db
from .routers import clientes

app = FastAPI(title="CIDESA MVP")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://127.0.0.1:5173", "http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def on_startup():
    init_db()

app.include_router(clientes.router)

@app.get("/")
def root():
    return {"status": "ok"}
"@ | Set-Content backend/app/main.py -Encoding UTF8

# ---- frontend_pro/index.html ----
@"
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <title>CIDESA · Módulo Clientes</title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-dark text-light">
  <div class="container py-4">
    <h2 class="mb-4">CIDESA · Módulo Clientes</h2>
    <div class="row g-4">
      <div class="col-md-4">
        <div class="card bg-secondary-subtle">
          <div class="card-body">
            <h5 class="card-title">Alta de Cliente</h5>
            <form id="form-cliente">
              <div class="mb-2">
                <label class="form-label">RFC</label>
                <input id="rfc" class="form-control" required minlength="10" maxlength="13" />
              </div>
              <div class="mb-2">
                <label class="form-label">Razón Social</label>
                <input id="razon_social" class="form-control" required />
              </div>
              <div class="mb-2">
                <label class="form-label">Email</label>
                <input id="email" type="email" class="form-control" />
              </div>
              <div class="mb-3">
                <label class="form-label">Teléfono</label>
                <input id="telefono" class="form-control" />
              </div>
              <div class="form-check form-switch mb-3">
                <input id="activo" class="form-check-input" type="checkbox" checked>
                <label class="form-check-label" for="activo">Activo</label>
              </div>
              <button class="btn btn-primary w-100" type="submit">Guardar</button>
              <div id="msg" class="mt-2 small"></div>
            </form>
          </div>
        </div>
      </div>
      <div class="col-md-8">
        <div class="card bg-secondary-subtle">
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-center mb-3">
              <h5 class="card-title mb-0">Clientes</h5>
              <div class="input-group" style="max-width: 320px;">
                <input id="q" class="form-control" placeholder="RFC o Razón Social">
                <button id="btn-buscar" class="btn btn-outline-primary">Buscar</button>
              </div>
            </div>
            <div class="table-responsive">
              <table class="table table-dark table-striped align-middle">
                <thead>
                  <tr>
                    <th>ID</th><th>RFC</th><th>Razón Social</th>
                    <th>Email</th><th>Teléfono</th><th>Estado</th><th></th>
                  </tr>
                </thead>
                <tbody id="clientes-tbody"></tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <script>
    window.API_BASE = "http://127.0.0.1:8000";
  </script>
  <script src="./main.js"></script>
</body>
</html>
"@ | Set-Content frontend_pro/index.html -Encoding UTF8

# ---- frontend_pro/main.js ----
@"
const API = window.API_BASE || "http://127.0.0.1:8000";

const $form = document.getElementById("form-cliente");
const $msg = document.getElementById("msg");
const $tbody = document.getElementById("clientes-tbody");
const $q = document.getElementById("q");
const $btnBuscar = document.getElementById("btn-buscar");

async function listarClientes(q = "") {
  try {
    const url = q ? `${API}/api/clientes?q=${encodeURIComponent(q)}` : `${API}/api/clientes`;
    const res = await fetch(url);
    const data = await res.json();
    renderTabla(data);
  } catch (e) {
    console.error(e);
    $tbody.innerHTML = `<tr><td colspan="7" class="text-danger">Error al cargar clientes</td></tr>`;
  }
}

function renderTabla(list) {
  if (!Array.isArray(list) || list.length === 0) {
    $tbody.innerHTML = `<tr><td colspan="7" class="text-secondary">Sin registros</td></tr>`;
    return;
  }
  $tbody.innerHTML = list.map(c => `
    <tr>
      <td>${c.cliente_id}</td>
      <td>${c.rfc ?? ""}</td>
      <td>${c.razon_social ?? ""}</td>
      <td>${c.email ?? ""}</td>
      <td>${c.telefono ?? ""}</td>
      <td>${c.activo ? "Activo" : "Inactivo"}</td>
      <td class="text-end">
        <button class="btn btn-sm btn-outline-danger" data-del="${c.cliente_id}">Borrar</button>
      </td>
    </tr>
  `).join("");
}

$form.addEventListener("submit", async (ev) => {
  ev.preventDefault();
  $msg.textContent = "Guardando...";
  const payload = {
    rfc: document.getElementById("rfc").value.trim(),
    razon_social: document.getElementById("razon_social").value.trim(),
    email: document.getElementById("email").value.trim() || null,
    telefono: document.getElementById("telefono").value.trim() || null,
    activo: document.getElementById("activo").checked
  };
  try {
    const res = await fetch(`${API}/api/clientes`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.detail || "Error al guardar");
    }
    await res.json();
    $msg.innerHTML = `<span class="text-success">Guardado ✅</span>`;
    $form.reset();
    document.getElementById("activo").checked = true;
    await listarClientes($q.value.trim());
  } catch (e) {
    console.error(e);
    $msg.innerHTML = `<span class="text-danger">${e.message}</span>`;
  } finally {
    setTimeout(() => ($msg.textContent = ""), 2000);
  }
});

$btnBuscar.addEventListener("click", () => listarClientes($q.value.trim()));
$q.addEventListener("keydown", (e) => {
  if (e.key === "Enter") {
    e.preventDefault();
    listarClientes($q.value.trim());
  }
});

$tbody.addEventListener("click", async (e) => {
  const id = e.target?.dataset?.del;
  if (!id) return;
  if (!confirm("¿Borrar este cliente?")) return;
  try {
    const res = await fetch(`${API}/api/clientes/${id}`, { method: "DELETE" });
    if (!res.ok) throw new Error("No se pudo borrar");
    await listarClientes($q.value.trim());
  } catch (err) {
    alert(err.message);
  }
});

listarClientes();
"@ | Set-Content frontend_pro/main.js -Encoding UTF8

Write-Host "✅ Archivos generados correctamente." -ForegroundColor Green
