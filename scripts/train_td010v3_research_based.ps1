# train_td010v3_research_based.ps1
# TD-010v3 RESEARCH-BASED: Обучение по рекомендациям Technical Report
# Источник: RTX 5060 Ti Technical Report (раздел 4.1, 6.2)

$ErrorActionPreference = "Stop"

Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🔬 TD-010v3 RESEARCH-BASED: Qwen2.5-3B" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Источник: RTX 5060 Ti Technical Report" -ForegroundColor Yellow
Write-Host "Раздел 4.1: '8B модели - идеальный выбор для QLoRA на 16GB'" -ForegroundColor Gray
Write-Host "`nОжидаемое время: ~12-15 минут" -ForegroundColor Gray
Write-Host "Model: Qwen/Qwen2.5-3B-Instruct" -ForegroundColor Yellow
Write-Host "`n📊 Конфигурация из документа (Table 4):" -ForegroundColor Green
Write-Host "  - LoRA rank: 8, targets: q_proj,v_proj (critical modules)" -ForegroundColor Gray
Write-Host "  - Quantization: 4-bit NF4 (load_in_4bit: true)" -ForegroundColor Gray
Write-Host "  - Optimizer: adamw_8bit (НЕ fused!)" -ForegroundColor Yellow
Write-Host "  - Gradient checkpointing: true" -ForegroundColor Gray
Write-Host "  - Batch size: 2, Accumulation: 8 (эффективный batch = 16)" -ForegroundColor Gray
Write-Host "`n💡 Ключевое отличие от предыдущих попыток:" -ForegroundColor Cyan
Write-Host "  ✅ adamw_8bit вместо adamw_torch_fused → -2-3 GB VRAM" -ForegroundColor Green
Write-Host "  ✅ lora_target только q_proj,v_proj → -1 GB VRAM" -ForegroundColor Green
Write-Host "  ✅ batch_size: 2 вместо 1 → стабильнее обучение" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# ═══════════════════════════════════════════════════════════════
# [1/7] Очистка процессов
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
# [2/7] Остановка Ollama + WSL
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
# [3/7] VRAM проверка
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[3/7] Checking baseline VRAM usage..." -ForegroundColor Yellow

$baselineVRAM = nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits
Write-Host "  Baseline VRAM: $baselineVRAM MB" -ForegroundColor $(if ($baselineVRAM -lt 2000) { "Green" } else { "Yellow" })

if ($baselineVRAM -gt 3000) {
    Write-Host "  ⚠️  WARNING: High baseline! Clearing CUDA cache..." -ForegroundColor Red
    E:\WORLD_OLLAMA\services\llama_factory\venv\Scripts\python.exe -c "import torch; torch.cuda.empty_cache(); print('CUDA cache cleared')"
    Start-Sleep -Seconds 2
    
    $newVRAM = nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits
    Write-Host "  VRAM after cleanup: $newVRAM MB" -ForegroundColor Green
}

# ═══════════════════════════════════════════════════════════════
# [4/7] Environment variables (из документа раздел 6.2)
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[4/7] Setting environment variables (Technical Report recommendations)..." -ForegroundColor Yellow

$env:PYTORCH_CUDA_ALLOC_CONF = "expandable_segments:True"
$env:CUDA_LAUNCH_BLOCKING = "0"
$env:HF_DATASETS_CACHE = "E:\WORLD_OLLAMA\services\llama_factory\hf_cache"
$env:HF_HOME = "E:\WORLD_OLLAMA\services\llama_factory\hf_home"

Write-Host "  ✅ Environment configured." -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════
# [5/7] Config validation
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[5/7] Verifying research-based configuration..." -ForegroundColor Yellow

$configPath = "E:\WORLD_OLLAMA\services\llama_factory\triz_qwen3b_research_based.yaml"

if (-not (Test-Path $configPath)) {
    Write-Host "  ❌ ERROR: Config not found!" -ForegroundColor Red
    exit 1
}

$config = Get-Content $configPath -Raw

# Проверка критичных параметров
$checks = @(
    @{Param="optim: adamw_8bit"; Name="8-bit optimizer"},
    @{Param="lora_target: q_proj,v_proj"; Name="Critical LoRA modules"},
    @{Param="gradient_checkpointing: true"; Name="Gradient checkpointing"},
    @{Param="per_device_train_batch_size: 2"; Name="Batch size 2"}
)

