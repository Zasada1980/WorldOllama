# CHANGELOG v0.3.0-alpha

**Release Date:** 2025-11-30  
**Status:** Alpha - Internal Use / Power Users  
**Codename:** Agent Automation

---

## 🚀 Major Features

### ⚡ Flows v1 - Agent Automation System

**NEW: Pre-built Multi-Step Workflows**

Execute complex automation tasks through a simple UI with full observability.

**Available Flows:**
- **quick_status** (1 step) - System health check
- **smoke_test** (2 steps) - STATUS + Git validation
- **git_check** (1 step) - Repository state verification
- **train_default** (2 steps) - STATUS + Model training
- **index_and_train** (3 steps) - Full cycle (INDEX → TRAIN)

**Features:**
- ✅ FlowsPanel UI with flow cards
- ✅ Real-time execution status
- ✅ Error handling (abort/continue policies)
- ✅ Step-by-step progress tracking

**Technical Details:**
- Flow definitions: `automation/flows/*.json`
- Backend: `flow_manager.rs` (ORDER 35)
- UI: `FlowsPanel.svelte` (TASK 22)

---

### 📊 Flows Observability (ORDER 38)

**NEW: Runtime Logging & Execution History**

Every flow execution is now logged and visible in UI.

**Runtime Logging:**
- **Format:** JSON Lines (`.jsonl`)
- **Location:** `logs/flows/flow_{id}_{timestamp}.jsonl`
- **Events:** Flow start/end, step start/success/error
- **Path-agnostic:** Works in dev and production

**Execution History:**
- **UI Component:** History table in FlowsPanel
- **Displays:** Last 10 executions
- **Info:** Flow name, status, duration, failed step
- **Auto-reload:** Updates after each flow completion

**Example Log:**
```jsonl
{"timestamp":1732923001,"flow_id":"quick_status","run_id":"1732923000","step_id":"step_1","cmd":"STATUS","status":"started","message":"Step step_1 (STATUS) started","error":null}
{"timestamp":1732923002,"flow_id":"quick_status","run_id":"1732923000","step_id":"step_1","cmd":"STATUS","status":"success","message":"System status: OK","error":null}
```

---

### 🔧 Backend Integration

#### INDEX Rust Wrapper (ORDER 37)

**NEW: Native Rust integration for knowledge base indexation**

- **Module:** `index_manager.rs`
- **Public API:** `run_indexing(config)` → `IndexResult`
- **Integration:** INDEX command in flows
- **Benefits:** No PowerShell dependency in flow execution

#### TRAIN Public API (ORDER 36)

**NEW: Unified training interface**

- **Module:** `training_manager.rs`
- **Public API:** `run_training(profile, dataset)` → `TrainingResult`
- **Integration:** TRAIN command in flows
- **Features:** Profile validation, dataset path resolution

#### Flow Backend Commands (ORDER 35)

**NEW: Real command execution in flow_manager**

- **STATUS:** System health check (Ollama + CORTEX)
- **GIT_PUSH:** Safe Git push with validation
- **TRAIN:** Model training via public API
- **INDEX:** Knowledge base indexation via Rust wrapper

---

## 🎨 UI/UX Improvements

### FlowsPanel (TASK 22)

- ✅ Flow cards with descriptions
- ✅ "Run Flow" button with states (idle/running/disabled)
- ✅ Loading/error/empty states
- ✅ Help banner with flow information
- ✅ Execution history table

### Welcome Tour Enhancements

- ✅ Flows introduction step
- ✅ Skip functionality
- ✅ localStorage persistence

---

## 🏗️ Architecture & Infrastructure

### Path-Agnostic Design

All flows and logging use 5-level fallback for `PROJECT_ROOT`:
1. `WORLD_OLLAMA_ROOT` env variable
2. 5-parent traversal from executable
3. Current directory fallback

**Impact:** Portable across dev/production environments

### Graceful Degradation

- Flow logging failures don't block execution
- Missing log directory auto-created
- Parse errors handled gracefully

---

## 📊 Observability Stack

### Flow Logging Architecture

```
User Action (Run Flow)
  ↓
FlowManager::execute_flow()
  ↓
FlowLogger::new(flow_id)  → creates log file
  ↓
For each step:
  log_step_start()
  execute_step()
  log_step_success() / log_step_error()
  ↓
log_flow_complete()
  ↓
Log file: logs/flows/flow_{id}_{timestamp}.jsonl
  ↓
FlowManager::get_flow_history() parses logs
  ↓
FlowsPanel displays history
```

**Key Components:**
- `FlowLogger` struct (170 lines, ORDER 38)
- `FlowRunSummary` API
- `get_flow_history` Tauri command
- History UI in FlowsPanel

---

