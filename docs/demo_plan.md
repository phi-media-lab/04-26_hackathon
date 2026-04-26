# 现场展示计划

比赛要求包括现场烹饪演示和 10 分钟项目汇报。展示重点应服务评分标准，而不是只展示训练日志。

## 1. 展示目标

核心信息：

```text
我们用遥操作采集数据，但不是用遥操作完成任务。
我们把示范数据训练成 ACT policy，并部署到 reComputer / 近端 GPU，驱动 reBot 执行烹饪动作 primitive。
```

## 2. 现场演示优先级

优先展示稳定动作，而不是追求所有动作串联都完美。

建议顺序：

1. 展示一个最稳定的夹取动作，例如 `pickbreadpot` 或 `pickbreadplate`。
2. 展示一个更有烹饪语义的动作，例如 `flipbreadtopot`。
3. 如果时间允许，展示鸡蛋相关动作 `pickeggtopot` / `pickeggtoplate`。
4. 用状态机或人工按钮触发多个 primitive，形成半自主菜谱流程。

## 3. 10 分钟汇报结构

### 第 1 分钟：问题和目标

```text
赛题要求 48 小时内完成半自主烹饪。
我们的切入点是把烹饪拆成可学习的动作 primitive。
```

### 第 2-3 分钟：系统架构

展示：

```text
数据采集 -> ACT 训练 -> HF checkpoint -> reComputer 推理 -> reBot 执行
```

强调：

```text
遥操作是数据来源，不是最终执行方式。
```

### 第 4-5 分钟：模型和数据

展示 5 个动作：

```text
flipbreadtopot
pickbreadplate
pickbreadpot
pickeggtopot
pickeggtoplate
```

说明每个动作一个 checkpoint，方便重训、替换和组合。

### 第 6 分钟：训练效率

重点数字：

```text
MI300X 单动作 20K 约 50 分钟
5 个动作 100K 总计约 4.16 GPU 小时
L20 2K benchmark 约 334 step/min，预计 20K 约 60 分钟
```

### 第 7 分钟：边缘部署

展示：

```text
reComputer 本地 LeRobot ACTPolicy.from_pretrained
full chunk generation: 12-14 Hz
cached action: ~1 ms
```

### 第 8 分钟：现场 demo 视频或实机

播放或现场演示 reBot 动作。

重点讲：

```text
模型输出 7DoF action
ACT 一次生成 50 步 action chunk
控制循环逐步执行
```

### 第 9 分钟：工程挑战

讲真实问题：

1. 数据集有坏上传，例如 `pickeggtoplate5` 不完整。
2. 多数据集合并后视频 timestamp 需要修。
3. reComputer 上 torch/torchvision/JetPack 环境需要适配。
4. 训练 loss 不等于真实任务成功率，必须上机械臂测试。

### 第 10 分钟：总结

总结为：

```text
我们在 48 小时内建立了一个可复用的机器人烹饪动作学习流水线。
这个流水线可以快速从新示范数据产生新动作 checkpoint，并部署到现场机器人。
```

## 4. 建议 PPT 页

| 页 | 标题 | 内容 |
| --- | --- | --- |
| 1 | 项目目标 | reBot 半自主烹饪 |
| 2 | 系统架构 | 采集、训练、部署、执行闭环 |
| 3 | 动作 primitive | 5 个 ACT 动作 |
| 4 | 数据与训练 | episodes、frames、20K checkpoint |
| 5 | 训练效率 | MI300X 与 L20 对比 |
| 6 | reComputer 部署 | ACTPolicy 本地推理 |
| 7 | 现场 demo | 视频或实机 |
| 8 | 挑战和修复 | 数据、timestamp、Jetson 环境 |
| 9 | 结果和下一步 | 成功率测试、状态机、更多动作 |

## 5. 风险和备用方案

| 风险 | 备用方案 |
| --- | --- |
| 现场网络不稳定 | checkpoint 提前下载到 reComputer |
| 某个动作失败 | 只展示最稳定的 1-2 个 primitive |
| 摄像头输入异常 | 使用固定初始位姿和构造 observation smoke test 说明链路 |
| 机械臂安全风险 | 保留急停和人工接管 |
| 菜品完整流程不稳定 | 展示关键动作 + 视频证据 + 训练闭环 |

## 6. 最应避免的展示方式

不要只展示：

```text
训练 loss 曲线
checkpoint 列表
离线推理 action shape
```

这些是支撑材料，不是最终比赛价值。

应该展示：

```text
真实机械臂动作
从示范到策略的闭环
可在 1 小时内新增/重训动作的工程效率
```
