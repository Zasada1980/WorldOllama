# SYNAPSE - Knowledge Connector (TD-007)

**Миссия:** Связать Агента (Qwen/Llama) с CORTEX (LightRAG) через стандартизированный интерфейс.

**Принцип ТРИЗ №24 "Посредник"** — создание промежуточного объекта для передачи действия.

---

## 📁 Структура

```
connectors/
├── python/
│   ├── knowledge_client.py      # Основной клиент SYNAPSE
│   ├── test_synapse.py          # Верификационный тест
│   └── synapse_tool_def.json    # OpenAPI/Ollama Function definition
└── README.md                     # Эта документация
```

---

## 🚀 Быстрый старт

### 1. Предварительные требования

- ✅ CORTEX сервер запущен на http://localhost:8004
- ✅ Python 3.12+ (с пакетом `requests`)

**Проверка CORTEX:**
```powershell
Invoke-RestMethod http://localhost:8004/health
```

**Запуск CORTEX (если не запущен):**
```powershell
pwsh E:\WORLD_OLLAMA\scripts\start_lightrag.ps1
```

### 2. Установка зависимостей

```powershell
# В песочнице нет venv, используем системный Python
pip install requests
```

### 3. Запуск тестов

```powershell
cd E:\WORLD_OLLAMA\workbench\sandbox_main\connectors\python
python test_synapse.py
```

**Ожидаемый результат:**
```
═══════════════════════════════════════════════════════════════
  SYNAPSE VERIFICATION TEST SUITE (TD-007)
  Knowledge Connector: Agent ↔ CORTEX Integration
═══════════════════════════════════════════════════════════════

TEST 1: CORTEX Health Check
✅ Status: healthy
✅ Working dir exists: True
✅ Library dir exists: True

TEST 2: Simple Query
Query: Какова структура проекта WORLD_OLLAMA?
Mode: hybrid
✅ Ответ получен (2500+ символов)
✅ Качество: Ответ содержит достаточно информации

... (остальные тесты)

TOTAL: 4/4 tests passed
VERDICT: ✅ SYNAPSE OPERATIONAL
```

---

## 📖 API Reference

### `lookup_knowledge(query, mode="hybrid", timeout=120)`

Основная функция для запроса знаний из CORTEX.

**Аргументы:**
- `query` (str) — Детальный поисковый запрос
- `mode` (str) — Режим поиска:
  - `"hybrid"` (рекомендуется) — комбинированный (30-60s)
  - `"local"` — entity-based локальный (20-30s)
  - `"global"` — глобальный граф (30-45s)
  - `"naive"` — векторный (10-20s, менее точно)
- `timeout` (int) — Таймаут в секундах (default: 120)

**Возвращает:**
- `str` — Текстовый ответ (обычно 2000-3000 символов)

**Исключения:**
- `CortexConnectionError` — Сервер недоступен
- `CortexQueryError` — Ошибка выполнения запроса
- `ValueError` — Некорректные входные данные

**Примеры:**

```python
from knowledge_client import lookup_knowledge

# Простой запрос
answer = lookup_knowledge("Как разогнать RTX 5060 Ti?")
print(answer)

# С указанием режима
answer = lookup_knowledge(
    query="Структура WORLD_OLLAMA",
    mode="local",
    timeout=90
)

# Обработка ошибок
try:
    answer = lookup_knowledge("Мой вопрос")
except CortexConnectionError as e:
    print(f"CORTEX offline: {e}")
except CortexQueryError as e:
    print(f"Query failed: {e}")
```

### `check_cortex_health()`

Проверка здоровья CORTEX сервера.

**Возвращает:**
- `dict` — `{"status": "healthy", "working_dir_exists": True, ...}`

**Исключения:**
- `CortexConnectionError` — Сервер недоступен

### `batch_lookup(queries, mode="hybrid")`

Пакетный запрос нескольких вопросов (последовательно).

**Аргументы:**
- `queries` (list[str]) — Список запросов
- `mode` (str) — Режим поиска (один для всех)

**Возвращает:**
- `list[str]` — Список ответов

---

## 🔌 Интеграция с агентами

### Open WebUI Tool Integration

1. **Импорт tool definition:**
   - Откройте Open WebUI → Settings → Tools
   - Import `synapse_tool_def.json`
   - Активируйте инструмент `lookup_knowledge`

2. **Использование в чате:**
   ```
   User: Расскажи про структуру WORLD_OLLAMA
   
   Agent: [вызывает lookup_knowledge("структура WORLD_OLLAMA")]
   Agent: Согласно базе знаний, WORLD_OLLAMA имеет следующую структуру...
   ```

### Ollama Functions API

