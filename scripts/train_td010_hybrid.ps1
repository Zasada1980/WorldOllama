# TD-010 HYBRID: Обучение Qwen2-7B с CPU offload
# Требует: DeepSpeed для offload optimizer/градиентов на CPU
# Время: ~25-35 минут

param(
    [switch]$SkipKill = $false
)

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🚀 TD-010 HYBRID: QWEN2-7B + CPU OFFLOAD" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Config:  triz_qwen7b_hybrid.yaml"
Write-Host "Strategy: LoRA rank 4, 4-bit, CPU offload optimizer"
Write-Host "Dataset: 300 samples, 2 epochs"
Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# 1. KILL всех Python процессов llama_factory
if (-not $SkipKill) {
    Write-Host "🔪 Убиваю старые процессы Python (llama_factory)..." -ForegroundColor Yellow
    Get-Process python -ErrorAction SilentlyContinue | Where-Object {
        $_.Path -like "*llama_factory*"
    } | ForEach-Object {
        Write-Host "   Killing PID $($_.Id)" -ForegroundColor Red
        Stop-Process -Id $_.Id -Force
    }
    Start-Sleep -Seconds 2
}

# 2. GPU VRAM before
Write-Host "`n📊 GPU VRAM (before):" -NoNewline
$vramBefore = (nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
Write-Host " $vramBefore MB" -ForegroundColor Cyan

# 3. Остановка Ollama (освобождение VRAM)
Write-Host "🛑 Останавливаю Ollama..." -ForegroundColor Yellow
Stop-Process -Name ollama -Force -ErrorAction SilentlyContinue
Get-Process python -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*ollama*"
} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

$vramAfterKill = (nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
Write-Host "   VRAM after Ollama kill: $vramAfterKill MB" -ForegroundColor Green

# 4. ЗАПУСК ОБУЧЕНИЯ
Write-Host "`n🔥 Запуск обучения с CPU offload..." -ForegroundColor Green
Write-Host "   (Ожидаемое время: ~25-35 минут)`n" -ForegroundColor Yellow

Set-Location "E:\WORLD_OLLAMA\services\llama_factory"

$env:PYTORCH_CUDA_ALLOC_CONF = "expandable_segments:True"  # Динамическая аллокация VRAM
$env:CUDA_LAUNCH_BLOCKING = "0"  # Асинхронные CUDA вызовы

# Запуск обучения
$venvPath = "E:\WORLD_OLLAMA\services\llama_factory\venv"
$pythonExe = Join-Path $venvPath "Scripts\python.exe"
$configPath = ".\triz_qwen7b_hybrid.yaml"

& $pythonExe .\src\train.py $configPath

$exitCode = $LASTEXITCODE

# 5. РЕЗУЛЬТАТЫ
Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan
if ($exitCode -eq 0) {
    Write-Host "✅ ОБУЧЕНИЕ ЗАВЕРШЕНО УСПЕШНО!" -ForegroundColor Green
    
    $adapterPath = "saves\Qwen2-7B\lora\triz_hybrid\adapter_model.safetensors"
    if (Test-Path $adapterPath) {
        $size = [math]::Round((Get-Item $adapterPath).Length / 1MB, 2)
        Write-Host "📦 Adapter: $size MB" -ForegroundColor Cyan
        
        # Метрики
        $trainMetrics = Get-Content "saves\Qwen2-7B\lora\triz_hybrid\train_results.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
        if ($trainMetrics) {
            Write-Host "📊 Train Loss: $($trainMetrics.train_loss)" -ForegroundColor Cyan
        }
        
        $evalMetrics = Get-Content "saves\Qwen2-7B\lora\triz_hybrid\eval_results.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
        if ($evalMetrics) {
            Write-Host "📊 Eval Loss: $($evalMetrics.eval_loss)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "⚠️  Adapter НЕ НАЙДЕН в saves\Qwen2-7B\lora\triz_hybrid\" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ ОБУЧЕНИЕ ЗАВЕРШИЛОСЬ С ОШИБКОЙ (код $exitCode)" -ForegroundColor Red
    Write-Host "   Проверьте логи в saves\Qwen2-7B\lora\triz_hybrid\" -ForegroundColor Yellow
}

# GPU VRAM after
$vramAfter = (nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
Write-Host "`n📊 GPU VRAM (after): $vramAfter MB" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan

exit $exitCode
