# 🧠 AI Knowledge Library

**Централизованная библиотека знаний для AI агентов на основе LightRAG GraphRAG**

Plug-and-play репозиторий с готовыми коннекторами для интеграции в любой AI проект за **3 минуты**.

## ✨ Особенности

- 📊 **377+ документов** по AI/ML разработке (96.7% индексация)
- 🕸️ **Graph RAG**: 3.7 MB граф знаний + 27.7 MB векторная БД сущностей
- 🔌 **Готовые SDK**: Python и TypeScript клиенты
- 🚀 **REST API**: Простая интеграция через HTTP
- 🤖 **Multi-agent ready**: Используется в AGENTS экосистеме

## 🚀 Quick Start (3 минуты)

### Вариант 1: Python SDK (рекомендуется)

```bash
# 1. Скопируйте клиент в свой проект
curl -O https://raw.githubusercontent.com/Zasada1980/PRICE_PC/main/connector/python/library_client.py

# 2. Используйте в коде
```

```python
from library_client import KnowledgeLibrary

# Инициализация клиента
library = KnowledgeLibrary("http://localhost:8003")

# Проверка доступности
if library.health_check():
    print("✅ Сервер доступен")

# Запрос к библиотеке
result = library.query(
    query="Что такое ТРИЗ? Расскажи основные принципы",
    mode="hybrid"  # naive, local, global, hybrid
)
print(result['response'])

# Получение статуса индексации
status = library.get_status()
print(f"Обработано: {status['processed']}/{status['total_docs']}")
```

### Вариант 2: TypeScript SDK

```bash
# 1. Скопируйте клиент
curl -O https://raw.githubusercontent.com/Zasada1980/PRICE_PC/main/connector/typescript/library-client.ts

# 2. Используйте
```

```typescript
import { KnowledgeLibraryClient } from './library-client';

const library = new KnowledgeLibraryClient("http://localhost:8003");

// Проверка доступности
await library.healthCheck();

// Запрос
const result = await library.query(
  "Расскажи про LangGraph",
  "hybrid"
);
console.log(result.response);
```

### Вариант 3: Прямой REST API

```bash
# Запрос к библиотеке
curl -X POST http://localhost:8003/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Как работает LightRAG?",
    "mode": "hybrid"
  }'

# Статус индексации
curl http://localhost:8003/status

# Health check
curl http://localhost:8003/health
```

## 📚 Режимы поиска

| Режим | Описание | Скорость | Качество | Использование |
|-------|----------|----------|----------|---------------|
| **`naive`** | Векторный поиск по embedding | ⚡ Быстро | ⭐⭐⭐ | Простые вопросы |
| **`local`** | Локальный граф (сущности + окружение) | 🔥 Средне | ⭐⭐⭐⭐ | Контекстуальные вопросы |
| **`global`** | Глобальный граф (широкий охват) | 🐌 Медленно | ⭐⭐⭐⭐⭐ | Сложные связи |
| **`hybrid`** | Комбинация всех методов | 🔥 Средне | ⭐⭐⭐⭐⭐ | **Рекомендуется ✨** |

## 🗂️ Структура репозитория

```
ai-knowledge-library/
├── documents/              # 377+ исходных .txt файлов библиотеки
├── connector/              # SDK для интеграции
│   ├── python/             # Python клиент (library_client.py)
│   │   └── library_client.py
│   └── typescript/         # TypeScript клиент (library-client.ts)
│       └── library-client.ts
├── graph/                  # Экспорт графа знаний (3.7 MB)
│   └── knowledge_graph.graphml
├── tools/                  # Утилиты для работы с репозиторием
│   └── sync_documents.ps1  # Auto-sync Documents → GitHub
└── api/                    # OpenAPI спецификация REST API
    └── openapi.yaml
```

## 📖 Содержимое библиотеки

**377 документов** (96.7% индексация, 13 failed) по AI/ML разработке:

### Тематики:
- 🤖 **AI Frameworks**: LangGraph, CrewAI, LightRAG, Autogen
- 💬 **LLM Engineering**: Промпт-инжиниринг, системные промпты, RAG паттерны
- 🧠 **Методологии**: ТРИЗ для AI разработки, Agent Design Patterns
- 🌐 **Real-time**: WebSocket streaming, SSE, async архитектуры
- 🐳 **DevOps**: Docker, DevContainers, CI/CD для AI проектов
- 🎮 **GPU**: Оптимизация VRAM, overclocking, мониторинг (RTX 5060 Ti 16GB)
- 📊 **Data Processing**: Parsing, scoring, database optimization
- 🔧 **Tools**: Ollama, Open WebUI, LightRAG server setup

