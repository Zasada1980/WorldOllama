# run_td009_chat_7b.ps1
# Запуск интерактивного чата с Qwen2-7B (локальная модель)
# Создано: 26.11.2025

param(
    [string]$ModelPath = "E:\WORLD_OLLAMA\models\qwen2-triz-merged",
    [string]$Template = "qwen",
    [switch]$Quantize8bit,
    [int]$CpuLayers = 0,  # Количество слоёв для CPU (0 = все на GPU)
    [string]$SystemPrompt = "Ты TRIZ-специалист. Отвечай ТОЛЬКО на русском языке. Используй принципы ТРИЗ для решения инженерных задач."
)

$ErrorActionPreference = "Stop"

Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🤖 QWEN2-7B TRIZ SPECIALIST CHAT" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Model Path: $ModelPath" -ForegroundColor Gray
Write-Host "Template:   $Template" -ForegroundColor Gray

if ($Quantize8bit) {
    Write-Host "Quantization: 8-bit (enabled)" -ForegroundColor Yellow
} else {
    Write-Host "Quantization: disabled (bf16/fp16)" -ForegroundColor Gray
}

if ($CpuLayers -gt 0) {
    Write-Host "CPU Offload: включён (auto device map)" -ForegroundColor Cyan
    Write-Host "             4-bit NF4 quantization (требуется для offload)" -ForegroundColor Yellow
    Write-Host "             Экономия VRAM: ~50-60%" -ForegroundColor Gray
} else {
    Write-Host "CPU Offload: disabled (все на GPU)" -ForegroundColor Gray
}

Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# Проверка наличия модели
if (-not (Test-Path "$ModelPath\config.json")) {
    Write-Host "❌ Модель не найдена: $ModelPath\config.json" -ForegroundColor Red
    exit 1
}

# Переход в каталог LLaMA Factory
Set-Location "E:\WORLD_OLLAMA\services\llama_factory"

# Активация venv
if (Test-Path ".\venv\Scripts\Activate.ps1") {
    Write-Host "🔧 Активация venv..." -ForegroundColor Yellow
    & .\venv\Scripts\Activate.ps1
} else {
    Write-Host "⚠️  venv не найден, используем глобальный Python" -ForegroundColor Yellow
}

# Формирование команды
$cliPath = ".\venv\Scripts\llamafactory-cli.exe"
$chatArgs = @(
    "chat",
    "--model_name_or_path", $ModelPath,
    "--template", $Template,
    "--default_system", $SystemPrompt
)

if ($CpuLayers -gt 0) {
    # CPU offloading требует 4-bit quantization
    $chatArgs += "--quantization_method", "bnb"
    $chatArgs += "--quantization_bit", "4"
    $chatArgs += "--quantization_device_map", "auto"
    
    # Указываем папку для offload (временное хранилище)
    $offloadDir = "E:\WORLD_OLLAMA\services\llama_factory\offload_cache"
    if (-not (Test-Path $offloadDir)) {
        New-Item -ItemType Directory -Path $offloadDir -Force | Out-Null
    }
    $chatArgs += "--offload_folder", $offloadDir
    
    Write-Host "⚙️  Настройка CPU offloading..." -ForegroundColor Yellow
    Write-Host "   Offload папка: $offloadDir" -ForegroundColor Gray
    Write-Host "   ⚠️  Автоматически переключено на 4-bit quantization (требование для CPU offload)" -ForegroundColor Yellow
} elseif ($Quantize8bit) {
    $chatArgs += "--quantization_method", "bnb"
    $chatArgs += "--quantization_bit", "8"
}

Write-Host "🚀 Запуск чата с Qwen2-7B..." -ForegroundColor Green
Write-Host "   Системный промпт: $($SystemPrompt.Substring(0, [Math]::Min(60, $SystemPrompt.Length)))..." -ForegroundColor Gray
Write-Host "   (Для выхода используйте: exit, quit, или Ctrl+C)`n" -ForegroundColor Gray

# Запуск чата
& $cliPath @chatArgs

# Возврат в исходную директорию
Set-Location "E:\WORLD_OLLAMA"

Write-Host "`n✅ Чат завершён." -ForegroundColor Green
