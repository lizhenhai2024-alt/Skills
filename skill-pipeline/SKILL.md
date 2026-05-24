---
name: skill-pipeline
version: "1.0.0"
description: "Parallel batch skill installation with security vetting and GFW-resilient networking. TRIGGER when: installing multiple skills at once, bulk-importing skills from a checklist, vetting skills before installation, or recovering from network failures during skill setup."
---

# Skill Pipeline — Parallel Vetting & Installation

Batch install, vet, and validate Claude Code skills with GFW-resilient networking and parallel execution.

## When to Use

- Installing multiple skills from a markdown checklist or URL list
- Recovering from GFW-blocked skill installations
- Vetting skills before installation (security-first)
- Bulk importing from GitHub repos, local directories, or archives
- When user says: "install these skills", "batch install", "vet and install", "skill pipeline", "install all skills from", "checklist install"

## Pipeline Architecture

```
PARSE checklist → DETECT installed → VET security (parallel) → INSTALL (parallel) → REPORT
```

---

## Phase 1: PARSE — Read the Checklist

Read the skill source list provided by the user. Supported formats:

### Format A: Markdown Checklist

```markdown
## Skills to Install
- [ ] https://github.com/user/skill-a
- [ ] https://github.com/user/skill-b
- [x] F:\PIMS\05_Code\0504_Scripts\Skills\my-local-skill
```

### Format B: Simple List

```
https://github.com/user/skill-a
https://github.com/user/skill-b
my-local-skill
```

### Format C: GitHub Bundle

```
https://github.com/owner/multi-skill-repo
```

For bundles, after cloning, scan subdirectories for SKILL.md files.

### Parsing Rules

1. Extract each line containing a URL or skill name
2. Normalize to: `{ name, source, source_type }`
3. For GitHub URLs: `source_type = "github"`, extract repo name as `name`
4. For local paths: `source_type = "local"`, use directory name as `name`
5. For archive URLs: `source_type = "url"`, use filename (without extension) as `name`
6. Skip lines that are comments (`#`) or already checked (`[x]`)

---

## Phase 2: DETECT — Check Installed Skills

Before fetching, check which skills are already installed.

```powershell
# List all installed skill directories
Get-ChildItem "$env:USERPROFILE\.claude\skills" -Directory | Select-Object -ExpandProperty Name
```

For each skill in the parsed list:
- If a directory with that name exists in `~/.claude/skills/` → mark as **SKIPPED**
- Otherwise → proceed to vetting

---

## Phase 3: VET — Security Vetting (Parallel)

For each uninstalled skill, spawn a subagent to perform security vetting.

### Network Recovery Before Fetching

Run proxy detection first:

```powershell
powershell -File "{baseDir}/scripts/detect-proxy.ps1" --test --json
```

If proxy is available but not enabled, enable it:

```powershell
powershell -File "{baseDir}/scripts/detect-proxy.ps1" --enable
```

### Fetching Skills to Staging

Create a staging directory:

```powershell
$stagingBase = Join-Path $env:TEMP "skill-pipeline-staging-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $stagingBase -Force
```

For each skill, fetch to staging using the fetch script:

```powershell
powershell -File "{baseDir}/scripts/fetch-skill.ps1" -Source "{source_url}" -Destination "$stagingBase/{skill-name}"
```

The fetch script handles the full network recovery cascade (direct → proxy → mirror).

### Parallel Vetting with Subagents

Spawn up to **5 concurrent** subagents (configurable in config.env). Each subagent uses the vetting protocol from `agents/vetter.md`:

1. Read ALL files in the skill directory
2. Execute the 4-step vetting protocol (Source Check → Code Review → Permission Scope → Risk Classification)
3. Produce a structured JSON verdict

**Vetting is READ-ONLY** — skills stay in staging, nothing is installed yet.

### Vetting Outcomes

| Verdict | Meaning | Next Action |
|---------|---------|-------------|
| SAFE_TO_INSTALL | No red flags, low risk | Proceed to install |
| INSTALL_WITH_CAUTION | Medium risk or minor concerns | Install but flag in report |
| DO_NOT_INSTALL | Red flags or high/extreme risk | Block installation |

---

## Phase 4: INSTALL — Parallel Installation

For each vetted skill with verdict SAFE_TO_INSTALL or INSTALL_WITH_CAUTION, spawn a subagent using `agents/installer.md`.

Each installer subagent:
1. Checks if skill is already installed (skip if present)
2. Copies from staging to `~/.claude/skills/{skill-name}/`
3. Injects GitHub metadata (if GitHub-sourced)
4. Initializes `evolution.json`
5. Validates structure via `scripts/validate-structure.ps1`
6. Cleans up staging directory

Skills with verdict DO_NOT_INSTALL are **blocked** — they remain in staging (not installed) and are flagged in the report.

### Install Command

```powershell
# Robocopy for large skills (handles Chinese paths)
robocopy "$stagingBase\{skill-name}" "$env:USERPROFILE\.claude\skills\{skill-name}" /E /MOVE /R:1 /W:1 /NFL /NDL /NP /XD .git

# Validate after install
powershell -File "{baseDir}/scripts/validate-structure.ps1" -Path "$env:USERPROFILE\.claude\skills\{skill-name}"
```

