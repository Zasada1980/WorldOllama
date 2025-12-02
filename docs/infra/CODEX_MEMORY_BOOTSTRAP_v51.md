# 🧠 CODEX MEMORY BOOTSTRAP v51

**Версия:** v51  
**Дата:** 02.12.2025  
**Цель:** Определить "источники истины" и алгоритм работы агента перед началом любой задачи

---

## 📚 ИСТОЧНИКИ ИСТИНЫ (SOURCES OF TRUTH)

Эти файлы являются **КАНОНИЧЕСКИМИ** источниками информации о проекте:

### 1️⃣ Структура и Индексы

| Файл | Назначение | Когда читать |
|------|------------|--------------|
| **`docs/project/PROJECT_INDEX_v51.json`** | Полная карта проекта (44909 файлов с тегами/статусами) | ВСЕГДА перед началом нового ORDER/TASK |
| **`DOCUMENTATION_INDEX.md`** | Навигация по документации (68 markdown файлов) | При поиске документации |
| **`PROJECT_MAP.md`** | Архитектура системы (компоненты, сервисы) | При изменении архитектуры |

### 2️⃣ Статус и Прогресс

| Файл | Назначение | Когда читать |
|------|------------|--------------|
| **`PROJECT_STATUS_SNAPSHOT_v4.0.md`** | Текущий статус проекта (v0.3.0-alpha) | ВСЕГДА перед началом работы |
| **`CHANGELOG.md`** | История релизов (v0.1.0 → v0.3.0-alpha) | При подготовке релиза или исследовании истории |
| **`README.md`** | Точка входа (Quick Start, требования) | При первом знакомстве с проектом |

### 3️⃣ Консолидированные Отчёты (PRIMARY SOURCES)

| Файл | Охват | Когда читать |
|------|-------|--------------|
| **`docs/tasks/TASKS_CONSOLIDATED_REPORT.md`** | TASK 4-16, ORDER 33-34, ORDER 42 (Desktop Client) | При работе с UI/UX, панелями, Flows |
| **`docs/models/MODELS_CONSOLIDATED_REPORT.md`** | TD-010v2/v3, VRAM calc, training metrics | При работе с моделями, обучением |
| **`docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md`** | CORTEX, Security, RAG, Orchestration | При работе с CORTEX, LightRAG, API Keys |

### 4️⃣ Active Tracking (Текущие ORDERs)

| Файл | Статус | Когда читать |
|------|--------|--------------|
| **`docs/tasks/ORDER_42_TRACKING.md`** | 🔄 IN PROGRESS | При работе с Training UI/profiles |
| **`docs/tasks/ORDER_37_FIX.md`** | 🔴 BLOCKER | При работе с INDEX path resolution |
| **`docs/tasks/ORDER_43_MODEL_HF_READINESS.md`** | 📋 PLANNED | При работе с HuggingFace моделями |

### 5️⃣ Legacy Awareness

| Файл | Назначение | Когда читать |
|------|------------|--------------|
| **`docs/project/LEGACY_FEATURES_REPORT_v51.md`** | Что помечено как LEGACY/ABANDONED/DEFERRED | ВСЕГДА перед изменением кода (проверить не legacy ли компонент) |

---

## 🤖 АЛГОРИТМ РАБОТЫ АГЕНТА (PRE-TASK PROTOCOL)

### ⚡ Перед ЛЮБОЙ новой задачей (ORDER/TASK/bugfix):

```plaintext
1. READ MANDATORY FILES:
   ├─ docs/project/PROJECT_INDEX_v51.json
   │  └─ Найти релевантные файлы по тегам (training, ui, flows, etc.)
   │
   ├─ PROJECT_STATUS_SNAPSHOT_v4.0.md
   │  └─ Узнать текущую версию (v0.3.0-alpha), активные ORDERs
   │
   └─ docs/project/LEGACY_FEATURES_REPORT_v51.md
      └─ Проверить: не помечен ли затрагиваемый компонент как LEGACY?

2. CONTEXT-SPECIFIC READS (зависит от задачи):
   ├─ Если задача про обучение моделей:
   │  ├─ docs/models/MODELS_CONSOLIDATED_REPORT.md
   │  ├─ docs/tasks/ORDER_42_TRACKING.md
   │  └─ docs/tasks/ORDER_43_MODEL_HF_READINESS.md
   │
   ├─ Если задача про Desktop Client UI:
   │  ├─ docs/tasks/TASKS_CONSOLIDATED_REPORT.md
   │  └─ UX_SPEC/ (для дизайн-гайдов)
   │
   ├─ Если задача про Flows/Automation:
   │  ├─ docs/tasks/TASKS_CONSOLIDATED_REPORT.md (ORDER 35-38)
   │  └─ automation/flows/*.json (примеры flow definitions)
   │
   └─ Если задача про CORTEX/RAG:
      └─ docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md

3. VERIFY NOT BLOCKED:
   ├─ Проверить ORDER_37_FIX.md — не затронута ли INDEX path resolution?
   ├─ Проверить PROJECT_STATUS blockers section
   └─ Если компонент помечен DEFERRED в LEGACY report → уточнить у пользователя

4. PROCEED WITH IMPLEMENTATION
   └─ Когда все контексты загружены
```

