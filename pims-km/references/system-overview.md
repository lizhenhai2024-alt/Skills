# PIMS v3.1 — 系统架构与编码体系参考

## 五大设计原则

| 原则 | 含义 |
|:--|:--|
| **P1 — 单一入口** | 每类信息只有一个权威位置 |
| **P2 — 最小摩擦** | 捕获越简单越好，先存inbox后整理 |
| **P3 — 输出导向** | 存储对应使用场景 |
| **P4 — 渐进精炼** | 先粗后精，迭代优化 |
| **P5 — 3-2-1备份** | 3份×2介质×1异地 |
| **P6 — 预览后执行** | 任何操作先出方案再执行 |
| **P7 — 全程日志** | 每次操作输出结构化日志 |

## 四层存储架构

| 磁盘 | 容量 | 角色 | 核心定位 |
|:--|:--:|:--|:--|
| **C盘** | 273GB | 系统盘 | 仅系统+必需软件，保持≥60G空闲 |
| **D盘** | 200GB | 工作台 | 活跃项目+收件箱+缓存，30天归档 |
| **SSD** | 2TB | 主力库 | 完整资料+知识库+代码+活跃媒体 |
| **HDD** | 4TB | 冷归档 | 备份+媒体库+历史归档 |

数据流：`收集 → D盘(Inbox) → SSD(主力库) → HDD(冷归档)`

## 四位数字编码体系

格式：`一级(2位) 二级(2位) 自定义名称`（如 `01 01 Projects`）

### 一级编码

| 编码 | 目录 | 说明 |
|:--:|:--|:--|
| 00 | Index | 资料索引、总规则文件、台账 |
| 01 | Work | 项目/标准/模板/参考 |
| 02 | Personal | 财务/健康/家庭/阅读 |
| 03 | Learning | 课程/书籍/工程深化/AI-LLM |
| 04 | Knowledge_Base | 设计规则/失效案例/计算/决策/MOC |
| 05 | Code | Python/Git/数据/脚本 |
| 06 | Media_Active | 照片/视频/音乐(近1-2年) |
| 07 | Software | 便携/安装包/驱动 |
| 08 | Archive_Active | 活跃归档 |
| 99 | Inbox | 收件箱(待分类/待处理) |

### 二级编码

| 一级 | 二级 | 职能 |
|:--:|:--:|:--|
| 01 | 0101 | Projects — 按客户/项目号归档 |
| 01 | 0102 | Standards — Customer_SOR / Internal_TS / GB_ISO_SAE |
| 01 | 0103 | Templates — Reports / Calculations / Presentations |
| 01 | 0104 | Reference — Papers / Competitor / Benchmarks |
| 02 | 0201 | Finance — 加密 |
| 02 | 0202 | Health — 体检/用药/运动 |
| 02 | 0203 | Family — 证件(加密)/照片/旅行 |
| 02 | 0204 | Reading — 书单/笔记 |
| 02 | 0205 | Ideas — inbox.md / 个人项目 |
| 03 | 0301 | Engineering — NVH / Control / FEM |
| 03 | 0302 | AI_LLM — Prompt / RAG / Karpathy |
| 03 | 0303 | Management — APQP_DFMEA / Technical_Review |
| 03 | 0304 | Courses |
| 03 | 0305 | Books |
| 03 | 0306 | Output — 文章/演示 |
| 04 | 0401 | Design_Rules — 设计规则 |
| 04 | 0402 | Failure_Cases — 失效案例 |
| 04 | 0403 | Calculations — 计算方法 |
| 04 | 0404 | Decision_Log — 决策日志 |
| 04 | 0410-0490 | 子系统MOC — CDC/NVH/Sealing/Structure等 |
| 05 | 0501 | Python_Apps |
| 05 | 0502 | Git_Repos |
| 05 | 0503 | Datasets |
| 05 | 0504 | Scripts |
| 06 | 0601 | Photos — 年/月/事件 |
| 06 | 0602 | Videos |
| 06 | 0603 | Music |
| 06 | 0604 | Design |