---

## Phase 5: REPORT — Consolidated Status

Collect all results from vetting and installation, then generate a report.

### Build Results JSON

Compile a JSON array with one entry per skill:

```json
[
  {
    "name": "web-access",
    "status": "SKIPPED",
    "path": "C:\\Users\\lizhe\\.claude\\skills\\web-access",
    "source_type": "github",
    "risk_level": "-",
    "issues": ["Already installed"]
  },
  {
    "name": "new-skill",
    "status": "INSTALLED",
    "path": "C:\\Users\\lizhe\\.claude\\skills\\new-skill",
    "source_type": "github",
    "risk_level": "LOW",
    "issues": []
  },
  {
    "name": "risky-skill",
    "status": "BLOCKED",
    "path": "-",
    "source_type": "github",
    "risk_level": "HIGH",
    "issues": ["Sends data to external servers", "Requests credentials"]
  },
  {
    "name": "failed-skill",
    "status": "FAILED",
    "path": "-",
    "source_type": "github",
    "risk_level": "-",
    "issues": ["Network timeout after 3 retries"]
  }
]
```

### Generate Report

```powershell
$resultsJson | Out-File "$env:TEMP\pipeline-results.json" -Encoding utf8
powershell -File "{baseDir}/scripts/generate-report.ps1" -ResultsFile "$env:TEMP\pipeline-results.json"
```

Output format:

```markdown
## Skill Pipeline Report

| Skill | Status | Path | Source | Risk | Issues |
|-------|--------|------|--------|------|--------|
| web-access | ⏭️ SKIPPED | ~/.claude/skills/web-access | github | - | Already installed |
| new-skill | ✅ INSTALLED | ~/.claude/skills/new-skill | github | LOW | - |
| risky-skill | 🚫 BLOCKED | - | github | HIGH | Sends data to external servers |
| failed-skill | ❌ FAILED | - | github | - | Network timeout after 3 retries |

**Summary**: 4 skills processed — 1 skipped, 1 installed, 1 blocked, 1 failed
```

---

## Network Recovery Strategy

When fetching skills from GitHub, follow this cascade:

```
Direct → With Proxy → GitHub Mirror → Alternative Mirror → FAILED
```

See `references/network-recovery.md` for full details including:
- Proxy detection (Windows registry + environment + config.env)
- Git proxy flags (`-c http.proxy=...`)
- GitHub mirrors (ghproxy.com, gitclone.com)
- npm mirrors (npmmirror.com)
- Retry with exponential backoff (2s → 4s → 8s)

**Key rule:** Never retry the same command after failure. Always change strategy (add proxy, switch mirror).

---

## Integration with Existing Skills

| Skill | Integration Point |
|-------|------------------|
| **skill-vetter** | Vetting subagent implements its 4-step protocol |
| **skill-manager** | Post-install registration and version tracking |
| **github-to-skills** | Metadata injection (github_url, github_hash) for GitHub-sourced skills |
| **skill-evolution-manager** | evolution.json initialization for newly installed skills |

---

## Configuration

Edit `config.env` to customize:

| Setting | Default | Description |
|---------|---------|-------------|
| PROXY_HOST | 127.0.0.1 | Proxy host address |
| PROXY_PORT | 11721 | Proxy port (Clash default) |
| GITHUB_MIRRORS | ghproxy.com, gitclone.com | GitHub mirror cascade |
| NPM_MIRROR | npmmirror.com | npm registry mirror |
| MAX_CONCURRENT | 5 | Maximum parallel subagents |
| MAX_RETRIES | 3 | Network retry attempts |
| INITIAL_DELAY_SECONDS | 2 | First retry delay |
| BACKOFF_MULTIPLIER | 2 | Delay multiplier per retry |
| GIT_CLONE_TIMEOUT | 120 | git clone timeout (seconds) |
| VETTING_MODE | standard | permissive / standard / strict |

---

## Self-Check

After completing the pipeline, verify:

- [ ] All skills in the checklist were processed (none silently dropped)
- [ ] SKIPPED skills are genuinely already installed
- [ ] INSTALLED skills pass validate-structure.ps1
- [ ] BLOCKED skills have clear red flag documentation
- [ ] FAILED skills have specific error messages (not just "failed")
- [ ] No skills were installed without vetting
- [ ] Staging directory was cleaned up
- [ ] Report was presented to the user

---

## Quick Start Example

```
User: "Install all skills from my checklist at F:\PIMS\00_Index\skill-checklist.md"

Pipeline execution:
1. PARSE: Read checklist, extract 10 skill URLs
2. DETECT: 7 already installed → SKIPPED, 3 need processing
3. VET: Spawn 3 parallel vetter subagents
   - skill-a: SAFE_TO_INSTALL
   - skill-b: INSTALL_WITH_CAUTION (reads ~/.config)
   - skill-c: DO_NOT_INSTALL (sends data externally)
4. INSTALL: Spawn 2 parallel installer subagents
   - skill-a: INSTALLED ✅
   - skill-b: INSTALLED_WITH_CAUTION ⚠️
   - skill-c: BLOCKED 🚫
5. REPORT: Show consolidated table
```
