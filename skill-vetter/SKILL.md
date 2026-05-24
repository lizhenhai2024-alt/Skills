---
name: skill-vetter
version: 2.0.0
user-invocable: true
description: "Multi-scanner security gate. TRIGGER when: user mentions installing, adding, or reviewing a skill to Claude Code, OpenClaw, or any other AI agent. Detects malicious code, vulnerabilities, and suspicious patterns. Use before installing any skill from ClawdHub, GitHub, or other sources."
---

# Skill Vetter 🔒

Multi-scanner security gate for AI agent skills. **Never install a skill without vetting it first.**

Ask the user: "Should I run skill-vetter on this before installing?" whenever they mention installing a new skill.

## When to Use

- Before installing **ANY** skill to Claude Code, OpenClaw, or other AI agents — whether from ClawHub, GitHub, or any external source
- Before running skills from GitHub repos
- When evaluating skills shared by other agents
- Anytime you are asked to install unknown code

## Vetting Protocol

### Step 1: Source Check

```
Questions to answer:
- [ ] Where did this skill come from?
- [ ] Is the author known/reputable?
- [ ] How many downloads/stars does it have?
- [ ] When was it last updated?
- [ ] Are there reviews from other agents?
```

### Step 2: Code Review (MANDATORY)

Read ALL files in the skill. Check for these **RED FLAGS**:

```
REJECT IMMEDIATELY IF YOU SEE:
-----------------------------------------
• curl/wget to unknown URLs
• Sends data to external servers
• Requests credentials/tokens/API keys
• Reads ~/.ssh, ~/.aws, ~/.config without clear reason
• Accesses MEMORY.md, USER.md, SOUL.md, IDENTITY.md
• Uses base64 decode on anything
• Uses eval() or exec() with external input
• Modifies system files outside workspace
• Installs packages without listing them
• Network calls to IPs instead of domains
• Obfuscated code (compressed, encoded, minified)
• Requests elevated/sudo permissions
• Accesses browser cookies/sessions
• Touches credential files
-----------------------------------------
```

### Step 3: Permission Scope

```
Evaluate:
- [ ] What files does it need to read?
- [ ] What files does it need to write?
- [ ] What commands does it run?
- [ ] Does it need network access? To where?
- [ ] Is the scope minimal for its stated purpose?
```

### Step 4: Risk Classification

| Risk Level | Examples | Action |
|------------|----------|--------|
| LOW | Notes, weather, formatting | Basic review, install OK |
| MEDIUM | File ops, browser, APIs | Full code review required |
| HIGH | Credentials, trading, system | Human approval required |
| EXTREME | Security configs, root access | Do NOT install |

## Output Format

After vetting, produce this report:

```
SKILL VETTING REPORT
=======================================
Skill: [name]
Source: [ClawdHub / GitHub / other]
Author: [username]
Version: [version]
---------------------------------------
METRICS:
• Downloads/Stars: [count]
• Last Updated: [date]
• Files Reviewed: [count]
---------------------------------------
RED FLAGS: [None / List them]

PERMISSIONS NEEDED:
• Files: [list or "None"]
• Network: [list or "None"]
• Commands: [list or "None"]
---------------------------------------
RISK LEVEL: [LOW / MEDIUM / HIGH / EXTREME]

VERDICT: [SAFE TO INSTALL / INSTALL WITH CAUTION / DO NOT INSTALL]

NOTES: [Any observations]
=======================================
```

## How to Run (Scripted Scan)

### Check dependencies first

```bash
bash {baseDir}/scripts/check-deps.sh
```

Fix any missing dependencies before proceeding.

### Run the full scan

```bash
bash {baseDir}/scripts/vett.sh "<skill-name-or-path>"
```

The argument can be:
- A ClawHub skill name: `youtube-summarize`
- A GitHub URL: `https://github.com/user/repo`
- A local path: `/tmp/my-skill/`

### Interpret Results

