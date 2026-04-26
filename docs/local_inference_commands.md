# 本地 ACT 实机推理 / 评测命令

本文档记录比赛现场在测试终端上实际使用的 LeRobot 原生 ACT 实机评测入口。

这里的“推理”不是单独跑一个 policy server，而是通过 `lerobot-record` 同时完成：

1. 连接 reBot follower 机械臂。
2. 连接 front / wrist 双摄像头。
3. 加载 ACT checkpoint。
4. 执行 policy 输出动作。
5. 把评测过程记录成 eval dataset。
6. 保留 teleop leader 作为接管/辅助输入。

## 1. 公共硬件配置

```text
robot.type: seeed_b601_dm_follower
robot.port: /dev/ttyACM0
robot.can_adapter: damiao
robot.id: follower1

front camera:
  type: opencv
  index_or_path: 10
  width: 640
  height: 480
  fps: 60
  fourcc: MJPG

wrist camera:
  type: opencv
  index_or_path: 4
  width: 640
  height: 480
  fps: 60
  fourcc: MJPG

teleop.type: rebot_arm_102_leader
teleop.port: /dev/ttyUSB0
teleop.id: rebot_arm_102_leader

dataset.num_episodes: 5
dataset.episode_time_s: 60
dataset.fps: 30
policy.device: cuda
```

说明：

```text
teleop leader 保留在命令里，主要用于现场接管/安全/调试。
关键动作仍由 --policy.path 加载的 ACT policy 输出。
```

## 2. 推荐脚本入口

仓库提供统一脚本：

```bash
scripts/eval_act_lerobot_record.sh <action>
```

支持：

```text
pickbreadpot
flipbreadtopot
pickbreadplate
pickeggtopot
pickeggtoplate
```

示例：

```bash
scripts/eval_act_lerobot_record.sh pickbreadpot
scripts/eval_act_lerobot_record.sh flipbreadtopot
scripts/eval_act_lerobot_record.sh pickbreadplate
scripts/eval_act_lerobot_record.sh pickeggtopot
scripts/eval_act_lerobot_record.sh pickeggtoplate
```

如本地 checkpoint 路径不同，可以覆盖：

```bash
POLICY_PATH=/home/recomputer/models/rebot-act-pickbreadpot-020000 \
  scripts/eval_act_lerobot_record.sh pickbreadpot
```

## 3. 五个动作的现场命令

### 3.1 `pickbreadpot`

```bash
lerobot-record \
  --robot.type=seeed_b601_dm_follower \
  --robot.port=/dev/ttyACM0 \
  --robot.can_adapter=damiao \
  --robot.cameras='{ front: {type: opencv, index_or_path: 10, width: 640, height: 480, fps: 60, fourcc: "MJPG"}, wrist: {type: opencv, index_or_path: 4, width: 640, height: 480, fps: 60, fourcc: "MJPG"}}' \
  --robot.id=follower1 \
  --display_data=true \
  --dataset.repo_id=Lisette1231/eval_20260426_act_pickbreadpot12 \
  --dataset.single_task="pick the bread into the pot" \
  --policy.path=outputs/train/pickbreadpot/checkpoint-020000 \
  --dataset.num_episodes=5 \
  --dataset.episode_time_s=60 \
  --policy.device=cuda \
  --dataset.fps=30 \
  --teleop.type=rebot_arm_102_leader \
  --teleop.port=/dev/ttyUSB0 \
  --teleop.id=rebot_arm_102_leader
```

### 3.2 `flipbreadtopot`

```bash
lerobot-record \
  --robot.type=seeed_b601_dm_follower \
  --robot.port=/dev/ttyACM0 \
  --robot.can_adapter=damiao \
  --robot.cameras='{ front: {type: opencv, index_or_path: 10, width: 640, height: 480, fps: 60, fourcc: "MJPG"}, wrist: {type: opencv, index_or_path: 4, width: 640, height: 480, fps: 60, fourcc: "MJPG"}}' \
  --robot.id=follower1 \
  --display_data=true \
  --dataset.repo_id=Lisette1231/eval_20260426_act_flipbreadtopot5 \
  --dataset.single_task="flip the bread in the pot" \
  --policy.path=flipbreadtopot/checkpoint-020000 \
  --dataset.num_episodes=5 \
  --dataset.episode_time_s=60 \
  --policy.device=cuda \
  --dataset.fps=30 \
  --teleop.type=rebot_arm_102_leader \
  --teleop.port=/dev/ttyUSB0 \
  --teleop.id=rebot_arm_102_leader
```

