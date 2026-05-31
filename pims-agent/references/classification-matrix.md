# 分类决策矩阵

本文件定义文件类型到 PIMS 分类的决策树。引用 pims-km 规则编号，完整规则见 `pims-km/references/archive-rules.md`。

## 决策流程

```
输入文件 → G3跳过检查 → G7年龄检查 → 源路径匹配 → 扩展名匹配 → 关键词匹配 → 项目号正则 → 客户标准识别 → 默认路由
```

## 1. G3 跳过（不处理）

| 模式 | 示例 |
|:--|:--|
| 系统文件 | desktop.ini, thumbs.db, .DS_Store |
| 临时文件 | *.tmp, *.temp, ~$*, *.crdownload, *.part |
| 空文件 | size_bytes = 0 |
| 快捷方式 | *.lnk, *.url |

## 2. G7 年龄过滤

| 年龄 | 操作 |
|:--|:--|
| < 7天 | [跳过] 文件太新，可能还在使用 |
| 7-30天 | 正常归档 |
| > 30天 | 归档，标注"陈旧文件" |
| > 180天 | 归档，[需人工确认] |

## 3. 源路径匹配

| 源路径模式 | 规则 | 说明 |
|:--|:--|:--|
| `C:\Users\*\Downloads\*` | Rule 3 | 下载文件夹清理 |
| `C:\Users\*\Desktop\*` | Rule 3 | 桌面文件 |
| `C:\Users\*\Documents\*` | Rule 1+3 | 文档文件夹 |
| `*\DCIM\*`, `*\Camera\*` | Rule 2 | 手机照片/视频 |
| `*\WeChat*\*` | Rule 2+3 | 微信文件 |
| `F:\PIMS\99_Inbox\*` | 全规则 | 收件箱，应用所有规则 |

## 4. 扩展名匹配

### 工程文件 → 01_Work (Rule 1)

