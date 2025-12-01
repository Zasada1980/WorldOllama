# start_agent_training.ps1
# Universal training launcher for WORLD_OLLAMA agents
# Created: 01.12.2025 (ORDER 42.3)
# Usage: .\start_agent_training.ps1 -Profile "triz_engineer" -DataPath "E:\DATA" -Epochs 3 -Mode "llama_factory"

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

# ============================================================
# SETUP LOGGING
# ============================================================
$logDir = Join-Path $ProjectRoot "logs\training"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logDir "train-$timestamp.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logLine = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Add-Content -Path $logFile -Value $logLine
    
    switch ($Level) {
        "ERROR" { Write-Host $Message -ForegroundColor Red }
        "WARN" { Write-Host $Message -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        default { Write-Host $Message -ForegroundColor Gray }
    }
}

# ============================================================
# BANNER
# ============================================================
Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🧠 AGENT TRAINING: $Profile" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Data:   $DataPath" -ForegroundColor Gray
Write-Host "Epochs: $Epochs" -ForegroundColor Gray
Write-Host "Mode:   $Mode" -ForegroundColor Gray
Write-Host "Log:    $logFile" -ForegroundColor DarkGray
Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan

Write-Log "Training started: Profile=$Profile, DataPath=$DataPath, Epochs=$Epochs, Mode=$Mode"

# ============================================================
# VALIDATION
# ============================================================

# Validate Profile (whitelist)
$validProfiles = @("default", "triz_engineer", "triz_researcher", "triz_td010v3_full", "triz_td010v3_smoketest", "lightweight")
if ($Profile -notin $validProfiles) {
    Write-Log "Invalid PROFILE: $Profile. Valid: $($validProfiles -join ', ')" "ERROR"
    exit 1
}

# Validate DataPath exists
if (-not (Test-Path $DataPath)) {
    Write-Log "DATA_PATH not found: $DataPath" "ERROR"
    exit 1
}

# Validate Epochs range
if ($Epochs -lt 1 -or $Epochs -gt 10) {
    Write-Log "EPOCHS must be between 1-10 (got: $Epochs)" "ERROR"
    exit 1
}

# Validate Mode
if ($Mode -ne "llama_factory") {
    Write-Log "Only 'llama_factory' mode is supported (got: $Mode)" "WARN"
    Write-Log "Proceeding with llama_factory..."
}

Write-Log "Validation passed" "SUCCESS"

# ============================================================
# SETUP PULSE v1 STATUS
# ============================================================
$statusDir = Join-Path $env:APPDATA "com.tauri.world-ollama"
if (-not (Test-Path $statusDir)) {
    New-Item -ItemType Directory -Path $statusDir -Force | Out-Null
}

$statusFile = Join-Path $statusDir "training_status.json"

function Update-TrainingStatus {
    param(
        [string]$State,
        [string]$Message = "",
        [int]$CurrentEpoch = 0,
        [int]$TotalEpochs = $Epochs,
        [double]$Loss = 0.0,
        [string]$Error = $null
    )
    
    $status = @{
        status        = $State
        message       = $Message
        current_epoch = $CurrentEpoch
        total_epochs  = $TotalEpochs
        loss          = $Loss
        profile       = $Profile
        data_path     = $DataPath
        mode          = $Mode
        started_at    = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        last_update   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        last_error    = $Error
    } | ConvertTo-Json -Depth 3
    
    Set-Content -Path $statusFile -Value $status -Encoding UTF8
    Write-Log "PULSE: $State $(if ($Message) { "- $Message" })"
}

Update-TrainingStatus -State "queued" -Message "Training job queued"

# ============================================================
# NAVIGATE TO LLAMA FACTORY
# ============================================================
$llamaFactoryPath = Join-Path $ProjectRoot "services\llama_factory"
if (-not (Test-Path $llamaFactoryPath)) {
    Update-TrainingStatus -State "error" -Error "LLaMA Factory not found at: $llamaFactoryPath"
    Write-Log "LLaMA Factory directory not found: $llamaFactoryPath" "ERROR"
    exit 1
}

Write-Log "LLaMA Factory found: $llamaFactoryPath" "SUCCESS"
Set-Location $llamaFactoryPath

