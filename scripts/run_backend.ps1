# scripts/run_backend.ps1 — Arrancar backend (requiere uvicorn instalado)
param([int]\ = 8000)
Set-Location 'C:\CIDESA_MVP\backend'
if (Test-Path .venv\Scripts\Activate.ps1) { . .\.venv\Scripts\Activate.ps1 }
uvicorn app.main:app --reload --port \
