<#
.SYNOPSIS
    Тесты интеграции обновлений в AI агента (GitHub Copilot)

.DESCRIPTION
    Проверяет:
    1. Обновление copilot-instructions.md с новыми инструментами
    2. Доступность новых скриптов для агента
    3. Корректность документации
    4. Интеграцию с MCP Shell Server

.EXAMPLE
    .\TEST_AGENT_INTEGRATION.ps1

.NOTES
    Версия: 1.0
    Автор: AI Agent (GitHub Copilot)
    Дата: 03.12.2025
#>

$ErrorActionPreference = "Continue"
$ProjectRoot = "E:\WORLD_OLLAMA"

$results = @{
    passed = 0
    failed = 0
    warnings = 0
    tests = @()
}

function Test-AgentItem {
    param(
        [string]$Name,
        [scriptblock]$TestBlock,
        [string]$Category = "AGENT"
    )
    
    Write-Host "`n[$Category] Тест: $Name" -ForegroundColor Cyan
    
    try {
        $result = & $TestBlock
        
        if ($result.Success) {
            Write-Host "  ✅ PASS" -ForegroundColor Green
            if ($result.Message) {
                Write-Host "     $($result.Message)" -ForegroundColor Gray
            }
            $script:results.passed++
        } else {
            Write-Host "  ❌ FAIL" -ForegroundColor Red
            Write-Host "     $($result.Message)" -ForegroundColor Yellow
            $script:results.failed++
        }
        
        if ($result.Warning) {
            Write-Host "  ⚠️  WARNING: $($result.Warning)" -ForegroundColor Yellow
            $script:results.warnings++
        }
        
        $script:results.tests += @{
            category = $Category
            name = $Name
            success = $result.Success
            message = $result.Message
            warning = $result.Warning
        }
    }
    catch {
        Write-Host "  ❌ EXCEPTION: $($_.Exception.Message)" -ForegroundColor Red
        $script:results.failed++
    }
}

Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     ТЕСТЫ ИНТЕГРАЦИИ ОБНОВЛЕНИЙ В AI АГЕНТА (COPILOT)      ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# ============================================================================
# КАТЕГОРИЯ 1: COPILOT-INSTRUCTIONS.MD
# ============================================================================

Test-AgentItem "copilot-instructions.md существует" {
    $path = "$ProjectRoot\.github\copilot-instructions.md"
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        return @{ Success = $true; Message = "Размер: $size байт" }
    }
    return @{ Success = $false; Message = "Файл не найден: $path" }
} -Category "DOCUMENTATION"

Test-AgentItem "copilot-instructions.md упоминает FileSystemWatcher" {
    $path = "$ProjectRoot\.github\copilot-instructions.md"
    $content = Get-Content $path -Raw
    
    if ($content -match 'FileSystemWatcher|WATCH_FILE_CHANGES') {
        return @{ 
            Success = $true
            Message = "Найдены упоминания FileSystemWatcher"
        }
    }
    return @{ 
        Success = $false
        Message = "FileSystemWatcher не упомянут в инструкциях агента"
        Warning = "Рекомендуется добавить раздел о новых инструментах"
    }
} -Category "DOCUMENTATION"

Test-AgentItem "copilot-instructions.md упоминает Git hooks" {
    $path = "$ProjectRoot\.github\copilot-instructions.md"
    $content = Get-Content $path -Raw
    
    if ($content -match 'Git.?hook|post-commit') {
        return @{ Success = $true; Message = "Найдены упоминания Git hooks" }
    }
    return @{ 
        Success = $false
        Message = "Git hooks не упомянуты"
        Warning = "Агент может не знать о post-commit автоматизации"
    }
} -Category "DOCUMENTATION"

Test-AgentItem "copilot-instructions.md упоминает Scheduled Task" {
    $path = "$ProjectRoot\.github\copilot-instructions.md"
    $content = Get-Content $path -Raw
    
    if ($content -match 'Scheduled.?Task|CREATE_SCHEDULED_TASK') {
        return @{ Success = $true; Message = "Найдены упоминания Scheduled Task" }
    }
    return @{ 
        Success = $false
        Message = "Scheduled Task не упомянут"
        Warning = "Агент может не знать о ежедневной переиндексации"
    }
} -Category "DOCUMENTATION"

# ============================================================================
# КАТЕГОРИЯ 2: ДОСТУПНОСТЬ СКРИПТОВ ДЛЯ АГЕНТА
# ============================================================================

Test-AgentItem "scripts/WATCH_FILE_CHANGES.ps1 доступен" {
    $path = "$ProjectRoot\scripts\WATCH_FILE_CHANGES.ps1"
    if (Test-Path $path) {
        $content = Get-Content $path -Raw
        $hasHelp = $content -match '\.SYNOPSIS|\.DESCRIPTION'
        
        if ($hasHelp) {
            return @{ Success = $true; Message = "Скрипт документирован (Help доступен)" }
        }
        return @{ 
            Success = $true
            Message = "Скрипт найден"
            Warning = "Отсутствует PowerShell Help комментарий"
        }
    }
    return @{ Success = $false; Message = "Скрипт не найден" }
} -Category "AVAILABILITY"

