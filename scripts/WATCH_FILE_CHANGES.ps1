<#
.SYNOPSIS
    FileSystemWatcher для автоматического обновления индекса проекта WORLD_OLLAMA

.DESCRIPTION
    Мониторит изменения .md файлов в проекте и автоматически обновляет RUNTIME_LOGS_JOURNAL_INDEX.md
    Реализация рекомендации из Consensus.app Research (03.12.2025)

.PARAMETER WatchPath
    Путь для мониторинга (по умолчанию: E:\WORLD_OLLAMA)

.PARAMETER IndexFile
    Путь к индексному файлу (по умолчанию: docs/project/RUNTIME_LOGS_JOURNAL_INDEX.md)

.PARAMETER DebounceMs
    Задержка debounce в миллисекундах (по умолчанию: 2000)

.EXAMPLE
    .\WATCH_FILE_CHANGES.ps1
    Запуск с дефолтными параметрами

.EXAMPLE
    .\WATCH_FILE_CHANGES.ps1 -WatchPath "E:\WORLD_OLLAMA\docs" -DebounceMs 5000
    Мониторинг только папки docs с увеличенным debounce

.NOTES
    Версия: 1.0
    Автор: AI Agent (GitHub Copilot)
    Дата: 03.12.2025
    Зависимости: PowerShell 7+, FileSystemWatcher .NET API
#>

param(
    [string]$WatchPath = "E:\WORLD_OLLAMA",
    [string]$IndexFile = "docs\project\RUNTIME_LOGS_JOURNAL_INDEX.md",
    [int]$DebounceMs = 2000
)

$ErrorActionPreference = "Stop"
$LogFile = "logs\file_watcher.log"

# Создать лог-файл если не существует
if (-not (Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logEntry
    
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry -ForegroundColor White }
    }
}

function Update-Index {
    param([string]$ChangedFile, [string]$ChangeType)
    
    Write-Log "Триггер обновления: $ChangeType - $ChangedFile" "INFO"
    
    try {
        # Запуск UPDATE_PROJECT_INDEX.ps1 (создадим его позже)
        $updateScript = Join-Path $PSScriptRoot "UPDATE_PROJECT_INDEX.ps1"
        
        if (Test-Path $updateScript) {
            Write-Log "Запуск переиндексации..." "INFO"
            & $updateScript -IncrementalMode -TriggerFile $ChangedFile
            Write-Log "Переиндексация завершена успешно" "SUCCESS"
        } else {
            Write-Log "Скрипт UPDATE_PROJECT_INDEX.ps1 не найден" "WARNING"
            
            # Fallback: просто обновить timestamp в индексе
            $indexPath = Join-Path $WatchPath $IndexFile
            if (Test-Path $indexPath) {
                $content = Get-Content $indexPath -Raw
                $newTimestamp = Get-Date -Format "dd.MM.yyyy HH:mm"
                $content = $content -replace '(\*\*Последнее обновление:\*\*\s+)\d{2}\.\d{2}\.\d{4}\s+\d{2}:\d{2}', "`$1$newTimestamp"
                $content | Set-Content $indexPath -NoNewline
                Write-Log "Обновлён timestamp в индексе" "SUCCESS"
            }
        }
    }
    catch {
        Write-Log "Ошибка при обновлении индекса: $($_.Exception.Message)" "ERROR"
    }
}

# Debounce логика
$script:lastEventTime = @{}
$script:debounceTimer = $null

