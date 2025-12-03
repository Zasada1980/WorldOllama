# ========================================
# WORLD_OLLAMA - Service Orchestrator
# START_ALL.ps1
# Версия: 1.0
# Дата: 27 ноября 2025
# ========================================

param(
    [switch]$SkipNeuroTerminal = $false,
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"
$Global:LogFile = Join-Path $ProjectRoot "logs\orchestrator.log"

# Создать директорию логов если не существует
$logsDir = Join-Path $ProjectRoot "logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    Add-Content -Path $Global:LogFile -Value $logMessage
    
    switch ($Level) {
        "ERROR" { Write-Host $Message -ForegroundColor Red }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        "WARNING" { Write-Host $Message -ForegroundColor Yellow }
        default { Write-Host $Message -ForegroundColor Cyan }
    }
}

function Test-Port {
    param([int]$Port)
    
    try {
        $connection = Test-NetConnection -ComputerName "localhost" -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
        return $connection
    } catch {
        return $false
    }
}

function Wait-ForService {
    param(
        [string]$Name,
        [int]$Port,
        [string]$HealthEndpoint,
        [int]$TimeoutSeconds = 30,
        [switch]$IsChainlit = $false
    )
    
    Write-Log "Waiting for $Name to start (port $Port)..." "INFO"
    
    $elapsed = 0
    while ($elapsed -lt $TimeoutSeconds) {
        if (Test-Port -Port $Port) {
            try {
                if ($IsChainlit) {
                    # Chainlit проверка: ждём реальный HTML ответ
                    $response = Invoke-WebRequest -Uri $HealthEndpoint -TimeoutSec 3 -UseBasicParsing -ErrorAction SilentlyContinue
                    if ($response -and $response.StatusCode -eq 200 -and $response.Content.Length -gt 100) {
                        Write-Log "✓ $Name is ready! (HTTP 200, Content: $($response.Content.Length) bytes)" "SUCCESS"
                        return $true
                    }
                } else {
                    # Обычная проверка health endpoint
                    $response = Invoke-RestMethod -Uri $HealthEndpoint -TimeoutSec 2 -ErrorAction SilentlyContinue
                    if ($response) {
                        Write-Log "✓ $Name is ready!" "SUCCESS"
                        return $true
                    }
                }
            } catch {
                # Health endpoint not ready yet, продолжаем ждать
            }
        }
        
        Start-Sleep -Seconds 1
        $elapsed++
        
        if ($elapsed % 10 -eq 0) {
            Write-Log "  Still waiting... ($elapsed/$TimeoutSeconds seconds)" "INFO"
        }
    }
    
    Write-Log "✗ $Name failed to start within ${TimeoutSeconds}s" "ERROR"
    return $false
}

# ========================================
# MAIN EXECUTION
# ========================================

Write-Log "========================================" "INFO"
Write-Log "WORLD_OLLAMA Service Orchestrator" "INFO"
Write-Log "Starting all services..." "INFO"
Write-Log "========================================" "INFO"

# ----------------------------------------
# 1. CHECK OLLAMA
# ----------------------------------------

Write-Log "" "INFO"
Write-Log "Step 1: Checking Ollama service..." "INFO"

if (-not (Test-Port -Port 11434)) {
    Write-Log "✗ Ollama is not running on port 11434" "ERROR"
    Write-Log "Please start Ollama service manually:" "ERROR"
    Write-Log "  - Open Ollama app from Start Menu, OR" "ERROR"
    Write-Log "  - Run: ollama serve" "ERROR"
    Write-Log "" "ERROR"
    Write-Log "Aborting startup." "ERROR"
    exit 1
}

try {
    $ollamaModels = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5
    Write-Log "✓ Ollama is running" "SUCCESS"
    
    # Check for required models
    $requiredModels = @("qwen2.5:14b", "nomic-embed-text:latest")
    $availableModels = $ollamaModels.models.name
    
    foreach ($model in $requiredModels) {
        if ($availableModels -contains $model) {
            Write-Log "  ✓ Model available: $model" "SUCCESS"
        } else {
            Write-Log "  ⚠ Model missing: $model" "WARNING"
            Write-Log "    Run: ollama pull $model" "WARNING"
        }
    }
} catch {
    Write-Log "✗ Ollama health check failed: $_" "ERROR"
    exit 1
}

