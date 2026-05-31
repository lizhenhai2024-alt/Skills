# pims-agent-scan.ps1 — PIMS Agent Scanner
# Recursively scan directory, generate file inventory (JSONL)
# Usage: .\pims-agent-scan.ps1 -Path <dir> [-OutputDir <dir>] [-SkipAgeDays <int>]

param(
    [Parameter(Mandatory=$true)]
    [string]$Path,

    [string]$OutputDir = $PWD.Path,

    [int]$SkipAgeDays = 7,

    [int]$StaleAgeDays = 30,

    [int]$FlagAgeDays = 180,

    [switch]$Force
)

$ErrorActionPreference = 'Continue'

# --- G3 skip rules ---
$script:skipNames = @('desktop.ini', 'thumbs.db', '.ds_store')
$script:skipPatterns = @('*.tmp', '*.temp', '*.lnk', '*.url', '*.crdownload', '*.part')
$script:skipPrefixes = @('~$')
$script:protectedDirs = @('.git', 'node_modules', '__pycache__', '.venv', '.obsidian', '.claude')

function Test-ShouldSkip {
    param([System.IO.FileInfo]$Item)
    $name = $Item.Name
    if ($Item.Length -eq 0) { return $true }
    if ($script:skipNames -contains $name.ToLower()) { return $true }
    foreach ($pat in $script:skipPatterns) {
        if ($name -like $pat) { return $true }
    }
    foreach ($prefix in $script:skipPrefixes) {
        if ($name.StartsWith($prefix)) { return $true }
    }
    return $false
}

function Test-ProtectedPath {
    param([string]$FullPath)
    $segments = $FullPath -split '[\\/]'
    foreach ($dir in $script:protectedDirs) {
        if ($segments -contains $dir) { return $true }
    }
    return $false
}

function Get-AgeCategory {
    param([int]$AgeDays)
    if ($AgeDays -lt $SkipAgeDays) { return 'skip' }
    if ($AgeDays -le $StaleAgeDays) { return 'archive' }
    if ($AgeDays -le $FlagAgeDays) { return 'stale' }
    return 'flag'
}

function Get-FileMD5 {
    param([string]$FilePath)
    try {
        $stream = [System.IO.File]::OpenRead($FilePath)
        $md5 = [System.Security.Cryptography.MD5]::Create()
        $hash = $md5.ComputeHash($stream)
        $stream.Close()
        $md5.Dispose()
        return ([BitConverter]::ToString($hash) -replace '-','')
    }
    catch {
        return $null
    }
}

# --- Main scan logic ---

