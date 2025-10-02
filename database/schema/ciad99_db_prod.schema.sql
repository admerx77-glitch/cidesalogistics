-- database/schema/ciad99_db_prod.schema.sql — Esquema inicial (plantilla)

-- CLIENTES
CREATE TABLE IF NOT EXISTS public.ciad99_clientes (
  cliente_id     SERIAL PRIMARY KEY,
  rfc            VARCHAR(13) NOT NULL,
  razon_social   VARCHAR(255) NOT NULL,
  email          VARCHAR(255),
  email_principal VARCHAR(255),
  telefono       VARCHAR(50),
  activo         BOOLEAN NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_ciad99_clientes_rfc ON public.ciad99_clientes (rfc);

-- EXPEDIENTES (simple placeholder, se ampliará en módulo 03)
CREATE TABLE IF NOT EXISTS public.ciad99_expedientes (
  expediente_id  SERIAL PRIMARY KEY,
  referencia     VARCHAR(32) NOT NULL,
  estado         VARCHAR(32) NOT NULL DEFAULT 'nuevo',
  cliente_id     INT REFERENCES public.ciad99_clientes(cliente_id),
  created_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Vistas/demos
CREATE OR REPLACE VIEW public.vw_clientes_activos AS
SELECT * FROM public.ciad99_clientes WHERE activo IS TRUE;
