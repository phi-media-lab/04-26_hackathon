# reBot ACT 训练算力对比：MI300X vs 阿里云 L20

本文档记录当前两类云端算力在 reBot ACT 训练任务上的对比结果。目标不是完整评测所有硬件极限，而是回答一个工程问题：如果把 MI300X 上已经跑通的 ACT 训练流程迁移到阿里云 L20，训练速度、显存占用和实际可用性大概是什么水平。

## 1. 对比对象

### 1.1 MI300X 训练服务器

```text
主机: phi-amd-work
GPU: AMD Instinct MI300X VF
ROCm GFX: gfx942
训练代码: /mnt/models_alehe/phi-fbsh/drtc-Phi
训练框架: LeRobot ACT + PyTorch ROCm
```

MI300X 已完成 5 个正式 ACT 动作训练，每个动作训练 20,000 steps。

### 1.2 阿里云 L20 服务器

```text
主机: root@47.106.21.198
OS: Ubuntu 24.04.4 LTS
GPU: NVIDIA L20
显存: 46GB
Driver: 580.126.09
CUDA runtime: 13.0
训练环境: /root/work/drtc-Phi/.venv
训练框架: LeRobot ACT + PyTorch CUDA
torch: 2.7.1+cu126
lerobot: 0.4.3
```

机器资源：

```text
CPU: Intel Xeon Gold 6462C, 16 vCPU
内存: 123GiB
系统盘: 126GB, 剩余约 25GB
Docker: 已安装，包含 nvidia runtime
```

网络：

```text
本地到阿里云 ping 平均约 18.8 ms
相比 MI300X 公网链路，更适合做现场远端推理服务
```

当前 L20 上有一个 idle 的 DRTC server：

```text
python examples/tutorial/async-inf/policy_server_drtc.py --host 0.0.0.0 --port 18201 --fps 15
显存占用: 约 2.8GB
GPU 利用率: 0%
```

该进程在本次 benchmark 中没有停止。它占用少量显存，但没有明显计算负载。

## 2. Apple-to-Apple 训练配置

为了对齐 MI300X，L20 benchmark 使用相同 ACT 配置和相同数据集。

数据集：

```text
phi-media-lab/rebot_flipbreadtopot_newway_20260425_49eps
episodes: 49
frames: 20,648
```

统一 ACT 配置：

```bash
lerobot-train \
  --policy.type=act \
  --policy.chunk_size=50 \
  --policy.n_action_steps=50 \
  --policy.push_to_hub=false \
  --dataset.repo_id=phi-media-lab/rebot_flipbreadtopot_newway_20260425_49eps \
  --dataset.video_backend=pyav \
  --batch_size=16 \
  --eval_freq=0 \
  --save_freq=10000 \
  --log_freq=100 \
  --num_workers=4 \
  --wandb.enable=false
```

模型规模：

```text
ACT policy
vision_backbone: ResNet18
num_learnable_params: 51,573,639
有效 batch size: 16
```

## 3. L20 Benchmark 执行方式

L20 不跑完整 20K，只跑 2,000 steps，用于采样训练吞吐、GPU 利用率和显存。

实际命令：

```bash
cd /root/work/drtc-Phi
source .venv/bin/activate

CUDA_VISIBLE_DEVICES=0 lerobot-train \
  --policy.type=act \
  --policy.chunk_size=50 \
  --policy.n_action_steps=50 \
  --policy.push_to_hub=false \
  --dataset.repo_id=phi-media-lab/rebot_flipbreadtopot_newway_20260425_49eps \
  --dataset.root=/root/.cache/huggingface/lerobot/phi-media-lab/rebot_flipbreadtopot_newway_20260425_49eps \
  --dataset.video_backend=pyav \
  --batch_size=16 \
  --steps=2000 \
  --eval_freq=0 \
  --save_freq=10000 \
  --log_freq=100 \
  --num_workers=4 \
  --wandb.enable=false \
  --output_dir=outputs/train/rebot_act_flipbread_newway_49eps_l20_b16_bench_2000steps
```

说明：

```text
首次运行下载了 ResNet18 backbone 权重，影响初始化时间，但不影响 step 稳定段吞吐。
数据集已在本地 cache，避免把 HF 下载时间计入训练速度。
```

## 4. 训练速度结果

### 4.1 MI300X 完整 20K 结果

MI300X 上同动作完整训练结果：

```text
动作: flipbreadtopot newway
数据集: phi-media-lab/rebot_flipbreadtopot_newway_20260425_49eps
训练长度: 20,000 steps
训练开始: 2026-04-25 15:51:19 UTC
训练结束: 2026-04-25 16:40:29 UTC
训练耗时: 2,950 秒 = 49 分 10 秒
吞吐: 406.8 step/min
单 step: 0.1475 秒
最终 loss: 0.070
```

MI300X 日志稳定段典型值：

```text
updt_s: 约 0.072s
data_s: 约 0.063-0.072s
```

### 4.2 L20 2K Benchmark 结果

L20 短跑结果：

