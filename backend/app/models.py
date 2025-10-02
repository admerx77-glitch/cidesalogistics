from sqlalchemy import Column, Integer, String, Boolean, Text, DateTime, func, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from .db import Base

class Cliente(Base):
    __tablename__ = "ciad99_clientes"
    cliente_id      = Column(Integer, primary_key=True, index=True)
    rfc             = Column(String(13), nullable=False, unique=True, index=True)
    razon_social    = Column(String(255), nullable=False)
    email           = Column(String(255))
    email_principal = Column(String(255))
    telefono        = Column(String(50))
    activo          = Column(Boolean, nullable=False, default=True)
    observaciones   = Column(Text)
    created_at      = Column(DateTime, nullable=False, server_default=func.now())
    contactos = relationship("Contacto", back_populates="cliente",
                             cascade="all, delete-orphan", passive_deletes=True)

class Contacto(Base):
    __tablename__ = "ciad99_clientes_contactos"
    contacto_id = Column(Integer, primary_key=True, index=True)
    cliente_id  = Column(Integer, ForeignKey("ciad99_clientes.cliente_id", ondelete="CASCADE"), nullable=False)
    nombre      = Column(String(120), nullable=False)
    email       = Column(String(255))
    telefono    = Column(String(50))
    area        = Column(String(120))

    cliente = relationship("Cliente", back_populates="contactos")

__table_args__ = (UniqueConstraint(Cliente.rfc, name="ux_ciad99_clientes_rfc"),)
