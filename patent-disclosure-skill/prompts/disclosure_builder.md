# Step 7：交底书构建

生成完整技术交底书 Markdown 主文件。先 `Read references/disclosure-master-template.md` 获取章节模板；减振器案件额外 `Read references/zf-writing-patterns.md`。

## 章节结构

按以下顺序生成，严格遵守：

```
0. 项目信息
1. 所属技术领域
2. 背景技术（含现有技术→问题→本文目标）
3. 发明要解决的技术问题
4. 技术方案
  4.1 总体方案
  4.2 关键部件/步骤详述
5. 有益效果
6. 具体实施方式
7. 附图清单与附图说明
8. 权利要求书骨架
9. 摘要骨架
附录：待补问题
```

## 项目信息（第 0 章）

不仅写基本信息，还需给出专利策略建议：
- 推荐标题
- 保护层级：零部件 / 总成 / 系统 / 方法
- 是否建议拆案及按什么维度拆
- 是否建议发明+实用新型双轨
- 预计申请时间建议

## 图示（§3.2 系统框图 & §3.4 流程图）

**必须使用 fenced `mermaid`**，不使用 ASCII 文字框图，不使用 PlantUML。

Mermaid 语法范例见 `prompts/template_reference.md`。生成后：

```bash
# 渲染 Mermaid → PNG → 拼接生成 .docx
python3 tools/mermaid_render.py --input disclosure.md --output {案件名}_{时间戳}.docx
```

依赖：Node.js + `npm install @mermaid-js/mermaid-cli`（或使用 `npx mmdc`）。

## 定稿交付

### 命名规则（§7.3）

凡落盘交付文件：**`{案件名}_{YYYYMMDDHHmmss}`**
- Markdown: `{案件名}_{YYYYMMDDHHmmss}.md`
- Word: `{案件名}_{YYYYMMDDHHmmss}.docx`
- **含首次定稿与迭代版本**，不默认覆盖旧稿

### 生成 .docx

1. **有 Mermaid** → `tools/mermaid_render.py` 渲染 Mermaid → PNG + 拼接 → .docx
2. **无 Mermaid 或 Mermaid 失败** → `tools/md_to_docx.py` 直转 .docx
3. Mermaid 渲染失败的块保留围栏代码在正文中，不丢弃

详细见 `tools/README.md`。

## ZF 减振器写作注意事项

加载 `references/zf-writing-patterns.md`，重点遵循：

- **术语统一**：阻尼力（不用"减震力"）、复原行程/压缩行程、活塞杆/工作缸/外筒
- **层级描述**：阀系从"外→内"或"高压侧→低压侧"顺序
- **力-速度曲线**：区分低速段（节流）、中速段（阀开）、高速段（旁通）的不同物理机制
- **效果对比**：尽可能量化（如"降噪 3dB(A)"、"响应时间缩短至 10ms"）
- **参照 ZF 已有专利**的附图风格——如有参考专利 PDF，打开看图例标注方式

## 附图说明格式

每张图按 `图N-描述` 编号，附说明文字：

```
图1：电控减振器总体结构剖视图
 1-外筒, 2-工作缸, 3-活塞杆, 4-电磁阀总成, 5-消泡环, 6-底阀
```

图中标号与 Mermaid 节点 ID 或文字描述中的引用须一致。

## 完成后

进入 Step 8 → `Read prompts/disclosure_self_check.md`。