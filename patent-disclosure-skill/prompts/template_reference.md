# 模板参考：Mermaid 图示范例

交底书 §3.2（系统框图）和 §3.4（流程图）使用 Mermaid 绘制，不使用 ASCII 框图 / PlantUML。

## 系统框图（减振器）

```mermaid
graph TB
    subgraph 电控减振器总成
        A[外筒] --- B[工作缸]
        B --- C[活塞总成]
        C --- D[活塞杆]
        B --- E[底阀总成]
        F[电磁阀总成] --- C
    end
    
    subgraph 电磁阀总成细节
        F --> G[先导阀]
        G --> H[电磁铁]
        H --> I[阀芯]
        I --> J[节流口]
    end
    
    E --- K[压缩阀片]
    E --- L[复原阀片]
```

## 系统框图（工艺）

```mermaid
graph LR
    A[来料检验] --> B[清洗]
    B --> C[装配定位]
    C --> D[焊接]
    D --> E[焊后热处理]
    E --> F[无损检测]
    F --> G[性能测试]
```

## 流程图（控制逻辑）

```mermaid
flowchart TD
    S1[ECU采集传感器信号] --> S2{车速 > 阈值?}
    S2 -->|是| S3[查询电流-阻尼力MAP]
    S2 -->|否| S4[保持默认电流]
    S3 --> S5{路面识别结果}
    S5 -->|舒适模式| S6[降低阻尼力]
    S5 -->|运动模式| S7[提高阻尼力]
    S6 --> S8[输出PWM驱动电磁阀]
    S7 --> S8
    S4 --> S8
    S8 --> S9[反馈实际电流值]
    S9 --> S1
```

## 流程图（方法步骤）

```mermaid
flowchart TD
    A[确定设计参数范围] --> B[建立有限元模型]
    B --> C[参数化扫描计算]
    C --> D[提取力-位移曲线]
    D --> E{误差 < 5%?}
    E -->|是| F[输出优化参数]
    E -->|否| G[调整网格/边界条件]
    G --> B
```

## Mermaid 块标记

在 .md 正文中的写法：

````markdown
### 3.2 系统框图

```mermaid
graph TB
    A[外筒] --- B[工作缸]
    ...
```

### 3.4 流程图

```mermaid
flowchart TD
    S1[开始] --> S2{判断}
    ...
```
````

**不**使用 PlantUML，**不**使用 ASCII 文字框图。

## 定稿渲染

```bash
python3 tools/mermaid_render.py --input disclosure.md
```

渲染依赖 `mmdc`（`npm install @mermaid-js/mermaid-cli` 或使用 `npx mmdc`）。内存不足时尝试加 `--puppeteerConfigFile .puppeteer.json`。