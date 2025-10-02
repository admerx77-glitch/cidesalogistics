$ErrorActionPreference = "Stop"
function OK($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function ERR($m){ Write-Host "[ ERROR ] $m" -ForegroundColor Red }
function STEP($m){ Write-Host "`n=== $m ===" -ForegroundColor Cyan }

Set-Location "C:\CIDESA_MVP"
$branch = (git rev-parse --abbrev-ref HEAD).Trim()
STEP "Actualizando rama local con rebase desde origin/$branch"

git fetch origin | Out-Null
git pull --rebase origin $branch
if ($LASTEXITCODE -ne 0) { ERR "Rebase con conflictos. Resuelve y vuelve a correr."; exit 1 }

OK "Rebase exitoso con origin/$branch"
