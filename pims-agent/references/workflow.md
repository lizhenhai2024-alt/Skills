# 6阶段工作流详细规范

## Stage 1: Scan — 扫描

### 输入
- 目标路径（默认 `F:\PIMS\99_Inbox`）
- 可选参数: `--age-filter` (覆盖G7阈值), `--extensions` (只扫描特定扩展名)

### 执行
调用 `scripts/pims-agent-scan.ps1`:
1. 递归枚举目标目录所有文件
2. 对每个文件计算属性:
   - `id`: 路径的SHA256哈希（前16位）
   - `source_path`: 完整路径
   - `filename`: 文件名
   - `extension`: 小写扩展名
   - `size_bytes`: 文件大小
   - `created`: 创建时间 (ISO 8601)
   - `modified`: 修改时间 (ISO 8601)
   - `age_days`: 距今天数（基于modified时间）
   - `age_category`: skip | archive | stale | flag
   - `md5`: 文件MD5哈希（>50MB文件只算size+mtime，不计算MD5以节省时间）
   - `parent_dir`: 父目录路径
3. 应用 G3 跳过规则，标记跳过的文件但不删除记录
4. 生成摘要: 总文件数/总大小/按年龄分类/按扩展名分类

### 输出
- `scan_inventory.jsonl` — 存储到 `{journal_dir}\{session_id}\`
- 控制台输出扫描摘要

### 幂等性
- 检查是否已有同目录的 `scan_inventory.jsonl`
- 比较目标目录的 LastWriteTime 与 inventory 的创建时间
- 若目录未修改，复用旧结果

---

## Stage 2: Classify — 分类

### 输入
- `scan_inventory.jsonl`
- `references/classification-matrix.md`（决策树）
- `pims-km/references/archive-rules.md`（按需加载完整规则）

### 分类流程
1. 读取 inventory，过滤 age_category=skip 的文件（标记为 [跳过]）
2. 对每个待分类文件，按决策树优先级匹配:
   a. **源路径匹配**: Downloads → Rule 3, 手机同步 → Rule 2, 99_Inbox → 全规则
   b. **扩展名匹配**: .dwg/.dxf/.stp → Rule 1, .jpg/.mp4 → Rule 2, .exe/.msi → Rule 3, .py/.js → 05_Code
   c. **关键词匹配**: 项目号(BM*/GY*/TY*/HQ*/BYD*) → Rule 1.1, DFMEA/DVP → Rule 1.2, SOR/LAH → Rule 6
   d. **PDF内容检测**: 需要时读取PDF前几页识别客户标准(Rule 6)或知识库内容(Rule 7)
3. 生成 target_path 基于 PIMS 编码体系
4. 冲突检测: 检查 target_path 是否已存在
5. 重复检测: Rule 5 五层识别
6. 置信度评估: high(规则明确匹配) / medium(扩展名+部分关键词) / low(无明确匹配)

### 输出
- `classification_plan.jsonl` — 每行增加:
  ```json
  {
    "target_path": "F:\\PIMS\\01_Work\\0101_Projects\\BMW\\BM1234\\Reports\\...",
    "classification_rule": "Rule 1.1 + 1.2",
    "confidence": "high",
    "conflicts": [],
    "duplicates": [],
    "action": "move"
  }
  ```

---

## Stage 3: Dry-Run — 干跑

### 输入
- `classification_plan.jsonl`

### 执行
1. 遍历 classification_plan，为每个文件生成操作条目
2. 对需要创建的目标目录生成 mkdir 操作
3. 对冲突文件生成 rename 操作（_conflict_YYYYMMDD）
4. 对重复文件生成 move to _Superseded 操作
5. 计算 op_id（递增序号）
6. 确定每条操作的 rollback_info

### 输出
- `dry_run_report.md`:
  - 汇总统计（N移动, N跳过, N冲突, N重复, N待确认）
  - 按目标分类分组表
  - 完整 source→target 映射表
  - 冲突列表及处理策略
  - 重复列表及版本追踪
  - 需人工确认项
  - 估算磁盘空间影响
- `operation_journal.jsonl`:
  - 每行格式见 `journal-format.md`
  - 存储到 `{journal_dir}\journal_YYYYMMDD_HHMMSS.jsonl`

### 关键约束
- **不执行任何文件操作**
- 不创建目录、不移动文件、不修改任何内容
- 只生成计划

---

## Stage 4: Verify — 验证

### 输入
- `operation_journal.jsonl`

### 7项预检
1. **目标路径验证**: 每个目标文件的父目录是否存在，若不存在是否可创建（检查权限）
2. **磁盘空间**: 每个目标盘汇总待写入大小，对比可用空间，需 > 10% 剩余
3. **命名冲突复检**: 重新检查目标路径是否已存在（dry-run后可能新增）
4. **源文件存在**: 重新检查源文件是否仍存在（可能被外部删除）
5. **文件锁定**: 尝试 `[System.IO.File]::Open(path, 'Open', 'Read', 'Read')` 检测锁定
6. **跨盘检测**: source 和 target 在不同盘 → 标记为 copy+delete 而非 move
7. **中文路径**: 检测路径中含非ASCII字符 → 标记使用 [System.IO] 方法

### 自动审批逻辑
```
if (零警告 AND 文件数 < auto_approve_threshold):
    自动进入 Stage 5
