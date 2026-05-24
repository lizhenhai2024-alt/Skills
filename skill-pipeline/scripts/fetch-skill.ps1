# fetch-skill.ps1 - Fetch a skill from source with retry and proxy support
# Usage:
#   GitHub:  powershell -File fetch-skill.ps1 -Source "https://github.com/user/skill" -Destination "C:\staging\skill"
#   Local:   powershell -File fetch-skill.ps1 -Source "F:\PIMS\Skills\my-skill" -Destination "C:\staging\my-skill"
#   URL:     powershell -File fetch-skill.ps1 -Source "https://example.com/skill.zip" -Destination "C:\staging\skill"

param(
    [Parameter(Mandatory=$true)]
    [string]$Source,

    [Parameter(Mandatory=$true)]
    [string]$Destination,

    [string]$Proxy = "",

    [string]$Mirror = "",

    [int]$MaxRetries = 3,

    [int]$Timeout = 120
)

# Load config.env
$configPath = Join-Path $PSScriptRoot "..\config.env"
$defaultProxyHost = "127.0.0.1"
$defaultProxyPort = "11721"
$githubMirrors = @("https://ghproxy.com", "https://gitclone.com")
$npmMirror = "https://registry.npmmirror.com"

if (Test-Path $configPath) {
    $config = Get-Content $configPath -ErrorAction SilentlyContinue
    $cfgHost = ($config | Where-Object { $_ -match '^PROXY_HOST=' }) -replace '^PROXY_HOST=', ''
    $cfgPort = ($config | Where-Object { $_ -match '^PROXY_PORT=' }) -replace '^PROXY_PORT=', ''
    $cfgMirrors = ($config | Where-Object { $_ -match '^GITHUB_MIRRORS=' }) -replace '^GITHUB_MIRRORS=', ''
    $cfgRetries = ($config | Where-Object { $_ -match '^MAX_RETRIES=' }) -replace '^MAX_RETRIES=', ''
    if ($cfgHost) { $defaultProxyHost = $cfgHost }
    if ($cfgPort) { $defaultProxyPort = $cfgPort }
    if ($cfgMirrors) { $githubMirrors = $cfgMirrors -split ',' }
    if ($cfgRetries) { $MaxRetries = [int]$cfgRetries }
}

if (-not $Proxy) {
    $Proxy = "http://${defaultProxyHost}:${defaultProxyPort}"
}

# Detect source type
function Get-SourceType {
    param([string]$Src)
    if ($Src -match '^https?://github\.com/') { return "github" }
    if ($Src -match '^https?://' -and $Src -match '\.(zip|skill|tar\.gz)$') { return "archive" }
    if ($Src -match '^https?://') { return "url" }
    if (Test-Path $Src -ErrorAction SilentlyContinue) { return "local" }
    return "unknown"
}

$sourceType = Get-SourceType $Source
Write-Host "[fetch-skill] Source: $Source (type: $sourceType)"

# Create destination parent
$destParent = Split-Path $Destination -Parent
if (-not (Test-Path $destParent)) {
    New-Item -ItemType Directory -Path $destParent -Force | Out-Null
}

function Invoke-WithRetry {
    param(
        [scriptblock]$Action,
        [string]$Description,
        [int]$Retries = $MaxRetries
    )

    for ($i = 1; $i -le $Retries; $i++) {
        Write-Host "[fetch-skill] $Description (attempt $i/$Retries)"
        try {
            & $Action
            if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
                Write-Host "[fetch-skill] Success" -ForegroundColor Green
                return $true
            }
        }
        catch {
            Write-Host "[fetch-skill] Error: $($_.Exception.Message)" -ForegroundColor Yellow
        }

        if ($i -lt $Retries) {
            $delay = 2 * [Math]::Pow(2, $i - 1)
            Write-Host "[fetch-skill] Retrying in ${delay}s..." -ForegroundColor Cyan
            Start-Sleep -Seconds $delay
        }
    }
    return $false
}

