# Быстрый тест Библиотеки Знаний v2.1.0

## 🎯 Цель
Проверить работу обновленного инструмента Open WebUI с новыми функциями (переиндексация + GitHub push).

---

## 📋 Pre-flight Checklist

### 1. Проверка сервера LightRAG
```powershell
# Проверка что сервер запущен
curl http://localhost:8003/health
# Ожидаемый ответ: {"status":"healthy"}

# Проверка новых endpoint'ов
curl http://localhost:8003/openapi.json | ConvertFrom-Json | Select-Object -ExpandProperty paths | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Sort-Object

# Должны быть:
# /api/git/push
# /api/reindex
```

### 2. Проверка VRAM (модели загружены?)
```powershell
nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits
# Должно быть >6000 MB (6 GB) если модели загружены
```

### 3. Проверка инструмента в БД
```powershell
cd E:\AGENTS\agents_tools
python -c "import sqlite3; conn = sqlite3.connect(r'E:\AGENTS\open-webui-bridge\data\webui.db'); cursor = conn.cursor(); cursor.execute('SELECT id, name, LENGTH(content) FROM tool WHERE id=\"librarian_knowledge_base\"'); print(cursor.fetchone()); conn.close()"
```

**Ожидаемый вывод:**
```
('librarian_knowledge_base', 'Библиотека Знаний LightRAG', <размер_в_байтах>)
```

---

## 🧪 Тестовые сценарии

### Тест 1: Активация инструмента в Open WebUI

**Шаги:**
1. Открыть браузер → `http://localhost:3000`
2. Войти в учетку (user: `admin@agents.local`)
3. Workspace → Tools (иконка инструментов слева)
4. Найти "Библиотека Знаний LightRAG"
5. Включить toggle переключатель

**Ожидаемый результат:**
- ✅ Инструмент появляется в списке
- ✅ Версия: 2.1.0
- ✅ Описание: "Поиск в локальной библиотеке знаний через LightRAG GraphRAG с индексацией и GitHub интеграцией"
- ✅ Функции: search_knowledge_base, get_library_status, trigger_reindex, push_to_github, list_library_floors

---

### Тест 2: Поиск в библиотеке

**Команда в чате:**
```
Найди информацию про разгон видеокарт MSI Afterburner
```

**Ожидаемое поведение:**
1. Open WebUI вызывает `search_knowledge_base(query="разгон видеокарт MSI Afterburner", mode="hybrid")`
2. Запрос к `POST http://localhost:8003/query`
3. LightRAG возвращает результаты из GraphRAG
4. Ответ содержит цитаты из библиотеки

**Признаки успеха:**
- ✅ Упоминание "MSI Afterburner"
- ✅ Цитаты из документов (файлы `*.md`)
- ✅ Режим поиска: "hybrid" (или "naive"/"local"/"global")

**Признаки ошибки:**
- ❌ "Connection refused" → LightRAG сервер не запущен
- ❌ Пустой ответ → Документы не проиндексированы
- ❌ Ошибка 500 → Проблема в коде инструмента

---

### Тест 3: Статус библиотеки

**Команда в чате:**
```
Покажи статус библиотеки
```

**Ожидаемое поведение:**
1. Вызов `get_library_status()`
2. Запрос к `GET http://localhost:8003/status`
3. Возврат JSON с количеством документов

**Ожидаемый ответ:**
```
📚 Статус Библиотеки Знаний:
- Обработано: 377 документов
- В процессе: 0
- Ошибки: 13
- Всего: 390
```

---

### Тест 4: Список этажей библиотеки

**Команда в чате:**
```
Покажи структуру библиотеки по этажам
```

**Ожидаемое поведение:**
1. Вызов `list_library_floors()`
2. Чтение `E:\AGENTS\librarian-agent\library\library_structure.json`
3. Вывод списка Floor_01 - Floor_09

**Ожидаемый ответ:**
```
📚 Структура Библиотеки (9 этажей):

Floor_01: [название темы]
- Файл: Floor_01_*.md
- Разделы: F1-S01, F1-S02, ...

Floor_02: [название темы]
...
```

---

### Тест 5: Переиндексация документов (НОВОЕ!)

**Команда в чате:**
```
Переиндексируй документы из библиотеки
```

**Ожидаемое поведение:**
1. Вызов `trigger_reindex()` (без параметров → дефолт `E:\AGENTS\Documents_cleaned`)
2. Запрос к `POST http://localhost:8003/api/reindex`
3. Сканирование всех `.md` файлов
4. Индексация через LightRAG

**Ожидаемый ответ:**
```json
{
  "status": "success",
  "watch_dir": "E:\\AGENTS\\Documents_cleaned",
  "total_files": 100,
  "indexed": 95,
  "skipped": 5,
  "indexed_files": ["doc1.md", "doc2.md", ...],
  "skipped_files": [{"file": "bad.md", "error": "..."}]
}
```

**Признаки успеха:**
- ✅ `status: "success"`
- ✅ `indexed > 0`
- ✅ Список файлов не пустой

**Признаки ошибки:**
- ❌ 404 "Directory not found" → Неверный путь к `Documents_cleaned`
- ❌ 500 "Reindex error" → Проблема с LightRAG
- ❌ `indexed: 0` → Нет новых файлов для индексации

---

### Тест 6: GitHub Push (НОВОЕ!)

**Команда в чате:**
```
Закоммить изменения в библиотеке с сообщением "Weekly documentation update"
```

