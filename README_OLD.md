# 🌍 WORLD_OLLAMA — Unified AI Knowledge System

**Дата создания:** 26 ноября 2025 г.  
**Версия:** 3.3  
**Статус:** 🟢 В активной разработке

---

## 📋 ОГЛАВЛЕНИЕ

1. [Быстрый старт](#-быстрый-старт)
2. [Desktop Client](#-desktop-client-tauri)
3. [Архитектура проекта](#-архитектура-проекта)
4. [Компоненты системы](#-компоненты-системы)
5. [Управление системой](#-управление-системой)
6. [Документация](#-документация)

---

## 🚀 БЫСТРЫЙ СТАРТ

### Desktop Client (Основной интерфейс)

```powershell
# 1. Запуск сервисов (автоматически)
pwsh E:\WORLD_OLLAMA\scripts\START_ALL.ps1

# 2. Запуск Desktop Client
cd E:\WORLD_OLLAMA\client
npm run tauri dev
```

**Откроется приложение с:**
- 💬 **Chat** — общение с AI (Ollama + CORTEX)
- 📡 **System Status** — мониторинг сервисов
- ⚙️ **Settings** — настройки моделей и параметров

### Neuro-Terminal (Альтернативный веб-интерфейс)

```powershell
# Запуск Neuro-Terminal
pwsh E:\WORLD_OLLAMA\scripts\start_neuro_terminal.ps1

# Откройте браузер:
http://localhost:8501
```

---

## 🖥️ DESKTOP CLIENT (TAURI)

### Основные возможности

**Текущая версия:** Task 5 завершена (Settings + Agent Profiles)

| Функция | Статус | Описание |
|---------|--------|----------|
| 💬 Chat с Ollama | ✅ | Локальные LLM запросы |
| 🧠 CORTEX RAG | ✅ | GraphRAG по базе знаний (486+ документов) |
| 📡 System Status | ✅ | Мониторинг Ollama + CORTEX |
| ⚙️ Settings | ✅ | Выбор модели, параметры CORTEX, профили |
| 👤 Agent Profiles | ✅ | ТРИЗ-инженер / Документалист / Code Assistant |
| 💾 Персистентность | ✅ | Сохранение настроек в AppData |

### Скриншоты и отчёты

- [TASK4_REPORT.md](client/TASK4_REPORT.md) — System Status UI
- [TASK5_REPORT.md](client/TASK5_REPORT.md) — Settings + Profiles

---

## 🏗️ АРХИТЕКТУРА ПРОЕКТА

### Основные компоненты

```
┌─────────────────────────────────────────────────────────┐
│  Desktop Client (Tauri + Rust + Svelte)                │
│  Port: Standalone application                          │
│  UI: Chat / Status / Settings                          │
└──────────────────┬──────────────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
┌────────────────┐    ┌────────────────────┐
│ Ollama         │    │ CORTEX (LightRAG)  │
│ Port: 11434    │    │ Port: 8004         │
│ LLM Inference  │    │ GraphRAG Engine    │
└────────────────┘    └────────────────────┘
                               │
                               ▼
                      ┌─────────────────┐
                      │ Knowledge Base  │
                      │ 486+ документов │
                      │ ТРИЗ + AI       │
                      └─────────────────┘
```

### Физическая структура

```
E:\WORLD_OLLAMA\
├── client/                         # 🖥️ Desktop Client (Tauri)
│   ├── src-tauri/                  # Rust backend
│   │   └── src/
│   │       ├── config.rs           # API конфигурация
│   │       ├── commands.rs         # Tauri команды
│   │       ├── settings.rs         # Управление настройками
│   │       └── lib.rs
│   ├── src/                        # Svelte frontend
│   │   ├── routes/+page.svelte     # Главная страница
│   │   └── lib/components/         # UI компоненты
│   ├── TASK4_REPORT.md             # Отчёт Task 4
│   ├── TASK5_REPORT.md             # Отчёт Task 5
│   └── test_task5_settings.ps1     # Тестовый скрипт
│
├── services/
│   ├── lightrag/                   # 🧠 CORTEX (GraphRAG)
│   │   ├── lightrag_server.py      # FastAPI сервер
│   │   └── data/                   # Персистентное хранилище
│   ├── neuro_terminal/             # 🌐 Neuro-Terminal (Chainlit)
│   ├── llama_factory/              # 🏭 LLaMA Factory
│   └── connectors/synapse/         # 🔗 SYNAPSE connector
│
├── library/
│   └── raw_documents/              # 📚 486+ документов ТРИЗ/AI
│
├── scripts/
│   ├── START_ALL.ps1               # Запуск всех сервисов
│   ├── STOP_ALL.ps1                # Остановка всех сервисов
│   ├── CHECK_STATUS.ps1            # Проверка статуса
│   ├── start_lightrag.ps1
│   └── start_neuro_terminal.ps1
│
├── production/                     # ✅ Production модели
│   └── TD010v2_triz_full/          # eval_loss 0.8591 ⭐ CERTIFIED
│
├── archive/                        # 📦 Архивные модели
│   └── Qwen2-7B_checkpoint/
│
├── docs/
│   └── SECURE_ENCLAVE_REPORT.md
│
├── library/                        # ✅ 179 файлов, 7.69 MB
│   ├── raw_documents/             # ТРИЗ принципы + AI методологии
│   ├── cleaned_documents/
│   └── backups/
│
├── logs/
│   ├── agents/
│   ├── ingestion/
│   └── services/
│
├── models/
│   ├── qwen2-triz-merged/         # Fine-tuned LoRA adapters (legacy)
│   └── triz-td010v2-merged/       # ✅ Merged production model (2960 MB)
│
├── scripts/                        # ✅ 20 PowerShell скриптов
│   ├── generate_map.ps1
│   ├── ingest_watcher.ps1
│   ├── start_lightrag.ps1
│   ├── start_neuro_terminal.ps1
│   ├── start_training_ui.ps1
│   ├── start_training.ps1
│   ├── cleanup_project.ps1        # Project cleanup automation
│   ├── export_td010v2_gguf.ps1    # Model export
│   └── ... (12 more training/utility scripts)
│
├── services/                       # ✅ Микросервисы
│   ├── connectors/
│   │   └── synapse/               # CORTEX API client (knowledge_client.py)
│   ├── fastapi-gateways/
│   ├── lightrag/                  # CORTEX (port 8004)
│   │   ├── data/                  # ✅ 1 файл (kv_store_llm_response_cache.json, 340 KB)
│   │   ├── lightrag_server.py     # 697 строк
│   │   ├── venv/                  # Python virtual environment
│   │   └── requirements.txt       # 8 dependencies
│   ├── llama_factory/             # Fine-tuning platform
│   │   ├── data/
│   │   │   └── triz_synthesis_v1.jsonl  # ✅ 300 строк, 480.19 KB
│   │   ├── triz_safe_config.yaml
│   │   ├── venv/
│   │   └── requirements.txt       # 30+ dependencies
│   └── neuro_terminal/            # UI (port 8501) - MAIN INTERFACE
│       ├── app.py                 # 210 строк
│       ├── .venv/                 # Python virtual environment
│       └── requirements.txt       # 3 dependencies
│
├── USER/                           # ✅ 5 PowerShell скриптов управления
│   ├── CHECK_STATUS.ps1           # Проверка статуса
│   ├── START_ALL.ps1              # Запуск системы
│   ├── START_ALL_TEST.ps1
│   ├── STOP_ALL.ps1               # Остановка системы
│   ├── TEST_E2E.ps1               # End-to-end тесты
│   └── README.md                  # Руководство пользователя
│
├── workbench/
│   └── sandbox_main/              # ✅ 13 скриптов/утилит
│       └── scripts/
│           ├── data_forge.py      # Self-distillation dataset generation
│           ├── force_inference_test.py
│           └── ...
│
├── NEURAL_LINK_ACTIVATION.md
├── PROJECT_MAP.md                 # Карта проекта
├── README.md                      # ← ВЫ ЗДЕСЬ
├── STATE_SNAPSHOT_v3.1.md         # Снимок состояния системы
└── TECHNICAL_REPORT_VERIFIED.md   # ✅ Верифицированный технический отчёт
```

---

## 🎯 КОМПОНЕНТЫ СИСТЕМЫ

### 1. CORTEX (LightRAG Knowledge Server)

**Порт:** 8004  
**Путь:** `services/lightrag/`  
**Функция:** GraphRAG сервер для семантического поиска по базе знаний

**Запуск:**
```powershell
pwsh E:\WORLD_OLLAMA\scripts\start_lightrag.ps1
```

**Особенности:**
- ✅ LightRAG 0.0.0.7+
- ✅ FastAPI 0.115.0+
- ✅ API Key auth: "sesa-secure-core-v1"
- ⚠️ Rerank ОТКЛЮЧЕН (bug LightRAG v1.4.9.8)
- ✅ 179 документов в library/raw_documents/ (7.69 MB)

### 2. Neuro-Terminal (Chainlit UI)

**Порт:** 8501 (ГЛАВНЫЙ ИНТЕРФЕЙС)  
**Путь:** `services/neuro_terminal/`  
**Функция:** Веб-интерфейс для диалога с AI

**Запуск:**
```powershell
pwsh E:\WORLD_OLLAMA\scripts\start_neuro_terminal.ps1
```

**Особенности:**
- ✅ Chainlit 1.1.402
- ✅ Chain-of-thought визуализация
- ✅ Интеграция с SYNAPSE connector
- ✅ Ollama 0.6.1 client

### 3. LLaMA Factory (Fine-tuning Platform)

**Порт:** 7860  
**Путь:** `services/llama_factory/`  
**Функция:** Обучение моделей (LoRA/QLoRA)

**Запуск:**
```powershell
pwsh E:\WORLD_OLLAMA\scripts\start_training_ui.ps1
```

**Особенности:**
- ✅ Dataset: triz_synthesis_v1.jsonl (300 pairs)
- ✅ LoRA rank 8, batch size 1
- ✅ preprocessing_num_workers: 1 (Windows file locking fix)

### 4. Ollama (LLM Engine)

**Порт:** 11434  
**Модель:** qwen2.5:14b-instruct-q4_k_m  
**Embeddings:** nomic-embed-text  
**GPU:** RTX 5060 Ti 16GB

**Проверка:**
```powershell
curl http://localhost:11434/api/tags
ollama list

# Проверка production модели:
ollama list | Select-String "triz"
# Ожидается: triz-td010v2:latest (3.1 GB)
```

### 5. Production Model (TD-010v2)

**Модель:** triz-td010v2:latest  
**Размер:** 3.1 GB (Ollama GGUF)  
**Base:** Qwen2.5-1.5B-Instruct + LoRA adapter (triz_full)  
**Качество:** eval_loss 0.8591 ⭐ (CERTIFIED)

**Расположение:**
- **Adapter:** `production/TD010v2_triz_full/` (35.27 MB)
- **Merged HF:** `models/triz-td010v2-merged/` (2960 MB)
- **Ollama Registry:** `triz-td010v2:latest`

**Использование:**
```powershell
# Тест модели напрямую через Ollama:
ollama run triz-td010v2 "Объясни принцип дробления ТРИЗ"

# Через Neuro-Terminal (рекомендуется):
# 1. Запустить: pwsh scripts\start_neuro_terminal.ps1
# 2. Открыть: http://localhost:8501
# 3. Выбрать модель: triz-td010v2
```

**Параметры обучения:**
- LoRA modules: 7 (up_proj, k_proj, gate_proj, v_proj, q_proj, o_proj, down_proj)
- LoRA rank: 8, alpha: 16
- Dataset: triz_synthesis_v1.jsonl (300 pairs)
- Optimizer: adamw_8bit (критично для RTX 5060 Ti)

---

## 🎮 УПРАВЛЕНИЕ СИСТЕМОЙ

### Запуск всей системы

```powershell
cd E:\WORLD_OLLAMA\USER
.\START_ALL.ps1
```

**Что запустится:**
1. CORTEX (LightRAG) → port 8004
2. LLaMA Board (Gradio) → port 7860
3. Neuro-Terminal (Chainlit) → port 8501

### Проверка статуса

```powershell
cd E:\WORLD_OLLAMA\USER
.\CHECK_STATUS.ps1
```

### Остановка системы

```powershell
cd E:\WORLD_OLLAMA\USER
.\STOP_ALL.ps1
```

---

## 📚 ДОКУМЕНТАЦИЯ

### Для пользователей

- **[USER/README.md](USER/README.md)** — Простое руководство (без технических деталей)
- **[STATE_SNAPSHOT_v3.1.md](STATE_SNAPSHOT_v3.1.md)** — Текущее состояние системы

### Для разработчиков

- **[TECHNICAL_REPORT_VERIFIED.md](TECHNICAL_REPORT_VERIFIED.md)** — Полный технический отчёт (физически проверенный)
- **[PROJECT_MAP.md](PROJECT_MAP.md)** — Карта структуры проекта
- **[.github/copilot-instructions.md](.github/copilot-instructions.md)** — Инструкции для AI Copilot

### Конфигурации

- **[services/lightrag/lightrag_server.py](services/lightrag/lightrag_server.py)** — CORTEX configuration
- **[services/neuro_terminal/app.py](services/neuro_terminal/app.py)** — UI configuration
- **[services/llama_factory/triz_safe_config.yaml](services/llama_factory/triz_safe_config.yaml)** — Training config

---

## ✅ КЛЮЧЕВЫЕ ФАКТЫ (физически проверены 27.11.2025)

| Аспект | Значение |
|--------|----------|
| **Документов в library** | 179 файлов (7.69 MB) |
| **LightRAG data** | 1 файл (357.85 KB) |
| **Датасет обучения** | 300 строк (480.19 KB) |
| **API Key** | "sesa-secure-core-v1" |
| **Ollama endpoint** | http://localhost:11434 |
| **LLM Model** | qwen2.5:14b |
| **Embedding Model** | nomic-embed-text |
| **LoRA rank** | 8 |
| **Batch size** | 1 (gradient accumulation: 4) |
| **preprocessing_num_workers** | 1 (Windows fix) |
| **Production Model** | TD-010v2 (triz_full) - eval_loss 0.8591 ⭐ |
| **Ollama Model** | triz-td010v2:latest (3.1 GB) |

---

## 🎓 ВАЖНЫЕ ОТКРЫТИЯ (TD-010 Research)

### Оптимизация для RTX 5060 Ti 16GB

**Критические находки:**
1. **Optimizer Impact**: `adamw_8bit` экономит 2-3 GB VRAM vs `adamw_torch_fused` (ОБЯЗАТЕЛЬНО)
2. **Hardware Ceiling**: ~2.5M trainable params максимум для 300-sample dataset
3. **Quality Paradox**: Qwen2.5-1.5B (7 LoRA modules) > Qwen2.5-3B (2 modules)
   - Полная адаптация важнее размера базовой модели
4. **Mini-test ≠ Full training**: VRAM масштабируется нелинейно

**Рекомендации:**
- Используйте `adamw_8bit` для всех тренировок на RTX 5060 Ti
- Предпочитайте меньшую модель + больше LoRA modules вместо большей модели + меньше modules
- Не экстраполируйте VRAM из mini-tests на полный dataset

### Production Deployment Workflow

1. **Training** → LLaMA Factory (`services/llama_factory/`)
2. **Export** → Merge LoRA + base model (`scripts/export_td010v2_gguf.ps1`)
3. **Deployment** → Ollama registry (`ollama create triz-td010v2`)
4. **Quality Check** → 2 TRIZ principle tests (дробление ✅, универсальность ✅)
5. **Cleanup** → Archive legacy models (`scripts/cleanup_project.ps1`)
6. **Certification** → Audit log (`docs/TD010_AUDIT_OK.log`)

---

## 📝 ИСТОРИЯ ВЕРСИЙ

- **v1.1 (27.11.2025)** — Production Model Deployment (TD-010v2 certified)
- **v1.0 (26.11.2025)** — Первая стабильная версия с верифицированными данными
| **Ollama endpoint** | http://localhost:11434 |
| **LLM Model** | qwen2.5:14b |
| **Embedding Model** | nomic-embed-text |
| **LoRA rank** | 8 |
| **Batch size** | 1 (gradient accumulation: 4) |
| **preprocessing_num_workers** | 1 (Windows fix) |
| **Production Model** | TD-010v2 (triz_full) - eval_loss 0.8591 ⭐ |
| **Ollama Model** | triz-td010v2:latest (3.1 GB) |

---

## 🔗 ССЫЛКИ

- **Neuro-Terminal:** http://localhost:8501 (ГЛАВНЫЙ ИНТЕРФЕЙС)
- **CORTEX API:** http://localhost:8004 (защищено API Key)
- **LLaMA Board:** http://localhost:7860
- **Ollama API:** http://localhost:11434

---

## 📝 ИСТОРИЯ ВЕРСИЙ

- **v1.0 (26.11.2025)** — Первая стабильная версия с верифицированными данными
- **v0.9 (25.11.2025)** — Neuro-Cognitive Stability (STATE_SNAPSHOT_v3.1)
- **v0.8 (24.11.2025)** — Отказ от Open WebUI, переход на Chainlit

---

**Проект:** WORLD_OLLAMA  
**Автор:** SESA3002a  
**Лицензия:** Private  
**Контакт:** см. документацию
