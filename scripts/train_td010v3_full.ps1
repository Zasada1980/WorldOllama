# TD-010v3 Full Training Launcher (Qwen2.5-3B)
# Purpose: Train 3B model on full TRIZ dataset (300 samples)
# Date: 2025-11-27
# Prerequisites: Mini-test passed successfully

param(
    [switch]$SkipOllamaKill = $false
)

Write-Host "`n=== TD-010v3 FULL TRAINING: Qwen2.5-3B (300 samples) ===" -ForegroundColor Cyan
Write-Host "Expected time: ~8-12 minutes" -ForegroundColor Yellow
Write-Host "Model: Qwen/Qwen2.5-3B-Instruct" -ForegroundColor Yellow
Write-Host "LoRA rank: 8, Quantization: 4-bit, Epochs: 3`n" -ForegroundColor Yellow

# =====================================================================
# SECTION 1: Kill existing Python processes
# =====================================================================
Write-Host "[1/7] Checking for existing llama_factory processes..." -ForegroundColor Cyan

$llamaProcesses = Get-Process python -ErrorAction SilentlyContinue | 
    Where-Object { $_.Path -like "*llama_factory*" }

if ($llamaProcesses) {
    Write-Host "Found $($llamaProcesses.Count) existing Python process(es). Killing..." -ForegroundColor Yellow
    $llamaProcesses | ForEach-Object {
        Write-Host "  - Killing PID $($_.Id) ($([math]::Round($_.WorkingSet64/1MB, 2)) MB RAM)" -ForegroundColor DarkYellow
        Stop-Process -Id $_.Id -Force
    }
    Start-Sleep -Seconds 2
    Write-Host "Done." -ForegroundColor Green
} else {
    Write-Host "No existing processes found." -ForegroundColor Green
}

# =====================================================================
# SECTION 2: Stop Ollama server (frees ~8GB VRAM)
# =====================================================================
if (-not $SkipOllamaKill) {
    Write-Host "`n[2/7] Stopping Ollama server..." -ForegroundColor Cyan
    
    $ollamaProcess = Get-Process ollama -ErrorAction SilentlyContinue
    if ($ollamaProcess) {
        Write-Host "Ollama running (PID $($ollamaProcess.Id)). Stopping..." -ForegroundColor Yellow
        Stop-Process -Name ollama -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Write-Host "Ollama stopped." -ForegroundColor Green
    } else {
        Write-Host "Ollama not running." -ForegroundColor Green
    }
    
    Write-Host "Shutting down WSL..." -ForegroundColor Yellow
    wsl --shutdown 2>$null
    Start-Sleep -Seconds 2
    Write-Host "WSL stopped." -ForegroundColor Green
} else {
    Write-Host "`n[2/7] SKIPPING Ollama kill (--SkipOllamaKill flag)" -ForegroundColor Yellow
}

# =====================================================================
# SECTION 3: Check baseline VRAM
# =====================================================================
Write-Host "`n[3/7] Checking baseline VRAM usage..." -ForegroundColor Cyan

$baselineVRAM = nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits
Write-Host "Baseline VRAM: $baselineVRAM MB" -ForegroundColor $(if ([int]$baselineVRAM -lt 2000) { "Green" } else { "Yellow" })

if ([int]$baselineVRAM -gt 2000) {
    Write-Host "WARNING: Baseline VRAM > 2GB. Something else is using GPU!" -ForegroundColor Red
}

# =====================================================================
# SECTION 4: Set environment variables
# =====================================================================
Write-Host "`n[4/7] Setting environment variables..." -ForegroundColor Cyan

$env:PYTORCH_CUDA_ALLOC_CONF = "expandable_segments:True"
$env:CUDA_LAUNCH_BLOCKING = "0"
$env:HF_DATASETS_CACHE = "E:\WORLD_OLLAMA\services\llama_factory\hf_cache"
$env:HF_HOME = "E:\WORLD_OLLAMA\services\llama_factory\hf_home"

Write-Host "  PYTORCH_CUDA_ALLOC_CONF = $env:PYTORCH_CUDA_ALLOC_CONF" -ForegroundColor DarkGray
Write-Host "  HF_DATASETS_CACHE = $env:HF_DATASETS_CACHE" -ForegroundColor DarkGray

# =====================================================================
# SECTION 5: Verify config file exists
# =====================================================================
Write-Host "`n[5/7] Verifying configuration file..." -ForegroundColor Cyan

$configPath = "E:\WORLD_OLLAMA\services\llama_factory\triz_qwen3b_full.yaml"
if (-not (Test-Path $configPath)) {
    Write-Host "ERROR: Config file not found at $configPath" -ForegroundColor Red
    exit 1
}

Write-Host "Config file found: triz_qwen3b_full.yaml" -ForegroundColor Green
Write-Host "  Model: Qwen/Qwen2.5-3B-Instruct" -ForegroundColor DarkGray
Write-Host "  Dataset: triz_synthesis_v1 (300 samples, 3 epochs)" -ForegroundColor DarkGray
Write-Host "  LoRA rank: 8, Quantization: 4-bit" -ForegroundColor DarkGray

