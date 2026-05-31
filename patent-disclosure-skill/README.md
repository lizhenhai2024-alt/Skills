# Patent Disclosure Skill v2.0

## 概述

从项目文档到**可交付的技术交底书**的完整 skill，专为减振器/CDC/阀系/NVH 领域优化。

融合了：
- GitHub `patent-disclosure-skill` v1.8.5 的全流程框架（分步指令、Mermaid 图示、迭代模式、自检）
- 本地 ZF 减振器领域特化内容（写作模式、检索策略、分析框架）

## 流程

```
挖掘(Step 1-4) → 查新(Step 5) → 预览(Step 6) → 交底书(Step 7) → 自检(Step 8) → 迭代(合并/纠正)
```

## 快速开始

```
用户: 看一下我这几个设计图，有没有能报专利的点
→ 自动触发本skill，执行 Step 1-4 专利点挖掘

用户: 帮我把这个减振器消泡环写成交底书
→ 执行 Step 5-8 查新+撰写+自检

用户: 第6节的阀片厚度改成0.15mm
→ 自动进入迭代模式，走correction_handler
```

## 文件结构

```
patent-disclosure-skill/
├── SKILL.md                  # 主入口
├── README.md                 # 本文件
├── prompts/                  # 分步指令
│   ├── intake.md
│   ├── project_scan.md
│   ├── patent_points_analyzer.md
│   ├── prior_art_search.md
│   ├── disclosure_preview.md
│   ├── disclosure_builder.md
│   ├── template_reference.md      # Mermaid 范例
│   ├── disclosure_self_check.md
│   ├── iteration_context.md
│   ├── merger.md
│   └── correction_handler.md
├── references/               # 领域知识（13个文件）
│   ├── zf-writing-patterns.md           # ZF 写作模式
│   ├── disclosure-master-template.md    # 交底书模板
│   ├── search-strategy-and-keywords.md  # 检索策略
│   └── ...（更多）
├── scripts/                  # 工具脚本
│   └── generate_disclosure.py
└── assets/
    └── quick-check-template.md
```

## 安装

```bash
# 安装到项目的 skills 目录
cp -r patent-disclosure-skill .claude/skills/

# Python 依赖（基础）
pip install -r requirements.txt

# 可选：国知局查新（需要 Chromium）
pip install -r tools/requirements-cnipa.txt
python -m playwright install chromium

# Mermaid 依赖（Node.js）
npm install @mermaid-js/mermaid-cli
```