```text
动作: flipbreadtopot newway
数据集: phi-media-lab/rebot_flipbreadtopot_newway_20260425_49eps
训练长度: 2,000 steps
训练开始: 2026-04-26 14:57:52 CST
训练结束: 2026-04-26 15:03:51 CST
训练耗时: 359 秒 = 5 分 59 秒
吞吐: 334.3 step/min
单 step: 0.1795 秒
2K loss: 0.838
```

L20 稳定段典型值：

```text
updt_s: 约 0.166s
data_s: 约 0.006s
```

GPU 状态：

```text
训练时 GPU util: 约 99%
训练时显存: 约 11.2GB / 46GB
训练时功耗: 约 297W
```

## 5. 直接对比

| 指标 | MI300X | 阿里云 L20 |
| --- | ---: | ---: |
| GPU | AMD Instinct MI300X VF | NVIDIA L20 |
| 框架后端 | PyTorch ROCm | PyTorch CUDA |
| 数据集 | flipbread newway 49eps | flipbread newway 49eps |
| batch size | 16 | 16 |
| 训练长度 | 20K 完整训练 | 2K 短跑 benchmark |
| 吞吐 | 406.8 step/min | 334.3 step/min |
| 单 step 时间 | 0.1475s | 0.1795s |
| 典型 `updt_s` | ~0.072s | ~0.166s |
| 典型 `data_s` | ~0.063-0.072s | ~0.006s |
| 显存占用 | 未单独记录峰值 | 约 11.2GB |
| 20K 训练估算 | 实测 49m10s | 估算约 59m50s |

按本次短跑估算：

```text
L20 比 MI300X 慢约 18%
MI300X 20K: 约 49-51 分钟
L20 20K: 约 60 分钟
```

## 6. 为什么 `updt_s/data_s` 看起来差异很大

MI300X：

```text
updt_s ~0.072s
data_s ~0.07s
```

L20：

```text
updt_s ~0.166s
data_s ~0.006s
```

这说明两台机器的瓶颈形态不同：

1. MI300X 上单次模型更新更快，但数据加载/视频 decode 占比更高。
2. L20 上数据加载非常快，主要瓶颈在模型 forward/backward/update。
3. L20 的 GPU util 接近 99%，说明训练计算侧已经吃满，进一步提速需要改 batch size、AMP、模型配置或 CUDA kernel 路径，而不是简单增加 data loader。

注意：两个环境的 LeRobot 版本不完全一致：

```text
MI300X: drtc-Phi ROCm 环境
L20: lerobot 0.4.3, torch 2.7.1+cu126
```

因此这不是严格硬件裸性能评测，而是“当前工程栈实际可用速度”的对比。

## 7. 可比性限制

本次 L20 只跑了 2K，没有完整跑 20K，因此 20K 时间是按短跑稳定段估算。

主要限制：

1. L20 首次运行下载了 ResNet18 权重，初始化时间不能用于比较。
2. L20 上仍有一个 idle DRTC server 占用约 2.8GB 显存，但 GPU util 为 0%，预计对速度影响很小。
3. L20 与 MI300X 的 LeRobot/PyTorch 后端不同，一个是 CUDA，一个是 ROCm。
4. MI300X 数据日志来自完整 20K，L20 来自 2K 短跑；loss 终值不能直接比较任务效果。
5. 训练效果最终仍需真实机械臂成功率验证，训练 loss 只能说明 supervised fitting 是否正常。

如果要做更严格对比，建议：

```text
停止 L20 上 idle DRTC server
确认 ResNet18 权重已缓存
同一数据集跑 5K 或 10K
采集 nvidia-smi dmon 日志
记录 peak VRAM、平均 GPU util、平均功耗
```

## 8. 工程结论

当前两台机器的定位建议：

### MI300X

适合：

```text
批量训练
完整 20K/更长 step 训练
多个动作连续产出 checkpoint
作为训练主力
```

理由：

```text
已经稳定完成 5 个 ACT 动作
20K 单动作约 50 分钟
吞吐约 400 step/min
训练流程已验证
```

### 阿里云 L20

适合：

```text
现场近距离推理服务
短程训练 benchmark
应急补训
本地低延迟 DRTC/ACT 服务
```

理由：

```text
本地 ping 约 18.8ms
GPU 显存 46GB 足够 ACT
2K benchmark 跑通
预计 20K 约 60 分钟，可接受
Docker/nvidia runtime 已具备
```

## 9. 当前判断

如果目标是最高训练效率，优先用 MI300X。

如果目标是比赛现场低延迟推理、就近部署、临时补训，阿里云 L20 已经足够可用。

综合判断：

```text
训练主力: MI300X
现场推理/近端服务: 阿里云 L20
应急训练备份: 阿里云 L20
```

当前 L20 的 benchmark 信息已经足够支撑算力选择，不需要为这个问题继续完整跑 20K。后续更重要的是把 5 个 ACT checkpoint 和 reComputer 真实控制链路打通，并用真实任务成功率评估模型效果。
