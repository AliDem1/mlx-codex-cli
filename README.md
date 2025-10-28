# Start MLX + Codex CLI Launcher

Launch any MLX-hosted large language model and connect it to the Codex CLI profile of your choice with one click.

This repo contains only source files (AppleScript + bash helpers) so you can audit, customize, and repackage the workflow however you like. Nothing in this repository depends on proprietary project code paths—every directory, model, and log target is configurable via environment variables.

---

## Architecture

| Component | Purpose |
|-----------|---------|
| `applescript/Start-MLX-Codex-CLI.applescript` | macOS launcher that opens two Terminal tabs: one to start the MLX server, one to wait for readiness and launch Codex. |
| `scripts/start_mzbac_mlx.sh` | Adapts the MIT-licensed `mzbac/mlx-lm` server launcher. Boots the specified MLX model, handles logging, and exposes `/v1/*` endpoints. |
| `scripts/codex_wait_mlx.sh` | Polls the MLX server until it responds, then launches Codex with the selected profile/reasoning effort (optionally via proxy). |

Flow:
1. AppleScript tab #1 executes `start_mzbac_mlx.sh` (optionally detached) to serve the model on `MLX_CODEX_HOST:MLX_CODEX_PORT`.
2. AppleScript waits one second, then tab #2 runs `codex_wait_mlx.sh`, which polls `/v1/models` until available.
3. Once ready, Codex CLI runs with your profile (e.g., `codex --profile mlx-codex-45 -c model_reasoning_effort=high`), targeting the MLX server as its OpenAI-compatible backend.

---

## Requirements

