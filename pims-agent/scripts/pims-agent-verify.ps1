# pims-agent-verify.ps1 - PIMS Agent Pre-execution Verifier
# Reads operation journal, runs 7 pre-flight checks
# Usage: .\pims-agent-verify.ps1 -Journal <journal.jsonl> [-OutputDir <dir>]

param(
    [Parameter(Mandatory=$true)]
    [string]$Journal,

    [string]$OutputDir = $PWD.Path,

    [double]$DiskSpaceThreshold = 0.10
)

$ErrorActionPreference = 'Continue'

if (-not (Test-Path $Journal)) {
    Write-Error "Journal not found: $Journal"
    exit 1
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$reportFile = Join-Path $OutputDir "verification_report_$timestamp.md"

# Read journal
$entries = @()
Get-Content $Journal -Encoding UTF8 | ForEach-Object {
    if ($_ -match '^\s*\{') {
        try { $entries += ($_ | ConvertFrom-Json) }
        catch { }
    }
}

$plannedEntries = @($entries | Where-Object { $_.status -eq 'planned' })
$warnings = [System.Collections.ArrayList]::new()
$errors = [System.Collections.ArrayList]::new()
$checks = @{}

# --- Check 1: Target path validation ---
Write-Output "[Verify] 1/7 Target path validation..."
$targetPaths = @($plannedEntries | Where-Object { $_.type -in @('move','copy') } |
    Select-Object -ExpandProperty target -ErrorAction SilentlyContinue)
$missingDirs = @{}
$check1 = 'PASS'

foreach ($tp in $targetPaths) {
    if (-not $tp) { continue }
    $parentDir = [System.IO.Path]::GetDirectoryName($tp)
    if (-not (Test-Path $parentDir)) {
        if (-not $missingDirs.ContainsKey($parentDir)) {
            $missingDirs[$parentDir] = 0
            $drive = [System.IO.Path]::GetPathRoot($parentDir)
            if ($drive -and -not (Test-Path $drive)) {
                $errors.Add("Target drive not found: $drive") | Out-Null
                $check1 = 'FAIL'
            }
        }
        $missingDirs[$parentDir]++
    }
    if ($tp.Length -gt 260) {
        $warnings.Add("Path >260 chars: $tp ($($tp.Length))") | Out-Null
        $check1 = 'WARN'
    }
    elseif ($tp.Length -gt 230) {
        $warnings.Add("Path approaching 260 limit: $tp ($($tp.Length))") | Out-Null
        if ($check1 -eq 'PASS') { $check1 = 'WARN' }
    }
}
$checks['1_TargetPath'] = $check1

# --- Check 2: Disk space ---
Write-Output "[Verify] 2/7 Disk space..."
$sizeByDrive = @{}
$diskSpace = @{}
$check2 = 'PASS'

$plannedMoves = @($plannedEntries | Where-Object { $_.type -in @('move','copy') })
foreach ($entry in $plannedMoves) {
    if (-not $entry.target) { continue }
    $drive = [System.IO.Path]::GetPathRoot($entry.target)
    if (-not $sizeByDrive.ContainsKey($drive)) { $sizeByDrive[$drive] = 0 }
    $sz = 0
    if ($entry.size_bytes) { $sz = [long]$entry.size_bytes }
    $sizeByDrive[$drive] += $sz
}

foreach ($drive in $sizeByDrive.Keys) {
    try {
        $di = [System.IO.DriveInfo]::new($drive)
        $availableGB = [math]::Round($di.AvailableFreeSpace / 1GB, 2)
        $totalGB = [math]::Round($di.TotalSize / 1GB, 2)
        $requiredGB = [math]::Round($sizeByDrive[$drive] / 1GB, 2)
        $freePercent = [math]::Round($di.AvailableFreeSpace / $di.TotalSize * 100, 1)

        $diskSpace[$drive] = @{
            available_gb = $availableGB
            total_gb = $totalGB
            required_gb = $requiredGB
            free_percent = $freePercent
        }

        if ($freePercent -lt ($DiskSpaceThreshold * 100)) {
            $errors.Add("Low disk on ${drive}: ${freePercent}% free, need ${requiredGB}GB") | Out-Null
            $check2 = 'FAIL'
        }
    }
    catch {
        $warnings.Add("Cannot check disk: $drive") | Out-Null
        $check2 = 'WARN'
    }
}
$checks['2_DiskSpace'] = $check2

# --- Check 3: Naming conflicts ---
Write-Output "[Verify] 3/7 Naming conflict recheck..."
$check3 = 'PASS'
$conflictCount = 0

foreach ($entry in $plannedMoves) {
    if (-not $entry.target) { continue }
    if (Test-Path $entry.target) {
        if ($entry.source -and (Test-Path $entry.source)) {
            $srcItem = Get-Item $entry.source -ErrorAction SilentlyContinue
            $tgtItem = Get-Item $entry.target -ErrorAction SilentlyContinue
            if ($srcItem -and $tgtItem -and $srcItem.FullName -eq $tgtItem.FullName) {
                continue
            }
        }
        $conflictCount++
        $warnings.Add("Target exists: $($entry.target)") | Out-Null
        if ($check3 -eq 'PASS') { $check3 = 'WARN' }
    }
}
if ($conflictCount -gt 0) {
    $warnings.Add("Total conflicts: $conflictCount") | Out-Null
}
$checks['3_Conflicts'] = $check3

# --- Check 4: Source file existence ---
Write-Output "[Verify] 4/7 Source file existence..."
$check4 = 'PASS'
$missingSources = 0

foreach ($entry in $plannedMoves) {
    if (-not $entry.source) { continue }
    if (-not (Test-Path $entry.source)) {
        $missingSources++
        $errors.Add("Source missing: $($entry.source)") | Out-Null
        $check4 = 'FAIL'
    }
}
$checks['4_SourceExists'] = $check4

# --- Check 5: File lock detection ---
Write-Output "[Verify] 5/7 File lock detection..."
$check5 = 'PASS'
$lockedFiles = 0

foreach ($entry in $plannedMoves) {
    if (-not $entry.source) { continue }
    if (-not (Test-Path $entry.source)) { continue }
    try {
        $stream = [System.IO.File]::Open($entry.source, 'Open', 'Read', 'Read')
        $stream.Close()
    }
    catch {
        $lockedFiles++
        $warnings.Add("File locked: $($entry.source)") | Out-Null
        if ($check5 -eq 'PASS') { $check5 = 'WARN' }
    }
}
if ($lockedFiles -gt 0) {
    $warnings.Add("Total locked: $lockedFiles") | Out-Null
}
$checks['5_Locks'] = $check5

# --- Check 6: Cross-drive detection ---
Write-Output "[Verify] 6/7 Cross-drive detection..."
$check6 = 'PASS'
$crossDriveCount = 0

foreach ($entry in $plannedMoves) {
    if (-not $entry.source -or -not $entry.target) { continue }
    $srcDrive = [System.IO.Path]::GetPathRoot($entry.source)
    $tgtDrive = [System.IO.Path]::GetPathRoot($entry.target)
    if ($srcDrive -ne $tgtDrive) {
        $crossDriveCount++
        if ($entry.type -eq 'move') {
            $warnings.Add("Cross-drive move (need copy+delete): $($entry.source) -> $($entry.target)") | Out-Null
            if ($check6 -eq 'PASS') { $check6 = 'WARN' }
        }
    }
}
if ($crossDriveCount -gt 0) {
    $warnings.Add("Total cross-drive ops: $crossDriveCount") | Out-Null
}
$checks['6_CrossDrive'] = $check6

# --- Check 7: Chinese path detection ---
Write-Output "[Verify] 7/7 Chinese path detection..."
$check7 = 'PASS'
$chinesePaths = 0

foreach ($entry in $plannedMoves) {
    foreach ($prop in @('source','target')) {
        $pathVal = $null
        if ($prop -eq 'source') { $pathVal = $entry.source }
        else { $pathVal = $entry.target }
        if (-not $pathVal) { continue }
        if ($pathVal -match '[^\x00-\x7F]') {
            $chinesePaths++
            $warnings.Add("Non-ASCII path (need .NET): $pathVal") | Out-Null
            if ($check7 -eq 'PASS') { $check7 = 'WARN' }
        }
    }
}
if ($chinesePaths -gt 0) {
    $warnings.Add("Total non-ASCII paths: $chinesePaths") | Out-Null
}
$checks['7_ChinesePath'] = $check7

# --- Overall status ---
$overallStatus = 'PASS'
if ($errors.Count -gt 0) { $overallStatus = 'FAIL' }
elseif ($warnings.Count -gt 0) { $overallStatus = 'WARN' }

# --- Build report ---
$checkLines = ""
foreach ($key in ($checks.Keys | Sort-Object)) {
    $checkLines += "| $key | $($checks[$key]) |`n"
}

$diskLines = ""
foreach ($d in ($diskSpace.Keys | Sort-Object)) {
    $ds = $diskSpace[$d]
    $diskLines += "| $d | $($ds.available_gb)GB | $($ds.total_gb)GB | $($ds.required_gb)GB | $($ds.free_percent)% |`n"
}

$errorLines = ""
foreach ($e in $errors) { $errorLines += "- $e`n" }

$warningLines = ""
foreach ($w in $warnings) { $warningLines += "- $w`n" }

$autoApprove = switch ($overallStatus) {
    'PASS' { "Verification passed. Auto-approve to execute." }
    'WARN' { "Warnings found. Manual review recommended before executing." }
    'FAIL' { "Errors found. Must fix before executing." }
}

$report = @"
# PIMS Agent Verification Report
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Journal: $Journal

## Overall: $overallStatus

## Checks

| # | Check | Status |
|:--|:--|:--|
$checkLines

## Stats

| Metric | Value |
|:--|:--|
| Planned ops | $($plannedEntries.Count) |
| Errors | $($errors.Count) |
| Warnings | $($warnings.Count) |
| Conflicts | $conflictCount |
| Missing sources | $missingSources |
| Locked files | $lockedFiles |
| Cross-drive | $crossDriveCount |
| Non-ASCII paths | $chinesePaths |

$(if ($diskLines) { "## Disk Space`n`n| Drive | Available | Total | Required | Free% |`n|:--|:--|:--|:--|:--|`n$diskLines" })

$(if ($errorLines) { "## Errors (must fix)`n$errorLines" })

$(if ($warningLines) { "## Warnings`n$warningLines" })

## Auto-approve
$autoApprove
"@

Add-Content -Path $reportFile -Value $report -Encoding UTF8

Write-Output ""
Write-Output "[Verify] Overall: $overallStatus"
Write-Output "[Verify] Errors: $($errors.Count), Warnings: $($warnings.Count)"
Write-Output "REPORT_PATH=$reportFile"

if ($overallStatus -eq 'FAIL') { exit 2 }
if ($overallStatus -eq 'WARN') { exit 1 }
exit 0
