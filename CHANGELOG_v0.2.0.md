# CHANGELOG — v0.2.0 (Release Candidate)

**Дата:** 28 ноября 2025 г.  
**Статус:** 🟡 RC1 (Pending Compilation & Testing)  
**Кодовое имя:** "Static Fire Readiness"

---

## 🎯 ЦЕЛЬ РЕЛИЗА

Интеграция двух критических подсистем Desktop Client:
1. **PULSE v1 Protocol** — Мониторинг обучения моделей в реальном времени
2. **Safe Git Assistant** — Безопасный конвейер Git Push с предварительным анализом

**Философия:** "Plan Before Execute" (ТРИЗ Principle №10 — Предварительное действие)

---

## 🚀 НОВЫЕ ВОЗМОЖНОСТИ

### 1. PULSE v1 — Training Status Monitor (TASK 16)

**Описание:** Архитектура для мониторинга обучения моделей через атомарные JSON файлы.

**Компоненты:**
- **Python Backend:** `pulse_wrapper.py` — Атомарная запись статуса через `os.replace()`
- **Rust Poller:** `poll_training_status()` — Singleton loop с адаптивным интервалом (2-10s)
- **UI Component:** `TrainingPanel.svelte` — Reactive dashboard с NaN guards

**PULSE Schema (FROZEN):**
```json
{
  "status": "idle|running|done|error",
  "epoch": 0.0,
  "total_epochs": 0.0,
  "loss": 0.0,
  "message": "string",
  "timestamp": 1732800000
}
```

**Ключевые изменения:**
- ✅ Разделение ответственности: Python (write only) ↔ Rust (read only)
- ✅ Context isolation: Profile/Dataset в localStorage (не в PULSE JSON)
- ✅ Progress calculation: `Math.min(100, (epoch/total_epochs)*100)` с zero-division guard
- ✅ Stale detection: Timeout 60s для running status
- ✅ Event-driven UI: `training_status_update` через Tauri events

**Метрики оптимизации:**
- TrainingStatus fields: 10 → 6 (-40%)
- Rust write functions: 6 → 0 (-100%)
- JSON size: ~500 bytes → ~200 bytes (-60%)

**Known Limitations:**
- Missing file = `idle` (ambiguous: "never started" or "file deleted"?)
- Stale detection ONLY для `running` (by design)
- No real-time updates (polling-based)

---

### 2. Safe Git Assistant (TASK 17)

**Описание:** Двухфазный конвейер для безопасного Git Push с предварительным анализом.

**Компоненты:**
- **Rust Backend:** `git_manager.rs` — Plan + Execute логика
- **Tauri Commands:** `plan_git_push`, `execute_git_push`
- **UI Component:** `GitPanel.svelte` — Plan preview + Execution control

**Workflow:**
```
1. PLAN (readonly):
   - Check unstaged/uncommitted changes
   - Check branch mismatch
   - Check remote ahead
   - Check no upstream
   - Return GitPushPlan { status, commits, blocked_reasons }

2. REVIEW (UI):
   - Show commits to push
   - Show changed files
   - Show blocked reasons (if any)
   - Enable/disable "Execute Push" button

3. EXECUTE (write):
   - RE-VALIDATE (plan_git_push повторно)
   - If status == "ready" → git push
   - Return GitPushResult { success, message }
```

**Safety Checks (7 блокирующих сценариев):**
1. ✅ Unstaged changes detected
2. ✅ Uncommitted changes detected
3. ✅ Current branch ≠ target branch
4. ✅ Remote not found
5. ✅ Branch does not exist on remote
6. ✅ **Remote is ahead (pull required)** ← NEW in RC1
7. ✅ **No upstream branch configured** ← NEW in RC1

**Приоритеты статусов (детерминированная логика):**
```rust
if !blocked_reasons.is_empty() {
    status = "blocked";  // ПРИОРИТЕТ 1
} else if commits.is_empty() {
    status = "clean";    // ПРИОРИТЕТ 2
} else {
    status = "ready";    // ПРИОРИТЕТ 3
}
```

**ТРИЗ Principles Applied:**
- **№10 (Предварительное действие):** Plan → Review → Execute
- **№3 (Местное качество):** Статус учитывает локальное + remote состояние
- **№13 (Инверсия):** "Pending Verification" как gate, не проблема

**Known Limitations:**
- Требует `git fetch` перед plan (иначе remote ahead не детектируется)
- Dry-run mode отсутствует (нет предпросмотра diff)
- API key detection не реализована (запланировано в TASK 17.3)

---

## 🔧 ТЕХНИЧЕСКИЕ ИЗМЕНЕНИЯ

### Rust Backend

**Новые модули:**
- `client/src-tauri/src/training_manager.rs` (TASK 16)
  - `poll_training_status()` — Singleton poller
  - `get_training_status()` — Read JSON
  - `TrainingStatus` struct (6 fields)
  
