# ACT Checkpoint 清单

本文档记录比赛期间训练完成并可部署的 ACT checkpoint。

## 1. 总览

| action | 任务说明 | 数据规模 | HF repo | 部署版本 |
| --- | --- | --- | --- | --- |
| `flipbreadtopot` | 翻面包到锅 | 49 episodes / 20,648 frames | `fbsh96/rebot-act-flipbreadtopot-newway-49eps` | `checkpoint-020000` |
| `pickbreadplate` | 夹面包到盘子 | 50 episodes / 28,335 frames | `fbsh96/rebot-act-pickbreadplate-50eps` | `checkpoint-020000` |
| `pickbreadpot` | 夹面包到锅 | 42 episodes / 28,145 frames | `fbsh96/rebot-act-pickbreadpot-42eps` | `checkpoint-020000` |
| `pickeggtopot` | 夹蛋到锅 | 50 episodes / 30,900 frames | `fbsh96/rebot-act-pickeggtopot-50eps` | `checkpoint-020000` |
| `pickeggtoplate` | 夹蛋到盘子 | 50 episodes / 30,355 frames | `fbsh96/rebot-act-pickeggtoplate-50eps-skip5` | `checkpoint-020000` |

## 2. Hugging Face 路径

```text
fbsh96/rebot-act-flipbreadtopot-newway-49eps/checkpoint-020000
fbsh96/rebot-act-pickbreadplate-50eps/checkpoint-020000
fbsh96/rebot-act-pickbreadpot-42eps/checkpoint-020000
fbsh96/rebot-act-pickeggtopot-50eps/checkpoint-020000
fbsh96/rebot-act-pickeggtoplate-50eps-skip5/checkpoint-020000
```

`pickeggtoplate` 是 `skip5` 版本，因为原始 `20260426_pickeggtoplate5` 数据集不完整。

## 3. checkpoint 文件结构

每个 LeRobot ACT checkpoint 目录应包含 7 个文件：

```text
config.json
model.safetensors
policy_postprocessor.json
policy_postprocessor_step_0_unnormalizer_processor.safetensors
policy_preprocessor.json
policy_preprocessor_step_3_normalizer_processor.safetensors
train_config.json
```

其中：

```text
model.safetensors: 约 207 MB
```

## 4. MI300X 本地路径

```text
/mnt/models_alehe/phi-fbsh/drtc-Phi/outputs/train/rebot_act_flipbread_newway_49eps_mi300x_b16_20000steps/checkpoints/020000/pretrained_model

/mnt/models_alehe/phi-fbsh/drtc-Phi/outputs/train/rebot_act_pickbreadplate_50eps_mi300x_b16_20000steps/checkpoints/020000/pretrained_model

/mnt/models_alehe/phi-fbsh/drtc-Phi/outputs/train/rebot_act_pickbreadpot_42eps_mi300x_b16_20000steps/checkpoints/020000/pretrained_model

/mnt/models_alehe/phi-fbsh/drtc-Phi/outputs/train/rebot_act_pickeggtopot_50eps_mi300x_b16_20000steps/checkpoints/020000/pretrained_model

/mnt/models_alehe/phi-fbsh/drtc-Phi/outputs/train/rebot_act_pickeggtoplate_50eps_skip5_mi300x_b16_20000steps/checkpoints/020000/pretrained_model
```

## 5. reComputer 目标路径

当前已经验证过的本地路径：

```text
/home/recomputer/models/rebot-act-flipbreadtopot-020000
/home/recomputer/models/rebot-act-pickbreadplate-020000
/home/recomputer/models/rebot-act-pickbreadpot-020000
```

建议补齐：

```text
/home/recomputer/models/rebot-act-pickeggtopot-020000
/home/recomputer/models/rebot-act-pickeggtoplate-020000
```

## 6. 加载方式

```python
from lerobot.policies.act.modeling_act import ACTPolicy

policy = ACTPolicy.from_pretrained("/home/recomputer/models/rebot-act-pickbreadpot-020000")
```

实际推理脚本见：

```text
/home/recomputer/work/drtc-Phi/tools/rebot_act_local_infer.py
```
