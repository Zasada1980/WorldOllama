---
description: Мост для прямого доступа к файлам контейнера Open WebUI
applyTo: '**'
---

# Open WebUI Bridge — Прямой доступ к файлам контейнера

## Концепция

**Проблема:** Docker контейнеры изолированы, для доступа к файлам требуется `docker cp` или `docker exec`.

**Решение:** Монтирование локальных путей как volume в контейнер. Файлы контейнера доступны напрямую через файловую систему Windows.

## Структура моста

```
E:\AGENTS\open-webui-bridge\
├── data\           # /app/backend/data (БД, пользовательские данные)
├── static\         # /app/backend/static (загруженные файлы)
├── config\         # Локальные конфиги (не монтируется)
└── sync.log        # Лог синхронизации
```

### Монтирование:
| Локальный путь | Путь в контейнере | Содержимое |
|----------------|-------------------|------------|
| `E:\AGENTS\open-webui-bridge\data\` | `/app/backend/data/` | `webui.db`, `uploads/`, `vector_db/` |
| `E:\AGENTS\open-webui-bridge\static\` | `/app/backend/static/` | Статические файлы загрузок |

## Установка моста

### Автоматическая установка (рекомендуется):
```powershell
# Запустить скрипт пересоздания контейнера
E:\AGENTS\agents_tools\recreate_openwebui_with_bridge.ps1
```

**Что делает скрипт:**
1. Создаёт финальный бэкап текущего контейнера
2. Извлекает параметры (порт, переменные окружения)
3. Останавливает и удаляет старый контейнер
4. Создаёт новый контейнер с монтированием `E:\AGENTS\open-webui-bridge\`
5. Восстанавливает данные из последнего бэкапа
6. Перезапускает контейнер

### Ручная установка:
```powershell
# 1. Остановить текущий контейнер
docker stop open-webui
docker rm open-webui

# 2. Создать новый с монтированием
docker run -d `
  --name open-webui `
  -p 3000:8080 `
  -e OLLAMA_BASE_URL=http://host.docker.internal:11435 `
  -v "E:\AGENTS\open-webui-bridge\data:/app/backend/data" `
  -v "E:\AGENTS\open-webui-bridge\static:/app/backend/static" `
  --add-host=host.docker.internal:host-gateway `
  --restart unless-stopped `
  ghcr.io/open-webui/open-webui:latest

# 3. Скопировать данные из бэкапа
Copy-Item "E:\AGENTS\backups\open-webui\data\<TIMESTAMP>\app_backend_data\*" `
          "E:\AGENTS\open-webui-bridge\data\" -Recurse -Force
docker restart open-webui
```

## Использование моста

### Прямой доступ к файлам:
```powershell
# Просмотреть БД
explorer E:\AGENTS\open-webui-bridge\data\

# Редактировать конфигурацию (если есть)
code E:\AGENTS\open-webui-bridge\data\config.json

# Добавить файл в контейнер
Copy-Item "my-document.pdf" "E:\AGENTS\open-webui-bridge\static\"
# Файл сразу доступен в контейнере!
```

### Утилита синхронизации:
```powershell
# Статус моста
python E:\AGENTS\agents_tools\bridge_sync.py status

# Мониторинг изменений (опционально)
python E:\AGENTS\agents_tools\bridge_sync.py watch

# Ручное копирование из контейнера
python E:\AGENTS\agents_tools\bridge_sync.py pull /app/backend/data/webui.db

# Ручное копирование в контейнер
python E:\AGENTS\agents_tools\bridge_sync.py push my-file.txt
```

## Рабочие сценарии

### 1. Редактирование БД
```powershell
# Остановить контейнер
docker stop open-webui

# Открыть БД (SQLite Browser или DB Browser)
# Путь: E:\AGENTS\open-webui-bridge\data\webui.db

# Внести изменения, сохранить

# Запустить контейнер
docker start open-webui
```

