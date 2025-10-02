# backend/app/db.py — Conexión SQLAlchemy (placeholder)
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Usa .env o variables de entorno en deps.py
DATABASE_URL = 'postgresql://postgres:postgres@localhost:5432/ciad99_db_prod'

engine = create_engine(DATABASE_URL, pool_pre_ping=True, future=True)
SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False, future=True)
