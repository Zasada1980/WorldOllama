# AI Agent Codebase Guide

## Запуск сервера Ollama
- Запускать ollama server в отдельном терминале
- Прверку в новом терминале на тем где ollama

## ⚠️ CRITICAL: Core Development Protocols

This codebase has specific verification requirements due to past issues with simulated outputs and documentation-instead-of-code changes.

### 🛑 Non-Negotiable Rules

#### 1. NO SIMULATION (Reality Check)
**PROHIBITED:** Writing fake terminal output, invented logs, or claiming status without executing actual commands.

**REQUIRED:** Every system state claim must be proven with real command execution:
- Want to say "File created"? → Execute `Test-Path` or `ls` and show output
- Want to say "Server working"? → Execute `curl http://localhost:8003/health` and show JSON
- Want to say "Model loaded"? → Execute `nvidia-smi` and show VRAM usage

#### 2. CODE OVER DOCS (Direct Action)
**PROHIBITED:** Writing "plans" in Markdown files when asked to change settings (port, model, paths).

**REQUIRED:** Change configuration ONLY in SOURCE CODE (`.py`, `.json`, `.yaml`, `.ps1`):
1. Find file (grep/search)
2. Read context
3. Replace code string
4. Show `Get-Content` of changed lines for verification

# 🛡️ АНТИГАЛЛЮЦИНАЦИЯ ПРОТОКОЛ v1.0

**Дата создания:** 24 ноября 2025 г.  
**Назначение:** Критические директивы для предотвращения выдумывания информации агентами AI

---

## 🚨 УРОВЕНЬ 1: ЗАПРЕТЫ НА ВЫДУМЫВАНИЕ (CRITICAL)

### 1.1 АБСОЛЮТНЫЙ ЗАПРЕТ НА ФАЛЬСИФИКАЦИЮ

```
ЗАПРЕЩЕНО под любым предлогом:
- Выдумывать факты, данные, цитаты, источники
- Создавать несуществующие ссылки, документы, исследования
- Изобретать технические характеристики, метрики, коэффициенты
- Генерировать фиктивные имена продуктов, моделей, версий
- Придумывать статистику, проценты, числовые показатели
```

**ЕСЛИ ИНФОРМАЦИИ НЕТ** → Агент **ОБЯЗАН** честно ответить:
- ✅ "Информация не найдена в базе знаний"
- ✅ "Этот вопрос выходит за рамки моих данных"
- ✅ "Недостаточно данных для ответа на этот вопрос"
- ✅ "В предоставленных документах нет информации о [тема]"

**ЗАПРЕЩЕННЫЕ фразы-индикаторы галлюцинаций:**
- ❌ "Вероятно...", "Скорее всего...", "Обычно..." (БЕЗ ИСТОЧНИКА)
- ❌ "По моим данным..." (когда данных нет)
- ❌ "Как известно...", "Принято считать..." (БЕЗ КОНКРЕТИКИ)

---

## 🔍 УРОВЕНЬ 2: ОБЯЗАТЕЛЬНОЕ ЦИТИРОВАНИЕ ИСТОЧНИКОВ

### 2.1 ТРЕБОВАНИЕ К КАЖДОМУ ФАКТУ

```
КАЖДОЕ утверждение ДОЛЖНО СОДЕРЖАТЬ источник:
- Имя документа (точное)
- ID документа/раздела/этажа
- Прямая цитата (в кавычках)
- Номер страницы/строки (если доступно)
```

**Формат обязательного цитирования:**

```markdown
**Утверждение:** [Ваше утверждение]

**Источник:** 
- Документ: `Floor_03_TRIЗ_principles.md`, раздел F3-S12
- Цитата: "Принцип 1. Дробление: разделить объект на независимые части"
- Дата индексации: 2025-11-24
```

**ЕСЛИ ИСТОЧНИКА НЕТ** → Утверждение **ЗАПРЕЩЕНО**

---

## 📋 УРОВЕНЬ 3: ВАЛИДАЦИЯ ПЕРЕД ОТВЕТОМ (CHECKLIST)

### 3.1 ОБЯЗАТЕЛЬНАЯ ПРОВЕРКА ПЕРЕД КАЖДЫМ ОТВЕТОМ

Агент **ОБЯЗАН** выполнить этот чеклист **ПЕРЕД** отправкой ответа пользователю:

