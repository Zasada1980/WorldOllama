<#
.SYNOPSIS
    🚀 WORLD_OLLAMA - Запуск Всей Системы (Одна Кнопка)

.DESCRIPTION
    Последовательный запуск всех компонентов:
    1. CORTEX (LightRAG) - База знаний
    2. LLaMA Board - Обучение моделей
    3. Neuro-Terminal - Интерфейс пользователя
    
    Применяет ТРИЗ Принцип №10 "Предварительное действие":
    Сначала база знаний, затем инструменты, затем интерфейс.

.EXAMPLE
    .\START_ALL.ps1
    
    Система запустится в 3 отдельных окнах PowerShell.
    Каждый сервис логируется в своём окне.

.NOTES
    Автор: SESA3002a
    Дата: 26.11.2025
    Время запуска: ~40-60 секунд
#>

$ErrorActionPreference = "Continue"

# Автоматический переход в директорию USER
Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           🚀 WORLD_OLLAMA - ПОЛНЫЙ ЗАПУСК СИСТЕМЫ              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "Применяется ТРИЗ Принцип №10 'Предварительное действие':" -ForegroundColor Yellow
Write-Host "  1. База знаний (CORTEX)" -ForegroundColor Gray
Write-Host "  2. Инструменты обучения (LLaMA Board)" -ForegroundColor Gray
Write-Host "  3. Пользовательский интерфейс (Neuro-Terminal)`n" -ForegroundColor Gray

# ПРОВЕРКА АКТИВНЫХ PYTHON ПРОЦЕССОВ (защита от перегрузки памяти)
Write-Host "=== ДИАГНОСТИКА: Активные Python процессы ===" -ForegroundColor Magenta
$activePython = Get-Process python -ErrorAction SilentlyContinue | Where-Object {$_.WorkingSet -gt 100MB} | Where-Object {
    # Исключаем MSI Afterburner и системные утилиты мониторинга
    $_.Path -notlike "*MSI Afterburner*" -and $_.Path -notlike "*RivaTuner*"
}
if ($activePython) {
    Write-Host "⚠️  ВНИМАНИЕ: Обнаружены активные Python процессы:`n" -ForegroundColor Yellow
    $activePython | Select-Object Id, @{N='RAM_GB';E={[math]::Round($_.WorkingSet/1GB,2)}}, @{N='CPU';E={[math]::Round($_.CPU,1)}} | Format-Table -AutoSize
    
    $totalRAM = ($activePython | Measure-Object -Property WorkingSet -Sum).Sum / 1GB
    Write-Host "📊 Общая память: $([math]::Round($totalRAM,2)) GB`n" -ForegroundColor Cyan
    
    $response = Read-Host "Продолжить запуск? Это может привести к перегрузке памяти (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "`n❌ Запуск отменен. Сначала остановите активные процессы через STOP_ALL.ps1`n" -ForegroundColor Red
        exit
    }
    Write-Host ""
} else {
    Write-Host "✓ Нет активных Python процессов (RAM > 100MB)" -ForegroundColor Green
}

# Проверка Ollama
Write-Host "`n=== ШАГ 0: Проверка Ollama ===" -ForegroundColor Yellow
try {
    $ollamaTest = Invoke-RestMethod http://localhost:11434/api/tags -TimeoutSec 3
    Write-Host "✓ Ollama работает" -ForegroundColor Green
} catch {
    Write-Host "✗ Ollama не запущен!" -ForegroundColor Red
    Write-Host "  Запустите: ollama serve" -ForegroundColor Yellow
    Read-Host "  Нажмите Enter после запуска Ollama"
}

# Запуск CORTEX
Write-Host "`n=== ШАГ 1: Запуск CORTEX (База Знаний) ===" -ForegroundColor Yellow
Write-Host "Порт: 8004 | Защита: API Key`n" -ForegroundColor Cyan

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd E:\WORLD_OLLAMA\services\lightrag; & .\venv\Scripts\Activate.ps1; Write-Host '🔒 CORTEX - База Знаний (LightRAG)' -ForegroundColor Cyan; python lightrag_server.py"
Write-Host "✓ CORTEX запускается в отдельном окне..." -ForegroundColor Green
Write-Host "  Ожидание инициализации (20 сек)..." -ForegroundColor Gray
Start-Sleep 20

