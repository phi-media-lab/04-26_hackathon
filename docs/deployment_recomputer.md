# reComputer 推理部署

本文档记录当前 reComputer / Jetson 端的 ACT 推理部署方案。

## 1. 当前推理方案

测试终端使用 LeRobot 原生 ACT 推理，不依赖 DRTC server/client。

```text
checkpoint -> ACTPolicy.from_pretrained -> 本地推理 -> 7DoF action
```

当前推理脚本：

```text
/home/recomputer/work/drtc-Phi/tools/rebot_act_local_infer.py
```

真实机械臂评测时，我们主要使用 `lerobot-record --policy.path=...` 加载 ACT checkpoint 并记录 eval episode。完整命令见 [local_inference_commands.md](local_inference_commands.md)。

## 2. reComputer 硬件与环境

已确认机器：

```text
Seeed reComputer Robotics Orin NX 16GB
Ubuntu 22.04
JetPack 6.2.1
L4T 36.4.3
CUDA driver 12.6
```

ACT venv：

```text
/home/recomputer/venvs/rebot-act
```

已安装：

```text
torch 2.5.0a0+872d972e41.nv24.08
LeRobot 0.4.1
```

注意：

```text
torchvision 存在 nms shim / torchvision.io warning。
当前对 ACT smoke test 可接受，但不是最终生产级干净环境。
```

## 3. 已部署 checkpoint

```text
/home/recomputer/models/rebot-act-flipbreadtopot-020000
/home/recomputer/models/rebot-act-pickbreadplate-020000
/home/recomputer/models/rebot-act-pickbreadpot-020000
```

待补齐：

```text
/home/recomputer/models/rebot-act-pickeggtopot-020000
/home/recomputer/models/rebot-act-pickeggtoplate-020000
```

## 4. 本地推理命令

```bash
ssh recomputer@10.42.0.254
cd /home/recomputer/work/drtc-Phi
source ~/venvs/rebot-act/bin/activate

python tools/rebot_act_local_infer.py --task flipbreadtopot
python tools/rebot_act_local_infer.py --task pickbreadplate
python tools/rebot_act_local_infer.py --task pickbreadpot
```

补齐模型和脚本映射后：

```bash
python tools/rebot_act_local_infer.py --task pickeggtopot
python tools/rebot_act_local_infer.py --task pickeggtoplate
```

## 5. 已测推理性能

| action | full chunk avg | full chunk Hz | cached action |
| --- | ---: | ---: | ---: |
| `flipbreadtopot` | 73.59 ms | 13.59 Hz | 0.901 ms |
| `pickbreadplate` | 72.39 ms | 13.81 Hz | 0.970 ms |
| `pickbreadpot` | 82.93 ms | 12.06 Hz | 0.885 ms |

解释：

```text
full chunk generation: 完整 ACT 模型前向，生成 50 步 action chunk。
cached action: 从已经生成的 chunk 中取下一步 action，不是完整模型前向。
```

## 6. 为什么适合比赛现场

ACT 的 chunked control 降低了实时推理压力：

```text
模型不需要每个控制 tick 都完整前向。
一次前向生成 50 步动作。
控制循环可以从 action queue 中逐步取动作。
```

这对烹饪任务比较合适，因为抓取、放置、翻转等动作对毫秒级远程 VLA 响应要求不高，更需要动作稳定和流程可恢复。

## 7. 后续部署 TODO

1. 把 `pickeggtopot` 和 `pickeggtoplate` 的 20K checkpoint 下载到 reComputer。
2. 更新 `tools/rebot_act_local_infer.py` 的 task mapping。
3. 对 5 个动作全部跑一次 smoke test。
4. 接入真实摄像头和机器人状态输入，替换构造 observation。
5. 加入 action safety clamp 和 emergency stop。
6. 把动作 primitive 接入菜谱状态机。
