# scripts/db_dump_schema.ps1 — Dump del esquema con pg_dump
param(
  [string]\ciad99_db_prod = 'ciad99_db_prod',
  [string]\System.Management.Automation.Internal.Host.InternalHost = 'localhost',
  [string]\ = '5432',
  [string]\ = 'postgres'
)
if (-not (Get-Command pg_dump -ErrorAction SilentlyContinue)) {
  Write-Host '[ WARN ] pg_dump no encontrado en PATH' -ForegroundColor Yellow
  exit 0
}
if (-not \) {
  Write-Host '[ WARN ] PGPASSWORD no definido' -ForegroundColor Yellow
  exit 0
}
\ = 'C:\CIDESA_MVP\database\schema\' + \ciad99_db_prod + '.schema.sql'
pg_dump -s -h \System.Management.Automation.Internal.Host.InternalHost -p \ -U \ -d \ciad99_db_prod > \
if (Test-Path \) { Write-Host "[ OK ] Dump de esquema en: \" -ForegroundColor Green } else { Write-Host "[ ERROR ] No se generó el dump" -ForegroundColor Red }
