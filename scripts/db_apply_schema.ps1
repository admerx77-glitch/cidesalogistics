# scripts/db_apply_schema.ps1 — Aplica schema al DB con psql
param(
  [string]\ciad99_db_prod = 'ciad99_db_prod',
  [string]\System.Management.Automation.Internal.Host.InternalHost = 'localhost',
  [string]\ = '5432',
  [string]\ = 'postgres'
)
if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
  Write-Host '[ ERROR ] psql no encontrado en PATH' -ForegroundColor Red
  exit 1
}
if (-not \) {
  Write-Host '[ ERROR ] Variable de entorno PGPASSWORD no definida' -ForegroundColor Red
  exit 1
}
\ = 'C:\CIDESA_MVP\database\schema\' + \ciad99_db_prod + '.schema.sql'
if (-not (Test-Path \)) {
  Write-Host "[ ERROR ] No existe el archivo de esquema: \" -ForegroundColor Red
  exit 1
}
psql "host=\System.Management.Automation.Internal.Host.InternalHost port=\ user=\ dbname=\ciad99_db_prod" -f \
if (\ -eq 0) {
  Write-Host '[ OK ] Esquema aplicado correctamente' -ForegroundColor Green
} else {
  Write-Host '[ ERROR ] Falló la aplicación del esquema' -ForegroundColor Red
}
