# TD-010v3 Mini-Test Launcher (Qwen2.5-3B)
# Purpose: Test if 3B model fits in 16GB VRAM during training
# Date: 2025-11-27
# Critical: VRAM monitoring to determine if full training possible

param(
    [switch]$SkipOllamaKill = $false
)

Write-Host "`n=== TD-010v3 MINI-TEST: Qwen2.5-3B VRAM Check ===" -ForegroundColor Cyan
Write-Host "Purpose: Determine if 3B training fits in RTX 5060 Ti 16GB" -ForegroundColor Yellow
Write-Host "Test: 10 samples, 1 epoch, batch_size=1, cutoff_len=1024`n" -ForegroundColor Yellow

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
    
    # Also shutdown WSL to free vmmemWSL
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
    Write-Host "Consider killing other processes or waiting..." -ForegroundColor Yellow
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
Write-Host "  CUDA_LAUNCH_BLOCKING = $env:CUDA_LAUNCH_BLOCKING" -ForegroundColor DarkGray
Write-Host "  HF_DATASETS_CACHE = $env:HF_DATASETS_CACHE" -ForegroundColor DarkGray

# =====================================================================
# SECTION 5: Verify config file exists
# =====================================================================
Write-Host "`n[5/7] Verifying configuration file..." -ForegroundColor Cyan

$configPath = "E:\WORLD_OLLAMA\services\llama_factory\triz_qwen3b_minitest.yaml"
if (-not (Test-Path $configPath)) {
    Write-Host "ERROR: Config file not found at $configPath" -ForegroundColor Red
    exit 1
}

Write-Host "Config file found: triz_qwen3b_minitest.yaml" -ForegroundColor Green
Write-Host "  Model: Qwen/Qwen2.5-3B-Instruct" -ForegroundColor DarkGray
Write-Host "  Dataset: triz_synthesis_v1 (10 samples)" -ForegroundColor DarkGray
Write-Host "  LoRA rank: 8" -ForegroundColor DarkGray
Write-Host "  Quantization: 4-bit NF4" -ForegroundColor DarkGray

# =====================================================================
# SECTION 6: Launch training with VRAM monitoring
# =====================================================================
Write-Host "`n[6/7] Launching mini-test training..." -ForegroundColor Cyan
Write-Host "Expected stages:" -ForegroundColor Yellow
Write-Host "  1. Model loading (30-60s) - VRAM should be ~5-6 GB" -ForegroundColor DarkYellow
Write-Host "  2. First training step - CRITICAL CHECK: VRAM < 14 GB" -ForegroundColor DarkYellow
Write-Host "  3. Training 8 samples (10 total - 2 eval)" -ForegroundColor DarkYellow
Write-Host ""

Set-Location E:\WORLD_OLLAMA\services\llama_factory

Write-Host "Starting training process..." -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor DarkGray

# Launch training
& .\venv\Scripts\python.exe src/train.py triz_qwen3b_minitest.yaml

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
Write-Host "`n=== MINI-TEST RESULTS ===" -ForegroundColor Cyan

if ($exitCode -eq 0) {
    Write-Host "`n✅ SUCCESS: Training completed without OOM!" -ForegroundColor Green
    Write-Host "   Qwen2.5-3B CAN be trained on RTX 5060 Ti 16GB`n" -ForegroundColor Green
    
    # Check for output files
    $outputDir = "E:\WORLD_OLLAMA\services\llama_factory\saves\Qwen2.5-3B\lora\triz_minitest"
    if (Test-Path "$outputDir\adapter_model.safetensors") {
        $adapterSize = [math]::Round((Get-Item "$outputDir\adapter_model.safetensors").Length / 1MB, 2)
        Write-Host "Adapter created: $adapterSize MB" -ForegroundColor Green
    }
    
    # Parse metrics if available
    if (Test-Path "$outputDir\trainer_log.jsonl") {
        $lastLog = Get-Content "$outputDir\trainer_log.jsonl" | Select-Object -Last 1 | ConvertFrom-Json
        if ($lastLog.loss) {
            Write-Host "Final train_loss: $([math]::Round($lastLog.loss, 4))" -ForegroundColor Green
        }
    }
    
    Write-Host "`n📊 NEXT STEP: Full training (300 samples)" -ForegroundColor Cyan
    Write-Host "   Run: pwsh E:\WORLD_OLLAMA\scripts\train_td010v3_full.ps1`n" -ForegroundColor Yellow
    
} elseif ($exitCode -eq 1) {
    Write-Host "`n❌ FAILED: Training crashed (likely OOM)" -ForegroundColor Red
    Write-Host "   Qwen2.5-3B is TOO LARGE for RTX 5060 Ti 16GB`n" -ForegroundColor Red
    
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  1. Stay with Qwen2.5-1.5B (proven to work)" -ForegroundColor White
    Write-Host "  2. Try further optimization (rank 4, cutoff 512)" -ForegroundColor White
    Write-Host "  3. Rent cloud GPU for 3B/7B training`n" -ForegroundColor White
    
} else {
    Write-Host "`n⚠️ UNKNOWN EXIT CODE: $exitCode" -ForegroundColor Yellow
    Write-Host "   Check logs manually`n" -ForegroundColor Yellow
}

Write-Host "=== END OF MINI-TEST ===`n" -ForegroundColor Cyan
