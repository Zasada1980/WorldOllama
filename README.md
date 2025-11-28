# 🌍 WORLD_OLLAMA

**Local-First AI Knowledge Workstation** — Desktop Client + GraphRAG + Model Training

[![Status](https://img.shields.io/badge/status-v0.2.0--rc1_Ready-yellow)]() 
[![Version](https://img.shields.io/badge/version-0.2.0--rc1-blue)]()
[![License](https://img.shields.io/badge/license-MIT-brightgreen)]()
[![Platform](https://img.shields.io/badge/platform-Windows-lightgrey)]()

**Последний релиз:** v0.1.0 (Developer Preview) — 27 ноября 2025 г.  
**Текущая версия:** v0.2.0-rc1 (Architecture Complete) — 29 ноября 2025 г.  
**GitHub:** https://github.com/Zasada1980/WorldOllama  
**Release:** https://github.com/Zasada1980/WorldOllama/releases/tag/v0.1.0

---

## 📖 Что это?

**WORLD_OLLAMA** — это комплексная система для работы с AI, которая работает **полностью локально** на вашем компьютере:

### Основные компоненты

| Компонент | Технология | Назначение |
|-----------|------------|------------|
| **Desktop Client** | Tauri (Rust + Svelte) | Графический интерфейс пользователя |
| **CORTEX** | LightRAG (GraphRAG) | База знаний с семантическим поиском |
| **Ollama** | LLM Inference Engine | Запуск локальных моделей (Qwen, LLaMA) |
| **LLaMA Factory** | Fine-tuning Framework | Обучение моделей на своих данных |
| **SYNAPSE** | Python Connector | Мост между компонентами |

### Философия проекта

✅ **Приватность:** Все данные остаются локально  
✅ **Контроль:** Полный контроль над моделями и данными  
✅ **Открытость:** Open-source, без vendor lock-in  
✅ **Интеграция:** Единый интерфейс для разных инструментов  

---

## ✨ Основные возможности v0.1.0

### 💬 Smart Chat с контекстом знаний

- **Общение с LLM** через desktop интерфейс
- **Автоматический RAG:** поиск релевантных документов из базы знаний
- **Chain-of-thought:** отображение процесса рассуждения модели
- **Источники знаний:** показ документов, на основе которых дан ответ

**Модель по умолчанию:** Qwen2.5-14B (128K context window)

### 📚 База знаний (TRIZ + AI)

**Контент v0.1.0:**
- 486+ документов по ТРИЗ (Теория Решения Изобретательских Задач)
- AI методологии и best practices
- Размер: ~7.7 MB текстовых данных

**Возможности:**
- ✅ Прединдексировано (готово к использованию)
- ✅ Семантический поиск через knowledge graph
- ✅ Управление индексацией через UI
- ✅ Автоматический мониторинг статуса

### 🎛️ Command DSL (Domain-Specific Language)

Управление системой через структурированные команды:

```
INDEX KNOWLEDGE PATH="E:\data\new_docs" MODE=hybrid PROFILE=default
TRAIN AGENT PROFILE="triz_full" DATASET="triz_td010v3" EPOCHS=3
GIT PUSH --dry-run
```

**Workflow:**
1. AI парсит команду и заполняет параметры
2. Пользователь подтверждает или редактирует
3. Система безопасно исполняет

**MVP Constraints (v0.1.0):**
- ⚠️ TRAIN AGENT: scaffold mode (безопасный просмотр параметров)
- ⚠️ GIT PUSH: dry-run only (реальный push в v0.2.0)

### 📡 System Status Monitoring

**Real-time мониторинг:**
- 🟢 Ollama (порт 11434) — статус, загруженные модели
- 🟢 CORTEX (порт 8004) — RAG сервер, response time
- 🟡 Neuro-Terminal (порт 8501) — опциональный Chainlit UI

**Auto-refresh:** каждые 15 секунд  
**Диагностика:** детальные подсказки при сбоях

### ⚙️ Settings & Agent Profiles

**Настройки:**
- Ollama endpoint и модель
- CORTEX базовый URL и API key
- Локальное хранение (AppData)

**Agent Profiles:**
- Создание профилей с custom system prompts
- Сохранение/загрузка/удаление профилей
- Интеграция с чатом (переключение контекста)

### 🔬 Training Panel (PULSE v1 Protocol)

**🚀 NEW in v0.2.0:** Мониторинг обучения в реальном времени через PULSE v1 Protocol

**Архитектура:**
```
Python (pulse_wrapper.py)
  ↓ atomic write (os.replace)
training_status.json
  ↑ poll every 2-10s (adaptive)
Rust (singleton poller)
  ↓ emit event
Tauri Event Bridge
  ↓ WebSocket
UI (TrainingPanel.svelte)
  → Reactive state updates
```

**Возможности:**
- ✅ **Real-time статус:** idle → running → done/error (автоматическое обнаружение)
- ✅ **Progress tracking:** Epoch progress bar (текущая/всего)
- ✅ **Loss monitoring:** Текущее значение loss function
- ✅ **Adaptive polling:** 2s (active) → 10s (idle) для экономии CPU
- ✅ **Atomic updates:** Python использует `os.replace()` для гарантии целостности данных

**PULSE v1 Schema:**
```json
{
  "status": "idle|running|done|error",
  "epoch": 0.0,
  "total_epochs": 0.0,
  "loss": 0.0,
  "message": "Training started",
  "timestamp": 1732800000
}
```

**Профили и датасеты:**
- **Профили:** triz_full, triz_lite, triz_smoketest
- **Датасеты:** triz_td010v3 (300 samples), triz_mini (50 samples)

**Known Limitations (PULSE v1):**
- ⚠️ **Missing file = idle:** Если `training_status.json` не существует, статус = idle (может быть неоднозначно)
- ⚠️ **Stale detection scope:** Если `timestamp` устарел, показывается warning (но не блокируется)
- ⚠️ **Polling latency:** 2-10s задержка между обновлениями

**Верификация:** См. `docs/qa/VERIFICATION_PROTOCOL_TASK16.md` для E2E тестов

### 🔐 Safe Git Assistant (Two-Phase Workflow)

**🚀 NEW in v0.2.0:** Безопасный Git Push с валидацией и предварительным просмотром

**Workflow:**
```
1. PLAN (readonly)
   - git status --porcelain
   - git branch --show-current
   - git remote get-url origin
   - git log origin/main..HEAD (outgoing commits)
   - git log HEAD..origin/main (remote ahead check)
   → GitPushPlan { status, commits, files, blocked_reasons }

2. REVIEW (UI)
   - Показать commits to be pushed
   - Показать files changed
   - Показать blocked reasons (если есть)
   - Enable/Disable кнопку "Execute Push"

3. EXECUTE (write operation)
   - RE-VALIDATE (повторная проверка)
   - IF status == "ready" → git push
   - ELSE → Error "Safety check failed"
   → GitPushResult { success, message }
```

**Safety Checks (7 блокирующих сценариев):**
1. ❌ **Unstaged changes:** Есть изменения, не добавленные в staging area
2. ❌ **Uncommitted changes:** Есть staged изменения без commit
3. ❌ **Branch mismatch:** Текущая ветка не `main`
4. ❌ **Remote not found:** Удалённый репозиторий не найден
5. ❌ **Branch not on remote:** Локальная ветка не существует на remote
6. ❌ **Remote ahead:** Remote содержит новые коммиты (требуется `git pull`)
7. ❌ **No upstream:** У ветки нет upstream-конфигурации

**ТРИЗ Principles Applied:**
- **№10 (Preliminary Action):** План создаётся ДО выполнения — предсказание проблем
- **№3 (Local Quality):** Статус учитывает локальное И удалённое состояние (global quality)
- **№13 (Inversion):** "Pending Verification" как требование, не проблема

**Known Limitations:**
- ⚠️ **Requires `git fetch`:** Проверка "Remote ahead" требует предварительного `git fetch`
- ⚠️ **No diff preview:** Нет показа содержимого изменений (только список файлов)
- ⚠️ **No API key detection:** Не проверяет наличие секретов в коде перед push

**Использование:** Перейдите на вкладку "Git Push Safety" → Click "Plan Push" → Review → "Execute Push"

---

## 🏗️ Архитектура

```
┌─────────────────────────────────────────────────────────────────┐
│                   USER INTERFACE LAYER                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │   Desktop Client (Tauri + Svelte) :8501                 │   │
│  │   - ChatPanel                                            │   │
│  │   - SystemStatusPanel                                    │   │
│  │   - SettingsPanel                                        │   │
│  │   - LibraryPanel                                         │   │
│  │   - CommandsPanel                                        │   │
│  │   - TrainingPanel                                        │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                               ↓ Tauri Commands (Rust)
┌─────────────────────────────────────────────────────────────────┐
│                    SERVICE LAYER                                │
│  ┌────────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │  Ollama        │  │  CORTEX      │  │  LLaMA Factory   │   │
│  │  :11434        │  │  :8004       │  │  (CLI/Web)       │   │
│  │                │  │              │  │                  │   │
│  │  - qwen2.5:14b │  │  - LightRAG  │  │  - Fine-tuning   │   │
│  │  - nomic-embed │  │  - GraphRAG  │  │  - LoRA adapters │   │
│  │  - triz-td010v2│  │  - Knowledge │  │  - TRIZ models   │   │
│  └────────────────┘  └──────────────┘  └──────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                               ↓ SYNAPSE Connector
┌─────────────────────────────────────────────────────────────────┐
│                    DATA LAYER                                   │
│  ┌────────────────────────────────────────────────────────┐   │
│  │  Knowledge Base                                         │   │
│  │  - Raw documents (486+ .txt файлов)                    │   │
│  │  - Graph database (entities, relations)                │   │
│  │  - Vector embeddings (768-dim)                         │   │
│  └────────────────────────────────────────────────────────┘   │
│  ┌────────────────────────────────────────────────────────┐   │
│  │  Models & Adapters                                      │   │
│  │  - Base models (Qwen2.5-1.5B, 3B, 7B, 14B)            │   │
│  │  - LoRA adapters (triz_full: 35.27 MB)                │   │
│  │  - Training datasets (TRIZ: 300 samples)               │   │
│  └────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Быстрый старт

### Системные требования

| Компонент | Минимум | Рекомендовано |
|-----------|---------|---------------|
| **OS** | Windows 10 64-bit | Windows 11 |
| **GPU** | RTX 3060 (12 GB VRAM) | RTX 5060 Ti (16 GB VRAM) |
| **RAM** | 16 GB | 32 GB |
| **Диск** | 50 GB SSD | 100 GB NVMe SSD |
| **Ollama** | v0.1.22+ | Latest |
| **Node.js** | v20+ | v22+ |
| **Rust** | 1.75+ | Latest stable |
| **Python** | 3.11+ | 3.11 |

### Установка (Developer Setup)

**1. Клонирование репозитория:**

```powershell
git clone https://github.com/Zasada1980/WorldOllama.git
cd WorldOllama
```

**2. Установка Ollama моделей:**

```powershell
ollama pull qwen2.5:14b
ollama pull nomic-embed-text
```

**3. Настройка Python сервисов:**

```powershell
# CORTEX (LightRAG)
cd services/lightrag
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt

# LLaMA Factory (опционально, для обучения)
cd ../llama_factory
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

**4. Установка Desktop Client зависимостей:**

```powershell
cd ../../client
npm install
```

### Запуск (Development Mode)

```powershell
# Terminal 1: Запуск сервисов
pwsh E:\WORLD_OLLAMA\scripts\START_ALL.ps1

# Terminal 2: Запуск Desktop Client
cd E:\WORLD_OLLAMA\client
npm run tauri dev
```

**Проверка работы:**
1. Desktop Client откроется автоматически
2. Перейдите на вкладку "System Status"
3. Проверьте статусы:
   - ✅ Ollama: Running
   - ✅ CORTEX: Running
   - 🟡 Neuro-Terminal: Down (опционально)

### Установка (End-User, v0.1.0 Release)

**1. Скачать portable exe:**

Перейдите на [GitHub Releases](https://github.com/Zasada1980/WorldOllama/releases/tag/v0.1.0) и скачайте `tauri_fresh.exe`.

**2. Установить зависимости:**

```powershell
# Установите Ollama
# https://ollama.ai/download

# Скачайте модели
ollama pull qwen2.5:14b
ollama pull nomic-embed-text
```

**3. Запустить сервисы:**

```powershell
# Скачайте репозиторий (только для скриптов)
git clone https://github.com/Zasada1980/WorldOllama.git
cd WorldOllama

# Запустите сервисы
pwsh scripts/START_ALL.ps1 -SkipNeuroTerminal
```

**4. Запустить приложение:**

Двойной клик на `tauri_fresh.exe`.

---

## 📊 Состояние проекта

### Текущий статус: v0.1.0 (Developer Preview)

**Завершённые фазы:**

```
✅ Phase 0: Orchestration Scripts (START_ALL, STOP_ALL, CHECK_STATUS)
✅ Phase 1: CORTEX Quality (Plan C Baseline)
✅ Phase 2: UX Spec (8 документов спецификаций)
✅ Phase 3: Desktop Client MVP (Tasks 4-15)
```

**Завершённые задачи (v0.1.0):**

| Task | Компонент | Статус | Отчёт |
|------|-----------|--------|-------|
| **TASK 4** | System Status Panel | ✅ DONE | `client/TASK4_REPORT.md` |
| **TASK 5** | Settings Panel | ✅ DONE | `client/TASK5_REPORT.md` |
| **TASK 6** | Library Panel (base) | ✅ DONE | `client/TASK_6_COMPLETION_REPORT.md` |
| **TASK 7** | Library Panel (full) | ✅ DONE | `client/TASK_7_COMPLETION_REPORT.md` |
| **TASK 8** | Commands Panel | ✅ DONE | `client/TASK_8_COMPLETION_REPORT.md` |
| **TASK 9** | Core Bridge | ✅ DONE | `client/docs/TASK_9_COMPLETION_REPORT.md` |
| **TASK 10** | Pre-Push Audit | ✅ DONE | `TASK_10_COMPLETION_REPORT.md` |
| **TASK 11** | Release v0.1.0 | ✅ DONE | `TASK_11_COMPLETION_REPORT.md` |
| **TASK 12** | Training Panel | ✅ DONE | `TASK_12_2_COMPLETION_REPORT.md` |
| **TASK 13** | Indexation Backend | ✅ DONE | `client/TASK_13_INDEXATION_REPORT.md` |
| **TASK 15** | Training Backend | ✅ DONE | `client/TASK_15_COMPLETION_REPORT.md` |

**Общий прогресс:**
```
Phases 0-3: ████████████████████ 100% ✅
Phase 4:     ███████████████░░░░░  75% 🔄 (v0.2.0-rc1)

OVERALL:     ███████████████████░  95%
```

### Roadmap v0.2.0 (Production Release)

**✅ Завершено (Architecture Complete):**

- ✅ **PULSE v1 Protocol (TASK 16):** Real-time training monitoring с adaptive polling
- ✅ **Safe Git Assistant (TASK 17):** Two-phase Git Push workflow с 7 safety checks
- ✅ **Consolidated Documentation:** Единые отчёты для Tasks/Models/Infrastructure

**🔄 В процессе разработки:**

- 🔜 **Compilation & Verification:** Запуск `cargo check`, E2E тестов (блокирует релиз)
- 🔜 **Windows Installers (TASK 18):** MSI/NSIS packages (WiX Toolset required)
- 🔜 **UI Improvements (TASK 19):** Темы, анимации, accessibility

**🎯 Запланировано (v0.2.x):**

- 🔜 **Performance Optimization (TASK 20):** VRAM usage monitoring, response time optimization
- 🔜 **Security Enhancements:** JWT tokens, rate limiting
- 🔜 **Monitoring Dashboard:** Prometheus + Grafana integration

**🚦 Release Status: v0.2.0-rc1 "Static Fire Readiness"**
- **Code:** 100% architecturally complete
- **Compilation:** 0% (Rust toolchain pending)
- **Testing:** 0% (E2E protocols documented)
- **Blocking:** `cargo check` + E2E Scenario 1-2

**Цель релиза:** Март 2026 г.  
**Детали:** См. `CHANGELOG_v0.2.0.md` для полного списка изменений

---

## 🤖 Модели и обучение

### Production Models

| Model | Назначение | Статус | Размер | Качество |
|-------|------------|--------|--------|----------|
| **triz-td010v2** | TRIZ Agent (Qwen2.5-1.5B) | ✅ PROD | 35.27 MB adapter | eval_loss: 0.8591 ⭐ |
| **qwen2.5:14b** | CORTEX LLM (базовая модель) | ✅ PROD | ~8 GB | MMLU: 74.8 |
| **nomic-embed-text** | CORTEX Embeddings | ✅ PROD | <1 GB | MTEB: 62.4 |

### Research Models

| Model | Назначение | Статус | Insights |
|-------|------------|--------|----------|
| **TD-010v3** (Qwen2.5-3B) | Больший TRIZ agent | 📁 ARCHIVE | `adamw_8bit` optimizer критичен |

**Подробнее:** См. `docs/models/MODELS_CONSOLIDATED_REPORT.md`

### Fine-tuning Workflow

```powershell
# 1. Подготовка датасета
llamafactory-cli export config/prepare_dataset.yaml

# 2. Обучение (LLaMA Factory)
llamafactory-cli train config/triz_td010v2.yaml

# 3. Экспорт merged model
llamafactory-cli export config/export_gguf.yaml

# 4. Интеграция в Ollama
ollama create triz-td010v2 -f Modelfile
```

**Training Time (RTX 5060 Ti 16GB):**
- Qwen2.5-1.5B (300 samples, 3 epochs): ~5 мин
- Qwen2.5-3B (300 samples, 3 epochs): ~3 мин

---

## 🏛️ Инфраструктура

### CORTEX (LightRAG) Configuration

**Текущая конфигурация (Plan C Baseline):**

```python
LLM_MODEL = "qwen2.5:14b"
EMBEDDING_MODEL = "nomic-embed-text:latest"
top_k = 20  # +100% vs baseline
enable_rerank = False  # Disabled (LightRAG bug)
host = "127.0.0.1"
port = 8004
```

**Metrics (50-query validation):**
- Precision@5: 0.184
- Recall@10: 0.268 (+16% vs baseline)
- Latency (avg): 6.7s

**Подробнее:** См. `docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md`

### Security (Secure Enclave)

**API Key Protection:**
```python
@app.middleware("http")
async def verify_api_key(request: Request, call_next):
    if request.url.path == "/health":
        return await call_next(request)
    
    api_key = request.headers.get("X-API-KEY")
    if api_key != CORTEX_API_KEY:
        return JSONResponse(status_code=401, content={"error": "Unauthorized"})
    
    return await call_next(request)
```

**Protected Endpoints:** `/`, `/query`, `/status`, `/insert`, `/batch_insert`  
**Public:** `/health` (для мониторинга)

---

## 📚 Документация

### Навигационная карта

| Документ | Назначение | Статус |
|----------|------------|--------|
| **README.md** | Главная точка входа | ✅ v3.0 (v0.2.0-rc1) |
| **MANUAL.md** | Пользовательское руководство | ✅ Актуален |
| **PROJECT_MAP.md** | Карта архитектуры проекта | ✅ Актуален |
| **CHANGELOG.md** | История изменений (все версии) | ✅ Актуален |
| **CHANGELOG_v0.2.0.md** | 🆕 Detailed v0.2.0-rc1 Release Notes | ✅ NEW |
| **INDEX.md** | Навигация по документации | ✅ Актуален |

### Консолидированные отчёты (новое!)

**Создано 28 ноября 2025 г.:**

| Отчёт | Контент | Файл |
|-------|---------|------|
| **Tasks Consolidated** | Все TASK 4-15 в одном документе | `docs/tasks/TASKS_CONSOLIDATED_REPORT.md` |
| **Models Consolidated** | TD-010v2, TD-010v3, архитектура | `docs/models/MODELS_CONSOLIDATED_REPORT.md` |
| **Infrastructure Consolidated** | CORTEX, Security, RAG metrics | `docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md` |
| **Documentation Structure** | Анализ и векторная карта связей | `docs/DOCUMENTATION_STRUCTURE_ANALYSIS.md` |

### Структура документации

```
E:\WORLD_OLLAMA\
├── README.md                    # Главный README (этот файл)
├── MANUAL.md                    # Пользовательское руководство
├── CHANGELOG.md                 # История изменений
├── PROJECT_MAP.md               # Карта проекта
├── INDEX.md                     # Навигация
│
├── docs/
│   ├── tasks/                   # Консолидированные TASK отчёты
│   │   └── TASKS_CONSOLIDATED_REPORT.md
│   ├── models/                  # Отчёты по моделям
│   │   └── MODELS_CONSOLIDATED_REPORT.md
│   ├── infrastructure/          # Инфраструктура
│   │   └── INFRASTRUCTURE_CONSOLIDATED_REPORT.md
│   └── DOCUMENTATION_STRUCTURE_ANALYSIS.md  # Анализ связей
│
└── client/
    ├── README.md                # Desktop Client документация
    └── docs/                    # Детальные TASK отчёты
```

**Полная карта:** См. `INDEX.md`

---

## 🧪 Тестирование

### Automated Tests

```powershell
# Core Bridge тесты
pwsh client/run_auto_tests.ps1

# System Status тесты (3 сценария)
pwsh client/test_task4_scenarios.ps1

# Settings тесты (5 сценариев)
pwsh client/test_task5_settings.ps1
```

### Manual Testing

**Smoke-test checklist (v0.1.0):**

1. **Chat Panel:**
   - [ ] Отправка сообщения → получен ответ
   - [ ] CORTEX RAG активирован → показаны источники
   - [ ] Chain-of-thought отображается

2. **System Status:**
   - [ ] Ollama: 🟢 Running
   - [ ] CORTEX: 🟢 Running
   - [ ] Auto-refresh работает (15s)

3. **Settings:**
   - [ ] Изменение модели → сохранено
   - [ ] Создание профиля → успех
   - [ ] Перезапуск приложения → настройки восстановлены

4. **Library:**
   - [ ] Статус индексации отображается
   - [ ] Кнопка "Start Indexation" работает

5. **Commands:**
   - [ ] Парсинг `INDEX KNOWLEDGE` → параметры заполнены
   - [ ] Подтверждение → статус "pending"

**Подробнее:** См. `TASK_11_SMOKE_TEST_REPORT.md`

---

## 🛠️ Разработка

### Сборка production версии

```powershell
# Автоматическая сборка через скрипт
pwsh scripts/BUILD_RELEASE.ps1

# Результат: client/src-tauri/target/release/tauri_fresh.exe
```

**Build Requirements:**
- Windows SDK 10.0+
- MSVC Build Tools 2022
- Rust toolchain 1.75+

### Архитектура кода

**Desktop Client (Tauri + Svelte):**
```
client/
├── src/                         # Svelte frontend
│   ├── routes/+page.svelte      # Главная страница
│   └── lib/
│       ├── components/          # UI компоненты (6 панелей)
│       ├── api/client.ts        # API client (Core Bridge)
│       └── stores/              # Svelte stores
│
└── src-tauri/                   # Rust backend
    ├── src/
    │   ├── commands.rs          # Tauri commands (indexation, training)
    │   ├── settings.rs          # Settings management
    │   └── config.rs            # Configuration
    └── Cargo.toml               # Rust dependencies
```

**Services:**
```
services/
├── lightrag/                    # CORTEX (LightRAG GraphRAG)
│   ├── lightrag_server.py       # FastAPI server
│   └── data/                    # Persistent storage
│
├── llama_factory/               # Model fine-tuning
│   ├── src/                     # LLaMA Factory source
│   └── data/                    # Datasets
│
└── connectors/synapse/          # SYNAPSE (bridge services)
    └── knowledge_client.py      # CORTEX API client
```

---

## 🔍 Troubleshooting

### Проблема: CORTEX не запускается

**Симптомы:**
```
CORTEX (LightRAG) (Port 8004): Down
```

**Решение:**
```powershell
# 1. Проверить логи
Get-Content E:\WORLD_OLLAMA\services\lightrag\logs\cortex.log -Tail 50

# 2. Проверить, что Ollama запущен
curl http://localhost:11434/api/tags

# 3. Перезапустить сервисы
pwsh scripts/STOP_ALL.ps1
pwsh scripts/START_ALL.ps1
```

### Проблема: Desktop Client не находит CORTEX

**Симптомы:**
```
Error: Failed to connect to CORTEX
```

**Решение:**
```powershell
# 1. Проверить статус CORTEX
pwsh scripts/CHECK_STATUS.ps1

# 2. Проверить настройки в Settings
# CORTEX URL должен быть: http://127.0.0.1:8004

# 3. Проверить API key
# По умолчанию: sesa-secure-core-v1
```

### Проблема: Модель не влезает в VRAM

**Симптомы:**
```
Ollama error: Out of Memory
```

**Решение:**
```powershell
# 1. Проверить доступную VRAM
nvidia-smi

# 2. Переключиться на меньшую модель
ollama pull qwen2.5:7b

# 3. Изменить модель в Settings
# Ollama Model: qwen2.5:7b
```

**Полный troubleshooting:** См. `MANUAL.md`, раздел "🔍 Troubleshooting"

---

## 📜 Лицензия

MIT License — см. файл `LICENSE`

---

## 🙏 Благодарности

**Технологии:**
- [Tauri](https://tauri.app/) — Desktop framework
- [Svelte](https://svelte.dev/) — UI framework
- [Ollama](https://ollama.ai/) — LLM inference engine
- [LightRAG](https://github.com/HKUDS/LightRAG) — GraphRAG implementation
- [LLaMA Factory](https://github.com/hiyouga/LLaMA-Factory) — Fine-tuning framework

**Модели:**
- [Qwen Team](https://qwenlm.github.io/) — Qwen2.5 models
- [Nomic AI](https://www.nomic.ai/) — nomic-embed-text

---

## 📞 Контакты

**GitHub:** https://github.com/Zasada1980/WorldOllama  
**Issues:** https://github.com/Zasada1980/WorldOllama/issues  
**Releases:** https://github.com/Zasada1980/WorldOllama/releases

---

**Дата последнего обновления:** 29 ноября 2025 г.  
**Версия документа:** 3.0 (v0.2.0-rc1 Update)  
**Статус:** ✅ АКТУАЛЕН

_Этот README полностью переработан с учетом v0.2.0-rc1 (PULSE v1 + Safe Git Assistant)._
