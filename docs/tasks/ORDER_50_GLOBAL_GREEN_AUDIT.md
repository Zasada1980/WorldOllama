# ORDER 50 — GLOBAL GREEN AUDIT

**Исполнителю:** CODEX Agent  
**Дата создания:** 01.12.2025 00:24  
**Статус:** 🔴 К ИСПОЛНЕНИЮ (READ-ONLY по коду)  
**Приоритет:** 🔴 CRITICAL  

**Цель:** Найти все случаи, где статус "✅ DONE / COMPLETE / GREEN" **НЕ СООТВЕТСТВУЕТ** реальному состоянию кода или E2E тестам.

---

## 🚫 ЖЁСТКИЕ ПРАВИЛА ДЛЯ ORDER 50

### ❌ ЗАПРЕЩЕНО:

1. **Любые изменения кода:**
   - `client/src-tauri/src/**/*.rs`
   - `client/src/lib/**/*.svelte`
   - `scripts/**/*.ps1`
   - `services/**/*.py`

2. **Git-команды, меняющие состояние:**
   - `git commit`, `git checkout` (на другую ветку)
   - `git reset`, `git merge`, `git rebase`, `git push`

3. **Любые действия, которые "чинят" код:**
   - Цель ордера — **найти и задокументировать** проблемы, НЕ чинить их

### ✅ РАЗРЕШЕНО:

1. **Чтение:**
   - `git status`, `git diff --stat`, `git show` (только чтение)
   - `view_file`, `grep_search`, `find_by_name`
   - Чтение логов, конфигов

2. **Проверки (READ-ONLY):**
   - `cargo check --message-format=json` (с timeout 120s)
   - `npm run check` (с timeout 120s)  
   - `cargo test -- --list` (без запуска, только список)
   - E2E тесты **ТОЛЬКО если они не меняют production данные**

3. **Изменения документации:**
   - `task.md`
   - `PROJECT_STATUS_SNAPSHOT_*.md`
   - `*_COMPLETION_REPORT.md`
   - `ORDER_50_AUDIT_REPORT.md` (новый файл)
   - `KNOWN_FALSE_GREENS.md` (опционально)

---

## 📋 КОМАНДА 50.1 — ИНВЕНТАРИЗАЦИЯ "ЗЕЛЁНОГО"

**Приоритет:** 🔴 CRITICAL  
**ETA:** 1-2 часа  
**Цель:** Собрать единый список всех задач/ордеров, помеченных как "готово"

### Шаги:

1. **Пройти по всем документам:**
   - `task.md`
   - `PROJECT_STATUS_SNAPSHOT_v*.md` (все версии)
   - `TASK_*_COMPLETION_REPORT.md`
   - `ORDER_*_COMPLETION_REPORT.md` / `*_IMPLEMENTATION_REPORT.md`
   - `CHANGELOG_v0.2.0.md`, `CHANGELOG_v0.3.0*.md`
   - `PROJECT_HANDOVER_REPORT.md`
   - `v0.3.0_PLANNING.md` / `v0.3.0-alpha_*`

2. **Создать матрицу в `ORDER_50_AUDIT_REPORT.md`:**

   ```markdown
   ## 50.1 INVENTORY — Все "Зелёные" Задачи

   | ID | Название | task.md | PROJECT_STATUS | Completion Report | Known Issues |
   |----|----------|---------|----------------|-------------------|--------------|
   | TASK 4 | Chat Panel | ✅ | ✅ | Да | Нет |
   | TASK 16 | PULSE v1 | ✅ | ✅ | Да | Да (ambiguous idle) |
   | ORDER 37 | INDEX wrapper | ✅ | ✅ | Да | Нет |
   | ORDER 42.1 | Training Profiles UX | 🟡 | ✅ | Да | Да (rolled back) |
   ```

3. **Особое внимание:**
   - ORDER 16-17 (PULSE v1, Safe Git)
   - ORDER 22 (Flows UI)
   - ORDER 33-34 (Terminal Safety, Display Settings)
   - ORDER 35-38 (Flows Backend, Training, INDEX, Observability)
   - ORDER 39 (Release Gate v0.3.0-alpha)
   - ORDER 40 (Bugfix Pack - план)
   - ORDER 42 (Training UI)

4. **НЕ исправлять статусы** — только собрать данные

---

## 🧪 КОМАНДА 50.2 — CODE VERIFICATION (SPOT-CHECK)