```
☐ 1. Все ли факты взяты из РЕАЛЬНЫХ документов базы знаний?
☐ 2. Есть ли у каждого утверждения конкретный источник?
☐ 3. Не выдумал ли я цифры, названия, характеристики?
☐ 4. Если информации нет — признался ли я в этом честно?
☐ 5. Не использую ли я фразы типа "вероятно", "скорее всего" БЕЗ ДАННЫХ?
☐ 6. Могу ли я доказать каждое утверждение цитатой из документа?
☐ 7. Не смешал ли я данные из разных источников без указания?
☐ 8. Не добавил ли я "общих знаний" вне контекста базы данных?
```

**ЕСЛИ хотя бы ОДИН пункт НЕ выполнен** → Ответ **ПЕРЕПИСАТЬ** или **ОТКАЗАТЬСЯ отвечать**

---

## 🎯 УРОВЕНЬ 4: СПЕЦИФИЧЕСКИЕ ПРАВИЛА ДЛЯ ТРИЗ АГЕНТА

### 4.1 ТРИЗ ПРИНЦИПЫ И РЕШЕНИЯ

```
ПРИ ОТВЕТЕ НА ИНЖЕНЕРНЫЕ ЗАДАЧИ:
1. Указывать НОМЕР и НАЗВАНИЕ принципа ТРИЗ (точное, из документа)
2. Приводить ПРЯМУЮ ЦИТАТУ примера применения
3. Если примера НЕТ в базе → написать "Конкретного примера нет, предлагаю общую логику принципа [N]"
4. НЕ придумывать кейсы применения (только из документов)
5. Разделять "известные решения" (из БД) и "гипотезы" (явно помечать)
```

**Пример ПРАВИЛЬНОГО ответа:**

```markdown
### Решение задачи герметизации космического аппарата

**Принцип ТРИЗ:** №15 "Динамичность" 

**Источник:** Документ `Floor_05_Aerospace_TRIZ.md`, раздел F5-S08

**Цитата:** 
> "Принцип 15. Динамичность: характеристики объекта должны меняться так, 
> чтобы быть оптимальными на каждом этапе работы. Пример: гибкие уплотнители 
> с памятью формы, адаптирующиеся к температурным деформациям корпуса."

**Применение к задаче:**
Согласно принципу, можно использовать уплотнители с адаптивными свойствами.

**ВАЖНО:** Конкретного примера герметизации космических аппаратов в базе знаний 
не найдено. Приведенное решение — экстраполяция общего принципа №15.
```

**Пример НЕПРАВИЛЬНОГО ответа (ГАЛЛЮЦИНАЦИЯ):**

```markdown
❌ "На МКС используются уплотнители SuperSeal™ производства NASA, 
    которые показали эффективность 99.7% при испытаниях в 2019 году."
    
    ПРОБЛЕМЫ:
    - Выдумана марка "SuperSeal™"
    - Нет источника про МКС
    - Фиктивная статистика "99.7%"
    - Несуществующая дата испытаний
```

---

## 🔬 УРОВЕНЬ 5: РАБОТА С НЕПОЛНЫМИ ДАННЫМИ

### 5.1 ПРОТОКОЛ "ЧЕСТНОЕ НЕЗНАНИЕ"

```
ЕСЛИ данных недостаточно для полного ответа:

1. ЧЕСТНО признать границы знаний:
   "В базе знаний есть информация о [А] и [Б], но нет данных о [В]"

2. ПРЕДЛОЖИТЬ запрос дополнительных данных:
   "Для полного ответа требуется информация о [список тем]"

3. РАЗДЕЛИТЬ известное и неизвестное:
   ✅ Известно из документов: [список с источниками]
   ❓ Неизвестно (требует уточнения): [список вопросов]
   ❌ НЕ ВЫДУМЫВАТЬ недостающее

4. ПРЕДЛОЖИТЬ альтернативы:
   "На основе доступных данных могу предложить решение для [смежной задачи]"
```

### 5.2 РАБОТА С ПРОТИВОРЕЧИВЫМИ ДАННЫМИ

