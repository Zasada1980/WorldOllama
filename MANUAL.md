# 📚 WORLD_OLLAMA — Руководство проекта

**Версия:** 3.3  
**Дата:** 27 ноября 2025 г.  
**Статус:** 🟢 В активной разработке

---

## 🎯 О проекте

**WORLD_OLLAMA** — унифицированная система работы с AI, объединяющая:
- **LLaMA Factory** — fine-tuning моделей
- **LightRAG** — графовая база знаний (GraphRAG)
- **Desktop Client** — Tauri приложение (Rust + Svelte)

**Цель:** Создание десктопного клиента для работы с локальными LLM и knowledge base к **10 декабря 2025 года**.

---

## 📁 Структура проекта

```
E:\WORLD_OLLAMA\
├── client/                      # Tauri Desktop Client
│   ├── src-tauri/               # Rust backend
│   │   ├── src/
│   │   │   ├── config.rs        # Конфигурация API
│   │   │   ├── commands.rs      # Tauri команды
│   │   │   ├── settings.rs      # Управление настройками
│   │   │   └── lib.rs           # Главный модуль
│   │   └── Cargo.toml           # Rust зависимости
│   ├── src/                     # Svelte frontend
│   │   ├── routes/
│   │   │   └── +page.svelte     # Главная страница (навигация)
│   │   └── lib/components/
│   │       ├── ChatPanel.svelte        # Чат интерфейс
│   │       ├── SystemStatusPanel.svelte # Мониторинг
│   │       ├── SettingsPanel.svelte    # Настройки
│   │       ├── MessageBubble.svelte    # Сообщение чата
│   │       └── SourcesList.svelte      # Источники CORTEX
│   ├── TASK4_REPORT.md          # Отчёт Task 4 (System Status)
│   ├── TASK5_REPORT.md          # Отчёт Task 5 (Settings)
│   └── test_task5_settings.ps1  # Тестовый скрипт Task 5
│
├── services/
│   ├── lightrag/                # CORTEX — LightRAG сервер
│   │   ├── lightrag_server.py   # FastAPI сервер
│   │   ├── init_index.py        # Инициализация индекса
│   │   └── data/                # Персистентное хранилище
│   ├── neuro_terminal/          # Neuro-Terminal (Chainlit UI)
│   ├── llama_factory/           # LLaMA Factory
│   └── connectors/synapse/      # SYNAPSE connector
│
├── library/
│   └── raw_documents/           # 486+ документов ТРИЗ/AI
│
├── scripts/
│   ├── start_lightrag.ps1       # Запуск CORTEX
│   ├── start_neuro_terminal.ps1 # Запуск Neuro-Terminal
│   ├── START_ALL.ps1            # Запуск всех сервисов
│   ├── STOP_ALL.ps1             # Остановка всех сервисов
│   └── CHECK_STATUS.ps1         # Проверка статуса
│
├── PROJECT_MAP.md               # Карта проекта
├── PROJECT_STATUS_SNAPSHOT_v3.3.md  # Текущий статус
└── README.md                    # Главный README
```

---

## 🚀 Быстрый старт

### 1. Проверка сервисов

```powershell
# Проверка статуса всех сервисов
pwsh E:\WORLD_OLLAMA\scripts\CHECK_STATUS.ps1

# Детальная проверка с откликами
pwsh E:\WORLD_OLLAMA\scripts\CHECK_STATUS.ps1 -Detailed
```

**Ожидаемый результат:**
- ✅ Ollama (11434): UP
- ✅ CORTEX LightRAG (8004): UP
- ⚠️ Neuro-Terminal (8501): опционально

---

### 2. Запуск сервисов

#### Автоматический запуск всех сервисов:
```powershell
pwsh E:\WORLD_OLLAMA\scripts\START_ALL.ps1
```

#### Запуск отдельных сервисов:

**Ollama** (если не запущен):
```powershell
ollama serve
```

**CORTEX (LightRAG):**
```powershell
pwsh E:\WORLD_OLLAMA\scripts\start_lightrag.ps1
```

**Neuro-Terminal (опционально):**
```powershell
pwsh E:\WORLD_OLLAMA\scripts\start_neuro_terminal.ps1
```

---

### 3. Запуск Desktop Client

```powershell
cd E:\WORLD_OLLAMA\client
npm run tauri dev
```

