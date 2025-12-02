# 🤖 SYSTEM PROMPT INTEGRATION — CODEX MEMORY v51

**Дата:** 02.12.2025  
**Версия:** v51  
**Файл для интеграции:** Добавить в system prompt / global rules AI агента

---

## 📋 ИНСТРУКЦИЯ ДЛЯ SYSTEM PROMPT

Скопировать следующий текст в конфигурацию AI агента (system prompt / instructions):

```markdown
# PROJECT MEMORY POLICY v51

Перед началом работы над ЛЮБОЙ новой задачей (ORDER/TASK):

1. Если в репозитории существует файл docs/infra/CODEX_MEMORY_BOOTSTRAP_v51.md — 
   сначала следуй его инструкциям.

2. ОБЯЗАТЕЛЬНО читай следующие источники истины:
   - docs/project/PROJECT_INDEX_v51.json      ← структура и статусы файлов (44909 файлов)
   - PROJECT_STATUS_SNAPSHOT_v4.0.md         ← актуальный статус проекта
   - CHANGELOG.md                            ← история релизов
   - README.md                               ← точка входа
   - docs/project/LEGACY_FEATURES_REPORT_v51.md ← что признано legacy/abandoned

3. Для специфических задач используй консолидированные отчёты:
   - docs/tasks/TASKS_CONSOLIDATED_REPORT.md (Desktop Client, UI, панели)
   - docs/models/MODELS_CONSOLIDATED_REPORT.md (модели, обучение, метрики)
   - docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md (CORTEX, RAG, Security)

4. НЕЛЬЗЯ помечать ORDER/TASK как ✅ COMPLETE, пока:
   - не обновлён соответствующий *_COMPLETION_REPORT.md
   - при изменении структуры репо не обновлён PROJECT_INDEX_v51.json
   - при изменении статуса/версии не обновлён PROJECT_STATUS_SNAPSHOT_v4.0.md

5. Избегай FALSE GREENS:
   - Проверяй реальный код (cargo check, npm run check), не только документацию
   - Запускай E2E тесты (если доступны)
   - Создавай completion reports с доказательствами (скриншоты, логи)

6. Перед изменением кода проверь LEGACY_FEATURES_REPORT_v51.md:
   - Не затрагивает ли задача компоненты помеченные как LEGACY/ABANDONED?
   - Не дублируется ли работа с DEFERRED фичами?
```

---

## 🔍 АЛГОРИТМ PRE-TASK PROTOCOL (детально)

Этот алгоритм агент должен выполнять **автоматически** перед началом любой работы:

```
┌─ START NEW TASK/ORDER ─────────────────────────────────────┐
│                                                             │
│  1. READ MANDATORY FILES (в этом порядке):                 │
│     ┌──────────────────────────────────────────────────┐   │
│     │ docs/project/PROJECT_INDEX_v51.json              │   │
│     │  → Найти релевантные файлы по тегам             │   │
│     │     (training, ui, flows, rag, etc.)             │   │
│     └──────────────────────────────────────────────────┘   │
│                                                             │
│     ┌──────────────────────────────────────────────────┐   │
│     │ PROJECT_STATUS_SNAPSHOT_v4.0.md                  │   │
│     │  → Узнать текущую версию (v0.3.0-alpha)         │   │
│     │  → Проверить активные ORDERs                     │   │
│     │  → Узнать известные блокеры (ORDER 37, 43)      │   │
│     └──────────────────────────────────────────────────┘   │
│                                                             │
│     ┌──────────────────────────────────────────────────┐   │
│     │ docs/project/LEGACY_FEATURES_REPORT_v51.md       │   │
│     │  → Проверить: не помечен ли компонент LEGACY?   │   │
│     │  → Проверить: не DEFERRED ли фича?              │   │
│     └──────────────────────────────────────────────────┘   │
│                                                             │
│  2. CONTEXT-SPECIFIC READS (зависит от задачи):            │
│                                                             │
│     IF (задача про обучение):                              │
│       → docs/models/MODELS_CONSOLIDATED_REPORT.md          │
│       → docs/tasks/ORDER_42_TRACKING.md                    │
│       → docs/tasks/ORDER_43_MODEL_HF_READINESS.md          │
│                                                             │
│     IF (задача про Desktop Client UI):                     │
│       → docs/tasks/TASKS_CONSOLIDATED_REPORT.md            │
│       → UX_SPEC/ (для дизайн-гайдов)                       │
│                                                             │
│     IF (задача про Flows/Automation):                      │
│       → docs/tasks/TASKS_CONSOLIDATED_REPORT.md (ORDER 35-38) │
│       → automation/flows/*.json (примеры flow definitions) │
│                                                             │
│     IF (задача про CORTEX/RAG):                            │
│       → docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED... │
│                                                             │
│  3. VERIFY NOT BLOCKED:                                    │
│     ┌──────────────────────────────────────────────────┐   │
│     │ Проверить ORDER_37_FIX.md                        │   │
│     │  → Не затронута ли INDEX path resolution?       │   │
│     └──────────────────────────────────────────────────┘   │
│                                                             │
│     ┌──────────────────────────────────────────────────┐   │
│     │ Проверить PROJECT_STATUS blockers section       │   │
│     │  → Есть ли критичные блокеры?                   │   │
│     └──────────────────────────────────────────────────┘   │
│                                                             │
│     ┌──────────────────────────────────────────────────┐   │
│     │ Если компонент помечен DEFERRED в LEGACY report │   │
│     │  → Уточнить у пользователя                      │   │
│     └──────────────────────────────────────────────────┘   │
│                                                             │
│  4. PROCEED WITH IMPLEMENTATION                            │
│     → Когда все контексты загружены                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 ИСПОЛЬЗОВАНИЕ PROJECT_INDEX_v51.json

**Файл:** `docs/project/PROJECT_INDEX_v51.json` (15.8 MB, 44909 файлов)

### Структура записи:

```json
{
  "path": "client/src/lib/components/TrainingPanel.svelte",
  "type": "code",
  "language": "svelte",
  "size_bytes": 28450,
  "tags": ["ui", "training", "pulse_v1", "training_ui"],
  "status": "active"
}
```

### Использование тегов для поиска:

```
Задача: "Исправить TrainingPanel"
→ Поиск в INDEX: tags содержит "training_ui"
→ Результат: client/src/lib/components/TrainingPanel.svelte

