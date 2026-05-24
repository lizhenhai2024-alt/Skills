# 实习/求职 Skill 安装与运行要求

适用于 `intern-job-advisor`（通用版）和 `intern-job-advisor-daughter`（女儿定制版）两个 Skill。

---

## 一、Skill 文件本身（核心）

两个 Skill 的 SKILL.md 文件需放在以下位置即可被 Claude Code 加载：

| Skill | 路径 | 状态 |
|-------|------|------|
| 通用版 | `~/.claude/skills/intern-job-advisor/SKILL.md` | 已创建 v1.0.0 |
| 女儿定制版 | `~/.claude/skills/intern-job-advisor-daughter/SKILL.md` | 已创建 v1.4.0 |

**不需要额外安装任何软件包。** Skill 文件写好即用。

---

## 二、联网搜索能力（第一层搜索，必备）

| 工具 | 用途 | 是否需要安装 |
|------|------|-------------|
| WebSearch | 搜索岗位信息、薪酬基准、行业趋势 | **无需安装**，Claude Code 内置 |
| WebFetch | 定向抓取招聘页面和公司官网 | **无需安装**，Claude Code 内置 |

✅ **开箱即用，零配置。**

---

## 三、CDP 浏览器深度搜索（第二层搜索，强烈推荐）

当 WebSearch 返回的 JD 信息过简（仅有岗位名称没有详细职责），Skill 会启动 CDP 浏览器直达招聘平台获取完整 JD。

### 3.1 所需条件

| 依赖 | 用途 | 安装方式 |
|------|------|---------|
| **Node.js 22+** | CDP Proxy 运行环境 | `winget install OpenJS.NodeJS` 或官网下载 |
| **Chrome / Edge 浏览器** | 携带登录态访问平台 | 已有（日常使用即满足） |
| **web-access skill** | CDP 浏览器控制 | 已安装 `~/.claude/skills/web-access/SKILL.md` |

### 3.2 验证 Node.js 版本

```powershell
node -v
# 应输出 v22.x.x 或更高
```

低于 v22 需要升级：
```powershell
# 查看当前版本
node -v

# 升级方式选一：
# 1. winget 安装
winget install OpenJS.NodeJS

# 2. 或官网下载安装包
# https://nodejs.org/ 下载 LTS 版本
```

### 3.3 验证 web-access CDP 连接

```powershell
node "C:/Users/lizhe/.claude/skills/web-access/scripts/check-deps.mjs"
```

如果遇到提示 `WEB_ACCESS_BROWSER` 未设置，按提示配置：
```powershell
# 使用 Chrome
echo "WEB_ACCESS_BROWSER=chrome" > "C:/Users/lizhe/.claude/skills/web-access/config.env"

# 或使用 Edge
echo "WEB_ACCESS_BROWSER=edge" > "C:/Users/lizhe/.claude/skills/web-access/config.env"
```

### 3.4 浏览器登录态（按需）

CDP 使用日常浏览器，部分招聘平台需要提前登录才能查看完整 JD：

| 平台 | 登录要求 | 说明 |
|------|---------|------|
| 实习僧 | 推荐登录 | 未登录可搜索，完整 JD 需登录 |
| BOSS直聘 | 推荐登录 | 同上 |
| 牛客网 | 可选 | 实习信息较全，搜索不需要登录 |
| 公司官网招聘页 | 无需 | 公开可查看 |

**Skill 自带处理逻辑**：打开页面先尝试获取内容，拿不到时才会提示"请登录 XX 网站"。

---

## 四、数据文件

| 文件 | 路径 | 说明 |
|------|------|------|
| 进化档案 | `~/.claude/skills/intern-job-advisor/evolution.json` | 通用版进化记录 |
| 进化档案 | `~/.claude/skills/intern-job-advisor-daughter/evolution.json` | 女儿版进化记录 |

自动维护，无需手动操作。

---

## 五、不需要安装的（常见疑问）

| 名称 | 为什么不需要 |
|------|-------------|
| **cloakbrowser** | 反检测浏览器，招聘平台无 Cloudflare 级反爬，用 web-access 的真实浏览器即可 |
| **WeasyPrint / markdown** | PDF 转换库，hv-analysis（横纵分析）需要，求职 Skill 不需要 |
| **Playwright** | 自动化浏览器控制，patent-disclosure（专利交底书）需要，求职 Skill 不需要 |
| **Mermaid CLI** | 图表渲染，patent-disclosure 需要，求职 Skill 不需要 |
| **mammoth / python-pptx** | Office 文档转换，patent-disclosure 需要，求职 Skill 不需要 |

---

## 六、完整安装步骤（首次使用）

```powershell
# Step 1: 确认 Node.js 版本
node -v
# 期望输出: v22.x.x

# Step 2: 验证 CDP 连接
node "C:/Users/lizhe/.claude/skills/web-access/scripts/check-deps.mjs"

# Step 3: 浏览器配置（如果 check-deps 要求）
echo "WEB_ACCESS_BROWSER=chrome" > "C:/Users/lizhe/.claude/skills/web-access/config.env"

# Step 4: 重新验证（如果 Step 2 配置了 config.env）
node "C:/Users/lizhe/.claude/skills/web-access/scripts/check-deps.mjs"
```

**全部完成。** 不需要 pip install，不需要 npm install，不需要安装任何额外包。

---

## 七、一句话总结

**零安装，开箱即用。** 只需确保 Node.js 22+ 可用、浏览器正常、web-access CDP 连接验证通过，即可开始使用求职 Skill。
