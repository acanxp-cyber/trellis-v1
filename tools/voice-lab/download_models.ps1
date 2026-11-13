$ErrorActionPreference = "Stop"
$lab = Split-Path -Parent $MyInvocation.MyCommand.Path
$modelDir = Join-Path $lab "models\Kokoro-82M"
$voiceDir = Join-Path $modelDir "voices"
$repoUrl = "https://huggingface.co/hexgrad/Kokoro-82M/resolve/main"

function Resolve-HuggingFaceIp {
    $uri = "https://cloudflare-dns.com/dns-query?name=huggingface.co&type=A"
    $response = Invoke-RestMethod `
        -Uri $uri `
        -Headers @{ Accept = "application/dns-json" } `
        -TimeoutSec 15
    $addresses = @(
        $response.Answer |
            Where-Object { $_.type -eq 1 } |
            ForEach-Object { $_.data }
    )
    foreach ($address in $addresses) {
        $client = [System.Net.Sockets.TcpClient]::new()
        try {
            $task = $client.ConnectAsync($address, 443)
            if ($task.Wait(3000) -and $client.Connected) {
                return $address
            }
        } catch {
        } finally {
            $client.Dispose()
        }
    }
    throw "No reachable Hugging Face address was found."
}

function Get-ModelFile {
    param(
        [string]$Ip,
        [string]$RelativePath
    )

    $target = Join-Path $modelDir $RelativePath
    $parent = Split-Path -Parent $target
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $partial = "$target.part"

    if ((Test-Path $target) -and ((Get-Item $target).Length -gt 0)) {
        Write-Host "Already present: $RelativePath"
        return
    }

    $arguments = @(
        "--resolve", "huggingface.co:443:$Ip",
        "--fail",
        "--location",
        "--retry", "4",
        "--retry-delay", "2",
        "--output", $partial
    )
    if ((Test-Path $partial) -and ((Get-Item $partial).Length -gt 0)) {
        $arguments += @("--continue-at", "-")
    }
    $arguments += "$repoUrl/$RelativePath"

    Write-Host "Downloading $RelativePath"
    & curl.exe @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Download failed: $RelativePath"
    }
    Move-Item -LiteralPath $partial -Destination $target -Force
}

$ip = Resolve-HuggingFaceIp
Write-Host "Using Hugging Face address $ip"
New-Item -ItemType Directory -Force -Path $voiceDir | Out-Null

Get-ModelFile -Ip $ip -RelativePath "config.json"
Get-ModelFile -Ip $ip -RelativePath "kokoro-v1_0.pth"
foreach ($voice in @("zf_xiaobei", "zf_xiaoni", "zf_xiaoxiao", "zf_xiaoyi", "zm_yunxi")) {
    Get-ModelFile -Ip $ip -RelativePath "voices/$voice.pt"
}

Write-Host "Kokoro models are ready."
