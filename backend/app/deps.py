# backend/app/deps.py — Dependencias FastAPI
from .db import SessionLocal
from sqlalchemy.orm import Session
from fastapi import Depends

def get_session():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