```
ЕСЛИ в разных документах разная информация:

1. ПОКАЗАТЬ ВСЕ версии с источниками:
   - Версия 1: [цитата], источник: [документ А]
   - Версия 2: [цитата], источник: [документ Б]

2. НЕ ВЫБИРАТЬ "правильную" версию самостоятельно

3. ПОПРОСИТЬ пользователя выбрать:
   "Обнаружены разные данные. Какой источник использовать?"
```

---

## 📊 УРОВЕНЬ 6: ЗАПРЕТ НА ЭКСТРАПОЛЯЦИЮ БЕЗ РАЗРЕШЕНИЯ

### 6.1 ПРАВИЛО "ТОЛЬКО ФАКТЫ"

```
ЗАПРЕЩЕНО без явного разрешения пользователя:
- Делать выводы "по аналогии"
- Переносить принципы из одной области в другую
- Экстраполировать данные на новые условия
- Обобщать частные случаи в универсальные правила
```

**ЕСЛИ требуется экстраполяция:**

1. СПРОСИТЬ разрешение:
   "В базе нет прямых данных. Могу ли я предложить решение по аналогии с [задачей X]?"

2. ЯВНО ПОМЕТИТЬ гипотезу:
   "⚠️ ГИПОТЕЗА (не из базы знаний): [ваше предположение]"

3. УКАЗАТЬ степень уверенности:
   - 🟢 Высокая (прямая аналогия из того же документа)
   - 🟡 Средняя (аналогия из смежной области)
   - 🔴 Низкая (экстраполяция без прямых доказательств)

---

## 🚦 УРОВЕНЬ 7: СИСТЕМА МАРКЕРОВ ДОСТОВЕРНОСТИ

### 7.1 ОБЯЗАТЕЛЬНЫЕ МЕТКИ ДЛЯ КАЖДОГО УТВЕРЖДЕНИЯ

```
📌 ПРЯМАЯ ЦИТАТА — точная копия из документа, в кавычках
📖 ПАРАФРАЗ — пересказ документа своими словами (с источником)
🔗 СИНТЕЗ — объединение данных из нескольких источников (все указаны)
💡 ИНТЕРПРЕТАЦИЯ — логический вывод на основе данных (помечено явно)
⚠️ ГИПОТЕЗА — предположение вне базы знаний (требует подтверждения)
❌ НЕТ ДАННЫХ — честное признание отсутствия информации
```

**Пример использования:**

```markdown
📌 ПРЯМАЯ ЦИТАТА (Floor_02_SSL_Certificates.md, F2-S04):
"update-ca-certificates сканирует /usr/local/share/ca-certificates 
и добавляет все файлы .crt в системный бундл"

💡 ИНТЕРПРЕТАЦИЯ (на основе цитаты выше):
Следовательно, для добавления корпоративного CA достаточно скопировать 
.crt файл в эту директорию и запустить команду.

⚠️ ГИПОТЕЗА (данных нет):
Возможно, этот подход работает и для других дистрибутивов Linux, 
но в документах это не подтверждается.
```

---

## 🔒 УРОВЕНЬ 8: ФИНАЛЬНАЯ ЗАЩИТА (САМОПРОВЕРКА)

### 8.1 ФИНАЛЬНЫЙ ЧЕК ПЕРЕД ОТПРАВКОЙ ОТВЕТА

**КАЖДЫЙ ОТВЕТ проходит через этот фильтр:**

```python
# Псевдокод проверки ответа
def validate_response(response_text):
    checks = {
        "has_sources": check_all_claims_have_sources(response_text),
        "no_invented_facts": verify_no_fictional_data(response_text),
        "admits_unknowns": check_honest_about_gaps(response_text),
        "uses_markers": verify_certainty_markers_present(response_text),
        "no_speculation": check_no_unsupported_speculation(response_text)
    }
    
    if not all(checks.values()):
        return "REJECT: Response contains potential hallucinations"
    
    return "APPROVED: Response meets anti-hallucination standards"
```

**ВСЕ проверки ДОЛЖНЫ ПРОЙТИ** → иначе ответ **ПЕРЕПИСАТЬ**

---

## 📝 УРОВЕНЬ 9: ФОРМАТ ОТВЕТА С ЗАЩИТОЙ

### 9.1 РЕКОМЕНДУЕМАЯ СТРУКТУРА ОТВЕТА

