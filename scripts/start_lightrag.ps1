<#
.SYNOPSIS
    LightRAG Server Launcher (CORTEX - TD-006)
.DESCRIPTION
    Запуск когнитивного ядра WORLD_OLLAMA с логированием
    
    Архитектура:
    - Модель: mistral-small:latest (Ollama port 11434)
    - Embeddings: nomic-embed-text
    - Индекс: E:\WORLD_OLLAMA\services\lightrag\data
    - Источник: E:\WORLD_OLLAMA\library\raw_documents (131 файл)
    
.NOTES
    Версия: 1.0 (25.11.2025 - TD-006 CORTEX Deployment)
    Автор: SESA Development Protocol
    Порт: 8004 (избежание конфликта с 8003)
    
.EXAMPLE
    # Стандартный запуск
    pwsh .\scripts\start_lightrag.ps1
    
    # С подробным логированием
    pwsh .\scripts\start_lightrag.ps1 -Verbose
#>

[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$ServicePath = "",
    [string]$LogPath = "",
    [int]$Port = 8004
)

# Автоопределение путей если не указаны
if ([string]::IsNullOrEmpty($ServicePath)) {
    $ServicePath = Join-Path $ProjectRoot "services\lightrag"
}
if ([string]::IsNullOrEmpty($LogPath)) {
    $LogPath = Join-Path $ServicePath "logs\cortex.log"
}

# Переход в директорию сервиса
Set-Location $ServicePath

# Проверка виртуального окружения
if (-not (Test-Path ".\venv\Scripts\Activate.ps1")) {
    Write-Host "[ERROR] Virtual environment not found!" -ForegroundColor Red
    Write-Host "Run: python -m venv venv" -ForegroundColor Yellow
    exit 1
}

# Проверка Ollama
Write-Host "`n=== CORTEX PRE-FLIGHT CHECK ===" -ForegroundColor Cyan
Write-Host "Checking Ollama (port 11434)..." -NoNewline

try {
    $ollamaTest = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 3
    Write-Host " OK" -ForegroundColor Green
} catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "[ERROR] Ollama not responding on port 11434" -ForegroundColor Red
    Write-Host "Start Ollama first!" -ForegroundColor Yellow
    exit 1
}

# Проверка моделей
$requiredModels = @("mistral-small:latest", "nomic-embed-text")  # Mistral Small 22B параметров
foreach ($model in $requiredModels) {
    $modelExists = $ollamaTest.models | Where-Object { $_.name -like "$model*" }
    if ($modelExists) {
        Write-Host "Model '$model': OK" -ForegroundColor Green
    } else {
        Write-Host "Model '$model': NOT FOUND" -ForegroundColor Red
        Write-Host "Pull model: ollama pull $model" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "`n=== STARTING CORTEX SERVER ===" -ForegroundColor Cyan
Write-Host "Service: LightRAG (WORLD_OLLAMA Cognitive Core)"
Write-Host "Port: $Port"
Write-Host "Index: $ServicePath\data"
Write-Host "Logs: $LogPath"
Write-Host "`nPress Ctrl+C to stop server`n"

# Активация venv и запуск сервера
& .\venv\Scripts\Activate.ps1

# Установка переменных окружения
$env:PYTHONUNBUFFERED = "1"
$env:PYTHONIOENCODING = "utf-8"

# Запуск с перенаправлением в лог
python lightrag_server.py 2>&1 | Tee-Object -FilePath $LogPath -Append
