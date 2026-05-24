---
domain: anker-in.com
aliases: [安克创新, Anker Innovations, career.anker-in.com]
updated: 2026-05-24
---

## 平台特征

- 安克创新运行两套招聘系统：
  - **飞书旧站** `anker-in.jobs.feishu.cn/189381/position/` — **已停用，显示0岗位**
  - **自建新站** `career.anker-in.com` — Gatsby SSR + React SPA，入口页无岗位列表，需导航到 `/universities/recruitment/new/?channel=internship`
- 新站前端是 Gatsby 应用，岗位表组件通过后端API加载，**不依赖飞书API**
- 新站页面DOM渲染有时不完整（Gatsby路由切换后组件未挂载），但API接口始终可用

## 有效模式

### 直接API调用（推荐，零CDP开销）

**岗位列表API**：
```
POST https://open.anker-in.com/service/lark/openapi/getJobPosts/{websiteId}?page=1&size=1000
Content-Type: application/json

Body:
{
  "job_function_id": [],
  "city_code": [],
  "subject_id": ["{subjectId}"],  // 项目ID
  "language_key": [],
  "keywords": ""
}
```

**关键ID**：
| 参数 | 值 | 含义 |
|------|------|------|
| websiteId | `7268177039772633400` | 校招站 |
| subjectId (校招) | `7597623693837879590` | 校园招聘 |
| subjectId (实习) | `7585117336022829322` | 实习招聘 |
| subjectId (航海计划) | `7537217835232594215` | 战略人才 |
| subjectId (海外) | `7537217743793703214` | 海外招聘 |

**其他可用API**：
- `GET https://rainbowbridge.anker.com/api/lark/hire/v1/job_functions?websiteId=7268177039772633400` — 职能分类列表
- `GET https://rainbowbridge.anker.com/api/lark/hire/v1/sites/7268177039772633400/job_cities` — 城市列表
- `GET https://rainbowbridge.anker.com/api/lark/hire/v1/websites/{websiteId}/job_posts/{jobPostId}` — 单岗详情

### CDP浏览（API不可用时的备选）

1. 打开 `career.anker-in.com/universities/recruitment/new/?channel=internship`
2. 页面可能不渲染岗位表（Gatsby路由问题），此时应回退到API方式
3. 如果页面成功渲染，搜索框和分类筛选可用

### API逆向方法（通用）

当SPA页面显示0岗位时：
1. CDP提取 `performance.getEntriesByType('resource')` 中的API URL
2. 下载主JS chunk（文件名含 `universities-job-table`）
3. 搜索 `getJobPosts`、`/api/lark/hire`、`open.anker-in.com` 定位接口
4. 提取 websiteId 和 subjectId 参数
5. 用Python `urllib.request` 直接调用

## 已知陷阱

- **飞书旧站已停用**：`anker-in.jobs.feishu.cn/189381/position/` 显示 `Find Your New Job (0)`，不要浪费时间在此页面
- **Gatsby页面渲染不稳定**：新站路由切换后DOM可能不更新，`document.body.innerText` 返回入口页内容而非岗位表
- **CORS限制**：前端JS中 `fetch` 调用 `open.anker-in.com` 会被CORS拦截，必须用Python/PowerShell等后端方式调用
- `rainbowbridge.anker.com` 的 `/job_posts/search` 接口需要飞书 `tenant_access_token`，而 `open.anker-in.com` 的 `/getJobPosts/` 接口无需鉴权
