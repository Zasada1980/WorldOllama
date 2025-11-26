# Быстрый старт интеграции библиотеки

## Шаг 1: Создать пользователя в Open WebUI

1. Открыть браузер: **http://localhost:3000**
2. Зарегистрироваться (первый пользователь = admin)
3. Войти в систему

## Шаг 2: Установить Tool

```powershell
cd E:\AGENTS
python agents_tools\install_library_tool_to_webui.py
```

**Ожидаемый результат:**
```
✅ Инструмент установлен успешно!
📚 Библиотека Знаний v2.0.0
```

## Шаг 3: Активировать в чате

1. Open WebUI → **Workspace** → **Tools**
2. Найти **"Библиотека Знаний"**
3. Нажать **Enable**

## Шаг 4: Использовать

В любом чате:

```python
search_library("Как настроить Ollama?")
```

---

## Для VS Code Copilot

### Настройка MCP

1. Установить зависимости:
```powershell
pip install mcp requests
```

2. Добавить в `settings.json`:
```json
{
  "github.copilot.advanced": {
    "mcp.servers": {
      "lightrag-library": {
        "command": "python",
        "args": ["E:\\AGENTS\\agents_tools\\mcp_library_server.py"],
        "env": {"LIGHTRAG_API_URL": "http://localhost:8003"}
      }
    }
  }
}
```

3. Перезапустить VS Code

4. Спросить Copilot: "Найди в библиотеке информацию про Ollama"

---

## Автоиндексация

```powershell
pip install watchdog
python agents_tools\auto_index_new_documents.py
```

**Добавить новый документ:**
```powershell
Copy-Item "my_doc.txt" "E:\AGENTS\Documents_cleaned\"
# Автоматически проиндексируется
```

---

## Полная документация

См. `E:\AGENTS\docs\LIBRARY_INTEGRATION_GUIDE.md`
