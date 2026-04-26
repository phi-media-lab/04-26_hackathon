# ACT 训练脚本

本仓库保留两个训练入口：

```text
scripts/train_act.sh
scripts/benchmark_act_training.sh
```

这两个脚本只封装我们比赛期间实际使用过的 LeRobot ACT 训练配置，不负责安装环境，也不负责采集数据。

## 1. 环境要求

运行前需要先进入已经安装好 LeRobot 的环境。

MI300X：

```bash
ssh -o RemoteCommand=none phi-amd-work
cd /mnt/models_alehe/phi-fbsh/drtc-Phi
source /mnt/models_alehe/phi-fbsh/.venvs/drtc-mi300x/bin/activate
```

阿里云 L20：

```bash
ssh -i /Users/fbsh/ali-gpu-key.pem root@47.106.21.198
cd /root/work/drtc-Phi
source .venv/bin/activate
```

确认：

```bash
which lerobot-train
python -c "import torch; print(torch.__version__, torch.cuda.is_available())"
```

## 2. 支持的动作

| action | dataset |
| --- | --- |
| `flipbreadtopot` | `phi-media-lab/rebot_flipbreadtopot_newway_20260425_49eps` |
| `pickbreadplate` | `phi-media-lab/rebot_pickbreadplate_20260425_50eps` |
| `pickbreadpot` | `phi-media-lab/rebot_pickbreadpot_20260425_42eps` |
| `pickeggtopot` | `phi-media-lab/rebot_pickeggtopot_20260426_50eps` |
| `pickeggtoplate` | `phi-media-lab/rebot_pickeggtoplate_20260426_50eps_skip5` |

`pickeggtoplate` 是 `skip5` 版本，因为原始第 5 个数据集不完整。

## 3. 完整训练

默认训练 20,000 steps：

```bash
scripts/train_act.sh flipbreadtopot
```

显式指定 steps：

```bash
scripts/train_act.sh pickeggtopot 20000
```

使用本地 LeRobot dataset cache：

```bash
DATASET_ROOT=/root/.cache/huggingface/lerobot/phi-media-lab/rebot_flipbreadtopot_newway_20260425_49eps \
  scripts/train_act.sh flipbreadtopot 20000
```

默认训练参数：

```text
policy.type=act
batch_size=16
steps=20000
chunk_size=50
n_action_steps=50
save_freq=10000
log_freq=100
num_workers=4
eval_freq=0
wandb.enable=false
```

输出：

```text
outputs/train/<run_name>/
logs/<run_name>.log
```

20K checkpoint：

```text
outputs/train/<run_name>/checkpoints/020000/pretrained_model
```

## 4. 短程 benchmark

用于比较不同机器的训练速度，不需要完整训练。

```bash
scripts/benchmark_act_training.sh flipbreadtopot 2000
```

脚本会先调用 `train_act.sh`，训练结束后解析日志并输出：

```text
train_duration_sec
step_per_min
sec_per_step
avg_updt_s
avg_data_s
first_record
last_record
```

比赛期间 L20 benchmark 使用的是：

```bash
DATASET_ROOT=/root/.cache/huggingface/lerobot/phi-media-lab/rebot_flipbreadtopot_newway_20260425_49eps \
  scripts/benchmark_act_training.sh flipbreadtopot 2000
```

结果约为：

```text
334 step/min
0.1795 sec/step
updt_s ~0.166
data_s ~0.006
```

MI300X 同动作完整 20K 结果约为：

```text
406.8 step/min
0.1475 sec/step
```

## 5. 常用 override

```bash
BATCH_SIZE=32 scripts/train_act.sh flipbreadtopot 20000
```

```bash
RUN_NAME=my_act_run scripts/train_act.sh pickbreadpot 20000
```

```bash
CUDA_VISIBLE_DEVICES=0 scripts/train_act.sh pickeggtoplate 20000
```

```bash
HIP_VISIBLE_DEVICES=0 CUDA_VISIBLE_DEVICES=0 scripts/train_act.sh pickeggtopot 20000
```

## 6. 注意事项

1. 脚本假设数据集已经能被 LeRobot 读取；如果原始数据集还没合并或有 timestamp 问题，需要先修复数据集。
2. benchmark 只用于训练速度对比，不代表最终模型效果。
3. 训练 loss 不能直接代表真实机械臂成功率，最终仍需上 reComputer 和 reBot 实测。
4. `pickeggtoplate` repo 名必须保留 `skip5`，避免误认为使用了完整 1-6 数据。
