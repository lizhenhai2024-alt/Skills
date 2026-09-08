<div align="center">

# Bruce Li · Automotive Chassis & Damper Engineering

**Suspension · Shock Absorbers · Electronic Dampers · Engineering AI**

把汽车底盘工程经验、确定性计算、试验数据分析与 AI 工作流结合起来，做真正能进入工程研发流程的工具。

*Automotive chassis engineer building practical tools for suspension, damper development, engineering analysis, and AI-assisted R&D.*

</div>

---

## What I build

我关注的不只是“让 AI 回答工程问题”，而是把工程问题拆成 **物理模型 → 数据 → 计算 → 校核 → 独立复核 → 可追溯结论**，再把这些流程沉淀成可重复使用的软件与工作流。

- **Damper & Suspension Engineering** — 被动减振器、CDC / 半主动减振器、液压阀系、弹簧、密封、噪声与耐久分析
- **Engineering AI** — Analyst / Reviewer 双角色、确定性计算器、证据链、数据策略与可追溯工程分析
- **Test Data Tools** — 试验数据清洗、循环识别、阻尼力评价、气体反弹力修正、工程图表与 Excel 输出
- **Patent Intelligence** — 专利检索、竞品结构理解、附图中文标注、专利布局与工程规避研究

---

## Featured projects

| Project | What it does | Focus |
|---|---|---|
| **[Damper Engineering AI Workbench](https://github.com/lizhenhai2024-alt/Damper-Engineering-AI-Workbench)** | 用 Analyst → independent Reviewer → deterministic Python calculator 的工作流验证 AI 在减振器工程分析中的可靠性 | Engineering AI · FastAPI · Python |
| **[CDC Zero Position Force Analyzer](https://github.com/lizhenhai2024-alt/CDC-Zero-Position-Force-Analyzer)** | Windows 单机 CDC 试验数据处理：电流工况识别、完整循环识别、中心窗口阻尼力评价、气体反弹力修正与 Excel 输出 | CDC · Test Data · PySide6 |
| **[Patent Figure CN Annotation](https://github.com/lizhenhai2024-alt/patent-figure-cn-annotation)** | 在保持原始专利技术图结构不变的前提下，为机械专利附图增加中文零件名称并进行布局检查 | Patent · Mechanical Drawing · Python |
| **[AI Job](https://github.com/lizhenhai2024-alt/AI_Job)** | 面向校招/求职场景的 AI 岗位匹配与决策辅助项目 | AI Application · Product Experiment |

---

## Engineering focus

```text
Vehicle Dynamics / Suspension
        ↓
Damper Architecture
        ↓
Hydraulic Path & Valve System
        ↓
Force / Pressure / Flow / Friction Models
        ↓
DVP · DOE · DFMEA · Durability · NVH
        ↓
Test Data & Evidence
        ↓
Engineering Decision
```

当前重点方向包括：

**Electronic dampers** — CDC、先导比例电磁阀、主阀 / 软阀、压力与流量、响应特性、温度效应、抖动与液压噪声。

**Mechanical & hydraulic design** — 阀片、弹簧、O 型圈、PTFE 摩擦副、孔口/流道、液压压力边界与耐久设计。

**Engineering methods** — APQP / DVP / DFMEA / DOE / 8D / 5WHY，以及面向研发 Gate 的证据链和输出物管理。

---

## Engineering AI philosophy

> **AI should not replace engineering judgment. It should make engineering reasoning more explicit, testable, and reviewable.**

我更关注下面这些问题：

- 模型给出的结论是否有明确的物理依据？
- 数值是否来自可复算的确定性计算，而不是模型“口算”？
- 假设、证据、计算结果和推断是否被清楚分层？
- 第二个 Reviewer 是否能独立发现第一份分析的漏洞？
- 工程输出能否进入真实的设计、试验、评审和问题解决流程？

---

## Tools & workflow

**Engineering:** Python · NumPy · Pandas · openpyxl · PySide6 · FastAPI · HTMX · pytest

**R&D workflow:** GitHub · Markdown · structured prompts · deterministic calculators · local knowledge base · Zotero-assisted research

**Domains:** Suspension · Dampers · CDC · Hydraulic Valves · Solenoids · Springs · Sealing · NVH · Durability · Patent Analysis

---

## Current work

- 完善 **Damper Engineering AI Workbench** 的真实 Golden Cases、工程计算器和 Blind A/B 评价机制
- 开发 **CDC Zero Position Force Analyzer**，把常规减振器台架数据处理规则软件化
- 构建面向减振器 / 电磁阀 / 主动悬架的 **专利与论文研究工作流**
- 将长期工程经验逐步沉淀为可验证的计算工具、设计规则和 AI Skills

---

<div align="center">

**Engineering first. AI second. Evidence always.**

[Repositories](https://github.com/lizhenhai2024-alt?tab=repositories) · [Damper AI Workbench](https://github.com/lizhenhai2024-alt/Damper-Engineering-AI-Workbench) · [CDC Analyzer](https://github.com/lizhenhai2024-alt/CDC-Zero-Position-Force-Analyzer)

</div>
