# reBot ACT 云端训练效率记录

本文档记录 reBot 机械臂在 MI300X 云端训练 ACT 策略的完整流程、数据集组织、训练参数、训练效率和 checkpoint 产物。重点结论是：在当前 LeRobot ACT 配置下，MI300X 上训练一个 20,000 step 的单动作策略大约需要 50 分钟，5 个正式动作累计完成 100,000 step，实际训练耗时约 4.16 GPU 小时。

## 1. 训练目标

目标是在 reBot 机械臂当前数据格式上，为每个离散动作训练一个独立 ACT policy，并在 reComputer 测试终端上使用 LeRobot 原生 `ACTPolicy.from_pretrained(...)` 进行本地推理。

当前正式 ACT 动作共 5 个：

| 动作 | 说明 | 训练状态 | HF 产物 |
| --- | --- | --- | --- |
| `flipbreadtopot` | 翻面包到锅 | 已完成 20K | `fbsh96/rebot-act-flipbreadtopot-newway-49eps` |
| `pickthebreadintotheplate` | 夹面包到盘子 | 已完成 20K | `fbsh96/rebot-act-pickbreadplate-50eps` |
| `pickthebreadintothepot` | 夹面包到锅 | 已完成 20K | `fbsh96/rebot-act-pickbreadpot-42eps` |
| `pickeggtopot` | 夹蛋到锅 | 已完成 20K | `fbsh96/rebot-act-pickeggtopot-50eps` |
| `pickeggtoplate` | 夹蛋到盘子 | 已完成 20K | `fbsh96/rebot-act-pickeggtoplate-50eps-skip5` |

`pickeggtoplate` 需要特别标注为 `skip5`：原始第 5 个数据集在 Hugging Face 上只有 `.gitattributes`、`README.md`、`meta/info.json`，缺少实际 data/video/tasks 文件，因此未参与训练。最终使用 `pickeggtoplate1/2/3/4/6`，合计仍为 50 episodes。

## 2. 训练机器和环境

训练机器：

```text
远端主机: phi-amd-work
GPU: AMD Instinct MI300X VF
ROCm GFX: gfx942
训练代码路径: /mnt/models_alehe/phi-fbsh/drtc-Phi
Python/venv: /mnt/models_alehe/phi-fbsh/.venvs/drtc-mi300x
```

训练框架：

```text
LeRobot ACT
PyTorch ROCm
单 GPU 训练
policy.type=act
vision_backbone=resnet18
num_learnable_params=51,573,639
```

远端进入环境：

```bash
ssh -o RemoteCommand=none phi-amd-work
cd /mnt/models_alehe/phi-fbsh/drtc-Phi
source /mnt/models_alehe/phi-fbsh/.venvs/drtc-mi300x/bin/activate
```

## 3. 数据集汇总

| 动作 | 合并后数据集 | episodes | frames | 备注 |
| --- | --- | ---: | ---: | --- |
| `flipbreadtopot` | `phi-media-lab/rebot_flipbreadtopot_newway_20260425_49eps` | 49 | 20,648 | newway 版本 |
| `pickthebreadintotheplate` | `phi-media-lab/rebot_pickbreadplate_20260425_50eps` | 50 | 28,335 | 5 组数据 |
| `pickthebreadintothepot` | `phi-media-lab/rebot_pickbreadpot_20260425_42eps` | 42 | 28,145 | 1/3/4/5 正常数据 |
| `pickeggtopot` | `phi-media-lab/rebot_pickeggtopot_20260426_50eps` | 50 | 30,900 | 7 组数据 |
| `pickeggtoplate` | `phi-media-lab/rebot_pickeggtoplate_20260426_50eps_skip5` | 50 | 30,355 | 跳过不完整的第 5 组 |

数据格式一致：

```text
observation.images.front: (3, 480, 640)
observation.images.wrist: (3, 480, 640)
action: (7,)
```

训练前必须做数据可读性验证，尤其是视频时间戳边界。`pickeggtopot` 和 `pickeggtoplate` 都遇到过合并后 episode metadata 中视频 timestamp 跨文件偏移不正确的问题。修正后通过多点抽样验证，再启动训练，避免训练中途随机读取坏帧失败。

## 4. 统一训练配置

5 个正式动作均采用同一组 ACT 训练参数，保证训练成本和结果可横向比较。

```bash
HIP_VISIBLE_DEVICES=0 CUDA_VISIBLE_DEVICES=0 lerobot-train \
  --policy.type=act \
  --policy.chunk_size=50 \
  --policy.n_action_steps=50 \
  --policy.push_to_hub=false \
  --dataset.repo_id=<MERGED_DATASET_REPO_ID> \
  --dataset.video_backend=pyav \
  --batch_size=16 \
  --steps=20000 \
  --eval_freq=0 \
  --save_freq=10000 \
  --log_freq=100 \
  --num_workers=4 \
  --wandb.enable=false \
  --output_dir=outputs/train/<RUN_NAME>
```

关键配置解释：

