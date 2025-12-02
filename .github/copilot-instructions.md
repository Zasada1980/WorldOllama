# AI Agent Codebase Guide — WORLD_OLLAMA

**Purpose:** Guide AI coding agents to be immediately productive in this multi-service AI knowledge system.  
**Updated:** 2025-12-02  
**Version:** 2.1  
**Last Verified:** ORDER 42 complete, v0.3.0-alpha released

---

## 🎯 Project At A Glance

**WORLD_OLLAMA** is a local-first AI knowledge system combining:
- **Desktop Client** (Tauri/Svelte) - User interface with 6 panels + Flows automation
- **CORTEX** (LightRAG) - GraphRAG knowledge server (port 8004)
- **Ollama** (qwen2.5:14b) - LLM inference (port 11434)
- **LLaMA Factory** - Model fine-tuning platform
- **Knowledge Base** - 486+ TRIZ documents (7.7 MB)

**Root:** `E:\WORLD_OLLAMA\` (NEVER hardcode - use `WORLD_OLLAMA_ROOT` env var or `get_project_root()`)  
**GPU:** RTX 5060 Ti 16GB VRAM  
**OS:** Windows 11 (PowerShell primary shell)

---

## ⚠️ CRITICAL: Development Protocols

### 1. NO SIMULATION — Verify Everything
**PROHIBITED:** Fake terminal output, invented logs, claiming status without proof.

**REQUIRED:** Execute commands and show real output:
```powershell
# Want to say "File exists"? → Show proof
Test-Path E:\WORLD_OLLAMA\services\lightrag\data\*.json

# Want to say "Server running"? → Verify health
Invoke-RestMethod http://localhost:8004/health

# Want to say "Models loaded"? → Check VRAM
nvidia-smi --query-gpu=memory.used --format=csv,noheader
```

### 1.a Agent Interaction Directive — No Manual Prompts

Агент не должен просить пользователя выполнять команды вручную, кроме случаев, когда действие по своей природе визуальное или требует интерактивного подтверждения.

- По умолчанию используйте инструменты: MCP (`myshell/execute_command`) и VS Code Terminal (`run_in_terminal`) для выполнения команд.
- Исключения: визуальные демонстрации (прогресс-бары, запуск окон Desktop Client), ручные клики в UI.
- Если пользователь уже выполнил ручное действие (например, запустил сервисы), агент обязан перейти к автоматической проверке состояния и не дублировать ручные указания.

### 2. CODE OVER DOCS — Direct Action
When asked to change settings (ports, models, paths):
- ❌ DON'T write plans in markdown
- ✅ DO modify source code (`.py`, `.rs`, `.yaml`, `.ps1`)
- ✅ DO show `Get-Content` verification after changes

### 3. Path Agnosticism — Dynamic Root Resolution
**NEVER hardcode** `E:\WORLD_OLLAMA\` in code:

```rust
// ✅ CORRECT - Dynamic resolution
let root = std::env::var("WORLD_OLLAMA_ROOT")
    .or_else(|_| std::env::current_exe()
        .map(|p| p.parent().unwrap().parent().unwrap().to_string_lossy().to_string()))
    .unwrap();