### Статистика граф знаний:
- **graph_chunk_entity_relation.graphml**: 3.7 MB (3792 KB)
- **vdb_entities.json**: 27.7 MB (28364 KB) — векторная БД сущностей
- **kv_store_full_docs.json**: 5.5 MB — полные тексты документов
- **Среднее**: 2.61 sub-chunks на документ (max 3)

## 🔌 Примеры интеграции

### Интеграция с Open WebUI (Tool)

Создайте новый Tool в Open WebUI → Settings → Tools:

```python
import requests

def search_knowledge_library(query: str, mode: str = "hybrid") -> str:
    """
    Поиск в централизованной библиотеке знаний AI агентов
    
    :param query: Вопрос на русском языке
    :param mode: naive/local/global/hybrid (по умолчанию hybrid)
    :return: Ответ из базы знаний
    """
    response = requests.post(
        "http://localhost:8003/query",
        json={"query": query, "mode": mode},
        timeout=60
    )
    return response.json()["response"]
```

### Интеграция с ChatGPT (Custom GPT)

**Instructions:**
```
You have access to AI Knowledge Library — knowledge graph with 377 documents about AI/ML development.

Use this API to answer questions:
- POST http://your-public-url:8003/query
- Body: {"query": "...", "mode": "hybrid"}
- Always use "hybrid" mode for best results
```

**Actions schema:**
```json
{
  "openapi": "3.0.0",
  "info": {"title": "AI Knowledge Library", "version": "1.0.0"},
  "servers": [{"url": "http://your-server:8003"}],
  "paths": {
    "/query": {
      "post": {
        "operationId": "queryKnowledge",
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "properties": {
                  "query": {"type": "string"},
                  "mode": {"type": "string", "enum": ["hybrid"]}
                }
              }
            }
          }
        }
      }
    }
  }
}
```

### Интеграция с CrewAI Agent

```python
from crewai import Agent, Task, Crew
from library_client import KnowledgeLibrary

# Инициализация библиотеки
library = KnowledgeLibrary("http://localhost:8003")

# Создание агента с доступом к библиотеке
researcher = Agent(
    role="AI Research Specialist",
    goal="Find answers in centralized knowledge library",
    backstory="Expert in AI/ML with access to 377+ documents",
    tools=[
        lambda query: library.query(query, mode="hybrid")
    ]
)

# Задача
task = Task(
    description="Найти информацию о ТРИЗ в контексте AI разработки",
    agent=researcher
)

crew = Crew(agents=[researcher], tasks=[task])
result = crew.kickoff()
```

## 🚧 Roadmap

- [x] ✅ Базовая структура библиотеки
- [x] ✅ LightRAG индексация (377/390 документов, 96.7%)
- [x] ✅ Python SDK (`library_client.py`)
- [x] ✅ TypeScript SDK (`library-client.ts`)
- [x] ✅ Auto-sync скрипт (`sync_documents.ps1`)
- [ ] 🔄 OpenAPI спецификация (`api/openapi.yaml`)
- [ ] 🔄 GitHub Pages документация
- [ ] 🔄 Open WebUI Tool template
- [ ] 🔄 Export граф знаний → `graph/knowledge_graph.graphml`
- [ ] 🔄 Docker Compose для быстрого деплоя сервера
- [ ] 🔄 Примеры интеграции для: Claude Projects, Google Gemini, LangChain
- [ ] 🔄 Smart Reindexing с qwen2.5-4k (num_ctx=4096)
- [ ] 🔄 GPU Overclock Profile (+2500 MHz Memory Clock)

## 🛠️ Deployment

### Локальный сервер (уже запущен)

```powershell
# Запуск LightRAG сервера
cd E:\AI_Librarian_Core
python lightrag_server.py

# Сервер доступен: http://localhost:8003
# Health check: curl http://localhost:8003/health
```

### Docker (в разработке)

```bash
docker-compose up -d
# Сервер: http://localhost:8003
```

## ⚙️ Технологии

| Компонент | Технология | Версия/Модель |
|-----------|-----------|---------------|
| **GraphRAG** | LightRAG | Latest |
| **LLM** | Ollama + qwen2.5 | 14b-instruct-q4_k_m |
| **Embeddings** | nomic-embed-text | Latest |
| **API Server** | FastAPI | Python 3.11+ |
| **GPU** | RTX 5060 Ti 16GB | MSI Gaming OC |
| **SDK** | Python + TypeScript | Requests + Fetch API |

## 📝 Лицензия

MIT License

## 🤝 Контакты

Репозиторий создан для поддержки AI агентов в multi-agent системах.

---

**Powered by:** LightRAG + Ollama + RTX 5060 Ti 16GB
