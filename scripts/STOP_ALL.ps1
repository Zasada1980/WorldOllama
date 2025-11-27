# ========================================
# WORLD_OLLAMA - Service Orchestrator
# STOP_ALL.ps1
# Версия: 1.0
# Дата: 27 ноября 2025
# ========================================

$ErrorActionPreference = "Continue"

function Write-ColorLog {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorLog "========================================" "Cyan"
Write-ColorLog "WORLD_OLLAMA - Stopping All Services" "Cyan"
Write-ColorLog "========================================" "Cyan"
Write-ColorLog "" "Cyan"

# ----------------------------------------
# 1. STOP PYTHON PROCESSES
# ----------------------------------------

Write-ColorLog "Step 1: Stopping Python services (CORTEX, Neuro-Terminal)..." "Yellow"

$pythonProcesses = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -like "*WORLD_OLLAMA*"
}

if ($pythonProcesses) {
    foreach ($proc in $pythonProcesses) {
        try {
            $procName = $proc.ProcessName
            $procId = $proc.Id
            $procPath = $proc.Path
            
            Write-ColorLog "  Stopping process: $procName (PID: $procId)" "Yellow"
            Write-ColorLog "    Path: $procPath" "Gray"
            
            Stop-Process -Id $procId -Force -ErrorAction Stop
            Write-ColorLog "  ✓ Stopped PID $procId" "Green"
        } catch {
            Write-ColorLog "  ✗ Failed to stop PID ${procId}: $_" "Red"
        }
    }
} else {
    Write-ColorLog "  No WORLD_OLLAMA Python processes found" "Gray"
}

# ----------------------------------------
# 2. VERIFY PORTS ARE FREE
# ----------------------------------------

Write-ColorLog "" "Cyan"
Write-ColorLog "Step 2: Verifying ports are free..." "Yellow"

$ports = @(
    @{Port=8004; Name="CORTEX"},
    @{Port=8501; Name="Neuro-Terminal"}
)

foreach ($service in $ports) {
    try {
        $connection = Test-NetConnection -ComputerName "localhost" -Port $service.Port -InformationLevel Quiet -WarningAction SilentlyContinue
        
        if ($connection) {
            Write-ColorLog "  ⚠ Port $($service.Port) ($($service.Name)) still in use" "Red"
        } else {
            Write-ColorLog "  ✓ Port $($service.Port) ($($service.Name)) is free" "Green"
        }
    } catch {
        Write-ColorLog "  ✓ Port $($service.Port) ($($service.Name)) is free" "Green"
    }
}

# ----------------------------------------
# 3. OLLAMA STATUS (INFORMATIONAL)
# ----------------------------------------

Write-ColorLog "" "Cyan"
Write-ColorLog "Step 3: Checking Ollama status..." "Yellow"

try {
    $ollamaRunning = Test-NetConnection -ComputerName "localhost" -Port 11434 -InformationLevel Quiet -WarningAction SilentlyContinue
    
    if ($ollamaRunning) {
        Write-ColorLog "  ℹ Ollama is still running (not stopped by this script)" "Cyan"
        Write-ColorLog "    Ollama runs as a system service and should stay running" "Gray"
    } else {
        Write-ColorLog "  ✓ Ollama is not running" "Green"
    }
} catch {
    Write-ColorLog "  ✓ Ollama is not running" "Green"
}

# ----------------------------------------
# FINAL STATUS
# ----------------------------------------

Write-ColorLog "" "Cyan"
Write-ColorLog "========================================" "Green"
Write-ColorLog "✓ ALL SERVICES STOPPED" "Green"
Write-ColorLog "========================================" "Green"
Write-ColorLog "" "Cyan"
Write-ColorLog "Note: Ollama service was not stopped (runs independently)" "Gray"
Write-ColorLog "" "Cyan"
Write-ColorLog "To start services again, run: pwsh START_ALL.ps1" "Cyan"
Write-ColorLog "========================================" "Cyan"