**Откроется окно с интерфейсом:**
- 💬 **Chat** — общение с Ollama и CORTEX
- 📡 **System Status** — мониторинг сервисов
- ⚙️ **Settings** — настройки моделей и параметров

---

## ⚙️ Конфигурация

### Настройки Desktop Client

**Файл:** `%APPDATA%\tauri_fresh\settings.json`

```json
{
  "ollama_model": "qwen2.5:14b-instruct-q4_k_m",
  "max_tokens": null,
  "cortex_top_k": 20,
  "cortex_mode": "local",
  "active_agent_profile": "triz_engineer"
}
```

**Доступные модели:**
- `qwen2.5:14b-instruct-q4_k_m` (default)
- `qwen2.5:3b-instruct`
- `triz-td010v2:latest`
- `llama3.1:8b`
- `librarian-lite`

**Режимы CORTEX:**
- `local` — быстрый локальный поиск
- `hybrid` — адаптивный гибридный поиск

**Профили агента:**
- `triz_engineer` — ТРИЗ-инженер
- `doc_organizer` — Документалист
- `code_assistant` — Code Assistant

---

### Конфигурация CORTEX (LightRAG)

**Файл:** `services/lightrag/lightrag_server.py`

```python
WORKING_DIR = "E:\\WORLD_OLLAMA\\services\\lightrag\\data"
LIBRARY_PATH = "E:\\WORLD_OLLAMA\\library\\raw_documents"
OLLAMA_BASE_URL = "http://127.0.0.1:11434"
MODEL = "qwen2.5:14b-instruct-q4_k_m"
EMBEDDING_MODEL = "nomic-embed-text"
```

**Индексация документов:**
```powershell
cd E:\WORLD_OLLAMA\services\lightrag
python init_index.py
```

---

## 📊 Состояние проекта

### Завершённые задачи (100%):

- ✅ **Task 1:** Инициализация Tauri проекта
- ✅ **Task 2:** Core Bridge (3 Tauri команды)
  - `get_system_status` — проверка Ollama и CORTEX
  - `send_ollama_chat` — запросы к LLM
  - `send_cortex_query` — запросы к knowledge base
- ✅ **Task 3:** Chat UI
  - `ChatPanel.svelte` — основной интерфейс чата
  - `MessageBubble.svelte` — отображение сообщений
  - `SourcesList.svelte` — источники из CORTEX
- ✅ **Task 4:** System Status UI
  - `SystemStatusPanel.svelte` — мониторинг с auto-refresh
  - Индикаторы статуса (UP/DOWN/UNKNOWN)
- ✅ **Task 5:** Settings + Agent Profiles
  - `SettingsPanel.svelte` — UI настроек
  - `settings.rs` — Rust backend для персистентности
  - Интеграция с Core Bridge

### В разработке:

- ⏳ **Task 6:** Indexation UI (планируется)
- ⏳ **Task 7:** Advanced Agent Profiles (планируется)

---

## 🔧 Разработка

### Требования

**Rust:**
```powershell
rustc --version  # 1.70+
cargo --version
```

**Node.js:**
```powershell
node --version   # 18+
npm --version
```

**Python:**
```powershell
python --version # 3.10+
```

**Ollama:**
```powershell
ollama --version # 0.1.0+
```

---

### Сборка проекта

**Desktop Client (Development):**
```powershell
cd E:\WORLD_OLLAMA\client
npm install
npm run tauri dev
```

**Desktop Client (Production build):**
```powershell
cd E:\WORLD_OLLAMA\client
npm run tauri build
```

**Проверка Rust кода:**
```powershell
cd E:\WORLD_OLLAMA\client\src-tauri
cargo check
cargo test
```

---

### Архитектура Desktop Client

```
┌─────────────────────────────────────────────┐
│  Frontend (Svelte + TypeScript)             │
│  ┌─────────────┐  ┌─────────────┐          │
│  │ ChatPanel   │  │ StatusPanel │          │
│  └──────┬──────┘  └──────┬──────┘          │
│         │                │                  │
│         └────────┬───────┘                  │
│              invoke()                       │
└──────────────────┼──────────────────────────┘
                   │ Tauri IPC
┌──────────────────▼──────────────────────────┐
│  Backend (Rust)                             │
│  ┌────────────────────────────────────────┐ │
│  │ commands.rs                            │ │
│  │  • send_ollama_chat()                  │ │
│  │  • send_cortex_query()                 │ │
│  │  • get_system_status()                 │ │
│  │  • get_app_settings()                  │ │
│  │  • save_app_settings()                 │ │
│  └────────────────────────────────────────┘ │
└──────────────────┬──────────────────────────┘
                   │ HTTP
┌──────────────────▼──────────────────────────┐
│  External Services                          │
│  ┌──────────────┐  ┌──────────────────────┐ │
│  │ Ollama       │  │ CORTEX (LightRAG)    │ │
│  │ :11434       │  │ :8004                │ │
│  └──────────────┘  └──────────────────────┘ │
└─────────────────────────────────────────────┘
```

