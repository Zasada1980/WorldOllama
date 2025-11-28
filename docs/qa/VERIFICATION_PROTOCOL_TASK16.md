# VERIFICATION PROTOCOL — TASK 16 (PULSE v1)

**Дата создания:** 28 ноября 2025 г.  
**Версия:** 1.0  
**Статус:** GATE для v0.2.0 Release  
**Принцип ТРИЗ:** №10 (Предварительное действие) — Подготовка проверки делает её тривиальной

---

## 🎯 НАЗНАЧЕНИЕ

Этот документ содержит **детерминированный чек-лист** для верификации интеграции PULSE v1 Protocol. Выполнение всех пунктов означает, что архитектура из "Static Fire Readiness" переходит в "Flight Ready".

**Цель:** Человек, выполняющий сборку, НЕ должен думать о том, что проверять. Он просто следует инструкциям и фиксирует результаты.

---

## ⚙️ ФАЗА 1: КОМПИЛЯЦИЯ RUST BACKEND

### 1.1. Проверка наличия Rust toolchain

**Команда:**
```powershell
rustc --version
cargo --version
```

**Ожидаемый вывод:**
```
rustc 1.XX.0 (YYYY-MM-DD)
cargo 1.XX.0 (YYYY-MM-DD)
```

**Критерий прохождения:** Версии отображаются, нет ошибок "command not found"

**Если НЕ установлен:**
```powershell
# Установка Rust toolchain
Invoke-WebRequest https://win.rustup.rs -OutFile rustup-init.exe
.\rustup-init.exe
# Перезапустить терминал после установки
```

---

### 1.2. Cargo Check (Синтаксическая проверка)

**Команда:**
```powershell
cd E:\WORLD_OLLAMA\client\src-tauri
cargo check 2>&1 | Tee-Object -FilePath "E:\WORLD_OLLAMA\docs\qa\cargo_check_output.txt"
```

**Ожидаемый вывод:**
```
    Checking world-ollama v0.1.0 (E:\WORLD_OLLAMA\client\src-tauri)
    Finished dev [unoptimized + debuginfo] target(s) in XX.XXs
```

**Критерий прохождения:** 
- ✅ `Finished dev` присутствует
- ✅ `0 errors` (нет строк с `error[E0xxx]`)
- ✅ Warnings допустимы (но лучше 0)

**Если FAIL:**
- Проверить вывод в `cargo_check_output.txt`
- Типичные ошибки:
  - `cannot find function set_training_*` → импорты не удалены корректно
  - `mismatched types TrainingStatus` → struct definition не соответствует использованию
  - `async fn poll_training_status not found` → функция не экспортирована

---

### 1.3. Проверка отсутствия obsolete функций (grep)

**Команда:**
```powershell
cd E:\WORLD_OLLAMA\client\src-tauri\src
Select-String -Pattern "set_training_queued|set_training_error|save_training_status" -Path *.rs
```

**Ожидаемый вывод:**
```
(пусто — нет совпадений, или только в комментариях DEPRECATED)
```

**Критерий прохождения:** 
- ✅ 0 matches в активном коде (не в комментариях)
- ✅ Если есть matches → проверить контекст (должны быть только в комментариях)

---

### 1.4. Проверка экспорта poll_training_status

**Команда:**
```powershell
cd E:\WORLD_OLLAMA\client\src-tauri\src
Select-String -Pattern "^pub async fn poll_training_status" -Path training_manager.rs
```

**Ожидаемый вывод:**
```
training_manager.rs:193:pub async fn poll_training_status(
```

**Критерий прохождения:** ✅ Функция найдена с модификатором `pub`

---

### 1.5. Проверка вызова poller в lib.rs

**Команда:**
```powershell
cd E:\WORLD_OLLAMA\client\src-tauri\src
Select-String -Pattern "training_manager::poll_training_status" -Path lib.rs -Context 3
```

