# generate-report.ps1 - Generate consolidated markdown report from pipeline results
# Usage: powershell -File generate-report.ps1 -ResultsFile "C:\temp\pipeline-results.json"

param(
    [Parameter(Mandatory=$true)]
    [string]$ResultsFile
)

if (-not (Test-Path $ResultsFile)) {
    Write-Host "Error: Results file not found: $ResultsFile" -ForegroundColor Red
    exit 1
}

$results = Get-Content $ResultsFile -Raw | ConvertFrom-Json

# Status markers (ASCII-safe for PS 5.1 compatibility)
$statusMark = @{
    "SKIPPED"                = "[SKIP]"
    "INSTALLED"              = "[OK]"
    "BLOCKED"                = "[BLOCK]"
    "FAILED"                 = "[FAIL]"
    "INSTALLED_WITH_CAUTION" = "[WARN]"
}

$counts = @{
    "SKIPPED"                = 0
    "INSTALLED"              = 0
    "BLOCKED"                = 0
    "FAILED"                 = 0
    "INSTALLED_WITH_CAUTION" = 0
}

$rows = @()
foreach ($skill in $results) {
    $status = $skill.status
    if ($counts.ContainsKey($status)) { $counts[$status]++ }

    $mark = "-"
    if ($statusMark.ContainsKey($status)) { $mark = $statusMark[$status] }

    $path = "-"
    if ($skill.path -and $skill.path.ToString() -ne "") {
        $path = $skill.path.ToString() -replace [regex]::Escape($env:USERPROFILE), "~"
    }

    $source = "-"
    if ($skill.source_type) { $source = $skill.source_type.ToString() }

    $risk = "-"
    if ($skill.risk_level -and $skill.risk_level.ToString() -ne "-") { $risk = $skill.risk_level.ToString() }

    $issues = "-"
    if ($skill.issues) {
        $issueList = @()
        foreach ($i in $skill.issues) { $issueList += $i.ToString() }
        if ($issueList.Count -gt 0) { $issues = $issueList -join "; " }
    }

    $name = $skill.name.ToString()
    $rows += "| $name | $mark $status | $path | $source | $risk | $issues |"
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$total = $results.Count

$tableRows = $rows -join "`n"
$sumSkipped = $counts["SKIPPED"]
$sumInstalled = $counts["INSTALLED"]
$sumCaution = $counts["INSTALLED_WITH_CAUTION"]
$sumBlocked = $counts["BLOCKED"]
$sumFailed = $counts["FAILED"]

Write-Host "## Skill Pipeline Report"
Write-Host ""
Write-Host "> Generated: $timestamp"
Write-Host ""
Write-Host "| Skill | Status | Path | Source | Risk | Issues |"
Write-Host "|-------|--------|------|--------|------|--------|"
Write-Host $tableRows
Write-Host ""
Write-Host "**Summary**: $total skills processed - $sumSkipped skipped, $sumInstalled installed, $sumCaution installed with caution, $sumBlocked blocked, $sumFailed failed"
