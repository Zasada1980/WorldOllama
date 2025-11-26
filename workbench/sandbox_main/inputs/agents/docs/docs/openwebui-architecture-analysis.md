# Архитектура и точки интеграции Open WebUI

## 1. Общая архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                    Open WebUI Container                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────┐         ┌──────────────────┐           │
│  │   Frontend       │◄────────┤   Backend API    │           │
│  │   (SvelteKit)    │         │   (FastAPI)      │           │
│  │   /app/build/    │         │   /app/backend/  │           │
│  └─────────────────┘         └──────────────────┘           │
│         │                            │                        │
│         │                            ▼                        │
│         │                    ┌──────────────────┐            │
│         │                    │   SQLite DB      │            │
│         │                    │   webui.db       │            │
│         │                    └──────────────────┘            │
│         │                            │                        │
│         └────────────────────────────┘                        │
│                                                               │
└─────────────────────────────────────────────────────────────┘
                    │                       │
                    ▼                       ▼
        ┌──────────────────┐   ┌──────────────────┐
        │   Ollama Server  │   │   Внешние API    │
        │   port 11435     │   │   OpenAI, etc.   │
        └──────────────────┘   └──────────────────┘
                    │
                    ▼
        ┌──────────────────────────┐
        │   Локальный агент        │
        │   E:\AGENTS\             │
        │   - agents_tools/        │
        │   - open-webui-bridge/   │
        └──────────────────────────┘
```

## 2. Структура Backend (FastAPI)

### 2.1. Основные компоненты

```
/app/backend/open_webui/
├── main.py                  # Главная точка входа FastAPI
├── config.py                # Конфигурация приложения
├── env.py                   # Переменные окружения
├── constants.py             # Константы
│
├── routers/                 # API эндпоинты
│   ├── auths.py            # Аутентификация (signup, signin)
│   ├── chats.py            # Управление чатами
│   ├── models.py           # Управление моделями
│   ├── prompts.py          # Промпты и шаблоны
│   ├── functions.py        # Python функции (Tools)
│   ├── tools.py            # Внешние инструменты
│   ├── files.py            # Файлы и загрузки
│   ├── retrieval.py        # RAG и векторный поиск
│   ├── knowledge.py        # База знаний
│   ├── memories.py         # Память диалогов
│   ├── evaluations.py      # Оценка ответов
│   ├── pipelines.py        # Плагины через Pipelines
│   ├── ollama.py           # Интеграция Ollama
│   ├── openai.py           # OpenAI-совместимые API
│   ├── users.py            # Управление пользователями
│   ├── configs.py          # Конфигурации UI
│   ├── folders.py          # Папки для организации
│   ├── groups.py           # Группы пользователей
│   ├── tasks.py            # Фоновые задачи
│   ├── audio.py            # TTS/STT
│   ├── images.py           # Генерация изображений
│   └── utils.py            # Утилиты
│
├── models/                  # Модели данных (Pydantic)
│   ├── chats.py
│   ├── users.py
│   ├── functions.py
│   └── ...
│
├── utils/                   # Вспомогательные утилиты
│   ├── auth.py             # Авторизация JWT
│   ├── tools.py            # Утилиты для инструментов
│   ├── chat.py             # Обработка чатов
│   ├── files.py            # Работа с файлами
│   ├── embeddings.py       # Векторные эмбеддинги
│   ├── plugin.py           # Система плагинов
│   ├── mcp/                # Model Context Protocol
│   │   └── client.py
│   └── ...
│
├── retrieval/               # RAG система
│   ├── vector/             # Векторные БД
│   ├── loaders/            # Загрузчики документов
│   ├── web/                # Веб-поиск
│   └── models/             # Модели для RAG
│
├── storage/                 # Хранилище файлов
├── data/                    # Данные пользователей
│   ├── uploads/
│   ├── cache/
│   └── vector_db/
│
└── static/                  # Статические файлы
    ├── fonts/
    ├── assets/
    └── custom.css          # Кастомные стили
