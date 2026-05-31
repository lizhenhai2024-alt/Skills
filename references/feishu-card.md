# 飞书交互卡片模板

仅飞书 bridge 环境使用。卡片格式：CardKit 2.0。

## 摘要卡片（搜索完成发送）
```json
{
  "schema": "2.0",
  "header": { "title": { "tag": "plain_text", "content": "🔍 岗位搜索摘要" }, "template": "blue" },
  "body": {
    "elements": [
      { "tag": "markdown", "content": "共找到 **X** 个适配岗位\n| # | 岗位 | 公司 | 地点 | 预估适配度 |\n|---|------|------|------|-----------||\n| 1 | 岗位名 | 公司 | 深圳 | 9/10 |" },
      { "tag": "action", "actions": [
        { "tag": "button", "text": { "tag": "plain_text", "content": "全部评估" }, "type": "primary", "behaviors": [{ "type": "callback", "value": { "__claude_cb": true, "action": "eval_all" } }] },
        { "tag": "button", "text": { "tag": "plain_text", "content": "只评估前5" }, "type": "default", "behaviors": [{ "type": "callback", "value": { "__claude_cb": true, "action": "eval_top5" } }] }
      ]}
    ]
  }
}
```

## 综合判断卡片（评估完成发送）
```json
{
  "schema": "2.0",
  "header": { "title": { "tag": "plain_text", "content": "📊 综合判断" }, "template": "indigo" },
  "body": {
    "elements": [
      { "tag": "markdown", "content": "| 类别 | 岗位 | 说明 |\n|------|------|------||\n| 最容易拿offer | XX | 原因 |\n| 未来最赚钱 | XX | 原因 |" },
      { "tag": "action", "actions": [
        { "tag": "button", "text": { "tag": "plain_text", "content": "查看完整报告" }, "type": "primary", "behaviors": [{ "type": "open_url", "default_url": "file:///outputs/report.html" }] }
      ]}
    ]
  }
}
```

## 颜色映射
| 评估结果 | template |
|---------|----------|
| 强烈推荐 | green |
| 推荐 | blue |
| 保底 | yellow |
| 不建议 | red |

## 单岗位评估卡片
与Markdown版内容相同，用JSON elements数组封装。评估表格+核心亮点+风险提示+投递建议，底部两个按钮：查看完整JD + 记录投递。
