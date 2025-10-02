# scripts\run_backend.ps1
param([int]$Port = 8000)
$ErrorActionPreference = 'Stop'
Set-Location 'C:\CIDESA_MVP\backend_stdlib'
try { Stop-Transcript | Out-Null } catch {}
Start-Transcript -Path 'C:\CIDESA_MVP\logs\backend.log' -Append | Out-Null
Write-Host "Log: C:\CIDESA_MVP\logs\backend.log"
& py 'C:\CIDESA_MVP\backend_stdlib\backend_simple.py' --port $Port
