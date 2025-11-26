# ✅ Open WebUI успешно переустановлен на диск E

## Текущий статус системы

### Open WebUI
- **URL:** http://localhost:3000
- **Статус:** ✅ Up (healthy)
- **Данные:** `E:\OpenWebUI_Data\` (270 KB, свежая установка)
- **База данных:** webui.db инициализирована
- **Контейнер:** open-webui (restart: always)

### Ollama
- **Контейнер:** demo_ollama
- **Порт:** 127.0.0.1:11444
- **Модель:** llama3.2:3b (2.0 GB)
- **Статус:** ✅ Работает

---

## Первоначальная настройка

### Шаг 1: Регистрация в Open WebUI

1. Откройте браузер: **http://localhost:3000**
2. Нажмите **Sign Up**
3. Заполните форму:
   - Email: ваш email
   - Name: ваше имя
   - Password: ваш пароль
4. Нажмите **Create Account**

> 💡 Первый пользователь автоматически получает права администратора.

---

### Шаг 2: Подключение Ollama

Open WebUI должен автоматически обнаружить Ollama через `host.docker.internal:11434`.

**Проверка подключения:**

1. Settings (⚙️) → Connections
2. В разделе **Ollama API**:
   - URL должен быть: `http://host.docker.internal:11434`
   - Нажмите **Verify Connection**
   - Должна появиться галочка ✅

**Если не подключился автоматически:**

Вручную установите URL:
```
http://host.docker.internal:11444
```
(т.к. ваш Ollama на порту 11444, а не 11434)

---

### Шаг 3: Загрузка библиотеки

**Консолидированные файлы готовы для загрузки:**

```
E:\AI_Librarian_Core\library_source\CONSOLIDATED_LIBRARY\
├── 01_Architecture_Methodology.md (3.3 MB, 13,610 строк)
├── 05_Prompts_Instructions.md (523 KB, 1,722 строки)
└── Uncategorized.md (3.1 MB, 16,027 строк)
```

**Процесс загрузки:**

1. Workspace → Documents
2. Upload Files
3. Выбрать все 3 файла из `CONSOLIDATED_LIBRARY\`
4. Дождаться индексации (7-10 минут)

**Индексация:**
- Open WebUI автоматически скачает `nomic-embed-text:latest` (~274 MB)
- Создаст векторные индексы в `E:\OpenWebUI_Data\vector_db\`

---

### Шаг 4: Загрузка модели Qwen 2.5 (опционально)

**Текущая модель:** llama3.2:3b (легкая, быстрая)

**Для более мощного агента:**

```powershell
# Загрузка Qwen 2.5 32B в demo_ollama
docker exec demo_ollama ollama pull qwen2.5:32b-instruct-q4_k_m
```

**Время загрузки:** ~15-25 минут (19 GB)

**После загрузки:**
- Модель появится в WebUI → New Chat → Model Selector
- Можно создать кастомного агента "librarian" с Modelfile

---

## Архитектура системы

```
┌─────────────────────────────────────┐
│  Open WebUI (порт 3000)             │
│  Данные: E:\OpenWebUI_Data\         │
└──────────────┬──────────────────────┘
               │
               │ host.docker.internal:11444
               │
┌──────────────▼──────────────────────┐
│  Ollama (demo_ollama)               │
│  Модель: llama3.2:3b                │
│  Порт: 127.0.0.1:11444              │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  Библиотека                         │
│  E:\AI_Librarian_Core\              │
│  └── library_source\                │
│      └── CONSOLIDATED_LIBRARY\      │
│          ├── 01_Architecture...     │
│          ├── 05_Prompts...          │
│          └── Uncategorized.md       │
└─────────────────────────────────────┘
```

---

## Преимущества новой установки

1. ✅ **Чистая база данных** — нет старых артефактов
2. ✅ **Данные на NVMe** (диск E) — быстрая работа RAG
3. ✅ **Стандартный порт 3000** — совместимость с документацией
4. ✅ **Автоматический перезапуск** — переживет перезагрузку системы
5. ✅ **Легкий доступ к данным** — `E:\OpenWebUI_Data\` прямо на диске

---

## Быстрые команды

### Управление контейнером
```powershell
# Остановить
docker stop open-webui

# Запустить
docker start open-webui

# Перезапустить
docker restart open-webui

# Логи
docker logs -f open-webui

# Статус
docker ps --filter "name=open-webui"
```

### Резервное копирование
```powershell
# Backup данных
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
Copy-Item -Recurse "E:\OpenWebUI_Data" "E:\Backups\OpenWebUI_$timestamp"

# Backup только базы данных
Copy-Item "E:\OpenWebUI_Data\webui.db" "E:\Backups\webui_$timestamp.db"
```

### Очистка (ВНИМАНИЕ: удалит все данные)
```powershell
docker stop open-webui
docker rm open-webui
Remove-Item -Recurse -Force "E:\OpenWebUI_Data"
```

---

## Интеграция с AI_Librarian_Core

**docker-compose.yaml обновлен:**
- Порт изменен с 3001 → 3000
- Контейнеры librarian_* остановлены

**Варианты использования:**

### Вариант 1: Только новый Open WebUI + demo_ollama (текущий)
- ✅ Простая конфигурация
- ✅ Работает сразу
- ⚠️ Нет GPU acceleration (demo_ollama без GPU)

### Вариант 2: Запустить librarian_brain из docker-compose
```powershell
cd E:\AI_Librarian_Core
docker-compose up -d ollama
```
- ✅ GPU acceleration (NVIDIA)
- ✅ Оптимизация под RTX 5060 Ti
- Затем в WebUI: Settings → Connections → Ollama API → `http://host.docker.internal:11434`

### Вариант 3: Standalone Ollama с GPU (рекомендуется)
```powershell
docker run -d \
  --gpus all \
  -p 11435:11434 \
  -v E:\AI_Librarian_Core\data\ollama:/root/.ollama \
  --name ollama_gpu \
  --restart always \
  ollama/ollama:latest
```
- WebUI → Settings → Connections → `http://host.docker.internal:11435`

---

## Следующие шаги

1. ⏳ **Сейчас:** Зарегистрироваться на http://localhost:3000
2. ⏳ **Следующий:** Загрузить консолидированную библиотеку
3. ⏳ **Далее:** Протестировать RAG с llama3.2:3b
4. ⏳ **Опционально:** Загрузить Qwen 2.5 32B для мощного агента

**Готово к работе!** 🚀
