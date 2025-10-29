#!/usr/bin/env bash
set -euo pipefail

# Single source of truth launcher for mzbac/mlx-lm server.
# Usage:
#   scripts/launch/start_mzbac_mlx.sh \
#     "/Users/you/.lmstudio/models/lmstudio-community/GLM-4.5-Air-MLX-8bit" \
#     "GLM 4.5 Air" [port]

MODEL_PATH=${1:-}
HUMAN_NAME=${2:-default_model}
PORT=${3:-8080}

# Optional behavior via env:
#   DETACH=1         → background server and write logs to LOG_FILE
#   LOG_FILE=path    → file to write logs (default: ~/Library/Logs/mzbac-mlx-lm-<PORT>.log)
#   LOG_LEVEL=level  → pass --log-level LEVEL to server (e.g., DEBUG|INFO)

TAG="[mzbac-mlx-lm]"

if [[ -z "${MODEL_PATH}" ]]; then
  echo "$TAG missing MODEL_PATH argument" >&2
  exit 1
fi

# Optional startup banner (disable with PRINT_BANNER=0)
if [[ "${PRINT_BANNER:-1}" == "1" ]]; then
  printf '%s\n' 'You are running in a Mac operating system. You have access to the command line which you can use. Plain-string commands only; no arrays.'
fi

export PYTHONNOUSERSITE=1
PROJECT_ROOT="${MLX_CODEX_WORKSPACE:-$HOME/codex-workspace}"
VENV_BIN="$PROJECT_ROOT/.mlx-venv/bin"
SERVER_BIN="$VENV_BIN/mlx_lm.server"

if [[ ! -x "$SERVER_BIN" ]]; then
  echo "$TAG mlx_lm.server not found at $SERVER_BIN" >&2
  echo "$TAG ensure venv is installed under \$MLX_CODEX_WORKSPACE/.mlx-venv and contains mlx-lm (pip install mlx-lm)" >&2
  exit 1
fi

if [[ ! -d "$MODEL_PATH" ]]; then
  echo "$TAG model path does not exist: $MODEL_PATH" >&2
  exit 1
fi

echo "$TAG stopping any server on :$PORT ..."
(lsof -ti:"$PORT" | xargs kill -9) >/dev/null 2>&1 || true
pkill -f mlx_lm.server >/dev/null 2>&1 || true

echo "$TAG starting $HUMAN_NAME on :$PORT ..."
echo "$TAG model path: $MODEL_PATH"

# Ensure compatible MLX version (mlx-lm 0.26.x expects MLX <=0.26.x APIs)
"$VENV_BIN"/python3 - <<'PY' || true
import importlib.metadata as m
def v(p):
  try:
    return m.version(p)
  except Exception:
    return "?"
print("mlx-lm", v("mlx-lm"))
print("mlx", v("mlx"))
PY

# Build command (optional thinking in chat template)
# Control via CHAT_ENABLE_THINKING env var: 1 (default) enables, 0 disables.
if [[ "${CHAT_ENABLE_THINKING:-1}" == "1" ]]; then
  CMD=("$SERVER_BIN" --model "$MODEL_PATH" --port "$PORT" --chat-template-args '{"enable_thinking":true}')
else
  CMD=("$SERVER_BIN" --model "$MODEL_PATH" --port "$PORT")
fi
if [[ -n "${LOG_LEVEL:-}" ]]; then
  CMD+=(--log-level "${LOG_LEVEL}")
fi

if [[ "${DETACH:-}" == "1" ]]; then
  # Determine log file
  if [[ -z "${LOG_FILE:-}" ]]; then
    LOG_DIR="$HOME/Library/Logs"
    mkdir -p "$LOG_DIR"
    LOG_FILE="$LOG_DIR/mzbac-mlx-lm-${PORT}.log"
  else
    mkdir -p "$(dirname "$LOG_FILE")" || true
  fi
  echo "$TAG logging to $LOG_FILE"
  nohup "${CMD[@]}" >>"$LOG_FILE" 2>&1 &
  echo "$TAG pid $!"
  exit 0
else
  exec "${CMD[@]}"
fi