---

## 🔒 ПРАВИЛО ЧЕСТНОЙ СИНХРОНИЗАЦИИ

**НЕЛЬЗЯ** помечать ORDER/TASK как ✅ COMPLETE, пока:

1. ❌ Не обновлён соответствующий `*_COMPLETION_REPORT.md`
2. ❌ Не обновлён `PROJECT_STATUS_SNAPSHOT_v4.0.md` (если значимое изменение)
3. ❌ Не обновлён `PROJECT_INDEX_v51.json` (если изменилась структура файлов)
4. ❌ Не обновлён `CHANGELOG.md` (если релизный ORDER)

**ВСЕГДА** создавать completion report **ДО** пометки ✅ COMPLETE:

```plaintext
Правильный порядок:
1. Выполнить работу (код, тесты, документация)
2. Создать ORDER_XX_COMPLETION_REPORT.md (детальный отчёт)
3. Обновить PROJECT_STATUS_SNAPSHOT_v4.0.md (статус ORDER)
4. Обновить PROJECT_INDEX_v51.json (если файлы изменились)
5. Только ПОТОМ пометить ORDER как ✅ COMPLETE
```

---

## 📋 ПРАВИЛО ИЗБЕГАНИЯ "FALSE GREENS"

**Проблема:** ORDER 50 Global Green Audit выявил 4 FALSE GREENS (ORDER 37, ORDER 42.1) — задачи помечены ✅, но код не работает.

**Решение:**

### 🔍 Перед пометкой COMPLETE:

1. **Проверить фактическое состояние кода:**
   ```powershell
   # Не доверять только документации!
   # Проверить реальный код:
   
   # Rust
   cargo check
   
   # Node/Svelte
   npm run check
   
   # Python
   python -m py_compile <файл>
   
   # PowerShell
   Get-Command <скрипт> -Syntax
   ```

2. **Запустить E2E тест** (если доступен):
   ```powershell
   # Для Desktop Client
   pwsh client/run_auto_tests.ps1
   
   # Для specific TASK
   pwsh client/test_task4_scenarios.ps1
   pwsh client/test_task5_settings.ps1
   ```

3. **Проверить Terminal Safety compliance** (если ORDER затрагивает команды):
   ```powershell
   # Убедиться что скрипт имеет:
   # - timeout_sec параметр
   # - логирование
   # - error handling
   ```

4. **Создать completion report с доказательствами:**
   ```markdown
   ## Evidence of Completion
   
   ### Code Verification
   - ✅ cargo check: 0 errors
   - ✅ npm run check: 0 errors
   
   ### Functional Testing
   - ✅ E2E test scenario 1: PASSED
   - ✅ E2E test scenario 2: PASSED
   
   ### Screenshots/Logs
   - [Screenshot: Feature working in UI]
   - [Log: Command executed successfully]
   ```

---

## 🗂️ ВЕКТОРНАЯ НАВИГАЦИЯ (DOCUMENTATION GRAPH)

**Источник:** `docs/DOCUMENTATION_STRUCTURE_ANALYSIS.md`

### 6 тематических кластеров:

| Кластер | Главный файл | Связанные файлы |
|---------|--------------|-----------------|
| **Архитектура** | `PROJECT_MAP.md` | `README.md`, `MANUAL.md`, `CHANGELOG.md` |
| **Статус/Прогресс** | `PROJECT_STATUS_SNAPSHOT_v4.0.md` | `DOCUMENTATION_INDEX.md`, `LOGS_INVENTORY_v51.md` |
| **Desktop Client** | `docs/tasks/TASKS_CONSOLIDATED_REPORT.md` | TASK 4-16 completion reports |
| **Модели** | `docs/models/MODELS_CONSOLIDATED_REPORT.md` | TD-010v2/v3 deployment reports |
| **Инфраструктура** | `docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md` | CORTEX, Security, RAG, Orchestration |
| **UX Specs** | `UX_SPEC/01_OVERVIEW.md` | 8 UX specification files |

**Правило:** При работе с документом → проверить его кластер → загрузить связанные файлы для полного контекста

---

## 🎯 ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ

### Пример 1: "Как работает Command DSL?"

```plaintext
1. Читаю PROJECT_INDEX_v51.json → ищу по тегу "commands"
   → Нахожу: client/src/lib/components/CommandsPanel.svelte
   
2. Читаю docs/tasks/TASKS_CONSOLIDATED_REPORT.md → нахожу TASK 8
   → Узнаю архитектуру DSL (parseCommand function, supported keywords)
   
3. Проверяю LEGACY_FEATURES_REPORT_v51.md → "commands" не помечен как legacy
   
4. Читаю client/docs/TASK_8_COMPLETION_REPORT.md для детальной справки
   
5. Отвечаю пользователю с указанием источников
```

