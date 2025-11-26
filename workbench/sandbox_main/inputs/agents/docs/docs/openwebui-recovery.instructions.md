---
description: Процедуры восстановления Open WebUI из бэкапов
applyTo: '**'
---

# Open WebUI Recovery Procedures

## Быстрое восстановление

### Сценарий 1: Контейнер повреждён, данные целы
```powershell
# Пересоздать контейнер с теми же настройками
docker stop open-webui
docker rm open-webui

# Найти последнюю рабочую конфигурацию
$lastConfig = Get-ChildItem E:\AGENTS\backups\open-webui\configs\container_config_*.json | Sort-Object Name -Descending | Select-Object -First 1

# Просмотреть параметры запуска (порты, переменные окружения)
Get-Content $lastConfig.FullName | ConvertFrom-Json | Select-Object -ExpandProperty Config

# Пересоздать контейнер (пример с портом 3000)
docker run -d `
  --name open-webui `
  -p 3000:8080 `
  -e OLLAMA_BASE_URL=http://host.docker.internal:11435 `
  -v open-webui-data:/app/backend/data `
  --restart unless-stopped `
  ghcr.io/open-webui/open-webui:latest
```

### Сценарий 2: Потеря данных, восстановление из бэкапа
```powershell
# 1. Выбрать бэкап для восстановления
Get-ChildItem E:\AGENTS\backups\open-webui\data\ | Sort-Object Name -Descending | Format-Table Name, LastWriteTime

# 2. Автоматическое восстановление
python E:\AGENTS\agents_tools\backup_openwebui.py restore 20251121_143000

# 3. Проверить логи контейнера
docker logs open-webui --tail 50 --follow
```

### Сценарий 3: Частичное восстановление (только БД)
```powershell
$BACKUP = "20251121_143000"

# Восстановить только базу данных
docker cp E:\AGENTS\backups\open-webui\data\$BACKUP\app_backend_data\webui.db open-webui:/app/backend/data/webui.db

# Перезапустить для применения
docker restart open-webui
```

### Сценарий 4: Откат конфигурации/переменных окружения
```powershell
# 1. Найти бэкап с нужной конфигурацией
$envBackup = Get-ChildItem E:\AGENTS\backups\open-webui\configs\env_vars_*.json | Sort-Object Name -Descending | Select-Object -First 1

# 2. Просмотреть переменные
Get-Content $envBackup.FullName | ConvertFrom-Json

# 3. Пересоздать контейнер с этими переменными (вручную или через docker-compose)
```

## Проверка целостности бэкапа

```powershell
# Функция проверки бэкапа
function Test-BackupIntegrity {
    param([string]$BackupTimestamp)
    
    $dataPath = "E:\AGENTS\backups\open-webui\data\$BackupTimestamp"
    $configPath = "E:\AGENTS\backups\open-webui\configs\container_config_$BackupTimestamp.json"
    
    $issues = @()
    
    # Проверка наличия данных
    if (-not (Test-Path $dataPath)) {
        $issues += "Отсутствует каталог данных"
    }
    
    # Проверка конфигурации
    if (-not (Test-Path $configPath)) {
        $issues += "Отсутствует файл конфигурации"
    } else {
        try {
            $config = Get-Content $configPath | ConvertFrom-Json
            if (-not $config.Config) {
                $issues += "Повреждён JSON конфигурации"
            }
        } catch {
            $issues += "Ошибка парсинга конфигурации: $_"
        }
    }
    
    # Проверка размера данных
    if (Test-Path $dataPath) {
        $size = (Get-ChildItem $dataPath -Recurse | Measure-Object -Property Length -Sum).Sum
        if ($size -lt 1KB) {
            $issues += "Подозрительно малый размер данных: $([math]::Round($size/1KB, 2)) KB"
        }
    }
    
    if ($issues.Count -eq 0) {
        Write-Host "✓ Бэкап $BackupTimestamp целостен" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Проблемы с бэкапом $BackupTimestamp:" -ForegroundColor Red
        $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
        return $false
    }
}