## SSD 完整目录树

```
{PIMS_ROOT}\
├── 00_Index\
│   ├── 总目录清单.xlsx
│   ├── MASTER_ARCHIVE_RULES.md
│   ├── KB_LINK_BUILDER.md
│   ├── 标签体系说明.md
│   └── 快速参考卡.md
│
├── 01_Work\
│   ├── 0101_Projects\
│   │   ├── BMW\[项目号]\{Drawings,Calculations,Reports,DFMEA_DVP,Presentations}
│   │   ├── Geely\[项目号]\
│   │   ├── Toyota\[项目号]\
│   │   ├── Hongqi\[项目号]\
│   │   └── _Unsorted\
│   ├── 0102_Standards\
│   │   ├── Customer_SOR\{BMW,Toyota,Geely,Hongqi,BYD,_UnknownCustomer,_NeedsReview}
│   │   ├── Internal_TS\
│   │   └── GB_ISO_SAE\{GB,ISO,SAE,DIN_VDA,ASTM}
│   ├── 0103_Templates\{Reports,Calculations,Presentations}
│   └── 0104_Reference\{Papers,Competitor_Analysis,OEM_Benchmarks}
│
├── 02_Personal\
│   ├── 0201_Finance\ (★加密)
│   ├── 0202_Health\
│   ├── 0203_Family\ (★加密)
│   ├── 0204_Reading\
│   └── 0205_Ideas\
│
├── 03_Learning\
│   ├── 0301_Engineering\{NVH_Acoustics,Control_Theory,FEM_Simulation}
│   ├── 0302_AI_LLM\{Prompt,RAG,Karpathy_Methods}
│   ├── 0303_Management\{APQP_DFMEA,Technical_Review}
│   ├── 0304_Courses\
│   ├── 0305_Books\
│   └── 0306_Output\{Articles_Draft,Presentations}
│
├── 04_Knowledge_Base\ (Obsidian vault)
│   ├── 0401_Design_Rules\           # DR_ 前缀
│   ├── 0402_Failure_Cases\          # FC_ 前缀
│   ├── 0403_Calculations\           # Calc_ 前缀
│   ├── 0404_Decision_Log\           # DL_ 前缀
│   ├── 0410_CDC\                    # CDC_ 前缀
│   ├── 0420_NVH\                    # NVH_ 前缀
│   ├── 0430_Sealing\                # Sealing_ 前缀
│   ├── 0440_Structure\              # Structure_ 前缀
│   ├── _Inbox\
│   ├── _Sources\ (只读备份)
│   ├── _Templates\
│   ├── _link_build_log\
│   └── MOC_*.md
│
├── 05_Code\{0501_Python_Apps,0502_Git_Repos,0503_Datasets,0504_Scripts}
├── 06_Media_Active\{0601_Photos,0602_Videos,0603_Music,0604_Design}
├── 07_Software\{0701_Portable,0702_Installers,0703_Drivers}
├── 08_Archive_Active\
└── 99_Inbox\{To_Sort,To_Process}
```

## HDD 目录树

```
HDD:\
├── Backup\
│   ├── 001_C_Drive_Image\ (Dism++，每月)
│   ├── 002_SSD_Sync\ (FreeFileSync，每周)
│   └── 003_SSD_Image\ (月镜像)
├── Archive_Cold\
│   ├── 001_Photos_Archive\
│   ├── 002_Projects_Archive\
│   ├── 003_Old_Backups\
│   └── 004_Other\
├── Media_Library\{Movies,TV_Series,Documentaries,Music_Lossless}
└── Documents_Archive\
```

## 知识蒸馏模板

### DR — 设计规则
```markdown
---
type: design-rule
subsystem: [子系统]
created: YYYY-MM-DD
source: [项目/评审ID]
status: active | draft | superseded
---

# [规则标题]

## 问题描述 → 为什么要制定这条规则
## 规则内容 → 具体约束、参数范围、判断标准
## 适用范围 → 产品/平台/工况
## 例外情况 → 何时可偏离
## 验证方法 → 如何验证执行
## 关联 → [[相关案例]] [[相关规则]]
```

