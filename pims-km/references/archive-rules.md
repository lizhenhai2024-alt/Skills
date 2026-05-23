# MASTER_ARCHIVE_RULES — 归档规则完整参考

## 全局规则（G1-G7）

### G1 — 安全原则
- **执行前必须列出操作计划，等待确认后再执行**
- 不删除任何文件，只执行移动/复制操作
- 同名文件冲突：保留两者，新文件加后缀 `_conflict_YYYYMMDD`
- 操作完成后输出结构化日志

### G2 — 文件名规范化
- 空格 → `_`
- 去除特殊字符（`!@#$%^&*`），保留中文、字母、数字、`-`、`_`、`.`
- 不修改扩展名大小写

### G3 — 跳过规则
- `.DS_Store` `desktop.ini` `thumbs.db`
- `~$*` `*.tmp` `*.temp`
- 被进程锁定的文件
- 大小为0的空文件

### G4 — 日志输出格式
```
[移动] 源路径 → 目标路径
[跳过] 文件路径 | 原因
[冲突] 文件路径 | 处理方式
[警告] 文件路径 | 说明
[需人工确认] 文件路径 | 原因
[错误] 文件路径 | 错误信息
汇总：移动N个，跳过N个，冲突N个，需人工确认N个，错误N个
```

### G5 — 预览模式优先
首次使用必须先用预览模式（只列方案，不移动文件）。

### G6 — PIMS编码对应
所有归档目标路径对应 PIMS 四位编码体系。

### G7 — 文件年龄处理阈值
| 年龄 | 操作 |
|:--|:--|
| < 7天 | 不处理 |
| 7-30天 | 按分类规则归档 |
| > 30天 | 归档，日志标注"陈旧文件" |
| > 180天 | 归档，日志单独列出，提示人工确认 |

---

## 规则一：工程文件归档（编码 0101）

