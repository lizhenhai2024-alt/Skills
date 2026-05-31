---
name: skill-pipeline
version: "1.0.0"
description: "Parallel batch skill installation with security vetting and GFW-resilient networking. TRIGGER when: installing multiple skills at once, bulk-importing skills from a checklist, vetting skills before installation, or recovering from network failures during skill setup."
github_repo: lizhenhai2024-alt/Skills
github_hash: 28a8ae9749ab3b2586253c22b5a48ad903145354
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

Each line → `{ name, source, source_type }`: GitHub URLs → `github`, local paths → `local`, archive URLs → `url`. Skip comments (`#`) and already-checked items (`[x]`).

---

## Phase 2: DETECT — Check Installed Skills

Before fetching, check which skills are already installed:
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

Create staging at `$env:TEMP\skill-pipeline-{timestamp}\`, then use `scripts/fetch-skill.ps1` to clone with full network recovery cascade.

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

`robocopy "$stagingBase\{skill-name}" "$env:USERPROFILE\.claude\skills\{skill-name}" /E /MOVE /R:1 /W:1 /NFL /NDL /NP /XD .git` → then validate with `scripts/validate-structure.ps1`.

---

## Phase 5: REPORT — Consolidated Status

Collect all results from vetting and installation, then generate a report.

### Build Results JSON

Compile results with one entry per skill: name, status (SKIPPED/INSTALLED/BLOCKED/FAILED), path, source_type, risk_level, issues.

### Generate Report

```powershell
$resultsJson | Out-File "$env:TEMP\pipeline-results.json" -Encoding utf8
powershell -File "{baseDir}/scripts/generate-report.ps1" -ResultsFile "$env:TEMP\pipeline-results.json"
```

Output format: a Markdown table with columns Skill, Status (✅/⏭️/🚫/❌), Path, Source, Risk, Issues.

---

## Network Recovery Strategy

Cascade: `Direct → Proxy → GitHub Mirror → Alternative Mirror → FAILED`

- Proxy detection: registry + env + config.env
- Mirrors: ghproxy.com, gitclone.com; npm: npmmirror.com
- Backoff: 2s → 4s → 8s, max 3 retries
- **Never retry the same command after failure** — always change strategy

Full details in `references/network-recovery.md`.

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

## Quick Start

```
User: "Install all skills from my checklist"
1. PARSE: Read checklist → extract URLs
2. DETECT: Check installed → skip duplicates
3. VET: Parallel security review (max 5 concurrent)
4. INSTALL: Copy vetted skills, inject metadata, validate
5. REPORT: Consolidated table with status per skill
```