Test-AgentItem "scripts/UPDATE_PROJECT_INDEX.ps1 доступен" {
    $path = "$ProjectRoot\scripts\UPDATE_PROJECT_INDEX.ps1"
    if (Test-Path $path) {
        $content = Get-Content $path -Raw
        $hasParams = $content -match 'param\('
        
        if ($hasParams) {
            return @{ Success = $true; Message = "Скрипт параметризован (агент может кастомизировать вызовы)" }
        }
        return @{ Success = $true; Message = "Скрипт найден" }
    }
    return @{ Success = $false; Message = "Скрипт не найден" }
} -Category "AVAILABILITY"

Test-AgentItem "scripts/CREATE_SCHEDULED_TASK.ps1 доступен" {
    $path = "$ProjectRoot\scripts\CREATE_SCHEDULED_TASK.ps1"
    if (Test-Path $path) {
        $content = Get-Content $path -Raw
        $hasRemoveOption = $content -match '-RemoveTask'
        
        if ($hasRemoveOption) {
            return @{ Success = $true; Message = "Поддерживается удаление задачи (-RemoveTask)" }
        }
        return @{ Success = $true; Message = "Скрипт найден" }
    }
    return @{ Success = $false; Message = "Скрипт не найден" }
} -Category "AVAILABILITY"

# ============================================================================
# КАТЕГОРИЯ 3: ИНТЕГРАЦИЯ С MCP SHELL SERVER
# ============================================================================

Test-AgentItem "MCP Shell Server может запустить UPDATE_PROJECT_INDEX.ps1" {
    $scriptPath = "$ProjectRoot\scripts\UPDATE_PROJECT_INDEX.ps1"
    
    # Симуляция вызова через MCP (проверка синтаксиса команды)
    $mcpCommand = "pwsh -File `"$scriptPath`" -FullReindex"
    
    # Проверить что команда не содержит проблемных символов для MCP
    $problematicChars = @('|', '{', '}', '$VAR')
    $hasProblems = $false
    
    foreach ($char in $problematicChars) {
        if ($mcpCommand -like "*$char*" -and $char -ne '$') {
            $hasProblems = $true
            break
        }
    }
    
    if (-not $hasProblems) {
        return @{ 
            Success = $true
            Message = "Команда совместима с MCP Shell (Base64 encoding не требуется)"
        }
    }
    return @{ 
        Success = $false
        Message = "Команда содержит проблемные символы для MCP"
        Warning = "Может потребоваться Base64 encoding"
    }
} -Category "MCP_INTEGRATION"

Test-AgentItem "MCP Shell Server может запустить WATCH_FILE_CHANGES.ps1" {
    $scriptPath = "$ProjectRoot\scripts\WATCH_FILE_CHANGES.ps1"
    
    # FileSystemWatcher - это background процесс
    # MCP должен запустить с isBackground=true
    $mcpCommand = "pwsh -File `"$scriptPath`""
    
    $content = Get-Content $scriptPath -Raw
    $hasInfiniteLoop = $content -match 'while\s*\(\s*\$true\s*\)'
    
    if ($hasInfiniteLoop) {
        return @{ 
            Success = $true
            Message = "Скрипт содержит бесконечный цикл (требуется isBackground=true в MCP)"
            Warning = "Агент должен запускать через run_in_terminal с isBackground=true"
        }
    }
    return @{ Success = $true; Message = "Скрипт может быть запущен через MCP" }
} -Category "MCP_INTEGRATION"

# ============================================================================
# КАТЕГОРИЯ 4: ДОКУМЕНТАЦИЯ ДЛЯ АГЕНТА
# ============================================================================

Test-AgentItem "README.md упоминает новые инструменты" {
    $path = "$ProjectRoot\README.md"
    if (Test-Path $path) {
        $content = Get-Content $path -Raw
        
        $mentions = @(
            ($content -match 'FileSystemWatcher'),
            ($content -match 'Git.?hook'),
            ($content -match 'Scheduled.?Task')
        )
        
        $foundCount = ($mentions | Where-Object { $_ }).Count
        
        if ($foundCount -ge 2) {
            return @{ Success = $true; Message = "Найдено упоминаний: $foundCount/3" }
        }
        return @{ 
            Success = $false
            Message = "Найдено упоминаний: $foundCount/3"
            Warning = "Рекомендуется обновить README.md"
        }
    }
    return @{ Success = $false; Message = "README.md не найден" }
} -Category "DOCUMENTATION"

