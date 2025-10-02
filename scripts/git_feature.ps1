param([Parameter(Mandatory=$true)][string]$Name)
$ErrorActionPreference = "Stop"
function OK($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function ERR($m){ Write-Host "[ ERROR ] $m" -ForegroundColor Red }
function STEP($m){ Write-Host "`n=== $m ===" -ForegroundColor Cyan }

if ([string]::IsNullOrWhiteSpace($Name)) { ERR "Debes pasar un nombre de feature"; exit 1 }
$slug = ($Name -replace '\s+','-').ToLower()
$branch = "feat/$slug"

Set-Location "C:\CIDESA_MVP"
STEP "Creando rama $branch"
git checkout -b $branch
if ($LASTEXITCODE -ne 0) { ERR "No pude crear la rama $branch"; exit 1 }

git push -u origin $branch
if ($LASTEXITCODE -ne 0) { ERR "No pude publicar origin/$branch"; exit 1 }

OK "Rama creada y publicada: $branch"
