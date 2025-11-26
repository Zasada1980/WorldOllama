<#
.SYNOPSIS
    🚀 WORLD_OLLAMA - Запуск Всей Системы (ТЕСТОВАЯ ВЕРСИЯ)

.DESCRIPTION
    Версия для E2E тестирования - запускает все сервисы в фоновых процессах
    БЕЗ создания отдельных окон PowerShell.
    
    НЕ для ручного использования! Только для автоматизированных тестов.

.NOTES
    Автор: SESA3002a
    Дата: 26.11.2025
#>

$ErrorActionPreference = "Continue"

# Автоматический переход в директорию USER
Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           🧪 WORLD_OLLAMA - ЗАПУСК (ТЕСТОВЫЙ РЕЖИМ)            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Проверка Ollama
Write-Host "=== ШАГ 0: Проверка Ollama ===" -ForegroundColor Yellow
try {
    Invoke-RestMethod http://localhost:11434/api/tags -TimeoutSec 3 | Out-Null
    Write-Host "✓ Ollama работает" -ForegroundColor Green
} catch {
    Write-Host "✗ Ollama не запущен!" -ForegroundColor Red
    exit 1
}

# Запуск CORTEX в фоновом режиме
Write-Host "`n=== ШАГ 1: Запуск CORTEX ===" -ForegroundColor Yellow
$cortexScript = {
    Set-Location E:\WORLD_OLLAMA\services\lightrag
    & .\venv\Scripts\Activate.ps1
    python lightrag_server.py
}
$cortexJob = Start-Job -ScriptBlock $cortexScript -Name "CORTEX_TEST"
Write-Host "✓ CORTEX запущен (JobId: $($cortexJob.Id))" -ForegroundColor Green
Start-Sleep 20

# Запуск LLaMA Board в фоновом режиме
Write-Host "`n=== ШАГ 2: Запуск LLaMA Board ===" -ForegroundColor Yellow
$llamaScript = {
    Set-Location E:\WORLD_OLLAMA\services\llama_factory
    & .\venv\Scripts\Activate.ps1
    llamafactory-cli webui
}
$llamaJob = Start-Job -ScriptBlock $llamaScript -Name "LLAMA_TEST"
Write-Host "✓ LLaMA Board запущен (JobId: $($llamaJob.Id))" -ForegroundColor Green
Start-Sleep 30

# Запуск Neuro-Terminal в фоновом режиме
Write-Host "`n=== ШАГ 3: Запуск Neuro-Terminal ===" -ForegroundColor Yellow
$neuroScript = {
    Set-Location E:\WORLD_OLLAMA\services\neuro_terminal
    & .\.venv\Scripts\Activate.ps1
    chainlit run app.py --port 8501
}
$neuroJob = Start-Job -ScriptBlock $neuroScript -Name "NEURO_TEST"
Write-Host "✓ Neuro-Terminal запущен (JobId: $($neuroJob.Id))" -ForegroundColor Green
Start-Sleep 15

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              ✓ ВСЕ СЕРВИСЫ ЗАПУЩЕНЫ (ТЕСТОВЫЙ РЕЖИМ)          ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "JobId список:" -ForegroundColor Cyan
Write-Host "  CORTEX:          $($cortexJob.Id)" -ForegroundColor White
Write-Host "  LLaMA Board:     $($llamaJob.Id)" -ForegroundColor White
Write-Host "  Neuro-Terminal:  $($neuroJob.Id)" -ForegroundColor White

Write-Host "`nДля остановки: Get-Job | Stop-Job; Get-Job | Remove-Job`n" -ForegroundColor Yellow