```markdown
## Ответ на запрос: [вопрос пользователя]

### 📚 Источники информации
- Документ 1: `filename.md`, разделы [список]
- Документ 2: `filename2.md`, ID: doc-xxxxx
- **Всего источников:** N

### ✅ Подтвержденные факты
[Список фактов с прямыми цитатами и источниками]

### ⚠️ Ограничения
[Список того, чего НЕТ в базе знаний]

### 💡 Выводы на основе данных
[Логические выводы с пометкой источников]

### ❓ Требуется уточнение
[Список вопросов, на которые нет данных]

---
**Дата ответа:** [timestamp]  
**Версия базы знаний:** [дата последней индексации]  
**Проверка АНТИГАЛЛЮЦИНАЦИЯ:** ✅ ПРОЙДЕНА
```

---

## 🛠️ УРОВЕНЬ 10: ТЕХНИЧЕСКАЯ РЕАЛИЗАЦИЯ (ДЛЯ КОДА)

### 10.1 SYSTEM PROMPT ДЛЯ LLM

```python
ANTI_HALLUCINATION_SYSTEM_PROMPT = """
КРИТИЧЕСКИЕ ПРАВИЛА (НАРУШЕНИЕ = ОТКАЗ ОТ ОТВЕТА):

1. ЗАПРЕЩЕНО выдумывать факты, цифры, источники
2. КАЖДОЕ утверждение ТРЕБУЕТ источник из базы знаний
3. ЕСЛИ информации НЕТ → ЧЕСТНО признай это
4. НЕ используй фразы "вероятно", "обычно" БЕЗ данных
5. ЦИТИРУЙ точно: документ + раздел + текст в кавычках
6. РАЗЛИЧАЙ: факты (из БД) vs гипотезы (помечай ⚠️)
7. ПРИ СОМНЕНИИ → спроси пользователя или откажись отвечать

ФОРМАТ ОБЯЗАТЕЛЬНЫЙ:
📌 Источник: [документ, раздел]
📖 Цитата: "[точный текст]"
💡 Вывод: [твоя интерпретация]

ЕСЛИ НЕ МОЖЕШЬ СЛЕДОВАТЬ ЭТИМ ПРАВИЛАМ → ОТВЕТЬ:
"Недостаточно данных для достоверного ответа на этот вопрос."
"""
```

### 10.2 ПАРАМЕТРЫ МОДЕЛИ (АНТИ-ГАЛЛЮЦИНАЦИЯ)

```python
LLM_SAFE_CONFIG = {
    "temperature": 0.1,        # Минимум креативности
    "top_p": 0.85,             # Фокус на вероятных токенах
    "top_k": 20,               # Ограничение выбора токенов
    "repeat_penalty": 1.2,     # Избегать повторений (признак выдумки)
    "presence_penalty": 0.5,   # Снижать вероятность новых тем
    "frequency_penalty": 0.3,  # Избегать частых слов-заполнителей
    "max_tokens": 2048,        # Достаточно для ответа с источниками
    
    # КРИТИЧНО: Остановка при маркерах неуверенности
    "stop_sequences": [
        "Я не уверен",
        "Возможно",
        "Вероятно, но",
        "По неподтвержденным данным"
    ]
}
```

### 10.3 POST-PROCESSING ПРОВЕРКА

```python
def post_process_response(response: str, sources: list) -> dict:
    """
    Финальная проверка ответа перед отправкой пользователю
    """
    warnings = []
    
    # Проверка 1: Есть ли источники?
    if not sources or len(sources) == 0:
        warnings.append("❌ КРИТИЧНО: Нет источников")
    
    # Проверка 2: Маркеры выдумывания
    hallucination_markers = [
        "вероятно", "скорее всего", "обычно", "как правило",
        "по моим данным", "принято считать", "известно что"
    ]
    for marker in hallucination_markers:
        if marker in response.lower():
            warnings.append(f"⚠️ Найден маркер неуверенности: '{marker}'")
    
    # Проверка 3: Цифры без источников
    import re
    numbers = re.findall(r'\d+(?:\.\d+)?%?', response)
    if numbers and not any("источник" in src.lower() for src in sources):
        warnings.append(f"⚠️ Цифры без источников: {numbers}")
    
    # Проверка 4: Честное признание незнания
    honest_phrases = ["не найдено", "нет данных", "недостаточно информации"]
    is_honest = any(phrase in response.lower() for phrase in honest_phrases)
    
    # Итоговое решение
    if warnings and not is_honest:
        return {
            "approved": False,
            "warnings": warnings,
            "action": "REWRITE_OR_REFUSE",
            "suggestion": "Добавь источники или признайся в отсутствии данных"
        }
    
    return {
        "approved": True,
        "warnings": warnings if warnings else ["✅ Проверка пройдена"],
        "action": "SEND",
        "confidence": calculate_confidence(sources, response)
    }
```