---

## 🧪 Тестирование

### Task 5 (Settings) — Тестовый сценарий

```powershell
pwsh E:\WORLD_OLLAMA\client\test_task5_settings.ps1
```

**Проверяет:**
1. Создание файла настроек
2. Работу сервисов (Ollama + CORTEX)
3. UI интеграцию (5 сценариев)

### Task 4 (System Status) — Тестовый сценарий

```powershell
pwsh E:\WORLD_OLLAMA\client\test_task4_scenarios.ps1
```

**Проверяет:**
1. Оба сервиса UP
2. CORTEX DOWN
3. Оба сервиса DOWN

---

## 📖 Документация

### Основные документы:

| Файл | Описание |
|------|----------|
| `README.md` | Главный README проекта |
| `PROJECT_MAP.md` | Карта проекта (архитектура) |
| `PROJECT_STATUS_SNAPSHOT_v3.3.md` | Текущий статус разработки |
| `client/README_CLIENT.md` | Документация Desktop Client |
| `client/TASK4_REPORT.md` | Отчёт о System Status UI |
| `client/TASK5_REPORT.md` | Отчёт о Settings + Profiles |

### UX Спецификация (Phase 2):

```
UX_SPEC/
├── 01_DESKTOP_CLIENT_OVERVIEW.md
├── 02_CHAT_INTERFACE_SPEC.md
├── 03_SYSTEM_STATUS_SPEC.md
├── 04_SETTINGS_SPEC.md
└── 05_INDEXATION_SPEC.md
```

---

## 🔍 Troubleshooting

### Ollama не запускается

```powershell
# Проверка процесса
Get-Process ollama -ErrorAction SilentlyContinue

# Запуск вручную
ollama serve
```

### CORTEX не отвечает

```powershell
# Проверка порта
netstat -ano | Select-String ":8004"

# Перезапуск
pwsh E:\WORLD_OLLAMA\scripts\start_lightrag.ps1
```

### Desktop Client ошибки компиляции

```powershell
# Очистка кеша Rust
cd E:\WORLD_OLLAMA\client\src-tauri
cargo clean

# Очистка кеша npm
cd E:\WORLD_OLLAMA\client
Remove-Item -Recurse -Force node_modules
npm install
```

### VRAM проблемы (GPU)

```powershell
# Проверка использования GPU
nvidia-smi

# Если VRAM < 6GB → модели не загружены
# Перезапустите CORTEX
```

---

## 🛠️ Полезные команды

### Остановка всех сервисов

```powershell
pwsh E:\WORLD_OLLAMA\scripts\STOP_ALL.ps1
```

### Мониторинг логов

**CORTEX:**
```powershell
Get-Content E:\WORLD_OLLAMA\services\lightrag\logs\cortex.log -Tail 50 -Wait
```

**Neuro-Terminal:**
```powershell
Get-Content E:\WORLD_OLLAMA\services\neuro_terminal\.chainlit\chat_files\*.json
```

### Проверка индексированных документов

```powershell
$status = Get-Content E:\WORLD_OLLAMA\services\lightrag\data\kv_store_doc_status.json | ConvertFrom-Json
$status.PSObject.Properties.Name.Count
```

---

## 📅 Roadmap

**До 10 декабря 2025:**
- [x] Task 1-5: Базовый функционал Desktop Client
- [ ] Task 6: Indexation UI
- [ ] Task 7: Advanced Agent Profiles
- [ ] Final testing & bug fixes
- [ ] Production build

---

## 👤 Автор

**Zasada1980**  
GitHub: https://github.com/Zasada1980/WorldOllama

---

## 📄 Лицензия

Этот проект создан для личного использования.

---

**Последнее обновление:** 27 ноября 2025 г.  
**Версия документа:** 1.0
