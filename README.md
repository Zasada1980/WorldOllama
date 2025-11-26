# 🌍 WORLD_OLLAMA — Unified AI Knowledge System

**Дата создания:** 26 ноября 2025 г.  
**Версия:** 1.0 STABLE  
**Статус:** ✅ Operational

---

## 📋 ОГЛАВЛЕНИЕ

1. [Быстрый старт](#-быстрый-старт)
2. [Архитектура проекта](#-архитектура-проекта)
3. [Компоненты системы](#-компоненты-системы)
4. [Управление системой](#-управление-системой)
5. [Документация](#-документация)

---

## 🚀 БЫСТРЫЙ СТАРТ

### Для пользователей

```powershell
# Запуск всей системы (одна команда)
cd E:\WORLD_OLLAMA\USER
.\START_ALL.ps1

# Откройте браузер:
http://localhost:8501
```

### Для разработчиков

См. полную документацию:
- [USER/README.md](USER/README.md) — руководство пользователя
- [TECHNICAL_REPORT_VERIFIED.md](TECHNICAL_REPORT_VERIFIED.md) — технический отчёт

---

## 🏗️ АРХИТЕКТУРА ПРОЕКТА

### Физическая структура (ФАКТ из проверки 26.11.2025)

```
E:\WORLD_OLLAMA\
├── .github/
│   └── copilot-instructions.md    # Инструкции для AI Copilot
│
├── agents/                         # Multi-Agent структура (ТОЛЬКО конфиги)
│   ├── qwen2-main/                # 2 файла: Modelfile + install script
│   └── helper-lite/               # 2 файла: Modelfile + install script
│
├── backups/
│   ├── archived_reports/          # Устаревшие отчёты
│   ├── daily/
│   ├── weekly/
│   └── manual/
│
├── docs/
│   └── SECURE_ENCLAVE_REPORT.md
│
├── library/                        # ✅ 177 файлов, 7.62 MB
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
│   └── qwen2-triz-merged/         # Fine-tuned LoRA adapters
│
├── scripts/                        # ✅ 6 PowerShell скриптов
│   ├── generate_map.ps1
│   ├── ingest_watcher.ps1
│   ├── start_lightrag.ps1
│   ├── start_neuro_terminal.ps1
│   ├── start_training_ui.ps1
│   └── start_training.ps1
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
- ✅ 177 документов в library/raw_documents/

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
```

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

## ✅ КЛЮЧЕВЫЕ ФАКТЫ (физически проверены 26.11.2025)

| Аспект | Значение |
|--------|----------|
| **Документов в library** | 177 файлов (7.62 MB) |
| **LightRAG data** | 1 файл (340.47 KB) |
| **Датасет обучения** | 300 строк (480.19 KB) |
| **API Key** | "sesa-secure-core-v1" |
| **Ollama endpoint** | http://localhost:11434 |
| **LLM Model** | qwen2.5:14b |
| **Embedding Model** | nomic-embed-text |
| **LoRA rank** | 8 |
| **Batch size** | 1 (gradient accumulation: 4) |
| **preprocessing_num_workers** | 1 (Windows fix) |

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