### FC — 失效案例
```markdown
---
type: failure-case
project: [项目名]
occurred: YYYY-MM-DD
severity: critical | major | minor
status: closed | tracking
---

# [案例名称]

## 现象 → 发生了什么
## 三维根因
1. 物理根因：材料/结构/工艺
2. 设计根因：方法/计算/经验
3. 管理根因：流程/评审/沟通
## 失效机理 → 物理/化学过程
## 纠正措施 → 已做什么
## 预防措施（横展）
- [ ] 是否更新了设计规则？→ [[0401_XX]]
- [ ] 是否需要在其他平台横展？
## 关联 → [[相关规则]] [[相关案例]]
```

### DL — 决策日志
```markdown
---
type: decision-log
project: [项目名]
decision-date: YYYY-MM-DD
status: verified | pending-verification
---

# 决策：[事项名称]

## 决策背景 → 约束条件？时间压力？
## 可选方案（表格对比）
| 方案 | 优点 | 缺点 | 成本影响 |
## 选择理由 → 最终选哪个？为什么？
## 事后验证 → 预期vs实际，偏差分析
## 经验提炼 → 下次该怎么做
## 关联 → [[参考规则]] [[规避案例]]
```

## SOP 维护清单

| 频率 | 内容 |
|:--|:--|
| **每日5分** | 文件命名规范化 → 想法记入 inbox.md → 桌面清空 |
| **每周30分** | 清空 inbox.md → 清理 Temp 缓存 → 一篇笔记输出 → 检查备份 |
| **每月1小时** | SSD→HDD全量同步 → 超30天未用文件归档 → C盘检查(≥60G) → 知识库git commit+push |
| **每季2小时** | 备份恢复演练(随机3文件) → 超2年旧媒体→HDD → C盘系统镜像 → 审视知识库结构 |
| **每年半天** | 全盘大整理 → 清理HDD超5年归档 → 年度四问 → HDD健康检查 |

## 工具清单

| 用途 | 工具 |
|:--|:--|
| 归档执行引擎 | MASTER_ARCHIVE_RULES + Claude Code |
| 知识链接引擎 | KB_LINK_BUILDER + Claude Code |
| 文件搜索 | Everything |
| 备份同步 | FreeFileSync |
| 系统镜像 | Dism++ |
| 知识管理 | Obsidian + Dataview + Templater + Git |
| 批量重命名 | Advanced Renamer |
| 磁盘加密 | VeraCrypt |
| 密码管理 | Bitwarden / KeePass |
| 磁盘健康 | CrystalDiskInfo |

## 文件命名速查

| 类型 | 格式 | 示例 |
|:--|:--|:--|
| 文件夹 | `[编码]_[名称]` | `0101_Projects` |
| 项目文件 | `YYYY-MM-DD_描述_v版本.ext` | `2026-05-21_报告_v2.1.docx` |
| 客户标准 | `[客户]_[类型]_[标准号]_[版本]_[日期].pdf` | `BMW_LAH_GS97030_V2019_20190601.pdf` |
| 知识笔记 | `[前缀]_[描述].md` | `DR_导向套lambda规范.md` |
| 照片 | `YYYY-MM-DD_事件_序号.jpg` | `2026-05-21_黄山_001.jpg` |
| 废弃版本 | `原名_sup_YYYYMMDD.ext` | `报告_sup_20260401.docx` |
| 冲突文件 | `原名_conflict_YYYYMMDD.ext` | `合同_conflict_20260521.pdf` |

## 冷启动30天

```
D1-D3  基础搭建：C盘瘦身 → SSD完整目录 → HDD目录 → 安装工具
D4-D10 资料归集：搜集到99_Inbox → 每天1-2个粗分类 → 02_Personal加密
D11-D20 知识激活：完成归类 → 写3篇知识模板(DR/FC/DL) → Obsidian+Templater配置
D21-D30 体系固化：首次全量备份 → 试运行SOP → 配置自动备份 → 初始双链
```
