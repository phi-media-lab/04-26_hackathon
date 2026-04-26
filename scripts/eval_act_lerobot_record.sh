#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/eval_act_lerobot_record.sh <action>

Actions:
  pickbreadpot
  flipbreadtopot
  pickbreadplate
  pickeggtopot
  pickeggtoplate

Environment overrides:
  FRONT_CAMERA=10
  WRIST_CAMERA=4
  ROBOT_PORT=/dev/ttyACM0
  TELEOP_PORT=/dev/ttyUSB0
  NUM_EPISODES=5
  EPISODE_TIME_S=60
  DATASET_FPS=30
  POLICY_DEVICE=cuda
  POLICY_PATH=/path/to/checkpoint
  DATASET_REPO_ID=Lisette1231/eval_xxx
EOF
}

if [[ $# -lt 1 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

ACTION="$1"

FRONT_CAMERA="${FRONT_CAMERA:-10}"
WRIST_CAMERA="${WRIST_CAMERA:-4}"
ROBOT_PORT="${ROBOT_PORT:-/dev/ttyACM0}"
TELEOP_PORT="${TELEOP_PORT:-/dev/ttyUSB0}"
NUM_EPISODES="${NUM_EPISODES:-5}"
EPISODE_TIME_S="${EPISODE_TIME_S:-60}"
DATASET_FPS="${DATASET_FPS:-30}"
POLICY_DEVICE="${POLICY_DEVICE:-cuda}"

case "$ACTION" in
  pickbreadpot)
    DEFAULT_DATASET_REPO_ID="Lisette1231/eval_20260426_act_pickbreadpot12"
    DEFAULT_SINGLE_TASK="pick the bread into the pot"
    DEFAULT_POLICY_PATH="outputs/train/pickbreadpot/checkpoint-020000"
    ;;
  flipbreadtopot)
    DEFAULT_DATASET_REPO_ID="Lisette1231/eval_20260426_act_flipbreadtopot5"
    DEFAULT_SINGLE_TASK="flip the bread in the pot"
    DEFAULT_POLICY_PATH="flipbreadtopot/checkpoint-020000"
    ;;
  pickbreadplate)
    DEFAULT_DATASET_REPO_ID="Lisette1231/eval_20260426_act_pickbreadplate2"
    DEFAULT_SINGLE_TASK="pick the bread on the plate"
    DEFAULT_POLICY_PATH="outputs/train/pickbreadplate/checkpoint-020000"
    ;;
  pickeggtopot)
    DEFAULT_DATASET_REPO_ID="Lisette1231/eval_20260426_act_pickeggtopot6"
    DEFAULT_SINGLE_TASK="pick the egg to the pot"
    DEFAULT_POLICY_PATH="outputs/pickeggtopot/checkpoint-020000"
    ;;
  pickeggtoplate)
    DEFAULT_DATASET_REPO_ID="Lisette1231/eval_20260426_act_pickeggtoplate9"
    DEFAULT_SINGLE_TASK="pick the egg to the plate"
    DEFAULT_POLICY_PATH="outputs/pickeggtoplate_checkpoint-020000"
    ;;
  *)
    echo "Unknown action: $ACTION" >&2
    usage >&2
    exit 2
    ;;
esac

DATASET_REPO_ID="${DATASET_REPO_ID:-$DEFAULT_DATASET_REPO_ID}"
SINGLE_TASK="${SINGLE_TASK:-$DEFAULT_SINGLE_TASK}"
POLICY_PATH="${POLICY_PATH:-$DEFAULT_POLICY_PATH}"

CAMERAS="{ front: {type: opencv, index_or_path: ${FRONT_CAMERA}, width: 640, height: 480, fps: 60, fourcc: \"MJPG\"}, wrist: {type: opencv, index_or_path: ${WRIST_CAMERA}, width: 640, height: 480, fps: 60, fourcc: \"MJPG\"}}"

echo "action=$ACTION"
echo "dataset.repo_id=$DATASET_REPO_ID"
echo "dataset.single_task=$SINGLE_TASK"
echo "policy.path=$POLICY_PATH"
echo "front_camera=$FRONT_CAMERA wrist_camera=$WRIST_CAMERA"
echo "robot_port=$ROBOT_PORT teleop_port=$TELEOP_PORT"

lerobot-record \
  --robot.type=seeed_b601_dm_follower \
  --robot.port="$ROBOT_PORT" \
  --robot.can_adapter=damiao \
  --robot.cameras="$CAMERAS" \
  --robot.id=follower1 \
  --display_data=true \
  --dataset.repo_id="$DATASET_REPO_ID" \
  --dataset.single_task="$SINGLE_TASK" \
  --policy.path="$POLICY_PATH" \
  --dataset.num_episodes="$NUM_EPISODES" \
  --dataset.episode_time_s="$EPISODE_TIME_S" \
  --policy.device="$POLICY_DEVICE" \
  --dataset.fps="$DATASET_FPS" \
  --teleop.type=rebot_arm_102_leader \
  --teleop.port="$TELEOP_PORT" \
  --teleop.id=rebot_arm_102_leader
