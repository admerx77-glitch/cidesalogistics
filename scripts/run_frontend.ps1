# scripts\run_frontend.ps1 (auto)
$ErrorActionPreference = 'Stop'
Set-Location 'C:\CIDESA_MVP\frontend_pro'
try { Stop-Transcript | Out-Null } catch {}
Start-Transcript -Path 'C:\CIDESA_MVP\logs\frontend.log' -Append | Out-Null
if (Get-Command python -ErrorAction SilentlyContinue) {
  python -m http.server 5173
} elseif (Get-Command py -ErrorAction SilentlyContinue) {
  py -m http.server 5173
} else {
  Start-Process (Resolve-Path '.\index.html').Path
  Start-Sleep -Seconds 3600
}
