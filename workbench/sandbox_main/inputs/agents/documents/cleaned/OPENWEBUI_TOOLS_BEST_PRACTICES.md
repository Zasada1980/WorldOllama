# Open WebUI Tools: Best Practices & Troubleshooting

**Дата создания:** 2025-11-24  
**Версия Open WebUI:** 0.6.36  
**Источник знаний:** Практический опыт разработки librarian_tool_v2.py

---

## 📋 Критические требования

### 1. Формат инструмента (Tool Format)

**Open WebUI 0.6.x требует FUNCTION-BASED формат:**

```python
# ✅ ПРАВИЛЬНО (Open WebUI 0.6.x)
"""
title: My Tool Name
description: Short description
version: 1.0.0
author: Your Name
"""

import requests

def my_function(param: str) -> str:
    """Function description"""
    # Implementation
    return result
```

**УСТАРЕВШИЙ формат (НЕ РАБОТАЕТ в 0.6.x):**

```python
# ❌ НЕПРАВИЛЬНО (старый формат)
class Tools:
    """
    Long description that will appear on start page instead of working
    """
    def my_function(self, param: str):
        # Implementation
        return result
```

**Симптомы неправильного формата:**
- Инструмент установлен в БД, но не работает
- Docstring класса появляется на стартовой странице
- JavaScript ошибка: `Cannot read properties of null (reading 'length')`

---

### 2. Timestamp формат (КРИТИЧНО!)

**Open WebUI использует Pydantic validation и ожидает INTEGER Unix timestamps:**

```python
# ✅ ПРАВИЛЬНО
import time

TOOL_METADATA = {
    "created_at": int(time.time()),  # 1763989855
    "updated_at": int(time.time())   # 1763989855
}
```

**НЕПРАВИЛЬНО (вызывает ValidationError):**

```python
# ❌ НЕПРАВИЛЬНО
from datetime import datetime

TOOL_METADATA = {
    "created_at": datetime.now().isoformat(),  # "2025-11-24T15:00:19.654168"
    "updated_at": datetime.now().isoformat()   # СТРОКА вместо ЧИСЛА
}
```

**Ошибка при неправильном формате:**
```
pydantic_core._pydantic_core.ValidationError: 2 validation errors for ToolModel
updated_at
  Input should be a valid integer, unable to parse string as an integer
  [type=int_parsing, input_value='2025-11-24T15:00:19.654168', input_type=str]
created_at
  Input should be a valid integer, unable to parse string as an integer
  [type=int_parsing, input_value='2025-11-24T15:00:19.654168', input_type=str]
```

**Последствия:**
- HTTP 500 Internal Server Error на `/api/v1/tools/`
- HTTP 500 на `/api/v1/tools/list`
- UI показывает: `Uncaught TypeError: Cannot read properties of null (reading 'length')`
- Все инструменты перестают работать (даже установленные ранее корректно)

---

### 3. Схема базы данных

**Таблица `tool` в webui.db:**

```sql
CREATE TABLE tool (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,           -- ОБЯЗАТЕЛЬНО! Foreign key to user.id
    name TEXT NOT NULL,
    content TEXT NOT NULL,            -- Python код инструмента
    specs TEXT NOT NULL,              -- JSON array спецификаций (может быть [])
    meta TEXT,                        -- JSON метаданных
    updated_at INTEGER NOT NULL,      -- Unix timestamp (НЕ строка!)
    created_at INTEGER NOT NULL,      -- Unix timestamp (НЕ строка!)
    FOREIGN KEY (user_id) REFERENCES user(id)
);
```

**Обязательные поля при INSERT:**
- `user_id` — получить из `SELECT id FROM user LIMIT 1`
- `specs` — JSON array, минимум `"[]"`
- `updated_at` — `int(time.time())`
- `created_at` — `int(time.time())`

---

## 🔧 Пример правильного скрипта установки

