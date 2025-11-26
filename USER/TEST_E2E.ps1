<#
.SYNOPSIS
    🧪 WORLD_OLLAMA - End-to-End Тестирование Системы

.DESCRIPTION
    Полный E2E тест всех команд управления:
    1. Проверка окружения (Ollama, Python, venv)
    2. Запуск всех сервисов (START_ALL.ps1)
    3. Проверка статуса (CHECK_STATUS.ps1)
    4. Функциональные тесты (health checks, API calls)
    5. Остановка сервисов (STOP_ALL.ps1)
    6. Финальная проверка (порты закрыты)
    
.EXAMPLE
    .\TEST_E2E.ps1
    
    Выполняет полный цикл тестирования системы.

.NOTES
    Автор: SESA3002a
    Дата: 26.11.2025
    Время выполнения: ~5-7 минут
    ВНИМАНИЕ: Остановит все запущенные сервисы!
#>

$ErrorActionPreference = "Continue"

# Автоматический переход в директорию USER
Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)

$testResults = @()
$testsPassed = 0
$testsFailed = 0

function Test-Step {
    param(
        [string]$TestName,
        [scriptblock]$TestCode,
        [string]$ExpectedResult = "SUCCESS"
    )
    
    Write-Host "`n────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "🧪 Тест: $TestName" -ForegroundColor Cyan
    
    try {
        $result = & $TestCode
        if ($result -eq $true -or $result -eq "PASS") {
            Write-Host "✅ PASSED" -ForegroundColor Green
            $script:testsPassed++
            $script:testResults += [PSCustomObject]@{
                Test = $TestName
                Status = "✅ PASSED"
                Details = "OK"
            }
            return $true
        } else {
            Write-Host "❌ FAILED: $result" -ForegroundColor Red
            $script:testsFailed++
            $script:testResults += [PSCustomObject]@{
                Test = $TestName
                Status = "❌ FAILED"
                Details = $result
            }
            return $false
        }
    } catch {
        Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $script:testsFailed++
        $script:testResults += [PSCustomObject]@{
            Test = $TestName
            Status = "❌ FAILED"
            Details = $_.Exception.Message
        }
        return $false
    }
}

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║         🧪 WORLD_OLLAMA E2E ТЕСТИРОВАНИЕ СИСТЕМЫ               ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta

Write-Host "⚠️  ВНИМАНИЕ: Этот тест остановит все запущенные сервисы!" -ForegroundColor Yellow
Write-Host "Время выполнения: ~5-7 минут`n" -ForegroundColor Gray

$userConfirm = Read-Host "Продолжить? (y/N)"
if ($userConfirm -ne "y") {
    Write-Host "Тест отменён пользователем." -ForegroundColor Yellow
    exit 0
}

# ═══════════════════════════════════════════════════════════════
# ФАЗА 1: ПРОВЕРКА ОКРУЖЕНИЯ
# ═══════════════════════════════════════════════════════════════
Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║              ФАЗА 1: ПРОВЕРКА ОКРУЖЕНИЯ                        ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow

Test-Step "1.1 - Существование директории USER" {
    $userDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    if (Test-Path $userDir) {
        return "PASS"
    } else {
        return "Директория USER не найдена"
    }
}

Test-Step "1.2 - Существование скрипта START_ALL.ps1" {
    if (Test-Path ".\START_ALL.ps1") {
        return "PASS"
    } else {
        return "START_ALL.ps1 не найден"
    }
}

Test-Step "1.3 - Существование скрипта STOP_ALL.ps1" {
    if (Test-Path ".\STOP_ALL.ps1") {
        return "PASS"
    } else {
        return "STOP_ALL.ps1 не найден"
    }
}

Test-Step "1.4 - Существование скрипта CHECK_STATUS.ps1" {
    if (Test-Path ".\CHECK_STATUS.ps1") {
        return "PASS"
    } else {
        return "CHECK_STATUS.ps1 не найден"
    }
}

Test-Step "1.5 - Ollama доступен" {
    try {
        $response = Invoke-RestMethod http://localhost:11434/api/tags -TimeoutSec 5
        if ($response) {
            return "PASS"
        }
    } catch {
        return "Ollama не запущен на порту 11434"
    }
}

Test-Step "1.6 - Python доступен" {
    $pythonVersion = python --version 2>&1
    if ($pythonVersion -like "*Python 3.*") {
        Write-Host "  Python: $pythonVersion" -ForegroundColor Gray
        return "PASS"
    } else {
        return "Python не найден или версия < 3.0"
    }
}

