# Operation Journal 格式规范与回滚协议

## Journal 文件

- 格式: JSONL（每行一个完整JSON对象）
- 编码: UTF-8 (无BOM)
- 存储: `{journal_dir}\journal_YYYYMMDD_HHMMSS.jsonl`
- 完整性: 每阶段完成后写入 SHA256 校验文件 `journal_YYYYMMDD_HHMMSS.sha256`

## 条目类型

### 1. mkdir — 创建目录
```json
{
  "op_id": 1,
  "type": "mkdir",
  "path": "F:\\PIMS\\01_Work\\0101_Projects\\BMW\\BM1234\\Reports",
  "status": "planned|completed|failed|skipped",
  "timestamp": "2026-05-24T14:30:00",
  "rule": null,
  "rollback": {
    "method": "rmdir_if_empty"
  }
}
```

### 2. move — 移动文件
```json
{
  "op_id": 2,
  "type": "move",
  "source": "F:\\PIMS\\99_Inbox\\BM1234_report_v2.docx",
  "target": "F:\\PIMS\\01_Work\\0101_Projects\\BMW\\BM1234\\Reports\\BM1234_report_v2.docx",
  "size_bytes": 1234567,
  "md5": "abc123...",
  "status": "planned|completed|failed|skipped",
  "timestamp": "2026-05-24T14:30:05",
  "rule": "Rule 1.1 + 1.2",
  "error": null,
  "rollback": {
    "method": "move_back",
    "source_was_deleted": true
  }
}
```

### 3. copy — 复制文件
```json
{
  "op_id": 3,
  "type": "copy",
  "source": "C:\\Users\\lizhe\\Downloads\\standard.pdf",
  "target": "F:\\PIMS\\01_Work\\0102_Standards\\GB_ISO_SAE\\standard.pdf",
  "size_bytes": 5678901,
  "md5": "def456...",
  "status": "planned|completed|failed|skipped",
  "timestamp": "2026-05-24T14:30:10",
  "rule": "Rule 3.4",
  "error": null,
  "rollback": {
    "method": "delete_target",
    "target_size": 5678901
  }
}
```

### 4. rename — 重命名文件（冲突处理）
```json
{
  "op_id": 4,
  "type": "rename",
  "original": "F:\\PIMS\\01_Work\\0102_Standards\\report.pdf",
  "renamed": "F:\\PIMS\\01_Work\\0102_Standards\\report_conflict_20260524.pdf",
  "status": "planned|completed|failed|skipped",
  "timestamp": "2026-05-24T14:30:12",
  "rule": "G1",
  "error": null,
  "rollback": {
    "method": "rename_back"
  }
}
```

## 状态流转

```
planned → completed  (操作成功)
planned → failed     (操作失败，error字段记录原因)
planned → skipped    (操作被跳过，如文件被锁定)
```

## 回滚协议

### 前提条件
1. Journal 文件存在且可读
2. Journal 年龄 < `rollback_max_age_days`（默认7天），超期需 `--force` 参数
3. 同一 journal 未被回滚过（检查是否有 rollback_report）

### 回滚流程
1. 读取 journal 文件
2. 过滤: 只处理 status=completed 的条目
3. **逆序遍历** (LIFO): 从最大 op_id 开始
4. 对每个条目执行回滚:
   - **mkdir**: 检查目录为空则删除，非空则跳过（[需人工确认]）
   - **move + move_back**: 将文件从 target 移回 source
   - **copy + delete_target**: 删除 target 文件（先验证大小匹配）
   - **rename + rename_back**: 将 renamed 改回 original
5. 每步完整性验证:
   - 文件 < 50MB: 验证 MD5 匹配
   - 文件 ≥ 50MB: 验证 size + modified time
   - 验证失败: 标记 [需人工确认]，跳过该条目
6. 写回滚报告

### 回滚安全
- 文件在原始操作后被修改 → 不自动回滚，标记 [需人工确认]
- 源位置已有新文件 → 不覆盖，标记 [需人工确认]
- 回滚操作本身也写入日志（rollback_report.jsonl）
- 回滚失败不中断，继续处理剩余条目

### 并发保护
- 执行期间创建 `{journal_dir}\.lock` 文件
- Lock 内容: PID + 启动时间
- 启动时检查 lock: 若进程不存在 → stale lock → 提示恢复或重新开始
- 回滚同样需要获取 lock