Задача: "Добавить новый flow"
→ Поиск в INDEX: tags содержит "flows"
→ Результат: client/src-tauri/src/flow_manager.rs, automation/flows/*.json

Задача: "Обновить CORTEX"
→ Поиск в INDEX: tags содержит "rag"
→ Результат: services/lightrag/lightrag_server.py
```

### Использование статусов:

```
Перед изменением файла проверить status:
- "active" → OK, можно менять
- "legacy" → ⚠️ Проверить LEGACY_FEATURES_REPORT, возможно компонент заменён
- "archived" → ❌ НЕ трогать, файл в backups/
- "experimental" → ⚠️ Workbench/sandbox, не production код
```

---

## 🛡️ ПРАВИЛО "ЧЕСТНОЙ СИНХРОНИЗАЦИИ"

**Неправильный порядок (приводит к FALSE GREENS):**

```
❌ 1. Выполнить работу (код изменён)
❌ 2. Пометить ORDER как ✅ COMPLETE в трекинге
❌ 3. (забыли) создать completion report
❌ 4. (забыли) обновить PROJECT_STATUS

→ Результат: ORDER помечен ✅, но нет доказательств (как ORDER 37, 42.1)
```

**Правильный порядок:**

```
✅ 1. Выполнить работу (код, тесты, документация)
✅ 2. Создать ORDER_XX_COMPLETION_REPORT.md (детальный отчёт с доказательствами)
✅ 3. Обновить PROJECT_STATUS_SNAPSHOT_v4.0.md (статус ORDER)
✅ 4. Обновить PROJECT_INDEX_v51.json (если файлы добавлены/удалены)
✅ 5. Только ПОТОМ пометить ORDER как ✅ COMPLETE

→ Результат: ORDER завершён с полной документацией
```

### Что должно быть в COMPLETION_REPORT:

```markdown
## Evidence of Completion

### Code Verification
- ✅ cargo check: 0 errors
- ✅ npm run check: 0 errors
- ✅ E2E test scenario 1: PASSED

### Functional Testing
- [Screenshot: Feature working in UI]
- [Log: Command executed successfully]

### Files Modified
- client/src/lib/components/TrainingPanel.svelte (+150 lines)
- client/src-tauri/src/commands.rs (+50 lines)

### Integration Points
- PULSE v1: training_status.json updates confirmed
- Tauri IPC: invoke("start_training_job") tested
```

---

## 🚨 ИЗБЕГАНИЕ FALSE GREENS (критично!)

**Проблема:** ORDER 50 Global Green Audit выявил 4 FALSE GREENS:
- ORDER 37: Помечен ✅, но INDEX не работает в production
- ORDER 42.1: Помечен ✅, но код откатили

**Решение:**

### 1. Всегда проверять реальный код:

```powershell
# НЕ доверять только документации!

# Rust
cargo check  # Должен пройти без ошибок

# Node/Svelte
npm run check  # Должен пройти без ошибок

# Python
python -m py_compile <файл>  # Должен пройти

# PowerShell
Get-Command <скрипт> -Syntax  # Должен показать параметры
```

### 2. Запускать E2E тесты:

```powershell
# Для Desktop Client
pwsh client/run_auto_tests.ps1

# Для specific TASK
pwsh client/test_task4_scenarios.ps1
pwsh client/test_task5_settings.ps1
```

### 3. Создавать completion reports с доказательствами:

```markdown
## Доказательства завершения

### Скриншоты
![Training started](screenshots/training_started.png)

### Логи
```
[2025-12-02 23:00:00] Training job started: train-20251202-230000
[2025-12-02 23:00:05] PULSE status: running, epoch 1/3
```

### Тесты
- ✅ E2E scenario 1: Start training with default profile → PASSED
- ✅ E2E scenario 2: Cancel training → PASSED
```

---

## 🎯 ПРИМЕРЫ РАБОТЫ ПО НОВОМУ ПРОТОКОЛУ

### Пример 1: "Как работает Command DSL?"

```
1. Читаю PROJECT_INDEX_v51.json → ищу по тегу "commands"
   → Нахожу: client/src/lib/components/CommandsPanel.svelte

2. Читаю docs/tasks/TASKS_CONSOLIDATED_REPORT.md → нахожу TASK 8
   → Узнаю архитектуру DSL (parseCommand function, supported keywords)

3. Проверяю LEGACY_FEATURES_REPORT_v51.md → "commands" не помечен как legacy

4. Читаю client/docs/TASK_8_COMPLETION_REPORT.md для детальной справки

5. Отвечаю пользователю с указанием источников:
   "Command DSL реализован в CommandsPanel.svelte (TASK 8).
    Поддерживает INDEX, TRAIN, GIT команды.
    См. docs/tasks/TASKS_CONSOLIDATED_REPORT.md, раздел TASK 8."
```

### Пример 2: "Добавить новое поле в PULSE v1"

```
1. Читаю PROJECT_STATUS_SNAPSHOT_v4.0.md
   → Вижу: PULSE v1 FROZEN schema (6 полей)

2. Читаю docs/tasks/TASKS_CONSOLIDATED_REPORT.md → TASK 16
   → Узнаю: PULSE v2 запланирован для v0.4.0

3. Читаю LEGACY_FEATURES_REPORT_v51.md
   → Вижу: расширения схемы DEFERRED to PULSE v2

4. Отвечаю пользователю:
   "PULSE v1 schema FROZEN (6 полей). Новые поля только в PULSE v2 (v0.4.0).
    См. docs/tasks/TASK_16_COMPLETION_REPORT.md для контекста."
```

### Пример 3: "Почему INDEX не работает в Flows?"

```
1. Читаю PROJECT_STATUS_SNAPSHOT_v4.0.md
   → Вижу: ORDER 37 — INDEX path resolution (BLOCKER)

2. Читаю docs/tasks/ORDER_37_FIX.md
   → Узнаю: hardcoded paths в commands.rs, 4 uses DEFERRED

3. Читаю PROJECT_INDEX_v51.json → ищу "index_manager.rs"
   → Вижу status: "active" (не legacy)

4. Отвечаю:
   "Блокер ORDER 37. INDEX wrapper существует, но имеет
    hardcoded paths. Фикс запланирован для v0.3.1.
    См. docs/tasks/ORDER_37_FIX.md"
```

---

## 📝 CHECKLIST ДЛЯ ИНТЕГРАЦИИ

- [ ] Скопировать "PROJECT MEMORY POLICY v51" в system prompt AI агента
- [ ] Настроить агента читать PROJECT_INDEX_v51.json перед каждой задачей
- [ ] Настроить агента проверять LEGACY_FEATURES_REPORT_v51.md перед изменением кода
- [ ] Настроить агента создавать completion reports перед пометкой ✅ COMPLETE
- [ ] Настроить агента запускать cargo check / npm run check перед завершением
- [ ] Тестовая задача: попросить агента объяснить как работает PULSE v1
  - Ожидаемый результат: агент прочитает TASKS_CONSOLIDATED_REPORT.md → TASK 16
- [ ] Тестовая задача: попросить агента добавить новое поле в PULSE v1
  - Ожидаемый результат: агент откажется (FROZEN schema) и предложит PULSE v2

---

## 🎯 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ ПОСЛЕ ИНТЕГРАЦИИ

### До интеграции (проблемы):
- ❌ Агент не знает что ORDER 37 — блокер
- ❌ Агент может изменить legacy код
- ❌ Агент помечает ORDER ✅ без completion report
- ❌ Агент не проверяет реальный код (только доки)

### После интеграции (решение):
- ✅ Агент автоматически читает PROJECT_STATUS → видит блокеры
- ✅ Агент проверяет LEGACY_REPORT → избегает legacy кода
- ✅ Агент создаёт completion report → доказательства работы
- ✅ Агент запускает cargo check → проверяет реальный код

---

**Файл для справки:** `docs/infra/CODEX_MEMORY_BOOTSTRAP_v51.md`  
**Дата внедрения:** 02.12.2025  
**Статус:** ✅ Готов к интеграции в AI агента