**Приоритет:** 🔴 HIGH  
**ETA:** 2-3 часа  
**Цель:** Проверить ключевые "зелёные" фичи против РЕАЛЬНОГО кода

### Фокус на критических блоках:

#### 1. PULSE v1 (TASK 16, ORDER 41)

**Проверить:**
- [ ] `training_manager.rs`: структура `TrainingStatus` = ровно 6 полей
  - `status: String`
  - `epoch: f32`
  - `total_epochs: f32`
  - `loss: f32`
  - `message: String`
  - `timestamp: i64`
- [ ] `pulse_wrapper.py`: схема JSON совпадает, использует `os.replace` для атомарности
- [ ] `TrainingPanel.svelte`: вычисляет `progressPercent = epoch / total_epochs * 100` БЕЗ поля `progress` в JSON

**Если НЕ совпадает:**
- Занести в раздел "50.2 Code vs Claims" как **POTENTIAL FALSE GREEN**

---

#### 2. Safe Git v1 (TASK 17)

**Проверить:**
- [ ] `git_manager.rs`: функции `plan_git_push()` и `execute_git_push()` существуют
- [ ] Проверка remote-ahead: `git log HEAD..origin/main`
- [ ] Проверка no-upstream: блокирует если `git remote get-url origin` fails
- [ ] `GitPanel.svelte`: кнопка "Execute Push" disabled если `status != "ready"`

**Если НЕ совпадает:**
- Занести как **POTENTIAL FALSE GREEN**

---

#### 3. Flows v1 (ORDER 22, 35, 38)

**Проверить:**
- [ ] `flow_manager.rs`: реализованы команды
  - `cmd_status()`
  - `cmd_git_push()`
  - `cmd_train()`
  - `cmd_index()`
- [ ] Есть логирование в `logs/flows/*.jsonl`
- [ ] `FlowsPanel.svelte`: есть кнопка "Run Flow" и таблица истории

**Если НЕ совпадает:**
- Занести как **POTENTIAL FALSE GREEN**

---

#### 4. INDEX Wrapper (ORDER 37)

**Проверить:**
- [ ] `index_manager.rs`: использует `get_project_root()` или эквивалент
- [ ] НЕ использует `current_exe() → target/debug/...` для путей к скриптам
- [ ] Path к `services/rag_service/run_lightrag.ps1` корректный

**Если НЕ совпадает:**
- Занести как **CRITICAL FALSE GREEN** (блокирует flows)

---

#### 5. Training UI (ORDER 36, 42)

**Проверить:**
- [ ] `TrainingPanel.svelte`: есть селекторы профилей/датасетов
- [ ] Есть computed: `selectedProfile`, `selectedDataset`
- [ ] Есть валидация: `canStartTraining`
- [ ] `startTraining()` вызывает **НЕ DSL**, а Tauri команду `start_training_job`

**Если НЕ совпадает:**
- Занести как **CONFIRMED FALSE GREEN** (ORDER 42.1 уже известен как откаченный)

---

### Результат 50.2:

Таблица в `ORDER_50_AUDIT_REPORT.md`:

```markdown
## 50.2 CODE VS CLAIMS — Проверка Кода

| ORDER/TASK | Feature | Заявлено | Реальность | Статус |
|------------|---------|----------|------------|--------|
| TASK 16 | PULSE v1 6 fields | ✅ | ✅ Confirmed | PASS |
| ORDER 37 | INDEX path agnostic | ✅ | ❌ Uses current_exe() | FAIL |
| ORDER 42.1 | Training Profiles UX | ✅ | ❌ Code rolled back | FAIL |
```

---

## 🧪 КОМАНДА 50.3 — E2E VERIFICATION (RUNTIME CHECK)

**Приоритет:** 🟠 MEDIUM  
**ETA:** 2-3 часа  
**Цель:** Убедиться, что "зелёные" фичи работают в runtime

### ⚠️ ПРАВИЛА БЕЗОПАСНОСТИ:

1. **Использовать smoke-test окружение** (если есть)
2. **НЕ запускать** на production данных
3. **Timeout для каждого теста:** макс 300s (5 минут)
4. **Если блокировка > 60s** — прерывать и фиксировать как FAIL

### Тестовые сценарии:

#### 1. Flows E2E

**Запустить flows:**
- [ ] `quick_status` → expected PASS
- [ ] `smoke_test` → expected PASS
- [ ] `git_check` → expected PASS (или явная ошибка о CWD)
- [ ] `train_default` → expected PASS или валидная ошибка "no profile selected"
- [ ] `index_and_train` → expected PASS или явная ошибка пути к скрипту