// ❌ WRONG - Hardcoded path
let root = "E:\\WORLD_OLLAMA\\";
```

See `TASK 16.1` in consolidated reports for context.

---

### 📋 АВТОМАТИЧЕСКАЯ НАВИГАЦИЯ ПО ДОКУМЕНТАЦИИ

**ПРАВИЛО:** Перед ответом на вопрос пользователя агент **ОБЯЗАН**:

1. **Определить категорию запроса:**
   - 🔵 Desktop Client / TASK → `docs/tasks/TASKS_CONSOLIDATED_REPORT.md`
   - 🤖 Модели / Обучение → `docs/models/MODELS_CONSOLIDATED_REPORT.md`
   - 🏗️ Инфраструктура / CORTEX → `docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md`
   - 📊 Архитектура / Проект → `PROJECT_MAP.md`, `DOCUMENTATION_STRUCTURE_ANALYSIS.md`
   - 📦 Релиз / Статус → `docs/release/v0.1.0/`, `PROJECT_STATUS.md`

2. **Загрузить соответствующий консолидированный отчёт:**
   ```python
   # Псевдокод
   if query.contains("TASK", "Desktop Client", "UI"):
       read_file("docs/tasks/TASKS_CONSOLIDATED_REPORT.md")
   elif query.contains("model", "training", "TD-010"):
       read_file("docs/models/MODELS_CONSOLIDATED_REPORT.md")
   elif query.contains("CORTEX", "RAG", "Security", "Ollama"):
       read_file("docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md")
   ```

3. **Использовать граф зависимостей для поиска связанных файлов:**
   - Если документ упоминает другой → загрузить связанный
   - Если нужен детальный контекст → найти оригинальный TASK отчёт в архиве

**ПРИМЕР WORKFLOW:**

**Запрос пользователя:** "Как работает Command DSL?"

**Автоматические действия агента:**
1. ✅ Читаю `DOCUMENTATION_STRUCTURE_ANALYSIS.md` → определяю кластер: **Desktop Client Tasks**
2. ✅ Вижу что TASK 8 (Commands Panel) в консолидированном отчёте
3. ✅ Читаю `docs/tasks/TASKS_CONSOLIDATED_REPORT.md` → нахожу раздел TASK 8
4. ✅ Извлекаю информацию о Command DSL
5. ✅ Отвечаю с указанием источника: `docs/tasks/TASKS_CONSOLIDATED_REPORT.md`, раздел TASK 8

**БЕЗ этой процедуры** → агент может не найти нужную информацию или использовать устаревшие данные

---

### 🗺️ КАРТА НАВИГАЦИИ ПО ДОКУМЕНТАЦИИ (ОБЯЗАТЕЛЬНАЯ СПРАВКА)

**Для агента:** Этот справочник **ВСЕГДА** доступен в памяти

| Тема запроса | Первичный источник | Детальный архив |
|--------------|-------------------|-----------------|
| **TASK 4-15 (Desktop Client)** | `docs/tasks/TASKS_CONSOLIDATED_REPORT.md` | `client/TASK_*_REPORT.md` |
| **System Status Panel** | `docs/tasks/TASKS_CONSOLIDATED_REPORT.md` (TASK 4) | `client/TASK4_REPORT.md` |
| **Settings + Profiles** | `docs/tasks/TASKS_CONSOLIDATED_REPORT.md` (TASK 5) | `client/TASK5_REPORT.md` |
| **Library Panel** | `docs/tasks/TASKS_CONSOLIDATED_REPORT.md` (TASK 6-7) | `client/TASK_6_COMPLETION_REPORT.md` |
| **Commands Panel (DSL)** | `docs/tasks/TASKS_CONSOLIDATED_REPORT.md` (TASK 8) | `client/TASK_8_COMPLETION_REPORT.md` |
| **Training UI** | `docs/tasks/TASKS_CONSOLIDATED_REPORT.md` (TASK 12.2) | `client/TASK_12_2_COMPLETION_REPORT.md` |
| **Модели (TD-010v2/v3)** | `docs/models/MODELS_CONSOLIDATED_REPORT.md` | `docs/TD010v2_DEPLOYMENT_COMPLETE.md` |
| **VRAM Calculator** | `docs/models/MODELS_CONSOLIDATED_REPORT.md` | `docs/qwen3b_training_requirements.md` |
| **CORTEX Configuration** | `docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md` | `docs/CORTEX_CONFIGURATION_REFERENCE.md` |
| **Security (API Keys)** | `docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md` | `docs/SECURE_ENCLAVE_REPORT.md` |
| **RAG Quality** | `docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md` | `docs/reports/RAG_QUALITY_REPORT.md` |
| **Orchestration Scripts** | `docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md` | `scripts/START_ALL.ps1`, `STOP_ALL.ps1` |
| **Архитектура проекта** | `PROJECT_MAP.md` | `DOCUMENTATION_STRUCTURE_ANALYSIS.md` |
| **Векторные зависимости** | `docs/project/DOCUMENTATION_STRUCTURE_ANALYSIS.md` | — |
| **Индекс документации** | `docs/project/INDEX_NEW.md` | — |

---

### 🎯 КОНТЕКСТНЫЕ ПРАВИЛА

**1. При упоминании TASK номера:**
```python
# ВСЕГДА загружать консолидированный отчёт ПЕРВЫМ
read_file("docs/tasks/TASKS_CONSOLIDATED_REPORT.md")