**Ожидаемый вывод:**
```
lib.rs:56:            let app_handle_clone = app_handle.clone();
lib.rs:57:            tauri::async_runtime::spawn(async move {
lib.rs:58:                if let Err(e) = training_manager::poll_training_status(app_handle_clone, status_path).await {
lib.rs:59:                    log::error!("[PULSE] Polling error: {}", e);
lib.rs:60:                }
```

**Критерий прохождения:** ✅ Вызов в `.setup()` hook, внутри `tauri::async_runtime::spawn`

---

## 💻 ФАЗА 2: КОМПИЛЯЦИЯ UI FRONTEND

### 2.1. Проверка Node.js и npm

**Команда:**
```powershell
node --version
npm --version
```

**Ожидаемый вывод:**
```
v20.XX.X (или v18.XX.X)
10.XX.X
```

**Критерий прохождения:** ✅ Версии корректные (Node ≥18, npm ≥9)

---

### 2.2. Установка зависимостей (если нужно)

**Команда:**
```powershell
cd E:\WORLD_OLLAMA\client
npm install
```

**Критерий прохождения:** ✅ `node_modules/` существует, нет ошибок установки

---

### 2.3. TypeScript/Svelte Check

**Команда:**
```powershell
cd E:\WORLD_OLLAMA\client
npm run check 2>&1 | Tee-Object -FilePath "E:\WORLD_OLLAMA\docs\qa\svelte_check_output.txt"
```

**Ожидаемый вывод:**
```
> world-ollama@0.1.0 check
> svelte-check --tsconfig ./tsconfig.json

Loading svelte-check in workspace: E:\WORLD_OLLAMA\client
Getting Svelte diagnostics...
====================================
svelte-check found 0 errors, 0 warnings, and 0 hints
```

**Критерий прохождения:** 
- ✅ `0 errors`
- ✅ Warnings допустимы, но лучше 0
- ✅ Нет ошибок типа `Property 'state' does not exist on type 'TrainingStatus'`

**Если FAIL (TypeScript errors):**
- Проверить `TrainingPanel.svelte`:
  - Все ссылки на `status.state` заменены на `status.status`
  - Все ссылки на `status.profile`, `status.dataset_path` удалены
  - Progress calculation использует `status.epoch` и `status.total_epochs`

---

### 2.4. Проверка импорта listen в TrainingPanel.svelte

**Команда:**
```powershell
Select-String -Path "E:\WORLD_OLLAMA\client\src\lib\components\TrainingPanel.svelte" -Pattern "import.*listen.*@tauri-apps/api/event" -Context 0,2
```

**Ожидаемый вывод:**
```
3:  import { listen, type UnlistenFn } from '@tauri-apps/api/event';
```

**Критерий прохождения:** ✅ Импорт `listen` и `UnlistenFn` присутствует

---

### 2.5. Проверка setupPulseListener вызывается в onMount

**Команда:**
```powershell
Select-String -Path "E:\WORLD_OLLAMA\client\src\lib\components\TrainingPanel.svelte" -Pattern "await setupPulseListener" -Context 2,2
```

**Ожидаемый вывод:**
```
311:    loadContext();              // PULSE v1: Load profile/dataset from localStorage
312:    await setupPulseListener(); // PULSE v1: Subscribe to training_status_update events
313:    refreshStatus();            // Initial status fetch
```

**Критерий прохождения:** ✅ Вызов в `onMount` до `refreshStatus()`

---

### 2.6. Проверка Progress Calculation

**Команда:**
```powershell
Select-String -Path "E:\WORLD_OLLAMA\client\src\lib\components\TrainingPanel.svelte" -Pattern "progressPercent.*Math\.min" -Context 1,1
```

**Ожидаемый вывод:**
```
251:  // NaN Protection: Math.min + zero-division guard
252:  $: progressPercent = (status && status.total_epochs > 0) 
253:    ? Math.min(100, Math.round((status.epoch / status.total_epochs) * 100)) 
254:    : 0;
```

