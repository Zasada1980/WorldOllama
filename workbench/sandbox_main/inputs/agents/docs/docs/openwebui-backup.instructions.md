---
description: Система автоматического бэкапа Open WebUI контейнера
applyTo: '**'
---

# Open WebUI Backup System

## Расположение бэкапов
**Основная директория:** `E:\AGENTS\backups\open-webui\`

### Структура:
```
E:\AGENTS\backups\open-webui\
├── configs/          # Конфигурации контейнера и переменные окружения
│   ├── container_config_YYYYMMDD_HHMMSS.json
│   ├── env_vars_YYYYMMDD_HHMMSS.json
│   └── .container_state.json  # Последнее состояние для мониторинга
├── data/             # Копии файлов из контейнера
│   └── YYYYMMDD_HHMMSS/
│       ├── app_backend_data/
│       ├── app_backend_static/
│       └── root_.ollama/
└── logs/             # Логи бэкапов и мониторинга
    ├── backup_YYYYMMDD.log
    └── watcher_YYYYMMDD.log
```

## Инструменты

### 1. backup_openwebui.py
**Местоположение:** `E:\AGENTS\agents_tools\backup_openwebui.py`

**Функции:**
- Сохранение конфигурации контейнера (docker inspect)
- Копирование переменных окружения
- Извлечение файлов из контейнера (`/app/backend/data`, `/app/backend/static`, `/root/.ollama`)
- Автоматическая очистка старых бэкапов (хранит последние 10)
- Восстановление из бэкапа

**Использование:**
```powershell
# Создать бэкап
python E:\AGENTS\agents_tools\backup_openwebui.py

# Восстановить из бэкапа
python E:\AGENTS\agents_tools\backup_openwebui.py restore 20251121_143000

# Список доступных бэкапов
Get-ChildItem E:\AGENTS\backups\open-webui\data\
```

### 2. watch_openwebui.py
**Местоположение:** `E:\AGENTS\agents_tools\watch_openwebui.py`

**Функции:**
- Мониторинг состояния контейнера каждые 5 минут
- Отслеживание изменений:
  - Конфигурации
  - Переменных окружения
  - Монтирования томов
  - Размера данных
  - Перезапусков контейнера
- Автоматический запуск бэкапа при критических изменениях

**Использование:**
```powershell
# Запустить мониторинг (фоновый режим)
Start-Process python -ArgumentList "E:\AGENTS\agents_tools\watch_openwebui.py" -WindowStyle Hidden

# Одноразовая проверка
python E:\AGENTS\agents_tools\watch_openwebui.py check

# Сброс состояния
python E:\AGENTS\agents_tools\watch_openwebui.py reset
```

### 3. setup_backup_schedule.ps1
**Местоположение:** `E:\AGENTS\agents_tools\setup_backup_schedule.ps1`

**Функции:**
- Создание задачи в Windows Task Scheduler
- Ежедневный бэкап в 02:00
- Бэкап при запуске системы (с задержкой 5 минут)

**Установка:**
```powershell
# Запустить от администратора
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
E:\AGENTS\agents_tools\setup_backup_schedule.ps1

# Управление задачей
Start-ScheduledTask -TaskName "OpenWebUI-AutoBackup"  # Запустить сейчас
Disable-ScheduledTask -TaskName "OpenWebUI-AutoBackup"  # Отключить
Enable-ScheduledTask -TaskName "OpenWebUI-AutoBackup"  # Включить
```

## Триггеры автоматического бэкапа

1. **Ежедневно в 02:00** (Task Scheduler)
2. **При запуске системы** (Task Scheduler, задержка 5 мин)
3. **При обнаружении изменений** (watch_openwebui.py):
   - Изменение конфигурации контейнера
   - Изменение переменных окружения
   - Изменение монтирования томов
   - Перезапуск контейнера

## Восстановление

### Полное восстановление:
```powershell
# 1. Остановить контейнер
docker stop open-webui

# 2. Найти нужный бэкап
Get-ChildItem E:\AGENTS\backups\open-webui\data\ | Sort-Object Name -Descending

# 3. Восстановить автоматически
python E:\AGENTS\agents_tools\backup_openwebui.py restore 20251121_143000

# 4. Проверить состояние
docker logs open-webui --tail 50
```

### Частичное восстановление (только данные):
```powershell
$BACKUP = "20251121_143000"
docker cp E:\AGENTS\backups\open-webui\data\$BACKUP\app_backend_data open-webui:/app/backend/data
docker restart open-webui
```

### Восстановление конфигурации:
```powershell
# Просмотреть сохранённую конфигурацию
$CONFIG = Get-Content E:\AGENTS\backups\open-webui\configs\container_config_20251121_143000.json | ConvertFrom-Json

# Воссоздать контейнер с теми же параметрами (вручную или через docker-compose)
```

## Мониторинг бэкапов

### Проверка последнего бэкапа:
```powershell
Get-ChildItem E:\AGENTS\backups\open-webui\data\ | Sort-Object Name -Descending | Select-Object -First 1
```

### Проверка логов:
```powershell
# Последний лог бэкапа
Get-Content (Get-ChildItem E:\AGENTS\backups\open-webui\logs\backup_*.log | Sort-Object Name -Descending | Select-Object -First 1).FullName -Tail 20

# Последний лог мониторинга
Get-Content (Get-ChildItem E:\AGENTS\backups\open-webui\logs\watcher_*.log | Sort-Object Name -Descending | Select-Object -First 1).FullName -Tail 20
```

### Размер бэкапов:
```powershell
Get-ChildItem E:\AGENTS\backups\open-webui\data\ -Recurse | Measure-Object -Property Length -Sum | Select-Object @{Name="TotalGB";Expression={[math]::Round($_.Sum/1GB, 2)}}
```

## Рекомендации

1. **Регулярная проверка:** Просматривайте логи раз в неделю для выявления проблем.
2. **Тестовое восстановление:** Раз в месяц выполняйте тестовое восстановление для проверки целостности.
3. **Дополнительный бэкап:** Для критических данных дублируйте бэкапы на облачное хранилище.
4. **Очистка:** Автоматическая очистка хранит 10 последних бэкапов. При необходимости архивируйте старые вручную.

## Интеграция с документацией

Эта система автоматически сохраняет:
- Все настройки веб-интерфейса Open WebUI (переменные окружения, конфигурация)
- Пользовательские данные (чаты, загруженные файлы, базы данных)
- Конфигурацию Ollama (если внутри контейнера)

При внесении изменений в Open WebUI через веб-интерфейс, изменения будут автоматически включены в следующий бэкап по расписанию или при обнаружении мониторингом.