# Проверка CORTEX
try {
    $cortexHealth = Invoke-RestMethod http://localhost:8004/health -TimeoutSec 5
    Write-Host "✓ CORTEX онлайн ($($cortexHealth.status))" -ForegroundColor Green
} catch {
    Write-Host "⚠ CORTEX ещё инициализируется (проверьте окно)" -ForegroundColor Yellow
}

# Запуск LLaMA Board
Write-Host "`n=== ШАГ 2: Запуск LLaMA Board (Обучение) ===" -ForegroundColor Yellow
Write-Host "Порт: 7860 | Функция: Fine-tuning`n" -ForegroundColor Cyan

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd E:\WORLD_OLLAMA\services\llama_factory; & .\venv\Scripts\Activate.ps1; Write-Host '🏋️ LLaMA Board - Обучение Моделей' -ForegroundColor Cyan; llamafactory-cli webui"
Write-Host "✓ LLaMA Board запускается в отдельном окне..." -ForegroundColor Green
Write-Host "  Ожидание инициализации (30 сек)..." -ForegroundColor Gray
Start-Sleep 30

# Проверка LLaMA Board
try {
    $llamaTest = Invoke-WebRequest http://localhost:7860 -TimeoutSec 5 -UseBasicParsing
    if ($llamaTest.StatusCode -eq 200) {
        Write-Host "✓ LLaMA Board онлайн" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠ LLaMA Board ещё инициализируется (проверьте окно)" -ForegroundColor Yellow
}

# Запуск Neuro-Terminal
Write-Host "`n=== ШАГ 3: Запуск Neuro-Terminal (UI) ===" -ForegroundColor Yellow
Write-Host "Порт: 8501 | Функция: Главный интерфейс`n" -ForegroundColor Cyan

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd E:\WORLD_OLLAMA\services\neuro_terminal; & .\.venv\Scripts\Activate.ps1; Write-Host '🌐 Neuro-Terminal - Главный Интерфейс' -ForegroundColor Cyan; chainlit run app.py --port 8501"
Write-Host "✓ Neuro-Terminal запускается в отдельном окне..." -ForegroundColor Green
Write-Host "  Ожидание инициализации (15 сек)..." -ForegroundColor Gray
Start-Sleep 15

# Проверка Neuro-Terminal
try {
    $neuroTest = Invoke-WebRequest http://localhost:8501 -TimeoutSec 5 -UseBasicParsing
    if ($neuroTest.StatusCode -eq 200) {
        Write-Host "✓ Neuro-Terminal онлайн" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠ Neuro-Terminal ещё инициализируется (проверьте окно)" -ForegroundColor Yellow
}

# Финальный отчёт
Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              ✓ СИСТЕМА ЗАПУЩЕНА УСПЕШНО                       ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "Активные сервисы:" -ForegroundColor Cyan
Write-Host "  🌐 Neuro-Terminal:  http://localhost:8501 (ГЛАВНЫЙ ИНТЕРФЕЙС)" -ForegroundColor White
Write-Host "  🔒 CORTEX:          http://localhost:8004 (База знаний)" -ForegroundColor White
Write-Host "  🏋️  LLaMA Board:     http://localhost:7860 (Обучение)" -ForegroundColor White

Write-Host "`nКаждый сервис работает в своём окне PowerShell." -ForegroundColor Gray
Write-Host "Для остановки всех сервисов: .\STOP_ALL.ps1`n" -ForegroundColor Yellow

Write-Host "Откройте браузер: http://localhost:8501" -ForegroundColor Cyan
Write-Host "Система готова к работе! 🚀`n" -ForegroundColor Green