```

## 3. API Эндпоинты (ключевые)

### 3.1. Аутентификация (`/api/v1/auths/`)
- `POST /signup` — регистрация нового пользователя
- `POST /signin` — вход
- `POST /signout` — выход
- `GET /` — получить текущего пользователя

### 3.2. Чаты (`/api/v1/chats/`)
- `GET /` — список всех чатов пользователя
- `GET /{id}` — получить чат по ID
- `POST /new` — создать новый чат
- `POST /{id}` — обновить чат
- `DELETE /{id}` — удалить чат
- `POST /{id}/archive` — архивировать чат
- `POST /{id}/clone` — клонировать чат
- `GET /{id}/share` — поделиться чатом

### 3.3. Модели (`/api/v1/models/`)
- `GET /` — список доступных моделей
- `POST /add` — добавить модель
- `GET /{id}` — получить модель
- `POST /{id}/update` — обновить модель
- `DELETE /{id}/delete` — удалить модель

### 3.4. Functions/Tools (`/api/v1/functions/`)
- `GET /` — список всех функций
- `POST /create` — создать новую функцию (Python код)
- `GET /id/{id}` — получить функцию по ID
- `POST /id/{id}/update` — обновить функцию
- `DELETE /id/{id}/delete` — удалить функцию
- `POST /id/{id}/valves/update` — обновить параметры функции
- `POST /id/{id}/toggle` — включить/выключить функцию

### 3.5. Промпты (`/api/v1/prompts/`)
- `GET /` — список промптов
- `POST /create` — создать промпт
- `GET /{command}` — получить промпт по команде
- `POST /{command}/update` — обновить
- `DELETE /{command}/delete` — удалить

### 3.6. RAG/Retrieval (`/api/v1/retrieval/`)
- `POST /query/doc` — поиск в документах
- `POST /query/collection` — поиск в коллекции
- `POST /process/doc` — обработать документ для RAG
- `GET /config` — получить конфигурацию RAG

### 3.7. Knowledge Base (`/api/v1/knowledge/`)
- `GET /` — список баз знаний
- `POST /create` — создать базу знаний
- `POST /{id}/file/add` — добавить файл
- `POST /{id}/file/update` — обновить файл
- `GET /{id}/file/list` — список файлов

### 3.8. Files (`/api/v1/files/`)
- `POST /` — загрузить файл
- `GET /` — список файлов
- `GET /{id}` — скачать файл
- `DELETE /{id}` — удалить файл

### 3.9. Configs (`/api/v1/configs/`)
- `GET /` — получить все конфигурации
- `POST /` — обновить конфигурацию

### 3.10. Pipelines (`/api/v1/pipelines/`)
- `GET /` — список плагинов
- `POST /` — добавить pipeline
- `GET /{id}` — получить pipeline

## 4. Структура Frontend (SvelteKit)

```
/app/build/
├── index.html              # Главная страница
├── _app/                   # Приложение SvelteKit
│   ├── immutable/
│   │   ├── entry/
│   │   │   ├── start.js   # Инициализация
│   │   │   └── app.js     # Главное приложение
│   │   ├── chunks/         # Модули кода
│   │   └── nodes/          # Страницы/компоненты
│   └── version.json
│
├── static/                  # Статические ресурсы
│   ├── favicon.png
│   ├── splash.png
│   ├── custom.css          # Кастомные стили
│   └── loader.js
│
├── assets/                  # Скомпилированные ресурсы
├── themes/                  # Темы оформления
└── manifest.json           # PWA манифест
```

### 4.1. Основные маршруты (предположительно по nodes)
- `/` — главная страница (чат)
- `/auth` — аутентификация
- `/workspace` — рабочее пространство
  - `/workspace/models` — управление моделями
  - `/workspace/functions` — управление функциями
  - `/workspace/prompts` — управление промптами
  - `/workspace/knowledge` — база знаний
  - `/workspace/tools` — инструменты
- `/admin` — админ панель
  - `/admin/users` — пользователи
  - `/admin/settings` — настройки

## 5. База данных (SQLite)

**Расположение:** `/app/backend/data/webui.db`  
**Доступ через мост:** `E:\AGENTS\open-webui-bridge\data\webui.db`

### 5.1. Основные таблицы
- `user` — пользователи
- `auth` — сессии аутентификации
- `chat` — чаты
- `message` — сообщения в чатах
- `model` — модели LLM
- `function` — Python функции/инструменты
- `prompt` — шаблоны промптов
- `knowledge` — базы знаний
- `file` — загруженные файлы
- `config` — конфигурация приложения
- `document` — документы для RAG
- `tag` — теги
- `folder` — папки для организации

## 6. Конфигурация (переменные окружения)

**Файл:** `/app/backend/open_webui/env.py`

### 6.1. Ключевые переменные
```python
# Базовые
DATA_DIR = "/app/backend/data"
FRONTEND_BUILD_DIR = "/app/build"
DATABASE_URL = f"sqlite:///{DATA_DIR}/webui.db"

