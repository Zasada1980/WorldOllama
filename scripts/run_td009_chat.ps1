# run_td009_chat.ps1
# Запуск интерактивного чата с fine-tuned моделью TD-009 (TRIZ специалист)
# Создано: 26.11.2025
# Модель: Qwen2.5-1.5B-Instruct + LoRA adapter (rank 8, TRIZ synthesis)

param(
    [string]$AdapterPath = "E:\WORLD_OLLAMA\saves\td009",
    [string]$BaseModel = "Qwen/Qwen2.5-1.5B-Instruct",
    [string]$Template = "qwen",
    [switch]$Quantize8bit,
    [string]$SystemPrompt = "Ты TRIZ-специалист. Отвечай ТОЛЬКО на русском языке. Используй принципы ТРИЗ для решения инженерных задач: анализируй противоречия, применяй 40 принципов ТРИЗ, предлагай конкретные решения."
)

$ErrorActionPreference = "Stop"

Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🤖 TD-009 TRIZ SPECIALIST CHAT" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Base Model: $BaseModel" -ForegroundColor Gray
Write-Host "Adapter:    $AdapterPath" -ForegroundColor Gray
Write-Host "Template:   $Template" -ForegroundColor Gray

if ($Quantize8bit) {
    Write-Host "Quantization: 8-bit (enabled)" -ForegroundColor Yellow
} else {
    Write-Host "Quantization: disabled (fp16)" -ForegroundColor Gray
}

Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# Проверка наличия адаптера
$adapterFile = Get-ChildItem "$AdapterPath\adapter_*.safetensors" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $adapterFile) {
    Write-Host "❌ Адаптер не найден в: $AdapterPath" -ForegroundColor Red
    Write-Host "   Ожидается файл вида adapter_*.safetensors" -ForegroundColor Yellow
    exit 1
}

# Если файл не называется adapter_model.safetensors, создаём симлинк/копию
$canonicalPath = Join-Path $AdapterPath "adapter_model.safetensors"
if (-not (Test-Path $canonicalPath)) {
    Write-Host "🔗 Создание канонического имени для адаптера..." -ForegroundColor Yellow
    Copy-Item $adapterFile.FullName $canonicalPath
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
    "--model_name_or_path", $BaseModel,
    "--adapter_folder", $AdapterPath,
    "--template", $Template,
    "--default_system", $SystemPrompt
)

if ($Quantize8bit) {
    $chatArgs += "--quantization_method", "bnb"
    $chatArgs += "--quantization_bit", "8"
}

Write-Host "🚀 Запуск чата..." -ForegroundColor Green
Write-Host "   Системный промпт: $($SystemPrompt.Substring(0, [Math]::Min(60, $SystemPrompt.Length)))..." -ForegroundColor Gray
Write-Host "   (Для выхода используйте: exit, quit, или Ctrl+C)`n" -ForegroundColor Gray

# Запуск чата
& $cliPath @chatArgs

# Возврат в исходную директорию
Set-Location "E:\WORLD_OLLAMA"

Write-Host "`n✅ Чат завершён." -ForegroundColor Green