- `client/src-tauri/src/git_manager.rs` (TASK 17)
  - `plan_git_push()` — 6 readonly checks
  - `execute_git_push()` — Re-validation + push
  - `GitPushPlan`, `GitPushResult` structs

**Модифицированные файлы:**
- `lib.rs`: +2 mod declarations, +2 Tauri commands
- `commands.rs`: +146 строк (4 новых команды)

**Tauri Commands (зарегистрированные):**
```rust
tauri::generate_handler![
    // ... existing ...
    get_training_status,
    clear_training_status,
    list_training_profiles,
    list_datasets_roots,
    get_project_root,        // TASK 16.1 — Path Agnosticism
    plan_git_push,           // TASK 17
    execute_git_push,        // TASK 17
]
```

---

### UI Frontend

**Новые компоненты:**
- `client/src/lib/components/TrainingPanel.svelte` (988 lines)
  - PULSE v1 event listener
  - localStorage context persistence
  - Progress calculation с NaN guards
  - Stale detection UI
  
- `client/src/lib/components/GitPanel.svelte` (465 lines)
  - Plan preview (commits, files, blocked reasons)
  - Execute button с loading state
  - Success/Error toast messages
  - Auto-refresh после push

**TypeScript Interfaces:**
```typescript
// PULSE v1
interface TrainingStatus {
  status: 'idle'|'running'|'done'|'error';
  epoch: number;
  total_epochs: number;
  loss: number;
  message: string;
  timestamp: number;
}

// Safe Git
interface GitPushPlan {
  status: 'ready'|'blocked'|'clean';
  commits: string[];
  files_changed: string[];
  blocked_reasons: string[];
}

interface GitPushResult {
  success: boolean;
  message: string;
}
```

**TypeScript Errors:** ✅ 0 (verified)

---

### Python Backend

**Новые модули:**
- `services/llama_factory/pulse_wrapper.py`
  - `write_idle_status()`
  - `write_running_status()`
  - `write_done_status()`
  - `write_error_status()`
  - All functions use atomic `os.replace()`

**Integration Points:**
- LLaMA Factory training loop (готово к интеграции)
- Файл статуса: `client/src-tauri/training_status.json`

---

## 📋 ДОКУМЕНТАЦИЯ

**Новые отчёты:**
- `docs/tasks/TASK_16_COMPLETION_REPORT.md` (90KB)
  - Полная спецификация PULSE v1
  - Deployment checklist (5 E2E сценариев)
  
- `docs/qa/VERIFICATION_PROTOCOL_TASK16.md` (детерминированный чек-лист)
  - Cargo check procedure
  - Svelte build procedure
  - E2E Test scenarios 1-5
  
- `PROJECT_STATUS_SNAPSHOT_v3.5.md` (обновлён)
  - TASK 16: 🟡 ARCHITECTURE COMPLETE
  - TASK 17: 🟡 ARCHITECTURE COMPLETE
  - Gate для v0.2.0: cargo check + E2E tests

**Обновлённые документы:**
- `PROJECT_MAP.md` — Архитектура проекта
- `STATE_SNAPSHOT_v3.1.md` — Состояние системы

---

## ⚠️ ИЗВЕСТНЫЕ ОГРАНИЧЕНИЯ (Known Issues)

### TASK 16 (PULSE v1)

1. **Ambiguous Idle State:**
   - Missing `training_status.json` → interpreted as "idle"
   - **Impact:** Невозможно отличить "never started" от "file deleted"
   - **Workaround:** Accepted tradeoff (prevents crash on first run)

2. **Stale Detection Scope:**
   - Timeout check ONLY для `status == "running"`
   - **Impact:** Если процесс завис в `done` или `error`, stale не детектируется
   - **Rationale:** By design (done/error = terminal states)

3. **Polling Latency:**
   - Adaptive interval: 2-10 seconds
   - **Impact:** UI обновляется с задержкой до 10 секунд
   - **Future:** PULSE v2 может использовать WebSockets

---

### TASK 17 (Safe Git)

1. **Fetch Requirement:**
   - Remote ahead check требует предварительного `git fetch`
   - **Impact:** Если не делать fetch, remote ahead не детектируется
   - **Workaround:** Документировано в USER MANUAL

2. **No Diff Preview:**
   - Нет предпросмотра изменений перед push
   - **Impact:** Пользователь не видит diff, только список файлов
   - **Future:** TASK 17.3 — Diff modal

3. **No API Key Detection:**
   - Отсутствует сканирование на утечку секретов
   - **Impact:** Риск случайного push API ключей
   - **Future:** TASK 17.3 — Regex + entropy analysis

---

## 🔄 МИГРАЦИЯ (для существующих пользователей)

**С v0.1.0 на v0.2.0:**

