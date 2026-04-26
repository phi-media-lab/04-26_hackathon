#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/train_act.sh <action> [steps]

Actions:
  flipbreadtopot
  pickbreadplate
  pickbreadpot
  pickeggtopot
  pickeggtoplate

Environment overrides:
  BATCH_SIZE=16
  SAVE_FREQ=10000
  LOG_FREQ=100
  NUM_WORKERS=4
  OUTPUT_ROOT=outputs/train
  LOG_ROOT=logs
  DATASET_ROOT=/path/to/local/lerobot/dataset
  CUDA_VISIBLE_DEVICES=0
  HIP_VISIBLE_DEVICES=0

Examples:
  scripts/train_act.sh flipbreadtopot 20000
  DATASET_ROOT=/root/.cache/huggingface/lerobot/phi-media-lab/rebot_flipbreadtopot_newway_20260425_49eps scripts/train_act.sh flipbreadtopot 2000
EOF
}

if [[ $# -lt 1 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

ACTION="$1"
STEPS="${2:-20000}"
BATCH_SIZE="${BATCH_SIZE:-16}"
SAVE_FREQ="${SAVE_FREQ:-10000}"
LOG_FREQ="${LOG_FREQ:-100}"
NUM_WORKERS="${NUM_WORKERS:-4}"
OUTPUT_ROOT="${OUTPUT_ROOT:-outputs/train}"
LOG_ROOT="${LOG_ROOT:-logs}"

case "$ACTION" in
  flipbreadtopot)
    DATASET_REPO="phi-media-lab/rebot_flipbreadtopot_newway_20260425_49eps"
    RUN_BASENAME="rebot_act_flipbread_newway_49eps"
    ;;
  pickbreadplate)
    DATASET_REPO="phi-media-lab/rebot_pickbreadplate_20260425_50eps"
    RUN_BASENAME="rebot_act_pickbreadplate_50eps"
    ;;
  pickbreadpot)
    DATASET_REPO="phi-media-lab/rebot_pickbreadpot_20260425_42eps"
    RUN_BASENAME="rebot_act_pickbreadpot_42eps"
    ;;
  pickeggtopot)
    DATASET_REPO="phi-media-lab/rebot_pickeggtopot_20260426_50eps"
    RUN_BASENAME="rebot_act_pickeggtopot_50eps"
    ;;
  pickeggtoplate)
    DATASET_REPO="phi-media-lab/rebot_pickeggtoplate_20260426_50eps_skip5"
    RUN_BASENAME="rebot_act_pickeggtoplate_50eps_skip5"
    ;;
  *)
    echo "Unknown action: $ACTION" >&2
    usage >&2
    exit 2
    ;;
esac

if ! command -v lerobot-train >/dev/null 2>&1; then
  echo "lerobot-train not found. Activate the LeRobot training environment first." >&2
  exit 127
fi

mkdir -p "$OUTPUT_ROOT" "$LOG_ROOT"

RUN_NAME="${RUN_NAME:-${RUN_BASENAME}_b${BATCH_SIZE}_${STEPS}steps}"
OUTPUT_DIR="${OUTPUT_ROOT}/${RUN_NAME}"
LOG_FILE="${LOG_ROOT}/${RUN_NAME}.log"

DATASET_ARGS=(--dataset.repo_id="$DATASET_REPO")
if [[ -n "${DATASET_ROOT:-}" ]]; then
  DATASET_ARGS+=(--dataset.root="$DATASET_ROOT")
fi

export CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-0}"
export HIP_VISIBLE_DEVICES="${HIP_VISIBLE_DEVICES:-0}"

echo "action=$ACTION"
echo "dataset=$DATASET_REPO"
if [[ -n "${DATASET_ROOT:-}" ]]; then
  echo "dataset_root=$DATASET_ROOT"
fi
echo "steps=$STEPS"
echo "batch_size=$BATCH_SIZE"
echo "output_dir=$OUTPUT_DIR"
echo "log_file=$LOG_FILE"

lerobot-train \
  --policy.type=act \
  --policy.chunk_size=50 \
  --policy.n_action_steps=50 \
  --policy.push_to_hub=false \
  "${DATASET_ARGS[@]}" \
  --dataset.video_backend=pyav \
  --batch_size="$BATCH_SIZE" \
  --steps="$STEPS" \
  --eval_freq=0 \
  --save_freq="$SAVE_FREQ" \
  --log_freq="$LOG_FREQ" \
  --num_workers="$NUM_WORKERS" \
  --wandb.enable=false \
  --output_dir="$OUTPUT_DIR" 2>&1 | tee "$LOG_FILE"
