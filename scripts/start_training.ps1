# LLaMA-Factory Training UI Launcher for RTX 5060 Ti (sm_120 Blackwell)
# Optimized for CUDA 12.8 + PyTorch 2.10 nightly
# SESA3002a FIX (25.11.2025): Corrected entry point to src/webui.py

Write-Host "🚀 Starting LLaMA-Factory (Blackwell Edition)..." -ForegroundColor Green

# Environment configuration
$env:CUDA_VISIBLE_DEVICES = "0"
$env:GRADIO_SERVER_PORT = "7860"
$env:HF_HUB_ENABLE_HF_TRANSFER = "1"  # Fast downloads via hf_transfer
$env:HF_HUB_DISABLE_SYMLINKS_WARNING = "1"  # Suppress symlink warnings on Windows

# Navigate to LLaMA-Factory directory
Set-Location "E:\WORLD_OLLAMA\services\llama_factory"

# Activate virtual environment
Write-Host "📦 Activating venv..." -ForegroundColor Yellow
.\venv\Scripts\Activate.ps1

# Launch training UI
Write-Host "🌐 Launching Gradio UI on http://localhost:7860..." -ForegroundColor Green
Write-Host "📌 GPU: RTX 5060 Ti 16GB (sm_120 Blackwell) | CUDA 12.8 | PyTorch 2.10 nightly" -ForegroundColor Magenta

# SESA FIX: Correct entry point
python src/webui.py
