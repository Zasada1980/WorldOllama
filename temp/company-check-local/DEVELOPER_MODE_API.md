# Developer Mode - Backend API Integration Guide

## Обзор

Developer Mode теперь подключен к реальным API вместо демо-данных. Все функции работают через REST API endpoints.

## 📁 Структура

```
src/
├── AdminPanel.tsx          # UI компонент Developer Mode
└── api/
    └── developerAPI.ts     # API клиент (все endpoints)
```

## 🔌 API Endpoints

### 1. File System API

**Base Path:** `/api/dev/files`

#### GET `/api/dev/files/tree`

Получить дерево файлов проекта.

**Response:**

```json
{
  "config": [
    { "name": "app.json", "path": "config/app.json", "type": "file", "size": 1024 }
  ],
  "src": [...]
}
```

#### GET `/api/dev/files/content?path=<filepath>`

Получить содержимое файла.

**Response:**

```json
{
  "content": "// file content here"
}
```

#### POST `/api/dev/files/save`

Сохранить файл.

**Request:**

```json
{
  "path": "config/app.json",
  "content": "{ \"app\": \"data\" }"
}
```

#### DELETE `/api/dev/files/delete`

Удалить файл.

**Request:**

```json
{
  "path": "config/old-file.json"
}
```

---

### 2. SQL Console API

**Base Path:** `/api/dev/sql`

#### POST `/api/dev/sql/execute`

Выполнить SQL запрос.

**Request:**

```json
{
  "query": "SELECT * FROM users LIMIT 10"
}
```

**Response:**

```json
{
  "columns": ["id", "email", "status"],
  "rows": [
    [1, "user@example.com", "active"],
    [2, "admin@example.com", "active"]
  ],
  "rowCount": 2
}
```

---

### 3. Terminal API

**Base Path:** `/api/dev/terminal`

#### POST `/api/dev/terminal/execute`

Выполнить команду в терминале.

**Request:**

```json
{
  "command": "ls -la"
}
```

**Response:**

```json
{
  "output": "total 64\ndrwxr-xr-x  12 user  staff   384 Dec  8 14:30 .\n..."
}
```

---

### 4. System Monitor API

**Base Path:** `/api/dev/monitor`

#### GET `/api/dev/monitor/metrics`

Получить метрики системы (CPU, RAM, Disk).

**Response:**

```json
{
  "cpu": {
    "usage": 45.3,
    "cores": 8,
    "model": "Intel Core i7"
  },
  "memory": {
    "total": 16384,
    "used": 10240,
    "free": 6144,
    "usagePercent": 62.5
  },
  "disk": {
    "total": 512000,
    "used": 256000,
    "free": 256000
  }
}
```

#### GET `/api/dev/monitor/env`

Получить environment variables.

**Response:**

```json
[
  { "key": "NODE_ENV", "value": "production", "masked": false },
  { "key": "DATABASE_URL", "value": "postgres://****", "masked": true }
]
```

---

### 5. API Playground

**Proxy для любых API запросов**

#### POST `/api/dev/playground/request`

Отправить произвольный HTTP запрос.

**Request:**

```json
{
  "method": "GET",
  "url": "/api/companies/515972651",
  "body": null
}
```

**Response:**

```json
{
  "status": 200,
  "statusText": "OK",
  "headers": { "content-type": "application/json" },
  "data": { "id": "515972651", "name": "..." }
}
```

---

### 6. Job Queues API

**Base Path:** `/api/dev/jobs`

#### GET `/api/dev/jobs`

Получить список фоновых задач.

**Response:**

```json
[
  {
    "id": "1",
    "name": "Generate PDF Report",
    "status": "completed",
    "progress": 100,
    "createdAt": "2024-12-08T14:20:00Z",
    "completedAt": "2024-12-08T14:22:00Z"
  },
  {
    "id": "2",
    "name": "Process AI Analysis",
    "status": "running",
    "progress": 45,
    "createdAt": "2024-12-08T14:25:00Z"
  }
]
```

