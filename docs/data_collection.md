# 数据采集流程

本文档记录本项目的 reBot 动作示范数据采集方式和采集效率。数据采集是整套 ACT 模仿学习流水线的起点，直接决定训练是否可用。

## 1. 采集目标

我们把完整烹饪任务拆成多个可学习的动作 primitive，每个 primitive 单独采集遥操作示范数据。

当前动作：

```text
flipbreadtopot
pickbreadplate
pickbreadpot
pickeggtopot
pickeggtoplate
```

每条 demonstration 对应一次完整动作尝试，例如：

```text
夹起面包 -> 移动到锅/盘 -> 放下
```

或：

```text
接近面包 -> 翻转 -> 放回锅中
```

## 2. 采集方式

采集阶段使用人工遥操作 reBot 完成动作，但遥操作不是最终比赛执行方式。

遥操作的作用是生成训练数据：

```text
human teleoperation
  -> synchronized observations and actions
  -> LeRobot dataset
  -> ACT supervised training
```

训练和部署后，关键动作由 ACT policy 输出 action，不再依赖人逐步遥操作完成。

## 3. 数据内容

每帧数据包含：

```text
observation.images.front: 前视相机图像
observation.images.wrist: 腕部相机图像
observation.state: 机械臂状态
action: 7DoF 动作
timestamp / frame_index / episode_index
```

实际训练使用的核心张量：

```text
observation.images.front: (3, 480, 640)
observation.images.wrist: (3, 480, 640)
action: (7,)
```

## 4. 采集效率

比赛现场实际采集效率约为：

```text
约 50 条有效 demonstrations / 小时
```

这里的“有效”指可以进入训练集的完整 episode，不包括明显失败、相机异常、动作中断、姿态偏离过大的样本。

这个效率很重要，因为它决定了新增动作的闭环时间：

```text
1 小时采集约 50 条有效示范
约 50 分钟完成 20K ACT 训练
数分钟上传 Hugging Face / 部署 checkpoint
```

因此，在当前流水线下，一个新动作从采集到可部署 checkpoint，理想情况下可以控制在约 2 小时内。

## 5. 当前已采集数据规模

| 动作 | 有效 episodes | frames | 备注 |
| --- | ---: | ---: | --- |
| `flipbreadtopot` | 49 | 20,648 | newway 版本 |
| `pickbreadplate` | 50 | 28,335 | 面包到盘 |
| `pickbreadpot` | 42 | 28,145 | 面包到锅 |
| `pickeggtopot` | 50 | 30,900 | 鸡蛋到锅 |
| `pickeggtoplate` | 50 | 30,355 | 跳过不完整第 5 组 |

合计：

```text
241 effective episodes
138,383 frames
```

## 6. 数据质量检查

每个原始 Hugging Face dataset 进入训练前，需要做以下检查：

1. `meta/tasks.parquet` 是否存在。
2. data parquet 是否存在。
3. front / wrist video 是否存在。
4. sample 是否可被 `LeRobotDataset(..., video_backend="pyav")` 读取。
5. `action.shape == (7,)`。
6. front / wrist 图像 shape 为 `(3, 480, 640)`。

示例检查代码：

```python
from lerobot.datasets.lerobot_dataset import LeRobotDataset

repos = [
    "Lisette1231/example_dataset1",
    "Lisette1231/example_dataset2",
]

for repo in repos:
    ds = LeRobotDataset(repo, video_backend="pyav")
    sample = ds[0]
    print(repo, ds.num_episodes, ds.num_frames)
    print(sample["action"].shape)
    print(sample["observation.images.front"].shape)
    print(sample["observation.images.wrist"].shape)
```

## 7. 常见数据问题

### 7.1 数据集上传不完整

例如 `20260426_pickeggtoplate5` 只包含：

```text
.gitattributes
README.md
meta/info.json
```

缺少：

```text
meta/tasks.parquet
data parquet
video files
```

这种数据集不能进入训练，只能跳过或重新上传。

### 7.2 多数据集合并后的 timestamp 问题

多个 LeRobot dataset 合并后，可能出现视频文件边界 timestamp 偏移错误。

典型错误：

```text
AssertionError: One or several query timestamps unexpectedly violate the tolerance
queried timestamps ...
loaded timestamps ...
```

处理方式：

```text
检查 meta/episodes parquet
确认每个 video file 的 duration
修正 from_timestamp / to_timestamp 或 file_index
重新跨边界抽样验证
```

## 8. 采集策略建议

为了最大化每小时有效数据量，采集时优先保证动作一致性，而不是追求极端多样性。

建议：

1. 每个动作先采 40-50 条稳定 demonstration。
2. 保持起始姿态、物体摆放和相机视角相对一致。
3. 如果动作成功率不足，再针对失败场景补采少量数据。
4. 每采完一组立即跑数据读取检查，避免最后发现整组数据不可用。
5. 不要把明显失败的 episode 混进训练集，否则 ACT 会模仿错误动作。

## 9. 和训练效率的关系

采集和训练的组合效率是本项目的核心优势。

```text
采集: 约 50 条有效 demonstrations / 小时
训练: MI300X 单动作 20K 约 50 分钟
部署: checkpoint 约 207 MB，可通过 Hugging Face 分发
```

这意味着我们可以在比赛现场快速迭代动作：

```text
发现某个动作不稳定
  -> 补采 20-50 条
  -> 重新训练 20K
  -> 上传 checkpoint
  -> reComputer 拉取部署
  -> 实机复测
```

这个闭环比单纯追求更大的模型更适合 48 小时黑客松。
