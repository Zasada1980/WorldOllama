#!/usr/bin/env pwsh
# AUTO-TEST SCRIPT для CORE BRIDGE
# Запускает все 3 теста и выводит результаты

Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🧪 АВТОМАТИЧЕСКИЕ ТЕСТЫ CORE BRIDGE                     ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "📋 Проверка сервисов перед тестами..." -ForegroundColor Yellow

# Проверка Ollama
$ollamaOk = $false
try {
    $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 3 -ErrorAction Stop
    Write-Host "  ✅ Ollama (11434): РАБОТАЕТ" -ForegroundColor Green
    $ollamaOk = $true
} catch {
    Write-Host "  ❌ Ollama (11434): НЕ ДОСТУПЕН" -ForegroundColor Red
    Write-Host "     Запустите: ollama serve" -ForegroundColor Yellow
}

# Проверка CORTEX
$cortexOk = $false
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8004/health" -TimeoutSec 3 -ErrorAction Stop
    Write-Host "  ✅ CORTEX (8004): РАБОТАЕТ" -ForegroundColor Green
    $cortexOk = $true
} catch {
    Write-Host "  ❌ CORTEX (8004): НЕ ДОСТУПЕН" -ForegroundColor Red
    Write-Host "     Запустите: pwsh scripts\START_ALL.ps1" -ForegroundColor Yellow
}

if (-not $ollamaOk -or -not $cortexOk) {
    Write-Host "`n⚠️  Некоторые сервисы не доступны. Тесты могут провалиться.`n" -ForegroundColor Yellow
    Read-Host "Нажмите Enter для продолжения или Ctrl+C для отмены"
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

# Функция для выполнения HTTP запросов к Tauri backend (через прямые вызовы)
function Test-TauriCommand {
    param(
        [string]$TestName,
        [string]$Endpoint,
        [hashtable]$Body = @{}
    )
    
    Write-Host "`n🔬 $TestName" -ForegroundColor Cyan
    Write-Host "   Endpoint: $Endpoint" -ForegroundColor Gray
    
    try {
        $headers = @{
            "Content-Type" = "application/json"
        }
        
        $jsonBody = $Body | ConvertTo-Json -Depth 10
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-RestMethod -Uri $Endpoint -Method Post -Body $jsonBody -Headers $headers -TimeoutSec 30
        $stopwatch.Stop()
        
        $elapsed = $stopwatch.Elapsed.TotalSeconds.ToString("F2")
        
        Write-Host "   ✅ Успешно (${elapsed}s)" -ForegroundColor Green
        Write-Host "   Ответ:" -ForegroundColor Yellow
        $response | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor White
        
        return @{
            success = $true
            time = $elapsed
            response = $response
        }
    } catch {
        Write-Host "   ❌ ОШИБКА: $($_.Exception.Message)" -ForegroundColor Red
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

# АЛЬТЕРНАТИВНЫЙ ПОДХОД: Прямые HTTP запросы к сервисам
# (т.к. Tauri commands доступны только внутри приложения)

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📝 ВНИМАНИЕ: Tauri commands доступны только внутри приложения" -ForegroundColor Yellow
Write-Host "   Выполняем прямые HTTP запросы к сервисам для проверки..." -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

$totalTests = 0
$passedTests = 0
$failedTests = 0
$totalTime = 0

# TEST 1: Проверка статуса Ollama
Write-Host "`n🧪 TEST 1: Ollama Status Check" -ForegroundColor Cyan
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5
    $stopwatch.Stop()
    $elapsed = $stopwatch.Elapsed.TotalSeconds.ToString("F2")
    
    Write-Host "   ✅ УСПЕШНО (${elapsed}s)" -ForegroundColor Green
    Write-Host "   Модели: $($response.models.Count) шт." -ForegroundColor White
    $response.models | ForEach-Object { Write-Host "     - $($_.name)" -ForegroundColor Gray }
    
    $passedTests++
    $totalTime += $elapsed
} catch {
    Write-Host "   ❌ ПРОВАЛ: $($_.Exception.Message)" -ForegroundColor Red
    $failedTests++
}
$totalTests++

# TEST 2: Ollama Chat
Write-Host "`n🧪 TEST 2: Ollama Chat (POST /api/chat)" -ForegroundColor Cyan
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $body = @{
        model = "qwen2.5:14b"
        messages = @(
            @{
                role = "user"
                content = "Привет! Ответь одним предложением: что такое ТРИЗ?"
            }
        )
        stream = $false
    } | ConvertTo-Json -Depth 10
    
    $response = Invoke-RestMethod -Uri "http://localhost:11434/api/chat" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 60
    $stopwatch.Stop()
    $elapsed = $stopwatch.Elapsed.TotalSeconds.ToString("F2")
    
    Write-Host "   ✅ УСПЕШНО (${elapsed}s)" -ForegroundColor Green
    Write-Host "   Модель: $($response.model)" -ForegroundColor White
    Write-Host "   Ответ: $($response.message.content)" -ForegroundColor White
    Write-Host "   Токены: $($response.eval_count) eval, $($response.prompt_eval_count) prompt" -ForegroundColor Gray
    
    $passedTests++
    $totalTime += $elapsed
} catch {
    Write-Host "   ❌ ПРОВАЛ: $($_.Exception.Message)" -ForegroundColor Red
    $failedTests++
}
$totalTests++

# TEST 3: CORTEX RAG Query
Write-Host "`n🧪 TEST 3: CORTEX RAG Query (POST /query)" -ForegroundColor Cyan
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $body = @{
        query = "Что такое принцип дробления в ТРИЗ?"
        top_k = 10
        mode = "local"
    } | ConvertTo-Json
    
    $headers = @{
        "Content-Type" = "application/json"
        "X-API-KEY" = "sesa-secure-core-v1"  # Default CORTEX API key
    }
    
    $response = Invoke-RestMethod -Uri "http://localhost:8004/query" -Method Post -Body $body -Headers $headers -TimeoutSec 90
    $stopwatch.Stop()
    $elapsed = $stopwatch.Elapsed.TotalSeconds.ToString("F2")
    
    Write-Host "   ✅ УСПЕШНО (${elapsed}s)" -ForegroundColor Green
    
    # CORTEX может возвращать либо 'answer', либо 'response'
    $answer = if ($response.answer) { $response.answer } elseif ($response.response) { $response.response } else { $null }
    
    if ($answer) {
        $answerPreview = if ($answer.Length -gt 200) { 
            $answer.Substring(0, 200) + "..." 
        } else { 
            $answer 
        }
        Write-Host "   Ответ: $answerPreview" -ForegroundColor White
    } else {
        Write-Host "   ⚠️  Ответ: (пустой ответ от CORTEX)" -ForegroundColor Yellow
    }
    
    if ($response.sources) {
        Write-Host "   Источники: $($response.sources.Count) шт." -ForegroundColor White
        $response.sources | Select-Object -First 3 | ForEach-Object {
            $preview = if ($_.Length -gt 80) { $_.Substring(0, 80) + "..." } else { $_ }
            Write-Host "     - $preview" -ForegroundColor Gray
        }
    } else {
        Write-Host "   Источники: нет данных" -ForegroundColor Gray
    }
    
    $passedTests++
    $totalTime += $elapsed
} catch {
    Write-Host "   ❌ ПРОВАЛ: $($_.Exception.Message)" -ForegroundColor Red
    $failedTests++
}
$totalTests++

