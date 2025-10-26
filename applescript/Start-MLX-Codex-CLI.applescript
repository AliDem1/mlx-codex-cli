tell application "Terminal"
	activate
do script "bash -lc 'LAUNCHER_ROOT=\"${MLX_CODEX_LAUNCHER_ROOT:-$HOME/start-mlx-codex-cli}\"; WORKSPACE=\"${MLX_CODEX_WORKSPACE:-$HOME/codex-workspace}\"; cd \"$LAUNCHER_ROOT\"; LOG_FILE=\"${MLX_CODEX_LOG_FILE:-$HOME/Library/Logs/mzbac-mlx-lm-8080.log}\" DETACH=1 MLX_CODEX_WORKSPACE=\"$WORKSPACE\" ./scripts/start_mzbac_mlx.sh \"${MLX_CODEX_MODEL_PATH:-$HOME/.lmstudio/models/lmstudio-community/GLM-4.5-Air-MLX-8bit}\" \"${MLX_CODEX_MODEL_NAME:-GLM 4.5 Air}\" \"${MLX_CODEX_PORT:-8080}\"'"
end tell

delay 1

tell application "Terminal"
do script "bash -lc 'LAUNCHER_ROOT=\"${MLX_CODEX_LAUNCHER_ROOT:-$HOME/start-mlx-codex-cli}\"; WORKSPACE=\"${MLX_CODEX_WORKSPACE:-$HOME/codex-workspace}\"; cd \"$LAUNCHER_ROOT\"; LOG_FILE=\"${MLX_CODEX_LOG_FILE:-$HOME/Library/Logs/mzbac-mlx-lm-8080.log}\" READINESS_TIMEOUT=${MLX_CODEX_READINESS_TIMEOUT:-300} ./scripts/codex_wait_mlx.sh ${MLX_CODEX_HOST:-127.0.0.1} ${MLX_CODEX_PORT:-8080} ${MLX_CODEX_PROFILE:-mlx-codex-45} \"$WORKSPACE\" ${MLX_CODEX_REASONING:-medium}'"
end tell