### 2. Добавление плагинов/расширений
```powershell
# Скопировать файлы плагина
Copy-Item -Path "my-plugin\*" `
          -Destination "E:\AGENTS\open-webui-bridge\data\plugins\" `
          -Recurse

# Перезапустить для применения
docker restart open-webui
```

### 3. Массовая загрузка файлов
```powershell
# Копировать множество документов
Copy-Item -Path "E:\Documents\*.pdf" `
          -Destination "E:\AGENTS\open-webui-bridge\static\uploads\"

# Файлы сразу доступны в Open WebUI
```

### 4. Бэкап напрямую
```powershell
# Вместо docker cp — прямое копирование
Copy-Item "E:\AGENTS\open-webui-bridge\data\webui.db" `
          "E:\AGENTS\backups\manual\webui_$(Get-Date -Format 'yyyyMMdd_HHmmss').db"
```

## Мониторинг и отладка

### Проверка монтирования:
```powershell
docker inspect open-webui --format '{{json .Mounts}}' | ConvertFrom-Json | Format-Table Source, Destination, Type
```

Ожидаемый вывод:
```
Source                                    Destination           Type
------                                    -----------           ----
E:\AGENTS\open-webui-bridge\data          /app/backend/data     bind
E:\AGENTS\open-webui-bridge\static        /app/backend/static   bind
```

### Проверка доступности файлов:
```powershell
# Из контейнера
docker exec open-webui ls -la /app/backend/data/

# Локально
Get-ChildItem E:\AGENTS\open-webui-bridge\data\
```

### Логи синхронизации:
```powershell
Get-Content E:\AGENTS\open-webui-bridge\sync.log -Tail 20
```

## Интеграция с бэкапами

Мост **автоматически включён** в систему бэкапов:
- `backup_openwebui.py` сохраняет файлы из моста
- `watch_openwebui.py` отслеживает изменения в монтированных путях

**Важно:** Изменения в `E:\AGENTS\open-webui-bridge\` сразу отражаются в контейнере, бэкап срабатывает при обнаружении изменений.

## Рекомендации

1. **Не редактировать БД во время работы контейнера** — может привести к блокировкам/повреждениям.
2. **Бэкап перед экспериментами:**
   ```powershell
   python E:\AGENTS\agents_tools\backup_openwebui.py
   ```
3. **Права доступа:** Docker Desktop на Windows автоматически управляет правами, дополнительная настройка не требуется.
4. **Размер данных:** Мост использует локальное хранилище — следить за свободным местом на диске E:.

## Миграция обратно (отключение моста)

Если потребуется вернуться к обычному контейнеру:

```powershell
# 1. Создать бэкап
python E:\AGENTS\agents_tools\backup_openwebui.py

# 2. Остановить контейнер с мостом
docker stop open-webui
docker rm open-webui

# 3. Создать обычный контейнер
docker run -d `
  --name open-webui `
  -p 3000:8080 `
  -e OLLAMA_BASE_URL=http://host.docker.internal:11435 `
  --restart unless-stopped `
  ghcr.io/open-webui/open-webui:latest

# 4. Восстановить данные из бэкапа
# (использовать docker cp, как раньше)
```

## Преимущества моста

✅ Прямой доступ к файлам контейнера через Explorer  
✅ Редактирование без `docker cp`  
✅ Быстрое добавление/удаление файлов  
✅ Простая интеграция с внешними инструментами (IDE, DB browser)  
✅ Автоматическая синхронизация изменений  
✅ Совместимость с системой бэкапов

## Связанные файлы

- Скрипт установки: `E:\AGENTS\agents_tools\recreate_openwebui_with_bridge.ps1`
- Утилита синхронизации: `E:\AGENTS\agents_tools\bridge_sync.py`
- Корневой путь моста: `E:\AGENTS\open-webui-bridge\`
- Документация бэкапов: `openwebui-backup.instructions.md`