```python
import sqlite3
import json
from pathlib import Path
import time  # ← ВАЖНО: для Unix timestamp

DB_PATH = Path(r"E:\AGENTS\open-webui-bridge\data\webui.db")
TOOL_FILE = Path(r"E:\AGENTS\librarian-agent\openwebui\librarian_tool_v2.py")

TOOL_METADATA = {
    "id": "my_tool_id",
    "name": "My Tool Name",
    "description": "Short description",
    "version": "1.0.0",
    "author": "Your Name",
    "created_at": int(time.time()),  # ← Unix timestamp
    "updated_at": int(time.time())   # ← Unix timestamp
}

def install_tool():
    with open(TOOL_FILE, 'r', encoding='utf-8') as f:
        tool_code = f.read()
    
    conn = sqlite3.connect(str(DB_PATH))
    cursor = conn.cursor()
    
    # Получить user_id
    cursor.execute("SELECT id FROM user LIMIT 1")
    user_row = cursor.fetchone()
    if not user_row:
        raise ValueError("No users in database")
    user_id = user_row[0]
    
    # Вставить инструмент
    cursor.execute("""
        INSERT OR REPLACE INTO tool (id, user_id, name, content, specs, meta, updated_at, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        TOOL_METADATA["id"],
        user_id,
        TOOL_METADATA["name"],
        tool_code,
        json.dumps([]),  # specs (пустой array)
        json.dumps({
            "description": TOOL_METADATA["description"],
            "version": TOOL_METADATA["version"],
            "author": TOOL_METADATA["author"]
        }),
        TOOL_METADATA["updated_at"],  # INTEGER!
        TOOL_METADATA["created_at"]   # INTEGER!
    ))
    
    conn.commit()
    conn.close()
    print("✅ Tool installed successfully")

if __name__ == "__main__":
    install_tool()
```

---

## 🐛 Диагностика проблем

### Ошибка 500 на `/api/v1/tools/`

**Симптомы:**
```javascript
GET http://localhost:3000/api/v1/tools/ 500 (Internal Server Error)
error-handling.js:68 Uncaught TypeError: Cannot read properties of null (reading 'length')
```

**Проверка логов Docker:**
```powershell
docker logs open-webui --tail 50 | Select-String "ValidationError"
```

**Если видите:**
```
pydantic_core._pydantic_core.ValidationError: 2 validation errors for ToolModel
updated_at
  Input should be a valid integer, unable to parse string as an integer
```

**Решение:**
1. Проверить формат timestamp в БД:
```python
import sqlite3
conn = sqlite3.connect(r'E:\AGENTS\open-webui-bridge\data\webui.db')
cursor = conn.cursor()
cursor.execute("SELECT id, updated_at, created_at FROM tool")
for row in cursor.fetchall():
    print(f"ID: {row[0]}, Updated: {row[1]} (type: {type(row[1])}), Created: {row[2]} (type: {type(row[2])})")
conn.close()
```

2. Если timestamp'ы строки — удалить инструмент и переустановить:
```python
cursor.execute("DELETE FROM tool WHERE id='your_tool_id'")
conn.commit()
```

3. Переустановить с правильными timestamp'ами (см. пример выше)

4. Перезагрузить Open WebUI:
```powershell
docker restart open-webui
```

---

### Инструмент не появляется в UI

**Проверка наличия в БД:**
```python
cursor.execute("SELECT id, name, LENGTH(content) FROM tool WHERE id='your_tool_id'")
print(cursor.fetchone())
```

**Если есть в БД, но не в UI:**
- Перезагрузить Open WebUI: `docker restart open-webui`
- Очистить кэш браузера (Ctrl+Shift+Delete)
- Проверить логи на ошибки валидации

---

### Docstring появляется на стартовой странице

**Причина:** Используется class-based формат вместо function-based.

**Решение:** Переписать инструмент в function-based формат (см. раздел "Формат инструмента").

---

## 📚 Метаданные в docstring заголовке

**Обязательные поля:**
```python
"""
title: Tool Name              # Название в UI
description: Short text       # Краткое описание
version: 1.0.0                # Версия (semver)
"""
```

**Опциональные:**
```python
"""
title: Tool Name
description: Short text
version: 1.0.0
author: Your Name             # Автор
license: MIT                  # Лицензия
required_open_webui_version: 0.6.0  # Минимальная версия Open WebUI
"""
```

