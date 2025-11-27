# train_td010v3_ultra_lite.ps1
# TD-010v3 ULTRA LITE: Qwen2.5-3B с оптимизацией для 16GB VRAM
# Создано: 27.11.2025

$ErrorActionPreference = "Stop"

Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🚀 TD-010v3 ULTRA LITE: Qwen2.5-3B (300 samples)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Expected time: ~10-12 minutes" -ForegroundColor Gray
Write-Host "Model: Qwen/Qwen2.5-3B-Instruct" -ForegroundColor Yellow
Write-Host "LoRA rank: 4 (optimized), Quantization: 4-bit, Epochs: 3" -ForegroundColor Yellow
Write-Host "Context: 384 tokens, Batch accumulation: 16" -ForegroundColor Yellow
Write-Host "`n💡 Optimizations:" -ForegroundColor Green
Write-Host "  - Reduced LoRA rank (4 vs 8) → ~7.5M trainable params" -ForegroundColor Gray
Write-Host "  - Shorter context (384 vs 512) → -30% activations memory" -ForegroundColor Gray
Write-Host "  - use_reentrant=false → additional memory savings" -ForegroundColor Gray
Write-Host "  - No dataloader prefetch → zero RAM buffer leaks" -ForegroundColor Gray
Write-Host "`n📊 Expected VRAM usage:" -ForegroundColor Cyan
Write-Host "  Baseline: ~2.0 GB (model 4-bit + LoRA)" -ForegroundColor Gray
Write-Host "  Peak:     ~5.8 GB (during backward pass)" -ForegroundColor Green
Write-Host "  Margin:   ~10 GB free (safe for 16GB card) ✅" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# ═══════════════════════════════════════════════════════════════
# [1/7] Проверка и остановка существующих процессов
# ═══════════════════════════════════════════════════════════════
Write-Host "[1/7] Checking for existing llama_factory processes..." -ForegroundColor Yellow

$existingProcesses = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -like "*llama_factory*"
}

if ($existingProcesses) {
    Write-Host "  Found $($existingProcesses.Count) existing process(es). Terminating..." -ForegroundColor Red
    $existingProcesses | Stop-Process -Force
    Start-Sleep -Seconds 2
    Write-Host "  ✅ Processes terminated." -ForegroundColor Green
} else {
    Write-Host "  No existing processes found." -ForegroundColor Green
}

# ═══════════════════════════════════════════════════════════════
# [2/7] Остановка Ollama и WSL для освобождения VRAM
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[2/7] Stopping Ollama server..." -ForegroundColor Yellow

$ollamaProcess = Get-Process ollama -ErrorAction SilentlyContinue
if ($ollamaProcess) {
    Stop-Process -Name ollama -Force -ErrorAction SilentlyContinue
    Write-Host "  Ollama stopped." -ForegroundColor Green
} else {
    Write-Host "  Ollama not running." -ForegroundColor Gray
}

Write-Host "  Shutting down WSL..." -ForegroundColor Yellow
wsl --shutdown 2>$null
Write-Host "  ✅ WSL stopped." -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════
# [3/7] Проверка базового VRAM
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[3/7] Checking baseline VRAM usage..." -ForegroundColor Yellow

$baselineVRAM = nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits
Write-Host "  Baseline VRAM: $baselineVRAM MB" -ForegroundColor $(if ($baselineVRAM -lt 2000) { "Green" } else { "Yellow" })

if ($baselineVRAM -gt 3000) {
    Write-Host "  ⚠️  WARNING: High baseline VRAM! Expected <2000 MB" -ForegroundColor Red
    Write-Host "  Attempting CUDA cache clear..." -ForegroundColor Yellow
    
    E:\WORLD_OLLAMA\services\llama_factory\venv\Scripts\python.exe -c "import torch; torch.cuda.empty_cache(); print('CUDA cache cleared')"
    Start-Sleep -Seconds 2
    
    $newVRAM = nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits
    Write-Host "  VRAM after cleanup: $newVRAM MB" -ForegroundColor Green
}

# ═══════════════════════════════════════════════════════════════
# [4/7] Установка environment variables
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[4/7] Setting environment variables..." -ForegroundColor Yellow

$env:PYTORCH_CUDA_ALLOC_CONF = "max_split_size_mb:128,expandable_segments:True,garbage_collection_threshold:0.6"
$env:CUDA_LAUNCH_BLOCKING = "0"
$env:HF_DATASETS_CACHE = "E:\WORLD_OLLAMA\services\llama_factory\hf_cache"
$env:HF_HOME = "E:\WORLD_OLLAMA\services\llama_factory\hf_home"

Write-Host "  PYTORCH_CUDA_ALLOC_CONF = $env:PYTORCH_CUDA_ALLOC_CONF" -ForegroundColor Gray
Write-Host "  HF_DATASETS_CACHE = $env:HF_DATASETS_CACHE" -ForegroundColor Gray
Write-Host "  ✅ Environment configured." -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════
# [5/7] Проверка конфигурационного файла
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[5/7] Verifying configuration file..." -ForegroundColor Yellow

$configPath = "E:\WORLD_OLLAMA\services\llama_factory\triz_qwen3b_ultra_lite.yaml"

if (-not (Test-Path $configPath)) {
    Write-Host "  ❌ ERROR: Config file not found!" -ForegroundColor Red
    Write-Host "  Expected: $configPath" -ForegroundColor Red
    exit 1
}