```python
import ollama

# Регистрация функции
tools = [{
    "type": "function",
    "function": {
        "name": "lookup_knowledge",
        "description": "Search WORLD_OLLAMA knowledge base",
        "parameters": {
            "type": "object",
            "properties": {
                "query": {"type": "string"}
            },
            "required": ["query"]
        }
    }
}]

# Чат с инструментом
response = ollama.chat(
    model="qwen2.5:14b-instruct-q4_k_m",
    messages=[{"role": "user", "content": "Что такое WORLD_OLLAMA?"}],
    tools=tools
)

# Если агент вызвал функцию
if response['message'].get('tool_calls'):
    for tool in response['message']['tool_calls']:
        if tool['function']['name'] == 'lookup_knowledge':
            query = tool['function']['arguments']['query']
            result = lookup_knowledge(query)
            # Отправить результат обратно агенту
```

### Прямое использование в скрипте

```python
from knowledge_client import lookup_knowledge

# Агент-скрипт с доступом к знаниям
def ai_assistant(user_question):
    # Агент решает, нужна ли база знаний
    if "WORLD_OLLAMA" in user_question or "проект" in user_question:
        context = lookup_knowledge(user_question)
        # Используем контекст для ответа
        return f"На основе базы знаний: {context}"
    else:
        return "Отвечаю из параметров модели..."
```

---

## 📊 Performance & Limitations

### Производительность

| Режим | Время ответа | Точность | Рекомендации |
|-------|-------------|----------|--------------|
| `naive` | 10-20s | ⭐⭐⭐ | Простые fact-based вопросы |
| `local` | 20-30s | ⭐⭐⭐⭐ | Entity-based запросы |
| `global` | 30-45s | ⭐⭐⭐⭐ | Связи между концепциями |
| `hybrid` | 30-60s | ⭐⭐⭐⭐⭐ | Комплексные вопросы (рекомендуется) |

### Известные ограничения

⚠️ **Rerank отключен** (баг в LightRAG 1.4.9.8)
- Impact: Результаты не переранжируются по релевантности
- Workaround: Hybrid mode компенсирует качеством

⚠️ **5 документов pending** (1.5% не проиндексированы)
- Non-critical: 98.5% coverage достаточно
- Можно проиндексировать вручную через `/insert` API

⚠️ **Медленные запросы** (30-90s)
- Нормально для LLM generation (qwen2.5:14b)
- Используйте `timeout=120` или больше

---

## 🧪 Тестирование

### Запуск полного теста

```powershell
python test_synapse.py
```

### Быстрая проверка

```powershell
python knowledge_client.py
```

### Ручной тест

```python
from knowledge_client import lookup_knowledge

# Ваш тест
answer = lookup_knowledge("Тестовый запрос")
print(answer)
```

---

## 🐛 Troubleshooting

### Ошибка: "CORTEX недоступен"

**Решение:**
```powershell
# Запустить CORTEX
pwsh E:\WORLD_OLLAMA\scripts\start_lightrag.ps1

# Проверить статус
Invoke-RestMethod http://localhost:8004/health
```

### Ошибка: "Timeout после 120s"

**Причина:** LightRAG генерирует долго (особенно hybrid mode)

**Решение:**
```python
# Увеличить timeout
answer = lookup_knowledge(query, timeout=180)

# Или использовать быстрый режим
answer = lookup_knowledge(query, mode="naive")
```

### Ошибка: "Информация не найдена"

**Причины:**
1. Запрос слишком специфичный (нет в 331 документе)
2. Используйте другие термины
3. Проверьте покрытие: только 98.5% документов проиндексировано

**Решение:**
```python
# Попробуйте более общий запрос
answer = lookup_knowledge("Общая информация о проекте WORLD_OLLAMA")

# Или другой режим поиска
answer = lookup_knowledge(query, mode="global")
```

---

## 📝 Changelog

**v1.0.0** (25.11.2025) — TD-007 Initial Release
- ✅ Основной клиент `knowledge_client.py`
- ✅ Тестовый набор `test_synapse.py`
- ✅ OpenAPI/Ollama tool definition
- ✅ Обработка ошибок (timeout, connection, query errors)
- ✅ Batch lookup support
- ✅ Health check функция

---

## 🎯 Next Steps (Future Enhancements)

- [ ] **TD-008:** Интеграция в Open WebUI как встроенный инструмент
- [ ] **TD-009:** Async версия клиента (для FastAPI integration)
- [ ] **TD-010:** Caching слой (избегать повторных запросов)
- [ ] **TD-011:** Streaming responses (chunk-by-chunk вывод)
- [ ] **TD-012:** Multi-modal queries (изображения + текст)

---

**Status:** ✅ OPERATIONAL  
**Created:** 25.11.2025 (TD-007)  
**Author:** SESA3002a + GitHub Copilot  
**Принцип ТРИЗ:** №24 "Посредник"
