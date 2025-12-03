# AI Agent Quickstart — WORLD_OLLAMA

**Project Type:** Local-first AI stack — Tauri/Svelte desktop client + LightRAG GraphRAG + Ollama + LLaMA Factory fine-tuning  
**Target Platform:** Windows 11, RTX GPU (16GB VRAM), PowerShell-first automation  
**Current Version:** v0.3.1 (Preview Release) — Flows automation + bugfix pack  
**Release Date:** 02.12.2025  
**GitHub:** https://github.com/Zasada1980/WorldOllama

## Path Resolution (CRITICAL)
**NEVER hardcode `E:\WORLD_OLLAMA`.** Always use:
- **Rust:** `crate::utils::get_project_root()` returns `PathBuf`
- **Python:** Check `WORLD_OLLAMA_ROOT` env var, fallback to `Path(__file__).resolve().parent.parent.parent`
- **PowerShell:** `$ProjectRoot = $PSScriptRoot` or param with default

Example (Rust):
```rust
let project_root = crate::utils::get_project_root();
let script_path = project_root.join("scripts").join("ingest_watcher.ps1");
```

## MCP Shell Server — Production Tool
**Use `myshell/execute_command` for all PowerShell** unless visual progress needed. Provides:
- **Auto Base64 encoding:** Eliminates Exit Code 255 for pipes `|`, braces `{}`, variables `$` (94.44% test coverage)
- **Circuit Breaker:** After 3 failures → `fallbackSuggested=true`, switch to `run_in_terminal`
- **Smart Retries:** Fast cmds retry 2×1s, medium 1×5s, long no retry (idempotent only)
- **Watchdog:** Kills hung processes after 30s no output; adaptive timeouts 60s/120s/900s
- **Error UX:** Russian `userMessage` for common failures (file not found, access denied)

**When to use MCP:**
- Health checks: `Test-NetConnection`, `ollama list | Select-String`, `nvidia-smi`
- Git operations: `git status --porcelain`, `git log origin/main..HEAD`
- Quick reads: `Get-Content`, `Test-Path`, complex pipelines

**When to fallback to terminal:**
- `meta.fallbackSuggested=true` (circuit breaker open)
- Visual progress: `npm run tauri dev`, `START_ALL.ps1`, training UI
- Background services: `isBackground=true` for long-running servers

**Verify:** `pwsh mcp-shell/test_phase1_edge_cases.ps1` → 17/18 PASS. Logs: `logs/mcp/mcp-events.log`

## Automatic Indexation Tools (v2.0 — 03.12.2025)

**Three automation mechanisms** for keeping `RUNTIME_LOGS_JOURNAL_INDEX.md` up-to-date (Consensus.app Research + Agent Testing validated):

### 1. FileSystemWatcher (Real-time)
**Script:** `scripts/WATCH_FILE_CHANGES.ps1`  
**Purpose:** Monitor `.md` files and trigger incremental reindexing on changes  
**Features:**
- Debounce 2s (prevents excessive updates)
- Excludes: venv, node_modules, archive, llamaboard_cache
- Heartbeat every 10 min
- Logs: `logs/file_watcher.log`

**Usage (MCP Shell — recommended):**
```json
{
  "tool": "mcp_myshell_execute_command",
  "parameters": {
    "command": "pwsh -File scripts\\WATCH_FILE_CHANGES.ps1",
    "isBackground": true
  }
}
```
**Notes:** Monitor `meta.breakerState`; fallback to `run_in_terminal` if `OPEN`. Infinite loop requires `isBackground: true`.

**Usage (Terminal — fallback):**
```powershell
# From repo root
pwsh -File scripts\WATCH_FILE_CHANGES.ps1
```

**Management:**
```powershell
# Check status
Get-Process pwsh | Where-Object { $_.CommandLine -like "*WATCH_FILE_CHANGES*" }

# Stop watcher
$watcher = Get-Process pwsh | Where-Object { $_.CommandLine -like "*WATCH_FILE_CHANGES*" }
if ($watcher) { Stop-Process -Id $watcher.Id -Force }

# Tail logs
Get-Content logs\file_watcher.log -Tail 20 -Wait
```