| 参数 | 当前值 | 作用 |
| --- | ---: | --- |
| `batch_size` | 16 | 单 GPU 有效 batch size |
| `steps` | 20,000 | 每个动作固定训练步数 |
| `save_freq` | 10,000 | 保存 10K 和 20K checkpoint |
| `chunk_size` | 50 | ACT 一次预测 50 步动作 chunk |
| `n_action_steps` | 50 | 推理端可从 chunk 中逐步取动作 |
| `num_workers` | 4 | 视频/数据加载 worker |
| `eval_freq` | 0 | 不做在线 eval，节省训练时间 |
| `wandb.enable` | false | 避免外部日志依赖，减少故障面 |

## 5. 训练效率结果

### 5.1 单动作训练耗时

| 动作 | frames | episodes | 训练开始 UTC | 训练结束 UTC | 20K 耗时 | step/min | sec/step | final loss |
| --- | ---: | ---: | --- | --- | ---: | ---: | ---: | ---: |
| `flipbreadtopot` | 20,648 | 49 | 2026-04-25 15:51:19 | 2026-04-25 16:40:29 | 49m10s | 406.8 | 0.1475 | 0.070 |
| `pickthebreadintotheplate` | 28,335 | 50 | 2026-04-25 20:36:37 | 2026-04-25 21:26:05 | 49m28s | 404.3 | 0.1484 | 0.082 |
| `pickthebreadintothepot` | 28,145 | 42 | 2026-04-25 22:58:47 | 2026-04-25 23:49:39 | 50m52s | 393.2 | 0.1526 | 0.068 |
| `pickeggtopot` | 30,900 | 50 | 2026-04-26 03:59:17 | 2026-04-26 04:49:22 | 50m05s | 399.3 | 0.1503 | 0.071 |
| `pickeggtoplate` | 30,355 | 50 | 2026-04-26 05:08:15 | 2026-04-26 05:58:00 | 49m45s | 402.0 | 0.1493 | 0.091 |

汇总：

```text
正式动作数: 5
累计训练步数: 100,000 steps
累计训练耗时: 14,960 秒 = 249.3 分钟 = 4.16 小时
平均单动作 20K 耗时: 49.9 分钟
平均吞吐: 约 401 step/min
平均单 step 时间: 约 0.150 秒
```

### 5.2 效率结论

当前 MI300X 训练 ACT 的效率非常稳定。不同动作的数据量从 20K frames 到 31K frames 不等，但 20K step 训练耗时都落在 49-51 分钟之间，说明主要瓶颈不是数据集总帧数，而是每 step 的模型前向/反向和视频 batch decode。

日志中稳定段典型值：

```text
updt_s: 约 0.071-0.073 秒
data_s: 约 0.069-0.076 秒
```

这说明训练循环中模型更新和数据加载耗时接近。继续优化时，如果只优化 GPU 计算而不优化视频读取，收益会有限；如果只优化数据加载而模型更新不变，收益也有限。更实际的优化方向是保持当前 pipeline 稳定，把数据校验和自动合并脚本化，减少失败重跑。

### 5.3 为什么这个效率对比赛有价值

在当前配置下，每新增一个动作，只要数据集完整且 schema 一致，可以按如下节奏迭代：

```text
数据集验证: 数分钟
数据集合并: 数分钟
20K 训练: 约 50 分钟
checkpoint 上传 HF: 约 1-3 分钟
reComputer 下载部署: 取决于现场网络，一般模型文件约 207 MB
```

也就是说，单个新动作从“数据可用”到“20K checkpoint 可部署”，理论上可以控制在 1 小时左右。这个迭代速度适合比赛现场快速补动作、重训动作、对比 10K/20K 效果。

## 6. checkpoint 产物

MI300X 本地训练产物：

```text
/mnt/models_alehe/phi-fbsh/drtc-Phi/outputs/train/
```

正式 20K checkpoint：

| 动作 | MI300X checkpoint 路径 | HF repo |
| --- | --- | --- |
| `flipbreadtopot` | `outputs/train/rebot_act_flipbread_newway_49eps_mi300x_b16_20000steps/checkpoints/020000/pretrained_model` | `fbsh96/rebot-act-flipbreadtopot-newway-49eps/checkpoint-020000` |
| `pickthebreadintotheplate` | `outputs/train/rebot_act_pickbreadplate_50eps_mi300x_b16_20000steps/checkpoints/020000/pretrained_model` | `fbsh96/rebot-act-pickbreadplate-50eps/checkpoint-020000` |
| `pickthebreadintothepot` | `outputs/train/rebot_act_pickbreadpot_42eps_mi300x_b16_20000steps/checkpoints/020000/pretrained_model` | `fbsh96/rebot-act-pickbreadpot-42eps/checkpoint-020000` |
| `pickeggtopot` | `outputs/train/rebot_act_pickeggtopot_50eps_mi300x_b16_20000steps/checkpoints/020000/pretrained_model` | `fbsh96/rebot-act-pickeggtopot-50eps/checkpoint-020000` |
| `pickeggtoplate` | `outputs/train/rebot_act_pickeggtoplate_50eps_skip5_mi300x_b16_20000steps/checkpoints/020000/pretrained_model` | `fbsh96/rebot-act-pickeggtoplate-50eps-skip5/checkpoint-020000` |

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