**Ожидаемое поведение:**
1. Вызов `push_to_github("Weekly documentation update", "main")`
2. Запрос к `POST http://localhost:8003/api/git/push`
3. Git операции:
   - `git add Documents_cleaned/ librarian-agent/library/`
   - `git commit -m "Weekly documentation update"`
   - `git push origin main`
4. Возврат хеша коммита

**Ожидаемый ответ:**
```json
{
  "status": "success",
  "commit_hash": "a1b2c3d4e5f6...",
  "commit_message": "Weekly documentation update",
  "branch": "main",
  "files_changed": 5,
  "changed_files": ["Documents_cleaned/doc1.md", ...]
}
```

**Признаки успеха:**
- ✅ `status: "success"`
- ✅ `commit_hash` не пустой (40 символов)
- ✅ `files_changed > 0`

**Признаки ошибки:**
- ❌ 400 "Not a Git repository" → `E:\AGENTS` не является Git репозиторием
- ❌ 500 "Git operation failed: nothing to commit" → Нет изменений для коммита
- ❌ 500 "Git push error" → Проблемы с авторизацией GitHub или сетью

---

## 🐛 Troubleshooting

### Проблема 1: Инструмент не появляется в Open WebUI

**Диагностика:**
```powershell
cd E:\AGENTS\agents_tools
python -c "import sqlite3; conn = sqlite3.connect(r'E:\AGENTS\open-webui-bridge\data\webui.db'); cursor = conn.cursor(); cursor.execute('SELECT id, name FROM tool'); print(cursor.fetchall()); conn.close()"
```

**Решение:**
```powershell
python install_library_tool_to_webui.py --force
```

---

### Проблема 2: Ошибка "Connection refused" при вызове функций

**Причина:** LightRAG сервер не запущен или висит на другом порту.

**Диагностика:**
```powershell
curl http://localhost:8003/health
```

**Решение:**
```powershell
# Остановить старый процесс
Get-Process python | Where-Object {$_.Path -like '*AI_Librarian_Core*'} | Stop-Process -Force

# Запустить новый
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd E:\AI_Librarian_Core; python lightrag_server.py"

# Подождать 10 секунд
Start-Sleep 10

# Проверить
curl http://localhost:8003/health
```

---

### Проблема 3: Функция trigger_reindex не работает

**Причина:** Endpoint `/api/reindex` не существует (старая версия сервера).

**Диагностика:**
```powershell
curl http://localhost:8003/openapi.json | ConvertFrom-Json | Select-Object -ExpandProperty paths | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Sort-Object
```

**Проверка:** Должен быть `/api/reindex` в списке.

**Решение:**
```powershell
# Проверить версию файла
(Get-Content E:\AI_Librarian_Core\lightrag_server.py).Count
# Должно быть ~508 строк (было 366)

# Если нет, значит изменения не сохранились
# Перечитать файл из репозитория или переделать replace_string_in_file

# Удалить кэш и перезапустить
Get-Process python | Where-Object {$_.Path -like '*AI_Librarian_Core*'} | Stop-Process -Force
Remove-Item E:\AI_Librarian_Core\__pycache__ -Recurse -Force -ErrorAction SilentlyContinue
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd E:\AI_Librarian_Core; python lightrag_server.py"
```

---

### Проблема 4: Git push возвращает ошибку авторизации

**Причина:** GitHub требует токен вместо пароля для HTTPS push.

**Решение:**
1. Сгенерировать Personal Access Token на GitHub: Settings → Developer settings → Personal access tokens
2. Сохранить токен в `E:\AGENTS\.git\config`:
```ini
[credential]
    helper = store
```
3. При первом push вместо пароля ввести токен
4. Последующие push будут работать автоматически

**Альтернатива:** Переключиться на SSH:
```powershell
cd E:\AGENTS
git remote set-url origin git@github.com:username/AGENTS.git
```

---

## 📊 Ожидаемые результаты

| Тест | Статус | Описание |
|------|--------|----------|
| Активация инструмента | ✅ | Инструмент появляется в списке Tools |
| Поиск в библиотеке | ✅ | Возвращает релевантные результаты |
| Статус библиотеки | ✅ | Показывает 377 документов |
| Список этажей | ✅ | Выводит структуру Floor_01 - Floor_09 |
| Переиндексация | ✅ | Сканирует и индексирует файлы |
| GitHub push | ⚠️ | Требует Git настройки (токен/SSH) |

---

## 🔗 Полезные команды

### Быстрая проверка системы
```powershell
# Все в одной команде
curl http://localhost:8003/health; curl http://localhost:8003/status; nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits
```

### Логи сервера
```powershell
# Если сервер запущен в отдельном окне, логи там
# Если нужно сохранить лог в файл:
cd E:\AI_Librarian_Core
python lightrag_server.py > lightrag_server.log 2>&1
```

### Перезагрузка всего стека
```powershell
# 1. Остановить LightRAG
Get-Process python | Where-Object {$_.Path -like '*AI_Librarian_Core*'} | Stop-Process -Force

# 2. Перезапустить Open WebUI контейнер
docker restart open-webui

# 3. Запустить LightRAG
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd E:\AI_Librarian_Core; python lightrag_server.py"

# 4. Подождать 15 секунд
Start-Sleep 15

# 5. Проверить
curl http://localhost:3000/health  # Open WebUI
curl http://localhost:8003/health  # LightRAG
```

---

**Следующий шаг:** Открыть `http://localhost:3000` и выполнить тесты 1-6 в чате.
