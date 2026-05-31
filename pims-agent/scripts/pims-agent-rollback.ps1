# pims-agent-rollback.ps1 - PIMS Agent Rollback Executor
# Reads operation journal, reverses completed operations in LIFO order
# Usage: .\pims-agent-rollback.ps1 -Journal <journal.jsonl> [-OutputDir <dir>] [-Force] [-MaxAgeDays <int>]

param(
    [Parameter(Mandatory=$true)]
    [string]$Journal,

    [string]$OutputDir = $PWD.Path,

    [int]$MaxAgeDays = 7,

    [switch]$Force
)

$ErrorActionPreference = 'Continue'

if (-not (Test-Path $Journal)) {
    Write-Error "Journal not found: $Journal"
    exit 1
}

# Check journal age
$journalTime = (Get-Item $Journal).LastWriteTime
$ageDays = [math]::Floor(((Get-Date) - $journalTime).TotalDays)
if ($ageDays -gt $MaxAgeDays -and -not $Force) {
    Write-Error "Journal is $ageDays days old (max $MaxAgeDays). Use -Force to override."
    exit 1
}

# Check for existing rollback report
$journalDir = [System.IO.Path]::GetDirectoryName($Journal)
$journalBase = [System.IO.Path]::GetFileNameWithoutExtension($Journal)
$existingRollback = Get-ChildItem $journalDir -Filter "rollback_report_*.md" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "*$journalBase*" }
if ($existingRollback -and -not $Force) {
    Write-Error "Rollback report already exists for this journal. Use -Force to override."
    exit 1
}

# Read journal
$entries = @()
Get-Content $Journal -Encoding UTF8 | ForEach-Object {
    if ($_ -match '^\s*\{') {
        try { $entries += ($_ | ConvertFrom-Json) }
        catch { }
    }
}

# Only process completed operations
$completedEntries = @($entries | Where-Object { $_.status -eq 'completed' })
if ($completedEntries.Count -eq 0) {
    Write-Output "[Rollback] No completed operations to rollback"
    exit 0
}

Write-Output "[Rollback] Starting: $($completedEntries.Count) operations"

# Sort descending by op_id (LIFO)
$sortedEntries = $completedEntries | Sort-Object { [int]$_.op_id } -Descending

$rollbackSuccess = 0
$rollbackFailed = 0
$rollbackSkipped = 0
$rollbackLog = [System.Collections.ArrayList]::new()

