---
name: patent-disclosure-skill
version: "2.0.0"
description: >
  中国专利交底书全流程skill：从项目文档挖掘专利点→国知局查新→生成含Mermaid图示的技术交底书(.md+.docx)→自检→迭代修订。
  专为减振器/CDC/阀系/NVH/悬架/材料/工艺领域优化，内置ZF写作模式和检索策略。
  在用户提及 专利挖掘、专利点、技术交底书、交底书、查新、专利申请、现有技术对比、规避设计、
  减振器专利、阀系专利 等场景时启用。也响应 /patent-disclosure、/交底书 等斜杠指令。
  当用户意图是在已有交底书上继续修改时，自动进入迭代模式。
---

# 中国专利挖掘与交底书生成

本 skill 覆盖 **专利点挖掘 → 查新与差异化 → 交底书生成 → 自检完善 → 迭代修订** 全流程。

**领域深度：** 减振器（shock absorber）、CDC/ECDC 电控阀系、NVH、液压、材料工艺、悬架系统。内置 ZF 专利写作模式和产业检索策略。

**分步指令在 `prompts/`**，每步执行前 Read 对应文件。

---

## 主流程（执行顺序）

| 步骤 | 读取 | 任务 |
|------|------|------|
| Step 1 | `prompts/intake.md` | 边界澄清：明确技术范围、申请人、交付要求 |
| Step 2 | `prompts/project_scan.md` | 项目文档扫描：设计文档/图纸/实验报告/代码 → 提取发明素材 |
| Step 3–4 | `prompts/patent_points_analyzer.md` | 候选专利点识别 → 讨论融合 → 选定最终方案 |
| Step 5 | `prompts/prior_art_search.md` | 联网查新：优先国知局公布站，降级 WebSearch/Google Patents |
| Step 6 | `prompts/disclosure_preview.md` | 摘要预览（用户可选跳过） |
| Step 7 | `prompts/disclosure_builder.md` + `prompts/template_reference.md` | 生成完整交底书：含 Mermaid 系统框图(3.2)和流程图(3.4) |
| Step 8 | `prompts/disclosure_self_check.md` | 内部自检：逻辑闭环、公式参数一致性（不写入正文） |

**禁止在交底书正文中加入"自检清单"章节**——自检仅内部使用。

---

## 领域资源加载规则

根据当前案件的技术方向，在 Step 2 扫描完成后选择性加载以下 reference：

| 技术方向 | 必读 reference |
|---------|---------------|
| 所有案件 | `references/disclosure-master-template.md`（交底书章节模板） |
| 减振器/阀系/CDC | `references/zf-writing-patterns.md`（ZF 专利写作模式与术语规范） |
| 所有查新 | `references/search-strategy-and-keywords.md` + `references/multilingual-patent-search.md` |
| 新颖性/创造性判断 | `references/china-patentability-checklist.md` |
| 风险评估/规避 | `references/analysis_framework.md` + `references/design-around-playbook.md` |
| 布局策略 | `references/portfolio-layout-heuristics.md` |
| 智能检索系统 | `references/smart-search-system.md` |
| 实施路径 | `references/implementation-roadmap.md` |
| 缺失信息收集 | `references/questionnaire_guide.md` |
| 筛选→撰写衔接 | `references/screening-handoff-checklist.md` |

---

## 工具与数据来源

### Office 文档预处理

若扫描范围含 `.docx` / `.pptx`，Step 2 中先用本仓库工具转为 Markdown：

```bash
python3 tools/docx_to_md.py --input {path}.docx --output {dir}/{name}.md
python3 tools/pptx_to_md.py --input {path}.pptx --output {dir}/{name}.md
```

依赖：`pip install -r requirements.txt`（含 mammoth、python-pptx）。

### 查新检索（Step 5）

执行前先 `Read prompts/prior_art_search.md`。

- **优先**：中国专利公布公告站（epub.cnipa.gov.cn）→ `tools/cnipa_epub_search.py`
- **补充**：Google Patents / WebSearch
- **检索前**归纳 2-8 个高相关度语义块，分批查询
- **多语种检索**参考 `references/multilingual-patent-search.md`

Cnipa 依赖：`pip install -r tools/requirements-cnipa.txt` + `python -m playwright install chromium`。未安装时降级为纯 WebSearch。

