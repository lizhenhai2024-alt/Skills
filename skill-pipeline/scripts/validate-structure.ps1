# validate-structure.ps1 - Validate installed skill structure
# Usage: powershell -File validate-structure.ps1 -Path "C:\Users\lizhe\.claude\skills\my-skill"

param(
    [Parameter(Mandatory=$true)]
    [string]$Path
)

$errors = @()
$warnings = @()

# 1. Check SKILL.md exists and is non-empty
$skillMd = Join-Path $Path "SKILL.md"
if (-not (Test-Path $skillMd)) {
    $errors += "SKILL.md not found"
}
else {
    $content = Get-Content $skillMd -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($content)) {
        $errors += "SKILL.md is empty"
    }

    # 2. Validate YAML frontmatter
    if ($content -match '(?s)^---\s*\r?\n(.*?)\r?\n---') {
        $frontmatter = $Matches[1]

        if ($frontmatter -notmatch '(?m)^name:\s*.+') {
            $errors += "SKILL.md frontmatter missing 'name' field"
        }
        elseif ($frontmatter -match '(?m)^name:\s*(.+)') {
            $name = $Matches[1].Trim().Trim("'").Trim('"')
            if ($name -notmatch '^[a-z][a-z0-9-]*$') {
                $warnings += "Skill name '$name' does not follow kebab-case (lowercase, digits, hyphens)"
            }
        }

        if ($frontmatter -notmatch '(?m)^description:\s*.+') {
            $warnings += "SKILL.md frontmatter missing 'description' field"
        }
    }
    else {
        $warnings += "SKILL.md has no YAML frontmatter"
    }
}

# 3. Check for forbidden files
$forbiddenFiles = @('.env', 'credentials.json', 'secrets.json', 'id_rsa', 'id_ed25519', '.pem')
foreach ($file in $forbiddenFiles) {
    $forbiddenPath = Join-Path $Path $file
    if (Test-Path $forbiddenPath) {
        $errors += "Forbidden file found: $file"
    }
}

# 4. Validate scripts/ directory (if present)
$scriptsDir = Join-Path $Path "scripts"
if (Test-Path $scriptsDir -PathType Container) {
    $scriptFiles = Get-ChildItem $scriptsDir -File -ErrorAction SilentlyContinue
    if ($scriptFiles.Count -eq 0) {
        $warnings += "scripts/ directory exists but is empty"
    }
}

# 5. Validate evolution.json (if present)
$evoJson = Join-Path $Path "evolution.json"
if (Test-Path $evoJson) {
    try {
        $evo = Get-Content $evoJson -Raw | ConvertFrom-Json
        if (-not $evo.version) {
            $warnings += "evolution.json missing 'version' field"
        }
    }
    catch {
        $errors += "evolution.json is not valid JSON"
    }
}

# Output as JSON
$result = @{
    path      = $Path
    valid     = ($errors.Count -eq 0)
    errors    = $errors
    warnings  = $warnings
    skill_md  = (Test-Path $skillMd)
    has_scripts = (Test-Path $scriptsDir -PathType Container)
    has_evolution = (Test-Path $evoJson)
}

$result | ConvertTo-Json -Compress

if ($errors.Count -gt 0) { exit 1 }
if ($warnings.Count -gt 0) { exit 2 }
exit 0
