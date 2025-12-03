param(
    [ValidateSet("Dev", "Release")]
    [string]$Mode = "Release",
    [switch]$SkipNeuroTerminal = $false
)

$ErrorActionPreference = "Stop"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = if ($env:WORLD_OLLAMA_ROOT) { $env:WORLD_OLLAMA_ROOT } else { $ScriptRoot }

Write-Host ""
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   WORLD_OLLAMA LAUNCHER v2.0               ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "Project root: $ProjectRoot" -ForegroundColor Gray
Write-Host "Mode: $Mode" -ForegroundColor Gray
Write-Host ""

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Test-Command($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        Write-Warning "⚠ Command '$name' not found in PATH"
        return $false
    }
    return $true
}

function Test-ServicePort {
    param([int]$Port, [string]$Name)
    
    Write-Host "  Checking $Name (port $Port)..." -NoNewline
    $result = Test-NetConnection -ComputerName localhost -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
    
    if ($result) {
        Write-Host " ✅" -ForegroundColor Green
        return $true
    } else {
        Write-Host " ❌" -ForegroundColor Red
        return $false
    }
}

function Wait-ForServices {
    param([int]$TimeoutSeconds = 60)
    
    Write-Host ""
    Write-Host "⏳ Waiting for services to start (timeout: ${TimeoutSeconds}s)..." -ForegroundColor Yellow
    
    $elapsed = 0
    $services = @(
        @{Name="Ollama"; Port=11434},
        @{Name="CORTEX"; Port=8004}
    )
    
    while ($elapsed -lt $TimeoutSeconds) {
        $allUp = $true
        
        foreach ($svc in $services) {
            if (-not (Test-NetConnection -ComputerName localhost -Port $svc.Port -InformationLevel Quiet -WarningAction SilentlyContinue)) {
                $allUp = $false
                break
            }
        }
        
        if ($allUp) {
            Write-Host "✅ All services ready!" -ForegroundColor Green
            return $true
        }
        
        Start-Sleep -Seconds 2
        $elapsed += 2
        Write-Host "." -NoNewline -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "⚠ Services did not start within ${TimeoutSeconds}s" -ForegroundColor Yellow
    return $false
}

# ============================================================================
# VALIDATION
# ============================================================================

Write-Host "🔍 Validating environment..." -ForegroundColor Cyan

$hasNode = Test-Command "node"
$hasNpm = Test-Command "npm"
$hasOllama = Test-Command "ollama"
$hasPwsh = $PSVersionTable.PSEdition -eq "Core"

if (-not $hasPwsh) {
    Write-Error "❌ PowerShell Core required (you're using Windows PowerShell)"
    exit 1
}

# ============================================================================
# STEP 1: START BACKEND SERVICES
# ============================================================================

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
Write-Host "STEP 1: Starting Backend Services" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan

$ScriptsDir = Join-Path $ProjectRoot "scripts"
$StartAll = Join-Path $ScriptsDir "START_ALL.ps1"

if (-not (Test-Path $StartAll)) {
    Write-Error "❌ START_ALL.ps1 not found at $StartAll"
    exit 1
}

# Проверка текущего статуса
Write-Host ""
Write-Host "Checking current service status..." -ForegroundColor Yellow

$ollamaUp = Test-ServicePort -Port 11434 -Name "Ollama"
$cortexUp = Test-ServicePort -Port 8004 -Name "CORTEX"

if ($ollamaUp -and $cortexUp) {
    Write-Host ""
    Write-Host "✅ Services already running, skipping START_ALL.ps1" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "🚀 Launching START_ALL.ps1..." -ForegroundColor Yellow
    
    $startArgs = @("-NoExit", "-File", "`"$StartAll`"")
    if ($SkipNeuroTerminal) {
        $startArgs += "-SkipNeuroTerminal"
    }
    
    Start-Process pwsh -ArgumentList $startArgs -WindowStyle Normal
    
    # Ждём готовности сервисов
    if (-not (Wait-ForServices -TimeoutSeconds 90)) {
        Write-Warning "⚠ Services startup timeout. You may need to check logs."
        Write-Host "   Press Ctrl+C to abort, or any key to continue anyway..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# ============================================================================
# STEP 2: START DESKTOP CLIENT
# ============================================================================

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
Write-Host "STEP 2: Starting Desktop Client" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan

$ClientDir = Join-Path $ProjectRoot "client"

if (-not (Test-Path $ClientDir)) {
    Write-Error "❌ client directory not found at $ClientDir"
    exit 1
}

if ($Mode -eq "Dev") {
    Write-Host ""
    Write-Host "🔧 Dev Mode: Starting Tauri Dev Server..." -ForegroundColor Yellow
    Write-Host "   (This will take ~30-60s for first-time compilation)" -ForegroundColor Gray
    Write-Host ""
    
    if (-not $hasNode -or -not $hasNpm) {
        Write-Error "❌ Node.js/npm required for Dev mode"
        exit 1
    }
    
    Start-Process pwsh -WorkingDirectory $ClientDir -ArgumentList "-NoExit", "-Command", "npm install; npm run tauri dev" -WindowStyle Normal
    
} else {
    # Release Mode
    $ClientExe = Join-Path $ClientDir "src-tauri\target\release\tauri_fresh.exe"
    
    if (-not (Test-Path $ClientExe)) {
        Write-Warning "⚠ Release build not found at:"
        Write-Warning "  $ClientExe"
        Write-Host ""
        Write-Host "Building release version (this may take 5-10 minutes)..." -ForegroundColor Yellow
        
        Set-Location $ClientDir
        
        # Очистка старого build
        if (Test-Path "build") {
            Remove-Item "build" -Recurse -Force
            Write-Host "  ✓ Cleaned old build directory" -ForegroundColor Gray
        }
        
        # Установка зависимостей
        Write-Host "  ⏳ Installing npm dependencies..." -ForegroundColor Gray
        npm install --silent
        
        # Сборка фронтенда
        Write-Host "  ⏳ Building frontend (SvelteKit)..." -ForegroundColor Gray
        npm run build
        
        # Сборка Tauri
        Write-Host "  ⏳ Building Tauri app (Rust compilation)..." -ForegroundColor Gray
        npm run tauri build
        
        if (-not (Test-Path $ClientExe)) {
            Write-Error "❌ Build failed. Check output above."
            exit 1
        }
        
        Write-Host "  ✅ Build complete!" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "🚀 Launching Desktop Client (Release)..." -ForegroundColor Green
    Start-Process $ClientExe
}

# ============================================================================
# STEP 3: FINAL STATUS
# ============================================================================

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
Write-Host "✅ WORLD_OLLAMA Launch Complete!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "Service Endpoints:" -ForegroundColor Cyan
Write-Host "  • Ollama:         http://localhost:11434" -ForegroundColor Gray
Write-Host "  • CORTEX:         http://localhost:8004" -ForegroundColor Gray
if (-not $SkipNeuroTerminal) {
    Write-Host "  • Neuro-Terminal: http://localhost:8501" -ForegroundColor Gray
}
Write-Host ""
Write-Host "Desktop Client:" -ForegroundColor Cyan
if ($Mode -eq "Dev") {
    Write-Host "  • Dev Server:     http://localhost:1420" -ForegroundColor Gray
    Write-Host "  • Window will open automatically (~30s)" -ForegroundColor Gray
} else {
    Write-Host "  • Application window opened" -ForegroundColor Gray
}
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Wait for Desktop Client window to appear" -ForegroundColor Gray
Write-Host "  2. Open 'Workflow' tab to see system status" -ForegroundColor Gray
Write-Host "  3. Use 'Chat' tab to interact with AI" -ForegroundColor Gray
Write-Host "  4. Check 'Status' tab if services are down" -ForegroundColor Gray
Write-Host ""
Write-Host "Troubleshooting:" -ForegroundColor Yellow
Write-Host "  • Services not starting?  → Check logs in services PowerShell window" -ForegroundColor Gray
Write-Host "  • Client not opening?     → Run 'npm run tauri build' manually" -ForegroundColor Gray
Write-Host "  • Connection refused?     → Verify services with CHECK_STATUS.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "To stop everything:" -ForegroundColor Yellow
Write-Host "  pwsh scripts\STOP_ALL.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
Write-Host "Press any key to exit this launcher..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