foreach ($check in $checks) {
    if ($config -match [regex]::Escape($check.Param)) {
        Write-Host "  ✅ $($check.Name)" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  $($check.Name) NOT SET!" -ForegroundColor Yellow
    }
}

# ═══════════════════════════════════════════════════════════════
# [6/7] Запуск обучения
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[6/7] Launching research-based training..." -ForegroundColor Yellow
Write-Host "Expected stages:" -ForegroundColor Cyan
Write-Host "  1. Model loading (60-90s)" -ForegroundColor Gray
Write-Host "  2. Dataset preparation (30-60s)" -ForegroundColor Gray
Write-Host "  3. Training 270 samples × 3 epochs (10-12 min)" -ForegroundColor Gray
Write-Host "  4. Final evaluation (30s)" -ForegroundColor Gray
Write-Host "`n📈 Expected VRAM profile (from Technical Report):" -ForegroundColor Cyan
Write-Host "  Model (4-bit): ~2.0 GB" -ForegroundColor Gray
Write-Host "  LoRA adapters: ~0.05 GB" -ForegroundColor Gray
Write-Host "  8-bit optimizer: ~0.08 GB (vs 0.12 GB fused)" -ForegroundColor Green
Write-Host "  Activations (batch=2): ~3-4 GB" -ForegroundColor Gray
Write-Host "  Peak total: ~8-10 GB ✅" -ForegroundColor Green
Write-Host "`nStarting training process..." -ForegroundColor Green
Write-Host "============================================`n" -ForegroundColor Cyan

Set-Location "E:\WORLD_OLLAMA\services\llama_factory"

$startTime = Get-Date

& .\venv\Scripts\python.exe src\train.py triz_qwen3b_research_based.yaml

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Training completed in $($duration.ToString('mm\:ss\.ff'))" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════
# [7/7] Results analysis
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[7/7] Analyzing results..." -ForegroundColor Yellow

$adapterPath = "saves\Qwen2.5-3B\lora\triz_research_based\adapter_model.safetensors"

if (Test-Path $adapterPath) {
    $adapterSize = [math]::Round((Get-Item $adapterPath).Length / 1MB, 2)
    Write-Host "`n🎉 SUCCESS: Research-based training completed!" -ForegroundColor Green
    Write-Host "   Adapter size: $adapterSize MB" -ForegroundColor Cyan
    
    # Метрики
    $trainLog = Get-Content "saves\Qwen2.5-3B\lora\triz_research_based\trainer_log.jsonl" -ErrorAction SilentlyContinue | 
        ConvertFrom-Json -ErrorAction SilentlyContinue | 
        Select-Object -Last 1
    
    if ($trainLog) {
        Write-Host "   Train Loss: $($trainLog.train_loss)" -ForegroundColor Cyan
    }
    
    $evalResults = Get-Content "saves\Qwen2.5-3B\lora\triz_research_based\eval_results.json" -ErrorAction SilentlyContinue | 
        ConvertFrom-Json -ErrorAction SilentlyContinue
    
    if ($evalResults -and $evalResults.eval_loss) {
        $evalLoss = [math]::Round($evalResults.eval_loss, 4)
        Write-Host "   Eval Loss:  $evalLoss" -ForegroundColor Cyan
        
        # Сравнение
        $td010v2_loss = 0.9358
        $improvement = [math]::Round((($td010v2_loss - $evalLoss) / $td010v2_loss) * 100, 1)
        
        Write-Host "`n📊 Comparison:" -ForegroundColor Yellow
        Write-Host "   TD-010v2 (1.5B):  $td010v2_loss" -ForegroundColor Gray
        Write-Host "   TD-010v3 (3B):    $evalLoss" -ForegroundColor Cyan
        
        if ($improvement -gt 0) {
            Write-Host "   🎉 IMPROVEMENT: +$improvement%" -ForegroundColor Green
        }
    }
    
    Write-Host "`n📝 Technical Report validation:" -ForegroundColor Cyan
    Write-Host "   ✅ Раздел 4.1: '8B модели - идеальный выбор' → 3B влез!" -ForegroundColor Green
    Write-Host "   ✅ Table 4: adamw_8bit + gradient_checkpointing → работает!" -ForegroundColor Green
    
} else {
    Write-Host "`n❌ TRAINING FAILED" -ForegroundColor Red
    Write-Host "   Проверьте логи в saves\Qwen2.5-3B\lora\triz_research_based\" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ✅ TD-010v3 RESEARCH-BASED COMPLETE" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
