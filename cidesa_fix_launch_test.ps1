# cidesa_fix_launch_test.ps1
# ==========================================================
# CIDESA · FIX DATABASE_URL + LAUNCH + TEST END-TO-END
# ==========================================================

$ErrorActionPreference = "Stop"
Clear-Host

[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$env:PYTHONIOENCODING = "UTF-8"

function Banner($text, $color="Cyan") {
  Write-Host ""
  Write-Host "==========================================================" -ForegroundColor $color
  Write-Host ("  {0}" -f $text) -ForegroundColor $color
  Write-Host "==========================================================" -ForegroundColor $color
  Write-Host ""
}
function Ok($msg){ Write-Host ("[ OK ] {0}" -f $msg) -ForegroundColor Green }
function Warn($msg){ Write-Host ("[ WARN ] {0}" -f $msg) -ForegroundColor Yellow }
function Fail($msg){ Write-Host ("[ ERROR ] {0}" -f $msg) -ForegroundColor Red }

# ---- CONFIG ----
$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$venv = Join-Path $root "venv"
$py   = Join-Path $venv "Scripts\python.exe"
$API_BASE = "http://127.0.0.1:8000"

# Credenciales Postgres (password CORRECTO aquí)
$PG_USER = "postgres"
$PG_PASS = "cidesa77"
$PG_HOST = "localhost"
$PG_PORT = 5432
$PG_DB   = "ciad99_db_prod"

$env:DATABASE_URL = "postgresql+psycopg2://$($PG_USER):$($PG_PASS)@$($PG_HOST):$($PG_PORT)/$($PG_DB)"
Banner "PASO 0: DATABASE_URL configurada"
Write-Host "DATABASE_URL= " -NoNewline; Write-Host $env:DATABASE_URL -ForegroundColor Yellow

# ---------- PASO 1: Python / venv ----------
Banner "PASO 1: Verificando Python y creando entorno"
$pySystem = Get-Command python -ErrorAction SilentlyContinue
if (-not $pySystem) { Fail "Python no está en PATH. Instálalo y vuelve a correr."; Read-Host "ENTER para salir"; exit }
if (-not (Test-Path $venv)) {
  Ok "Creando venv en $venv"
  python -m venv $venv
} else { Ok "venv encontrado." }
& "$venv\Scripts\Activate.ps1"
python -m pip install --upgrade pip wheel setuptools

# ---------- PASO 2: Dependencias ----------
Banner "PASO 2: Instalando dependencias (incluye psycopg2-binary)"
$packages = @(
  "fastapi",
  "uvicorn[standard]",
  "sqlalchemy>=2.0",
  "psycopg2-binary",
  "pydantic>=2.0",
  "email-validator",
  "python-multipart"
)
foreach ($p in $packages) {
  Write-Host ">> instalando $p" -ForegroundColor Yellow
  python -m pip install $p
}
@($packages) -join "`r`n" | Set-Content "$root\requirements.txt" -Encoding UTF8
Ok "Dependencias instaladas."

# ---------- PASO 3: psycopg2 + conexión BD ----------
Banner "PASO 3: Verificando psycopg2 y conexión a PostgreSQL"
try {
  & $py -c "import psycopg2; print('psycopg2 OK')"
  Ok "psycopg2 importado correctamente."
} catch { Fail "No se pudo importar psycopg2."; Fail $_.Exception.Message; Read-Host "ENTER para salir"; exit }

$testPy = @"
import os, sys
from sqlalchemy import create_engine, text
url = os.environ.get('DATABASE_URL')
try:
    eng = create_engine(url, future=True)
    with eng.begin() as conn:
        conn.execute(text('SELECT 1'))
    print('DB_OK')
except Exception as e:
    print('DB_FAIL:', e)
    sys.exit(2)
"@
$tmp = New-TemporaryFile
$testPy | Set-Content $tmp -Encoding UTF8
try {
  $out = & $py $tmp
  if ($out -notmatch "DB_OK") { throw $out }
  Ok "Conexión a PostgreSQL exitosa."
} catch {
  Fail "Fallo conectando a la BD usando:`n$($env:DATABASE_URL)"
  Fail $_
  Read-Host "ENTER para salir"; exit
} finally { Remove-Item $tmp -ErrorAction SilentlyContinue }

# ---------- PASO 4: Levantar servicios ----------
Banner "PASO 4: Lanzando Backend y Frontend"
$backendCmd = "cd `"$root\backend`"; $py -m uvicorn app.main:app --reload --port 8000"
Start-Process powershell -ArgumentList "-NoExit","-Command",$backendCmd | Out-Null
$frontendCmd = "cd `"$root\frontend_pro`"; $py -m http.server 5173"
Start-Process powershell -ArgumentList "-NoExit","-Command",$frontendCmd | Out-Null

Start-Sleep -Seconds 2
Start-Process "$API_BASE/docs"
Start-Process "http://127.0.0.1:5173"

# ---------- PASO 5: Esperar API ----------
Banner "PASO 5: Esperando API listo"
$maxTries = 20; $ready = $false
for ($i=1; $i -le $maxTries; $i++) {
  try {
    $h = Invoke-RestMethod -Uri "$API_BASE/" -TimeoutSec 2
    if ($h.status -eq "ok") { $ready = $true; break }
  } catch { Start-Sleep -Milliseconds 500 }
}
if (-not $ready) { Fail "El API no respondió. Revisa la ventana del backend."; Read-Host "ENTER para salir"; exit }
Ok "API listo."

# ---------- PASO 6: Insertar y validar ----------
Banner "PASO 6: Insertando y validando cliente de prueba"
# RFC válido de 13 caracteres: base 10 + 3 dígitos
$baseRFC = "XAXX010101"
$suf     = (Get-Random -Minimum 100 -Maximum 999)
$TEST_RFC  = "$baseRFC$suf"

$payload = @{
  rfc=$TEST_RFC
  razon_social="PRUEBA CIDESA $suf SA DE CV"
  email=("prueba{0}@example.com" -f $suf)
  telefono=("777000{0}" -f $suf)
  activo=$true
} | ConvertTo-Json

try {
  $ins = Invoke-RestMethod -Method POST -Uri "$API_BASE/api/clientes" -ContentType "application/json" -Body $payload -ErrorAction Stop
  if (-not $ins.cliente_id) { throw "Sin cliente_id en respuesta." }
  Ok "Insertado cliente_id=$($ins.cliente_id) RFC=$TEST_RFC"
} catch {
  Fail "Fallo insertando cliente."
  # Si es 422 u otro error HTTP, intentamos leer el cuerpo de respuesta
  $errBody = ""
  if ($_.Exception.Response) {
    try {
      $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
      $errBody = $reader.ReadToEnd()
    } catch {}
  }
  if ($errBody) {
    Write-Host ">> Respuesta del servidor:" -ForegroundColor Yellow
    Write-Host $errBody
  }
  Write-Host ">> Payload enviado:" -ForegroundColor Yellow
  Write-Host $payload
  Read-Host "ENTER para salir"; exit
}

try {
  $found = Invoke-RestMethod -Method GET -Uri "$API_BASE/api/clientes?q=$([uri]::EscapeDataString($TEST_RFC))"
  $match = $found | Where-Object { $_.rfc -eq $TEST_RFC }
  if ($null -eq $match) { throw "No se encontró el RFC insertado." }
  Ok "Validación OK. El cliente aparece (id=$($match.cliente_id))."
} catch {
  Fail "Fallo validando cliente."
  Fail $_.Exception.Message
  Read-Host "ENTER para salir"; exit
}

# ---------- FIN ----------
Banner "✅ TODO LISTO"
Ok "Backend corriendo y BD guardando registros."
Write-Host "RFC de prueba: $TEST_RFC" -ForegroundColor Green
Write-Host "DATABASE_URL: $env:DATABASE_URL" -ForegroundColor Yellow
Read-Host ">>> ENTER para finalizar <<<"