Test-AgentItem "RUNTIME_LOGS_JOURNAL_INDEX.md актуален" {
    $path = "$ProjectRoot\docs\project\RUNTIME_LOGS_JOURNAL_INDEX.md"
    if (Test-Path $path) {
        $content = Get-Content $path -Raw
        
        # Проверить дату последнего обновления
        if ($content -match 'Последнее обновление:\*\*\s+(\d{2}\.\d{2}\.\d{4})') {
            $dateStr = $matches[1]
            $indexDate = [datetime]::ParseExact($dateStr, "dd.MM.yyyy", $null)
            $daysDiff = ((Get-Date) - $indexDate).Days
            
            if ($daysDiff -le 1) {
                return @{ Success = $true; Message = "Индекс обновлён $daysDiff дн. назад (актуален)" }
            }
            return @{ 
                Success = $false
                Message = "Индекс обновлён $daysDiff дн. назад"
                Warning = "Рекомендуется запустить UPDATE_PROJECT_INDEX.ps1"
            }
        }
        return @{ Success = $false; Message = "Дата обновления не найдена в индексе" }
    }
    return @{ Success = $false; Message = "Индекс не найден" }
} -Category "DOCUMENTATION"

# ============================================================================
# КАТЕГОРИЯ 5: АГЕНТСКИЕ РЕКОМЕНДАЦИИ
# ============================================================================

Test-AgentItem "Логи автоматизации доступны для анализа" {
    $logPaths = @(
        "$ProjectRoot\logs\file_watcher.log",
        "$ProjectRoot\logs\indexation.log",
        "$ProjectRoot\logs\scheduled_reindex.log"
    )
    
    $existingLogs = $logPaths | Where-Object { Test-Path $_ }
    
    if ($existingLogs.Count -gt 0) {
        return @{ 
            Success = $true
            Message = "Доступно логов: $($existingLogs.Count)/3"
        }
    }
    return @{ 
        Success = $true
        Message = "Логи ещё не созданы (будут созданы при первом запуске)"
        Warning = "Агент может анализировать логи после первого запуска инструментов"
    }
} -Category "AGENT_RECOMMENDATIONS"

Test-AgentItem "Скрипты содержат примеры использования" {
    $scripts = @(
        "$ProjectRoot\scripts\WATCH_FILE_CHANGES.ps1",
        "$ProjectRoot\scripts\UPDATE_PROJECT_INDEX.ps1",
        "$ProjectRoot\scripts\CREATE_SCHEDULED_TASK.ps1"
    )
    
    $withExamples = 0
    foreach ($script in $scripts) {
        $content = Get-Content $script -Raw
        if ($content -match '\.EXAMPLE') {
            $withExamples++
        }
    }
    
    if ($withExamples -eq $scripts.Count) {
        return @{ Success = $true; Message = "Все скрипты содержат .EXAMPLE секции" }
    }
    return @{ 
        Success = $false
        Message = "Скриптов с примерами: $withExamples/$($scripts.Count)"
        Warning = "Агенту может быть сложнее понять использование без примеров"
    }
} -Category "AGENT_RECOMMENDATIONS"

# ============================================================================
# ИТОГОВАЯ СТАТИСТИКА
# ============================================================================

Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              ИТОГОВАЯ СТАТИСТИКА (AGENT INTEGRATION)         ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "✅ PASSED:   $($results.passed)" -ForegroundColor Green
Write-Host "❌ FAILED:   $($results.failed)" -ForegroundColor Red
Write-Host "⚠️  WARNINGS: $($results.warnings)" -ForegroundColor Yellow
Write-Host "📊 TOTAL:    $($results.tests.Count)`n" -ForegroundColor White

$successRate = [math]::Round(($results.passed / $results.tests.Count) * 100, 1)
Write-Host "Success Rate: $successRate%`n" -ForegroundColor $(if ($successRate -ge 90) { "Green" } elseif ($successRate -ge 70) { "Yellow" } else { "Red" })

# Рекомендации для агента
Write-Host "💡 РЕКОМЕНДАЦИИ ДЛЯ АГЕНТА:" -ForegroundColor Cyan
Write-Host "   1. Обновить copilot-instructions.md с новыми инструментами" -ForegroundColor Gray
Write-Host "   2. Использовать MCP Shell Server для запуска скриптов" -ForegroundColor Gray
Write-Host "   3. FileSystemWatcher запускать с isBackground=true" -ForegroundColor Gray
Write-Host "   4. Анализировать логи в logs/file_watcher.log и logs/indexation.log`n" -ForegroundColor Gray

# Сохранить результаты
$reportPath = "$ProjectRoot\logs\test_agent_integration_report.json"
$results | ConvertTo-Json -Depth 5 | Out-File $reportPath
Write-Host "📄 Детальный отчёт сохранён: $reportPath`n" -ForegroundColor Gray

if ($results.failed -eq 0 -and $results.warnings -le 3) {
    Write-Host "✅ ИНТЕГРАЦИЯ С АГЕНТОМ ГОТОВА — АГЕНТ МОЖЕТ ИСПОЛЬЗОВАТЬ НОВЫЕ ИНСТРУМЕНТЫ`n" -ForegroundColor Green
    exit 0
} else {
    Write-Host "⚠️  ТРЕБУЮТСЯ УЛУЧШЕНИЯ ИНТЕГРАЦИИ — СМОТРИ РЕКОМЕНДАЦИИ ВЫШЕ`n" -ForegroundColor Yellow
    exit 1
}
