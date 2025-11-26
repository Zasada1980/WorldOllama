<#
.SYNOPSIS
    ✅ WORLD_OLLAMA - Проверка Статуса Системы

.DESCRIPTION
    Проверяет состояние всех компонентов:
    - Ollama (модели)
    - CORTEX (база знаний)
    - LLaMA Board (обучение)
    - Neuro-Terminal (интерфейс)
    
.EXAMPLE
    .\CHECK_STATUS.ps1
    
    Выводит таблицу со статусами всех сервисов.

.NOTES
    Автор: SESA3002a
    Дата: 26.11.2025
#>

$ErrorActionPreference = "Continue"

# Автоматический переход в директорию USER
Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           ✅ WORLD_OLLAMA - СТАТУС СИСТЕМЫ                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Цвета для статусов
function Get-StatusColor {
    param($status)
    switch ($status) {
        "🟢 РАБОТАЕТ" { return "Green" }
        "🔴 ОСТАНОВЛЕН" { return "Red" }
        "🟡 ПРОБЛЕМА" { return "Yellow" }
        default { return "Gray" }
    }
}

# Проверка Ollama
Write-Host "=== Ollama (Модели) ===" -ForegroundColor Yellow
try {
    $ollamaResp = Invoke-RestMethod http://localhost:11434/api/tags -TimeoutSec 3
    $ollamaStatus = "🟢 РАБОТАЕТ"
    $ollamaModels = ($ollamaResp.models | Where-Object { $_.name -like "*qwen*" -or $_.name -like "*nomic*" }).Count
    Write-Host "Статус: $ollamaStatus" -ForegroundColor Green
    Write-Host "Моделей (qwen/nomic): $ollamaModels`n" -ForegroundColor Cyan
} catch {
    $ollamaStatus = "🔴 ОСТАНОВЛЕН"
    Write-Host "Статус: $ollamaStatus" -ForegroundColor Red
    Write-Host "Ошибка: $($_.Exception.Message)`n" -ForegroundColor Gray
}

# Проверка CORTEX
Write-Host "=== CORTEX (База Знаний) ===" -ForegroundColor Yellow
try {
    $cortexResp = Invoke-RestMethod http://localhost:8004/health -TimeoutSec 5
    $cortexStatus = "🟢 РАБОТАЕТ"
    Write-Host "Статус: $cortexStatus" -ForegroundColor Green
    Write-Host "Состояние: $($cortexResp.status)" -ForegroundColor Cyan
    
    # Проверка статистики с API ключом
    try {
        $headers = @{"X-API-KEY" = $env:CORTEX_API_KEY}
        if (-not $env:CORTEX_API_KEY) {
            $headers = @{"X-API-KEY" = "sesa-secure-core-v1"}
        }
        $statsResp = Invoke-RestMethod http://localhost:8004/status -Headers $headers -TimeoutSec 5
        Write-Host "Документов обработано: $($statsResp.processed_count)" -ForegroundColor Cyan
        Write-Host "Документов в обработке: $($statsResp.processing_count)" -ForegroundColor Cyan
        Write-Host "Всего документов: $($statsResp.total_count)`n" -ForegroundColor Cyan
    } catch {
        Write-Host "Статистика недоступна (проверьте API Key)`n" -ForegroundColor Yellow
    }
} catch {
    $cortexStatus = "🔴 ОСТАНОВЛЕН"
    Write-Host "Статус: $cortexStatus" -ForegroundColor Red
    Write-Host "Ошибка: $($_.Exception.Message)`n" -ForegroundColor Gray
}

# Проверка LLaMA Board
Write-Host "=== LLaMA Board (Обучение) ===" -ForegroundColor Yellow
try {
    $llamaResp = Invoke-WebRequest http://localhost:7860 -TimeoutSec 5 -UseBasicParsing
    if ($llamaResp.StatusCode -eq 200) {
        $llamaStatus = "🟢 РАБОТАЕТ"
        Write-Host "Статус: $llamaStatus" -ForegroundColor Green
        Write-Host "URL: http://localhost:7860`n" -ForegroundColor Cyan
    }
} catch {
    $llamaStatus = "🔴 ОСТАНОВЛЕН"
    Write-Host "Статус: $llamaStatus" -ForegroundColor Red
    Write-Host "Ошибка: $($_.Exception.Message)`n" -ForegroundColor Gray
}

