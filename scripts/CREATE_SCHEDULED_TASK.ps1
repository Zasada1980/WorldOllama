<#
.SYNOPSIS
    Создание Windows Scheduled Task для ежедневной переиндексации WORLD_OLLAMA

.DESCRIPTION
    Регистрирует задачу в Windows Task Scheduler для ежедневного запуска
    UPDATE_PROJECT_INDEX.ps1 с полной переиндексацией

.PARAMETER TaskName
    Имя задачи (по умолчанию: WORLD_OLLAMA_Daily_Reindex)

.PARAMETER ExecutionTime
    Время выполнения задачи (по умолчанию: 03:00)

.PARAMETER RemoveTask
    Удалить существующую задачу вместо создания

.EXAMPLE
    .\CREATE_SCHEDULED_TASK.ps1
    Создание задачи с дефолтными параметрами

.EXAMPLE
    .\CREATE_SCHEDULED_TASK.ps1 -ExecutionTime "02:30"
    Создание задачи с запуском в 02:30

.EXAMPLE
    .\CREATE_SCHEDULED_TASK.ps1 -RemoveTask
    Удаление задачи

.NOTES
    Версия: 1.0
    Автор: AI Agent (GitHub Copilot)
    Дата: 03.12.2025
    Требования: Права администратора
#>

param(
    [string]$TaskName = "WORLD_OLLAMA_Daily_Reindex",
    [string]$ExecutionTime = "03:00",
    [switch]$RemoveTask
)

# Проверка прав администратора
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "`n❌ ОШИБКА: Требуются права администратора`n" -ForegroundColor Red
    Write-Host "Запустите PowerShell от имени администратора:" -ForegroundColor Yellow
    Write-Host "  1. Правый клик на PowerShell" -ForegroundColor Gray
    Write-Host "  2. 'Запуск от имени администратора'" -ForegroundColor Gray
    Write-Host "  3. Повторите команду`n" -ForegroundColor Gray
    exit 1
}

$ProjectRoot = "E:\WORLD_OLLAMA"
$ScriptPath = "$ProjectRoot\scripts\UPDATE_PROJECT_INDEX.ps1"
$LogPath = "$ProjectRoot\logs\scheduled_reindex.log"

# УДАЛЕНИЕ ЗАДАЧИ
if ($RemoveTask) {
    Write-Host "`n🗑️  УДАЛЕНИЕ SCHEDULED TASK`n" -ForegroundColor Cyan
    
    try {
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        
        if ($existingTask) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Write-Host "✅ Задача '$TaskName' успешно удалена`n" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Задача '$TaskName' не найдена`n" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "❌ ОШИБКА при удалении задачи: $($_.Exception.Message)`n" -ForegroundColor Red
        exit 1
    }
    
    exit 0
}

# СОЗДАНИЕ ЗАДАЧИ
Write-Host "`n📅 СОЗДАНИЕ WINDOWS SCHEDULED TASK`n" -ForegroundColor Cyan

# Проверить наличие скрипта
if (-not (Test-Path $ScriptPath)) {
    Write-Host "❌ ОШИБКА: Скрипт не найден: $ScriptPath`n" -ForegroundColor Red
    exit 1
}

Write-Host "Параметры задачи:" -ForegroundColor White
Write-Host "  Имя: $TaskName" -ForegroundColor Gray
Write-Host "  Время: Ежедневно в $ExecutionTime" -ForegroundColor Gray
Write-Host "  Скрипт: $ScriptPath" -ForegroundColor Gray
Write-Host "  Лог: $LogPath`n" -ForegroundColor Gray

try {
    # Удалить существующую задачу если есть
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "⚠️  Найдена существующая задача '$TaskName', удаление..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }
    
    # Создать Action (запуск PowerShell с логированием)
    $actionArgs = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-Command",
        "& { `$ErrorActionPreference='Stop'; try { & '$ScriptPath' -FullReindex *>&1 | Tee-Object -FilePath '$LogPath' -Append } catch { `$_ | Out-File '$LogPath' -Append } }"
    )
    
    $action = New-ScheduledTaskAction `
        -Execute "pwsh.exe" `
        -Argument ($actionArgs -join " ")
    
    # Создать Trigger (ежедневно в указанное время)
    $trigger = New-ScheduledTaskTrigger `
        -Daily `
        -At $ExecutionTime
    
    # Создать Settings (разрешить запуск при работе от батареи, не прерывать)
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable:$false `
        -ExecutionTimeLimit (New-TimeSpan -Hours 2)
    
    # Создать Principal (запуск с правами текущего пользователя)
    $principal = New-ScheduledTaskPrincipal `
        -UserId "$env:USERDOMAIN\$env:USERNAME" `
        -LogonType S4U `
        -RunLevel Highest
    
    # Регистрация задачи
    $task = Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description "Ежедневная полная переиндексация журналов проекта WORLD_OLLAMA (рекомендация Consensus.app Research)"
    
    Write-Host "✅ Задача '$TaskName' успешно создана`n" -ForegroundColor Green
    
    # Показать детали задачи
    $taskInfo = Get-ScheduledTask -TaskName $TaskName
    $taskInfo | Format-List TaskName, State, Triggers, Actions | Out-String | Write-Host
    
    Write-Host "Следующий запуск:" -ForegroundColor Cyan
    $nextRun = (Get-ScheduledTaskInfo -TaskName $TaskName).NextRunTime
    Write-Host "  $nextRun`n" -ForegroundColor White
    
    Write-Host "Для ручного запуска задачи выполните:" -ForegroundColor Cyan
    Write-Host "  Start-ScheduledTask -TaskName '$TaskName'`n" -ForegroundColor Gray
    
    Write-Host "Для просмотра логов:" -ForegroundColor Cyan
    Write-Host "  Get-Content '$LogPath' -Tail 50`n" -ForegroundColor Gray
    
    Write-Host "Для удаления задачи:" -ForegroundColor Cyan
    Write-Host "  .\CREATE_SCHEDULED_TASK.ps1 -RemoveTask`n" -ForegroundColor Gray
}
catch {
    Write-Host "❌ ОШИБКА при создании задачи: $($_.Exception.Message)`n" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host "$($_.ScriptStackTrace)`n" -ForegroundColor Gray
    exit 1
}

exit 0
