---
name: skill-manager
description: 本地Skills的大管家，负责所有本地Skills的管理、查询、版本监控和删除
---

# Skill Manager - 技能管理器

## 概述

**你的Skills大管家，一站式管理所有本地Skills。**

功能清单：
1. 📋 Skills查询 - 以表格形式列出所有Skills的类型、描述、版本
2. 🔄 Skills版本监控 - 对比GitHub远程仓库，检查是否有更新
3. 🗑️ Skills管理 - 一句话删除不需要的Skills

## 触发场景

当你需要：
- 查看已安装的所有Skills列表
- 检查哪些Skills需要更新
- 删除不再使用的Skills
- 管理Skills的版本和状态

## 功能详解

### 1. Skills查询

**核心功能：** 生成美观的表格，列出所有Skills的详细信息。

**输出字段：**
| 字段 | 说明 |
|------|------|
| Skill名称 | Skill的文件夹名称 |
| 类型 | 区分「GitHub打包」或「本地创建」 |
| 描述 | Skill头部的description字段 |
| 版本 | 若有github_hash则显示，否则显示「本地版」 |

**实现步骤：**
1. 遍历 `~/.claude/skills/` 目录下的所有文件夹
2. 读取每个文件夹中的 `SKILL.md` 文件头部信息
3. 检测是否存在 `github_hash` 字段判断来源类型
4. 以Markdown表格形式输出结果

**判断逻辑：**
- 有 `github_hash` 字段 → GitHub打包的Skill
- 无 `github_hash` 字段 → 本地创建的Skill

---

### 2. Skills版本监控

**核心功能：** 对比本地Skill与GitHub远程仓库的版本差异。

**实现步骤：**
1. 读取本地Skill头部的 `github_hash` 和 `github_repo` 字段
2. 调用GitHub API获取远程仓库的最新commit hash：
   ```
   GET https://api.github.com/repos/{owner}/{repo}/commits/{branch}
   ```
3. 对比本地hash与远程hash
4. 输出版本状态表格

**状态定义：**
| 状态 | 含义 | 操作建议 |
|------|------|----------|
| ✅ 最新 | 本地与远程版本一致 | 无需操作 |
| ⚠️ 过期 | 远程有更新版本 | 建议更新 |
| ❓ 未知 | 本地无github_hash或API请求失败 | 无法检测 |

**注意事项：**
- GitHub API有请求频率限制，未认证用户60次/小时
- 若遇到限流，提示用户稍后再试或添加Token
- 对于非GitHub来源的Skill，直接标记为「本地版，不检测」

---

### 3. Skills管理（删除）

**核心功能：** 一句话删除指定的Skill。

**操作流程：**
1. 用户输入：「删除XXX这个skill」或类似表述
2. 确认待删除的Skill名称准确无误
3. 显示删除确认信息：
   > 确认删除 Skill: `{skill-name}`?
   > 
   > 描述: `{skill-description}`
4. 获取用户确认后执行删除
5. 输出删除结果：成功/失败

**安全机制：**
- **必须二次确认**，禁止直接删除
- 删除前备份至 `~/.claude/skills/.trash/{skill-name}.{timestamp}/`
- 支持误删恢复（手动从.trash目录恢复）

**删除命令（伪代码）：**
```bash
# 先备份
mv ~/.claude/skills/{skill-name} ~/.claude/skills/.trash/{skill-name}.{timestamp}
# 确认备份成功后再清理（可选，保留7天）
```

---

## 使用示例

### 示例1：查询所有Skills
**用户输入：**
> 列出我所有的skills

**输出：**
```markdown
## 📋 已安装的Skills列表

| # | Skill名称 | 类型 | 描述 | 版本 |
|---|----------|------|------|------|
| 1 | graphify | GitHub | any input to knowledge graph | abc1234 |
| 2 | hv-analysis | 本地 | 横纵分析法 | 本地版 |
| 3 | skill-manager | 本地 | Skills管理器 | 本地版 |

**总计：3个Skills，其中1个GitHub来源，2个本地创建**
```

### 示例2：检查版本更新
**用户输入：**
> 检查哪些skill需要更新

**输出：**
```markdown
## 🔄 Skills版本检测结果

| Skill名称 | 本地版本 | 远程版本 | 状态 |
|----------|----------|----------|------|
| graphify | abc1234 | xyz7890 | ⚠️ 过期 |
| structured-coding | def5678 | def5678 | ✅ 最新 |

**检测完成：1个Skill可更新，1个Skill已是最新版本**
```

### 示例3：删除Skill
**用户输入：**
> 删除test-skill这个skill

**输出：**
```markdown
## 🗑️ 删除确认

请确认删除以下Skill：
- **名称：** test-skill
- **描述：** 这是一个测试用的skill
- **类型：** 本地创建

确认删除吗？（是/否）
```

用户确认后输出：
> ✅ Skill `test-skill` 已成功删除（已备份至 .trash 目录）

---

## 常见问题处理

| 问题 | 处理方式 |
|------|----------|
| SKILL.md 读取失败 | 标记为「损坏」，提示用户检查文件 |
| GitHub API 限流 | 提示：「GitHub API请求受限，请稍后再试或配置Token」 |
| 删除时文件被占用 | 提示：「删除失败，文件可能被占用，请关闭相关程序后重试」 |
| Skill名称不明确 | 列出相似名称让用户选择 |

---

## 设计理念

> **「相当于我们以前的Mod或者插件管理器，只不过把更新迭代的过程也放在了对话里。」**

这个Skill的核心价值在于：
1. **可视化管理** - 再也不用面对一堆文件夹不知道干啥的
2. **自动化检测** - 不用手动去GitHub翻有没有更新
3. **安全删除** - 带备份机制的删除，不怕误操作
4. **对话式交互** - 所有操作都在自然语言对话中完成

**非常有用，非常方便。**

---

## 进化记录 v1.0.0

**进化时间：** 2026-05-23
**进化来源：** 首次全量 SKILL 进化分析
**本次变更：**
- 创建 evolution.json，纳入进化管理体系
- 待优化：增加实际执行能力（当前为说明文档，需配套可执行脚本）

**学到的教训：**
> 作为基础设施类 skill，仅靠文档说明不足以发挥价值，应考虑增加实际执行脚本。

---

## 自检清单

- [ ] 查询前确认了 skill 名称拼写正确
- [ ] 版本检查结果已向用户展示新旧版本差异
- [ ] 删除操作前已备份 skill 到 .trash 目录
- [ ] 没有误删其他用户的自研 skill
- [ ] 最终输出格式清晰（表格/列表）
- [ ] evolution.json 中的版本号与当前一致
