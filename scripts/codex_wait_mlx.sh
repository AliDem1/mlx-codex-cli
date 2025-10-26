#!/usr/bin/env bash
set -euo pipefail

# Wait for a local MLX server to expose /v1/models, then launch Codex.
#
# Usage:
#   scripts/launch/codex_wait_mlx.sh [HOST] [PORT] [CODEX_PROFILE] [WORKDIR] [REASONING]
#
# Defaults:
#   HOST=127.0.0.1
#   PORT=8080
#   CODEX_PROFILE=mlx-codex-45
#   WORKDIR=$HOME/codex-workspace
#   REASONING=medium
#   Set SKIP_REASONING_FLAG=1 to omit the Codex reasoning flag entirely
#
# Env:
#   READINESS_TIMEOUT=300   # seconds to wait before failing
#   LOG_FILE=~/Library/Logs/mzbac-mlx-lm-<PORT>.log

HOST=${1:-127.0.0.1}
PORT=${2:-8080}
PROFILE=${3:-mlx-codex-45}
WORKDIR=${4:-"${MLX_CODEX_WORKSPACE:-$HOME/codex-workspace}"}
REASONING=${5:-medium}

BASE_URL="http://${HOST}:${PORT}/v1"
TIMEOUT=${READINESS_TIMEOUT:-300}
LOG_FILE=${LOG_FILE:-"$HOME/Library/Logs/mzbac-mlx-lm-${PORT}.log"}

echo "[codex-wait-mlx] waiting for server on :${PORT} ..."

start_ts=$(date +%s)
while :; do
  if curl -sf "${BASE_URL}/models" >/dev/null; then
    break
  fi
  now=$(date +%s)
  if (( now - start_ts >= TIMEOUT )); then
    echo "[codex-wait-mlx] ERROR: server not ready after ${TIMEOUT}s; aborting." >&2
    if [[ -f "$LOG_FILE" ]]; then
      echo "[codex-wait-mlx] tailing log: $LOG_FILE" >&2
      tail -n 80 "$LOG_FILE" || true
    else
      echo "[codex-wait-mlx] log file not found: $LOG_FILE" >&2
    fi
    exit 1
  fi
  sleep 1
done

if [[ "${SKIP_REASONING_FLAG:-}" == "1" ]]; then
  echo "[codex-wait-mlx] server ready; launching Codex (profile=${PROFILE}, reasoning=default)"
else
  echo "[codex-wait-mlx] server ready; launching Codex (profile=${PROFILE}, reasoning=${REASONING})"
fi
cd "$WORKDIR"
if [[ "${SKIP_REASONING_FLAG:-}" == "1" ]]; then
  if [[ -n "${PROXY_BASE:-}" ]]; then
    exec codex --profile "$PROFILE" -c model_providers.mlx.base_url="$PROXY_BASE"
  else
    exec codex --profile "$PROFILE"
  fi
else
  if [[ -n "${PROXY_BASE:-}" ]]; then
    exec codex --profile "$PROFILE" \
      -c model_providers.mlx.base_url="$PROXY_BASE" \
      -c model_reasoning_effort="$REASONING"
  else
    exec codex --profile "$PROFILE" -c model_reasoning_effort="$REASONING"
  fi
fi
