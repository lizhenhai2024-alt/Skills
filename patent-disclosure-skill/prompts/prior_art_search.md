# Step 5：联网查新

基于选定方案的核心技术特征，搜索现有专利/文献，判断新颖性和创造性。

## 搜索策略

执行前 Read `references/search-strategy-and-keywords.md` 和 `references/multilingual-patent-search.md`。

### 语义块构建

从方案中提取 2-8 个语义块，每个语义块包含：

```
语义块: [中文关键词] | [英文关键词]
CPC分类号提示（如有）
```

| 减振器常见 CPC | 含义 |
|---------------|------|
| F16F 9/32~9/34 | 减振器结构/阀系 |
| F16F 9/46~9/50 | 减振器控制/调节方法 |
| F16F 9/36~9/38 | 密封/导向/防尘 |
| B23K | 焊接工艺 |
| F16K 31/06 | 电磁阀 |

### 搜索层级（减振器专用降级策略）

1. **国知局公布公告站** → `tools/cnipa_epub_search.py`（优先，数据最全）
2. **Google Patents** → WebSearch 或直接访问 patents.google.com
3. **学术文献** → Google Scholar / CNKI（若涉及控制算法/材料）

## 国知局搜索（Cnipa）

依赖安装后使用：
```bash
pip install -r tools/requirements-cnipa.txt
python -m playwright install chromium
```

### 搜索规范

- **每次仅传一个语义块**，分多次调用 `cnipa_epub_search.py`
- 自行按 `pub_number` 合并多轮 `EPUB_HITS_JSON`（不要输出 HTML 落盘）
- `abstract` 字段必须使用

无 Cnipa 依赖时，降级为 WebSearch：`"关键词" site:cnipa.gov.cn`。

## 命中筛选

从结果中保留 3-10 个最强命中：

- 优先关注独立权利要求有重叠的
- 关注仍在有效期的（授权且维持）
- 关注在中国有同族专利的
- 不只看标题和摘要——打开代表性专利阅读权利要求

## 查新报告输出

```
查新报告
═══════════
检索日期: [date]
检索范围: 中国专利公布公告 + [补充来源]
检索语义块: [列表]
命中数: [total] | 深度分析: [N]

命中专利:
1. [公开号] [标题] [申请人] [法律状态]
   相关性: [一句话]
   与本案区别: [关键差异]

新颖性评估: [高/中/低]
创造性评估（三步法）:
  1. 最接近现有技术: [公开号]
  2. 区别技术特征: [列出]
  3. 是否显而易见: [判断]
风险等级: 低风险 / 中风险 / 高风险 / 信息不足
```

## 减振器领域搜索注意事项

- 检索日文关键词（减振器技术日本文献量大）：ショックアブソーバ / 減衰力 / バルブ / CDC
- 检索德文关键词（ZF 原厂 Patent）：Stoßdämpfer / Dämpfventil / Dämpfkraft
- 关注 ZF Sachs / KYB / Hitachi / Mando / Tenneco 的公开专利
- 如 ZF专利/ 目录下有相关 PDF，一并阅读作为现有技术比对

## 完成后

进入 Step 6 → `Read prompts/disclosure_preview.md`。如用户要求"直接写"可跳过 Step 6。