### 2. Git Post-Commit Hook (On-commit)
**Scripts:** `scripts/post-commit.hook` + `scripts/INSTALL_GIT_HOOK.ps1`  
**Purpose:** Automatic reindexing after Git commits with `.md` changes  
**Installation:**
```powershell
pwsh scripts\INSTALL_GIT_HOOK.ps1
```
**Verification:**
```powershell
Test-Path .git\hooks\post-commit  # Should return True
```
**Trigger:** Runs after each `git commit` if `.md` files changed (non-blocking, won't fail commit on errors)

### 3. Windows Scheduled Task (Daily)
**Script:** `scripts/CREATE_SCHEDULED_TASK.ps1`  
**Purpose:** Full reindexing daily at 03:00 (cleanup accumulated errors)  
**Installation (requires admin):**
```powershell
# Create task (default: daily at 03:00)
pwsh scripts\CREATE_SCHEDULED_TASK.ps1

# Create with custom time
pwsh scripts\CREATE_SCHEDULED_TASK.ps1 -ExecutionTime "02:30"

# Remove task
pwsh scripts\CREATE_SCHEDULED_TASK.ps1 -RemoveTask
```
**Verification:**
```powershell
Get-ScheduledTask -TaskName "WORLD_OLLAMA_Daily_Reindex"
# Manually trigger (test)
Start-ScheduledTask -TaskName "WORLD_OLLAMA_Daily_Reindex"
# Check result (0=success)
(Get-ScheduledTaskInfo -TaskName "WORLD_OLLAMA_Daily_Reindex").LastTaskResult
```

### Core Reindexing Script
**Script:** `scripts/UPDATE_PROJECT_INDEX.ps1`  
**Modes:**
```powershell
# Incremental (1-5 files, <500ms)
pwsh scripts\UPDATE_PROJECT_INDEX.ps1 -IncrementalMode -TriggerFile "path.md"

# Full (all files, ~870ms for 166 files)
pwsh scripts\UPDATE_PROJECT_INDEX.ps1 -FullReindex
```
**Updates:** `docs/project/RUNTIME_LOGS_JOURNAL_INDEX.md` metadata (file counts, timestamps, coverage period)  
**Logs:** `logs/indexation.log`

**Summary:** Use all three mechanisms together — FileSystemWatcher (development), Git Hook (CI/CD), Scheduled Task (safety net). Overhead: ~0.001% (1s/day).

## Architecture & Data Flows

### Training Pipeline (UI → Rust → PowerShell → Python)
```
TrainingPanel.svelte (UI validation: epochs 1-5, profile whitelist)
  ↓ POST /api/training/start
client/src/lib/api/client.ts (startTrainingJob)
  ↓ Tauri invoke
client/src-tauri/src/commands.rs (start_training_job)
  ↓ PowerShell call
scripts/start_agent_training.ps1 (params validation)
  ↓ llamafactory-cli
services/llama_factory/src/train.py
  ↓ writes atomically (os.replace)
training_status.json
  ↑ polled by training_manager.rs (2-10s adaptive)
  ↓ emit Tauri event
UI updates (PULSE v1 protocol: idle/running/done/error)
```
**Key files:** `commands.rs::start_training_job`, `start_agent_training.ps1`, `training_manager.rs::start_polling`, `TrainingPanel.svelte`

### CORTEX RAG Pipeline (GraphRAG with LightRAG)
```
UI query → client/src/lib/api/client.ts
  ↓ POST http://localhost:8004/query
services/lightrag/lightrag_server.py (FastAPI)
  ↓ LightRAG(mode="hybrid", enable_rerank=False)
  ↓ ollama_model_complete("qwen2.5:14b")
  ↓ ollama_embed("nomic-embed-text")
Ollama (http://localhost:11434)
  ↓ returns context + answer
lightrag_server.py → JSON response
  ↓ back to UI
ChatPanel.svelte renders sources + chain-of-thought
```
**Health check:** `Invoke-RestMethod http://localhost:8004/health` or `curl http://localhost:11434/api/tags`  
**GPU telemetry:** `nvidia-smi --query-gpu=memory.used --format=csv,noheader` (>6 GB = embeddings loaded)  
**Chunking:** Fixed ~10 KB in `lightrag_server.py`, token budget <4k/chunk for Ollama limits

## Documentation Compass

**ALWAYS start with consolidated reports** before touching code:
- **UI tasks** (TASK 4-16, ORDER 33-42, ORDER 52) → `docs/tasks/TASKS_CONSOLIDATED_REPORT.md` (полные спецификации + тестирование)
- **Models/training** (TD-010v2/v3, fine-tuning) → `docs/models/MODELS_CONSOLIDATED_REPORT.md`
- **Infrastructure** (CORTEX, security, RAG, tools audit) → `docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md`
- **Tools cleanup** (VS Code extensions) → `docs/infra/TOOLS_CLEANUP_RESULTS.md` (71 → 51 расширений, конфликты решены)

**Architecture/status questions:**
1. `PROJECT_MAP.md` — directory structure, ignored folders, generation protocol
2. `PROJECT_STATUS_SNAPSHOT_v4.0.md` — current phase (v0.3.1 Released 02.12.2025), ORDER 40+52 COMPLETE, known blockers (ORDER 43 - HF gated models)
3. `README.md` — user-facing features, quick start, troubleshooting, релиз v0.3.1
4. `DOCUMENTATION_INDEX.md` — полная карта документации (68 файлов, консолидированные отчёты)

**Task-specific deep dives:** Cross-referenced in consolidated reports (e.g., `client/TASK8_COMPLETION_REPORT.md` for Command DSL details)

## Core Workflows
- **Start stack:** `pwsh scripts/START_ALL.ps1`, then `pwsh scripts/CHECK_STATUS.ps1 -Detailed`. Desktop client (6 panels + ⚡ Flows) expects CORTEX up before `npm run tauri dev`.
- **Flows automation:** JSON definitions live in `automation/flows/*.json`, executed through `FlowExecutor` in `client/src-tauri/src/flow_manager.rs`. Every run logs JSON lines to `logs/flows/flow_{id}_{timestamp}.jsonl`; inspect there when troubleshooting multi-step failures.
- **Training:** Allowed epochs 1-5, profiles restricted to whitelisted names (see `start_training_job` and `scripts/start_agent_training.ps1`). If the HF base model is gated (ORDER 43), either `huggingface-cli login` or switch to the open config in `services/llama_factory/config/llama3_lora_sft.yaml`. Track progress via `services/llama_factory/training_status.json` and `logs/training/train-*.log`.
- **Safe Git Assistant:** Tauri command `plan_git_push` enforces seven blockers (unstaged changes, wrong branch, remote ahead, etc.) before `execute_git_push`. Always re-run the plan right before pushing; UI mirrors the Rust validations.

## Project Conventions

**PowerShell automation:**
- Use JSON logs (one object per line) for all orchestration — compatible with `FlowLogger` in `flow_manager.rs`
- Always use `$ErrorActionPreference = "Stop"` for fail-fast behavior
- Log format: `[timestamp] [LEVEL] message` to `logs/orchestrator.log`

**RAG/CORTEX constraints:**
- LightRAG chunking: fixed ~10 KB in `lightrag_server.py`
- Token budget: <4k per chunk (Ollama context window limits)
- Never re-index without checking `services/lightrag/data/kv_store_doc_status.json`
- Rerank disabled (`enable_rerank=False`) due to stability issues (see PLAN C baseline)

**Tauri/Rust patterns:**
- All Tauri commands return `ApiResponse<T>` (see `commands.rs::ApiResponse`)
- Use `crate::utils::get_project_root()` for path operations — never `current_exe()` directly
- Settings persistence: `%APPDATA%/WorldOllama` via `settings.rs`
- Profile switching: check `client/src/lib/stores/settings.ts` for state management

**Code style:**
- Rust: Follow existing pattern of extensive comments with ORDER/TASK references
- Svelte: Reactive statements (`$:`) for derived state, avoid imperative updates
- Python: Type hints required, use `Path` objects not string concatenation for file paths

## Testing & Verification
- UI/bridge smoke tests live in `client/run_auto_tests.ps1`, `client/test_task4_scenarios.ps1`, `client/test_task5_settings.ps1`; run them from repo root with PowerShell.
- For release builds use `pwsh scripts/BUILD_RELEASE.ps1`; manual fallback is `npm run tauri build` (output in `client/src-tauri/target/release`).
- Before claiming GPU-intensive work succeeded, quote real telemetry: `nvidia-smi`, `ollama list`, log tails from `logs/services` or `logs/mcp`.

## When Things Break
- Dockerized Ollama is unsupported on this host—if you see `/usr/bin/ollama runner` in logs, stop/remove the container and ensure native Ollama answers `curl http://localhost:11434/api/tags`.
- If the MCP circuit breaker opens (meta `breakerState="OPEN"`), pause MCP usage, switch the next command to a terminal, then probe `myshell/health_check` after ~5 s before resuming structured calls.
- **MCP meta field reference:** Every `execute_command` response includes `meta: { breakerState, classification, consecutiveFailures, fallbackSuggested, durationMs, retryAttempt, maxRetries, errorCode?, userMessage? }`. Use `classification` for debugging: `timeout_exec` (>120s), `no_output_timeout` (hung), `exec_error` (Exit Code >0), `spawn_error`, `file_not_found`, `access_denied`, `path_issue`. Agent should report `userMessage` to user when present.
- **Performance thresholds:** Fast commands <500ms, medium <5s, long 30-300s expected. If `durationMs` exceeds 2× → investigate system load. Check `logs/mcp/mcp-events.log` for execution history.
- **Concurrency limit:** Max 5 concurrent `execute_command` calls. Requests beyond this queue automatically (no agent action needed).

## MCP Testing & Verification
- **Smoke test:** `myshell/health_check` → expect `{status: "ok", breakerState: "CLOSED"}`. If degraded, wait 5s and retry.
- **Edge case suite:** `pwsh mcp-shell/test_phase1_edge_cases.ps1` → 17/18 PASS validates Base64 encoding. Test 16 (port 8004 check) fails if CORTEX down (expected).
- **E2E tests:** `mcp-shell/e2e/` contains concurrency stress, watchdog, soft kill, long command tests. Run with `npx tsx mcp-shell/e2e/test_*.ts` from project root.
- **Logs:** All executions logged to `logs/mcp/mcp-events.log` (JSON lines): `EXEC cmd=...`, `SUCCESS durationMs=...`, `FAIL classification=...`, `STATE_CHANGE CLOSED→OPEN`. Mirror to project root when running from subfolders (controlled by `MCP_LOG_MIRROR_ROOT=1` env var).

## VS Code Tooling (After Cleanup 03.12.2025)

**Status:** 51 расширений (было 71, удалено 20 за -28%)  
**Конфликты:** Все решены ✅ (AI дубликаты, MCP конфликт, Azure ecosystem)

**Критичные расширения (6):**
- `github.copilot` + `github.copilot-chat` — единственный AI ассистент с MCP интеграцией
- `ms-vscode.powershell` — PowerShell automation (проект core)
- `ms-python.python` — Python services (LightRAG, LLaMA Factory)
- `svelte.svelte-vscode` — Svelte UI framework
- `ms-mssql.mssql` — MCP MSSQL server integration

**Autoapprove whitelist (8 команд):**
```json
{
  "pwsh": true,
  "Get-NetTCPConnection": true,
  "nvidia-smi": true,
  "Test-NetConnection": true,
  "ollama": true,
  "git": true,
  "npm": true,
  "/.*/": true
}
```

**⚠️ Безопасность:** Удалены хардкод токены (Invoice API, Telegram bot) из старого autoapprove (67 записей из проектов REVIZOR/Telegram bot).

**Детали:** См. `docs/infra/TOOLS_CLEANUP_RESULTS.md` и `docs/infra/TOOLS_AUDIT_REPORT.md`

---

_Questions or missing details? Let me know which section feels light so I can expand it._
