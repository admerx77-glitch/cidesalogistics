Write-Host "=============================" -ForegroundColor Cyan
Write-Host "   Lanzando CIDESA Backend y Frontend" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# Activa el entorno virtual
$env:VIRTUAL_ENV = "$PSScriptRoot\venv"
$env:PATH = "$env:VIRTUAL_ENV\Scripts;" + $env:PATH

# 1) Levantar Backend (FastAPI en :8000)
Start-Process powershell -ArgumentList "-NoExit", "-Command",
"cd $PSScriptRoot\backend; python -m uvicorn app.main:app --app-dir backend --reload --port 8000"

# 2) Levantar Frontend (servidor estático en :5173)
Start-Process powershell -ArgumentList "-NoExit", "-Command",
"cd $PSScriptRoot\frontend_pro; python -m http.server 5173"

# 3) Esperar unos segundos y abrir navegador automáticamente
Start-Sleep -Seconds 5
Start-Process "http://127.0.0.1:8000/docs"
Start-Process "http://127.0.0.1:5173"

Write-Host "✅ Backend y Frontend arrancados. Revisa navegador y ventanas azules." -ForegroundColor Green