switch ($sourceType) {
    "github" {
        # Strategy: direct -> with proxy -> with mirror

        # Attempt 1: Direct clone
        $success = Invoke-WithRetry -Description "git clone (direct)" -Action {
            git clone --depth 1 $Source $Destination 2>&1 | Write-Host
        }

        # Attempt 2: With proxy
        if (-not $success) {
            Write-Host "[fetch-skill] Trying with proxy: $Proxy" -ForegroundColor Cyan
            $success = Invoke-WithRetry -Description "git clone (proxy)" -Action {
                $env:HTTP_PROXY = $Proxy
                $env:HTTPS_PROXY = $Proxy
                git -c http.proxy=$Proxy -c https.proxy=$Proxy clone --depth 1 $Source $Destination 2>&1 | Write-Host
            }
        }

        # Attempt 3: GitHub mirrors
        if (-not $success) {
            foreach ($mirror in $githubMirrors) {
                $mirrorUrl = "$mirror/$Source"
                Write-Host "[fetch-skill] Trying mirror: $mirror" -ForegroundColor Cyan
                $success = Invoke-WithRetry -Description "git clone (mirror: $mirror)" -Retries 2 -Action {
                    git clone --depth 1 $mirrorUrl $Destination 2>&1 | Write-Host
                }
                if ($success) { break }
            }
        }

        if (-not $success) {
            Write-Host "[fetch-skill] FAILED: Could not fetch from GitHub after all attempts" -ForegroundColor Red
            exit 1
        }

        # Get commit hash for metadata
        Push-Location $Destination
        $commitHash = git rev-parse HEAD 2>$null
        Pop-Location
        if ($commitHash) {
            Write-Host "[fetch-skill] Commit: $commitHash"
        }
    }

    "local" {
        Write-Host "[fetch-skill] Copying from local: $Source"
        try {
            # Use Robocopy for reliability with Chinese paths
            robocopy $Source $Destination /E /COPY:DAT /R:1 /W:1 /NFL /NDL /NP /XD .git | Out-Null
            # Robocopy exit codes 0-7 are success
            if ($LASTEXITCODE -le 7) {
                Write-Host "[fetch-skill] Local copy succeeded" -ForegroundColor Green
            } else {
                Write-Host "[fetch-skill] Local copy failed (exit: $LASTEXITCODE)" -ForegroundColor Red
                exit 1
            }
        }
        catch {
            Write-Host "[fetch-skill] Local copy error: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    }

    "archive" {
        $tempFile = Join-Path $env:TEMP "skill-pipeline-$(Get-Random).zip"

        # Attempt 1: Direct download
        $success = Invoke-WithRetry -Description "Download archive (direct)" -Action {
            Invoke-WebRequest -Uri $Source -OutFile $tempFile -TimeoutSec $Timeout -UseBasicParsing
        }

        # Attempt 2: With proxy
        if (-not $success) {
            $success = Invoke-WithRetry -Description "Download archive (proxy)" -Action {
                Invoke-WebRequest -Uri $Source -OutFile $tempFile -TimeoutSec $Timeout -Proxy $Proxy -UseBasicParsing
            }
        }

        if ($success) {
            Expand-Archive -Path $tempFile -DestinationPath $Destination -Force
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            Write-Host "[fetch-skill] Archive extracted to $Destination" -ForegroundColor Green
        }
        else {
            Write-Host "[fetch-skill] FAILED: Could not download archive" -ForegroundColor Red
            exit 1
        }
    }

    default {
        Write-Host "[fetch-skill] FAILED: Unknown source type for '$Source'" -ForegroundColor Red
        exit 1
    }
}

# Verify SKILL.md exists in destination
$skillMd = Join-Path $Destination "SKILL.md"
if (Test-Path $skillMd) {
    Write-Host "[fetch-skill] SKILL.md found in destination" -ForegroundColor Green
    exit 0
}
else {
    # Check subdirectories (some repos have skills nested)
    $nested = Get-ChildItem $Destination -Directory -ErrorAction SilentlyContinue | Where-Object {
        Test-Path (Join-Path $_.FullName "SKILL.md")
    }

    if ($nested.Count -eq 1) {
        Write-Host "[fetch-skill] SKILL.md found in subdirectory: $($nested[0].Name)" -ForegroundColor Yellow
        Write-Host "[fetch-skill] Note: Skill is nested, may need path adjustment"
    }
    elseif ($nested.Count -gt 1) {
        Write-Host "[fetch-skill] Multiple subdirectories with SKILL.md found (multi-skill repo)" -ForegroundColor Yellow
        $nested | ForEach-Object { Write-Host "  - $($_.Name)" }
    }
    else {
        Write-Host "[fetch-skill] WARNING: No SKILL.md found in destination" -ForegroundColor Yellow
    }
    exit 0
}
