# API Коннектор для библиотеки знаний

Эта папка содержит SDK клиенты для разных языков программирования.

## Доступные клиенты

### ✅ Python
- **Файл:** `python/library_client.py`
- **Требования:** `requests>=2.31.0`
- **Пример:** `python/example.py`

```bash
cd connector/python
pip install -r requirements.txt
python example.py
```

### 🚧 TypeScript (в разработке)
- Будет поддерживать async/await
- Типизация через TypeScript
- Совместимость с Node.js и браузером

## Быстрый старт

### Python

```python
from library_client import KnowledgeLibrary

library = KnowledgeLibrary(base_url="http://localhost:8003")
result = library.query("Что такое ТРИЗ?", mode="hybrid")
print(result)
```

### cURL (для тестирования)

```bash
# Запрос к библиотеке
curl -X POST http://localhost:8003/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Расскажи про LangGraph",
    "mode": "hybrid"
  }'

# Проверка статуса
curl http://localhost:8003/status

# Health check
curl http://localhost:8003/health
```

## API Endpoints

| Endpoint | Method | Описание |
|----------|--------|----------|
| `/query` | POST | Запрос к графу знаний |
| `/insert` | POST | Добавить документ |
| `/status` | GET | Статус индексации |
| `/health` | GET | Проверка работоспособности |

## Режимы поиска

- **`naive`** — Векторный поиск (самый быстрый)
- **`local`** — Локальный граф (контекстуальный)
- **`global`** — Глобальный граф (широкий охват)
- **`hybrid`** — Комбинированный (рекомендуется)

## Создание своего клиента

Базовый пример на любом языке:

```javascript
// Пример на JavaScript
const response = await fetch('http://localhost:8003/query', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    query: "Что такое ТРИЗ?",
    mode: "hybrid"
  })
});

const result = await response.json();
console.log(result.response);
```

## Требования к серверу

- **LightRAG Server** на порту 8003
- **Ollama** с моделью `qwen2.5:14b-instruct-q4_k_m`
- **VRAM:** ~11-12 GB для полной работы
