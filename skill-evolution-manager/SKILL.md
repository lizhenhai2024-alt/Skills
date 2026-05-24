---
name: skill-evolution-manager
description: Skill进化管理器(skill-evolution-manager)。当用户需要在对话结束时复盘优化Skills、根据用户反馈迭代改进Skill、总结对话经验沉淀到Skill文档、提取成功解决方案和失败教训、将非结构化反馈转为结构化经验数据(evolution.json)、智能缝合经验到SKILL.md文档、跨版本对齐经验数据(skill-manager更新后)、记录用户偏好和约束条件(preference learning)、诊断Skill表现问题、保存代码规范和最佳实践到Skill、执行经验复盘(review/extract)、增量合并经验数据(merge_evolution)、文档智能缝合(smart_stitch)等相关任务时立即使用。提供merge_evolution.py、smart_stitch.py、align_all.py等核心脚本实现经验持久化和跨版本兼容。
trigger:
  - Skill复盘
  - Skill优化
  - 经验沉淀
  - 迭代Skill
  - 对话复盘
  - 保存经验
  - evolution.json
  - 缝合文档
  - 经验提取
  - Skill进化
  - 跨版本对齐
  - 用户偏好学习
  - 诊断Skill
  - 代码规范保存
  - merge_evolution
  - smart_stitch
  - align_all
  - 经验持久化
  - 最佳实践记录
  - skill-evolution
---

# Skill Evolution Manager

**Skills的自我进化系统，让静态Skill随使用经验持续成长。** 通过外挂 `evolution.json`，记录对话中Skill的表现，自动迭代优化，实现「一坑不踩两次」。

## 触发场景

1. 对话结束时（用户说"结束""完成"）
2. Skill执行出错、未达预期
3. Skill表现出色、效果超预期
4. 用户提出改进建议
5. 用户说"复盘一下"、"保存经验"、/evolve

## 数据结构：evolution.json

```json
{
  "skill_name": "skill-name",
  "version": "1.0.0",
  "evolution_history": [
    { "timestamp": "2026-05-24T00:00:00+08:00", "type": "bugfix", "description": "修复X问题", "changes": ["修改A", "添加B"] }
  ],
  "lessons_learned": [
    { "id": "L001", "scenario": "场景", "problem": "问题", "solution": "方案", "first_occurred": "2026-05-24", "fixed_in_version": "1.1.0" }
  ],
  "pending_improvements": [
    { "idea": "优化建议", "priority": "medium", "suggested_by": "用户反馈", "noted_at": "2026-05-24" }
  ],
  "stats": { "total_evolutions": 0, "bugs_fixed": 0, "features_added": 0, "lessons_recorded": 0 }
}
```

- `type`: bugfix / feature / optimization / clarification
- `lessons_learned`: 踩过的坑和经验（核心：「一坑不踩两次」）
- `pending_improvements`: 待优化项

## 工作流程

### 阶段1：对话中默默记笔记

| 信号 | 记录条件 |
|------|---------|
| ❌ 错误 | Skill输出错误、用户说"这不对" |
| ⚠️ 瑕疵 | 结果可用但体验不好（格式乱、速度慢） |
| ✅ 亮点 | 用户说"这个好""就这么做" |
| 💡 建议 | 用户直接提改进意见 |
| 🤔 困惑 | 用户反复追问说明表述不清 |

### 阶段2：对话结束，写入进化档案

1. 整理临时笔记 → 去重、分类
2. 读取/创建 `evolution.json`
3. 写入 `lessons_learned`，更新 `evolution_history` 和 `stats`
4. 脚本持久化：`python {baseDir}/scripts/merge_evolution.py <skill_path> '<json_string>'`

### 阶段3：应用进化，更新SKILL.md

- 脚本缝合：`python {baseDir}/scripts/smart_stitch.py <skill_path>`
- 将 `evolution.json` 内容转化为 Markdown 追加到 `SKILL.md` 末尾

| 修改类型 | 位置 | 示例 |
|---------|------|------|
| 坑位规避 | 常见问题/注意事项 | 添加「遇到X时不要用Y」 |
| 流程补全 | 工作流程 | 插入缺失步骤 |
| 边界处理 | 异常处理 | 新增边界条件方案 |
| 示例补充 | 使用示例 | 添加正反例对比 |
| 描述优化 | 概述/触发场景 | 改写模糊表述 |

**修改格式**：每次进化后在文件末尾追加：

```markdown
## 进化记录 v{版本号}
**进化时间：** {时间}
**本次变更：**
- {变更1}
**学到的教训：**
> {核心经验}
```

## 进化等级体系

| 等级 | 次数 | 称号 |
|------|------|------|
| Lv.1 | 0 | 初生 |
| Lv.2 | 1-3 | 见习 |
| Lv.3 | 4-10 | 成熟 |
| Lv.4 | 11-20 | 老练 |
| Lv.5 | 21+ | 宗师 |

## 核心脚本

| 脚本 | 用途 |
|------|------|
| `scripts/merge_evolution.py` | 增量合并：读取旧JSON，去重合并新List，保存 |
| `scripts/smart_stitch.py` | 文档生成：读取JSON，在SKILL.md末尾生成最佳实践章节 |
| `scripts/align_all.py` | 全量对齐：遍历所有Skill，重新缝合经验回SKILL.md |

## 进化原则

### ✅ 应该进化
- 明确bug和错误
- 用户反复遇到的困惑点
- 多次出现的相同问题
- 流程中缺失的关键步骤

### ❌ 禁止自动进化
- 没有明确证据的"可能改进"
- 用户随口一提的想法
- 未经证实的假设
- 破坏核心功能的改动

## 最佳实践

- **不直接修改SKILL.md正文**（除拼写错误），通过 `evolution.json` 通道进行，保证升级时经验不丢失
- **多Skill协同**：一次对话涉及多个Skill时，依次为每个执行上述流程
- **跨版本对齐**：skill-manager更新后，运行 `align_all.py` 将之前保存的经验重新缝合到新版文档

## 进化记录 v1.0.0

**进化时间：** 2026-05-23
**进化来源：** 首次全量 SKILL 进化分析
**本次变更：**
- 创建 evolution.json
- 新增问题：SKILL.md仅有方法论说明，缺乏自动化执行支撑

**学到的教训：**
> 进化管理器自身也需要进化——从纯文档进化为可执行系统。

## 进化记录 v1.1.0

**进化时间：** 2026-05-24
**进化来源：** 同步远程仓库 galaxygx1983/skill-evolution-manager 更新
**本次变更：**
- 下载远程脚本：merge_evolution.py、smart_stitch.py、align_all.py
- 新增核心脚本说明表
- 新增跨版本对齐章节
- 新增最佳实践

**学到的教训：**
> 进化管理器从纯文档升级为脚本+文档双驱动。脚本保证经验持久化，文档保证方法论可理解。

## 自检清单

- [ ] 本次对话产生了值得沉淀的新经验（非重复已有内容）
- [ ] evolution.json 追加后验证了 JSON 格式正确
- [ ] lessons_learned 是具体教训而非空话（"不要XXX"而非"注意XXX"）
- [ ] 没有把单次事故记录成通用经验
- [ ] 跨版本对齐（align_all.py）已执行
- [ ] 智能缝合（smart_stitch.py）没有破坏 SKILL.md 已有结构