**Критерий прохождения:** 
- ✅ `Math.min(100, ...)` присутствует (clamp к 100%)
- ✅ `status.total_epochs > 0` guard присутствует (zero-division protection)

---

## 🧪 ФАЗА 3: E2E ТЕСТИРОВАНИЕ (RUNTIME)

### Prerequisite: Запуск сервисов

**Команды:**
```powershell
# Запустить Ollama + CORTEX (без Neuro-Terminal)
pwsh E:\WORLD_OLLAMA\scripts\START_ALL.ps1 -SkipNeuroTerminal

# Проверить статус
pwsh E:\WORLD_OLLAMA\scripts\CHECK_STATUS.ps1
```

**Ожидаемый вывод CHECK_STATUS:**
```
✅ Ollama: http://127.0.0.1:11434 (Response time: XX ms)
✅ CORTEX: http://127.0.0.1:8004/health (Response time: XX ms)
```

**Критерий прохождения:** ✅ Оба сервиса LISTENING

---

### E2E Test 1: Singleton Poller Start (BLOCKING для v0.2.0)

**Шаг 1:** Запустить Tauri app
```powershell
cd E:\WORLD_OLLAMA\client
npm run tauri dev
```

**Шаг 2:** Проверить лог в терминале

**Ожидаемый вывод:**
```
[PULSE] Starting singleton training status poller
```

**Критерий прохождения:** 
- ✅ Лог присутствует в первые 5 секунд запуска
- ✅ Только ОДНО сообщение (не дублируется)

**Если FAIL:**
- Poller не запускается → проверить `lib.rs` .setup() hook
- Poller запускается несколько раз → проверить отсутствие вызовов из других мест

---

### E2E Test 2: Event Emission (Basic Flow) (BLOCKING для v0.2.0)

**Шаг 1:** Оставить Tauri app запущенным, открыть новый терминал

**Шаг 2:** Имитировать PULSE update (Python)
```powershell
cd E:\WORLD_OLLAMA\services\llama_factory
.\.venv\Scripts\Activate.ps1
python -c "from pulse_wrapper import write_running_status; write_running_status('E:/WORLD_OLLAMA/client/src-tauri/training_status.json', 1.5, 3.0, 0.342, 'test epoch 1.5/3')"
```

**Шаг 3:** Наблюдать UI в течение 2-10 секунд

**Ожидаемые изменения в UI:**
- ✅ Status badge: `ВЫПОЛНЯЕТСЯ` (зелёный)
- ✅ Progress bar: `50%` (или близко к этому)
- ✅ Loss: `0.3420`
- ✅ Эпохи: `1.5 / 3.0`
- ✅ Сообщение: `test epoch 1.5/3`
- ✅ Timestamp: обновился (текущее время)

**Критерий прохождения:** ✅ Все 6 полей обновились корректно

**Если FAIL:**
- UI не обновляется → проверить console logs (F12), ошибки event listening
- Progress NaN → проверить calculation в TrainingPanel.svelte
- Данные не соответствуют → проверить TrainingStatus interface (6 полей)

---

### E2E Test 3: localStorage Context Persistence (RECOMMENDED)

**Шаг 1:** В UI открыть вкладку "Training Panel"

**Шаг 2:** Выбрать:
- Profile: "TRIZ Engineer" (или любой доступный)
- Dataset: "Cleaned Documents" (или любой доступный)

**Шаг 3:** Нажать "Запустить обучение" (или mock это через startTraining())

**Шаг 4:** Открыть DevTools (F12) → Application → Local Storage → `http://localhost:1420`

**Ожидаемое содержимое:**
```
Key: active_training_context
Value: {"profile":"TRIZ Engineer","dataset":"Cleaned Documents"}
```

**Критерий прохождения:** 
- ✅ Key существует
- ✅ Value корректный JSON
- ✅ Поля `profile` и `dataset` соответствуют выбранным

**Если FAIL:**
- Key отсутствует → проверить вызов `saveContext()` в `startTraining()`
- Value некорректный → проверить `profileObj.name` и `datasetObj.name`

