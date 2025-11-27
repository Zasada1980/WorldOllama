# run_training_td010_qwen7b.ps1
# Запуск Fine-Tuning TD-010: Qwen2-7B + TRIZ специализация
# Создано: 26.11.2025
# Стратегия: 4-bit QLoRA

param(
    [switch]$Monitor  # Флаг для мониторинга прогресса
)

$ErrorActionPreference = "Stop"

Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🚀 TD-010: FINE-TUNING QWEN2-7B (4-bit QLoRA)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Config:  triz_qwen7b_config.yaml" -ForegroundColor Gray
Write-Host "Dataset: triz_synthesis_v1 (300 samples, 3 epochs)" -ForegroundColor Gray
Write-Host "Method:  LoRA rank 8, 4-bit NF4 quantization" -ForegroundColor Gray
Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# Проверка VRAM перед стартом
$vramBefore = (nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits) -replace '\s',''
Write-Host "GPU VRAM (before): $vramBefore MB" -ForegroundColor Yellow

# Переход в рабочую директорию
Set-Location "E:\WORLD_OLLAMA\services\llama_factory"

# Запуск обучения
$trainCmd = "E:\WORLD_OLLAMA\services\llama_factory\venv\Scripts\python.exe"
$trainArgs = "src\train.py", "triz_qwen7b_config.yaml"

Write-Host "🔥 Запуск обучения..." -ForegroundColor Green
Write-Host "   (Ожидаемое время: ~15-25 минут)`n" -ForegroundColor Gray

# Запуск в текущем терминале (для видимости прогресса)
& $trainCmd @trainArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ ОБУЧЕНИЕ ЗАВЕРШЕНО УСПЕШНО!" -ForegroundColor Green
    
    # Проверка артефактов
    $adapterPath = "saves\Qwen2-7B\lora\triz_full\adapter_model.safetensors"
    if (Test-Path $adapterPath) {
        $adapterSize = (Get-Item $adapterPath).Length / 1MB
        Write-Host "   Адаптер сохранён: $adapterPath" -ForegroundColor Cyan
        Write-Host "   Размер: $([math]::Round($adapterSize, 2)) MB" -ForegroundColor Gray
    }
    
    # VRAM после обучения
    $vramAfter = (nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits) -replace '\s',''
    Write-Host "   GPU VRAM (after): $vramAfter MB" -ForegroundColor Yellow
    
} else {
    Write-Host "`n❌ ОБУЧЕНИЕ ЗАВЕРШИЛОСЬ С ОШИБКОЙ (код $LASTEXITCODE)" -ForegroundColor Red
    Write-Host "   Проверьте логи в saves/Qwen2-7B/lora/triz_full/" -ForegroundColor Yellow
}

# Возврат в root
Set-Location "E:\WORLD_OLLAMA"

Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan
