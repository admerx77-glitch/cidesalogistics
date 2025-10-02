# backend/app/routers/clientes.py — Placeholder CRUD mínimo
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from ..deps import get_session

router = APIRouter(prefix='/clientes', tags=['Clientes'])

class ClienteIn(BaseModel):
    rfc: str = Field(..., min_length=12, max_length=13)
    razon_social: str = Field(..., min_length=2, max_length=255)
    email: str | None = None
    email_principal: str | None = None
    telefono: str | None = None
    activo: bool = True

@router.post('/')
def crear_cliente(data: ClienteIn, db: Session = Depends(get_session)):
    # Placeholder: solo eco de validación
    if len(data.rfc) not in (12,13):
        raise HTTPException(status_code=400, detail='RFC inválido')
    return {'mensaje':'OK (placeholder)', 'recibido': data.model_dump()}