**Фиксировать результаты:**
```markdown
| Flow | Expected | Actual | Issue |
|------|----------|--------|-------|
| quick_status | PASS | PASS | ✅ OK |
| git_check | PASS | FAIL | CWD wrong, goes to target/ |
| index_and_train | PASS | FAIL | Script path not found |
```

**Если FAIL:**
- Связать с ORDER (37 для INDEX, 22 для Flows общее)
- НЕ чинить — только документировать

---

#### 2. TrainingPanel Manual Start

**Действия:**
1. Открыть UI → TrainingPanel
2. Проверить:
   - Видны селекторы профилей/датасетов?
   - Кнопка "Запустить" активна/неактивна корректно?
   - При клике — запускается обучение ИЛИ валидная ошибка?

**Фиксировать:**
```markdown
| Check | Expected | Actual | Issue |
|-------|----------|--------|-------|
| Profile selector visible | Yes | No | ORDER 42.1 rolled back |
| Epochs validation | Yes | N/A | UI missing |
```

---

### Результат 50.3:

Таблица в `ORDER_50_AUDIT_REPORT.md`:

```markdown
## 50.3 E2E VERIFICATION — Runtime Тесты

| Scenario | Status | Error | Related ORDER |
|----------|--------|-------|---------------|
| quick_status flow | ✅ PASS | - | - |
| git_check flow | ❌ FAIL | Wrong CWD | ORDER 22/37 |
| index_and_train flow | ❌ FAIL | Script not found | ORDER 37 |
| TrainingPanel UI | ❌ FAIL | Missing elements | ORDER 42.1 |
```

---

## 🔍 КОМАНДА 50.4 — FIND FALSE GREENS

**Приоритет:** 🔴 CRITICAL  
**ETA:** 1 час  
**Цель:** Явно назвать ВСЕ ложные "зелёные"

### Критерии FALSE GREEN:

Статус ✅ в документах **И** одно из:
1. Код не соответствует описанию (50.2)
2. E2E стабильно FAIL (50.3)
3. Completion-report честно писал Known Issues, но task.md — безоговорочное ✅

### Шаги:

1. Проанализировать данные из 50.1-50.3
2. Создать список всех FALSE GREENS
3. Оформить в `ORDER_50_AUDIT_REPORT.md`:

```markdown
## 50.4 FALSE GREENS — Итоговый Список

### 🔴 CRITICAL False Greens (блокируют функциональность)

#### ORDER 37 — INDEX Wrapper
- **Заявлено:** ✅ COMPLETE - Path-agnostic INDEX integration
- **Реальность:** ❌ Uses `current_exe()` paths, breaks in flows
- **Доказательство:** 
  - Code: `index_manager.rs:42` hardcodes wrong path
  - E2E: `index_and_train` flow fails "script not found"
- **Next Step:** ORDER 37-FIX или ORDER 40.3

#### ORDER 42.1 — Training Profiles UX  
- **Заявлено:** ✅ COMPLETE - Enhanced training UI
- **Реальность:** ❌ Code rolled back by git checkout
- **Доказательство:**
  - Code: `grep canStartTraining TrainingPanel.svelte` → NOT FOUND
  - Runtime: UI missing profile cards, smart validation
- **Next Step:** ORDER 42-FIX

---

### 🟡 MEDIUM False Greens (работает с оговорками)

#### ORDER 22 — Flows UI
- **Заявлено:** ✅ COMPLETE - Full Flows v1 implementation
- **Реальность:** 🟡 PARTIAL - UI works, some flows fail
- **Доказательство:**
  - E2E: `git_check` and `train_default` unstable
  - Related to ORDER 37 INDEX issues
- **Next Step:** Reclassify as "COMPLETE WITH KNOWN ISSUES"

---

### 🟢 VALIDATED Greens (действительно готовы)

#### TASK 16 — PULSE v1
- **Заявлено:** ✅ COMPLETE
- **Реальность:** ✅ CONFIRMED
- **Доказательство:**
  - Code: 6-field schema matches spec
  - Runtime: Progress tracking works
- **Known Issues:** Documented (ambiguous idle), acceptable

```

---

## 🧹 КОМАНДА 50.5 — SYNC STATUSES

**Приоритет:** 🟠 MEDIUM  
**ETA:**  1 час  
**Цель:** Привести task.md и PROJECT_STATUS в честное состояние