**НЕ добавлять длинные инструкции в docstring заголовок** — они появятся на стартовой странице!

---

## 🎯 Функции инструмента

### Сигнатуры функций

**Type hints обязательны:**
```python
# ✅ Правильно
def search(query: str, mode: str = "hybrid") -> str:
    """Search in knowledge base"""
    return results

# ❌ Неправильно (нет типов)
def search(query, mode="hybrid"):
    return results
```

### Docstrings функций

**Краткий формат:**
```python
def function_name(param: str) -> str:
    """
    One-line description of what function does.
    
    Args:
        param: Parameter description
    
    Returns:
        Description of return value
    """
    # Implementation
```

**Open WebUI использует docstring для:**
- Показа подсказок в UI
- Автогенерации документации
- Валидации параметров

---

## 🔍 Debugging Best Practices

### 1. Проверка сервера LightRAG/FastAPI перед установкой
```powershell
curl http://localhost:8003/health
# Ожидаемый ответ: {"status":"healthy"}
```

### 2. Проверка формата инструмента
```python
# Прочитать содержимое tool файла
with open(TOOL_FILE, 'r', encoding='utf-8') as f:
    content = f.read()
    
# Проверить наличие title в первых 5 строках
lines = content.split('\n')[:5]
has_title = any('title:' in line for line in lines)
print(f"Function-based format: {has_title}")
```

### 3. Мониторинг VRAM для LightRAG
```powershell
nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits
# Если < 6000 MB → модели не загружены → LightRAG не работает
```

### 4. Проверка доступности API endpoint'ов
```powershell
curl http://localhost:8003/openapi.json | ConvertFrom-Json | Select-Object -ExpandProperty paths | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
```

---

## 📊 Чек-лист перед установкой инструмента

- [ ] Формат: function-based (не class-based)
- [ ] Метаданные: `title`, `description`, `version` в docstring заголовке
- [ ] Type hints: все параметры и возвращаемые значения типизированы
- [ ] Timestamp: `int(time.time())` для `created_at` и `updated_at`
- [ ] user_id: получен из `SELECT id FROM user LIMIT 1`
- [ ] specs: минимум пустой JSON array `[]`
- [ ] Backend API: сервер запущен и отвечает на `/health`
- [ ] VRAM: > 6 GB если используется LLM/embeddings

---

## 🎓 Извлеченные уроки

### 1. Pydantic strict validation
Open WebUI использует Pydantic с **strict mode**, поэтому:
- Строки НЕ конвертируются автоматически в числа
- ISO datetime строки НЕ парсятся в timestamp
- Типы данных должны **точно совпадать** с схемой модели

### 2. Python кэширование
После изменения `.py` файлов сервера:
```powershell
# Удалить __pycache__ перед перезапуском
Remove-Item __pycache__ -Recurse -Force -ErrorAction SilentlyContinue
```

### 3. Docker перезагрузка необходима
После изменений в `webui.db`:
```powershell
docker restart open-webui
```
Без перезагрузки FastAPI кэширует старые данные из БД.

### 4. Все инструменты ломаются из-за одного
Если хотя бы ОДИН инструмент в БД имеет неправильный формат timestamp — **весь API /api/v1/tools/ возвращает 500**.

**Решение:** Валидировать ВСЕ инструменты перед установкой нового:
```python
cursor.execute("SELECT id, updated_at, created_at FROM tool")
for row in cursor.fetchall():
    if not isinstance(row[1], int) or not isinstance(row[2], int):
        print(f"⚠️ Invalid timestamps in tool: {row[0]}")
```

---

## 🔗 Полезные ресурсы

- **Open WebUI API Schema:** `http://localhost:3000/docs`
- **Pydantic docs:** https://docs.pydantic.dev/
- **SQLite browser:** DB Browser for SQLite для просмотра `webui.db`
- **FastAPI debugging:** Логи в `docker logs open-webui`

---

**Версия документа:** 1.0  
**Дата последнего обновления:** 2025-11-24  
**Проверено на:** Open WebUI 0.6.36, Pydantic 2.11

