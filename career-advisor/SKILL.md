---
name: career-advisor
description: >
  通用实习求职顾问（备选）— 与 intern-job-advisor 功能一致，当通用版未触发时后备。
  触发：岗位筛选、JD评估、求职建议、offer对比。响应 /career-advisor、/求职。
  **触发路由**：出海/英语→daughter版 | 其他方向→通用版 | 均未触发→本skill。
---

# 通用学生实习求职顾问（备选方案）

本 skill 是 **intern-job-advisor** 的备选版，核心框架完全相同。

## 框架摘要
1. **画像构建** — 专业/学校、年级、目标行业、技能、求职类型
2. **联网搜索** — A类(官网)CDP直达 / B类(聚合平台)WebSearch→CDP
3. **七步分析** — 岗位分类→九维评估→方向归类→关键词扫描→幽灵检测→推荐等级→职业路径
4. **薪酬评估** — WebSearch实时搜索行业薪资基准
5. **输出报告** — 逐个评估+综合判断+优先级排名

**完整分析框架详见 `intern-job-advisor` 的 SKILL.md。**

## 路由表

| skill | 定位 | 适用场景 |
|-------|------|----------|
| **intern-job-advisor-daughter** | 出海定制版 | 跨境电商/DTC/品牌出海，预设英语专业画像 |
| **intern-job-advisor** | 通用版 | 任意专业+行业，首选 |
| **career-advisor（本skill）** | 备选版 | 以上均未触发时后备 |

## 自检清单
- [ ] 画像5维度完整 | A类公司CDP直达 | 10维评估完整 | 分数有依据 | 薪资有来源 | 报告已写入outputs/含时间戳 | 无相对时间
