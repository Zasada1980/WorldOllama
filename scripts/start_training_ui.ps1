<#
.SYNOPSIS
    Запуск LLaMA Board (Training Gym) - веб-интерфейс для fine-tuning моделей

.DESCRIPTION
    Активирует venv, настраивает окружение (CUDA, порт 7860), запускает LLaMA-Factory WebUI
    ТРИЗ принцип №25 "Самообслуживание": агент может самостоятельно обучаться через этот интерфейс

.EXAMPLE
    .\scripts\start_training_ui.ps1
    # Интерфейс доступен: http://localhost:7860

.NOTES
    Автор: SESA3002a
    Дата: 25.11.2025
    Версия: 1.0.0
    Зависимости: services/llama_factory/venv, PyTorch 2.6.0+cu124
#>

$ErrorActionPreference = "Stop"

# Путь к проекту
$LLAMA_FACTORY_DIR = "E:\WORLD_OLLAMA\services\llama_factory"
$VENV_PATH = "$LLAMA_FACTORY_DIR\venv"
$ACTIVATE_SCRIPT = "$VENV_PATH\Scripts\Activate.ps1"

# Проверка существования venv
if (-not (Test-Path $ACTIVATE_SCRIPT)) {
    Write-Error "Virtual environment не найден: $VENV_PATH"
    Write-Error "Запустите сначала: python -m venv venv"
    exit 1
}

# Активация окружения
Write-Host "🔧 Активация виртуального окружения..." -ForegroundColor Cyan
& $ACTIVATE_SCRIPT

# Настройка переменных окружения
Write-Host "⚙️  Настройка окружения..." -ForegroundColor Cyan
$env:GRADIO_SERVER_PORT = "7860"
$env:CUDA_VISIBLE_DEVICES = "0"  # RTX 5060 Ti 16GB
$env:PYTHONPATH = $LLAMA_FACTORY_DIR

# Переход в директорию проекта
Set-Location $LLAMA_FACTORY_DIR

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  🏋️  LLaMA Board (Training Gym) - Запуск                     ║" -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  Адрес:     http://localhost:7860                           ║" -ForegroundColor White
Write-Host "║  GPU:       RTX 5060 Ti 16GB (CUDA 12.4)                    ║" -ForegroundColor White
Write-Host "║  Режим:     Fine-tuning (LoRA/QLoRA)                        ║" -ForegroundColor White
Write-Host "║  Операция:  GYMNASIUM (RAG → Learning эволюция)             ║" -ForegroundColor White
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# Запуск LLaMA Board
Write-Host "🚀 Запуск веб-интерфейса (webui.py)..." -ForegroundColor Yellow
Write-Host "   ТРИЗ Принцип №25: Агент теперь может модифицировать свои веса" -ForegroundColor DarkGray
Write-Host ""

# Запуск через Python (правильный путь к webui.py)
python src\webui.py
