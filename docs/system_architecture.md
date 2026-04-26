# 系统架构

本文档描述本项目的完整系统架构，重点回答比赛评委关心的三个问题：

1. 机械臂是否真的在执行自主或半自主策略。
2. 算法、训练、部署是否形成完整闭环。
3. 方案是否能支撑实际烹饪任务，而不是单个离线模型 demo。

## 1. 总体方案

我们的方案是把复杂烹饪任务拆成多个可训练、可验证、可组合的动作 primitive。

每个 primitive 对应一个 ACT policy：

```text
front/wrist 图像 + 当前关节状态
  -> ACT policy
  -> 未来 50 步 action chunk
  -> 逐步发送 7DoF action
```

菜谱级流程由一个上层状态机或人工触发器组合这些 primitive：

```text
准备食材
  -> pickbreadpot
  -> flipbreadtopot
  -> pickeggtopot
  -> pickeggtoplate
  -> 出餐
```

这不是纯遥操作。遥操作只用于数据采集、调试和安全接管；比赛执行时关键动作由训练好的 policy 输出动作。

## 2. 分层架构

```text
┌──────────────────────────────────────────────┐
│ 菜谱层 Recipe / State Machine                │
│ 选择当前动作 primitive，处理开始/结束/失败恢复 │
└──────────────────────────────────────────────┘
                    │
┌──────────────────────────────────────────────┐
│ Policy 层 LeRobot ACT                         │
│ 每个动作一个 checkpoint，输入视觉与状态，输出动作 │
└──────────────────────────────────────────────┘
                    │
┌──────────────────────────────────────────────┐
│ Runtime 层 reComputer / 近端 GPU              │
│ 加载 checkpoint，执行 ACTPolicy.from_pretrained │
└──────────────────────────────────────────────┘
                    │
┌──────────────────────────────────────────────┐
│ Robot 层 reBot B601 DM                        │
│ 执行 7DoF action，读取相机和关节状态            │
└──────────────────────────────────────────────┘
```

## 3. 数据闭环

```text
遥操作示范
  -> LeRobot dataset
  -> 数据校验
  -> 多数据集合并
  -> 视频 timestamp 修复
  -> ACT 训练
  -> checkpoint
  -> reComputer 部署
  -> 真实机械臂评估
```

数据格式：

```text
observation.images.front: (3, 480, 640)
observation.images.wrist: (3, 480, 640)
action: (7,)
```

关键经验：

1. 每个 Hugging Face dataset 必须先验证 `tasks.parquet`、data parquet 和视频文件完整。
2. 合并后的 dataset 必须跨视频文件边界抽样验证。
3. 如果出现 timestamp tolerance error，必须修正 episode metadata 后再训练。

## 4. 训练层

训练主力是 MI300X：

```text
GPU: AMD Instinct MI300X VF
单动作 20K: 约 49-51 分钟
5 个动作 100K: 约 4.16 GPU 小时
```

近端备份训练和推理服务器是阿里云 L20：

```text
GPU: NVIDIA L20 46GB
2K benchmark: 334 step/min
预计 20K: 约 60 分钟
本地 ping: 约 18.8 ms
```

训练配置统一：

```text
policy.type=act
batch_size=16
steps=20000
chunk_size=50
n_action_steps=50
num_workers=4
```

## 5. 模型资产层

每个动作一个 checkpoint repo，统一使用 20K 版本作为部署基线。

优点：

1. 单个动作失败时可以单独重采、单独重训。
2. 模型分发清晰，reComputer 可按动作拉取。
3. 菜谱流程可以按动作粒度替换策略。

局限：

1. 当前不是一个端到端 VLA 大模型。
2. 需要上层状态机选择动作。
3. 动作切换和失败恢复仍需要工程逻辑。

## 6. 推理层

当前测试终端使用 LeRobot 原生 ACT 推理：

```python
ACTPolicy.from_pretrained(checkpoint_path)
```

推理形态：

```text
完整模型前向 -> 生成 50 步 action chunk
控制循环 -> 从 chunk 中逐步取 action
```

已测量量级：

```text
full chunk generation: 约 12-14 Hz
cached action step: 约 1 ms
```

对于烹饪任务，ACT chunked control 比 token-by-token 远程 VLA 更稳定，因为动作频率和网络延迟压力更低。

## 7. 和赛题评分的关系

| 评分项 | 对应系统能力 |
| --- | --- |
| 现场演示 | reBot 真实执行策略动作 |
| GitHub / README | 本仓库记录完整训练、部署、checkpoint |
| reComputer 部署 | 使用 reComputer 本地推理 ACT checkpoint |
| 技术创新 | 模仿学习 ACT，评分权重 0.8 |
| 菜品味道 | 稳定动作 primitive 支撑菜品完成 |

## 8. 展示时的核心表述

推荐表述：

```text
我们没有把机械臂当成遥操作设备，而是把遥操作变成训练数据。
在 48 小时内，我们采集了多个烹饪动作的数据，训练出 5 个 ACT policy，
并把它们部署到 reComputer / 近端 GPU 推理环境中，组合成可执行的烹饪 primitive 系统。
```

不要把主线讲成：

```text
我们只是训练了几个 checkpoint。
```

应该讲成：

```text
我们建立了一个从示范到训练、部署、执行的机器人烹饪动作生产线。
```
