#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-flipbreadtopot}"
STEPS="${2:-2000}"

export SAVE_FREQ="${SAVE_FREQ:-10000}"
export LOG_FREQ="${LOG_FREQ:-100}"
export BATCH_SIZE="${BATCH_SIZE:-16}"
export RUN_NAME="${RUN_NAME:-rebot_act_${ACTION}_bench_b${BATCH_SIZE}_${STEPS}steps}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

"${REPO_ROOT}/scripts/train_act.sh" "$ACTION" "$STEPS"

LOG_FILE="${LOG_ROOT:-logs}/${RUN_NAME}.log"

python - "$LOG_FILE" "$STEPS" <<'PY'
import re
import sys
from datetime import datetime
from pathlib import Path

log_path = Path(sys.argv[1])
target_steps = int(sys.argv[2])
lines = log_path.read_text(errors="replace").splitlines()

start = end = None
records = []
for line in lines:
    m = re.search(r"INFO (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}).*Start offline training", line)
    if m:
        start = datetime.strptime(m.group(1), "%Y-%m-%d %H:%M:%S")

    m = re.search(r"INFO (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}).*End of training", line)
    if m:
        end = datetime.strptime(m.group(1), "%Y-%m-%d %H:%M:%S")

    m = re.search(
        r"INFO (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}).*step:(\d+)(K?) .*loss:([0-9.]+).*updt_s:([0-9.]+) data_s:([0-9.]+)",
        line,
    )
    if m:
        step = int(m.group(2)) * (1000 if m.group(3) else 1)
        records.append(
            {
                "time": datetime.strptime(m.group(1), "%Y-%m-%d %H:%M:%S"),
                "step": step,
                "loss": float(m.group(4)),
                "updt_s": float(m.group(5)),
                "data_s": float(m.group(6)),
            }
        )

print(f"log_file={log_path}")
if start and end:
    duration = (end - start).total_seconds()
    print(f"train_duration_sec={duration:.1f}")
    print(f"step_per_min={target_steps / (duration / 60):.2f}")
    print(f"sec_per_step={duration / target_steps:.4f}")

if records:
    stable = records[1:] if len(records) > 1 else records
    print(f"first_record={records[0]}")
    print(f"last_record={records[-1]}")
    print(f"avg_updt_s={sum(r['updt_s'] for r in stable) / len(stable):.4f}")
    print(f"avg_data_s={sum(r['data_s'] for r in stable) / len(stable):.4f}")
else:
    print("no_step_records_found")
PY