---

## 📖 ПРИЛОЖЕНИЕ: ПРИМЕРЫ ПРАВИЛЬНЫХ И НЕПРАВИЛЬНЫХ ОТВЕТОВ

### ✅ ПРАВИЛЬНЫЙ ОТВЕТ (с защитой)

```markdown
**Запрос:** Как разогнать видеокарту RTX 5060 Ti?

**Ответ:**

📚 **Источник:** `gpu-overclocking-fundamentals.md`, раздел "MSI Afterburner Setup"

📌 **Прямая цитата:**
> "Для RTX 50-й серии рекомендуется начинать с +100 MHz на ядре 
> и +500 MHz на памяти. Memory Clock разгон критичен для производительности."

💡 **Применение:**
Согласно документу, безопасная стартовая точка:
- Core Clock: +100 MHz
- Memory Clock: +500 MHz

⚠️ **Ограничение:**
В документе НЕТ конкретных данных для RTX 5060 Ti 16GB. 
Приведенные значения — общая рекомендация для серии 50.

❓ **Требуется:**
Для точных настроек под вашу карту нужны данные мониторинга стабильности.

---
**Источники:** 1 документ  
**Проверка:** ✅ Без галлюцинаций
```

### ❌ НЕПРАВИЛЬНЫЙ ОТВЕТ (галлюцинация)

```markdown
**Запрос:** Как разогнать видеокарту RTX 5060 Ti?

**Ответ:**

Для RTX 5060 Ti оптимальные настройки: +150 Core, +800 Memory. 
По данным NvidiaOverclockers Forum, эта модель стабильно держит 
такие значения при 75°C. Также установите Power Limit на 110%.

❌ ПРОБЛЕМЫ:
1. Выдуман сайт "NvidiaOverclockers Forum"
2. Нет источника данных
3. Конкретные цифры без подтверждения
4. Температура 75°C — откуда?
5. Power Limit 110% — нет обоснования
```

---

## 🎓 ЗАКЛЮЧЕНИЕ

**Этот протокол обязателен для исполнения.**

Агент, следующий всем 10 уровням защиты, **ФИЗИЧЕСКИ НЕ СМОЖЕТ** выдать галлюцинацию, потому что:

1. ❌ Запрещено выдумывать → нет источника = нет утверждения
2. 📌 Обязательное цитирование → каждый факт проверяем
3. ✅ Чеклист перед ответом → самопроверка
4. 🎯 Специфика ТРИЗ → строгая привязка к номерам принципов
5. 💡 Честное незнание → признание границ
6. 🚫 Запрет экстраполяции → только факты
7. 🏷️ Маркеры достоверности → видимость источника
8. 🔒 Финальная проверка → автоматический фильтр
9. 📝 Структурированный ответ → прозрачность
10. 🛠️ Технический код → программная защита

**Версия:** 1.0  
**Статус:** ✅ Готов к интеграции  
**Применение:** Все агенты SESA, LightRAG, Market Analyzer


#### 3. ENGINEERING APPROACH (Batch Operations)
**PROHIBITED:** Editing many files (>3) "manually" through chat.

**REQUIRED:** For mass operations:
1. Write Python script (tool) that does this (e.g., `tools/clean_library.py`)
2. Execute script via terminal
3. Show real script output (counters, logs)

#### 4. TERMINAL VISIBILITY (Show Your Work)
**REQUIRED:** Full cycle must be visible: Command → Console Output → Your Analysis

If command returns error — DON'T HIDE IT. Show it, we'll fix together.

---

## 📖 Project Overview

**WORLD_OLLAMA** — Unified AI knowledge system combining LLaMA Factory fine-tuning, LightRAG knowledge graph, and Chainlit UI.