#### POST `/api/dev/jobs/{id}/retry`

Повторить failed задачу.

---

### 7. Webhooks API

**Base Path:** `/api/dev/webhooks`

#### POST `/api/dev/webhooks/trigger`

Триггернуть webhook событие.

**Request:**

```json
{
  "event": "payment.success",
  "payload": {
    "user_id": 123,
    "amount": 99.0,
    "currency": "USD"
  }
}
```

---

## 🛠️ Fallback Strategy

Если backend недоступен, система автоматически использует **демо-данные**:

```typescript
try {
  const response = await fetch(`${API_BASE}/api/dev/files/tree`);
  return await response.json();
} catch (error) {
  // Fallback на демо
  return {
    config: [
      /* demo files */
    ],
    src: [
      /* demo files */
    ],
  };
}
```

## 🚀 Deployment

### Frontend (уже задеплоено)

```bash
cd e:\WORLD_OLLAMA\temp\company-check-local
npm run build
scp -r dist/* root@46.224.36.109:/var/www/html/company-check/
```

### Backend (нужно реализовать)

Создайте Express/FastAPI сервер с endpoints:

**Express.js пример:**

```javascript
const express = require("express");
const app = express();

app.get("/api/dev/files/tree", (req, res) => {
  // Реальная логика чтения файловой системы
  const tree = getProjectFileTree();
  res.json(tree);
});

app.post("/api/dev/sql/execute", (req, res) => {
  const { query } = req.body;
  // Выполнение SQL через pg/mysql
  const result = executeSQL(query);
  res.json(result);
});

// ... остальные endpoints
```

**Python FastAPI пример:**

```python
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

@app.get("/api/dev/files/tree")
async def get_file_tree():
    # Реальная логика
    return {
        "config": [...],
        "src": [...]
    }

@app.post("/api/dev/sql/execute")
async def execute_sql(query: str):
    # SQL execution
    result = db.execute(query)
    return {
        "columns": result.columns,
        "rows": result.rows,
        "rowCount": len(result.rows)
    }
```

## 🔒 Security

**ВАЖНО:** Все Developer Mode endpoints должны быть защищены:

1. **Authentication:** Только админы
2. **SQL Injection:** Параметризованные запросы
3. **File Access:** Ограничение на project root
4. **Terminal Commands:** Whitelist разрешенных команд
5. **Rate Limiting:** Защита от злоупотреблений

```javascript
// Middleware example
app.use("/api/dev/*", requireAdminAuth);
app.use("/api/dev/*", rateLimiter({ max: 100, windowMs: 60000 }));
```

## 📊 Monitoring

Developer Mode использует **polling** каждые 2 секунды для:

- CPU/RAM метрик
- Job Queue статусов

Оптимизация: рассмотрите **WebSocket** для real-time обновлений.

## 🐛 Troubleshooting

### Проблема: "Cannot fetch file tree"

**Решение:** Проверьте CORS настройки backend:

```javascript
app.use(
  cors({
    origin: "http://46.224.36.109",
    credentials: true,
  })
);
```

### Проблема: SQL запросы не выполняются

**Решение:** Проверьте database connection string в env переменных.

### Проблема: Terminal команды timeout

**Решение:** Увеличьте timeout для долгих команд (npm install, git clone).

---

## 📝 TODO (Backend Implementation)

- [ ] Создать Express/FastAPI сервер
- [ ] Реализовать File System endpoints
- [ ] Подключить SQL Console к БД
- [ ] Настроить Terminal executor (с whitelisting)
- [ ] Добавить System Monitor (os module)
- [ ] Настроить Job Queue (Bull/Celery)
- [ ] Webhook trigger logic
- [ ] Security middleware (auth + rate limiting)
- [ ] WebSocket для real-time updates
- [ ] Logging и error handling

---

**Статус:** ✅ Frontend готов и задеплоен  
**Требуется:** Backend implementation для полного функционала