| 扩展名 | 目标子目录 | 置信度 |
|:--|:--|:--|
| .dwg, .dxf, .stp, .step, .catpart, .catdrawing, .catproduct, .prt, .asm, .sldprt, .sldasm | `0101_Projects\{客户}\{项目号}\Drawings\` | high |
| .xlsx + 含计算/calc/强度/校核/check/尺寸链 | `0101_Projects\{客户}\{项目号}\Calculations\` | high |
| .docx, .pdf + 含报告/report/分析/analysis/总结/summary | `0101_Projects\{客户}\{项目号}\Reports\` | medium |
| 含 DFMEA/DVP/验证计划/风险 | `0101_Projects\{客户}\{项目号}\DFMEA_DVP\` | high |
| .pptx, .ppt | `0101_Projects\{客户}\{项目号}\Presentations\` | high |

### 媒体文件 → 06_Media_Active (Rule 2)

| 扩展名 | 目标子目录 | 置信度 |
|:--|:--|:--|
| .jpg, .jpeg, .png, .heic, .heif, .raw, .bmp, .tiff | `0601_Photos\{YYYY-MM事件名}\` | high |
| .mp4, .mov, .avi, .mkv, .wmv | `0602_Videos\{YYYY-MM事件名}\` | high |
| .mp3, .flac, .wav, .aac, .m4a | `0603_Music\` | high |
| .psd, .ai, .svg, .indd | `0604_Design\` | high |

### 安装包/软件 → 07_Software (Rule 3)

| 扩展名 | 目标子目录 | 置信度 |
|:--|:--|:--|
| .exe, .msi, .msix | `0701_Installers\` | high |
| .zip, .rar, .7z (含 install/setup/portable) | `0701_Installers\` | medium |
| .zip, .rar, .7z (无关键词) | `0702_Archives\` | low |
| .iso, .img | `0701_Installers\` | high |
| .dll, .sys, .inf | `0703_Drivers\` | medium |

### 代码文件 → 05_Code

| 扩展名 | 目标子目录 | 置信度 |
|:--|:--|:--|
| .py, .js, .ts, .jsx, .tsx, .go, .rs, .java, .cpp, .c, .h | `0501_Python\` 或按语言 | high |
| .html, .css, .scss | `0501_Python\` (web项目) | medium |
| .json, .yaml, .yml, .toml, .xml | 看上下文 | low |
| .sql, .db, .sqlite | `0503_Datasets\` | medium |
| .ipynb | `0501_Python\` | high |

### 学习/阅读 → 03_Learning

| 扩展名+关键词 | 目标子目录 | 置信度 |
|:--|:--|:--|
| .pdf + 含课程/course/培训/training/教程/tutorial | `0301_Engineering\` 或 `0302_AI_LLM\` | medium |
| .pdf + 含AI/LLM/prompt/RAG/transformer/GPT | `0302_AI_LLM\` | high |
| .pdf + 含管理/APQP/DFMEA/项目管理 | `0303_Management\` | medium |
| .epub, .mobi | `0304_Books\` | high |

### 个人文档 → 02_Personal

| 关键词 | 目标子目录 | 置信度 |
|:--|:--|:--|
| 含银行/工资/发票/报销/financial | `0201_Finance\` | medium |
| 含体检/病历/用药/health | `0202_Health\` | medium |
| 含证件/户口/护照/family | `0203_Family\` | medium |
| 含书单/阅读/reading | `0204_Reading\` | medium |

### 知识库 → 04_Knowledge_Base (Rule 7)

| 条件 | 目标子目录 | 置信度 |
|:--|:--|:--|
| .md + 在 _Sources 中 | `0401-0440\` 按主题 | high |
| .pdf + 含客户标准号格式 | Rule 6 → `0102_Standards\` | high |
| .pdf + 含设计规则/失效/DR/FC | `04_Knowledge_Base\` 按主题 | medium |

## 5. 项目号正则匹配 (Rule 1.1)

| 正则 | 客户 | 目标 |
|:--|:--|:--|
| `BM\d{2,4}` | BMW | `0101_Projects\BMW\BM{N}\` |
| `BMW\d{2,4}` | BMW | `0101_Projects\BMW\BMW{N}\` |
| `GY\d{2,4}` | Geely | `0101_Projects\Geely\GY{N}\` |
| `Geely\d{2,4}` | Geely | `0101_Projects\Geely\Geely{N}\` |
| `TY\d{2,4}` | Toyota | `0101_Projects\Toyota\TY{N}\` |
| `Toyota\d{2,4}` | Toyota | `0101_Projects\Toyota\Toyota{N}\` |
| `HQ\d{2,4}` | Hongqi | `0101_Projects\Hongqi\HQ{N}\` |
| `Hongqi\d{2,4}` | Hongqi | `0101_Projects\Hongqi\Hongqi{N}\` |
| `BYD\d{2,4}` | BYD | `0101_Projects\BYD\BYD{N}\` |

## 6. 客户标准识别 (Rule 6)

| 标准号格式 | 标准 | 目标 |
|:--|:--|:--|
| `GS\d+-\d+` | BMW标准 | `0102_Standards\Customer_SOR\BMW\` |
| `Q/JW\d+` | 一汽标准 | `0102_Standards\Internal_TS\` |
| `GB/T?\s*\d+` | 国标 | `0102_Standards\GB_ISO_SAE\GB\` |
| `ISO\s*\d+` | ISO标准 | `0102_Standards\GB_ISO_SAE\ISO\` |
| `SAE\s*\w+` | SAE标准 | `0102_Standards\GB_ISO_SAE\SAE\` |
| `DIN\s*\d+` | DIN标准 | `0102_Standards\GB_ISO_SAE\DIN\` |
| `ASTM\s*\w+` | ASTM标准 | `0102_Standards\GB_ISO_SAE\ASTM\` |

## 7. 默认路由

未匹配任何规则的文件:

| 条件 | 目标 | 置信度 |
|:--|:--|:--|
| 扩展名已识别但无关键词 | `99_Inbox\To_Sort\` | low |
| 扩展名未识别 | `99_Inbox\To_Sort\` | low |
| 文件名含中文 | `99_Inbox\To_Sort\` + 标注中文 | low |

## 重复检测 (Rule 5)

5层识别，逐层提升:

| 层 | 方法 | 条件 |
|:--|:--|:--|
| L1 | 精确文件名 | 完全相同（忽略大小写） |
| L2 | 模糊文件名 | 相似度 ≥ 80%（Levenshtein） |
| L3 | Office元数据 | .docx/.xlsx/.pptx 内部 Author/Modified/Title |
| L4 | PDF元数据 | .pdf 内部 Title/Author/CreationDate |
| L5 | MD5哈希 | 完全相同 |

重复文件处理: 移至 `_Superseded\` 目录，保留最新版本在原位。