# Если нужна детализация → найти оригинальный отчёт
if need_details:
    read_file(f"client/TASK_{task_number}_COMPLETION_REPORT.md")
```

**2. При работе с моделями:**
```python
# ВСЕГДА проверить статус в консолидированном отчёте
read_file("docs/models/MODELS_CONSOLIDATED_REPORT.md")

# Если вопрос про конкретную модель → загрузить детали
if model_name == "TD-010v2":
    read_file("docs/TD010v2_DEPLOYMENT_COMPLETE.md")
```

**3. При вопросах об инфраструктуре:**
```python
# ВСЕГДА начинать с консолидированного отчёта
read_file("docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md")

# Если нужен код → использовать код из консолидированного отчёта
# Он содержит готовые code snippets
```

---

### 📊 ВЕКТОРНЫЙ ГРАФ (ALWAYS IN MEMORY)

**6 тематических кластеров:**

1. **Архитектура проекта (4 файла):**
   - `PROJECT_MAP.md` → `README.md` → `MANUAL.md` → `CHANGELOG.md`

2. **Статус и прогресс (4 файла):**
   - `PROJECT_STATUS.md` → `docs/project/DOCUMENTATION_STRUCTURE_ANALYSIS.md` → `docs/project/INDEX_NEW.md` → `docs/project/DOCUMENTATION_REORGANIZATION_COMPLETE.md`

3. **Desktop Client Tasks (11 TASK):**
   - `docs/tasks/TASKS_CONSOLIDATED_REPORT.md` → все TASK 4-15

4. **Модели и обучение (7 отчётов):**
   - `docs/models/MODELS_CONSOLIDATED_REPORT.md` → TD-010v2/v3 отчёты

5. **Инфраструктура (4 отчёта + 2 лога):**
   - `docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md` → CORTEX/Security/RAG/Orchestration

6. **UX спецификации (8 файлов):**
   - `UX_SPEC/*.md` → UI/UX документация

**ПРАВИЛО:** При работе с документом → проверить его кластер → загрузить связанные файлы

---

## 🏗️ Architecture — Data Flow Patterns

### Service Communication (Critical Integration Points)

```
Desktop Client (Tauri)
  ↓ invoke("start_training_job")
Rust Backend (commands.rs)
  ↓ Command::new("pwsh")
PowerShell Script (start_agent_training.ps1)
  ↓ llamafactory-cli train
LLaMA Factory Process
  ↓ writes training_status.json (PULSE v1)
Rust Singleton Poller (training_manager.rs)
  ↓ app.emit("training_status_update")
Svelte UI (TrainingPanel.svelte)
```

**Key Insight:** UI doesn't call Python directly. All training goes through Rust → PowerShell → llamafactory-cli.

### CORTEX (LightRAG) Request Flow

```
UI API call (client.ts)
  ↓ fetch("http://localhost:8004/query")
FastAPI Server (lightrag_server.py)
  ↓ rag.query(mode="hybrid")
LightRAG Library
  ↓ ollama_model_complete(qwen2.5:14b)
Ollama (port 11434)
  ↓ returns context + entities
FastAPI Response
  ↓ JSON with answer + sources
UI renders with chain-of-thought
```

**Key Insight:** `mode="hybrid"` is recommended (adaptive local/global search). `enable_rerank=False` due to LightRAG bug.

---

## 🚀 Critical Developer Workflows

### Starting Services (REQUIRED for development)

```powershell
# ONE-COMMAND START (recommended)
pwsh E:\WORLD_OLLAMA\scripts\START_ALL.ps1

# Verify all services running
pwsh E:\WORLD_OLLAMA\scripts\CHECK_STATUS.ps1 -Detailed

# Expected output:
# ✓ Ollama (11434): Running
# ✓ CORTEX (8004): Running  
# ○ Neuro-Terminal (8501): Down (optional)
```

**CRITICAL:** Desktop Client expects CORTEX running. If `CHECK_STATUS` shows CORTEX down, troubleshoot before running client.

### Desktop Client Development

```powershell
# Terminal 1: Keep services running (see above)

# Terminal 2: Run Tauri dev mode
cd E:\WORLD_OLLAMA\client
npm run tauri dev  # Opens window automatically

# Hot reload: Edit .svelte files → auto-refresh
# Rust changes: Requires manual restart (Ctrl+C → re-run)
```

### Training a Model (E2E Workflow)

```powershell
# 1. Verify services
pwsh scripts\CHECK_STATUS.ps1

# 2. Option A: Via UI
#    - Open Desktop Client → Training Panel
#    - Select profile (e.g., "triz_engineer")
#    - Set epochs (1-5)
#    - Click "Start Training"

# 3. Option B: Via Script (for testing)
pwsh scripts\start_agent_training.ps1 `
  -ProfileName "triz_engineer" `
  -DataPath "E:\WORLD_OLLAMA\services\llama_factory\data\triz_synthesis_v1.jsonl" `
  -OutputDir "E:\WORLD_OLLAMA\models\test_output" `
  -Epochs 1

# 4. Monitor PULSE status
Get-Content E:\WORLD_OLLAMA\services\llama_factory\training_status.json

# 5. Check logs
Get-Content E:\WORLD_OLLAMA\logs\training\train-*.log -Tail 20
```

**Known Issue (ORDER 43):** Training fails if HuggingFace model is gated. Either:
- Login: `huggingface-cli login` (requires HF token)
- OR switch to open model in `llama3_lora_sft.yaml`

### VRAM Monitoring (GPU Health Check)

```powershell
# Check VRAM usage (models loaded when >6GB)
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader

# Expected when CORTEX indexing:
# 8500, 16384  (8.5GB used, healthy)

# If <6000 MB → Models NOT loaded, indexing broken
```

**RULE:** VRAM <6GB = indexing not working. Don't report success until VRAM >6GB.

---

## 📚 Documentation Navigation Protocol

### Quick Reference Map

| Topic | Primary Source | Detailed Archive |
|-------|---------------|------------------|
| **Desktop Client (TASK 4-16)** | `docs/tasks/TASKS_CONSOLIDATED_REPORT.md` | `client/docs/TASK_*_REPORT.md` |
| **Models (TD-010v2/v3)** | `docs/models/MODELS_CONSOLIDATED_REPORT.md` | `docs/TD010v2_DEPLOYMENT_COMPLETE.md` |
| **Infrastructure (CORTEX)** | `docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md` | `docs/CORTEX_CONFIGURATION_REFERENCE.md` |
| **Architecture** | `PROJECT_MAP.md`, `README.md` | `DOCUMENTATION_INDEX.md` |
| **Current Status** | `PROJECT_STATUS_SNAPSHOT_v4.0.md` | `CHANGELOG_v0.3.0.md` |

### Context Gathering Strategy

When working on a task:

1. **Identify cluster** (Desktop/Models/Infrastructure/Architecture)
2. **Read consolidated report** for overview
3. **Check detailed reports** only if needed
4. **Verify with code** (don't trust docs alone)

**Example:** "How does Command DSL work?"
```
1. Category: Desktop Client
2. Read: docs/tasks/TASKS_CONSOLIDATED_REPORT.md → TASK 8
3. If need code: grep "parseCommand" client/src/lib/
4. Verify: Check client/src/lib/components/CommandsPanel.svelte
```

---

## 🔍 Key Files Reference

| File Pattern | Purpose | Example |
|--------------|---------|---------|
| `scripts/*.ps1` | Service orchestration | `START_ALL.ps1`, `CHECK_STATUS.ps1` |
| `client/src-tauri/src/commands.rs` | All Tauri commands (1063 lines) | `start_training_job`, `execute_agent_command` |
| `client/src-tauri/src/flow_manager.rs` | Flows automation backend | `FlowExecutor`, `FlowLogger` |
| `client/src-tauri/src/training_manager.rs` | PULSE v1 implementation | `TrainingStatus`, polling logic |
| `client/src/lib/api/client.ts` | Frontend API client | All `invoke()` wrappers |
| `client/src/lib/components/FlowsPanel.svelte` | Flows UI | Flow cards, execution history |
| `automation/flows/*.json` | Flow definitions | `quick_status.json`, `index_and_train.json` |
| `services/lightrag/lightrag_server.py` | CORTEX FastAPI server (756 lines) | `/query`, `/insert`, `/health` |
| `services/llama_factory/config/*.yaml` | Training configurations | `llama3_lora_sft.yaml` |
| `docs/tasks/TASKS_CONSOLIDATED_REPORT.md` | TASK 4-16 complete reference | UI implementation details |
| `docs/models/MODELS_CONSOLIDATED_REPORT.md` | Model training reports | TD-010v2 eval_loss: 0.8591 |
| `docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md` | CORTEX, Security, RAG | Configuration reference |

---

## 🛠️ Build & Release

### Development Build

```powershell
cd E:\WORLD_OLLAMA\client

# Frontend only (no Rust rebuild)
npm run dev

# Full Tauri dev (hot reload)
npm run tauri dev
```

### Production Build

```powershell
# Automated build script (recommended)
pwsh E:\WORLD_OLLAMA\scripts\BUILD_RELEASE.ps1

# Manual (if script fails)
cd E:\WORLD_OLLAMA\client
npm run tauri build

# Output: client/src-tauri/target/release/tauri_fresh.exe
```

**Requirements:**
- Windows SDK 10.0+
- MSVC Build Tools 2022
- Rust 1.75+

### Testing

```powershell
# Core Bridge integration tests
pwsh E:\WORLD_OLLAMA\client\run_auto_tests.ps1

# System Status (3 scenarios)
pwsh E:\WORLD_OLLAMA\client\test_task4_scenarios.ps1

# Settings (5 scenarios)
pwsh E:\WORLD_OLLAMA\client\test_task5_settings.ps1

# E2E smoke test
pwsh E:\WORLD_OLLAMA\USER\TEST_E2E.ps1
```

---

## 💡 Critical Learnings (Hard-Won Knowledge)

### 1. Micro-Chunking for Large Files
**Problem:** Ollama limit 4096 tokens (~15K chars), but files were 3.3MB  
**Solution:** 10KB chunks (~3-4K tokens, 25% safety margin)  
**Result:** 3.3MB file = 330 chunks, ~15 min indexing, 100% reliable

See: `services/lightrag/lightrag_server.py` chunking logic

### 2. GPU Memory Discovery (MSI Afterburner)
**Problem:** RTX 5060 Ti showed 13GB VRAM instead of 16GB  
**Root Cause:** Memory Clock not overclocked  
**Solution:** +2000 MHz Memory Clock → full 16GB available  

Files: `docs/gpu-optimization-todo.md`, `docs/rtx-5060ti-16gb-safe-tuning-roadmap.md`

### 3. Docker Ollama Breaks GPU (Windows)
**Symptoms:** Logs show `/usr/bin/ollama runner`, low GPU utilization (<10%)  
**Cause:** Docker Ollama (Linux) can't access Windows GPU properly  
**Solution:** Stop Docker Ollama, use only local Windows Ollama

```powershell
docker stop ollama; docker rm ollama
curl http://localhost:11434/api/tags  # Verify local works
```

### 4. LightRAG State Persistence
**WRONG:** Assuming restart = data loss, reindexing from scratch  
**CORRECT:** `data/kv_store_doc_status.json` survives restarts

```powershell
# Check progress before reindexing
$docs = Get-Content services\lightrag\data\kv_store_doc_status.json | ConvertFrom-Json
$docs.PSObject.Properties.Name.Count  # Shows indexed documents
```

---

## 🚦 Quick Commands Reference

```powershell
# === SERVICE MANAGEMENT ===
pwsh scripts\START_ALL.ps1              # Start Ollama + CORTEX (+ optional Neuro-Terminal)
pwsh scripts\STOP_ALL.ps1               # Stop all services
pwsh scripts\CHECK_STATUS.ps1           # Health check (single)
pwsh scripts\CHECK_STATUS.ps1 -Detailed # With response times

# === MONITORING ===
nvidia-smi --query-gpu=memory.used,utilization.gpu --format=csv  # GPU stats
netstat -ano | Select-String ":8004"    # Check CORTEX port
Get-Content services\lightrag\logs\cortex.log -Tail 20  # CORTEX logs

# === DEVELOPMENT ===
cd client; npm run tauri dev            # Start Desktop Client dev mode
pwsh client\run_auto_tests.ps1          # Run tests

# === TRAINING ===
pwsh scripts\start_training_ui.ps1      # Launch LLaMA Board (web UI)
Get-Content services\llama_factory\training_status.json  # PULSE v1 status

# === TROUBLESHOOTING ===
Get-Process python | Where-Object {$_.CommandLine -like "*lightrag*"} | Stop-Process
ollama list | Select-String "qwen|nomic"  # Check models
```

---

## 🔄 Hybrid Execution Strategy (MCP + Terminal)

**Principle:** Use the right tool for the right job

### Use `myshell/execute_command` (MCP) for:

✅ **Automated Testing & Validation** (TASK 51 pattern)
```powershell
# Structured output needed for analysis
myshell/execute_command: "cargo check"
myshell/execute_command: "npm run check"
myshell/execute_command: "Get-Command script.ps1"
```

✅ **Health Checks** (agent needs exitCode for logic)
```powershell
myshell/execute_command: "Test-NetConnection localhost -Port 8004"
myshell/execute_command: "ollama list | Select-String qwen"
```

✅ **Quick Information Retrieval** (<2 min, for agent parsing)
```powershell
myshell/execute_command: "git status --porcelain"
myshell/execute_command: "Get-Content config.json | ConvertFrom-Json"
```

**Why MCP:** Structured JSON output (`exitCode`, `stdout`, `stderr`), isolated process, agent can parse results.

---

### Use `run_in_terminal` (VS Code) for:

✅ **Presentation & Demonstration** (user observes)
```powershell
run_in_terminal: "pwsh scripts/START_ALL.ps1"
run_in_terminal: "nvidia-smi"
run_in_terminal: "cargo build --release"  # Show progress bars
```

✅ **Background Processes** (services, dev servers)
```powershell
run_in_terminal(isBackground=true): "npm run tauri dev"
run_in_terminal(isBackground=true): "pwsh scripts/start_lightrag.ps1"
```

✅ **Long Operations** (>2 min, avoid MCP timeout)
```powershell
run_in_terminal: "npm install"
run_in_terminal: "docker build ."
run_in_terminal: "pwsh scripts/train_model.ps1"
```

✅ **Interactive/Debugging** (requires user input)
```powershell
run_in_terminal: "python -m pdb script.py"
```

**Why Terminal:** Visual output, colors, progress bars, no timeout risk, user control.

---

### Decision Tree:

```
Command execution needed?
├─ Result needed for agent logic? → Time < 2 min?
│  ├─ YES → ✅ MCP (structured output)
│  └─ NO → ⚠️ Terminal (avoid timeout)
└─ User observes execution? OR Background process?
   └─ YES → ✅ Terminal (presentation/services)
```

**Reference:** `docs/tasks/HYBRID_EXECUTION_STRATEGY_ANALYSIS.md`

---

## 🔧 MCP Auto-Activation (Phase 1 v0.4.0)

**CRITICAL:** MCP Server settings apply **AUTOMATICALLY** — no manual activation needed.

### What Works Automatically (02.12.2025)

✅ **Terminal Settings** (from `.vscode/settings.json`):
- Persistent Sessions enabled
- Shell Integration enabled  
- Environment variable `VSCODE_AGENT_ENABLED=1` set in new terminals

✅ **MCP Server** (`myshell/execute_command`):
- Registered via `github.copilot.chat.mcp.servers` in settings
- Starts automatically on first Copilot request
- **NO NEED to check availability** — tool is always ready

✅ **Base64 Encoding** (v1.2.0):
- Auto-detects problematic characters: `|`, `{}`, `$`, `"`, `'`, `` ` ``
- Applies encoding automatically (100% accuracy, 17/17 tests passed)
- **NO NEED to specify `useEncodedCommand`** — regex handles it

### What Agent MUST NOT Do

❌ **DON'T** ask "Should I activate MCP server?"  
❌ **DON'T** check if `execute_command` tool exists before using it  
❌ **DON'T** ask "Should I use Base64 Encoding for this command?"  
❌ **DON'T** manually specify `useEncodedCommand` parameter

### What Agent SHOULD Do

✅ **DO** call `myshell/execute_command` directly for any PowerShell command  
✅ **DO** trust auto-detection for complex commands (pipes, braces, variables)  
✅ **DO** use MCP for structured output (Exit Code, stdout, stderr parsing)  
✅ **DO** use Terminal for visual demos or background processes

### Example (Correct Usage)

```typescript
// ✅ CORRECT - Direct call, auto-detection handles encoding
myshell/execute_command: "Get-Process | Where-Object { $_.CPU -gt 1 } | Select-Object -First 5"

// Result: Exit Code 0 (Base64 applied automatically)
```

```typescript
// ❌ WRONG - Unnecessary manual check
Agent: "Should I use Base64 Encoding for this command?"
User: (confused — it's automatic)
```

### Restart Required (One Time Only)

After updating `.vscode/settings.json` or `mcp-shell/server.ts`:
1. `Ctrl+Shift+P` → `Developer: Reload Window`
2. Wait 2-3 seconds
3. ✅ All settings active automatically

**Reference:** `docs/infra/MCP_AUTO_ACTIVATION_VERIFICATION.md`

---

## ⚡ Task Tracking & Versioning

**Current Status:** v0.3.0-alpha (ORDER 42 complete, ORDER 43 pending)

| Version | Status | Key Features |
|---------|--------|--------------|
| **v0.1.0** | ✅ Released 27.11.2025 | Desktop Client MVP (TASK 4-15) |
| **v0.2.0** | ✅ Released 29.11.2025 | PULSE v1, Safe Git Assistant |
| **v0.3.0-alpha** | ✅ Released 30.11.2025 | Flows Automation (ORDER 35-38, 42) |
| **v0.3.1** | 📋 Planned | ORDER 37 fix (INDEX paths), ORDER 43 (HF auth) |

**Active Blockers:**
- 🔴 ORDER 37: INDEX path resolution (production blocker)
- 🟡 ORDER 43: HuggingFace authentication (optional for training)

See `PROJECT_STATUS_SNAPSHOT_v4.0.md` for detailed status.

---

## 📖 Further Reading

- **Full Architecture:** `PROJECT_MAP.md`
- **User Manual:** `MANUAL.md`
- **All Tasks:** `docs/tasks/TASKS_CONSOLIDATED_REPORT.md`
- **All Changes:** `CHANGELOG.md`, `CHANGELOG_v0.3.0.md`
- **Complete Index:** `DOCUMENTATION_INDEX.md` (68 markdown files)

---

_This guide prioritizes actionable technical knowledge over aspirational practices. Focus on discoverable patterns, not documentation-only claims._