### 交底书定稿交付（Step 7）

- **系统框图（3.2）与流程图（3.4）**：fenced `mermaid`，参照 `prompts/template_reference.md` 范例
- **Mermaid → PNG → .docx**：`tools/mermaid_render.py` 渲染后默认生成同名 .docx
- **若不需 Mermaid**：`tools/md_to_docx.py` 直接转换
- **Mermaid 依赖**：Node.js + `mmdc`（`npm install @mermaid-js/mermaid-cli` 或使用 `npx mmdc`）

### 文件保存路径

- 写入用户指定路径；未指定时建议 `./outputs/{案件标识}/`
- 交付文件命名：`{案件名}_{YYYYMMDDHHmmss}.md` 与同名 `.docx`（含首次定稿与迭代，勿默认覆盖旧稿）
- `outputs/` 整目录默认 `.gitignore`

---

## 迭代模式

当用户意图明显是在已有交底书上继续工作时（补充材料、修改章节、扩写实施例、修正参数/事实等），自动进入迭代模式——**无需**用户写出"迭代"等固定词。

### 路由规则

| 场景 | 读取 | 行为 |
|------|------|------|
| 补充材料 / 扩展章节 | `prompts/iteration_context.md` → `prompts/merger.md` | 合并增量内容，重新自检 |
| 指出错误 / 修正事实 | `prompts/iteration_context.md` → `prompts/correction_handler.md` | 逐条纠正，保留修正痕迹 |

### 迭代铁律

- **禁止**在迭代意图成立时回到 Step 3-4 做全文重新分析（除非用户明确要求）
- **另存为**新文件：`{案件名}_{YYYYMMDDHHmmss}.md` / `.docx`，**不覆盖**旧稿
- 每轮合并/纠正完成后，在案件目录**追加**`交底书修订对话记录.md`
- 完成后**必须**在对话中输出「合并摘要」或「纠正摘要」留档

---

## 进化记录 v1.0.0

**进化时间：** 2026-05-23
**进化来源：** 首次全量 SKILL 进化分析
**本次变更：**
- 创建 evolution.json，纳入进化管理体系

**学到的教训：**
> 专利交底书 skill 已相对成熟（v2.0.0），prompts/ 目录的分步设计合理，保持 evolution 兼容即可。

---

## 输出规约

### 交底书章节

```
0. 项目信息（含推荐标题、保护层级、拆案/双轨建议）
1. 所属技术领域
2. 背景技术（含最接近现有技术与本文要解决的问题）
3. 发明要解决的技术问题
4. 技术方案
  4.1 总体方案
  4.2 关键部件/步骤详述
5. 有益效果（对照现有技术的量化/定性提升）
6. 具体实施方式（至少一个完整实施例）
7. 附图清单与附图说明
8. 权利要求书骨架
9. 摘要骨架
附录：待补问题
```

### 事实边界

- **不编造**尺寸、材料牌号、参数范围、测试结果、法律结论
- 不确定的信息标为 `[待确认]` 并纳入 `待补问题`
- 引用专利：公开号/申请号 + 申请人 + 最相关的独立权利要求

---

## 减振器领域特殊约定

加载 `references/zf-writing-patterns.md`，遵循：

- 部件命名：统一使用行业术语（活塞、底阀、电磁阀、节流片、储能器……）
- 功能描述：力-速度曲线、阻尼力-电流特性、频率响应等用物理量表达
- 阀系结构：层级递归描述（主阀→先导阀→电磁铁→阀芯→节流口）
- 图例：剖面图按"外→内→外"或"上→下"顺序标注
- 参照 ZF 已有专利（`ZF专利/` 目录下 PDF）的附图风格和术语体系

---

## Agent 自检清单

```
□ 已按步骤 Read 对应 prompts
□ Step 2 若含 Office 文件，已执行 docx/pptx → md 并读了产出
□ Step 5 已归纳多语义块分批检索，合并了多轮结果
□ 识别到迭代意图时已走 merger/correction_handler，而非回到 Step 3
□ 迭代交付为新文件 `{案件名}_{时间戳}.md/.docx`，未覆盖旧稿
□ merger/纠正后已在对话输出留档摘要，案件目录已追加修订对话记录
□ 交底书正文不含"自检清单"章节
```