Test-Step "1.7 - Виртуальное окружение LightRAG" {
    if (Test-Path "E:\WORLD_OLLAMA\services\lightrag\venv\Scripts\python.exe") {
        return "PASS"
    } else {
        return "venv для LightRAG не найдено"
    }
}

Test-Step "1.8 - Виртуальное окружение Neuro-Terminal" {
    if (Test-Path "E:\WORLD_OLLAMA\services\neuro_terminal\.venv\Scripts\python.exe") {
        return "PASS"
    } else {
        return "venv для Neuro-Terminal не найдено"
    }
}

Test-Step "1.9 - Виртуальное окружение LLaMA Factory" {
    if (Test-Path "E:\WORLD_OLLAMA\services\llama_factory\venv\Scripts\python.exe") {
        return "PASS"
    } else {
        return "venv для LLaMA Factory не найдено"
    }
}

# ═══════════════════════════════════════════════════════════════
# ФАЗА 2: ОСТАНОВКА ПРЕДЫДУЩИХ ЗАПУСКОВ (ЧИСТЫЙ СТАРТ)
# ═══════════════════════════════════════════════════════════════
Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║              ФАЗА 2: ПОДГОТОВКА (ЧИСТЫЙ СТАРТ)                 ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow

Test-Step "2.1 - Выполнение STOP_ALL.ps1 (очистка)" {
    & ".\STOP_ALL.ps1" | Out-Null
    Start-Sleep 3
    
    # Проверка что порты освободились
    $port8004 = netstat -ano | Select-String ":8004" | Select-String "LISTENING"
    $port8501 = netstat -ano | Select-String ":8501" | Select-String "LISTENING"
    $port7860 = netstat -ano | Select-String ":7860" | Select-String "LISTENING"
    
    if (-not $port8004 -and -not $port8501 -and -not $port7860) {
        return "PASS"
    } else {
        return "Некоторые порты всё ещё заняты"
    }
}

# ═══════════════════════════════════════════════════════════════
# ФАЗА 3: ЗАПУСК СИСТЕМЫ (START_ALL.ps1)
# ═══════════════════════════════════════════════════════════════
Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║              ФАЗА 3: ЗАПУСК СИСТЕМЫ (START_ALL_TEST.ps1)      ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow

Write-Host "⏳ Запуск START_ALL_TEST.ps1 (версия для E2E)..." -ForegroundColor Cyan
Write-Host "   Это займёт ~60-90 секунд...`n" -ForegroundColor Gray

# Запускаем тестовую версию START_ALL
& ".\START_ALL_TEST.ps1"

Write-Host "`nОжидание стабилизации сервисов (дополнительно 10 секунд)...`n" -ForegroundColor Yellow
Start-Sleep 10

Test-Step "3.1 - Порт 8004 (CORTEX) слушает" {
    $listener = netstat -ano | Select-String ":8004" | Select-String "LISTENING"
    if ($listener) {
        return "PASS"
    } else {
        return "Порт 8004 не слушает"
    }
}

Test-Step "3.2 - Порт 7860 (LLaMA Board) слушает" {
    $listener = netstat -ano | Select-String ":7860" | Select-String "LISTENING"
    if ($listener) {
        return "PASS"
    } else {
        return "Порт 7860 не слушает"
    }
}

Test-Step "3.3 - Порт 8501 (Neuro-Terminal) слушает" {
    $listener = netstat -ano | Select-String ":8501" | Select-String "LISTENING"
    if ($listener) {
        return "PASS"
    } else {
        return "Порт 8501 не слушает"
    }
}

# ═══════════════════════════════════════════════════════════════
# ФАЗА 4: ФУНКЦИОНАЛЬНЫЕ ТЕСТЫ (HEALTH CHECKS)
# ═══════════════════════════════════════════════════════════════
Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║              ФАЗА 4: ФУНКЦИОНАЛЬНЫЕ ТЕСТЫ                      ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow

Test-Step "4.1 - CORTEX /health endpoint" {
    try {
        $response = Invoke-RestMethod http://localhost:8004/health -TimeoutSec 10
        if ($response.status -eq "healthy") {
            Write-Host "  Статус: $($response.status)" -ForegroundColor Gray
            return "PASS"
        } else {
            return "Неожиданный статус: $($response.status)"
        }
    } catch {
        return "HTTP ошибка: $($_.Exception.Message)"
    }
}