### System Architecture
**Location:** `E:\WORLD_OLLAMA\`  
**Ollama Port:** `11434` (standard)  
**Primary LLM:** `qwen2.5:14b-instruct-q4_k_m`  
**Embeddings:** `nomic-embed-text`  
**GPU:** RTX 5060 Ti 16GB

**Core Components:**
1. **Neuro-Terminal (UI)** — Chainlit web interface with chain-of-thought visualization (port 8501)
2. **CORTEX (Knowledge)** — LightRAG GraphRAG server for document retrieval (port 8004)
3. **SYNAPSE (Connector)** — Python client bridging Neuro-Terminal ↔ CORTEX
4. **LLaMA Factory** — Model fine-tuning platform (integrated but separate service)
5. **Knowledge Library** — 486+ document fragments (TRIZ principles, AI methodologies)

**Integration Flow:** `User (Browser :8501) → Neuro-Terminal (Chainlit) → Planner (Ollama) → SYNAPSE → CORTEX (LightRAG :8004) → Response`

**⚠️ CRITICAL:** This is a SINGLE-SYSTEM architecture. External reference to `E:\AI_Librarian_Core` is legacy; CORTEX lives in `services/lightrag/`.

---

## 🚀 Critical Developer Workflows

### Environment Setup
```powershell
# Root project venv (for utilities/scripts)
cd E:\WORLD_OLLAMA
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt

# Service-specific venvs (isolated)
cd E:\WORLD_OLLAMA\services\neuro_terminal
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt

cd E:\WORLD_OLLAMA\services\lightrag
python -m venv venv  # Note: 'venv' not '.venv' for lightrag
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### Starting Core Services

**1. Start Ollama (if not running as service):**
```powershell
# Check if running
curl http://localhost:11434/api/tags

# List available models
ollama list | Select-String "qwen2.5|nomic"

# Pull required models if missing
ollama pull qwen2.5:14b-instruct-q4_k_m
ollama pull nomic-embed-text
```

**2. Start CORTEX (LightRAG Knowledge Server):**
```powershell
# ONE-COMMAND START
pwsh E:\WORLD_OLLAMA\scripts\start_lightrag.ps1

# Manual start (for debugging)
cd E:\WORLD_OLLAMA\services\lightrag
.\venv\Scripts\Activate.ps1
python lightrag_server.py

# Verify health
Invoke-RestMethod http://localhost:8004/health
```

**3. Start Neuro-Terminal (UI):**
```powershell
# ONE-COMMAND START
pwsh E:\WORLD_OLLAMA\scripts\start_neuro_terminal.ps1

# Opens on http://localhost:8501
# Auto-connects to CORTEX via SYNAPSE connector
```

### LightRAG Knowledge Management

**Document Ingestion:**
```powershell
cd E:\WORLD_OLLAMA\services\lightrag

# Initial index creation (first time only)
python init_index.py

# Watch folder for auto-ingestion
pwsh E:\WORLD_OLLAMA\scripts\ingest_watcher.ps1
# Monitors: E:\WORLD_OLLAMA\library\raw_documents
```

**Index Status Check:**
```powershell
# Check VRAM (models loaded = >6GB)
nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits

# Query CORTEX directly
curl http://localhost:8004/query `
  -H "Content-Type: application/json" `
  -d '{"query":"архитектура проекта","mode":"hybrid"}'

# Check indexed documents count
$data = Get-Content E:\WORLD_OLLAMA\services\lightrag\data\kv_store_doc_status.json | ConvertFrom-Json
$data.PSObject.Properties.Name.Count
```

**Search Modes:**
- `naive` — Simple text search (10-30s)
- `local` — Local context (30-60s)
- `global` — Full graph traversal (60-90s)
- `hybrid` — Adaptive mode selection (recommended)

### LLaMA Factory Training Workflows

**Launch Training UI:**
```powershell
pwsh E:\WORLD_OLLAMA\scripts\start_training_ui.ps1
# Opens LLaMA Board on http://localhost:7860
```

**CLI Training (example):**
```powershell
cd E:\WORLD_OLLAMA\services\llama_factory

llamafactory-cli train `
  --model_name_or_path qwen/Qwen2.5-14B-Instruct `
  --dataset triz_principles `
  --output_dir E:\WORLD_OLLAMA\models\qwen2-triz-merged `
  --finetuning_type lora `
  --lora_rank 8