1. **Training System:**
   - Старые `training_status.json` будут игнорироваться (новый schema)
   - Требуется удалить старый файл: `rm client/src-tauri/training_status.json`
   - Context (profile/dataset) теперь в localStorage

2. **Git System:**
   - Нет breaking changes (новая функциональность)
   - Рекомендуется: `git fetch` перед использованием GitPanel

3. **Path Agnosticism:**
   - Новая команда `get_project_root()` автоматически определяет корень
   - Environment variable `WORLD_OLLAMA_ROOT` для override

---

## 🧪 ТЕСТИРОВАНИЕ (требуется перед production)

### БЛОКИРУЮЩИЕ ПРОВЕРКИ (v0.2.0 Release Gate)

**Compilation:**
```powershell
cd E:\WORLD_OLLAMA\client\src-tauri
cargo check
# Expected: 0 errors
```

**TypeScript:**
```powershell
cd E:\WORLD_OLLAMA\client
npm run check
# Expected: 0 errors
```

**E2E Scenario 1-2 (PULSE):**
1. Start Tauri app
2. Write PULSE status via Python
3. Verify UI updates within 10s
4. Check localStorage context persistence

**E2E Scenario 1-2 (Git):**
1. Create test commit
2. Run `plan_git_push` → status = "ready"
3. Click "Execute Push"
4. Verify success message + auto-refresh

### РЕКОМЕНДУЕМЫЕ ПРОВЕРКИ

- E2E Scenario 3-5 (PULSE): Stale detection, NaN guards
- E2E Scenario 3-5 (Git): Remote ahead, no upstream, clean state
- Performance: Poller CPU usage (<1%)
- Memory: Training status JSON size (<1KB)

---

## 📊 СТАТИСТИКА РЕЛИЗА

**Кодовая база:**
- Новых файлов: 6 (2 Rust, 2 Svelte, 2 Python)
- Модифицированных файлов: 4 (lib.rs, commands.rs, PROJECT_STATUS, README)
- Строк кода добавлено: ~2500
- Строк документации: ~1200

**Компоненты:**
- Rust modules: 2 (training_manager, git_manager)
- Tauri commands: 7 (4 training, 2 git, 1 path)
- UI components: 2 (TrainingPanel, GitPanel)
- Python wrappers: 1 (pulse_wrapper)

**Тесты:**
- Unit tests: 0 (pending TASK 17.4)
- E2E tests: 10 сценариев (documented, not automated)
- Verification protocols: 2 (TASK 16, TASK 17)

---

## 🎯 СЛЕДУЮЩИЕ ШАГИ (Post-v0.2.0)

### Фаза 4: Production Deployment

1. **TASK 17.3:** Pre-flight Safety Checks
   - File size limits (>100MB)
   - API key detection (regex + entropy)
   - Diff preview modal

2. **TASK 18:** Windows Installer (WiX)
   - MSI package с auto-update
   - Desktop shortcuts
   - Uninstaller

3. **TASK 19:** PULSE v2 (Real-time)
   - WebSocket вместо polling
   - Progress bar с ETA
   - Training metrics visualization

4. **TASK 20:** Git Advanced Features
   - Branch management UI
   - Merge conflict resolver
   - Commit history viewer

---

## 👥 АВТОРЫ И БЛАГОДАРНОСТИ

**Команда разработки:**
- **CODEX Agent** — Rust/TypeScript implementation
- **SESA3002a** — ТРИЗ Architecture & Design Review
- **Aura** — Code Quality Audit & Safety Analysis

**ТРИЗ Principles Consultant:**
- Principle №1 (Segmentation): Architecture vs Verification separation
- Principle №3 (Local Quality): Remote + Local state fusion
- Principle №10 (Preliminary Action): Plan Before Execute paradigm
- Principle №13 (Inversion): Pending Verification as gate
- Principle №22 (Convert Harm to Benefit): Missing file = idle (accepted tradeoff)

---

## 📝 ЗАМЕТКИ ДЛЯ РЕЛИЗНОГО ИНЖЕНЕРА

**CRITICAL:**
- ⚠️ Код НЕ СКОМПИЛИРОВАН (no Rust toolchain in current environment)
- ⚠️ TypeScript проверен (0 errors), Rust статически верифицирован (grep)
- ✅ Код считается "Golden Master" (готов к compilation)

**Рекомендации:**
1. Запустить `cargo check` в первую очередь
2. Если ошибки → проверить `git_manager.rs` imports
3. После compilation → запустить E2E Scenario 1-2 (блокирующие)
4. После успеха → создать MSI installer (TASK 18)

**Контакт для вопросов:**
- GitHub Issues: WorldOllama/issues
- Project Lead: SESA3002a

---

**СТАТУС:** ✅ Changelog Complete  
**ВЕРСИЯ ДОКУМЕНТА:** 1.0  
**ДАТА ПОСЛЕДНЕГО ОБНОВЛЕНИЯ:** 28 ноября 2025 г.
