<#
.SYNOPSIS
    🛑 WORLD_OLLAMA - Остановка Всех Сервисов

.DESCRIPTION
    Корректное завершение всех компонентов:
    - Neuro-Terminal (Chainlit)
    - CORTEX (LightRAG)
    - LLaMA Board (LLaMA-Factory)
    
.EXAMPLE
    .\STOP_ALL.ps1
    
    Все сервисы будут остановлены.

.NOTES
    Автор: SESA3002a
    Дата: 26.11.2025
#>

$ErrorActionPreference = "Continue"

# Автоматический переход в директорию USER
Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║           🛑 WORLD_OLLAMA - ОСТАНОВКА СИСТЕМЫ                  ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Yellow

$stopped = 0
$notFound = 0

# Остановка Neuro-Terminal (Chainlit)
Write-Host "=== Остановка Neuro-Terminal (Chainlit) ===" -ForegroundColor Yellow
$chainlitProcs = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*chainlit*" -or $_.CommandLine -like "*app.py*"
} | Where-Object {
    # Исключаем MSI Afterburner и системные процессы
    $_.Path -notlike "*MSI Afterburner*" -and 
    $_.Path -notlike "*RivaTuner*"
}
if ($chainlitProcs) {
    $chainlitProcs | Stop-Process -Force
    $count = ($chainlitProcs | Measure-Object).Count
    Write-Host "✓ Остановлено процессов Chainlit: $count" -ForegroundColor Green
    $stopped += $count
} else {
    Write-Host "⚠ Chainlit не запущен" -ForegroundColor Gray
    $notFound++
}

# Остановка CORTEX (LightRAG)
Write-Host "`n=== Остановка CORTEX (LightRAG) ===" -ForegroundColor Yellow
$cortexProcs = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*lightrag_server*"
} | Where-Object {
    # Исключаем MSI Afterburner
    $_.Path -notlike "*MSI Afterburner*" -and $_.Path -notlike "*RivaTuner*"
}
if ($cortexProcs) {
    $cortexProcs | Stop-Process -Force
    $count = ($cortexProcs | Measure-Object).Count
    Write-Host "✓ Остановлено процессов CORTEX: $count" -ForegroundColor Green
    $stopped += $count
} else {
    Write-Host "⚠ CORTEX не запущен" -ForegroundColor Gray
    $notFound++
}

# Остановка LLaMA Board
Write-Host "`n=== Остановка LLaMA Board ===" -ForegroundColor Yellow
$llamaProcs = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*llamafactory*" -or $_.CommandLine -like "*webui*"
} | Where-Object {
    # Исключаем MSI Afterburner
    $_.Path -notlike "*MSI Afterburner*" -and $_.Path -notlike "*RivaTuner*"
}
if ($llamaProcs) {
    $llamaProcs | Stop-Process -Force
    $count = ($llamaProcs | Measure-Object).Count
    Write-Host "✓ Остановлено процессов LLaMA Board: $count" -ForegroundColor Green
    $stopped += $count
} else {
    Write-Host "⚠ LLaMA Board не запущен" -ForegroundColor Gray
    $notFound++
}

# ФИНАЛЬНАЯ ПРОВЕРКА: Поиск зависших больших Python процессов
Write-Host "`n=== Дополнительная проверка: Большие Python процессы ===" -ForegroundColor Magenta
$bigPython = Get-Process python -ErrorAction SilentlyContinue | Where-Object {$_.WorkingSet -gt 200MB} | Where-Object {
    # Исключаем MSI Afterburner и системные утилиты
    $_.Path -notlike "*MSI Afterburner*" -and $_.Path -notlike "*RivaTuner*"
}

if ($bigPython) {
    Write-Host "⚠️  Найдены большие Python процессы (возможно обучение модели):`n" -ForegroundColor Yellow
    $bigPython | Select-Object Id, @{N='RAM_GB';E={[math]::Round($_.WorkingSet/1GB,2)}}, @{N='CPU';E={[math]::Round($_.CPU,1)}} | Format-Table -AutoSize
    
    $response = Read-Host "`nОстановить эти процессы? Это прервет обучение! (y/N)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        $bigPython | Stop-Process -Force
        Write-Host "✓ Остановлено процессов: $($bigPython.Count)" -ForegroundColor Green
        $stopped += $bigPython.Count
    } else {
        Write-Host "⚠️  Процессы оставлены активными" -ForegroundColor Yellow
    }
} else {
    Write-Host "✓ Нет больших Python процессов" -ForegroundColor Green
}

# Финальный отчёт
Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
if ($stopped -gt 0) {
    Write-Host "║              ✓ СИСТЕМА ОСТАНОВЛЕНА                             ║" -ForegroundColor Green
} else {
    Write-Host "║              ⚠ НЕТ ЗАПУЩЕННЫХ СЕРВИСОВ                         ║" -ForegroundColor Yellow
}
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "Остановлено процессов: $stopped" -ForegroundColor Cyan
Write-Host "Не найдено: $notFound`n" -ForegroundColor Gray

if ($stopped -gt 0) {
    Write-Host "Все окна PowerShell с сервисами можно закрыть." -ForegroundColor Yellow
}

Write-Host "Для запуска системы: .\START_ALL.ps1`n" -ForegroundColor Cyan
