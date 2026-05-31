# 安全护栏

## 硬限制（触碰即停，不执行任何操作）

| # | 限制 | 阈值 | 原因 |
|:--|:--|:--|:--|
| H1 | 目标盘剩余空间 | < 10% | 防止磁盘满导致系统不稳定 |
| H2 | 单次文件数上限 | 10,000 | 防止失控批量操作 |
| H3 | 单次总大小上限 | 50 GB | 防止意外大迁移 |
| H4 | 保护源目录 | `00_System`, `_Sources`, `_Superseded`, `.obsidian` | 这些目录为只读/系统目录，不可移动 |
| H5 | 保护文件模式 | `.git/`, `node_modules/`, `__pycache__/`, `.venv/` | 非用户数据，移动会破坏项目 |
| H6 | 跨盘移动方式 | 必须使用 copy → verify → delete_source | Move-Item 跨盘失败会丢数据 |
| H7 | 禁止操作 | 不删除文件，不修改文件内容 | 只移动/复制/重命名 |

## 软限制（警告但可继续）

| # | 限制 | 处理方式 |
|:--|:--|:--|
| S1 | 中文路径 | 切换到 `[System.IO.File]::Move()` / `[System.IO.File]::Copy()` |
| S2 | 目标路径 > 230 字符 | 警告并尝试缩短路径名，若仍超 260 则使用 `\\?\` 前缀 |
| S3 | 文件被锁定 | 跳过该文件，日志 [错误]，继续处理其他文件 |
| S4 | 低置信度分类 | 路由到 `99_Inbox\To_Sort`，日志 [需人工确认] |
| S5 | 单文件 > 500MB | 日志 [警告]，正常执行 |
| S6 | 目标目录已有同名文件 | 添加 `_conflict_YYYYMMDD` 后缀 |
| S7 | Robocopy 非零退出码 | 检查是否为成功码(0-7)，非成功码标记为失败 |

## 保护目录清单

以下目录中的文件**永远不会被移动**:

```
F:\PIMS\00_System\*           # PIMS系统文件
F:\PIMS\04_Knowledge_Base\_Sources\*  # 只读备份源
F:\PIMS\*\*\_Superseded\*     # 已被取代的旧版本
F:\PIMS\.claude\*             # Claude配置
F:\PIMS\.obsidian\*           # Obsidian配置
**/\.git\*                    # Git仓库
**/\node_modules\*            # Node依赖
**/\__pycache__\*             # Python缓存
**/\.venv\*                   # Python虚拟环境
```

## 保护文件扩展名

以下文件类型**不会被处理**:

```
desktop.ini, thumbs.db, .DS_Store
*.tmp, *.temp, ~$*            # 临时文件
*.lnk, *.url                   # 快捷方式
*.crdownload, *.part           # 未完成下载
```

## 并发安全

### Lock 文件
- 路径: `{journal_dir}\.lock`
- 内容: `{"pid": 12345, "started": "2026-05-24T14:30:00", "session_id": "..."}`
- 获取: 启动时检查，若不存在则创建
- 冲突: 若存在且进程仍运行 → 报错退出；进程已死 → stale lock，提示用户选择

### 互斥
- 同一时间只允许一个 pims-agent 实例
- pims-organize 不受此限制（它是交互式的，不做批量操作）

## 文件操作约束（来自 CLAUDE.md）

- **禁止 xcopy** — 中文路径和特殊字符会静默失败
- **Robocopy 参数**: `/E /MOVE /R:1 /W:1 /NFL /NDL /NP`
- **大批量**: 追加 `/MT:8` 启用多线程
- **MAX_PATH**: 使用 `\\?\` 前缀
- **中文路径**: 优先使用 `[System.IO]` .NET 方法
- **操作后验证**: 对比源和目标文件数
- **已有数据**: 目标有预存数据时用 copy-verify-delete-source 而非 Move-Item

## 异常处理

| 异常 | 处理 |
|:--|:--|
| 源文件不存在 | 跳过，标记 failed |
| 目标目录无法创建 | 跳过该文件，标记 failed，检查权限 |
| 磁盘空间不足 | 停止整个批次（H1） |
| 文件被锁定 | 跳过，标记 skipped |
| 权限不足 | 尝试 [System.IO] 方法，若仍失败则标记 failed |
| 路径过长 | 尝试 \\?\ 前缀，若仍失败则标记 failed |
| 网络驱动器断开 | 停止整个批次 |
