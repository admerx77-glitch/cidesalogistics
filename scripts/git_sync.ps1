param(
  [string]$Message = "chore: sync $(Get-Date -Format yyyy-MM-dd HH:mm)"
)
$ErrorActionPreference = "Stop"
function OK($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function ERR($m){ Write-Host "[ ERROR ] $m" -ForegroundColor Red }
function STEP($m){ Write-Host "`n=== $m ===" -ForegroundColor Cyan }

Set-Location "C:\CIDESA_MVP"
$branch = (git rev-parse --abbrev-ref HEAD).Trim()
STEP "Rama actual: $branch"

git status --porcelain | Out-Null
git add -A
$st = git status --porcelain
if ([string]::IsNullOrWhiteSpace($st)) {
  OK "No hay cambios para commitear"
} else {
  git commit -m $Message | Out-Null
  OK "Commit creado: $Message"
}

git push -u origin $branch
if ($LASTEXITCODE -ne 0) { ERR "Fallo push a origin/$branch"; exit 1 }
OK "Push a origin/$branch completado"

Write-Host ""
OK "INFORME FINAL:"
Write-Host " - Rama: $branch"
Write-Host " - Mensaje: $Message"