# Проверка Neuro-Terminal
Write-Host "=== Neuro-Terminal (Интерфейс) ===" -ForegroundColor Yellow
try {
    $neuroResp = Invoke-WebRequest http://localhost:8501 -TimeoutSec 5 -UseBasicParsing
    if ($neuroResp.StatusCode -eq 200) {
        $neuroStatus = "🟢 РАБОТАЕТ"
        Write-Host "Статус: $neuroStatus" -ForegroundColor Green
        Write-Host "URL: http://localhost:8501`n" -ForegroundColor Cyan
    }
} catch {
    $neuroStatus = "🔴 ОСТАНОВЛЕН"
    Write-Host "Статус: $neuroStatus" -ForegroundColor Red
    Write-Host "Ошибка: $($_.Exception.Message)`n" -ForegroundColor Gray
}

# Проверка портов (альтернативный метод)
Write-Host "=== Проверка Портов (netstat) ===" -ForegroundColor Yellow
$ports = @{
    "11434" = "Ollama"
    "8004"  = "CORTEX"
    "7860"  = "LLaMA Board"
    "8501"  = "Neuro-Terminal"
}

# 6. ДИАГНОСТИКА PYTHON ПРОЦЕССОВ (защита от перегрузки)
Write-Host "`n🐍 АКТИВНЫЕ PYTHON ПРОЦЕССЫ:" -ForegroundColor Magenta
$pythonProcs = Get-Process python -ErrorAction SilentlyContinue | Where-Object {$_.WorkingSet -gt 50MB} | Where-Object {
    # Исключаем MSI Afterburner и другие системные утилиты
    $_.Path -notlike "*MSI Afterburner*" -and $_.Path -notlike "*RivaTuner*"
}
if ($pythonProcs) {
    $pythonProcs | Select-Object Id, @{N='RAM_GB';E={[math]::Round($_.WorkingSet/1GB,2)}}, @{N='CPU_sec';E={[math]::Round($_.CPU,1)}}, @{N='Uptime_min';E={[math]::Round(((Get-Date) - $_.StartTime).TotalMinutes,1)}} | Sort-Object RAM_GB -Descending | Format-Table -AutoSize
    
    $totalRAM = ($pythonProcs | Measure-Object -Property WorkingSet -Sum).Sum / 1GB
    $ramColor = if($totalRAM -gt 12){'Red'}elseif($totalRAM -gt 8){'Yellow'}else{'Green'}
    Write-Host "  📊 Общая память Python процессов: $([math]::Round($totalRAM,2)) GB" -ForegroundColor $ramColor
    
    if ($totalRAM -gt 14) {
        Write-Host "  ⚠️  КРИТИЧЕСКАЯ ПЕРЕГРУЗКА! Рекомендуется остановить процессы через STOP_ALL.ps1" -ForegroundColor Red
    } elseif ($totalRAM -gt 10) {
        Write-Host "  ⚠️  Высокая нагрузка. Возможно обучение модели в процессе." -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✓ Нет активных Python процессов (RAM > 50MB)" -ForegroundColor Green
}

# 7. GPU СТАТУС
Write-Host "`n🎮 GPU СТАТУС:" -ForegroundColor Cyan
try {
    $gpuInfo = nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader
    Write-Host "  $gpuInfo" -ForegroundColor White
    
    # Парсинг VRAM
    if ($gpuInfo -match '(\d+)\s*MiB,\s*(\d+)\s*MiB') {
        $vramUsed = [int]$matches[1]
        $vramTotal = [int]$matches[2]
        $vramPercent = [math]::Round(($vramUsed / $vramTotal) * 100, 1)
        
        $vramColor = if($vramPercent -gt 90){'Red'}elseif($vramPercent -gt 70){'Yellow'}else{'Green'}
        Write-Host "  📊 VRAM: $vramUsed MB / $vramTotal MB ($vramPercent%)" -ForegroundColor $vramColor
    }
} catch {
    Write-Host "  ⚠️  nvidia-smi недоступен" -ForegroundColor Yellow
}

# Финальная таблица
Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              СВОДНАЯ ТАБЛИЦА СТАТУСОВ                          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "Сервис               Порт    Статус" -ForegroundColor White
Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "Ollama               11434   $ollamaStatus" -ForegroundColor $(Get-StatusColor $ollamaStatus)
Write-Host "CORTEX               8004    $cortexStatus" -ForegroundColor $(Get-StatusColor $cortexStatus)
Write-Host "LLaMA Board          7860    $llamaStatus" -ForegroundColor $(Get-StatusColor $llamaStatus)
Write-Host "Neuro-Terminal       8501    $neuroStatus" -ForegroundColor $(Get-StatusColor $neuroStatus)

Write-Host "`nДля запуска: .\START_ALL.ps1" -ForegroundColor Cyan
Write-Host "Для остановки: .\STOP_ALL.ps1`n" -ForegroundColor Yellow
