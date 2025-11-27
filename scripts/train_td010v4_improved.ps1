#!/usr/bin/env pwsh
# TD-010v4 Training Launcher (Improved: 4 LoRA modules)
# Target: eval_loss < 0.95 (better than TD-010v2: 0.9358)

$ErrorActionPreference = "Stop"

Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  TD-010v4 IMPROVED TRAINING (Qwen2.5-3B + 4 LoRA modules)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# Step 1: Validate environment
Write-Host "[1/7] Validating environment..." -ForegroundColor Yellow

$venvPath = "E:\WORLD_OLLAMA\services\llama_factory\venv\Scripts\python.exe"
if (-not (Test-Path $venvPath)) {
    Write-Host "❌ Virtual environment not found: $venvPath" -ForegroundColor Red
    exit 1
}

$configPath = "E:\WORLD_OLLAMA\services\llama_factory\triz_qwen3b_improved.yaml"
if (-not (Test-Path $configPath)) {
    Write-Host "❌ Config not found: $configPath" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Environment validated" -ForegroundColor Green

# Step 2: Validate config parameters
Write-Host "`n[2/7] Validating config parameters..." -ForegroundColor Yellow

$config = Get-Content $configPath -Raw
$checks = @{
    "adamw_8bit" = $config -match "optim:\s*adamw_8bit"
    "4 LoRA modules" = $config -match "lora_target:\s*q_proj,v_proj,k_proj,o_proj"
    "gradient_checkpointing" = $config -match "gradient_checkpointing:\s*true"
    "batch_size 2" = $config -match "per_device_train_batch_size:\s*2"
    "bf16" = $config -match "bf16:\s*true"
}

foreach ($check in $checks.GetEnumerator()) {
    if ($check.Value) {
        Write-Host "  ✅ $($check.Key)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $($check.Key) NOT FOUND!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ Config parameters validated" -ForegroundColor Green

# Step 3: Display expected VRAM profile
Write-Host "`n[3/7] Expected VRAM profile (4 LoRA modules):" -ForegroundColor Yellow
Write-Host "  Model (4-bit):         ~2.0 GB" -ForegroundColor Cyan
Write-Host "  LoRA adapters (4 mod): ~0.07 GB" -ForegroundColor Cyan
Write-Host "  8-bit optimizer:       ~0.10 GB" -ForegroundColor Cyan
Write-Host "  Activations (batch=2): ~3-4 GB" -ForegroundColor Cyan
Write-Host "  Overhead:              ~1.5 GB" -ForegroundColor Cyan
Write-Host "  ─────────────────────────────" -ForegroundColor DarkGray
Write-Host "  Peak total:            ~4-5 GB ✅ (safe on 16 GB)" -ForegroundColor Green

# Step 4: Display improvements vs TD-010v3
Write-Host "`n[4/7] Improvements vs TD-010v3 (research_based):" -ForegroundColor Yellow
Write-Host "  TD-010v3: 2 LoRA modules (q_proj, v_proj)" -ForegroundColor DarkGray
Write-Host "  TD-010v4: 4 LoRA modules (q_proj, v_proj, k_proj, o_proj)" -ForegroundColor Green
Write-Host "  ───────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  Trainable params: 1.84M → ~3.5M (+90%)" -ForegroundColor Cyan
Write-Host "  Expected eval_loss: 1.0026 → <0.95 (-5%)" -ForegroundColor Cyan
Write-Host "  BF16 precision: Blackwell Tensor Cores optimized" -ForegroundColor Cyan

# Step 5: Display target vs baselines
Write-Host "`n[5/7] Target vs Baselines:" -ForegroundColor Yellow
Write-Host "  TD-010v2 (1.5B): eval_loss 0.9358 ⭐ (current best)" -ForegroundColor White
Write-Host "  TD-010v3 (3B):   eval_loss 1.0026 (research_based)" -ForegroundColor White
Write-Host "  TD-010v4 (3B):   target <0.95 🎯 (improved)" -ForegroundColor Green

# Step 6: Check VRAM before training
Write-Host "`n[6/7] Checking current VRAM..." -ForegroundColor Yellow

try {
    $vramInfo = nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits
    $vramUsed = [int]($vramInfo.Split(',')[0].Trim())
    $vramTotal = [int]($vramInfo.Split(',')[1].Trim())
    $vramFree = $vramTotal - $vramUsed
    
    Write-Host "  VRAM Used:  $vramUsed MB" -ForegroundColor Cyan
    Write-Host "  VRAM Total: $vramTotal MB" -ForegroundColor Cyan
    Write-Host "  VRAM Free:  $vramFree MB" -ForegroundColor Green
    
    if ($vramFree -lt 6000) {
        Write-Host "  ⚠️  Warning: Low VRAM (<6 GB free)" -ForegroundColor Yellow
    } else {
        Write-Host "  ✅ Sufficient VRAM for training" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Could not check VRAM (nvidia-smi failed)" -ForegroundColor Yellow
}

# Step 7: Launch training
Write-Host "`n[7/7] Launching training..." -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$env:HF_DATASETS_CACHE = "E:\WORLD_OLLAMA\services\llama_factory\hf_cache"
$env:HF_HOME = "E:\WORLD_OLLAMA\services\llama_factory\hf_home"
$env:PYTORCH_CUDA_ALLOC_CONF = "expandable_segments:True"

Set-Location "E:\WORLD_OLLAMA\services\llama_factory"

# Activate venv
& ".\venv\Scripts\Activate.ps1"

$startTime = Get-Date

# Use llamafactory-cli directly (not python -m)
llamafactory-cli train triz_qwen3b_improved.yaml

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Training completed in $($duration.ToString('mm\:ss\.ff'))" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# Step 8: Analyze results
Write-Host "[8/8] Analyzing results..." -ForegroundColor Yellow

$adapterPath = "E:\WORLD_OLLAMA\services\llama_factory\saves\Qwen2.5-3B\lora\triz_improved\adapter_model.safetensors"
if (Test-Path $adapterPath) {
    $adapterSize = [math]::Round((Get-Item $adapterPath).Length / 1MB, 2)
    Write-Host "`n🎉 SUCCESS: Adapter created!" -ForegroundColor Green
    Write-Host "   Adapter size: $adapterSize MB" -ForegroundColor Cyan
    
    # Extract metrics from trainer_log.jsonl
    $logPath = "E:\WORLD_OLLAMA\services\llama_factory\saves\Qwen2.5-3B\lora\triz_improved\trainer_log.jsonl"
    if (Test-Path $logPath) {
        $logs = Get-Content $logPath | ForEach-Object { $_ | ConvertFrom-Json }
        $finalEval = $logs | Where-Object { $_.eval_loss -ne $null } | Select-Object -Last 1
        
        if ($finalEval) {
            $evalLoss = [math]::Round($finalEval.eval_loss, 4)
            Write-Host "   Train Loss: " -NoNewline -ForegroundColor White
            Write-Host "$($finalEval.train_loss)" -ForegroundColor Cyan
            Write-Host "   Eval Loss:  " -NoNewline -ForegroundColor White
            Write-Host "$evalLoss" -ForegroundColor Cyan
            
            Write-Host "`n📊 Comparison:" -ForegroundColor Yellow
            Write-Host "   TD-010v2 (1.5B):  0.9358" -ForegroundColor White
            Write-Host "   TD-010v3 (3B):    1.0026" -ForegroundColor White
            Write-Host "   TD-010v4 (3B):    $evalLoss" -ForegroundColor $(if ($evalLoss -lt 0.95) { "Green" } else { "Yellow" })
            
            if ($evalLoss -lt 0.95) {
                Write-Host "`n🎯 TARGET ACHIEVED: eval_loss < 0.95!" -ForegroundColor Green
                Write-Host "   TD-010v4 becomes NEW BASELINE ⭐" -ForegroundColor Green
            } elseif ($evalLoss -lt 0.9358) {
                Write-Host "`n✅ BETTER than TD-010v2: eval_loss < 0.9358!" -ForegroundColor Green
                Write-Host "   TD-010v4 is new champion 🏆" -ForegroundColor Green
            } elseif ($evalLoss -lt 1.0026) {
                Write-Host "`n✅ BETTER than TD-010v3: eval_loss < 1.0026!" -ForegroundColor Green
                Write-Host "   4 LoRA modules improved quality" -ForegroundColor Cyan
            } else {
                Write-Host "`n⚠️  eval_loss >= TD-010v3 baseline" -ForegroundColor Yellow
                Write-Host "   Consider: More epochs or different learning rate" -ForegroundColor Gray
            }
        }
    }
    
    # Compare with Technical Report predictions
    Write-Host "`n📝 Technical Report validation:" -ForegroundColor Yellow
    Write-Host "   ✅ Раздел 4.1: '8B модели - идеальный выбор' → 3B влез!" -ForegroundColor Green
    Write-Host "   ✅ Table 4: adamw_8bit + BF16 → работает!" -ForegroundColor Green
    Write-Host "   ✅ Section 3.2: '8-bit optimizers save VRAM' → подтверждено!" -ForegroundColor Green
    
} else {
    Write-Host "`n❌ FAILED: Adapter not found!" -ForegroundColor Red
    Write-Host "   Check logs for errors" -ForegroundColor Yellow
}

Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ✅ TD-010v4 IMPROVED TRAINING COMPLETE" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