### 3.3 `pickbreadplate`

```bash
lerobot-record \
  --robot.type=seeed_b601_dm_follower \
  --robot.port=/dev/ttyACM0 \
  --robot.can_adapter=damiao \
  --robot.cameras='{ front: {type: opencv, index_or_path: 10, width: 640, height: 480, fps: 60, fourcc: "MJPG"}, wrist: {type: opencv, index_or_path: 4, width: 640, height: 480, fps: 60, fourcc: "MJPG"}}' \
  --robot.id=follower1 \
  --display_data=true \
  --dataset.repo_id=Lisette1231/eval_20260426_act_pickbreadplate2 \
  --dataset.single_task="pick the bread on the plate" \
  --policy.path=outputs/train/pickbreadplate/checkpoint-020000 \
  --dataset.num_episodes=5 \
  --dataset.episode_time_s=60 \
  --policy.device=cuda \
  --dataset.fps=30 \
  --teleop.type=rebot_arm_102_leader \
  --teleop.port=/dev/ttyUSB0 \
  --teleop.id=rebot_arm_102_leader
```

### 3.4 `pickeggtopot`

```bash
lerobot-record \
  --robot.type=seeed_b601_dm_follower \
  --robot.port=/dev/ttyACM0 \
  --robot.can_adapter=damiao \
  --robot.cameras='{ front: {type: opencv, index_or_path: 10, width: 640, height: 480, fps: 60, fourcc: "MJPG"}, wrist: {type: opencv, index_or_path: 4, width: 640, height: 480, fps: 60, fourcc: "MJPG"}}' \
  --robot.id=follower1 \
  --display_data=true \
  --dataset.repo_id=Lisette1231/eval_20260426_act_pickeggtopot6 \
  --dataset.single_task="pick the egg to the pot" \
  --policy.path=outputs/pickeggtopot/checkpoint-020000 \
  --dataset.num_episodes=5 \
  --dataset.episode_time_s=60 \
  --policy.device=cuda \
  --dataset.fps=30 \
  --teleop.type=rebot_arm_102_leader \
  --teleop.port=/dev/ttyUSB0 \
  --teleop.id=rebot_arm_102_leader
```

原始命令中 `single_task` 写成了 `pick the edd to the pot`，这里修正为 `pick the egg to the pot`。

### 3.5 `pickeggtoplate`

```bash
lerobot-record \
  --robot.type=seeed_b601_dm_follower \
  --robot.port=/dev/ttyACM0 \
  --robot.can_adapter=damiao \
  --robot.cameras='{ front: {type: opencv, index_or_path: 10, width: 640, height: 480, fps: 60, fourcc: "MJPG"}, wrist: {type: opencv, index_or_path: 4, width: 640, height: 480, fps: 60, fourcc: "MJPG"}}' \
  --robot.id=follower1 \
  --display_data=true \
  --dataset.repo_id=Lisette1231/eval_20260426_act_pickeggtoplate9 \
  --dataset.single_task="pick the egg to the plate" \
  --policy.path=outputs/pickeggtoplate_checkpoint-020000 \
  --dataset.num_episodes=5 \
  --dataset.episode_time_s=60 \
  --policy.device=cuda \
  --dataset.fps=30 \
  --teleop.type=rebot_arm_102_leader \
  --teleop.port=/dev/ttyUSB0 \
  --teleop.id=rebot_arm_102_leader
```

## 4. 和离线 smoke test 的区别

之前的 `tools/rebot_act_local_infer.py` 用于离线 smoke test：

```text
构造 observation -> ACTPolicy.forward -> 输出 action
```

本文档里的 `lerobot-record` 命令是实机评测入口：

```text
真实相机 + 真实机械臂状态 + ACT checkpoint + 记录 eval episode
```

因此，比赛展示时应优先引用本页命令。

## 5. 注意事项

1. camera index `10` 和 `4` 是现场机器的实际编号，换机器后可能变化。
2. `policy.path` 是现场路径，不一定等于 Hugging Face repo 名。
3. `dataset.repo_id` 是评测 episode 的输出 repo，不是训练数据源。
4. `display_data=true` 方便现场观察，但可能略增运行开销。
5. 真实机械臂运行前必须确认急停、安全员、工作区无干涉。
