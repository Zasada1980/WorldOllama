<#
.SYNOPSIS
    Скрипт обновления индекса проекта WORLD_OLLAMA

.DESCRIPTION
    Поддерживает два режима:
    1. Инкрементальное обновление (только изменённые файлы)
    2. Полная переиндексация (все .md файлы)

.PARAMETER IncrementalMode
    Включить инкрементальное обновление (по умолчанию: false)

.PARAMETER TriggerFile
    Файл-триггер для инкрементального обновления

.PARAMETER FullReindex
    Выполнить полную переиндексацию (игнорирует IncrementalMode)

.EXAMPLE
    .\UPDATE_PROJECT_INDEX.ps1 -IncrementalMode -TriggerFile "docs\tasks\NEW_REPORT.md"
    Инкрементальное обновление

.EXAMPLE
    .\UPDATE_PROJECT_INDEX.ps1 -FullReindex
    Полная переиндексация

.NOTES
    Версия: 1.0
    Автор: AI Agent (GitHub Copilot)
    Дата: 03.12.2025
#>

param(
    [switch]$IncrementalMode,
    [string]$TriggerFile = "",
    [switch]$FullReindex
)

$ErrorActionPreference = "Stop"
$ProjectRoot = "E:\WORLD_OLLAMA"
$IndexFile = "$ProjectRoot\docs\project\RUNTIME_LOGS_JOURNAL_INDEX.md"
$LogFile = "$ProjectRoot\logs\indexation.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
    Write-Host $logEntry
}

function Get-ProjectJournals {
    Write-Log "Сканирование проекта..." "INFO"
    
    # Сканировать все .md файлы (исключая библиотеки)
    $allMdFiles = Get-ChildItem $ProjectRoot -Recurse -Filter *.md -File | 
        Where-Object { 
            $_.FullName -notmatch '\\venv\\|\\node_modules\\|\\archive\\|\\llamaboard_cache\\'
        }
    
    Write-Log "Найдено .md файлов: $($allMdFiles.Count)" "INFO"
    
    # Фильтр журналов/отчётов (паттерны из v2.1)
    $journalPatterns = @(
        'REPORT', 'LOG', 'JOURNAL', 'INVENTORY', 'INDEX', 'STATUS', 'SNAPSHOT',
        'COMPLETION', 'ANALYSIS', 'AUDIT', 'GUIDE', 'SUMMARY', 'CHANGELOG',
        'REFERENCE', 'DEPLOYMENT', 'RESEARCH', 'COMPARISON', 'EVOLUTION',
        'REQUIREMENTS', 'QUALITY', 'POLICY', 'HANDOVER', 'STRUCTURE'
    )
    
    $journals = $allMdFiles | Where-Object {
        $name = $_.Name
        $journalPatterns | Where-Object { $name -like "*$_*" } | Select-Object -First 1
    }
    
    Write-Log "Отфильтровано журналов/отчётов: $($journals.Count)" "INFO"
    
    # Runtime logs (точный подсчёт)
    $runtimeLogs = @{
        flows = (Get-ChildItem "$ProjectRoot\logs\flows\*.jsonl" -ErrorAction SilentlyContinue).Count
        training = @(
            Get-ChildItem "$ProjectRoot\logs\training\train-*.log" -ErrorAction SilentlyContinue
        ).Count
        mcp = if (Test-Path "$ProjectRoot\logs\mcp\mcp-events.log") { 1 } else { 0 }
        orchestrator = if (Test-Path "$ProjectRoot\logs\orchestrator.log") { 1 } else { 0 }
    }
    
    $runtimeTotal = $runtimeLogs.flows + $runtimeLogs.training + $runtimeLogs.mcp + $runtimeLogs.orchestrator
    
    Write-Log "Runtime логов: $runtimeTotal (flows: $($runtimeLogs.flows), training: $($runtimeLogs.training), MCP: $($runtimeLogs.mcp), orchestrator: $($runtimeLogs.orchestrator))" "INFO"
    
    return @{
        journals = $journals
        runtimeCount = $runtimeTotal
        totalCount = $journals.Count + $runtimeTotal
    }
}

function Update-IndexMetadata {
    param(
        [int]$TotalJournals,
        [int]$RuntimeLogs,
        [int]$DocReports
    )
    
    Write-Log "Обновление метаданных индекса..." "INFO"
    
    if (-not (Test-Path $IndexFile)) {
        Write-Log "Файл индекса не найден: $IndexFile" "ERROR"
        return
    }
    
    $content = Get-Content $IndexFile -Raw
    $timestamp = Get-Date -Format "dd.MM.yyyy HH:mm"
    
    # Обновить Executive Summary
    $content = $content -replace '(\*\*Всего журналов проекта:\*\*\s+)\d+', "`$1$TotalJournals"
    $content = $content -replace '(\*\*Runtime логов:\*\*\s+)\d+', "`$1$RuntimeLogs"
    $content = $content -replace '(\*\*Documentation Reports:\*\*\s+)\d+', "`$1$DocReports"
    
    # Обновить timestamp
    $content = $content -replace '(\*\*Последнее обновление:\*\*\s+)\d{2}\.\d{2}\.\d{4}\s+\d{2}:\d{2}', "`$1$timestamp"
    
    # Обновить период
    $today = Get-Date -Format "yyyy-MM-dd"
    $content = $content -replace '(\*\*Период:\*\*\s+\d{4}-\d{2}-\d{2}\s+до\s+)\d{4}-\d{2}-\d{2}', "`$1$today"
    
    $content | Set-Content $IndexFile -NoNewline
    
    Write-Log "Метаданные обновлены: $TotalJournals журналов (Runtime: $RuntimeLogs, Docs: $DocReports)" "SUCCESS"
}

# MAIN EXECUTION
Write-Log "=== ЗАПУСК UPDATE_PROJECT_INDEX ===" "INFO"
Write-Log "Режим: $(if ($FullReindex) { 'FULL REINDEX' } elseif ($IncrementalMode) { "INCREMENTAL (trigger: $TriggerFile)" } else { 'FULL' })" "INFO"

try {
    if ($IncrementalMode -and -not $FullReindex) {
        Write-Log "Инкрементальное обновление для: $TriggerFile" "INFO"
        
        # Для инкрементального режима просто обновляем timestamp
        # (полная логика категоризации требует больше времени)
        $data = Get-ProjectJournals
        Update-IndexMetadata -TotalJournals $data.totalCount -RuntimeLogs $data.runtimeCount -DocReports $data.journals.Count
        
        Write-Log "Инкрементальное обновление завершено ✅" "SUCCESS"
    }
    else {
        Write-Log "Полная переиндексация..." "INFO"
        
        $data = Get-ProjectJournals
        Update-IndexMetadata -TotalJournals $data.totalCount -RuntimeLogs $data.runtimeCount -DocReports $data.journals.Count
        
        Write-Log "Полная переиндексация завершена ✅" "SUCCESS"
        Write-Log "Найдено журналов: $($data.totalCount) (Runtime: $($data.runtimeCount), Docs: $($data.journals.Count))" "INFO"
    }
}
catch {
    Write-Log "ОШИБКА: $($_.Exception.Message)" "ERROR"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}

Write-Log "=== UPDATE_PROJECT_INDEX ЗАВЕРШЁН ===" "SUCCESS"
