param(
    [ValidateSet("Dev", "Release")]
    [string]$Mode = "Dev"
)

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = if ($env:WORLD_OLLAMA_ROOT) { $env:WORLD_OLLAMA_ROOT } else { $ScriptRoot }

Write-Host "WORLD_OLLAMA LAUNCHER" -ForegroundColor Cyan
Write-Host "Project root: $ProjectRoot"
Write-Host "Mode: $Mode"

function Test-Command($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        Write-Warning "Command '$name' not found in PATH. Some features may not work."
        return $false
    }
    return $true
}

$hasNode = Test-Command "node"
$hasNpm = Test-Command "npm"
$hasGit = Test-Command "git"
$hasPwsh = $PSVersionTable.PSEdition -eq "Core"

# Step 1: Start Services
$ScriptsDir = Join-Path $ProjectRoot "scripts"
$StartAll = Join-Path $ScriptsDir "START_ALL.ps1"

if (-not (Test-Path $StartAll)) {
    Write-Error "START_ALL.ps1 not found at $StartAll"
    exit 1
}

Write-Host "Starting backend services via START_ALL.ps1..." -ForegroundColor Yellow
# Отдельное окно, чтобы лог сервисов был виден
Start-Process pwsh -ArgumentList "-NoExit", "-File `"$StartAll`"", "-ProjectRoot `"$ProjectRoot`""

# Step 2: Start Desktop UI (Dev)
$ClientDir = Join-Path $ProjectRoot "client"

if (-not (Test-Path $ClientDir)) {
    Write-Error "client directory not found at $ClientDir"
    exit 1
}

Write-Host "Starting Tauri Dev Client (npm run tauri dev)..." -ForegroundColor Yellow
Start-Process pwsh -WorkingDirectory $ClientDir -ArgumentList "-NoExit", "-Command npm install; npm run tauri dev"

# Step 3: Final Message
Write-Host ""
Write-Host "============================================" -ForegroundColor DarkCyan
Write-Host " WORLD_OLLAMA is launching..." -ForegroundColor Green
Write-Host " 1) Backend services -> in separate PowerShell window" -ForegroundColor Gray
Write-Host " 2) Desktop UI       -> in separate PowerShell window (Tauri Dev)" -ForegroundColor Gray
Write-Host "--------------------------------------------" -ForegroundColor DarkCyan
Write-Host " When UI is up, open:" -ForegroundColor Yellow
Write-Host "  - Workflow tab: visual pipeline" -ForegroundColor Yellow
Write-Host "  - Training: PULSE v1" -ForegroundColor Yellow
Write-Host "  - Git: Safe Git Assistant" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor DarkCyan