# Аутентификация
WEBUI_AUTH = True  # Включить/выключить авторизацию
WEBUI_SECRET_KEY = "secret_key"
WEBUI_JWT_SECRET_KEY = "jwt_secret"

# UI
WEBUI_NAME = "Open WebUI"
WEBUI_FAVICON_URL = "/static/favicon.png"

# Ollama
OLLAMA_BASE_URL = "http://host.docker.internal:11434"

# OpenAI
OPENAI_API_KEY = ""
OPENAI_API_BASE_URL = "https://api.openai.com/v1"

# RAG
CHUNK_SIZE = 1500
CHUNK_OVERLAP = 100
RAG_EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2"

# Pipelines
PIPELINES_URL = ""

# Redis (опционально)
REDIS_URL = ""
```

## 7. Точки интеграции агента

### 7.1. Прямой доступ к файлам (через мост)
```
E:\AGENTS\open-webui-bridge\
├── data\
│   ├── webui.db           # Прямое редактирование БД
│   ├── uploads\           # Загруженные файлы
│   ├── cache\             # Кэш
│   └── vector_db\         # Векторные индексы
└── static\
    └── custom.css         # Кастомные стили
```

### 7.2. API интеграция
```python
import requests

BASE_URL = "http://localhost:3000/api/v1"
TOKEN = "Bearer <jwt_token>"

# Создать функцию
response = requests.post(
    f"{BASE_URL}/functions/create",
    headers={"Authorization": TOKEN},
    json={
        "id": "custom_agent_tool",
        "name": "Custom Agent Tool",
        "content": "def execute():\n    return 'Hello from agent!'",
        "type": "function"
    }
)

# Создать промпт
response = requests.post(
    f"{BASE_URL}/prompts/create",
    headers={"Authorization": TOKEN},
    json={
        "command": "/agent",
        "title": "Agent Assistant",
        "content": "You are an AI agent...",
    }
)

# Добавить файл в knowledge base
with open("document.pdf", "rb") as f:
    response = requests.post(
        f"{BASE_URL}/files/",
        headers={"Authorization": TOKEN},
        files={"file": f}
    )
```

### 7.3. Pipelines (плагины)
**Концепция:** Внешний сервис, который обрабатывает запросы/ответы.

```python
# Запустить Pipeline сервер
# https://github.com/open-webui/pipelines

from pipelines import Pipeline

class CustomAgentPipeline(Pipeline):
    def pipe(self, body: dict) -> dict:
        # Модификация запроса
        user_message = body["messages"][-1]["content"]
        
        # Вызов локального агента
        agent_response = call_local_agent(user_message)
        
        # Возврат модифицированного ответа
        return {"messages": [{"role": "assistant", "content": agent_response}]}
```

### 7.4. Python Functions (встроенные инструменты)
**Через UI:** Workspace → Functions → Create Function

```python
# Пример функции-инструмента
"""
title: Local Agent Tool
author: Your Name
version: 1.0
"""

import subprocess
from typing import Callable

class Tools:
    def __init__(self):
        self.citation = True
        
    def execute_agent_command(
        self,
        command: str,
        __event_emitter__: Callable[[dict], None] = None
    ) -> str:
        """
        Execute local agent command
        :param command: Command to execute
        """
        
        if __event_emitter__:
            await __event_emitter__({
                "type": "status",
                "data": {"description": f"Executing: {command}"}
            })
        
        # Выполнить команду локального агента
        result = subprocess.run(
            ["python", "E:\\AGENTS\\agents_tools\\your_tool.py", command],
            capture_output=True,
            text=True
        )
        
        return result.stdout
