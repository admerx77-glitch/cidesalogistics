# CIAD99 (CIDESA APP) — Baseline

Infraestructura lista para desarrollar por módulos.

## Servicios
- **Backend** FastAPI — http://127.0.0.1:8000
- **Frontend** estático — http://127.0.0.1:5173
- **PostgreSQL** DB: ciad99_db_prod

## Estructura
- backend/app/ (FastAPI: main.py, db.py, deps.py, routers/)
- frontend_pro/ (index.html, main.js)
- database/ (schema, functions, triggers, data)
- docs/ (arquitectura, roadmap)
- modules/ (etapas)
- scripts/ (helpers PS)
- tools/
- uploads/ (fuera de Git)

## Flujo expediente
nuevo → en_proceso → liberado → facturacion_cidesa → cerrado

## Numeración
- Clientes: desde 100
- Expedientes: {ADUANA}-{#####}-{AÑO} (##### desde 00100 por aduana/año)
