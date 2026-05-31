# detect-proxy.ps1 - Windows proxy detection for GFW bypass
# Usage:
#   powershell -File detect-proxy.ps1              # Text output
#   powershell -File detect-proxy.ps1 --test       # Test proxy port reachability
#   powershell -File detect-proxy.ps1 --json       # JSON output
#   powershell -File detect-proxy.ps1 --enable     # Set env vars for current process

param(
    [switch]$Test,
    [switch]$Json,
    [switch]$Enable
)

# Read Windows registry
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
$proxyEnabled = $false
$proxyServer = ""
$proxyPort = 0
$source = "none"

try {
    $proxyEnable = (Get-ItemProperty -Path $regPath -Name ProxyEnable -ErrorAction SilentlyContinue).ProxyEnable
    $proxyServerReg = (Get-ItemProperty -Path $regPath -Name ProxyServer -ErrorAction SilentlyContinue).ProxyServer

    if ($proxyEnable -and $proxyEnable -ne 0 -and $proxyServerReg) {
        $proxyEnabled = $true
        $proxyServer = $proxyServerReg
        $source = "registry"
    }
    elseif ($proxyServerReg) {
        # Proxy configured but disabled
        $proxyServer = $proxyServerReg
        $source = "registry_disabled"
    }
}
catch {
    # Cannot read registry
}

# Check environment variables
$envProxy = if ($env:HTTP_PROXY) { $env:HTTP_PROXY } elseif ($env:HTTPS_PROXY) { $env:HTTPS_PROXY } elseif ($env:http_proxy) { $env:http_proxy } elseif ($env:https_proxy) { $env:https_proxy } elseif ($env:ALL_PROXY) { $env:ALL_PROXY } elseif ($env:all_proxy) { $env:all_proxy } else { $null }
if ($envProxy -and $source -eq "none") {
    $proxyEnabled = $true
    $proxyServer = $envProxy -replace '^https?://', ''
    $source = "environment"
}

# Parse host:port from proxyServer
if ($proxyServer -match '([^:]+):(\d+)') {
    $proxyHost = $Matches[1]
    $proxyPort = [int]$Matches[2]
}
elseif ($proxyServer) {
    $proxyHost = $proxyServer
    $proxyPort = 11721  # Default Clash port
}
else {
    $proxyHost = "127.0.0.1"
    $proxyPort = 11721  # Default fallback
}

# Read config.env as fallback
if ($source -eq "none" -or $source -eq "registry_disabled") {
    $configPath = Join-Path $PSScriptRoot "..\config.env"
    if (Test-Path $configPath) {
        $configContent = Get-Content $configPath -ErrorAction SilentlyContinue
        $configProxyHost = ($configContent | Where-Object { $_ -match '^PROXY_HOST=' }) -replace '^PROXY_HOST=', ''
        $configProxyPort = ($configContent | Where-Object { $_ -match '^PROXY_PORT=' }) -replace '^PROXY_PORT=', ''
        if ($configProxyHost -and $configProxyPort) {
            $proxyHost = $configProxyHost
            $proxyPort = [int]$configProxyPort
            if ($source -eq "none") { $source = "config" }
        }
    }
}

# Test proxy reachability
$portReachable = $false
if ($Test) {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $result = $tcp.BeginConnect($proxyHost, $proxyPort, $null, $null)
        $wait = $result.AsyncWaitHandle.WaitOne(2000, $false)
        if ($wait -and $tcp.Connected) {
            $portReachable = $true
        }
        $tcp.Close()
    }
    catch {
        $portReachable = $false
    }
}

$proxyUrl = "http://${proxyHost}:${proxyPort}"

# Enable proxy for current process
if ($Enable) {
    $env:HTTP_PROXY = $proxyUrl
    $env:HTTPS_PROXY = $proxyUrl
    $env:ALL_PROXY = $proxyUrl
    Write-Host "[detect-proxy] Proxy enabled: $proxyUrl" -ForegroundColor Green
}

# Output
$result = @{
    proxy_enabled   = $proxyEnabled
    proxy_server    = $proxyServer
    proxy_host      = $proxyHost
    proxy_port      = $proxyPort
    proxy_url       = $proxyUrl
    port_reachable  = $portReachable
    source          = $source
}

if ($Json) {
    $result | ConvertTo-Json -Compress
}
else {
    Write-Host "=== Proxy Detection ==="
    Write-Host "Source:        $source"
    Write-Host "Enabled:       $proxyEnabled"
    Write-Host "Server:        $proxyServer"
    Write-Host "Proxy URL:     $proxyUrl"
    if ($Test) {
        Write-Host "Port Reachable: $portReachable" -ForegroundColor $(if ($portReachable) { 'Green' } else { 'Red' })
    }
}