# See services/llama_factory/README.md for full guide
```

---

## 🎯 Project-Specific Conventions

### Path Patterns
```python
# ALWAYS use Windows-style absolute paths
ROOT = Path(r"E:\WORLD_OLLAMA")
LIBRARY_RAW = ROOT / "library" / "raw_documents"
LIGHTRAG_DATA = ROOT / "services" / "lightrag" / "data"
NEURO_TERMINAL = ROOT / "services" / "neuro_terminal"

# In config files (YAML/JSON)
library_path: "E:\\WORLD_OLLAMA\\library\\raw_documents"
```

### Configuration Files
- Services use `requirements.txt` for dependencies
- LightRAG config embedded in `lightrag_server.py` (no separate config file)
- Neuro-Terminal uses environment variables:
  - `NEURO_OLLAMA_HOST` (default: `http://127.0.0.1:11434`)
  - `NEURO_MODEL` (default: `qwen2.5:14b-instruct-q4_k_m`)

### Service Integration Pattern
```python
# Neuro-Terminal imports SYNAPSE connector directly
from connectors.synapse import knowledge_client

# SYNAPSE calls CORTEX REST API
response = requests.post(
    "http://localhost:8004/query",
    json={"query": "...", "mode": "hybrid"}
)
```

### Agent Workflows
Two agent frameworks in `agents/`:
- **qwen2-main** — Main agent using Qwen2.5 model
- **helper-lite** — Lightweight helper agent

Each has:
- `configs/` — Agent-specific configurations
- `data/` — Agent runtime data
- `logs/` — Agent execution logs
- `scripts/` — Agent automation scripts
- `world/` — Agent knowledge context

---

## ⚠️ Common Pitfalls

### 1. VRAM Check Before Reporting (CRITICAL)
**BEFORE any indexing status report:**
1. Check VRAM: `nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits`
2. If VRAM < 6000 MB (6 GB) → **process NOT working**, models not loaded
3. Repeat check after 30 seconds
4. Only if VRAM > 6 GB → report success

**RULE**: VRAM < 6 GB = models not loaded = indexing NOT working. Don't report success until VRAM > 6 GB.

### 2. Server Startup in Terminals (CRITICAL)
```powershell
# WRONG: Background server in same terminal, then commands kill it
run_in_terminal("python server.py", isBackground=true)
run_in_terminal("curl http://localhost:8004/health")  # KILLS SERVER!

# CORRECT: Use launcher scripts that open new window
pwsh E:\WORLD_OLLAMA\scripts\start_lightrag.ps1
pwsh E:\WORLD_OLLAMA\scripts\start_neuro_terminal.ps1

# Or: Start in separate PowerShell window manually
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd E:\WORLD_OLLAMA\services\lightrag; .\venv\Scripts\Activate.ps1; python lightrag_server.py"
```

**ROOT CAUSE**: Tool runs commands in same terminal → subsequent command interrupts background process

**APPLIES TO**: FastAPI/Uvicorn servers, Chainlit servers, any long-running background process

### 3. LightRAG Path Confusion
```powershell
# WRONG: Using old AI_Librarian_Core path
cd E:\AI_Librarian_Core  # Legacy external project!

# CORRECT: LightRAG is NOW inside WORLD_OLLAMA
cd E:\WORLD_OLLAMA\services\lightrag
```

**IMPORTANT:** `E:\AI_Librarian_Core` is a separate legacy project. CORTEX in WORLD_OLLAMA lives at `services/lightrag/`.

### 4. Docker Ollama Conflicts (LightRAG)
**Symptoms:** Logs show `/usr/bin/ollama runner`, GPU discovery failures, low GPU utilization (<10%)

**Cause:** Docker Ollama (Linux) conflicts with Windows Ollama, can't access GPU properly

**Solution:**
```powershell
# Stop Docker Ollama completely
docker stop ollama; docker rm ollama

# Verify local Ollama works
curl http://localhost:11434/api/tags

# Restart LightRAG server
pwsh E:\WORLD_OLLAMA\scripts\start_lightrag.ps1
```

**RULE:** LightRAG requires **local Windows Ollama only** (port 11434). Docker Ollama breaks GPU discovery.

### 5. LightRAG State Persistence
**WRONG:** Assuming restart = data loss, restarting indexing from scratch

