# Skill Source Formats and Extraction Patterns

## Supported Source Types

### 1. GitHub Repository (Single Skill)

Pattern: `https://github.com/{owner}/{repo}`

The skill files are at the repo root. SKILL.md is in the top-level directory.

```
repo/
├── SKILL.md
├── scripts/
├── agents/
└── references/
```

Fetch: `git clone --depth 1 {url}`

### 2. GitHub Repository (Multi-Skill Bundle)

Pattern: `https://github.com/{owner}/{bundle-repo}`

Multiple skills are nested in subdirectories, each with their own SKILL.md.

```
bundle-repo/
├── skill-a/
│   └── SKILL.md
├── skill-b/
│   └── SKILL.md
└── README.md
```

Fetch: `git clone --depth 1 {url}`, then iterate subdirectories with SKILL.md.

Known bundles:
- `anthropics/claude-plugins-official` — 16+ official skills
- `forrestchang/andrej-karpathy-skills` — Karpathy guidelines
- `thedotmack/claude-mem` — Memory management
- `academic-research-skills` bundle — 3 research skills

### 3. Local Directory

Pattern: `F:\PIMS\05_Code\0504_Scripts\Skills\{skill-name}` or any valid path

Skill files are in a local directory, already structured.

```
skill-name/
├── SKILL.md
├── scripts/
└── ...
```

Fetch: `robocopy {source} {dest} /E /COPY:DAT /R:1 /W:1 /XD .git`

### 4. Archive URL

Pattern: `https://example.com/{skill}.zip` or `https://example.com/{skill}.skill`

A downloadable archive containing the skill files.

Fetch: `Invoke-WebRequest -Uri {url} -OutFile {temp}`, then `Expand-Archive`

## Skill Structure Requirements

A valid skill must have:

| Required | File | Description |
|----------|------|-------------|
| Yes | `SKILL.md` | Main skill definition with YAML frontmatter |
| No | `scripts/` | Automation scripts |
| No | `agents/` | SubAgent instruction files |
| No | `references/` | Reference documents |
| No | `evolution.json` | Evolution tracking data |
| No | `config.env` | User-configurable settings |

## SKILL.md Frontmatter Schema

```yaml
---
name: skill-name          # Required, kebab-case
description: >            # Required, one-line summary
  What this skill does
version: "1.0.0"         # Optional
---
```

## Known Install Locations

| Location | Purpose |
|----------|---------|
| `C:\Users\lizhe\.claude\skills\` | Active installed skills |
| `F:\PIMS\05_Code\0504_Scripts\Skills\` | Source repo for self-developed skills |
| `F:\PIMS\99_Inbox\` | Staging area for incoming skills |

## Post-Install Metadata (for GitHub-sourced skills)

After installation, inject into SKILL.md frontmatter:

```yaml
github_url: https://github.com/{owner}/{repo}
github_hash: {commit-sha}
github_branch: main
github_last_updated: {date}
```

This enables skill-manager's version monitoring.
