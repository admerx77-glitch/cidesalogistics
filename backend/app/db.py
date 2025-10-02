# backend/app/db.py — SQLAlchemy ORM (SQLite por defecto)
import os
from pathlib import Path
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, declarative_base
try:
    from dotenv import load_dotenv
except Exception:
    load_dotenv = None

Base = declarative_base()

def _load_env():
    base = Path(__file__).resolve().parents[2]
    env = base / ".env"
    if load_dotenv and env.exists():
        load_dotenv(env)

def _default_sqlite_url():
    base = Path(__file__).resolve().parents[2]
    data = base / "data"
    data.mkdir(parents=True, exist_ok=True)
    return "sqlite:///" + str((data / "cidesa.db")).replace("\\","/")

def get_database_url():
    _load_env()
    return os.getenv("DATABASE_URL") or _default_sqlite_url()

DATABASE_URL = get_database_url()

def _mk_engine(url: str):
    kw = dict(future=True)
    if url.startswith("sqlite"):
        kw["connect_args"] = {"check_same_thread": False}
    return create_engine(url, echo=False, **kw)

engine = _mk_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False, future=True)

def init_db():
    from . import models
    Base.metadata.create_all(bind=engine)

def run_migrations():
    # Asegurar columna 'area' en contactos
    with engine.begin() as conn:
        try:
            if engine.dialect.name == "sqlite":
                cols = [r[1] for r in conn.execute(text("PRAGMA table_info(ciad99_clientes_contactos)"))]
                if "area" not in cols:
                    conn.execute(text("ALTER TABLE ciad99_clientes_contactos ADD COLUMN area VARCHAR(120)"))
            else:
                conn.execute(text("ALTER TABLE IF EXISTS ciad99_clientes_contactos ADD COLUMN IF NOT EXISTS area VARCHAR(120)"))
        except Exception:
            pass

def get_session():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