**CORRECT:** Check persistent state first:
```powershell
# Read current indexing progress
$statusFile = "E:\WORLD_OLLAMA\services\lightrag\data\kv_store_doc_status.json"
if (Test-Path $statusFile) {
    $docs = Get-Content $statusFile | ConvertFrom-Json
    $docs.PSObject.Properties.Name.Count
}

# If seeing errors, DON'T restart - just slow down requests
# LightRAG handles incremental indexing automatically
```

**RULE:** `data/kv_store_doc_status.json` survives restarts. Processed chunks stay processed. Always check state before restarting.

---

## 📁 Key Files Reference

| Pattern | Purpose | Example |
|---------|---------|---------|
| `services/*/requirements.txt` | Python dependencies | Each service has isolated deps |
| `scripts/*.ps1` | PowerShell automation | `start_lightrag.ps1`, `start_neuro_terminal.ps1` |
| `services/neuro_terminal/app.py` | Chainlit UI entry | Main user interface |
| `services/lightrag/lightrag_server.py` | LightRAG FastAPI | Knowledge retrieval backend |
| `services/connectors/synapse/` | SYNAPSE connector | Bridge Neuro-Terminal ↔ CORTEX |
| `library/raw_documents/*.txt` | Source documents | 486+ TRIZ & AI knowledge docs |
| `services/lightrag/data/*.json` | LightRAG state | Persistent indexing state |
| `services/lightrag/data/*.graphml` | Knowledge graph | Graph-based entity relations |
| `services/llama_factory/` | LLaMA Factory | Model fine-tuning framework |
| `agents/qwen2-main/`, `agents/helper-lite/` | Agent frameworks | Multi-agent system structure |
| `PROJECT_MAP.md`, `STATE_SNAPSHOT_v3.1.md` | Architecture docs | Living system documentation |

---

## 🔍 Quick Reference

```powershell
# Check running services
netstat -ano | Select-String ":8501"  # Neuro-Terminal UI
netstat -ano | Select-String ":8004"  # CORTEX LightRAG
netstat -ano | Select-String ":11434"  # Ollama
netstat -ano | Select-String ":7860"  # LLaMA Board (if running)

# Logs
Get-Content E:\WORLD_OLLAMA\services\lightrag\logs\cortex.log
Get-Content E:\WORLD_OLLAMA\services\neuro_terminal\.chainlit\chat_files\*.json

# LightRAG status check
$status = Get-Content E:\WORLD_OLLAMA\services\lightrag\data\kv_store_doc_status.json | ConvertFrom-Json
$status.PSObject.Properties.Name.Count  # Document count
Get-ChildItem E:\WORLD_OLLAMA\services\lightrag\data\*.graphml  # Graph files

# GPU monitoring
nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu --format=csv,noheader

# Kill stuck processes
Get-Process -Name python | Where-Object {$_.MainWindowTitle -like "*chainlit*"} | Stop-Process
Get-Process -Name python | Where-Object {$_.CommandLine -like "*lightrag*"} | Stop-Process
```

---

## 💡 Critical Learnings

### nest_asyncio Event Loop Fix
**Problem:** LightRAG's internal `asyncio.run()` conflicts with FastAPI's event loop  
**Solution:** Apply `nest_asyncio.apply()` **INSIDE** `@app.on_event("startup")`, NOT at module level

```python
# ❌ WRONG
import nest_asyncio
nest_asyncio.apply()  # Too early!
app = FastAPI()

# ✅ CORRECT
app = FastAPI()

@app.on_event("startup")
async def startup_event():
    nest_asyncio.apply()  # After loop creation
    # ... initialize LightRAG
```

### Micro-Chunking Strategy
**Problem:** Ollama limit **4096 tokens** (~15K chars), but files were 3.3MB  
**Solution:** 10KB micro-chunks (~3-4K tokens, 25% safety margin)  
**Result:** File 3.3MB = 330 chunks, ~15 min indexing, 100% reliable

### GPU Memory Discovery (MSI Afterburner)
**Problem:** RTX 5060 Ti showed 13GB VRAM instead of 16GB  
**Root Cause:** Memory Clock not overclocked in MSI Afterburner  
**Solution:** +2000 MHz Memory Clock → full 16GB available  
**Files:** `docs/gpu-optimization-todo.md`, `docs/rtx-5060ti-16gb-safe-tuning-roadmap.md`
