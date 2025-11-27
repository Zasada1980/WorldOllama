# TD-010v2 GGUF Export Launcher
# Purpose: Export best 1.5B adapter (eval_loss 0.8591) to GGUF Q4_K_M
# Hardware: RTX 5060 Ti 16GB (sm_120)
# Date: 27 ноября 2025 г.

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  TD-010v2 GGUF EXPORT (Q4_K_M)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Environment Setup
$ROOT = "E:\WORLD_OLLAMA"
$VENV = "$ROOT\services\llama_factory\venv"
$CONFIG = "$ROOT\services\llama_factory\triz_td010v2_export_gguf.yaml"
$ADAPTER_PATH = "$ROOT\services\llama_factory\saves\Qwen2.5-1.5B-Instruct\lora\triz_full"
$MERGED_DIR = "$ROOT\models\triz-td010v2-merged"
$GGUF_DIR = "$ROOT\models\triz-td010v2-gguf"

# Validation
Write-Host "📋 Pre-Export Validation:" -ForegroundColor Yellow
Write-Host "  ├─ Adapter Path: $ADAPTER_PATH" -ForegroundColor White

if (-not (Test-Path "$ADAPTER_PATH\adapter_model.safetensors")) {
    Write-Host "  └─ ❌ ERROR: Adapter not found!" -ForegroundColor Red
    exit 1
}

$adapterSize = [math]::Round((Get-Item "$ADAPTER_PATH\adapter_model.safetensors").Length/1MB, 2)
Write-Host "  ├─ Adapter Size: $adapterSize MB" -ForegroundColor Green

# Check metrics
if (Test-Path "$ADAPTER_PATH\..\all_results.json") {
    $metrics = Get-Content "$ADAPTER_PATH\..\all_results.json" | ConvertFrom-Json
    Write-Host "  ├─ eval_loss: $($metrics.eval_loss)" -ForegroundColor Green
    Write-Host "  ├─ train_loss: $($metrics.train_loss)" -ForegroundColor Green
}

Write-Host "  └─ ✅ Validation passed!`n" -ForegroundColor Green

# Create output directories
if (-not (Test-Path $MERGED_DIR)) {
    Write-Host "📁 Creating merged model directory: $MERGED_DIR" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $MERGED_DIR -Force | Out-Null
}
if (-not (Test-Path $GGUF_DIR)) {
    Write-Host "📁 Creating GGUF directory: $GGUF_DIR" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $GGUF_DIR -Force | Out-Null
}

# Activate venv
Write-Host "🔧 Activating LLaMA Factory venv..." -ForegroundColor Yellow
& "$VENV\Scripts\Activate.ps1"

# Check llamafactory-cli
$cli = Get-Command llamafactory-cli -ErrorAction SilentlyContinue
if (-not $cli) {
    Write-Host "❌ ERROR: llamafactory-cli not found in venv!" -ForegroundColor Red
    exit 1
}
Write-Host "  └─ ✅ llamafactory-cli found: $($cli.Source)`n" -ForegroundColor Green

# VRAM Check
Write-Host "🎮 GPU Status (before export):" -ForegroundColor Yellow
$gpu = nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits
Write-Host "  └─ $gpu`n" -ForegroundColor White

# STEP 1: Export merged HF model (LoRA + base)
Write-Host "🚀 STEP 1: Merging LoRA adapter into base model..." -ForegroundColor Cyan
Write-Host "  ├─ Config: $CONFIG" -ForegroundColor White
Write-Host "  ├─ Output: $MERGED_DIR" -ForegroundColor White
Write-Host "  └─ Format: HuggingFace safetensors`n" -ForegroundColor White

$step1Start = Get-Date

try {
    llamafactory-cli export $CONFIG
    
    $step1End = Get-Date
    $step1Duration = $step1End - $step1Start
    
    Write-Host "`n✅ STEP 1 completed in $($step1Duration.TotalMinutes.ToString('0.00')) minutes!" -ForegroundColor Green
    
    # Verify merged model
    if (Test-Path "$MERGED_DIR\model*.safetensors") {
        $mergedSize = (Get-ChildItem "$MERGED_DIR\model*.safetensors" | Measure-Object -Property Length -Sum).Sum / 1MB
        Write-Host "  └─ Merged model size: $([math]::Round($mergedSize, 2)) MB`n" -ForegroundColor Green
    } else {
        Write-Host "  └─ ⚠️ WARNING: No safetensors files found!" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "`n❌ STEP 1 failed with error:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# STEP 2: Convert HF model to GGUF Q4_K_M
Write-Host "🚀 STEP 2: Converting to GGUF Q4_K_M..." -ForegroundColor Cyan
Write-Host "  ├─ Input: $MERGED_DIR" -ForegroundColor White
Write-Host "  ├─ Output: $GGUF_DIR" -ForegroundColor White
Write-Host "  └─ Quantization: Q4_K_M (optimal quality/size)`n" -ForegroundColor White

$step2Start = Get-Date

try {
    # Use llama.cpp convert.py (if available) or HF to_gguf
    # Note: This requires llama.cpp installation
    Write-Host "  ⚠️ STEP 2 requires manual conversion:" -ForegroundColor Yellow
    Write-Host "  1. Install llama.cpp: git clone https://github.com/ggerganov/llama.cpp" -ForegroundColor White
    Write-Host "  2. Convert: python llama.cpp/convert_hf_to_gguf.py $MERGED_DIR --outfile $GGUF_DIR\triz-td010v2-q4km.gguf --outtype q4_k_m`n" -ForegroundColor White
    Write-Host "  OR use Ollama directly (see next steps)" -ForegroundColor White
    
} catch {
    Write-Host "`n⚠️ STEP 2 skipped (manual conversion required)" -ForegroundColor Yellow
}

# Final VRAM check
Write-Host "🎮 GPU Status (after export):" -ForegroundColor Yellow
$gpu = nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits
Write-Host "  └─ $gpu`n" -ForegroundColor White

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TD-010v2 EXPORT COMPLETE!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "📝 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Create Ollama Modelfile (see config YAML comments)" -ForegroundColor White
Write-Host "  2. Test: ollama create triz-td010v2 -f Modelfile" -ForegroundColor White
Write-Host "  3. Run: ollama run triz-td010v2" -ForegroundColor White
Write-Host "  4. Benchmark on TRIZ tasks (10 questions)`n" -ForegroundColor White