foreach ($entry in $sortedEntries) {
    $opId = $entry.op_id
    $type = $entry.type

    if ($type -eq 'mkdir') {
        $path = $entry.path
        if (Test-Path $path) {
            $items = @(Get-ChildItem $path -ErrorAction SilentlyContinue)
            if ($items.Count -eq 0) {
                try {
                    Remove-Item $path -Force -Confirm:$false
                    $rollbackSuccess++
                    $rollbackLog.Add("[OK] mkdir rmdir: $path") | Out-Null
                }
                catch {
                    $rollbackFailed++
                    $rollbackLog.Add("[ERR] mkdir rmdir failed: $path | $_") | Out-Null
                }
            }
            else {
                $rollbackSkipped++
                $rollbackLog.Add("[SKIP] mkdir dir not empty: $path ($($items.Count) files)") | Out-Null
            }
        }
        else {
            $rollbackSkipped++
            $rollbackLog.Add("[SKIP] mkdir dir gone: $path") | Out-Null
        }
    }

    elseif ($type -eq 'move') {
        $target = $entry.target
        $source = $entry.source

        if (-not (Test-Path $target)) {
            $rollbackSkipped++
            $rollbackLog.Add("[SKIP] move target gone: $target") | Out-Null
            continue
        }

        # Integrity check: size
        $targetItem = Get-Item $target
        if ($entry.size_bytes -and $targetItem.Length -ne [long]$entry.size_bytes) {
            $rollbackSkipped++
            $rollbackLog.Add("[MANUAL] move target size changed: $target") | Out-Null
            continue
        }

        # Check if source location already has a file
        if ($source -and (Test-Path $source)) {
            $rollbackSkipped++
            $rollbackLog.Add("[MANUAL] move source already occupied: $source") | Out-Null
            continue
        }

        try {
            # Ensure source directory exists
            $sourceDir = [System.IO.Path]::GetDirectoryName($source)
            if (-not (Test-Path $sourceDir)) {
                New-Item -ItemType Directory -Path $sourceDir -Force | Out-Null
            }
            # Use .NET method (supports Chinese paths)
            [System.IO.File]::Move($target, $source)
            $rollbackSuccess++
            $rollbackLog.Add("[OK] move back: $target -> $source") | Out-Null
        }
        catch {
            # Fallback to PowerShell Move-Item
            try {
                Move-Item -Path $target -Destination $source -Force
                $rollbackSuccess++
                $rollbackLog.Add("[OK] move back (PS): $target -> $source") | Out-Null
            }
            catch {
                $rollbackFailed++
                $rollbackLog.Add("[ERR] move back failed: $target -> $source | $_") | Out-Null
            }
        }
    }

    elseif ($type -eq 'copy') {
        $target = $entry.target

        if (-not (Test-Path $target)) {
            $rollbackSkipped++
            $rollbackLog.Add("[SKIP] copy target gone: $target") | Out-Null
            continue
        }

        # Size validation
        $targetItem = Get-Item $target
        $tgtSize = 0
        if ($entry.rollback) {
            $rb = $entry.rollback | ConvertTo-Json -Depth 1 | ConvertFrom-Json
            if ($rb.target_size) { $tgtSize = [long]$rb.target_size }
        }
        if ($tgtSize -gt 0 -and $targetItem.Length -ne $tgtSize) {
            $rollbackSkipped++
            $rollbackLog.Add("[MANUAL] copy target size changed: $target") | Out-Null
            continue
        }

        try {
            Remove-Item $target -Force -Confirm:$false
            $rollbackSuccess++
            $rollbackLog.Add("[OK] copy delete: $target") | Out-Null
        }
        catch {
            $rollbackFailed++
            $rollbackLog.Add("[ERR] copy delete failed: $target | $_") | Out-Null
        }
    }

    elseif ($type -eq 'rename') {
        $renamed = $entry.renamed
        $original = $entry.original

        if (-not (Test-Path $renamed)) {
            $rollbackSkipped++
            $rollbackLog.Add("[SKIP] rename file gone: $renamed") | Out-Null
            continue
        }

        if (Test-Path $original) {
            $rollbackSkipped++
            $rollbackLog.Add("[MANUAL] rename original occupied: $original") | Out-Null
            continue
        }

        try {
            [System.IO.File]::Move($renamed, $original)
            $rollbackSuccess++
            $rollbackLog.Add("[OK] rename back: $renamed -> $original") | Out-Null
        }
        catch {
            try {
                $origName = [System.IO.Path]::GetFileName($original)
                Rename-Item -Path $renamed -NewName $origName -Force
                $rollbackSuccess++
                $rollbackLog.Add("[OK] rename back (PS): $renamed -> $original") | Out-Null
            }
            catch {
                $rollbackFailed++
                $rollbackLog.Add("[ERR] rename back failed: $renamed -> $original | $_") | Out-Null
            }
        }
    }

    else {
        $rollbackSkipped++
        $rollbackLog.Add("[SKIP] unknown op type: $type (op_id=$opId)") | Out-Null
    }
}

# Write rollback report
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$reportFile = Join-Path $OutputDir "rollback_report_$timestamp.md"

$logLines = ""
foreach ($l in $rollbackLog) { $logLines += "- $l`n" }

$manualLines = ""
foreach ($l in $rollbackLog) {
    if ($l -match '^\[(ERR|MANUAL)\]') { $manualLines += "- $l`n" }
}

$report = @"
# PIMS Agent Rollback Report
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Journal: $Journal

## Summary

| Metric | Value |
|:--|:--|
| Success | $rollbackSuccess |
| Failed | $rollbackFailed |
| Skipped | $rollbackSkipped |
| Journal age | $ageDays days |

## Log

$logLines

$(if ($manualLines) { "## Manual Review Needed`n`n$manualLines" })
"@

Add-Content -Path $reportFile -Value $report -Encoding UTF8

Write-Output ""
Write-Output "[Rollback] Done: success=$rollbackSuccess failed=$rollbackFailed skipped=$rollbackSkipped"
Write-Output "ROLLBACK_REPORT=$reportFile"

if ($rollbackFailed -gt 0) { exit 2 }
if ($rollbackSkipped -gt 0) { exit 1 }
exit 0