Test-Step "4.2 - CORTEX /status (с API Key)" {
    try {
        $headers = @{"X-API-KEY" = "sesa-secure-core-v1"}
        $response = Invoke-RestMethod http://localhost:8004/status -Headers $headers -TimeoutSec 10
        Write-Host "  Обработано: $($response.processed_count)" -ForegroundColor Gray
        Write-Host "  Всего: $($response.total_count)" -ForegroundColor Gray
        return "PASS"
    } catch {
        return "HTTP ошибка: $($_.Exception.Message)"
    }
}

Test-Step "4.3 - CORTEX блокирует /status без API Key (401)" {
    try {
        $response = Invoke-WebRequest http://localhost:8004/status -TimeoutSec 5 -UseBasicParsing
        return "Должен был вернуть 401, но вернул $($response.StatusCode)"
    } catch {
        if ($_.Exception.Response.StatusCode -eq 401) {
            Write-Host "  Корректно вернул 401 Unauthorized" -ForegroundColor Gray
            return "PASS"
        } else {
            return "Неожиданный код: $($_.Exception.Response.StatusCode)"
        }
    }
}

Test-Step "4.4 - CORTEX /query (с API Key)" {
    try {
        $headers = @{
            "X-API-KEY" = "sesa-secure-core-v1"
            "Content-Type" = "application/json"
        }
        $body = @{
            query = "архитектура системы"
            mode = "naive"
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod http://localhost:8004/query -Method Post -Headers $headers -Body $body -TimeoutSec 60
        if ($response.response) {
            Write-Host "  Получен ответ: $(($response.response).Substring(0, [Math]::Min(60, $response.response.Length)))..." -ForegroundColor Gray
            return "PASS"
        } else {
            return "Пустой ответ от CORTEX"
        }
    } catch {
        return "HTTP ошибка: $($_.Exception.Message)"
    }
}

Test-Step "4.5 - LLaMA Board UI доступен (HTTP 200)" {
    try {
        $response = Invoke-WebRequest http://localhost:7860 -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            return "PASS"
        } else {
            return "Неожиданный код: $($response.StatusCode)"
        }
    } catch {
        return "HTTP ошибка: $($_.Exception.Message)"
    }
}

Test-Step "4.6 - Neuro-Terminal UI доступен (HTTP 200)" {
    try {
        $response = Invoke-WebRequest http://localhost:8501 -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            return "PASS"
        } else {
            return "Неожиданный код: $($response.StatusCode)"
        }
    } catch {
        return "HTTP ошибка: $($_.Exception.Message)"
    }
}

# ═══════════════════════════════════════════════════════════════
# ФАЗА 5: ПРОВЕРКА CHECK_STATUS.ps1
# ═══════════════════════════════════════════════════════════════
Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║              ФАЗА 5: ТЕСТ CHECK_STATUS.ps1                     ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow

Test-Step "5.1 - Выполнение CHECK_STATUS.ps1" {
    try {
        $output = & ".\CHECK_STATUS.ps1" 2>&1 | Out-String
        
        # Проверяем количество рабочих сервисов в сводной таблице
        $tableSection = $output -split "СВОДНАЯ ТАБЛИЦА СТАТУСОВ" | Select-Object -Last 1
        $greenCount = ([regex]::Matches($tableSection, "🟢 РАБОТАЕТ")).Count
        
        Write-Host "  Обнаружено рабочих сервисов: $greenCount" -ForegroundColor Gray
        
        if ($greenCount -ge 3) {  # Ожидаем минимум 3: CORTEX, LLaMA, Neuro
            return "PASS"
        } else {
            return "Недостаточно рабочих сервисов: $greenCount"
        }
    } catch {
        return "Ошибка выполнения: $($_.Exception.Message)"
    }
}

# ═══════════════════════════════════════════════════════════════
# ФАЗА 6: ОСТАНОВКА СИСТЕМЫ (STOP_ALL.ps1)
# ═══════════════════════════════════════════════════════════════
Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║              ФАЗА 6: ОСТАНОВКА СИСТЕМЫ (STOP_ALL.ps1)         ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow

Test-Step "6.1 - Выполнение STOP_ALL.ps1" {
    $output = & ".\STOP_ALL.ps1" 2>&1 | Out-String
    
    # Проверяем что скрипт отработал (либо остановил процессы, либо сообщил что нет запущенных)
    if ($output -like "*Остановлено процессов:*" -or $output -like "*НЕТ ЗАПУЩЕННЫХ СЕРВИСОВ*") {
        # Извлекаем количество остановленных процессов
        if ($output -match "Остановлено процессов: (\d+)") {
            $stoppedCount = [int]$matches[1]
            Write-Host "  Остановлено процессов: $stoppedCount" -ForegroundColor Gray
        }
        return "PASS"
    } else {
        return "Неожиданный вывод STOP_ALL.ps1"
    }
}

Start-Sleep 5

Test-Step "6.2 - Порт 8004 освобождён" {
    $listener = netstat -ano | Select-String ":8004" | Select-String "LISTENING"
    if (-not $listener) {
        return "PASS"
    } else {
        return "Порт всё ещё занят"
    }
}

Test-Step "6.3 - Порт 7860 освобождён" {
    $listener = netstat -ano | Select-String ":7860" | Select-String "LISTENING"
    if (-not $listener) {
        return "PASS"
    } else {
        return "Порт всё ещё занят"
    }
}

Test-Step "6.4 - Порт 8501 освобождён" {
    $listener = netstat -ano | Select-String ":8501" | Select-String "LISTENING"
    if (-not $listener) {
        return "PASS"
    } else {
        return "Порт всё ещё занят"
    }
}

Test-Step "6.5 - Процессы Python (CORTEX) остановлены" {
    $cortexProcs = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*lightrag_server*"
    }
    if (-not $cortexProcs) {
        return "PASS"
    } else {
        return "Найдено процессов: $(($cortexProcs | Measure-Object).Count)"
    }
}

# Очистка фоновых job'ов (созданных START_ALL_TEST.ps1)
Write-Host "`n=== Очистка фоновых процессов ===" -ForegroundColor Gray
Get-Job | Stop-Job -ErrorAction SilentlyContinue
Get-Job | Remove-Job -ErrorAction SilentlyContinue
Write-Host "✓ Все фоновые задачи остановлены" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════
# ФИНАЛЬНЫЙ ОТЧЁТ
# ═══════════════════════════════════════════════════════════════
Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║              📊 ФИНАЛЬНЫЙ ОТЧЁТ E2E ТЕСТИРОВАНИЯ               ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta

Write-Host "Всего тестов: $($testsPassed + $testsFailed)" -ForegroundColor Cyan
Write-Host "✅ Успешно: $testsPassed" -ForegroundColor Green
Write-Host "❌ Провалено: $testsFailed`n" -ForegroundColor $(if ($testsFailed -gt 0) { "Red" } else { "Gray" })

if ($testsFailed -gt 0) {
    Write-Host "═══════ ПРОВАЛИВШИЕСЯ ТЕСТЫ ═══════" -ForegroundColor Red
    $testResults | Where-Object { $_.Status -eq "❌ FAILED" } | Format-Table -AutoSize
}

Write-Host "`n═══════ СВОДНАЯ ТАБЛИЦА ВСЕХ ТЕСТОВ ═══════" -ForegroundColor Cyan
$testResults | Format-Table -AutoSize

# Итоговый вердикт
$successRate = [math]::Round(($testsPassed / ($testsPassed + $testsFailed)) * 100, 1)

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor $(if ($successRate -ge 90) { "Green" } elseif ($successRate -ge 70) { "Yellow" } else { "Red" })
Write-Host "║              ИТОГОВЫЙ ВЕРДИКТ: $successRate% УСПЕШНО" -NoNewline
Write-Host (" " * (25 - $successRate.ToString().Length)) -NoNewline
Write-Host "║" -ForegroundColor $(if ($successRate -ge 90) { "Green" } elseif ($successRate -ge 70) { "Yellow" } else { "Red" })
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor $(if ($successRate -ge 90) { "Green" } elseif ($successRate -ge 70) { "Yellow" } else { "Red" })

if ($successRate -ge 90) {
    Write-Host "🎉 ОТЛИЧНО! Система работает корректно." -ForegroundColor Green
} elseif ($successRate -ge 70) {
    Write-Host "⚠️  ПРЕДУПРЕЖДЕНИЕ: Некоторые тесты провалились." -ForegroundColor Yellow
} else {
    Write-Host "🚨 КРИТИЧНО: Множественные отказы, требуется диагностика!" -ForegroundColor Red
}

Write-Host "`nДата тестирования: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Версия тестов: E2E v1.0`n" -ForegroundColor Gray

# Возвращаем exit code
if ($testsFailed -eq 0) {
    exit 0
} else {
    exit 1
}