其中 `model.safetensors` 约 207 MB，是主要权重文件。

## 7. 推理端关系

reComputer 测试终端当前使用的是 LeRobot 原生 ACT 推理方案：

```text
/home/recomputer/work/drtc-Phi/tools/rebot_act_local_infer.py
```

推理方式：

```python
ACTPolicy.from_pretrained(<local_checkpoint_path>)
```

当前已经在 reComputer 落盘过的 20K checkpoint：

```text
/home/recomputer/models/rebot-act-flipbreadtopot-020000
/home/recomputer/models/rebot-act-pickbreadplate-020000
/home/recomputer/models/rebot-act-pickbreadpot-020000
```

后续应继续把新增的两个动作部署到 reComputer：

```text
/home/recomputer/models/rebot-act-pickeggtopot-020000
/home/recomputer/models/rebot-act-pickeggtoplate-020000
```

此前本地推理 smoke test 的量级：

```text
full chunk generation: 约 12-14 Hz
cached action step: 约 1 ms
```

这里需要明确：`cached action step` 不是完整模型前向，而是在 ACT 已生成的 50 步 chunk 中取下一步动作；真正模型推理频率要看 full chunk generation。

## 8. 标准新增动作流程

新增动作建议严格按以下顺序执行。

### 8.1 验证每个原始数据集

```python
from lerobot.datasets.lerobot_dataset import LeRobotDataset

repos = [
    "Lisette1231/<dataset1>",
    "Lisette1231/<dataset2>",
]

total_eps = 0
total_frames = 0
for repo in repos:
    ds = LeRobotDataset(repo, video_backend="pyav")
    total_eps += ds.num_episodes
    total_frames += ds.num_frames
    sample = ds[0]
    print(repo, ds.num_episodes, ds.num_frames, sample["action"].shape)
```

必须确认：

```text
meta/tasks.parquet 存在
data parquet 存在
front/wrist videos 存在
action shape 为 (7,)
front/wrist image shape 为 (3, 480, 640)
```

### 8.2 合并数据集

使用 LeRobot 的 `aggregate_datasets` 合并多个同 schema 数据集。合并后必须创建或确认本地 cache/symlink，使 `lerobot-train --dataset.repo_id=...` 可以直接找到本地合并结果。

合并完成后必须抽样验证视频边界：

```text
第 0 帧
每个原始数据集边界前后
中间随机帧
最后 1 帧
```

如果出现类似下面错误，说明 episode metadata 的 video timestamp 需要修正：

```text
AssertionError: One or several query timestamps unexpectedly violate the tolerance
queried timestamps ... loaded timestamps ...
```

### 8.3 启动训练

推荐命名：

```text
outputs/train/rebot_act_<action>_<episodes>eps_mi300x_b16_20000steps
```

如果跳过了坏数据集，必须在名字里标注：

```text
skip5
```

### 8.4 训练完成后检查

检查日志：

```bash
tail -80 logs/<run>.log
```

必须看到：

```text
Checkpoint policy after step 20000
End of training
```

检查 checkpoint：

```bash
find outputs/train/<run>/checkpoints -maxdepth 2 -type d | sort
```

必须存在：

```text
checkpoints/020000/pretrained_model
```

### 8.5 上传 Hugging Face

如果只需要部署最佳版本，优先只上传 `020000`：

```text
fbsh96/rebot-act-<action>-<episodes>eps/checkpoint-020000
```

如果数据集有跳过项，HF repo 名也必须包含 `skipX`：

```text
fbsh96/rebot-act-pickeggtoplate-50eps-skip5
```

上传后必须用 HF API 校验：

```text
checkpoint-020000/model.safetensors exists
checkpoint-020000 下共有 7 个文件
```

## 9. 当前训练效率的工程判断

当前 ACT 训练方案已经足够用于比赛现场快速迭代：

```text
单动作 20K: 约 50 分钟
5 个动作 100K: 约 4.16 小时
单模型大小: 约 207 MB
部署方式: HF 拉取到 reComputer，本地 LeRobot ACT 推理
```

训练效率上最值得强调的不是单步极限性能，而是整体闭环稳定：

1. 数据集验证能提前发现坏数据。
2. 合并后抽样能提前发现视频时间戳问题。
3. 统一训练参数让不同动作的训练成本可预测。
4. 20K checkpoint 在 1 小时内可产出，适合比赛现场快速补动作。
5. HF 分发让 reComputer 端不依赖 MI300X 远端文件传输。

当前最重要的后续动作不是继续调大训练步数，而是把 5 个 ACT checkpoint 全部部署到 reComputer，并在真实机械臂上做动作级成功率测试。训练 loss 只能说明 supervised fitting 正常，不能直接代表真实任务成功率。
