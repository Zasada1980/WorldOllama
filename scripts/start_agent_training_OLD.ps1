# start_agent_training.ps1
# Universal training launcher for WORLD_OLLAMA agents
# Created: 27.11.2025 (Task 9.2)
# Usage: .\start_agent_training.ps1 -Profile "triz_engineer" -DataPath "E:\DATA" -Epochs 5 -Mode "llama_factory"

param(
    [Parameter(Mandatory=$true)]
    [string]$Profile,
    
    [Parameter(Mandatory=$true)]
    [string]$DataPath,
    
    [int]$Epochs = 3,
    
    [string]$Mode = "llama_factory"
)

$ErrorActionPreference = "Stop"

Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🧠 AGENT TRAINING: $Profile" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Data:   $DataPath" -ForegroundColor Gray
Write-Host "Epochs: $Epochs" -ForegroundColor Gray
Write-Host "Mode:   $Mode" -ForegroundColor Gray
Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# Validation: Check DATA_PATH exists
if (-not (Test-Path $DataPath)) {
    Write-Host "❌ ERROR: DATA_PATH not found: $DataPath" -ForegroundColor Red
    exit 1
}

# Validation: Check Mode
if ($Mode -ne "llama_factory") {
    Write-Host "⚠️  WARNING: Only 'llama_factory' mode supported (got: $Mode)" -ForegroundColor Yellow
    Write-Host "    Proceeding with llama_factory..." -ForegroundColor Gray
}

# Navigate to LLaMA Factory
$llamaFactoryPath = "E:\WORLD_OLLAMA\services\llama_factory"
if (-not (Test-Path $llamaFactoryPath)) {
    Write-Host "❌ ERROR: LLaMA Factory not found at: $llamaFactoryPath" -ForegroundColor Red
    exit 1
}

Set-Location $llamaFactoryPath

# Check venv
$pythonExe = "venv\Scripts\python.exe"
if (-not (Test-Path $pythonExe)) {
    Write-Host "❌ ERROR: Python venv not found at: $pythonExe" -ForegroundColor Red
    Write-Host "   Run: python -m venv venv" -ForegroundColor Yellow
    exit 1
}

# TODO: Generate config file for this training session
# For MVP, we use existing config and just log parameters
Write-Host "📋 Training parameters:" -ForegroundColor Green
Write-Host "   Profile:    $Profile" -ForegroundColor White
Write-Host "   Data Path:  $DataPath" -ForegroundColor White
Write-Host "   Epochs:     $Epochs" -ForegroundColor White

# MVP: Stub execution (don't run real training yet for safety)
Write-Host "`n⚠️  MVP MODE: Training stub (not running real train.py)" -ForegroundColor Yellow
Write-Host "   This would execute:" -ForegroundColor Gray
Write-Host "   $pythonExe src\train.py <config_file>" -ForegroundColor DarkGray

# Update training_status.json in %APPDATA%
$statusDir = "$env:APPDATA\tauri_fresh"
if (-not (Test-Path $statusDir)) {
    New-Item -ItemType Directory -Path $statusDir -Force | Out-Null
}

$statusFile = Join-Path $statusDir "training_status.json"
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

$status = @{
    state = "queued"
    profile = $Profile
    data_path = $DataPath
    epochs = $Epochs
    mode = $Mode
    started_at = $timestamp
    last_error = $null
} | ConvertTo-Json -Depth 3

Set-Content -Path $statusFile -Value $status -Encoding UTF8

Write-Host "`n✅ Training job queued successfully!" -ForegroundColor Green
Write-Host "   Status file: $statusFile" -ForegroundColor Gray
Write-Host "`n   Next steps (manual for now):" -ForegroundColor Yellow
Write-Host "   1. Create config file for profile '$Profile'" -ForegroundColor DarkYellow
Write-Host "   2. Run real training: python src\train.py <config>" -ForegroundColor DarkYellow
Write-Host "   3. Monitor progress in LLaMA Board UI" -ForegroundColor DarkYellow

Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan

# Return to root
Set-Location "E:\WORLD_OLLAMA"

exit 0
