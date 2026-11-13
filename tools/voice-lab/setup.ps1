$ErrorActionPreference = "Stop"
$lab = Split-Path -Parent $MyInvocation.MyCommand.Path
$venv = Join-Path $lab ".venv"

if (-not (Test-Path (Join-Path $venv "Scripts\python.exe"))) {
    py -3.10 -m venv $venv
}

$python = Join-Path $venv "Scripts\python.exe"
& $python -m pip install --upgrade pip
& $python -m pip install -r (Join-Path $lab "requirements.txt")
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $lab "download_models.ps1")

Write-Host ""
Write-Host "Voice Lab setup complete."
Write-Host "Run start.ps1 or the desktop VBS launcher."