# ИТОГОВЫЙ ОТЧЁТ
Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  📊 ИТОГОВЫЙ ОТЧЁТ                                        ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n  Всего тестов:       $totalTests" -ForegroundColor White
Write-Host "  ✅ Успешно:          $passedTests" -ForegroundColor Green
Write-Host "  ❌ Провалено:        $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { 'Red' } else { 'Gray' })
Write-Host "  ⏱️  Общее время:      $($totalTime.ToString('F2'))s" -ForegroundColor White

$successRate = [Math]::Round(($passedTests / $totalTests) * 100, 2)
Write-Host "`n  Процент успеха:     ${successRate}%" -ForegroundColor $(if ($successRate -eq 100) { 'Green' } elseif ($successRate -ge 66) { 'Yellow' } else { 'Red' })

if ($passedTests -eq $totalTests) {
    Write-Host "`n  🎉 ВСЕ ТЕСТЫ ПРОЙДЕНЫ!" -ForegroundColor Green
} else {
    Write-Host "`n  ⚠️  ЕСТЬ ПРОВАЛЕННЫЕ ТЕСТЫ" -ForegroundColor Red
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

Write-Host "💡 Для проверки Tauri commands откройте:" -ForegroundColor Yellow
Write-Host "   http://localhost:1420/test (если Tauri dev запущен)`n" -ForegroundColor White
