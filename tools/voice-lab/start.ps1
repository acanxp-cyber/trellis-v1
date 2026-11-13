$ErrorActionPreference = "Stop"
$lab = Split-Path -Parent $MyInvocation.MyCommand.Path
$python = Join-Path $lab ".venv\Scripts\python.exe"
$url = "http://127.0.0.1:8765"

function Show-Error($message) {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show(
        $message,
        "SOMETHING Voice Lab",
        "OK",
        "Error"
    ) | Out-Null
}

if (-not (Test-Path $python)) {
    Show-Error "Voice Lab is not installed. Run setup.ps1 first."
    exit 1
}

$healthy = $false
try {
    $health = Invoke-RestMethod -Uri "$url/health" -TimeoutSec 2
    $healthy = $health.ok -eq $true
} catch {
    $healthy = $false
}

if (-not $healthy) {
    Start-Process `
        -FilePath $python `
        -ArgumentList (Join-Path $lab "server.py") `
        -WorkingDirectory $lab `
        -WindowStyle Hidden

    for ($attempt = 0; $attempt -lt 60; $attempt++) {
        Start-Sleep -Milliseconds 500
        try {
            $health = Invoke-RestMethod -Uri "$url/health" -TimeoutSec 2
            if ($health.ok -eq $true) {
                $healthy = $true
                break
            }
        } catch {
        }
    }
}

if (-not $healthy) {
    Show-Error "Voice Lab failed to start. Check tools\voice-lab\server.py."
    exit 1
}

Start-Process $url
