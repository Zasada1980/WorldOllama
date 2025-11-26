# Knowledge Connector Sandbox Workspace

Этот каталог содержит полностью автономную копию Python-коннектора к библиотеке знаний LightRAG.

## Структура

```
scripts/knowledge_connector/
├── README.md                 # этот файл
├── requirements.txt          # зависимости (requests)
├── cli.py                    # CLI для health/query/status
├── knowledge_connector/
│   ├── __init__.py
│   └── library_client.py     # SDK-клиент с env-поддержкой
└── examples/
    └── sample_query.txt      # текст для быстрого теста CLI
```

## Быстрый старт

```powershell
cd E:\WORLD_OLLAMA\workbench\sandbox_main\scripts\knowledge_connector
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### Проверка доступности API

```powershell
python cli.py --base-url http://localhost:8003 health
```

### Отправка запроса

```powershell
python cli.py --base-url http://localhost:8003 query --query "Что такое LangGraph?"
```

или использовать файл с запросом:

```powershell
python cli.py query --query-file examples\sample_query.txt
```

### Статус индексации

```powershell
python cli.py status
```

## Использование в других проектах

```python
from knowledge_connector import KnowledgeLibrary

client = KnowledgeLibrary.from_env()  # читает KNOWLEDGE_LIBRARY_URL
answer = client.query("Расскажи про LightRAG", mode="hybrid")
print(answer.get("response"))
```

## TODO
- [ ] TypeScript паритет (использовать PRICE_PC/connector/typescript для портирования)
- [ ] Автотест, мокирующий HTTP ответы
- [ ] GitHub Action для линта перед выносом из песочницы
