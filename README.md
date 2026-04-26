# 04-26 Robot Cooking Hackathon

本仓库是 2026-04-26 胡闹厨房 Robot Cooking Hackathon 的项目交付仓库。

我们的方案是：基于 reBot B601 DM 机械臂和 LeRobot，采集遥操作示范数据，为关键烹饪动作训练 ACT imitation learning policy，并把 checkpoint 部署到 reComputer / 近端 GPU 服务上，组合成半自主烹饪流程。

## 项目主线

```text
遥操作采集示范
  -> LeRobot 数据集
  -> MI300X / L20 云端训练 ACT policy
  -> Hugging Face checkpoint 分发
  -> reComputer 本地 ACT 推理
  -> reBot 执行烹饪动作 primitive
  -> 菜谱级状态机组合动作
```

## 当前能力

已训练 5 个 ACT 动作 primitive：

| 动作 | 说明 | HF checkpoint |
| --- | --- | --- |
| `flipbreadtopot` | 翻面包到锅 | `fbsh96/rebot-act-flipbreadtopot-newway-49eps/checkpoint-020000` |
| `pickbreadplate` | 夹面包到盘子 | `fbsh96/rebot-act-pickbreadplate-50eps/checkpoint-020000` |
| `pickbreadpot` | 夹面包到锅 | `fbsh96/rebot-act-pickbreadpot-42eps/checkpoint-020000` |
| `pickeggtopot` | 夹蛋到锅 | `fbsh96/rebot-act-pickeggtopot-50eps/checkpoint-020000` |
| `pickeggtoplate` | 夹蛋到盘子 | `fbsh96/rebot-act-pickeggtoplate-50eps-skip5/checkpoint-020000` |

说明：`pickeggtoplate` 是 `skip5` 版本，因为原始第 5 个数据集不完整，实际使用 `1/2/3/4/6` 合计 50 episodes。

## 训练效率

MI300X 上 5 个正式动作均完成 20,000 step 训练。

```text
累计训练: 100,000 steps
累计耗时: 约 4.16 GPU 小时
单动作 20K: 约 49-51 分钟
平均吞吐: 约 401 step/min
```

阿里云 L20 也完成同配置短程 benchmark：

```text
L20 benchmark: 约 334 step/min
预计 20K: 约 60 分钟
```

## 推理部署

当前测试终端使用 LeRobot 原生 ACT 推理：

```text
ACTPolicy.from_pretrained(<local_checkpoint_path>)
```

reComputer 上已验证过的本地推理量级：

```text
full chunk generation: 约 12-14 Hz
cached action step: 约 1 ms
```

注意：`cached action step` 是从 ACT 生成的 50 步 action chunk 中取下一步，不是完整模型前向。

## 仓库结构

```text
docs/
  system_architecture.md          系统架构与比赛展示主线
  demo_plan.md                    现场展示与 10 分钟汇报计划
  checkpoints.md                  5 个 ACT checkpoint 清单
  deployment_recomputer.md        reComputer / 推理端部署说明
  training_efficiency_mi300x.md   MI300X 训练效率记录
  compute_comparison.md           MI300X vs L20 算力对比
  training_scripts.md             训练脚本使用说明

scripts/
  train_act.sh                    ACT 完整训练入口
  benchmark_act_training.sh       ACT 训练速度 benchmark
```

## 快速训练

```bash
scripts/train_act.sh pickeggtopot 20000
```

短程 benchmark：

```bash
scripts/benchmark_act_training.sh flipbreadtopot 2000
```

## 评分项对应

| 评分项 | 我们的对应内容 |
| --- | --- |
| 现场演示 | reBot 执行 ACT 动作 primitive，组合成烹饪流程 |
| 讲解 PPT | 见 `docs/demo_plan.md` |
| GitHub README | 本仓库 |
| reComputer 部署 | 见 `docs/deployment_recomputer.md` |
| 技术创新 | LeRobot + ACT 模仿学习，权重 0.8 |
| 菜品味道 | 通过稳定 primitive 服务最终菜品制作 |

## 当前工程判断

展示时应强调完整闭环，而不是单点模型指标：

```text
采集 -> 训练 -> checkpoint 分发 -> reComputer 推理 -> 机械臂执行 -> 菜品流程
```

训练 loss 只能说明 supervised fitting 正常，最终效果需要通过真实机械臂成功率和菜品完成度评估。
