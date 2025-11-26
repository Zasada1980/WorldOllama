# SESA-LightRAG Connector

Песочное рабочее пространство для запуска моста `agent_bridge.py`, который
подключает агента SESA3002a к локальной библиотеке знаний LightRAG.

## Структура

```
connector/
├── README.md
└── python/
    ├── agent_bridge.py
    └── library_client.py
```

## Требования
- Python 3.11+
- `requests>=2.31.0`
- Запущенный LightRAG сервер (по умолчанию `http://localhost:8003`)

Установка зависимостей (внутри песочницы):

```powershell
cd E:\WORLD_OLLAMA\workbench\sandbox_main\connector\python
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install requests>=2.31.0
```

## Запуск LightRAG health-check

```powershell
python agent_bridge.py
```

Скрипт автоматически:
1. Проверит `health` и `status` LightRAG.
2. Выполнит гибридный поиск по примеру задачи.
3. Сымитирует запись решения (insert) назад в базу знаний.

## Кастомизация
- Чтобы использовать собственный запрос, отредактируйте переменную `problem`
  внутри `agent_bridge.py` или оберните класс `SESAKnowledgeConnector` в свой
  модуль.
- Для альтернативного URL задайте переменную окружения
  `KNOWLEDGE_LIBRARY_URL` и обновите константу `LIBRARY_URL` при необходимости.