```

### 7.5. Knowledge Base интеграция
1. **Через UI:** Workspace → Knowledge → Create
2. **Через API:** `POST /api/v1/knowledge/create`
3. **Прямое добавление в БД:**
   ```sql
   INSERT INTO knowledge (id, name, description, data)
   VALUES ('agent_kb', 'Agent Knowledge', 'Local agent docs', '{}');
   ```

### 7.6. Custom Static Page (инструкции)
**Путь:** `/app/backend/open_webui/static/agent-guide.html`  
**Доступ:** `http://localhost:3000/static/agent-guide.html`

## 8. Потоки данных

### 8.1. Запрос пользователя → ответ модели
```
User Input (Frontend)
    ↓
WebSocket /api/chat
    ↓
Backend Router (/routers/openai.py or /routers/ollama.py)
    ↓
[Optional] Pipelines Middleware
    ↓
[Optional] Functions/Tools Execution
    ↓
[Optional] RAG Retrieval (/retrieval/)
    ↓
LLM API (Ollama/OpenAI)
    ↓
Response Processing
    ↓
[Optional] Memory Storage (/memories/)
    ↓
Frontend Display
```

### 8.2. Загрузка файла для RAG
```
User Upload File
    ↓
POST /api/v1/files/
    ↓
Save to /app/backend/data/uploads/
    ↓
Process Document (/retrieval/loaders/)
    ↓
Create Embeddings (/utils/embeddings.py)
    ↓
Store in Vector DB (/data/vector_db/)
    ↓
Index for Search
```

## 9. Кастомизация UI

### 9.1. Через конфигурацию
**API:** `POST /api/v1/configs/`
```json
{
  "ui": {
    "default_models": ["llama3:8b"],
    "default_prompt_suggestions": [
      {"title": "Agent Help", "content": "How to use local agent?"}
    ]
  }
}
```

### 9.2. Через custom.css
**Файл:** `/app/backend/open_webui/static/custom.css`  
**Мост:** `E:\AGENTS\open-webui-bridge\static\custom.css`

```css
/* Кастомный цвет */
:root {
  --primary-color: #00ff00;
}

/* Добавить кнопку */
.custom-agent-button {
  background: linear-gradient(45deg, #667eea 0%, #764ba2 100%);
  padding: 10px 20px;
  border-radius: 8px;
}
```

### 9.3. Через модификацию HTML
**Файл:** `/app/build/index.html` (перестроить фронтенд)
Или инжектировать через:
```html
<!-- /app/backend/open_webui/static/custom-inject.js -->
<script>
document.addEventListener('DOMContentLoaded', () => {
  const btn = document.createElement('button');
  btn.textContent = 'Call Local Agent';
  btn.onclick = () => fetch('/api/v1/agent/execute');
  document.body.appendChild(btn);
});
</script>
```

## 10. Резюме точек интеграции

| Метод | Сложность | Персистентность | Использование |
|-------|-----------|-----------------|---------------|
| **Прямое редактирование БД** | Низкая | Да | Массовые операции, миграция данных |
| **REST API** | Средняя | Да | Автоматизация, внешние сервисы |
| **Pipelines** | Высокая | Да | Middleware обработка запросов |
| **Python Functions** | Средняя | Да | Встроенные инструменты для LLM |
| **Custom Static Files** | Низкая | Да | Документация, кастомные страницы |
| **Knowledge Base** | Средняя | Да | RAG интеграция, база знаний |
| **Environment Variables** | Низкая | Да (конфиг) | Базовая настройка |
| **Docker Volume Mount** | Низкая | Да | Прямой доступ к файлам |

## 11. Следующие шаги для агента

1. **Создать Python Function** для вызова локальных инструментов
2. **Настроить Pipeline** для препроцессинга запросов
3. **Добавить Knowledge Base** с документацией агента
4. **Создать Custom Page** с полными инструкциями
5. **Автоматизировать через API** создание промптов и функций
