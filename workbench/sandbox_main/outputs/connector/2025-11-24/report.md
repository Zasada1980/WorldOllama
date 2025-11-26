# Connector Workspace Report — 2025-11-24

## Scope
- Создан каталог `scripts/knowledge_connector` с автономным Python SDK и CLI.
- Добавлены env-friendly настройки (`ConnectorConfig`) и пример запроса.
- Подготовлен `.env.example`, `requirements.txt`, README с runbook.

## Artifacts
| Тип | Файл |
|-----|------|
| SDK | `scripts/knowledge_connector/knowledge_connector/library_client.py` |
| CLI | `scripts/knowledge_connector/cli.py` |
| Docs | `scripts/knowledge_connector/README.md` |
| Sample | `scripts/knowledge_connector/examples/sample_query.txt` |
| Config | `scripts/knowledge_connector/.env.example` |

## How to Run
```powershell
cd E:\WORLD_OLLAMA\workbench\sandbox_main\scripts\knowledge_connector
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python cli.py --base-url http://localhost:8003 health
python cli.py query --query "Что такое LangGraph?"
python cli.py status
```

## Verification Status
- LightRAG сервер (порт 8003) недоступен в текущей сессии → фактические запросы не выполнялись.
- CLI выведет понятные ошибки сети, если сервер не поднят. После запуска `lightrag_server.py` повторите команды выше.

## Next Steps
1. Добавить unit-тесты с моками HTTP.
2. Портировать TypeScript SDK в `scripts/knowledge_connector/ts`.
3. Завести Playwright/Postman smoke-тест для `/query` и `/status`.