if (-not (Test-Path $Path)) {
    Write-Error "Path not found: $Path"
    exit 1
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$inventoryFile = Join-Path $OutputDir "scan_inventory_$timestamp.jsonl"
$summaryFile = Join-Path $OutputDir "scan_summary_$timestamp.json"

# Idempotency check
if (-not $Force -and (Test-Path $OutputDir)) {
    $existing = Get-ChildItem $OutputDir -Filter 'scan_inventory_*.jsonl' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($existing) {
        $dirLastWrite = (Get-Item $Path).LastWriteTime
        if ($dirLastWrite -lt $existing.LastWriteTime) {
            Write-Output "[INFO] Directory unchanged, reusing: $($existing.FullName)"
            Write-Output "INVENTORY_PATH=$($existing.FullName)"
            exit 0
        }
    }
}

$today = Get-Date
$totalFiles = 0
$totalSize = [long]0
$skippedFiles = 0
$protectedFiles = 0
$ageSkip = 0; $ageArchive = 0; $ageStale = 0; $ageFlag = 0
$extensionCounts = @{}

Write-Output "[Scan] Starting: $Path"

# Use [System.IO] for enumeration (faster, supports long paths)
$enumPath = $Path
if ($Path.Length -gt 240) { $enumPath = "\\?\$Path" }

$fileList = @()
try {
    $fileList = [System.IO.Directory]::EnumerateFiles($enumPath, '*', [System.IO.SearchOption]::AllDirectories)
}
catch {
    Write-Error "Cannot enumerate directory: $_"
    exit 1
}

foreach ($fp in $fileList) {
    # Remove \\?\ prefix
    $cleanPath = $fp -replace '^\\\\\?\\', ''

    # Protected directory check
    if (Test-ProtectedPath -FullPath $cleanPath) {
        $protectedFiles++
        continue
    }

    # Get FileInfo
    try {
        $fi = [System.IO.FileInfo]::new($fp)
    }
    catch {
        continue
    }

    # G3 skip check
    if (Test-ShouldSkip -Item $fi) {
        $skippedFiles++
        continue
    }

    $ageDays = [math]::Floor(($today - $fi.LastWriteTime).TotalDays)
    $ageCategory = Get-AgeCategory -AgeDays $ageDays

    if ($fi.Extension) {
        $ext = $fi.Extension.ToLower()
    } else {
        $ext = ''
    }

    # Stats
    $totalFiles++
    $totalSize += $fi.Length

    switch ($ageCategory) {
        'skip'   { $ageSkip++ }
        'archive' { $ageArchive++ }
        'stale'  { $ageStale++ }
        'flag'   { $ageFlag++ }
    }

    if ($extensionCounts.ContainsKey($ext)) {
        $extensionCounts[$ext]++
    } else {
        $extensionCounts[$ext] = 1
    }

    # MD5 (only for non-skip files, skip >50MB)
    $md5 = $null
    if ($ageCategory -ne 'skip' -and $fi.Length -le 50MB) {
        $md5 = Get-FileMD5 -FilePath $cleanPath
    }

    # Compute id (SHA256 of path, first 16 chars)
    $pathBytes = [System.Text.Encoding]::UTF8.GetBytes($cleanPath)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha.ComputeHash($pathBytes)
    $sha.Dispose()
    $idStr = ([BitConverter]::ToString($hashBytes) -replace '-','').Substring(0, 16)

    $parentDir = [System.IO.Path]::GetDirectoryName($cleanPath)

    # Build JSONL entry manually for reliability
    $jsonEntry = '{"id":"' + $idStr + '",' +
        '"source_path":' + (ConvertTo-Json -InputObject $cleanPath -Compress) + ',' +
        '"filename":' + (ConvertTo-Json -InputObject $fi.Name -Compress) + ',' +
        '"extension":"' + $ext + '",' +
        '"size_bytes":' + $fi.Length + ',' +
        '"created":"' + $fi.CreationTime.ToString('o') + '",' +
        '"modified":"' + $fi.LastWriteTime.ToString('o') + '",' +
        '"age_days":' + $ageDays + ',' +
        '"age_category":"' + $ageCategory + '",' +
        '"md5":' + $(if ($md5) { '"' + $md5 + '"' } else { 'null' }) + ',' +
        '"parent_dir":' + (ConvertTo-Json -InputObject $parentDir -Compress) + '}'

    Add-Content -Path $inventoryFile -Value $jsonEntry -Encoding UTF8
}

# Write summary
$summaryJson = @{
    timestamp = $timestamp
    source_path = $Path
    total_files = $totalFiles
    total_size_bytes = $totalSize
    skipped_files = $skippedFiles
    protected_files = $protectedFiles
    age_skip = $ageSkip
    age_archive = $ageArchive
    age_stale = $ageStale
    age_flag = $ageFlag
    inventory_file = $inventoryFile
} | ConvertTo-Json

Add-Content -Path $summaryFile -Value $summaryJson -Encoding UTF8

Write-Output "[Scan] Done: $totalFiles files, $skippedFiles skipped, $protectedFiles protected"
Write-Output "[Scan] Age: skip=$ageSkip archive=$ageArchive stale=$ageStale flag=$ageFlag"
Write-Output "INVENTORY_PATH=$inventoryFile"
Write-Output "SUMMARY_PATH=$summaryFile"
