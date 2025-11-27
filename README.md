# 🌍 WORLD_OLLAMA

**Local-First AI Workstation** — Desktop приложение для работы с знаниями через LLM

[![Status](https://img.shields.io/badge/status-MVP_Complete-green)]() 
[![Version](https://img.shields.io/badge/version-0.1.0-blue)]()
[![License](https://img.shields.io/badge/license-MIT-brightgreen)]()

**Текущая версия:** v0.1.0 (Developer Preview)

---

## 📖 Что это?

**WORLD_OLLAMA** — это десктопное приложение (Tauri + Svelte), которое объединяет:
- **Ollama** — локальные LLM модели (Qwen2.5, LLaMA и др.)
- **CORTEX (LightRAG)** — knowledge graph для поиска по документам
- **LLaMA Factory** — fine-tuning моделей на своих данных
- **Command DSL** — управление системой через естественный язык

**Философия:** Все работает локально, без облака. Ваши данные остаются у вас.

---

## ✨ Основные возможности

### 💬 Умный чат с контекстом
- Общение с LLM через десктопное приложение
- Автоматический поиск релевантных документов (CORTEX/LightRAG)
- Поддержка chain-of-thought рассуждений

### 🔧 Командная система (DSL)
ИИ предлагает команды → пользователь подтверждает → система исполняет:
- **INDEX KNOWLEDGE** — индексация новых документов
- **TRAIN AGENT** — запуск обучения модели на своих данных
- **GIT PUSH** — dry-run проверка изменений (безопасный режим)

### 📚 База знаний
- 486+ документов по ТРИЗ и AI методологиям
- Автоматическая индексация и поиск
- Knowledge graph для связи концепций

### 📡 Мониторинг системы
- Статус Ollama, CORTEX, LightRAG в реальном времени
- VRAM и CPU мониторинг
- Индикаторы здоровья сервисов

---

## 🚀 Быстрый старт

### Требования

- **Windows 10/11** (для Tauri)
- **Ollama** ([установка](https://ollama.ai/download))
- **Node.js 20+** ([установка](https://nodejs.org/))
- **Rust** ([установка](https://rustup.rs/))
- **Python 3.11+** (для сервисов)

### Установка

```powershell
# 1. Клонировать репозиторий
git clone https://github.com/Zasada1980/WorldOllama.git
cd WorldOllama

# 2. Установить зависимости Desktop Client
cd client
npm install

# 3. Установить Python окружения для сервисов
cd ../services/lightrag
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt

cd ../llama_factory
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### Запуск

```powershell
# Вариант 1: Запуск через скрипты (рекомендуется)

# 1. Запустить сервисы (Ollama, CORTEX)
pwsh scripts/START_ALL.ps1

# 2. Запустить Desktop Client
cd client
npm run tauri dev

# Вариант 2: Запуск вручную (для разработки)

# Терминал 1: Ollama (если не запущен как сервис)
ollama serve

# Терминал 2: CORTEX (LightRAG)
cd services/lightrag
.\venv\Scripts\Activate.ps1
python lightrag_server.py

# Терминал 3: Desktop Client
cd client
npm run tauri dev
```

**Desktop Client откроется автоматически** на порту 1420 (Tauri default).

---

## 🏗️ Архитектура

```
┌─────────────────────────────────────────────────────┐
│         Desktop Client (Tauri + Svelte)             │
│  ┌─────────┬─────────┬──────────┬─────────────┐    │
│  │  Chat   │ System  │ Settings │  Commands   │    │
│  │         │ Status  │          │  (DSL)      │    │
│  └─────────┴─────────┴──────────┴─────────────┘    │
│              ↕ Tauri IPC (Rust Backend)             │
└─────────────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│                   Backend Services                   │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────┐  │
│  │   Ollama    │  │   CORTEX    │  │   LLaMA    │  │
│  │  (LLM API)  │  │ (LightRAG)  │  │  Factory   │  │
│  │  :11434     │  │    :8004    │  │  :7860     │  │
│  └─────────────┘  └─────────────┘  └────────────┘  │
└─────────────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│              Data & Knowledge                        │
│  • library/raw_documents (TRIZ knowledge base)      │
│  • services/lightrag/data (indexed graphs)          │
│  • models/ (fine-tuned LoRA adapters)               │
└─────────────────────────────────────────────────────┘
```

### Компоненты

#### Desktop Client (`client/`)
- **Фронтенд:** Svelte 5 + TypeScript + Vite
- **Backend:** Rust (Tauri) — нативное приложение
- **Основные вкладки:**
  - 💬 **Chat** — общение с LLM
  - 📡 **System Status** — мониторинг сервисов
  - ⚙️ **Settings** — настройки моделей и параметров
  - 📚 **Library** — управление базой знаний
  - 🔧 **Commands** — командная консоль (DSL)

#### Backend Services (`services/`)

**CORTEX (LightRAG)** — knowledge graph сервер
- Индексация документов из `library/raw_documents`
- Поиск по knowledge graph (local/global/hybrid)
- FastAPI REST API (порт 8004)

**LLaMA Factory** — fine-tuning платформа
- Обучение моделей на своих данных (LoRA/QLoRA)
- Gradio UI для управления обучением (порт 7860)
- Интеграция с Ollama для экспорта моделей

**Neuro-Terminal** — legacy Chainlit UI (опционально)
- Альтернативный веб-интерфейс (порт 8501)
- Сохранён для совместимости

#### Библиотека знаний (`library/`)
- `raw_documents/` — 486 текстовых файлов (ТРИЗ принципы, AI методологии)
- `cleaned_documents/` — обработанные версии
- Автоматическая индексация в CORTEX

---

## 🎮 Использование

### 1. Чат с контекстом

**Открыть вкладку Chat → ввести вопрос:**

```
Какие принципы ТРИЗ помогут решить проблему
герметизации космического аппарата?
```

**Система:**
1. Отправляет запрос в CORTEX → поиск релевантных документов
2. Передаёт найденные фрагменты + вопрос в Ollama LLM
3. Возвращает ответ с указанием источников

### 2. Командная система (DSL)

**Вкладка Chat → ИИ предлагает команду:**

```
Хочу проиндексировать новые документы в library/raw_documents
```

**ИИ предлагает:**
```
INDEX KNOWLEDGE
PATH: E:\WORLD_OLLAMA\library\raw_documents
MODE: hybrid
PROFILE: default
```

**Пользователь:**
- Нажимает **"Execute INDEX KNOWLEDGE"** в вкладке Commands
- Система запускает индексацию в фоне
- Статус отображается в Library

**Доступные команды:**

| Команда | Описание | Статус |
|---------|----------|--------|
| `INDEX KNOWLEDGE` | Индексация документов в CORTEX | ✅ Работает |
| `TRAIN AGENT` | Запуск обучения модели (MVP stub) | 🟡 Безопасный режим |
| `GIT PUSH` | Dry-run проверка изменений | 🟡 Dry-run only |

### 3. Управление базой знаний

**Вкладка Library:**
- Просмотр статуса индексации
- Управление документами
- Запуск индексации вручную

**Добавление новых документов:**
```powershell
# 1. Скопировать файлы в library/raw_documents
Copy-Item C:\MyDocuments\*.txt E:\WORLD_OLLAMA\library\raw_documents\

# 2. В Desktop Client → Library → Start Indexation
# или через команду INDEX KNOWLEDGE
```

### 4. Fine-tuning моделей

**Вариант 1: Через команду TRAIN AGENT (MVP)**
```
TRAIN AGENT
PROFILE: default
DATA_PATH: E:\WORLD_OLLAMA\library\raw_documents
EPOCHS: 3
MODE: llama_factory
```

**Вариант 2: Через LLaMA Board UI**
```powershell
pwsh scripts/start_training_ui.ps1
# Откроется http://localhost:7860
```

---

## 📝 Документация

### Основная документация
- [`PROJECT_MAP.md`](PROJECT_MAP.md) — архитектурная карта проекта
- [`PROJECT_STATUS_SNAPSHOT_v3.3.md`](PROJECT_STATUS_SNAPSHOT_v3.3.md) — текущий статус
- [`MANUAL.md`](MANUAL.md) — руководство пользователя
- [`CHANGELOG.md`](CHANGELOG.md) — история изменений и релизы

### Документация по задачам (client/docs/)
- [`TASK_9_COMPLETION_REPORT.md`](client/docs/TASK_9_COMPLETION_REPORT.md) — отчёт о Task 9 (реальные команды)
- [`TASK_9_TESTING_GUIDE.md`](client/docs/TASK_9_TESTING_GUIDE.md) — тестирование команд
- Старые отчёты: TASK_4, TASK_5, TASK_6, TASK_7, TASK_8

### Для разработчиков
- [`client/README_CLIENT.md`](client/README_CLIENT.md) — разработка Desktop Client
- [`services/lightrag/README.md`](services/lightrag/README.md) — CORTEX API
- [`services/llama_factory/README.md`](services/llama_factory/README.md) — LLaMA Factory

---

## 🛠️ Разработка

### Структура проекта

```
WORLD_OLLAMA/
├── client/               # Desktop Client (Tauri + Svelte)
│   ├── src/             # Svelte компоненты
│   ├── src-tauri/       # Rust backend
│   │   ├── src/
│   │   │   ├── commands.rs      # Tauri commands API
│   │   │   ├── command_parser.rs # DSL parser
│   │   │   └── main.rs
│   │   └── Cargo.toml
│   ├── docs/            # Документация по задачам
│   └── package.json
├── services/            # Backend сервисы
│   ├── lightrag/        # CORTEX (LightRAG)
│   ├── llama_factory/   # Fine-tuning платформа
│   ├── neuro_terminal/  # Legacy Chainlit UI
│   ├── connectors/      # Интеграционные коннекторы
│   └── fastapi-gateways/
├── library/             # База знаний
│   ├── raw_documents/   # Исходные документы (ТРИЗ)
│   └── cleaned_documents/
├── scripts/             # PowerShell automation
│   ├── START_ALL.ps1    # Запуск всех сервисов
│   ├── STOP_ALL.ps1     # Остановка всех сервисов
│   ├── CHECK_STATUS.ps1 # Проверка статуса
│   ├── BUILD_RELEASE.ps1 # Сборка релиза
│   ├── start_lightrag.ps1
│   ├── start_neuro_terminal.ps1
│   ├── start_training_ui.ps1
│   └── start_agent_training.ps1  # TASK 9
├── models/              # Fine-tuned модели (локально, не в git)
├── docs/                # Общая документация
├── USER/                # Пользовательские скрипты
└── .github/
    └── copilot-instructions.md
```

### Сборка production версии

```powershell
# Автоматическая сборка (рекомендуется)
pwsh scripts/BUILD_RELEASE.ps1

# Или вручную:
cd client
npm run tauri build

# Скомпилированное приложение:
# client/src-tauri/target/release/bundle/msi/*.msi (installer)
# client/src-tauri/target/release/WORLD_OLLAMA.exe (portable)
```

---

## ⚠️ Ограничения и TODO

### MVP Ограничения
- **TRAIN AGENT** — пока безопасный stub (обновляет статус, но не запускает реальное обучение)
- **GIT PUSH** — только dry-run (`git status --porcelain`), без реального push
- **INDEX KNOWLEDGE** — параметры PATH/MODE/PROFILE пока не передаются в PowerShell скрипт

### TODO (будущие улучшения)
- [ ] Реальное обучение в TRAIN AGENT (генерация config, запуск `train.py`)
- [ ] Реальный git commit/push (с подтверждением)
- [ ] Progress tracking для обучения (epochs completed, loss, ETA)
- [ ] Toast notifications для завершённых фоновых задач
- [ ] Live status updates в CommandSlot (polling `training_status.json`)
- [ ] History log команд в CommandSlot
- [ ] Интеграция с GitHub API (создание PR)

---

## 🤝 Вклад в проект

Проект находится в активной разработке. Приветствуются:
- Баг-репорты (Issues)
- Feature requests (Issues с тегом `enhancement`)
- Pull requests

**Перед PR:**
1. Форкните репозиторий
2. Создайте feature branch (`git checkout -b feature/AmazingFeature`)
3. Закоммитьте изменения (`git commit -m 'Add AmazingFeature'`)
4. Запушьте branch (`git push origin feature/AmazingFeature`)
5. Откройте Pull Request

---

## 📜 Лицензия

MIT License — см. [`LICENSE`](LICENSE) файл.

---

## 📧 Контакты

**Автор:** Zasada1980  
**GitHub:** [github.com/Zasada1980/WorldOllama](https://github.com/Zasada1980/WorldOllama)

---

## 🙏 Благодарности

Проект использует:
- [Ollama](https://ollama.ai/) — локальные LLM модели
- [Tauri](https://tauri.app/) — нативные десктопные приложения
- [Svelte](https://svelte.dev/) — реактивный UI фреймворк
- [LightRAG](https://github.com/HKUDS/LightRAG) — knowledge graph retrieval
- [LLaMA Factory](https://github.com/hiyouga/LLaMA-Factory) — LLM fine-tuning
- [Rust](https://rust-lang.org/) — системный язык программирования

---

**Версия README:** 1.0.0  
**Дата обновления:** 27 ноября 2025 г.  
**Статус проекта:** ✅ MVP Complete (Tasks 1-9)