### 触发范围
- 源：Downloads、桌面、Documents
- 目标：`{PIMS_ROOT}\01_Work\0101_Projects\`

### 1.1 项目号识别（优先级最高）
| 项目号格式 | 归档目标 |
|:--|:--|
| `BM****` `BMW****` | `BMW\[项目号]\` |
| `GY****` `Geely****` | `Geely\[项目号]\` |
| `TY****` `Toyota****` | `Toyota\[项目号]\` |
| `HQ****` `Hongqi****` | `Hongqi\[项目号]\` |
| `BYD****` | `BYD\[项目号]\` |

### 1.2 按扩展名+关键词归档
| 类型 | 条件 | 目标子目录 |
|:--|:--|:--|
| 图纸 | `.dwg` `.dxf` `.stp` `.step` `.catpart` `.catdrawing` | `Drawings\` |
| 计算书 | `.xlsx` + 含 计算/calc/强度/校核/check/尺寸链/dimensional | `Calculations\` |
| 报告 | `.docx` `.pdf` + 含 报告/report/分析/analysis/总结/summary | `Reports\` |
| DFMEA/DVP | 含 DFMEA/DVP/验证计划/风险 | `DFMEA_DVP\` |
| PPT | `.pptx` `.ppt` | `Presentations\`（培训/分享类→0306或0104） |
| 内部标准 | 含 TS-/FAWER-TS/企业标准 | `0102_Standards\Internal_TS\` |
| 客户要求 | 含 SOR/LAH/客户要求/技术要求 | → 进入规则六 |
| 通用标准 | 含 GB/ISO/SAE/DIN | `0102_Standards\GB_ISO_SAE\` |

### 1.3 AI版本文档处理
识别条件：文件名含 `v1`/`v2`/`最终`/`final`/`draft`/`修改`，或同基础名≥3个

处理：
- 修改时间最新的 → 重命名为 `MASTER_文件名.扩展名`
- 其余 → 移入项目目录下的 `_Superseded\`

跳过来源含 `_Sources`/`_Archive`/`_Backup` 的文件。

---

## 规则二：照片和视频归档（编码 0601）

### 触发范围
- 源：Downloads、Pictures、手机同步文件夹
- 目标：`{PIMS_ROOT}\06_Media_Active\0601_Photos\`

### 支持格式
- 图片：`.jpg` `.jpeg` `.png` `.heic` `.heif` `.raw` `.cr2` `.nef` `.arw`
- 视频：`.mp4` `.mov` `.avi` `.mkv` `.m4v`

### 日期提取优先级
1. EXIF 拍摄日期（DateTimeOriginal）
2. 文件名日期（`YYYYMMDD`/`YYYY-MM-DD`/`YYYY_MM_DD`）
3. 文件修改时间 → `_DateUnknown\`

### 归档结构
```
{PIMS_ROOT}\06_Media_Active\0601_Photos\YYYY\MM_月份名\[事件名]\
```
事件名识别：travel/旅行→`旅行_[目的地]`, family/家庭→`家庭`, birthday/生日→`生日`

### 重复处理
MD5相同 → `_Duplicates\`，不删除，等人工确认。

---

## 规则三：下载文件夹清理

### 触发范围
- 源：`C:\Users\*\Downloads`

### 分类规则
| 类型 | 条件 | 目标 |
|:--|:--|:--|
| 安装包 | `.exe` `.msi` `.dmg` `.pkg` | `07_Software\0702_Installers\` |
| 压缩包 | `.zip` `.rar` `.7z` `.tar.gz` | 解压识别内容，否则 `Downloads\_Archives\` |
| 字体 | `.ttf` `.otf` `.woff` | `Downloads\_Fonts\` |
| 论文PDF | `.pdf` + 含doi/期刊名格式 | `01_Work\0104_Reference\Papers\` |
| 客户标准 | 含标准识别关键词 | → 进入规则六 |
| 图片 | `.jpg` `.png` | → 进入规则二 |
| 工程文件 | 含项目号或工程关键词 | → 进入规则一 |

---

## 规则四：执行模式

| 模式 | 说明 |
|:--|:--|
| **预览模式**（默认） | 仅列方案，不移动。首次必须用此模式 |
| **执行模式** | 预览确认后，实际移动 |
| **单规则模式** | 只处理指定规则（如"只整理Downloads"） |
| **增量模式** | 只处理上次执行后新增的文件 |

---

## 规则五：重复版本处理（5层识别）

### 第一层：文件名完全相同 → 按修改时间
修改时间最新为主，其余移入 `_Superseded\`

### 第二层：文件名模糊匹配（≥80%）
去除日期/版本词（v1/final/最终/修改/revised/副本/(1)）/人名后缀后比较。
修改时间最新且文件最大的为主。

**特殊情况**：新文件比旧文件小>30%，日志标注 `[警告]`

### 第三层：Office元数据
读取 `.docx` `.xlsx` `.pptx` 修订次数，最高为主。

### 第四层：PDF元数据
读取 ModDate，最新为主。

### 第五层：MD5哈希兜底
- 完全相同：保留最新，其余注明"内容完全相同"入 `_Superseded\`
- 内容不同且无法判断：标注 `[需人工确认]`

### `_Superseded\` 命名规范
`原文件名_sup_YYYYMMDD.扩展名`

### 不自动处理的情况
| 情况 | 原因 |
|:--|:--|
| 新文件比旧文件小>30% | 可能是摘要版 |
| 文件名含 方案A/方案B | 并列方案 |
| 修改时间差<1小时 | 同期不同用途 |
| 含客户名/供应商名差异 | 不同提交方 |

### 版本台账
每次执行后更新 `_Superseded\_superseded_index.md`：
```markdown
| 主文件 | 过时版本 | 原修改时间 | 归档时间 | 识别方式 |
```

---

## 规则六：客户标准归档（编码 0102）

### 触发范围
- 源：Downloads、任意含客户标准的文件夹
- 目标：`{PIMS_ROOT}\01_Work\0102_Standards\Customer_SOR\`

### 5层识别机制

| 层级 | 识别方式 | 置信度 |
|:--:|:--|:--:|
| 1 | 来源文件夹路径关键词 | 高 |
| 2 | 文件名关键词 | 高 |
| 3 | 标准号格式 | 中高 |
| 4 | PDF正文前3页关键词 | 中 |
| 5 | ZIP解压后遍历子文件 | 兜底 |

**客户识别表：** BMW/BM/宝马→BMW, Toyota/丰田/TY→Toyota, Geely/吉利/GY→Geely, Hongqi/红旗/HQ→Hongqi, BYD/比亚迪→BYD, VW/Volkswagen/大众→VW

**文件类型识别：** SOR/整车要求→`SOR\`, LAH/LH/零部件规范→`LAH\`, Test/Testing/试验→`Testing\`, Drawing/图纸/GD&T→`Drawing_Standards\`

**标准号格式：** GS****/N****/QV****→BMW, TSM****/TSZ****/TMS****→Toyota, Q/GEE****/QGLY****→Geely, Q/FAW****/QC/T****→Hongqi/一汽, Q/BYD****→BYD

**通用标准：** GB****→`GB\`, ISO****→`ISO\`, SAE****→`SAE\`, DIN****/VDA****→`DIN_VDA\`, ASTM****→`ASTM\`

### 命名规范
`[客户]_[类型]_[标准号]_[版本]_[生效日期].pdf`

版本/日期无法识别时：版本→`V未知`，日期→`导入日期YYYYMMDD`

### 标准台账
自动维护 `Customer_SOR\_标准台账.md`

---

## 规则七：知识库整合迁移（编码 04）

### 6阶段执行

```
Step 0：备份（强制）→ 复制到 _Sources\
Step 1：扫描生成清单 → migration_inventory.md
Step 2：四层分类迁移（frontmatter → 标签 → 文件名 → 正文）
Step 3：Obsidian 双链修复（断链标注）
Step 4：文件名规范化（DR_/FC_/Calc_/DL_ 前缀）
Step 5：生成 _Inbox 辅助报告
Step 6：输出完整迁移日志
```

### 四层分类逻辑
| 优先级 | 方法 | 目标 |
|:--:|:--|:--|
| 1 | YAML frontmatter type字段 | 0401-0404 |
| 2 | Obsidian标签 | 0410-0490 子系统 |
| 3 | 文件名关键词 | 含规则→0401 / 失效→0402 / 计算→0403 / 决策→0404 |
| 4 | 正文前500字词频 | 关键词扫描 |

### 非 Markdown 文件处理
| 类型 | 处理 |
|:--|:--|
| .pdf | 按文件名+路径判断分类 |
| .xlsx + 计算关键词 | 0403_Calculations |
| .docx | 提取前500字走优先级4 |
| .py/.js/.html | 移至 05_Code |
| 其他 | `_Inbox\` |

### 文件名前缀规范
| 前缀 | 目录 |
|:--|:--|
| DR_ | 0401_Design_Rules |
| FC_ | 0402_Failure_Cases |
| Calc_ | 0403_Calculations |
| DL_ | 0404_Decision_Log |
| CDC_ | 0410_CDC |
| NVH_ | 0420_NVH |
| Sealing_ | 0430_Sealing |
| Structure_ | 0440_Structure |
| MOC_ | 知识库根目录 |
