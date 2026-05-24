# Network Recovery Strategies for China GFW

## Problem
GitHub, npm, and many web resources are blocked or throttled by China's GFW. This causes skill installations to fail with timeouts, connection resets, or extremely slow transfers.

## Proxy Detection (Windows)

The system has a Clash proxy at `127.0.0.1:11721` (detected from Windows registry). Use `scripts/detect-proxy.ps1` to check status:

```powershell
# Check proxy configuration
powershell -File detect-proxy.ps1 --test --json

# Enable proxy for current session
powershell -File detect-proxy.ps1 --enable
```

Detection priority: Environment variables > Windows registry > config.env > Default (127.0.0.1:11721)

## Recovery Cascade for GitHub Operations

```
Attempt 1: Direct git clone
  |  git clone --depth 1 https://github.com/user/repo
  |
  +-- FAIL (timeout / connection refused / SSL error)
      |
      v
Attempt 2: git clone with proxy
  |  git -c http.proxy=http://127.0.0.1:11721 -c https.proxy=http://127.0.0.1:11721 clone --depth 1 https://github.com/user/repo
  |
  +-- FAIL (proxy not running or still blocked)
      |
      v
Attempt 3: GitHub mirror (ghproxy.com)
  |  git clone --depth 1 https://ghproxy.com/https://github.com/user/repo
  |
  +-- FAIL
      |
      v
Attempt 4: Alternative mirror (gitclone.com)
  |  git clone --depth 1 https://gitclone.com/github.com/user/repo
  |
  +-- FAIL
      |
      v
Mark as FAILED, log specific error in report
```

## Recovery Cascade for npm Operations

```
Attempt 1: Default registry
  |  npm install
  |
  +-- FAIL
      |
      v
Attempt 2: With proxy
  |  npm install --proxy=http://127.0.0.1:11721 --https-proxy=http://127.0.0.1:11721
  |
      +-- FAIL
      |
      v
Attempt 3: npmmirror
  |  npm install --registry=https://registry.npmmirror.com
  |
      +-- FAIL
      |
      v
Mark as FAILED
```

## Retry Strategy

| Parameter | Value | Notes |
|-----------|-------|-------|
| Max retries | 3 | Per attempt in cascade |
| Initial delay | 2s | Before first retry |
| Backoff multiplier | 2x | 2s → 4s → 8s |
| GitHub API timeout | 30s | Rate limit: 60 req/hr unauthenticated |
| git clone timeout | 120s | Shallow clone (--depth 1) |
| npm install timeout | 60s | Per package |

## Available GitHub Mirrors

| Mirror | URL Pattern | Notes |
|--------|------------|-------|
| ghproxy.com | `https://ghproxy.com/https://github.com/...` | Most reliable in China |
| gitclone.com | `https://gitclone.com/github.com/...` | Alternative, may be slower |
| hub.nuaa.cf | `https://hub.nuaa.cf/...` | University mirror, intermittent |

## Available npm Mirrors

| Mirror | Registry URL | Notes |
|--------|-------------|-------|
| npmmirror | `https://registry.npmmirror.com` | Alibaba, most reliable in China |
| tencent | `https://mirrors.cloud.tencent.com/npm/` | Tencent Cloud |

## Key Rules

1. **Never retry the same command** after a network failure — always change strategy (add proxy, switch mirror)
2. **Distinguish network errors from content errors** — only network errors trigger the cascade
3. **Use shallow clones** (`--depth 1`) to reduce transfer size and timeout risk
4. **Set proxy per-command** for git (`-c http.proxy=...`) rather than modifying global config
5. **Test proxy health** before relying on it — the Clash proxy may not be running
6. **Log every attempt** with strategy and result for the consolidated report
