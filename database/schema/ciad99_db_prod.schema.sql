-- CIADESA / Módulo 1 — Clientes
CREATE TABLE IF NOT EXISTS public.ciad99_clientes (
  cliente_id      SERIAL PRIMARY KEY,
  rfc             VARCHAR(13) NOT NULL,
  razon_social    VARCHAR(255) NOT NULL,
  email           VARCHAR(255),
  email_principal VARCHAR(255),
  telefono        VARCHAR(50),
  activo          BOOLEAN NOT NULL DEFAULT TRUE,
  observaciones   TEXT,
  created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_ciad99_clientes_rfc ON public.ciad99_clientes (rfc);

CREATE TABLE IF NOT EXISTS public.ciad99_clientes_contactos (
  contacto_id SERIAL PRIMARY KEY,
  cliente_id  INT NOT NULL REFERENCES public.ciad99_clientes(cliente_id) ON DELETE CASCADE,
  nombre      VARCHAR(120) NOT NULL,
  email       VARCHAR(255),
  telefono    VARCHAR(50)
);