# ----------------------------------------
# 2. START CORTEX (LightRAG)
# ----------------------------------------

Write-Log "" "INFO"
Write-Log "Step 2: Starting CORTEX (LightRAG)..." "INFO"

if (Test-Port -Port 8004) {
    Write-Log "⚠ CORTEX already running on port 8004" "WARNING"
} else {
    $cortexPath = Join-Path $ProjectRoot "services\lightrag"
    
    if (-not (Test-Path $cortexPath)) {
        Write-Log "✗ CORTEX directory not found: $cortexPath" "ERROR"
        exit 1
    }
    
    $cortexCmd = @"
cd '$cortexPath'
.\venv\Scripts\Activate.ps1
python lightrag_server.py
"@
    
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $cortexCmd -WindowStyle Normal
    
    if (Wait-ForService -Name "CORTEX" -Port 8004 -HealthEndpoint "http://localhost:8004/health" -TimeoutSeconds 30) {
        Write-Log "✓ CORTEX started successfully" "SUCCESS"
    } else {
        Write-Log "✗ CORTEX failed to start" "ERROR"
        Write-Log "Check logs at: $cortexPath\logs\cortex.log" "ERROR"
        exit 1
    }
}

# ----------------------------------------
# 3. START NEURO-TERMINAL (Optional)
# ----------------------------------------

if (-not $SkipNeuroTerminal) {
    Write-Log "" "INFO"
    Write-Log "Step 3: Starting Neuro-Terminal UI..." "INFO"
    
    if (Test-Port -Port 8501) {
        Write-Log "⚠ Neuro-Terminal already running on port 8501" "WARNING"
    } else {
        $neuroPath = Join-Path $ProjectRoot "services\neuro_terminal"
        
        if (-not (Test-Path $neuroPath)) {
            Write-Log "⚠ Neuro-Terminal directory not found: $neuroPath" "WARNING"
            Write-Log "Skipping Neuro-Terminal startup" "WARNING"
        } else {
            $neuroCmd = @"
cd '$neuroPath'
.\.venv\Scripts\Activate.ps1
chainlit run app.py --port 8501
"@
            
            Start-Process powershell -ArgumentList "-NoExit", "-Command", $neuroCmd -WindowStyle Normal
            
            if (Wait-ForService -Name "Neuro-Terminal" -Port 8501 -HealthEndpoint "http://localhost:8501" -TimeoutSeconds 120 -IsChainlit) {
                Write-Log "✓ Neuro-Terminal started successfully" "SUCCESS"
            } else {
                Write-Log "⚠ Neuro-Terminal failed to start within 120s (non-critical, continuing...)" "WARNING"
                Write-Log "  Service may still be starting in background - check http://localhost:8501 in browser" "WARNING"
                Write-Log "  You can verify status later with CHECK_STATUS.ps1" "WARNING"
            }
        }
    }
} else {
    Write-Log "" "INFO"
    Write-Log "Step 3: Skipping Neuro-Terminal (SkipNeuroTerminal flag set)" "INFO"
}

# ----------------------------------------
# FINAL STATUS
# ----------------------------------------

Write-Log "" "INFO"
Write-Log "========================================" "SUCCESS"
Write-Log "✓ ALL SERVICES STARTED" "SUCCESS"
Write-Log "========================================" "SUCCESS"
Write-Log "" "INFO"
Write-Log "Service Endpoints:" "INFO"
Write-Log "  Ollama:         http://localhost:11434" "INFO"
Write-Log "  CORTEX:         http://localhost:8004" "INFO"

if (-not $SkipNeuroTerminal -and (Test-Port -Port 8501)) {
    Write-Log "  Neuro-Terminal: http://localhost:8501" "INFO"
}

Write-Log "" "INFO"
Write-Log "Logs: $Global:LogFile" "INFO"
Write-Log "" "INFO"
Write-Log "To stop all services, run: pwsh STOP_ALL.ps1" "INFO"
Write-Log "========================================" "INFO"
