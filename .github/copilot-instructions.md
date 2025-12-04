````instructions
# AI Agent Instructions — WORLD_OLLAMA (Core)

**Project Type:** Local-first AI stack — Tauri/Svelte + LightRAG + Ollama + LLaMA Factory
**Platform:** Windows 11, RTX GPU, PowerShell-first
**Version:** v0.4.0 (Production Ready)
**GitHub:** https://github.com/Zasada1980/WorldOllama

---

## 🔒 ABSOLUTE RULE: SETTINGS FILES ARE READ-ONLY

**FORBIDDEN (Agent CANNOT modify these files):**
- ❌ `.github/copilot-instructions.md` (this file)
- ❌ `.github/instructions/client.instructions.md`
- ❌ `.github/instructions/rust.instructions.md`
- ❌ `.github/instructions/scripts.instructions.md`
- ❌ `.github/instructions/services.instructions.md`
- ❌ `.github/AGENTS.md`

**If settings need changes:**
1. Agent MUST stop and report to user
2. Explain WHY change is needed
3. Provide exact text for user to add manually
4. DO NOT use `replace_string_in_file` or `create_file` on settings files

**Exception:** NONE. Even with user permission, agent must provide instructions, not execute.

---

## 📚 PATH-SPECIFIC INSTRUCTIONS

**For detailed, context-aware rules, see:**
- **Client (Svelte/Tauri):** `.github/instructions/client.instructions.md`
- **Backend (Rust):** `.github/instructions/rust.instructions.md`
- **Scripts (PowerShell):** `.github/instructions/scripts.instructions.md`
- **Services (Python):** `.github/instructions/services.instructions.md`
- **Agent Behavior:** `.github/AGENTS.md`

**This file contains only CORE universal directives.**

---

## 🚨 MANDATORY PRE-TASK PROTOCOL (NO EXCEPTIONS)

**EVERY agent MUST execute BEFORE starting ANY task:**

### STEP 1: Read Project Status (MANDATORY — NO EXCEPTIONS)
```typescript
await read_file({ filePath: "e:\\WORLD_OLLAMA\\PROJECT_STATUS_SNAPSHOT_v4.0.md" });
```
**Extract:**
- Current phase (v0.4.0 - PRODUCTION READY)
- Known blockers
- Critical files list

**⛔ SKIPPING THIS STEP IS PROHIBITED** — Agent must have current context before any action.

### STEP 2: Verify Context (REQUIRED)
Confirm in response:
- Current version: v0.4.0
- Desktop Client status
- Project root verified

### STEP 3: Use Quick Index (CRITICAL)
```typescript
await read_file({ filePath: "e:\\WORLD_OLLAMA\\docs\\journals\\QUICK_INDEX.md" });
```
**Search time:** <30 seconds (vs 2-10 minutes manual search)

**⛔ FORBIDDEN:**
- ❌ Manual file_search without consulting Quick Index first
- ❌ grep_search without Quick Index check
- ❌ Asking user "where is X file?" without checking index

**Auto-Update Rule:**
After creating .md file in `docs/journals/`, update Quick Index:
```typescript
await run_in_terminal({
  command: "pwsh scripts/INDEX_ALL_MD_FILES.ps1 -UpdateQuickIndex",
  explanation: "Update Quick Index with new journal file"
});
```

### STEP 4: Check Relevant Docs (CONDITIONAL)
IF task involves:
- UI/Desktop Client → Read `docs/tasks/TASKS_CONSOLIDATED_REPORT.md`
- Training/Models → Read `docs/models/MODELS_CONSOLIDATED_REPORT.md`
- Infrastructure/Services → Read `docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md`

### STEP 5: Apply Directives (REQUIRED)
Acknowledge which directives apply:
- UI-First Workflow
- Runtime Stability
- Exit Code Check
- Service Dependencies

**⚠️ ENFORCEMENT:** Agent MUST include Compliance Verification block in response (see section below). Skipping = violation.

**Path Resolution Reference:**
- Rust: `crate::utils::get_project_root()` → PathBuf
- Python: `WORLD_OLLAMA_ROOT` env var or `Path(__file__).parent.parent.parent`
- PowerShell: `$ProjectRoot = $PSScriptRoot` (parameter with default)

---

## ❌ ABSOLUTE RULE #0: DESKTOP CLIENT FIRST

**ALL user-facing operations THROUGH Desktop Client UI.**