- macOS 13+ with Terminal and Script Editor (or Automator).
- Python 3.11+ virtual environment containing [`mlx-lm`](https://github.com/mzbac/mlx-lm) and its dependencies. The launcher looks for `mlx_lm.server` under `${MLX_CODEX_WORKSPACE}/.mlx-venv/bin`.
- LM Studio (optional) if you want its UI to manage downloads/models; you can also place MLX weights directly under `~/.lmstudio/models` or any directory.
- Codex CLI configured with the profile you plan to launch (defaults assume `mlx-codex-45` inside `~/codex-workspace`, but any profile name/path works).

---

## Quick Start

1. **Clone** this repository anywhere (default assumptions use `~/start-mlx-codex-cli`):
   ```bash
   git clone https://github.com/<you>/start-mlx-codex-cli.git ~/start-mlx-codex-cli
   ```
2. **Prepare** your MLX environment if you have not already:
   ```bash
   cd ~/codex-workspace   # or your workspace
   python3 -m venv .mlx-venv
   source .mlx-venv/bin/activate
   pip install mlx-lm
   ```
3. **Download** an MLX model (LM Studio UI or manual `huggingface-cli download ...`).
4. **Configure** optional environment variables (see table below) or edit the AppleScript if you prefer static values.
5. **Run directly**:
   ```bash
   cd ~/start-mlx-codex-cli
   MLX_CODEX_MODEL_PATH="$HOME/.lmstudio/models/your-model" \
   MLX_CODEX_PROFILE="your-codex-profile" \
   ./scripts/start_mzbac_mlx.sh "$MLX_CODEX_MODEL_PATH" "Your Model" 8080 &
   MLX_CODEX_PROFILE="your-codex-profile" \
   ./scripts/codex_wait_mlx.sh 127.0.0.1 8080 "$MLX_CODEX_PROFILE" "$HOME/your-workspace" high
   ```
6. **Or build the macOS app**:
   - Open `applescript/Start-MLX-Codex-CLI.applescript` in Script Editor.
   - Set any default env values inside the script (or rely on environment variables).
   - Choose **File → Export…**, select **Application**, and save (e.g., `Start MLX + Codex.app`).
   - Double-click the `.app` to launch both Terminal tabs automatically.

---

## Beginner-Friendly Setup Checklist

If you are new to MLX or Codex, follow these small steps in order:

1. **Install Command Line Tools** – run `xcode-select --install` once to ensure `git`, `make`, and compilers exist.
2. **Install Python 3.11+** – the built-in macOS Python is not enough; download from [python.org](https://www.python.org/) or use Homebrew (`brew install python@3.11`).
3. **Create the workspace** – choose a folder (e.g., `~/codex-workspace`) and run:
   ```bash
   mkdir -p ~/codex-workspace
   cd ~/codex-workspace
   python3 -m venv .mlx-venv
   source .mlx-venv/bin/activate
   pip install --upgrade pip
   pip install mlx-lm codex-cli
   ```
4. **Download your model** – open LM Studio or pull from Hugging Face. Place the model folder anywhere (the default uses `~/.lmstudio/models/...`).
5. **Clone this launcher** – `git clone https://github.com/<you>/start-mlx-codex-cli.git ~/start-mlx-codex-cli`.
6. **Set environment variables** – the safest approach is to create a `.env` file or export before launching:
   ```bash
   export MLX_CODEX_WORKSPACE=~/codex-workspace
   export MLX_CODEX_MODEL_PATH=~/.lmstudio/models/GLM-4.5-Air-MLX-8bit
   export MLX_CODEX_PROFILE=mlx-codex-45
   export MLX_CODEX_REASONING=high          # high reasoning is now stable with the penalties below
   export CHAT_ENABLE_THINKING=1            # keep GLM thinking enabled (output stays hidden in Codex CLI)
   # Penalties already baked in; export only if you want to override the defaults
   export CODEX_REPETITION_PENALTY=1.12     # mild sampler guard to prevent runaway loops
   export CODEX_FREQUENCY_PENALTY=0.15      # soft penalty that trims duplicate phrasing without muting answers
   export CODEX_PRESENCE_PENALTY=0.05       # gentle topic spread so Codex doesn’t latch onto the same detail
   ```
7. **Test from Terminal** – while the AppleScript adds convenience, first confirm the raw scripts work:
   ```bash
   cd ~/start-mlx-codex-cli
   DETACH=1 ./scripts/start_mzbac_mlx.sh "$MLX_CODEX_MODEL_PATH" "GLM 4.5 Air" 8080
   ./scripts/codex_wait_mlx.sh 127.0.0.1 8080 "$MLX_CODEX_PROFILE" "$MLX_CODEX_WORKSPACE" high
   ```
8. **Export the AppleScript** – once the manual run succeeds, open `applescript/Start-MLX-Codex-CLI.applescript` in Script Editor, export as an application, and keep it on your Desktop.

Performing steps manually once ensures that, if anything fails later, you can reproduce the exact command and inspect logs.

---

## Configuration

All tunables are environment variables. You can set them in your shell profile, in the AppleScript (before calling the bash scripts), or inline when launching.

| Variable | Default | Description |
|----------|---------|-------------|
| `MLX_CODEX_LAUNCHER_ROOT` | `~/start-mlx-codex-cli` | Location of this repo. |
| `MLX_CODEX_WORKSPACE` | `~/codex-workspace` | Workspace containing `.mlx-venv` and Codex profiles. |
| `MLX_CODEX_MODEL_PATH` | `~/.lmstudio/models/lmstudio-community/GLM-4.5-Air-MLX-8bit` | Directory containing the MLX weights to serve. |
| `MLX_CODEX_MODEL_NAME` | `GLM 4.5 Air` | Friendly name printed in logs. |
| `MLX_CODEX_HOST` | `127.0.0.1` | Hostname Codex will target. |
| `MLX_CODEX_PORT` | `8080` | Port for the MLX HTTP server. |
| `MLX_CODEX_PROFILE` | `mlx-codex-45` | Codex profile name. |
| `MLX_CODEX_REASONING` | `medium` | Reasoning effort flag passed to Codex (`-c model_reasoning_effort=`). Leave at `medium` if you want stock behavior, or set `high` together with the penalties above for the best GLM-4.6 experience. Set `SKIP_REASONING_FLAG=1` to omit. |
| `MLX_CODEX_LOG_FILE` | `~/Library/Logs/mzbac-mlx-lm-<port>.log` | Location for MLX server logs when running detached. |
| `MLX_CODEX_READINESS_TIMEOUT` | `300` | Seconds to wait for `/v1/models` before giving up. |
| `CHAT_ENABLE_THINKING` | `1` | Enables GLM “thinking” XML tokens when supported. Set `0` for models that do not implement the `<think>` stream. |
| `CODEX_REPETITION_PENALTY` | `1.12` | Codex CLI sampling override (override via env to change). Keeps high-reasoning traces from looping while still allowing the model to repeat important tokens. |
| `CODEX_FREQUENCY_PENALTY` | `0.15` | Codex CLI sampling override (override via env to change). Gently discourages verbatim restatements without muting necessary numbers or code. |
| `CODEX_PRESENCE_PENALTY` | `0.05` | Codex CLI sampling override (override via env to change). Nudges Codex toward fresh evidence while keeping summaries coherent. |
| `PROXY_BASE` | _(unset)_ | If Codex should call the MLX server through a proxy base URL. |

All scripts respect standard env expansion, so you can integrate them with launchd services, cron jobs, or other orchestrators.

---

## Model Compatibility

- **GLM 4.x (XML thinking tags)**: Supported out of the box. The launcher sets `--chat-template-args '{"enable_thinking":true}'` when `CHAT_ENABLE_THINKING=1`, and the Codex CLI now ships with light sampling penalties (`CODEX_REPETITION_PENALTY=1.12`, `CODEX_FREQUENCY_PENALTY=0.15`, `CODEX_PRESENCE_PENALTY=0.05`) so **high reasoning** is stable by default while `<think>` traces stay hidden from the terminal transcript. If you prefer to disable the XML stream completely, export `CHAT_ENABLE_THINKING=0` before launching.
- **Other MLX models (Qwen, Llama, Mistral, etc.)**: Also supported so long as `mlx_lm.server` can load them. Provide the correct `MLX_CODEX_MODEL_PATH` and disable GLM-specific flags if necessary. These models typically ignore unused arguments but you can be explicit with `CHAT_ENABLE_THINKING=0`.
- **LM Studio-managed servers**: If you prefer LM Studio’s in-app server instead of `mlx_lm.server`, skip `start_mzbac_mlx.sh` and point `codex_wait_mlx.sh` at LM Studio’s host/port. The rest of the workflow (readiness polling + Codex launch) is identical.

The Codex side is agnostic to XML tags—what matters is that the MLX server exposes an OpenAI-compatible `/v1/chat/completions` endpoint. If your chosen model lacks tool/function-calling, Codex will still run but any tool invocations will fail until you add that capability upstream.

---

## Running Without AppleScript

If you prefer pure terminal automation (CI jobs, launchd services, etc.), skip the `.app` entirely:

```bash
MLX_CODEX_MODEL_PATH=/path/to/model \
MLX_CODEX_WORKSPACE=/path/to/workspace \
DETACH=1 ./scripts/start_mzbac_mlx.sh "$MLX_CODEX_MODEL_PATH" "My Model" 8080

MLX_CODEX_WORKSPACE=/path/to/workspace \
MLX_CODEX_PROFILE=my-profile \
./scripts/codex_wait_mlx.sh 127.0.0.1 8080 my-profile "$MLX_CODEX_WORKSPACE" high
```

This is the same sequence the AppleScript follows, just without opening Terminal tabs.

---

## Logs & Troubleshooting

- **Server logs** live at `${MLX_CODEX_LOG_FILE}` when `DETACH=1`. Tail them to inspect token throughput or CUDA/MLX warnings.
- **Readiness failures**: `codex_wait_mlx.sh` tails the last 80 lines of the log if the MLX server never responds. Increase `MLX_CODEX_READINESS_TIMEOUT` for slower model loads.
- **Codex profile issues**: Pass `SKIP_REASONING_FLAG=1` if your profile doesn’t support reasoning flags, or specify `PROXY_BASE` if Codex must hit the MLX server through another host.

---

## Relationship to `mzbac/mlx-lm`

The `start_mzbac_mlx.sh` helper is adapted from the MIT-licensed [`mzbac/mlx-lm`](https://github.com/mzbac/mlx-lm) project; everything else (wait script, AppleScript, documentation) is original glue. See `THIRD_PARTY_NOTICES.md` for the required upstream notice.

---

## Rebuilding the macOS App

1. Open the AppleScript in Script Editor.
2. Choose **File → Export…**, select **Application**, and save (e.g., `Start MLX + Codex.app`).
3. Optionally add a custom icon (Finder → Get Info → drag `.icns` onto the icon placeholder).
4. Share the `.app` alongside this repo so users can recompile after auditing the source.

---

## License

Released under the MIT License (see `LICENSE`). Remember to preserve the third-party MIT notice from `mzbac/mlx-lm` if you distribute binaries.