### Пример 2: "Добавить новое поле в PULSE v1"

```plaintext
1. Читаю PROJECT_STATUS_SNAPSHOT_v4.0.md
   → Вижу: PULSE v1 FROZEN schema (6 полей)
   
2. Читаю docs/tasks/TASKS_CONSOLIDATED_REPORT.md → TASK 16
   → Узнаю: PULSE v2 запланирован для v0.4.0
   
3. Читаю LEGACY_FEATURES_REPORT_v51.md
   → Вижу: расширения схемы DEFERRED to PULSE v2
   
4. Отвечаю пользователю:
   "PULSE v1 schema FROZEN. Новые поля только в PULSE v2 (v0.4.0).
    См. docs/tasks/TASK_16_COMPLETION_REPORT.md для контекста."
```

### Пример 3: "Почему INDEX не работает в Flows?"

```plaintext
1. Читаю PROJECT_STATUS_SNAPSHOT_v4.0.md
   → Вижу: ORDER 37 — INDEX path resolution (BLOCKER)
   
2. Читаю docs/tasks/ORDER_37_FIX.md
   → Узнаю: hardcoded paths в commands.rs, 4 uses DEFERRED
   
3. Читаю PROJECT_INDEX_v51.json → ищу "index_manager.rs"
   → Вижу status: "active" (не legacy)
   
4. Отвечаю: "Блокер ORDER 37. INDEX wrapper существует, но имеет
    hardcoded paths. Фикс запланирован для v0.3.1."
```

---

## 🛡️ TERMINAL SAFETY INTEGRATION

**Документация:** `docs/infra/TERMINAL_SAFETY_IMPLEMENTATION_GUIDE.md`

### При работе с командами через терминал:

```plaintext
ВСЕГДА использовать:
1. timeout_sec параметр (default: 300s для Rust, 60s для быстрых команд)
2. Логирование в logs/<subsystem>/
3. Error handling (try/catch, $LASTEXITCODE проверки)

НЕ ДОПУСКАТЬ:
- Бесконечных retry loops
- Команд без timeout
- Молчаливых ошибок (silent failures)
```

**Проверка перед запуском скрипта:**

```powershell
# ✅ GOOD (Terminal Safety compliant)
$job = Start-Job -ScriptBlock { cargo check 2>&1 }
Wait-Job $job -Timeout 600 | Out-Null
if ($job.State -eq 'Running') { Stop-Job $job }

# ❌ BAD (no timeout, может зависнуть)
cargo check
```

---

## 📝 ИНСТРУКЦИЯ ДЛЯ SYSTEM PROMPT

**Добавить в system prompt AI агента:**

```markdown
# CODEX Memory Bootstrap Protocol

Перед началом работы над ЛЮБОЙ новой задачей (ORDER/TASK/bugfix):

1. ОБЯЗАТЕЛЬНО прочитать:
   - docs/project/PROJECT_INDEX_v51.json (структура проекта)
   - PROJECT_STATUS_SNAPSHOT_v4.0.md (текущий статус)
   - docs/project/LEGACY_FEATURES_REPORT_v51.md (что legacy/abandoned)

2. Использовать как источники истины:
   - PROJECT_STATUS_SNAPSHOT_v4.0.md (НЕ старые snapshots v3.x)
   - PROJECT_INDEX_v51.json (НЕ устаревшие INDEX.md)
   - CHANGELOG.md (история релизов)
   - README.md (точка входа)

3. Для специфических задач читать консолидированные отчёты:
   - docs/tasks/TASKS_CONSOLIDATED_REPORT.md (Desktop Client)
   - docs/models/MODELS_CONSOLIDATED_REPORT.md (Модели)
   - docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md (CORTEX/RAG)

4. Перед пометкой ORDER как ✅ COMPLETE:
   - Создать *_COMPLETION_REPORT.md с доказательствами
   - Обновить PROJECT_STATUS_SNAPSHOT_v4.0.md
   - Обновить PROJECT_INDEX_v51.json (если структура изменилась)

5. Избегать FALSE GREENS:
   - Проверять реальный код (cargo check, npm run check)
   - Запускать E2E тесты (если доступны)
   - Не доверять только документации
```

---

## 🎯 DEFINITION OF DONE

ORDER 51.8 считается завершённым, когда:

- ✅ Этот файл (`docs/infra/CODEX_MEMORY_BOOTSTRAP_v51.md`) создан
- ✅ Определены 15 источников истины
- ✅ Описан алгоритм pre-task protocol
- ✅ Определены правила синхронизации (completion reports, PROJECT_STATUS, INDEX)
- ✅ Описаны правила избегания FALSE GREENS
- ✅ Добавлена инструкция для system prompt

**Статус ORDER 51.8:** ✅ COMPLETE  
**Next:** Финализация ORDER 51 → commit изменений