# Проверить последний бэкап
$lastBackup = (Get-ChildItem E:\AGENTS\backups\open-webui\data\ | Sort-Object Name -Descending | Select-Object -First 1).Name
Test-BackupIntegrity -BackupTimestamp $lastBackup
```

## Аварийное восстановление

### Полная потеря контейнера и данных
```powershell
# 1. Создать новый контейнер
docker run -d `
  --name open-webui `
  -p 3000:8080 `
  -e OLLAMA_BASE_URL=http://host.docker.internal:11435 `
  --restart unless-stopped `
  ghcr.io/open-webui/open-webui:latest

# 2. Дождаться инициализации (30-60 секунд)
Start-Sleep -Seconds 60

# 3. Остановить для копирования данных
docker stop open-webui

# 4. Восстановить данные из последнего бэкапа
$lastBackup = (Get-ChildItem E:\AGENTS\backups\open-webui\data\ | Sort-Object Name -Descending | Select-Object -First 1).Name
docker cp "E:\AGENTS\backups\open-webui\data\$lastBackup\app_backend_data" open-webui:/app/backend/

# 5. Запустить
docker start open-webui

# 6. Проверить
Start-Sleep -Seconds 10
Start-Process "http://localhost:3000"
```

## Миграция на новый хост

```powershell
# На старом хосте: создать финальный бэкап
python E:\AGENTS\agents_tools\backup_openwebui.py

# Скопировать всю папку бэкапов на новый хост
# Например, через сетевое хранилище или USB

# На новом хосте:
# 1. Скопировать папку бэкапов в E:\AGENTS\backups\open-webui\
# 2. Установить Docker
# 3. Создать контейнер и восстановить данные (см. Аварийное восстановление)
```

## Регулярное тестирование

### Ежемесячный тест восстановления (рекомендуется)
```powershell
# 1. Создать тестовый контейнер
docker run -d `
  --name open-webui-test `
  -p 3001:8080 `
  ghcr.io/open-webui/open-webui:latest

# 2. Восстановить данные из случайного бэкапа
$randomBackup = (Get-ChildItem E:\AGENTS\backups\open-webui\data\ | Get-Random).Name
docker cp "E:\AGENTS\backups\open-webui\data\$randomBackup\app_backend_data" open-webui-test:/app/backend/

# 3. Запустить и проверить доступность
docker restart open-webui-test
Start-Sleep -Seconds 10
Start-Process "http://localhost:3001"

# 4. Удалить тестовый контейнер после проверки
docker stop open-webui-test
docker rm open-webui-test
```

## Логирование операций восстановления

При каждом восстановлении создавайте запись в лог:

```powershell
$recoveryLog = "E:\AGENTS\backups\open-webui\logs\recovery.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$entry = "$timestamp | Восстановление из бэкапа: $BackupTimestamp | Причина: [указать причину]"
Add-Content -Path $recoveryLog -Value $entry
```

## Контрольный список восстановления

- [ ] Определена причина сбоя
- [ ] Выбран подходящий бэкап (проверена целостность)
- [ ] Создан snapshot текущего состояния (если возможно)
- [ ] Остановлены зависимые сервисы
- [ ] Выполнено восстановление
- [ ] Проверена доступность веб-интерфейса
- [ ] Проверена работа интеграции с Ollama
- [ ] Проверены пользовательские данные (чаты, загрузки)
- [ ] Обновлён лог восстановления
- [ ] Перезапущены зависимые сервисы
- [ ] Отправлено уведомление (если применимо)

## Автоматическое уведомление при восстановлении

Добавьте в конец скрипта `backup_openwebui.py` функцию `restore_from_backup`:

```python
# В конце функции restore_from_backup
logger.info("=" * 60)
logger.info("ВОССТАНОВЛЕНИЕ ЗАВЕРШЕНО")
logger.info(f"Бэкап: {backup_timestamp}")
logger.info(f"Время: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
logger.info("=" * 60)

# Опционально: отправить уведомление (email, webhook и т.д.)
```
