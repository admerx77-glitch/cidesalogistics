from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .db import init_db, run_migrations
from .routers import clientes

app = FastAPI(title="CIDESA LOGISTICS")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"]
)

@app.on_event("startup")
def on_startup():
    init_db()
    run_migrations()

@app.get("/health")
def health():
    return {"status": "ok"}

app.include_router(clientes.router)