| Verdict | Meaning | Action |
|---------|---------|--------|
| **BLOCKED** | CRITICAL or HIGH findings | Do NOT install. Show findings. |
| **REVIEW** | Medium severity findings | Show findings, ask user to decide. |
| **SAFE** | All scanners passed | Proceed with installation. |

### After Verdict

Always show the user:
1. Which scanners ran
2. Which passed/failed
3. Specific findings for anything flagged
4. Your recommendation

**Never install the skill automatically.** Always confirm with the user after showing results.

## Scanners Used

| Scanner | What It Checks |
|---------|---------------|
| aguara | Prompt injection, obfuscation, suspicious LLM calls |
| skill-analyzer | Known malicious patterns, CVE database |
| secrets-scan | Hardcoded API keys, tokens, credentials |
| structure-check | Missing SKILL.md, malformed YAML, dangerous files |

## Dependencies

- `aguara` — Go-based prompt scanner
- `skill-analyzer` — Cisco AI skill scanner (Python)
- `python3` — For additional checks
- `curl`, `jq` — For API calls and JSON parsing

Run `check-deps.sh` to verify all tools are installed.

## Quick Vet Commands (Manual)

For GitHub-hosted skills:
```bash
# Check repo stats
curl -s "https://api.github.com/repos/OWNER/REPO" | jq '{stars: .stargazers_count, forks: .forks_count, updated: .updated_at}'

# List skill files
curl -s "https://api.github.com/repos/OWNER/REPO/contents/skills/SKILL_NAME" | jq '.[].name'

# Fetch and review SKILL.md
curl -s "https://raw.githubusercontent.com/OWNER/REPO/main/skills/SKILL_NAME/SKILL.md"
```

## Trust Hierarchy

1. **Official OpenClaw skills** → Lower scrutiny (still review)
2. **High-star repos (1000+)** → Moderate scrutiny
3. **Known authors** → Moderate scrutiny
4. **New/unknown sources** → Maximum scrutiny
5. **Skills requesting credentials** → Human approval always

## Remember

- No skill is worth compromising security
- When in doubt, do not install
- Ask your human for high-risk decisions
- Document what you vet for future reference

---

*Paranoia is a feature.*

---

## 自检清单

- [ ] 已读取待审查skill的全部文件（不只看SKILL.md）
- [ ] 4步审查协议（Source Check → Code Review → Permission Scope → Risk Classification）已逐条执行
- [ ] 重点检查了RED FLAGS列表中的各项（curl到未知地址、读取凭证文件、eval/exec等）
- [ ] 风险等级判断与审查结果一致
- [ ] 安装前已向用户展示了审查报告并获得了确认
- [ ] 未自动安装任何未经用户确认的skill

---

## 进化记录 v1.0.0

**进化时间：** 2026-05-23
**进化来源：** 首次全量 SKILL 进化分析
**本次变更：**
- 创建 evolution.json，纳入进化管理体系
- 确认技能已有完整的 Step 1-4 审查流程

**学到的教训：**
> 安全审查类 skill 的完善度高于预期，四个步骤均已覆盖，满足基本安全审查需求。

## 进化记录 v2.0.0

**进化时间：** 2026-05-24
**进化来源：** 同步远程仓库 app-incubator-xyz/skill-vetter 更新
**本次变更：**
- 升级为多扫描器架构（aguara/skill-analyzer/secrets-scan/structure-check）
- 新增脚本扫描支持：check-deps.sh、install.sh、vett.sh
- 新增脚本扫描结果解读（BLOCKED/REVIEW/SAFE 三档裁决）
- 保留原有手动审查流程（Step 1-4）作为无脚本环境下的备选
- 更新 description 和 version，新增 user-invocable 标记

**学到的教训：**
> 安全审查从纯人工走清单升级为脚本+人工双重保障。脚本可自动化检测已知恶意模式，人工审查仍需覆盖脚本无法判断的逻辑风险。