function Invoke-Debounced {
    param([string]$File, [string]$ChangeType)
    
    $key = "$File-$ChangeType"
    $now = Get-Date
    
    # Проверить debounce
    if ($script:lastEventTime.ContainsKey($key)) {
        $elapsed = ($now - $script:lastEventTime[$key]).TotalMilliseconds
        if ($elapsed -lt $DebounceMs) {
            Write-Log "Debounce: пропущено событие для $File ($elapsed ms < $DebounceMs ms)" "DEBUG"
            return
        }
    }
    
    $script:lastEventTime[$key] = $now
    
    # Отменить предыдущий таймер
    if ($null -ne $script:debounceTimer) {
        $script:debounceTimer.Stop()
        $script:debounceTimer.Dispose()
    }
    
    # Создать новый таймер
    $script:debounceTimer = New-Object System.Timers.Timer
    $script:debounceTimer.Interval = $DebounceMs
    $script:debounceTimer.AutoReset = $false
    
    Register-ObjectEvent -InputObject $script:debounceTimer -EventName Elapsed -Action {
        Update-Index -ChangedFile $File -ChangeType $ChangeType
    } | Out-Null
    
    $script:debounceTimer.Start()
}

# Создать FileSystemWatcher
Write-Log "Инициализация FileSystemWatcher для $WatchPath" "INFO"
Write-Log "Мониторинг: *.md файлов (исключая venv, node_modules, archive)" "INFO"
Write-Log "Debounce: $DebounceMs ms" "INFO"

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $WatchPath
$watcher.Filter = "*.md"
$watcher.IncludeSubdirectories = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor 
                         [System.IO.NotifyFilters]::LastWrite -bor
                         [System.IO.NotifyFilters]::CreationTime

# Фильтр исключений
$excludePatterns = @("\\venv\\", "\\node_modules\\", "\\archive\\", "\\llamaboard_cache\\")

function Test-ShouldExclude {
    param([string]$Path)
    
    foreach ($pattern in $excludePatterns) {
        if ($Path -like "*$pattern*") {
            return $true
        }
    }
    return $false
}

# Обработчики событий
$onCreated = {
    $file = $Event.SourceEventArgs.FullPath
    if (-not (Test-ShouldExclude $file)) {
        Invoke-Debounced -File $file -ChangeType "Created"
    }
}

$onChanged = {
    $file = $Event.SourceEventArgs.FullPath
    if (-not (Test-ShouldExclude $file)) {
        Invoke-Debounced -File $file -ChangeType "Changed"
    }
}

$onDeleted = {
    $file = $Event.SourceEventArgs.FullPath
    if (-not (Test-ShouldExclude $file)) {
        Invoke-Debounced -File $file -ChangeType "Deleted"
    }
}

$onRenamed = {
    $file = $Event.SourceEventArgs.FullPath
    $oldFile = $Event.SourceEventArgs.OldFullPath
    if (-not (Test-ShouldExclude $file)) {
        Invoke-Debounced -File "$oldFile → $file" -ChangeType "Renamed"
    }
}

# Регистрация событий
$handlers = @()
$handlers += Register-ObjectEvent -InputObject $watcher -EventName Created -Action $onCreated
$handlers += Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $onChanged
$handlers += Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $onDeleted
$handlers += Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $onRenamed

# Запуск мониторинга
$watcher.EnableRaisingEvents = $true

Write-Log "FileSystemWatcher запущен успешно ✅" "SUCCESS"
Write-Log "Нажмите Ctrl+C для остановки..." "INFO"

try {
    # Бесконечный цикл (держит скрипт активным)
    while ($true) {
        Start-Sleep -Seconds 10
        
        # Heartbeat каждые 10 минут
        $now = Get-Date
        if ($now.Minute -eq 0 -and $now.Second -lt 10) {
            Write-Log "Heartbeat: FileSystemWatcher активен (отслеживается $($watcher.Path))" "INFO"
        }
    }
}
finally {
    # Очистка при завершении
    Write-Log "Остановка FileSystemWatcher..." "INFO"
    
    $watcher.EnableRaisingEvents = $false
    
    foreach ($handler in $handlers) {
        Unregister-Event -SubscriptionId $handler.Id
    }
    
    $watcher.Dispose()
    
    if ($null -ne $script:debounceTimer) {
        $script:debounceTimer.Dispose()
    }
    
    Write-Log "FileSystemWatcher остановлен" "SUCCESS"
}