**FORBIDDEN:**
- ❌ DO NOT give terminal commands to user (pwsh, ollama, git)
- ❌ DO NOT instruct "выполните команду X"
- ❌ DO NOT show PowerShell/Bash examples for user execution
- ❌ DO NOT use run_in_terminal for user-facing operations
- ❌ DO NOT provide "Alternative (manual)" sections with terminal commands

**HARD BLOCKS (Prohibited Patterns):**

```markdown
❌ WRONG:
"Run this command to start services:
pwsh scripts/START_ALL.ps1"

❌ WRONG:
"Alternative (manual):
cd client
npm run tauri dev"

❌ WRONG:
"Execute the following:
ollama pull mistral-small"
```

**REQUIRED:**
- ✅ Direct user to Desktop Client UI (http://localhost:1420)
- ✅ Specify correct panel (SystemStatusPanel, CommandsPanel, TrainingPanel, GitPanel)
- ✅ Use terminal ONLY for internal agent verification
- ✅ Check Desktop Client availability BEFORE instructing user

**EXCEPTION (Bootstrap Only):**
When Desktop Client is NOT running, you MAY give ONE command to start it:
```markdown
✅ ALLOWED (Bootstrap):
"Desktop Client не запущен. Для запуска выполните:
cd client
npm run tauri dev

После запуска используйте UI для всех операций."
```

**Agent Internal Checks (Communication Pattern):**

When agent runs commands for INTERNAL verification:

```markdown
✅ CORRECT (Show Results):
"Проверяю статус Ollama..."
[agent runs command internally]
"✅ Ollama работает на порту 11434"

❌ WRONG (Show Commands):
"Проверю статус Ollama:
pwsh scripts/CHECK_STATUS.ps1"
```

**Rule:** Never show raw terminal commands in responses. Show RESULTS of checks, not commands.

**Examples:**

```markdown
✅ CORRECT (User Instruction):
"📋 To start services:
1. Open Desktop Client: http://localhost:1420
2. Navigate to CommandsPanel
3. Select 'START_ALL.ps1'
4. Click Execute
5. Monitor progress in SystemStatusPanel

(Agent verified internally: all services running)"

❌ WRONG (Terminal Command to User):
"Run: pwsh scripts/START_ALL.ps1"

✅ CORRECT (Model Selection):
"📋 To pull model:
1. Open Desktop Client
2. Go to LibraryPanel → Models tab
3. Search 'mistral-small'
4. Click Install"

❌ WRONG:
"Execute: ollama pull mistral-small"
```

---

## 🪟 WINDOWS 11 PRODUCTION READY (v0.4.0)

**ALL 5 CRASH SCENARIOS FIXED:**
- **Blank screen (40%)** → IPv4 binding (`vite.config.js` host: "127.0.0.1")
- **Ctrl+C crash (100%)** → Tauri CLI v2.9.4+ upgrade
- **Zombie processes (100%)** → Job Objects + PowerShell cleanup
- **Error 1411 (100%)** → Linked Token UDF resolver
- **UDF access denied (60%)** → %LOCALAPPDATA% path fix

**Pre-Launch Checklist (MANDATORY on Windows 11):**
```powershell
pwsh scripts/cleanup_webview.ps1 -Aggressive
cd client; pwsh test_phase3_e2e_validation.ps1  # Expect 18/18 PASS
npm run tauri dev
```

**Key Files:**
- `client/src-tauri/src/linked_token.rs` (234 lines)
- `client/src-tauri/src/windows_job.rs` (135 lines)
- `scripts/cleanup_webview.ps1` (105 lines)
- `client/test_phase3_e2e_validation.ps1` (344 lines)

---

## 🚨 ABSOLUTE RULE: RUNTIME STABILITY

**AFTER background process start, agent MUST:**

1. ✅ **WAIT:** Minimum 10 seconds (stabilization)
2. ✅ **CHECK PROCESS:** `Get-Process -Name process_name` (running?)
3. ✅ **CHECK PORT:** `Test-NetConnection -Port XXXX` (listening?)
4. ✅ **CHECK UI/API:** HTTP request or command verification

**IF ANY check ❌ → "NOT FUNCTIONAL"**

**Critical Service Ports:**
- Desktop Client: 1420
- Ollama: 11434
- CORTEX (LightRAG): 8004
- Neuro-Terminal: 8000

**TCP Check Pattern (with timeout):**
```typescript
const portCheck = await run_in_terminal({
  command: "Test-NetConnection -ComputerName 127.0.0.1 -Port 1420 -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction Stop"
});
if (portCheck.stdout.trim() !== "True") {
  throw new Error("❌ Port 1420 not accessible");
}
```

**Note:** `Test-NetConnection` has implicit 5s timeout. For faster checks, use `Test-Connection` or direct socket test.

**Example:****
```typescript
// After: npm run tauri dev (isBackground: true)
await new Promise(resolve => setTimeout(resolve, 10000));  // 10s wait

const processCheck = await run_in_terminal({
  command: "Get-Process -Name tauri_fresh -ErrorAction SilentlyContinue"
});
if (processCheck.exitCode !== 0) {
  throw new Error("❌ Process not found");
}

const portCheck = await run_in_terminal({
  command: "Test-NetConnection -Port 1420 -InformationLevel Quiet"
});
if (portCheck.stdout.trim() !== "True") {
  throw new Error("❌ Port 1420 not accessible");
}

console.log("✅ Desktop Client FUNCTIONAL and STABLE");
```

---

## 🚨 ABSOLUTE RULE: TESTS REQUIRE runTests TOOL

**FORBIDDEN:**
- ❌ DO NOT use `run_in_terminal` for test files (`*test*.ps1`, `test_*.py`, `*.test.ts`)
- ❌ DO NOT use `run_in_terminal` for `pytest`, `npm test`, `cargo test`

**REQUIRED:**
- ✅ USE `runTests` tool for ALL test execution

**Detection Pattern:**
If command contains "test" in filename → use `runTests`:
```typescript
// ❌ WRONG:
await run_in_terminal({ command: "pwsh client/run_auto_tests.ps1" });

// ✅ CORRECT:
await runTests({ files: ["e:\\WORLD_OLLAMA\\client\\run_auto_tests.ps1"] });
```

**Test File Patterns (auto-detect):**
- `**/run_auto_tests.ps1`
- `**/test_*.ps1`
- `**/test_*.py`
- `**/*.test.ts`
- `**/*_test.rs`

---

## 🚨 ABSOLUTE RULE: EXIT CODE CHECK

**EVERY run_in_terminal MUST check Exit Code. NO EXCEPTIONS.**

| Exit Code | Status | Action |
|-----------|--------|--------|
| 0 | ✅ SUCCESS | Continue |
| 1-255 | ❌ FAIL | STOP, report to user |

**Pattern:**
```typescript
const result = await run_in_terminal({ command: "..." });

if (result.exitCode !== 0) {
  throw new Error(`❌ FAIL: Command failed (exit code ${result.exitCode})`);
}

console.log("✅ SUCCESS: Command completed (exit code 0)");
```

**FORBIDDEN:**
- ❌ DO NOT proceed if exitCode !== 0
- ❌ DO NOT ignore exit codes
- ❌ DO NOT retry without error analysis

---

## 🚨 ABSOLUTE RULE: PRODUCTION READY VERIFICATION

**Agent CANNOT claim "PRODUCTION READY" without FULL checklist:**

1. ✅ **Compilation:** `cargo check`, `cargo build --release` (exitCode 0)
2. ✅ **Tests:** `runTests` (all passed)
3. ✅ **Runtime:** Desktop Client (process + port + UI accessible)
4. ✅ **Services:** Ollama + CORTEX (ports + APIs working)
5. ✅ **GPU:** `nvidia-smi` (>6GB VRAM if training involved)
6. ✅ **Exit Codes:** ALL commands returned 0

**IF ANY ❌ → "NOT PRODUCTION READY"**

---

## 🧠 MANDATORY CHAIN OF THOUGHT (CoT)

**TRIGGER (ANY of):**
- Task affects **>1 file**
- Code changes **>50 lines** total
- Has **dependencies** between changes
- Modifies **critical infrastructure** (commands.rs, ApiResponse, flow_manager.rs)

**AUTO-TRIGGER (Agent MUST detect):**
- `multi_replace_string_in_file` with >2 replacements → CoT REQUIRED
- Modification of commands.rs + lib.rs + client.ts → CoT REQUIRED
- Any task mentioning "add new command/feature" → CoT REQUIRED
- User says "plan first" or "steps" → CoT REQUIRED

**BEFORE making changes:**
1. ✅ Call `manage_todo_list` (breakdown into 3-7 steps)
2. ✅ Explain reasoning for each step
3. ✅ Identify dependencies & execution order
4. ✅ Predict side effects (what might break?)
5. ✅ Create rollback plan (git branch, backup)

**DURING execution:**
- Mark ONE task "in-progress" at a time
- Mark "completed" IMMEDIATELY after finishing
- Update user after major milestones

**ENFORCEMENT:** Complex task without CoT → STOP EXECUTION

---

## 📦 TECH STACK (Exact Versions)

**Frontend:**
- **Tauri:** 2.0.x (NOT 1.x — incompatible API)
- **Svelte:** 5.0.0 INSTALLED, but code uses **4.x syntax** (migration pending Q1 2025)
- **Vite:** 6.0.3
- **TypeScript:** 5.6.2

**Backend:**
- **Rust:** 1.75+ (edition 2021)
- **Python:** 3.11+ (NOT 3.9 — missing features)
- **PowerShell:** 7.x (NOT 5.x — different syntax)

**AI Stack:**
- **Ollama:** Latest stable (native, NOT Docker)
- **LightRAG:** Custom fork (`services/lightrag/`)
- **LLaMA Factory:** Custom fork (`services/llama_factory/`)

**ENFORCEMENT:**
- ❌ DO NOT suggest code for wrong versions
- ❌ DO NOT use deprecated APIs (e.g., Tauri 1.x invoke)
- ❌ DO NOT assume PowerShell 5.x compatibility
- ✅ ALWAYS check version BEFORE generating code

---

## 🚨 ABSOLUTE RULE: TESTS REQUIRE runTests TOOL

**FORBIDDEN:**
- ❌ DO NOT use `run_in_terminal` for test files (`*test*.ps1`, `test_*.py`, `*.test.ts`)
- ❌ DO NOT use `run_in_terminal` for `pytest`, `npm test`

**REQUIRED:**
- ✅ USE `runTests` tool for ALL test execution

**Detection Pattern:**
If command contains "test" in filename → use `runTests`:
```typescript
// ❌ WRONG:
await run_in_terminal({ command: "pwsh client/run_auto_tests.ps1" });

// ✅ CORRECT:
await runTests({ files: ["e:\\WORLD_OLLAMA\\client\\run_auto_tests.ps1"] });
```

---

## 🔒 AGENT COMPLIANCE VERIFICATION

**Compliance block REQUIRED for:**
- Tasks affecting >1 file
- Terminal command execution
- Service/API operations
- Code generation
- Analysis tasks creating reports

**Compliance block NOT required for:**
- Simple info queries (version, file location)
- Read-only file analysis (<3 files)
- Quick Index lookups
- Documentation searches

**Format:**

```markdown
## ✅ Pre-Task Protocol Compliance

- [x] Step 1: Read PROJECT_STATUS_SNAPSHOT_v4.0.md
- [x] Step 2: Current version verified (v0.4.0)
- [x] Step 3: Quick Index consulted (if info search needed)
- [x] Step 4: Relevant docs reviewed (if task-specific)

**Applicable Directives:**
- UI-First Workflow: ✅ / ❌ / N/A — [explanation]
- Runtime Stability: ✅ / ❌ / N/A — [explanation]
- Exit Code Check: ✅ / ❌ / N/A — [explanation]
- Service Dependencies: ✅ / ❌ / N/A — [explanation]
```

**Enforcement Policy:**
1. **First violation:** ⚠️ Warning + re-execution required
2. **Second violation:** 🔴 Task rejected, full audit
3. **Third violation:** ⛔ Agent reconfiguration needed

---

## 📋 Quick Reference

**Stack Components:**
- Desktop Client: Tauri 2.0 + Svelte 4.x syntax → 6 panels (Status, Settings, Library, Commands, Training, Git)
- CORTEX (RAG): LightRAG on port 8004 → Ollama (mistral-small + nomic-embed-text)
- Training: LLaMA Factory → TD-010v2 production model

**Critical Files:**
- `PROJECT_STATUS_SNAPSHOT_v4.0.md` — current state, blockers
- `docs/journals/QUICK_INDEX.md` — fast file lookup
- `docs/tasks/TASKS_CONSOLIDATED_REPORT.md` — all UI features
- `client/src-tauri/src/commands.rs` — Tauri API surface
- `services/lightrag/lightrag_server.py` — CORTEX entry point

**Automation (for agents):**
```typescript
// Start all services
await run_in_terminal({
  command: "pwsh scripts/START_ALL.ps1",
  explanation: "Start Ollama + CORTEX + Neuro-Terminal",
  isBackground: true
});

// Check health
await mcp_myshell_execute_command({
  command: "pwsh scripts/CHECK_STATUS.ps1 -Detailed"
});

// Smoke tests
await runTests({
  files: ["e:\\WORLD_OLLAMA\\client\\run_auto_tests.ps1"]
});
```

---

_Core instructions v1.0 — Modular system for optimal context — Token budget: ~1000 tokens_
````
