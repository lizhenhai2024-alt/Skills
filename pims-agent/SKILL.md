---
name: pims-agent
description: >
  Autonomous PIMS file organization agent with dry-run, verification, and rollback.
  Automatically scans directories, classifies files per PIMS v3.1 rules (G1-G7, Rules 1-7),
  generates operation plans with dry-run verification, executes with full reversibility via
  operation journal, and supports one-command rollback.

  Trigger when: user mentions "auto-organize", "batch organize", "scan and classify",
  "dry-run organize", "PIMS agent", "autonomous organize", "organize inbox",
  "organize downloads", "batch archive", "rollback organize", "undo organize",
  "auto scan", "回滚整理", "撤销整理", "批量归档", "自动整理", "扫描分类",
  "干跑验证", "自治Agent", or wants to process large numbers of files without
  step-by-step confirmation. Also trigger when user asks to organize 99_Inbox,
  Downloads, or any directory with more than 20 files. Also trigger for
  "/pims-agent rollback" to undo a previous batch operation.
---

# Autonomous PIMS Agent

自动扫描驱动器、分类、dry-run验证、回滚的自治Agent。6阶段流水线：Scan → Classify → Dry-Run → Verify → Execute → Report。

## 配置

| 参数 | 默认值 | 说明 |
|:--|:--|:--|
| `auto_approve_threshold` | 500 | 验证通过后自动审批的文件数上限 |
| `journal_dir` | `F:\PIMS\00_System\_agent_journals\` | 操作日志存储目录 |
| `report_dir` | `F:\PIMS\00_System\_agent_reports\` | 执行报告存储目录 |
| `rollback_max_age_days` | 7 | 自动回滚的journal最大年龄(天) |
| `scan_default_path` | `F:\PIMS\99_Inbox` | 默认扫描目标 |
| `skip_age_days` | 7 | G7: 跳过小于此天数的文件 |
| `stale_age_days` | 30 | G7: 标记为陈旧的阈值 |
| `flag_age_days` | 180 | G7: 需人工确认的阈值 |
| `robocopy_threads` | 8 | 大批量Robocopy /MT线程数 |

## 命令模式

| 用户意图 | 命令 | 说明 |
|:--|:--|:--|
| 自动整理 | `/pims-agent [路径]` | 完整6阶段流水线，路径默认99_Inbox |
| 仅干跑 | `/pims-agent dry-run [路径]` | 只运行Stage 1-3，不执行 |
| 回滚 | `/pims-agent rollback --journal <路径>` | 回滚指定journal的操作 |
| 恢复中断 | `/pims-agent resume` | 从最近的未完成journal恢复执行 |

## 6阶段流水线

### Stage 1: Scan — 扫描

使用 `scripts/pims-agent-scan.ps1` 递归扫描目标目录。

- 输出: `scan_inventory.jsonl`（每行一个JSON：路径/扩展名/大小/时间/年龄分类/MD5）
- 应用 G3 跳过规则（desktop.ini, thumbs.db, .tmp, ~$*, 0字节文件）
- 应用 G7 年龄阈值（<7天跳过, 7-30天归档, >30天标注陈旧, >180天需人工确认）
- 幂等：若已有 inventory 且目标目录未修改，复用旧结果

### Stage 2: Classify — 分类

读取 `scan_inventory.jsonl`，按 `references/classification-matrix.md` 决策树分类。

- 决策优先级: 源路径 → 扩展名 → 关键词 → 项目号正则 → 客户标准识别
- 引用 pims-km 规则（Rule 1-7），按需读取 `pims-km/references/archive-rules.md` 获取完整规则
- 输出: `classification_plan.jsonl`（增加 target_path / rule / confidence / conflicts / action）
- 冲突处理: 目标已存在 → `_conflict_YYYYMMDD` 后缀（G1）
- 重复检测: Rule 5 五层识别（精确名→模糊≥80%→Office元数据→PDF元数据→MD5）
- 低置信度: confidence=low → `99_Inbox\To_Sort`

### Stage 3: Dry-Run — 干跑

生成完整操作计划，**不执行任何文件操作**。

- 输出1: `dry_run_report.md`（人类可读：汇总统计、分类分组、映射表、冲突/重复/待确认列表）
- 输出2: `operation_journal.jsonl`（机器可读：每行一个操作，含 op_id/type/source/target/status/rollback_info）
- Journal 存储到 `journal_dir`，文件名: `journal_YYYYMMDD_HHMMSS.jsonl`

### Stage 4: Verify — 验证

使用 `scripts/pims-agent-verify.ps1` 运行7项预检。

1. 目标父目录存在/可创建
2. 磁盘空间（目标盘剩余 > 10%）
3. 命名冲突复检
4. 源文件仍存在
5. 文件锁定检测
6. 跨盘移动标记（需 copy+delete）
7. 中文路径标记（需 .NET 方法）

**自动审批**: 验证零警告 + 文件数 < `auto_approve_threshold` → 自动进入 Stage 5。否则暂停等用户确认。

### Stage 5: Execute — 执行

按 `operation_journal.jsonl` 逐条执行文件操作。

- **策略**: <10文件用 Move-Item；10-500用 Robocopy `/E /MOVE /R:1 /W:1`；500+用 Robocopy `/MT:8`
- **每步**: 更新 journal entry (status=completed/failed, timestamp)，验证源删除/目标存在
- **G4 日志**: `[移动]`/`[跳过]`/`[冲突]`/`[错误]` 实时输出
- **可恢复**: 中断后重跑，读取 journal 跳过 completed，从第一个 planned 继续
- **跨盘**: 使用 copy → verify → delete_source（不直接 Move-Item 跨盘）
- **中文路径**: 使用 `[System.IO.File]::Move()` 替代 PowerShell cmdlet
- **MAX_PATH**: 使用 `\\?\` 前缀

### Stage 6: Report — 报告

- 输出: `execution_report.md` → `report_dir`
- 内容: 完成数/失败数/跳过数、G4日志全文、失败详情、回滚指令、磁盘空间变化
- 回滚指令: `使用 /pims-agent rollback --journal <journal路径>`

## 回滚

详见 `references/journal-format.md`。

- Journal 是回滚的唯一真相来源
- move → 反向移回；copy → 删除目标；mkdir → 空则删；rename → 改回原名
- 逆序遍历（LIFO），每步验证文件完整性
- 文件已被修改 → `[需人工确认]` 跳过
- Journal > 7天需手动指定

## 安全护栏

详见 `references/safety-guardrails.md`。

**硬限制（触碰即停）**:
- 目标盘剩余 < 10%、单次 >10,000 文件、单次 >50 GB
- 保护源目录: 00_System, _Sources, _Superseded
- 保护模式: .git, node_modules, __pycache__
- 跨盘移动必须 copy+verify+delete

**软限制（警告继续）**:
- 中文路径 → [System.IO]、MAX_PATH → \\?\ 前缀、文件锁定 → 跳过、低置信度 → To_Sort

**并发安全**: `.lock` 文件，同一时间仅一个实例

## 与 pims-km 的关系

- **不复制规则**: classification-matrix.md 引用 pims-km 规则编号，按需读取详情
- **日志格式兼容**: 使用相同的 G4 格式
- **版本文档协同**: 写入相同的 _superseded_index.md 和 _标准台账.md
- **范围不重叠**: pims-agent 只做归档/分类，不涉及建链/查询/SOP

## 自检清单

- [ ] 未使用 xcopy
- [ ] 每次批量操作后有文件数校验
- [ ] 无文件被静默丢弃到 _Unsorted
- [ ] 中文/特殊字符路径处理无误
- [ ] 执行前检查目标目录已有数据
- [ ] Journal 完整记录所有操作
- [ ] 回滚脚本可用且测试通过
- [ ] G4 日志格式正确输出
