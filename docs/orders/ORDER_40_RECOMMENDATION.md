# 🎯 NEXT STEP RECOMMENDATION — ORDER 40

**Дата:** 02.12.2025  
**После:** ORDER 51 (housekeeping complete)  
**Рекомендация:** ORDER 40 — Bugfix Pack v0.3.1

---

## 📊 ТЕКУЩАЯ СИТУАЦИЯ

### ✅ Что завершено (ORDER 51):

- Документация очищена и структурирована
- 44909 файлов проиндексировано с тегами/статусами
- CODEX Memory Bootstrap протокол создан
- System healthcheck: 0 critical issues
- Агент знает как избегать FALSE GREENS

### ⚠️ Что блокирует v0.3.1 release:

| Блокер | Статус | Impact |
|--------|--------|--------|
| **ORDER 37** — INDEX path resolution | 🔴 CRITICAL | `index_and_train` flow fails in production |
| **GitPanel CWD** | 🟡 MEDIUM | `git_check` flow fails (wrong working directory) |
| **TrainingPanel profile** | 🟡 MEDIUM | `train_default` flow partially broken |
| **ORDER 43** — HF auth | 🟢 EXTERNAL | Blocks real training (user action needed) |

### 📋 Cleanup Backlog (non-blocking):

- 7 Rust warnings (unused imports/functions)
- 8 Svelte warnings (a11y + unused CSS)
- 1 legacy script to archive
- 1 unimplemented feature (ingest_watcher.ps1)

---

## 🎯 РЕКОМЕНДАЦИЯ: ORDER 40 — BUGFIX PACK v0.3.1

**Цель:** Стабилизировать функциональность перед выходом из alpha в preview-ready.

**Фокус:** Исправить 3 критичных блокера flows + cleanup warnings.

---

## 📋 ORDER 40 EXECUTION PLAN (draft)

### Команда 40.1 — FIX INDEX Path Resolution (ORDER 37)

**Блокер:** `index_and_train` flow fails

**Проблема:**
```rust
// client/src-tauri/src/index_manager.rs
let root = std::env::current_exe()
    .parent().parent()  // Hardcoded assumption about exe location
```

**Решение:**
- Использовать `WORLD_OLLAMA_ROOT` env var
- Fallback: `std::env::current_dir()`
- Убрать hardcoded paths

**Expected effort:** 2-3 hours

**Definition of Done:**
- ✅ `index_and_train` flow passes E2E test
- ✅ INDEX command works in both dev (`npm run tauri dev`) and production (`tauri_fresh.exe`)
- ✅ ORDER_37_FIX_COMPLETION_REPORT.md создан с доказательствами

---

### Команда 40.2 — FIX GitPanel Working Directory

**Блокер:** `git_check` flow fails

**Проблема:**
```rust
// GitPanel calls git commands without setting CWD
// → git commands execute in wrong directory
```

**Решение:**
- В `git_manager.rs` добавить `set_current_dir()` перед git командами
- Использовать `WORLD_OLLAMA_ROOT` как base directory

**Expected effort:** 1-2 hours

**Definition of Done:**
- ✅ `git_check` flow passes E2E test
- ✅ GitPanel показывает корректный status
- ✅ Git commands execute in correct working directory

---

### Команда 40.3 — FIX TrainingPanel Profile Selection

**Блокер:** `train_default` flow partially broken

**Проблема:**
- Profile selection не синхронизирована с `canStartTraining` validation
- Некоторые профили не передаются в backend

**Решение:**
- Проверить reactive logic в TrainingPanel.svelte
- Убедиться что все профили в Rust whitelist
- Добавить profile в PULSE status updates

**Expected effort:** 1-2 hours

**Definition of Done:**
- ✅ `train_default` flow passes E2E test
- ✅ Все профили доступны и работают
- ✅ PULSE показывает активный profile

---

### Команда 40.4 — Cleanup Warnings

**Non-blocking cleanup:**

1. **Rust warnings (7 total):**
   ```powershell
   # Удалить unused imports
   - commands.rs: AppHandle, Emitter
   - git_manager.rs: PathBuf
   
   # Удалить unused code
   - training_manager.rs: calculate_progress, get_current_timestamp
   - flow_manager.rs: unused `app` variable
   - index_manager.rs: unused fields `profile`, `mode`
   ```

2. **Svelte warnings (8 total):**
   ```powershell
   # Fix HTML best practices
   - Chat.svelte: self-closing <textarea />
   - CommandSlot.svelte: self-closing <textarea />
   
   # Fix a11y
   - Settings.svelte: label без associated control
   
   # Remove unused CSS
   - SettingsPanel.svelte: .message, .message.success, .message.error
   - SystemStatusPanel.svelte: .error-box
   - TrainingPanel.svelte: .toggle input[type="checkbox"]
   ```

**Expected effort:** 1 hour

**Definition of Done:**
- ✅ `cargo check` → 0 warnings
- ✅ `npm run check` → 0 warnings

---

### Команда 40.5 — E2E Validation & Reports

**Цель:** Убедиться что все 5 flows работают

**Flows to test:**
1. `quick_status` — System status check
2. `index_and_train` — Full pipeline (INDEX + TRAIN)
3. `git_check` — Git status verification
4. `train_default` — Training with default profile
5. `pulse_monitor` — Real-time PULSE monitoring

