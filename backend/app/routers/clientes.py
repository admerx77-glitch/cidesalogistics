from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field, EmailStr
from pydantic import ConfigDict
from typing import Optional, List
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from ..db import get_session
from ..models import Cliente, Contacto

router = APIRouter(prefix="/clientes", tags=["Clientes"])

class ContactoIn(BaseModel):
    nombre: str = Field(..., min_length=2, max_length=120)
    email: Optional[EmailStr] = None
    telefono: Optional[str] = None
    area: Optional[str] = None

class ContactoOut(ContactoIn):
    contacto_id: int
    model_config = ConfigDict(from_attributes=True)

class ClienteIn(BaseModel):
    razon_social: str = Field(..., min_length=2, max_length=255)
    rfc: str = Field(..., min_length=12, max_length=13)
    telefono: Optional[str] = None
    email: Optional[EmailStr] = None
    email_principal: Optional[EmailStr] = None
    observaciones: Optional[str] = None
    contactos: List[ContactoIn] = Field(default_factory=list)

class ClienteOut(BaseModel):
    cliente_id: int
    razon_social: str
    rfc: str
    telefono: Optional[str]
    email: Optional[str]
    email_principal: Optional[str]
    observaciones: Optional[str]
    activo: bool
    created_at: Optional[str]
    contactos: List[ContactoOut] = Field(default_factory=list)
    model_config = ConfigDict(from_attributes=True)

def _serialize(c: Cliente) -> ClienteOut:
    return ClienteOut(
        cliente_id=c.cliente_id, razon_social=c.razon_social, rfc=c.rfc,
        telefono=c.telefono, email=c.email, email_principal=c.email_principal,
        observaciones=c.observaciones, activo=bool(c.activo),
        created_at=c.created_at.isoformat() if c.created_at else None,
        contactos=[ContactoOut.model_validate(x) for x in c.contactos]
    )

@router.post("/", response_model=ClienteOut)
def crear_cliente(data: ClienteIn, db: Session = Depends(get_session)):
    if len(data.rfc.strip()) not in (12,13):
        raise HTTPException(status_code=400, detail="RFC inválido (12 o 13)")
    cli = Cliente(
        rfc=data.rfc.strip().upper(),
        razon_social=data.razon_social.strip(),
        telefono=data.telefono or None,
        email=data.email or None,
        email_principal=data.email_principal or None,
        observaciones=data.observaciones or None,
        activo=True
    )
    for c in data.contactos:
        cli.contactos.append(Contacto(
            nombre=c.nombre.strip(), email=c.email, telefono=c.telefono, area=c.area
        ))
    db.add(cli)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="RFC duplicado")
    db.refresh(cli)
    return _serialize(cli)

@router.get("/", response_model=List[ClienteOut])
def listar_clientes(db: Session = Depends(get_session)):
    rows = db.query(Cliente).order_by(Cliente.cliente_id.desc()).all()
    return [_serialize(x) for x in rows]

@router.put("/{cliente_id}", response_model=ClienteOut)
def actualizar_cliente(cliente_id: int, data: ClienteIn, db: Session = Depends(get_session)):
    cli = db.get(Cliente, cliente_id)
    if not cli:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    if len(data.rfc.strip()) not in (12,13):
        raise HTTPException(status_code=400, detail="RFC inválido (12 o 13)")

    cli.rfc = data.rfc.strip().upper()
    cli.razon_social = data.razon_social.strip()
    cli.telefono = data.telefono or None
    cli.email = data.email or None
    cli.email_principal = data.email_principal or None
    cli.observaciones = data.observaciones or None

    cli.contactos.clear()
    for c in data.contactos:
        cli.contactos.append(Contacto(
            nombre=c.nombre.strip(), email=c.email, telefono=c.telefono, area=c.area
        ))
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="RFC duplicado")
    db.refresh(cli)
    return _serialize(cli)