$configContent = Get-Content $configPath -Raw
Write-Host "  Config file found: triz_qwen3b_ultra_lite.yaml" -ForegroundColor Green

# Проверка ключевых параметров
if ($configContent -match "cutoff_len:\s*384") {
    Write-Host "  ✅ cutoff_len: 384 (optimized)" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  cutoff_len not set to 384!" -ForegroundColor Yellow
}

if ($configContent -match "lora_rank:\s*4") {
    Write-Host "  ✅ lora_rank: 4 (memory-efficient)" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  lora_rank not set to 4!" -ForegroundColor Yellow
}

if ($configContent -match "use_reentrant:\s*false") {
    Write-Host "  ✅ use_reentrant: false (extra memory savings)" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  use_reentrant optimization not enabled!" -ForegroundColor Yellow
}

# ═══════════════════════════════════════════════════════════════
# [6/7] Запуск обучения
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[6/7] Launching ultra-lite training..." -ForegroundColor Yellow
Write-Host "Expected stages:" -ForegroundColor Cyan
Write-Host "  1. Model loading (60-90s)" -ForegroundColor Gray
Write-Host "  2. Dataset preparation (30-60s)" -ForegroundColor Gray
Write-Host "  3. Training 270 samples × 3 epochs (8-10 min)" -ForegroundColor Gray
Write-Host "  4. Final evaluation (30s)" -ForegroundColor Gray
Write-Host "`nStarting training process..." -ForegroundColor Green
Write-Host "============================================`n" -ForegroundColor Cyan

Set-Location "E:\WORLD_OLLAMA\services\llama_factory"

$startTime = Get-Date

& .\venv\Scripts\python.exe src\train.py triz_qwen3b_ultra_lite.yaml

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Training completed in $($duration.ToString('mm\:ss\.ff'))" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════
# [7/7] Проверка результатов и сравнение
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[7/7] Analyzing results..." -ForegroundColor Yellow

$adapterPath = "saves\Qwen2.5-3B\lora\triz_ultra_lite\adapter_model.safetensors"

if (Test-Path $adapterPath) {
    $adapterSize = [math]::Round((Get-Item $adapterPath).Length / 1MB, 2)
    Write-Host "`n✅ SUCCESS: Adapter created!" -ForegroundColor Green
    Write-Host "   Size: $adapterSize MB" -ForegroundColor Cyan
    
    # Чтение метрик
    $trainResults = Get-Content "saves\Qwen2.5-3B\lora\triz_ultra_lite\trainer_log.jsonl" -ErrorAction SilentlyContinue | 
        ConvertFrom-Json -ErrorAction SilentlyContinue | 
        Select-Object -Last 1
    
    if ($trainResults) {
        $trainLoss = $trainResults.train_loss
        Write-Host "   Train Loss: $trainLoss" -ForegroundColor Cyan
    }
    
    # Попытка получить eval_loss
    $evalResults = Get-Content "saves\Qwen2.5-3B\lora\triz_ultra_lite\eval_results.json" -ErrorAction SilentlyContinue | 
        ConvertFrom-Json -ErrorAction SilentlyContinue
    
    if ($evalResults -and $evalResults.eval_loss) {
        $evalLoss = [math]::Round($evalResults.eval_loss, 4)
        Write-Host "   Eval Loss:  $evalLoss" -ForegroundColor Cyan
        
        # Сравнение с TD-010v2 (1.5B)
        $td010v2_loss = 0.9358
        $improvement = [math]::Round((($td010v2_loss - $evalLoss) / $td010v2_loss) * 100, 1)
        
        Write-Host "`n📊 Comparison with TD-010v2 (Qwen2.5-1.5B):" -ForegroundColor Yellow
        Write-Host "   TD-010v2 (1.5B):  eval_loss = $td010v2_loss" -ForegroundColor Gray
        Write-Host "   TD-010v3 (3B):    eval_loss = $evalLoss" -ForegroundColor Cyan
        
        if ($improvement -gt 0) {
            Write-Host "   🎉 IMPROVEMENT: +$improvement%" -ForegroundColor Green
        } elseif ($improvement -lt 0) {
            Write-Host "   ⚠️  REGRESSION: $improvement%" -ForegroundColor Yellow
        } else {
            Write-Host "   ≈ Same quality" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n📦 Next steps:" -ForegroundColor Cyan
    Write-Host "   1. Export adapter:" -ForegroundColor White
    Write-Host "      Copy-Item saves\Qwen2.5-3B\lora\triz_ultra_lite\*.safetensors E:\WORLD_OLLAMA\saves\td010v3\" -ForegroundColor Gray
    Write-Host "   2. Test quality:" -ForegroundColor White
    Write-Host "      Create chat launcher similar to run_td009_chat.ps1" -ForegroundColor Gray
    Write-Host "   3. Commit to GitHub:" -ForegroundColor White
    Write-Host "      git add . && git commit -m 'TD-010v3: 3B ultra-lite adapter'" -ForegroundColor Gray
    
} else {
    Write-Host "`n❌ TRAINING FAILED" -ForegroundColor Red
    Write-Host "   Adapter NOT FOUND: $adapterPath" -ForegroundColor Red
    Write-Host "   Check logs in saves\Qwen2.5-3B\lora\triz_ultra_lite\" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ✅ TD-010v3 ULTRA LITE COMPLETE" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
