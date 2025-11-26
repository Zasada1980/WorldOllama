# ✅ Миграция Open WebUI на диск E

## Дата: 2025-11-22 13:59

### Выполненные операции

1. **Удаление старого экземпляра:**
   - ✅ Остановлен контейнер `open-webui`
   - ✅ Удален контейнер `open-webui`
   - ✅ Удален Docker volume `open-webui`
   - ⚠️ Образы `ghcr.io/open-webui/open-webui` сохранены (6.07 GB)

2. **Создание нового экземпляра:**
   - ✅ Создан каталог `E:\OpenWebUI_Data\`
   - ✅ Запущен новый контейнер с томом на диске E
   - ✅ Порт: **3000** (восстановлен стандартный)
   - ✅ База данных инициализирована (270 KB)

### Текущая конфигурация

**Контейнер:**
```
Имя: open-webui
Статус: Up (healthy)
Порт: 0.0.0.0:3000 → 8080
Restart: always
```

**Данные на диске E:**
```
E:\OpenWebUI_Data\
├── cache/          ← Кэш приложения
├── uploads/        ← Загруженные документы
├── vector_db/      ← Векторные индексы (RAG)
└── webui.db        ← База данных SQLite (270 KB)
```

**Параметры запуска:**
```bash
docker run -d \
  -p 3000:8080 \
  --add-host=host.docker.internal:host-gateway \
  -v E:\OpenWebUI_Data:/app/backend/data \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

### Обновления в AI_Librarian_Core

**docker-compose.yaml:**
- Порт изменен с `3001` → `3000`
- Контейнеры `librarian_interface` и `librarian_brain` остановлены

**Следствия:**
- Теперь есть **один главный Open WebUI** на порту 3000
- Данные хранятся на диске E (производительный NVMe)
- `librarian_interface` из docker-compose можно не использовать

### Доступ к системе

**URL:** http://localhost:3000

**Первый запуск:**
1. Откройте браузер: http://localhost:3000
2. Нажмите **Sign Up**
3. Создайте аккаунт (первый пользователь = администратор)

### Интеграция с Ollama

**Текущее состояние:**
- ⚠️ Open WebUI запущен, но **не подключен к Ollama**
- Контейнер `librarian_brain` (Ollama) остановлен

**Варианты подключения:**

#### Вариант 1: Использовать локальный Ollama (если установлен)

```powershell
# Проверка локального Ollama
curl http://localhost:11434/api/tags
```

Если работает — Open WebUI автоматически подключится через `host.docker.internal:11434`

#### Вариант 2: Запустить Ollama из docker-compose

```powershell
cd E:\AI_Librarian_Core

# Запустить только Ollama (без второго WebUI)
docker-compose up -d ollama
```

Затем в Open WebUI (http://localhost:3000):
- Settings → Connections → Ollama API
- URL: `http://host.docker.internal:11434`

#### Вариант 3: Standalone Ollama контейнер

```powershell
docker run -d \
  --gpus all \
  -p 11434:11434 \
  -v E:\AI_Librarian_Core\data\ollama:/root/.ollama \
  --name ollama \
  --restart always \
  ollama/ollama:latest
```

### Миграция библиотеки

**Консолидированные файлы:**
```
E:\AI_Librarian_Core\library_source\CONSOLIDATED_LIBRARY\
├── 01_Architecture_Methodology.md (3.3 MB)
├── 05_Prompts_Instructions.md (523 KB)
└── Uncategorized.md (3.1 MB)
```

**Загрузка в новый Open WebUI:**

1. http://localhost:3000 → Workspace → Documents
2. Upload Files → выбрать все 3 файла
3. Дождаться индексации (7-10 минут)

### Backup старых данных

**Важно:** Старые данные были в Docker volume `open-webui` (удален).

Если нужно восстановить:
- ❌ Данные утеряны (volume удален без резервной копии)
- ✅ Консолидированная библиотека сохранена в `CONSOLIDATED_LIBRARY/`
- ✅ Оригинальные Floor_*.md в `_ARCHIVE_ORIGINALS/`

### Рекомендации

1. **Сейчас:**
   - Зарегистрироваться в новом Open WebUI
   - Загрузить консолидированную библиотеку
   - Запустить Ollama (выбрать вариант подключения)

2. **Резервное копирование:**
   ```powershell
   # Создание backup Open WebUI
   Copy-Item -Recurse "E:\OpenWebUI_Data" "E:\Backups\OpenWebUI_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
   ```

3. **Оптимизация:**
   - Настроить автоматический backup
   - Подключить Ollama с моделью Qwen 2.5 32B
   - Создать агента "librarian" с Modelfile

### Статус

- ✅ Старый Open WebUI полностью удален
- ✅ Новый Open WebUI запущен на порту 3000
- ✅ Данные на диске E (NVMe)
- ⏳ Требуется регистрация и настройка
- ⏳ Требуется подключение Ollama
- ⏳ Требуется загрузка библиотеки

**Следующий шаг:** Открыть http://localhost:3000 и зарегистрироваться.