## 📝 Documentation Updates

### New Documents

- `ORDER_35_IMPLEMENTATION_REPORT.md` - Flow backend integration
- `ORDER_36_COMPLETION_REPORT.md` - TRAIN API
- `TASK_37_COMPLETION_REPORT.md` - INDEX wrapper
- `ORDER_38_COMPLETION_WALKTHROUGH.md` - Observability
- `ORDERS_1_38_COMPREHENSIVE_AUDIT.md` - Full project audit
- `ORDER_39_IMPLEMENTATION_PLAN.md` - Release gate plan

### Updated Documents

- `README.md` - v0.3.0-alpha features, Flows section
- `task.md` - ORDER 22, 35-39 status

---

## ⚠️ Known Limitations

### v0.3.0-alpha Constraints

**Not Included:**
- ❌ Flow Editor (create/edit flows in UI)
- ❌ Flow Scheduler (cron-like automation)
- ❌ Flow Cancellation (stop running flows)
- ❌ UI Log Viewer (browse logs in-app)
- ❌ PULSE v2 (enhanced training monitoring)
- ❌ Safe Git v2 (diff preview, secret detection)

**Known Issues:**
- ⚠️ `train_default.json` requires dataset path configuration
- ⚠️ Compilation warnings (unused imports - cosmetic only)
- ⚠️ No log rotation (logs accumulate indefinitely)

### Recommended Workflows

**Stable:**
- ✅ quick_status - Always works
- ✅ smoke_test - Works if repo clean
- ✅ index_and_train - Works if dataset exists

**Experimental:**
- ⚠️ train_default - Requires profile/dataset setup
- ⚠️ git_check - Depends on repository state

---

## 🔄 Migration from v0.2.0

### Breaking Changes

**None** - v0.3.0-alpha is additive

### New Features Available

1. **Flows System:**
   - Navigate to "⚡ Flows" in UI
   - Run pre-built workflows
   - View execution history

2. **Flow Logs:**
   - Check `logs/flows/` directory
   - Parse `.jsonl` files for debugging

3. **Backend APIs:**
   - `index_manager::run_indexing()`
   - `training_manager::run_training()`
   - Available for custom integrations

---

## 🧪 Testing & Verification

### E2E Testing

**Flows Tested:**
- quick_status ✅
- smoke_test ✅ (conditional on repo state)
- git_check ✅
- train_default ⚠️ (dataset dependency)
- index_and_train ✅ (conditional on data)

**Test Reports:**
- `TASK_22_E2E_REPORT.md`
- `TASK_39_RELEASE_GATE_REPORT.md`

### Build Verification

- ✅ Rust backend compiles (with warnings)
- ✅ Frontend builds successfully
- ✅ Dev mode stable (40+ min uptime verified)

---

## 📦 Deliverables

### Code

| Component | Files Modified | Lines Added |
|-----------|----------------|-------------|
| Flow Manager | flow_manager.rs | +400 |
| INDEX Manager | index_manager.rs | +110 (new) |
| Training Manager | training_manager.rs | +50 |
| Commands | commands.rs | +50 |
| FlowsPanel UI | FlowsPanel.svelte | +150 |

### Flows

| Flow File | Steps | Commands | Status |
|-----------|-------|----------|--------|
| quick_status.json | 1 | STATUS | ✅ Stable |
| smoke_test.json | 2 | STATUS, GIT_PUSH | ✅ Stable |
| git_check.json | 1 | GIT_PUSH | ✅ Stable |
| train_default.json | 2 | STATUS, TRAIN | ⚠️ Config needed |
| index_and_train.json | 3 | STATUS, INDEX, TRAIN | ✅ Stable |

---

## 🎯 Roadmap

### v0.3.1 (Next)

**Planned:**
- Flow Editor UI
- Flow Scheduler
- UI Log Viewer
- Log rotation/cleanup
- Compilation warnings cleanup

### v0.4.0 (Future)

**Planned:**
- PULSE v2 (real-time INDEX+TRAIN monitoring)
- Safe Git v2 (diff preview, secret detection)
- Performance optimization
- Monitoring dashboard (Prometheus/Grafana)

---

## 👥 Contributors

**This Release:**
- CODEX Agent - ORDER 22, 35-39 execution
- User collaboration - Requirements, testing, verification

---

## 📜 License

MIT License - see `LICENSE` file

---

**For detailed technical information, see:**
- `ORDERS_1_38_COMPREHENSIVE_AUDIT.md` - Complete audit
- `ORDER_38_COMPLETION_WALKTHROUGH.md` - Observability details
- `README.md` - User guide

**Status:** Alpha Release - Recommended for internal use and power users only.

---

_This is an alpha release. Features may change in future versions. Feedback welcome!_