else:
    输出 verification_report.md
    暂停等待用户确认
```

### 输出
- `verification_report.md` — 通过/失败/警告列表
- 控制台输出验证结果

---

## Stage 5: Execute — 执行

### 输入
- `operation_journal.jsonl`（status=planned）

### 执行策略
| 文件数 | 方法 | 命令 |
|:--|:--|:--|
| <10 | PowerShell Move-Item/Copy-Item | `Move-Item -Force` / `Copy-Item -Force` |
| 10-500 | Robocopy 单线程 | `robocopy /E /MOVE /R:1 /W:1 /NFL /NDL /NP` |
| 500+ | Robocopy 多线程 | `robocopy /E /MOVE /R:1 /W:1 /NFL /NDL /NP /MT:8` |

### 逐条执行流程
1. 读取 journal，跳过 status=completed 的条目
2. 对 status=planned 的条目:
   a. 若为 mkdir → 创建目录
   b. 若为 move → 同盘用 Move-Item，跨盘用 copy+verify+delete
   c. 若为 copy → Copy-Item + 验证大小
   d. 若为 rename → Rename-Item
3. 每步操作后:
   - 更新 journal entry: status, timestamp
   - 验证: 源删除(对move) / 目标存在 / 大小匹配
   - 失败: status=failed, error=错误信息
4. G4 格式实时日志输出

### 可恢复性
- 中断后重跑: 读取 journal，跳过 completed，从第一个 planned 继续
- 部分完成的批次: 已完成的条目不受影响，只重新执行未完成的

### 特殊路径处理
- 中文路径: `[System.IO.File]::Move(source, target)` 替代 Move-Item
- MAX_PATH (>260): 使用 `\\?\` 前缀
- `&` in path: PowerShell 单引号包裹

---

## Stage 6: Report — 报告

### 输入
- `operation_journal.jsonl`（所有条目已处理）

### 报告内容
```markdown
# PIMS Agent 执行报告
日期: YYYY-MM-DD HH:MM:SS
Journal: {journal_path}

## 汇总
| 指标 | 数量 |
|:--|:--|
| 完成 | N |
| 失败 | N |
| 跳过 | N |
| 需人工确认 | N |

## 操作日志
（G4格式完整日志）

## 失败详情
| 文件 | 错误 |
|:--|:--|

## 磁盘空间变化
| 盘符 | 执行前 | 执行后 | 变化 |
|:--|:--|:--|:--|

## 回滚指令
使用 /pims-agent rollback --journal {journal_path}
```

### 输出
- `execution_report.md` → `{report_dir}\report_YYYYMMDD_HHMMSS.md`
- 控制台输出摘要