### Шаги:

1. **Обновить `task.md`:**

   Для каждого FALSE GREEN:
   - Заменить:
     - `✅ COMPLETE` → `🟡 COMPLETE WITH KNOWN ISSUES (см. ORDER_50)`
     - ИЛИ → `🟠 PARTIAL (см. ORDER_50)`
     - ИЛИ → `❌ ROLLED BACK (см. ORDER_50)`

2. **Обновить `PROJECT_STATUS_SNAPSHOT_*.md`:**

   Добавить секцию:
   ```markdown
   ## ⚠️ FALSE GREENS AUDIT (ORDER 50)

   **Дата аудита:** 01.12.2025
   **Статус:** Обнаружено X FALSE GREENS

   - ORDER 37 — INDEX wrapper: CRITICAL (breaks flows)
   - ORDER 42.1 — Training UI: ROLLED BACK (needs reapply)
   - ORDER 22 — Flows UI: PARTIAL (some flows unstable)

   **Recovery Plans:**
   - ORDER 37 → ORDER 40 или ORDER 37-FIX
   - ORDER 42.1 → ORDER 42-FIX (уже создан)
   - ORDER 22 → Документировать Known Issues
   ```

3. **Создать `TASK_50_AUDIT_COMPLETION_REPORT.md`:**

   ```markdown
   # ORDER 50 — GLOBAL GREEN AUDIT (COMPLETION REPORT)

   **Дата:** 01.12.2025
   **Статус:** ✅ COMPLETE

   ## Summary

   - **Проверено задач:** 45
   - **Зелёных статусов:** 24
   - **FALSE GREENS обнаружено:** 3
     - 🔴 CRITICAL: 2
     - 🟡 MEDIUM: 1
   - **VALIDATED GREENS:** 21

   ## Critical False Greens

   1. ORDER 37 — INDEX wrapper
   2. ORDER 42.1 — Training Profiles UX

   ## Next Steps

   - Исполнить ORDER 37-FIX или интегрировать в ORDER 40
   - Исполнить ORDER 42-FIX
   - Обновить документацию ORDER 22

   **Full Report:** `ORDER_50_AUDIT_REPORT.md`
   ```

---

## ✅ DEFINITION OF DONE (ORDER 50)

ORDER 50 считается завершённым когда:

- ✅ Создан `ORDER_50_AUDIT_REPORT.md` со всеми разделами 50.1-50.4
- ✅ Все FALSE GREENS задокументированы с доказательствами
- ✅ `task.md` синхронизирован с реальностью
- ✅ `PROJECT_STATUS_SNAPSHOT_*.md` обновлён с секцией False Greens
- ✅ Создан `TASK_50_AUDIT_COMPLETION_REPORT.md`
- ✅ **НИ ОДНА строка кода не изменена** (READ-ONLY аудит)

---

## 🎯 ПРИОРИТЕТНЫЕ КАНДИДАТЫ НА FALSE GREEN

На основе истории проекта:

### 🔴 HIGH SUSPICION:

1. **ORDER 42.1** — Training Profiles UX
   - Подтверждено: код откачен `git checkout`
   - Документы: ✅ COMPLETE
   - **Verdict:** CONFIRMED FALSE GREEN

2. **ORDER 37** — INDEX Wrapper
   - Completion report: ✅ DONE
   - E2E (ORDER 39): `index_and_train` fails с path error
   - **Verdict:** LIKELY FALSE GREEN

3. **ORDER 22** — Flows UI
   - Completion report: ✅ DONE
   - E2E: некоторые flows нестабильны
   - **Verdict:** POSSIBLY PARTIAL, not 100% GREEN

### 🟡 MEDIUM SUSPICION:

4. **ORDER 33** — Terminal Safety Policy
   - Completion report говорит "docs only"
   - В task.md может стоять ✅ без оговорок
   - **Check:** реализован ли timeout в коде?

---

## 📝 NOTES

- Этот ордер — **диагностический**, не лечебный
- Все найденные проблемы должны порождать ОТДЕЛЬНЫЕ ордера-фиксы
- ORDER 50 **НЕ блокирует** другие ордера, но его результаты критически важны для планирования
- После ORDER 50 можно осознанно приоритизировать фиксы

**Дата создания:** 01.12.2025 00:24  
**Исполнитель:** CODEX Agent  
**Статус:** 🔜 READY TO START