**E2E test procedure:**
```powershell
# 1. Запустить Desktop Client
npm run tauri dev

# 2. Для каждого flow:
#    - Запустить через FlowsPanel UI
#    - Проверить execution history (no errors)
#    - Проверить логи (logs/flows/*.log)

# 3. Создать отчёты:
#    - TASK_40_E2E_TEST_RESULTS.md
#    - ORDER_40_COMPLETION_REPORT.md
```

**Expected effort:** 2 hours

**Definition of Done:**
- ✅ Все 5 flows проходят E2E тест
- ✅ TASK_40_E2E_TEST_RESULTS.md создан
- ✅ ORDER_40_COMPLETION_REPORT.md создан
- ✅ TASK_39_RELEASE_GATE_REPORT.md обновлён (5/5 flows green)

---

### Команда 40.6 — Update Documentation

**Files to update:**

1. **PROJECT_STATUS_SNAPSHOT_v4.0.md:**
   - ORDER 40 → ✅ COMPLETE
   - ORDER 37 → ✅ RESOLVED (path resolution fixed)
   - v0.3.1 → READY FOR RELEASE

2. **CHANGELOG.md:**
   ```markdown
   ## v0.3.1 (Bugfix Pack) — 202X-XX-XX
   
   ### Fixed
   - ORDER 37: INDEX path resolution (production blocker)
   - GitPanel working directory (git_check flow)
   - TrainingPanel profile selection (train_default flow)
   - 7 Rust warnings (unused code cleanup)
   - 8 Svelte warnings (a11y + unused CSS)
   
   ### Tested
   - 5/5 flows pass E2E validation
   ```

3. **PROJECT_INDEX_v51.json:**
   - Re-generate после изменений (если файлы добавлены/удалены)

**Expected effort:** 30 min

**Definition of Done:**
- ✅ PROJECT_STATUS updated
- ✅ CHANGELOG updated
- ✅ PROJECT_INDEX regenerated (if needed)

---

## 🎯 TOTAL EFFORT ESTIMATE

| Команда | Описание | Effort | Priority |
|---------|----------|--------|----------|
| 40.1 | INDEX path fix | 2-3h | 🔴 CRITICAL |
| 40.2 | GitPanel CWD fix | 1-2h | 🟡 MEDIUM |
| 40.3 | TrainingPanel profile fix | 1-2h | 🟡 MEDIUM |
| 40.4 | Cleanup warnings | 1h | 🟢 LOW |
| 40.5 | E2E validation | 2h | 🔴 CRITICAL |
| 40.6 | Update docs | 30m | 🔴 CRITICAL |
| **TOTAL** | | **8-11 hours** | |

**Realistic timeline:** 1-2 дня (с перерывами)

---

## 📋 DEFINITION OF DONE (ORDER 40)

ORDER 40 считается завершённым, когда:

- ✅ ORDER 37 FIX: INDEX path resolution работает в dev и production
- ✅ GitPanel CWD: `git_check` flow passes
- ✅ TrainingPanel: `train_default` flow passes
- ✅ Cleanup: `cargo check` и `npm run check` → 0 warnings
- ✅ E2E: Все 5 flows проходят тестирование
- ✅ Reports:
  - ORDER_37_FIX_COMPLETION_REPORT.md
  - TASK_40_E2E_TEST_RESULTS.md
  - ORDER_40_COMPLETION_REPORT.md
- ✅ Documentation:
  - PROJECT_STATUS_SNAPSHOT_v4.0.md updated
  - CHANGELOG.md updated (v0.3.1 section)

---

## 🚀 СЛЕДУЮЩИЙ ОРДЕР

**Формулировка для агента:**

```markdown
КОМАНДНЫЙ ОРДЕР № 40 — BUGFIX PACK v0.3.1

Статус: К ИСПОЛНЕНИЮ
Исполнитель: CODEX Agent
Предыдущий: ORDER 51 (housekeeping complete)

Цель:
Исправить 3 критичных блокера flows (ORDER 37, GitPanel CWD, TrainingPanel profile),
провести cleanup warnings, выполнить E2E validation всех 5 flows.

Команды:
1. 40.1 — FIX INDEX Path Resolution (ORDER 37) → 2-3h
2. 40.2 — FIX GitPanel Working Directory → 1-2h
3. 40.3 — FIX TrainingPanel Profile Selection → 1-2h
4. 40.4 — Cleanup Warnings (7 Rust + 8 Svelte) → 1h
5. 40.5 — E2E Validation (all 5 flows) → 2h
6. 40.6 — Update Documentation → 30m

Definition of Done:
- Все 5 flows проходят E2E тест
- cargo check и npm run check → 0 warnings
- ORDER_40_COMPLETION_REPORT.md создан с доказательствами
- PROJECT_STATUS updated (v0.3.1 READY FOR RELEASE)

Total effort: 8-11 hours
Priority: 🔴 CRITICAL (unlocks v0.3.1 release)
```

---

**Статус рекомендации:** ✅ READY  
**Приоритет:** 🔴 CRITICAL  
**Ожидаемый результат:** v0.3.1 preview-ready (выход из alpha)