# ============================================================
# CHECK PYTHON ENVIRONMENT
# ============================================================
$pythonExe = Join-Path $llamaFactoryPath "venv\Scripts\python.exe"
if (-not (Test-Path $pythonExe)) {
    Update-TrainingStatus -State "error" -Error "Python venv not found. Run: python -m venv venv"
    Write-Log "Python venv not found at: $pythonExe" "ERROR"
    Write-Log "Create venv with: python -m venv venv" "WARN"
    exit 1
}

Write-Log "Python venv found: $pythonExe" "SUCCESS"

# Check llamafactory-cli
$llamaFactoryCli = Join-Path $llamaFactoryPath "venv\Scripts\llamafactory-cli.exe"
if (-not (Test-Path $llamaFactoryCli)) {
    Update-TrainingStatus -State "error" -Error "llamafactory-cli not found. Run: pip install -e ."
    Write-Log "llamafactory-cli not found. Install with: pip install -e ." "ERROR"
    exit 1
}

Write-Log "llamafactory-cli found: $llamaFactoryCli" "SUCCESS"

# ============================================================
# BUILD TRAINING CONFIG
# ============================================================
Write-Log "Building training configuration..."

# Map profile to config file
$configMap = @{
    "default"                = "examples\train_lora\llama3_lora_sft.yaml"
    "triz_engineer"          = "examples\train_lora\llama3_lora_sft.yaml"
    "triz_researcher"        = "examples\train_lora\llama3_lora_sft.yaml"
    "triz_td010v3_full"      = "examples\train_lora\llama3_lora_sft.yaml"
    "triz_td010v3_smoketest" = "examples\train_lora\llama3_lora_sft.yaml"
    "lightweight"            = "examples\train_lora\llama3_lora_sft.yaml"
}

$configTemplate = $configMap[$Profile]
if (-not $configTemplate) {
    $configTemplate = $configMap["default"]
}

$configFile = Join-Path $llamaFactoryPath $configTemplate
if (-not (Test-Path $configFile)) {
    Update-TrainingStatus -State "error" -Error "Config template not found: $configTemplate"
    Write-Log "Config template not found: $configFile" "ERROR"
    exit 1
}

Write-Log "Using config template: $configTemplate" "SUCCESS"

# ============================================================
# START TRAINING
# ============================================================
Update-TrainingStatus -State "running" -Message "Starting training process..."

Write-Host "`n🚀 Starting LLaMA Factory training..." -ForegroundColor Green
Write-Host "   Command: llamafactory-cli train $configTemplate" -ForegroundColor DarkGray
Write-Host "   Output will be logged to: $logFile`n" -ForegroundColor DarkGray

Write-Log "Executing: llamafactory-cli train $configTemplate"

try {
    # Start training process
    $process = Start-Process -FilePath $llamaFactoryCli `
        -ArgumentList "train", $configTemplate `
        -WorkingDirectory $llamaFactoryPath `
        -NoNewWindow `
        -PassThru `
        -RedirectStandardOutput (Join-Path $logDir "train-$timestamp-stdout.log") `
        -RedirectStandardError (Join-Path $logDir "train-$timestamp-stderr.log")
    
    Write-Log "Training process started with PID: $($process.Id)" "SUCCESS"
    Update-TrainingStatus -State "running" -Message "Training in progress (PID: $($process.Id))" -CurrentEpoch 1
    
    Write-Host "✅ Training started successfully!" -ForegroundColor Green
    Write-Host "   Process ID: $($process.Id)" -ForegroundColor Gray
    Write-Host "   Status file: $statusFile" -ForegroundColor DarkGray
    Write-Host "`n💡 Monitor progress in the Training Panel or check logs at:" -ForegroundColor Cyan
    Write-Host "   $logFile`n" -ForegroundColor DarkGray
    
}
catch {
    $errorMsg = $_.Exception.Message
    Update-TrainingStatus -State "error" -Error "Failed to start training: $errorMsg"
    Write-Log "Training failed: $errorMsg" "ERROR"
    exit 1
}

Write-Log "Training script completed successfully"
exit 0