---

### E2E Test 4: Stale Detection (60s Timeout) (RECOMMENDED)

**Шаг 1:** Создать старый timestamp (70 секунд назад)
```powershell
$oldTimestamp = [Math]::Floor((Get-Date).ToUniversalTime().Subtract((Get-Date "1970-01-01 00:00:00")).TotalSeconds) - 70
```

**Шаг 2:** Записать старый PULSE status
```powershell
cd E:\WORLD_OLLAMA\services\llama_factory
.\.venv\Scripts\Activate.ps1
python -c "import json; open('E:/WORLD_OLLAMA/client/src-tauri/training_status.json', 'w').write(json.dumps({'status': 'running', 'epoch': 1.0, 'total_epochs': 3.0, 'loss': 0.5, 'message': 'old status', 'timestamp': $oldTimestamp}))"
```

**Шаг 3:** Подождать 2-10 секунд (polling cycle)

**Ожидаемые изменения в UI:**
- ✅ Status badge: `ОШИБКА` (красный)
- ✅ Message: `Process unresponsive (stale pulse)` (или схожее)

**Критерий прохождения:** ✅ UI показывает error status

**Если FAIL:**
- Status не меняется на error → проверить `is_stale()` в `training_manager.rs`
- Stale detection срабатывает для idle/done → проверить guard `self.status != "running"`

---

### E2E Test 5: Progress NaN Protection (RECOMMENDED)

**Шаг 1:** Записать PULSE с total_epochs = 0
```powershell
cd E:\WORLD_OLLAMA\services\llama_factory
.\.venv\Scripts\Activate.ps1
python -c "from pulse_wrapper import write_running_status; write_running_status('E:/WORLD_OLLAMA/client/src-tauri/training_status.json', 0.0, 0.0, 0.0, 'zero epochs test')"
```

**Шаг 2:** Проверить UI

**Ожидаемый результат:**
- ✅ Progress bar: `0%` (НЕ NaN, НЕ Infinity)
- ✅ Нет console errors (F12 → Console)

**Критерий прохождения:** ✅ Progress остаётся 0, UI не ломается

**Если FAIL:**
- Progress показывает NaN → проверить `status.total_epochs > 0` guard
- UI ломается → проверить reactive statement `$: progressPercent`

---

## 📊 ФАЗА 4: ФИНАЛЬНЫЙ ОТЧЁТ

### 4.1. Заполнение Verification Report

Создать файл `E:\WORLD_OLLAMA\docs\qa\TASK16_VERIFICATION_RESULTS.md` с результатами:

```markdown
# TASK 16 VERIFICATION RESULTS

**Дата проверки:** [YYYY-MM-DD]  
**Исполнитель:** [Имя проверяющего]  
**Версия:** [v0.2.0-pre или v0.X.X]

## ФАЗА 1: RUST BACKEND

- [ ] 1.1. Rust toolchain установлен
- [ ] 1.2. `cargo check` — 0 errors
- [ ] 1.3. Obsolete функции отсутствуют (grep)
- [ ] 1.4. `poll_training_status` экспортирован
- [ ] 1.5. Poller вызывается в lib.rs

**Результат Фазы 1:** ✅ PASS / ❌ FAIL

## ФАЗА 2: UI FRONTEND

- [ ] 2.1. Node.js и npm установлены
- [ ] 2.2. Зависимости установлены
- [ ] 2.3. `npm run check` — 0 errors
- [ ] 2.4. `listen` импортирован
- [ ] 2.5. `setupPulseListener` вызывается
- [ ] 2.6. Progress calculation корректен

**Результат Фазы 2:** ✅ PASS / ❌ FAIL

## ФАЗА 3: E2E ТЕСТИРОВАНИЕ

- [ ] Test 1: Singleton poller start (BLOCKING)
- [ ] Test 2: Event emission (BLOCKING)
- [ ] Test 3: localStorage persistence (RECOMMENDED)
- [ ] Test 4: Stale detection (RECOMMENDED)
- [ ] Test 5: Progress NaN protection (RECOMMENDED)

**Результат Фазы 3:** ✅ PASS / ❌ FAIL

## ОБЩИЙ СТАТУС

- **ФАЗА 1:** [ ] PASS / [ ] FAIL
- **ФАЗА 2:** [ ] PASS / [ ] FAIL
- **ФАЗА 3 (BLOCKING):** [ ] PASS / [ ] FAIL
- **ФАЗА 3 (RECOMMENDED):** [ ] PASS / [ ] FAIL

**ФИНАЛЬНЫЙ ВЕРДИКТ:** [ ] ✅ GATE OPEN (v0.2.0 ready) / [ ] ❌ GATE CLOSED (need fixes)

**Комментарии:**
[Любые наблюдения, проблемы, рекомендации]
```

