

# start_agent_training.ps1
# Universal training launcher for WORLD_OLLAMA agents
# Created: 27.11.2025 (Task 9.2)
# Usage: .\start_agent_training.ps1 -Profile "triz_engineer" -DataPath "E:\DATA" -Epochs 5 -Mode "llama_factory"

param(
    [Parameter(Mandatory = $true)]
    [string]$Profile,
    
    [Parameter(Mandatory = $true)]
    [string]$DataPath,
    
    [int]$Epochs = 3,
    
    [string]$Mode = "llama_factory",
    
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   AGENT TRAINING: $Profile" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Data:   $DataPath" -ForegroundColor Gray
Write-Host "Epochs: $Epochs" -ForegroundColor Gray
Write-Host "Mode:   $Mode" -ForegroundColor Gray
Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# Validation: Check DATA_PATH exists
if (-not (Test-Path $DataPath)) {
    Write-Host " ERROR: DATA_PATH not found: $DataPath" -ForegroundColor Red
    exit 1
}

# Validation: Check Mode
if ($Mode -ne "llama_factory") {
    Write-Host " WARNING: Only 'llama_factory' mode supported (got: $Mode)" -ForegroundColor Yellow
    Write-Host "    Proceeding with llama_factory..." -ForegroundColor Gray
}

# Navigate to LLaMA Factory (TASK 16.1: Dynamic path)
$llamaFactoryPath = Join-Path $ProjectRoot "services\llama_factory"
if (-not (Test-Path $llamaFactoryPath)) {
    Write-Host " ERROR: LLaMA Factory not found at: $llamaFactoryPath" -ForegroundColor Red
    exit 1
}

Set-Location $llamaFactoryPath

# Check venv
$pythonExe = "venv\Scripts\python.exe"
if (-not (Test-Path $pythonExe)) {
    Write-Host " ERROR: Python venv not found at: $pythonExe" -ForegroundColor Red
    Write-Host "   Run: python -m venv venv" -ForegroundColor Yellow
    exit 1
}

# ========================================
# 15.2.3: PROFILE-BASED CONFIG ROUTING
# ========================================

$ConfigPath = $null
$OutputDir = $null

switch ($Profile) {
    "triz_td010v3_full" {
        $ConfigPath = "$llamaFactoryPath\triz_td010v3_full.yaml"
        $OutputDir = "$llamaFactoryPath\outputs\triz_td010v3"
        Write-Host " Profile: TRIZ TD010v3 (LoRA, Qwen 14B)" -ForegroundColor Cyan
    }
    "triz_td010v3_smoketest" {
        # 15.2.5: Smoke-test профиль с ограниченным датасетом
        $ConfigPath = "$llamaFactoryPath\triz_td010v3_smoketest.yaml"
        $OutputDir = "$llamaFactoryPath\outputs\triz_td010v3_smoketest"
        Write-Host " Profile: TRIZ TD010v3 SMOKE-TEST (100 examples, 50 steps)" -ForegroundColor Yellow
    }
    "triz_engineer" {
        # Legacy profile name (still functional, uses triz_safe_config.yaml)
        $ConfigPath = "$llamaFactoryPath\triz_safe_config.yaml"
        $OutputDir = "$llamaFactoryPath\saves\Qwen2-7B-Instruct\lora\triz_safe"
        Write-Host " Profile: TRIZ Engineer (Active)" -ForegroundColor Cyan
    }
    default {
        Write-Host " ERROR: Unknown profile '$Profile'" -ForegroundColor Red
        Write-Host "   Supported profiles: triz_td010v3_full, triz_td010v3_smoketest, triz_engineer" -ForegroundColor Yellow
        exit 1
    }
}

if (-not (Test-Path $ConfigPath)) {
    Write-Host " ERROR: Config file not found: $ConfigPath" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Training parameters:" -ForegroundColor Green
Write-Host "   Profile:     $Profile" -ForegroundColor White
Write-Host "   Config:      $ConfigPath" -ForegroundColor White
Write-Host "   Output Dir:  $OutputDir" -ForegroundColor White
Write-Host "   Data Path:   $DataPath" -ForegroundColor White
Write-Host "   Epochs:      $Epochs" -ForegroundColor White

# ========================================
# REAL TRAINING EXECUTION (15.2.3)
# ========================================

Write-Host "`n Launching LLaMA Factory training..." -ForegroundColor Green

# Формируем команду для вызова llamafactory-cli train
$trainCommand = "llamafactory-cli train `"$ConfigPath`""

Write-Host "   Command: $trainCommand" -ForegroundColor Gray

# Escape quotes for interpolation in Start-Process argument
$trainCommandEscaped = $trainCommand -replace '"', '`"'

# Запускаем обучение в отдельном окне PowerShell (не блокируя UI)
try {
    Start-Process -FilePath "pwsh.exe" -ArgumentList "-NoExit", "-Command", "cd '$llamaFactoryPath'; . .\venv\Scripts\Activate.ps1; $trainCommandEscaped" -WorkingDirectory $llamaFactoryPath
    
    Write-Host " Training process started in new window" -ForegroundColor Green
}
catch {
    Write-Host " ERROR: Failed to launch training: $_" -ForegroundColor Red
    exit 1
}

# Update training_status.json in %APPDATA%
$statusDir = "$env:APPDATA\tauri_fresh"
if (-not (Test-Path $statusDir)) {
    New-Item -ItemType Directory -Path $statusDir -Force | Out-Null
}

$statusFile = Join-Path $statusDir "training_status.json"
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

$status = @{
    state      = "queued"
    profile    = $Profile
    data_path  = $DataPath
    epochs     = $Epochs
    mode       = $Mode
    started_at = $timestamp
    last_error = $null
} | ConvertTo-Json -Depth 3

Set-Content -Path $statusFile -Value $status -Encoding UTF8

Write-Host "`n Training job queued successfully!" -ForegroundColor Green
Write-Host "   Status file: $statusFile" -ForegroundColor Gray
Write-Host "`n   Next steps (manual for now):" -ForegroundColor Yellow
Write-Host "   1. Create config file for profile '$Profile'" -ForegroundColor DarkYellow
Write-Host "   2. Run real training: python src\train.py [config]" -ForegroundColor DarkYellow
Write-Host "   3. Monitor progress in LLaMA Board UI" -ForegroundColor DarkYellow

Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan

# Return to root
Set-Location "E:\WORLD_OLLAMA"

exit 0