# =====================================================================
# SECTION 6: Launch training
# =====================================================================
Write-Host "`n[6/7] Launching full training..." -ForegroundColor Cyan
Write-Host "Expected stages:" -ForegroundColor Yellow
Write-Host "  1. Model loading (60-90s)" -ForegroundColor DarkYellow
Write-Host "  2. Dataset preparation (30-60s)" -ForegroundColor DarkYellow
Write-Host "  3. Training 270 samples (8-10 min)" -ForegroundColor DarkYellow
Write-Host "  4. Final evaluation (30s)" -ForegroundColor DarkYellow
Write-Host ""

Set-Location E:\WORLD_OLLAMA\services\llama_factory

Write-Host "Starting training process..." -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor DarkGray

# Launch training
& .\venv\Scripts\python.exe src/train.py triz_qwen3b_full.yaml

$exitCode = $LASTEXITCODE

Write-Host "`n============================================" -ForegroundColor DarkGray
Write-Host "Training process exited with code: $exitCode" -ForegroundColor $(if ($exitCode -eq 0) { "Green" } else { "Red" })

# =====================================================================
# SECTION 7: Check final VRAM and results
# =====================================================================
Write-Host "`n[7/7] Final VRAM check..." -ForegroundColor Cyan

Start-Sleep -Seconds 2
$finalVRAM = nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits
Write-Host "Final VRAM: $finalVRAM MB" -ForegroundColor Yellow
Write-Host "Baseline was: $baselineVRAM MB" -ForegroundColor DarkGray

# =====================================================================
# RESULTS ANALYSIS
# =====================================================================
Write-Host "`n=== TD-010v3 TRAINING RESULTS ===" -ForegroundColor Cyan

if ($exitCode -eq 0) {
    Write-Host "`n✅ SUCCESS: Training completed!" -ForegroundColor Green
    
    # Check for output files
    $outputDir = "E:\WORLD_OLLAMA\services\llama_factory\saves\Qwen2.5-3B\lora\triz_td010v3"
    if (Test-Path "$outputDir\adapter_model.safetensors") {
        $adapterSize = [math]::Round((Get-Item "$outputDir\adapter_model.safetensors").Length / 1MB, 2)
        Write-Host "Adapter created: $adapterSize MB" -ForegroundColor Green
    }
    
    # Parse metrics
    if (Test-Path "$outputDir\train_results.json") {
        $trainResults = Get-Content "$outputDir\train_results.json" | ConvertFrom-Json
        Write-Host "`n📊 Training metrics:" -ForegroundColor Cyan
        Write-Host "  Train loss: $([math]::Round($trainResults.train_loss, 4))" -ForegroundColor Yellow
        Write-Host "  Runtime: $([math]::Round($trainResults.train_runtime / 60, 2)) minutes" -ForegroundColor Yellow
    }
    
    if (Test-Path "$outputDir\eval_results.json") {
        $evalResults = Get-Content "$outputDir\eval_results.json" | ConvertFrom-Json
        Write-Host "`n📈 Evaluation metrics:" -ForegroundColor Cyan
        Write-Host "  Eval loss: $([math]::Round($evalResults.eval_loss, 4))" -ForegroundColor Green
        Write-Host ""
        
        # Compare with TD-010v2 (1.5B)
        Write-Host "📊 COMPARISON with TD-010v2 (Qwen2.5-1.5B):" -ForegroundColor Cyan
        Write-Host "  TD-010v2 (1.5B): eval_loss = 0.9358" -ForegroundColor DarkYellow
        Write-Host "  TD-010v3 (3B):   eval_loss = $([math]::Round($evalResults.eval_loss, 4))" -ForegroundColor Yellow
        
        $improvement = (0.9358 - $evalResults.eval_loss) / 0.9358 * 100
        if ($improvement -gt 0) {
            Write-Host "  Improvement: +$([math]::Round($improvement, 1))%" -ForegroundColor Green
        } else {
            Write-Host "  Degradation: $([math]::Round($improvement, 1))%" -ForegroundColor Red
        }
    }
    
    Write-Host "`n📊 NEXT STEP: Export adapter for Git LFS" -ForegroundColor Cyan
    Write-Host "   Run: cd E:\WORLD_OLLAMA\services\llama_factory" -ForegroundColor Yellow
    Write-Host "        cp saves\Qwen2.5-3B\lora\triz_td010v3\adapter_model.safetensors E:\WORLD_OLLAMA\saves\td010v3\`n" -ForegroundColor Yellow
    
} else {
    Write-Host "`n❌ FAILED: Training crashed" -ForegroundColor Red
    Write-Host "   Check logs at: saves\Qwen2.5-3B\lora\triz_td010v3\`n" -ForegroundColor Yellow
}

Write-Host "=== END OF TD-010v3 FULL TRAINING ===`n" -ForegroundColor Cyan