---

### 4.2. Обновление PROJECT_STATUS_SNAPSHOT

**Если ВСЕ ФАЗЫ PASS:**
- Изменить статус TASK 16: `🟡 ARCHITECTURE COMPLETE` → `✅ VERIFIED`
- Удалить блокировку v0.2.0 Release Gate

**Если FAIL:**
- Зафиксировать проблемы в `TASK16_VERIFICATION_RESULTS.md`
- Создать TASK 16.1 (Bug Fix) с конкретными ошибками
- Оставить блокировку v0.2.0 Release Gate

---

## 🎯 КРИТЕРИИ УСПЕХА (SUMMARY)

### Минимальные требования для v0.2.0 Release (BLOCKING):

1. ✅ **Cargo check passes** (0 errors)
2. ✅ **Svelte check passes** (0 errors)
3. ✅ **E2E Test 1** (Singleton poller starts)
4. ✅ **E2E Test 2** (Event emission works)

### Рекомендуемые проверки (RECOMMENDED):

5. ✅ **E2E Test 3** (localStorage context)
6. ✅ **E2E Test 4** (Stale detection)
7. ✅ **E2E Test 5** (NaN protection)

**ОБЩАЯ ФОРМУЛА:**
```
GATE OPEN = (BLOCKING tests ALL PASS) AND (Recommended tests ≥60% PASS)
```

---

## 📝 NOTES & TROUBLESHOOTING

### Типичные проблемы и решения

**Problem 1: cargo check fails с "cannot find function poll_training_status"**
- **Solution:** Проверить `pub` модификатор в `training_manager.rs` line 193

**Problem 2: UI не обновляется при изменении JSON**
- **Solution 1:** Проверить console logs (F12) на ошибки event listening
- **Solution 2:** Проверить что poller запустился (лог `[PULSE] Starting singleton...`)
- **Solution 3:** Проверить что JSON файл в правильном месте (`client/src-tauri/training_status.json`)

**Problem 3: Progress показывает NaN**
- **Solution:** Проверить reactive statement в TrainingPanel.svelte:
  ```typescript
  $: progressPercent = (status && status.total_epochs > 0) 
    ? Math.min(100, Math.round((status.epoch / status.total_epochs) * 100)) 
    : 0;
  ```

**Problem 4: TypeScript errors про missing fields (state, profile, etc.)**
- **Solution:** Заменить все старые поля на PULSE v1:
  - `status.state` → `status.status`
  - `status.profile` → `context?.profile` (из localStorage)
  - `status.current_epoch` → `status.epoch`
  - `status.progress` → `progressPercent` (computed)

---

**ВЕРСИЯ ПРОТОКОЛА:** 1.0  
**ПОСЛЕДНЕЕ ОБНОВЛЕНИЕ:** 28 ноября 2025 г.  
**АВТОР:** CODEX Agent (под руководством SESA3002a)  
**ПРИНЦИП ТРИЗ:** №10 (Предварительное действие) — "Если проверка подготовлена детально, её выполнение тривиально"

---

_"Static Fire to Flight Ready: Verification is not a task, it's a ritual."_
