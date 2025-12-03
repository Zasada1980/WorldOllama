# Quick Install Script
# One-command installation for all three mechanisms

param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$SkipGitHook,
    [switch]$SkipScheduledTask,
    [switch]$SkipWatcher,
    [string]$ExecutionTime = "03:00"
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== VS Code Indexation Tools - Quick Install ===" -ForegroundColor Cyan
Write-Host "Version: 2.0" -ForegroundColor Gray
Write-Host "Project Root: $ProjectRoot`n" -ForegroundColor Gray

$scriptsDir = Join-Path $ProjectRoot "scripts"

# Check prerequisites
Write-Host "[Prerequisites Check]" -ForegroundColor Yellow

# PowerShell version
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -ge 7) {
    Write-Host "  ✅ PowerShell $($psVersion.Major).$($psVersion.Minor)" -ForegroundColor Green
} else {
    Write-Host "  ❌ PowerShell 7+ required (current: $($psVersion.Major).$($psVersion.Minor))" -ForegroundColor Red
    throw "PowerShell 7+ required"
}

# Git
try {
    $gitVersion = git --version
    Write-Host "  ✅ Git installed" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️ Git not found (post-commit hook will be skipped)" -ForegroundColor Yellow
    $SkipGitHook = $true
}

# Admin rights (for scheduled task)
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Host "  ✅ Running as Administrator" -ForegroundColor Green
} else {
    Write-Host "  ⚠️ Not running as Administrator (scheduled task will be skipped)" -ForegroundColor Yellow
    $SkipScheduledTask = $true
}

Write-Host ""

# Install Git Hook
if (-not $SkipGitHook) {
    Write-Host "[1/3] Installing Git post-commit hook..." -ForegroundColor Magenta
    $installHookScript = Join-Path $scriptsDir "INSTALL_GIT_HOOK.ps1"
    
    if (Test-Path $installHookScript) {
        try {
            & $installHookScript -ProjectRoot $ProjectRoot -Backup
            Write-Host "  ✅ Git hook installed" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ Git hook installation failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  ❌ INSTALL_GIT_HOOK.ps1 not found" -ForegroundColor Red
    }
} else {
    Write-Host "[1/3] Skipping Git hook installation" -ForegroundColor Gray
}

Write-Host ""

# Install Scheduled Task
if (-not $SkipScheduledTask) {
    Write-Host "[2/3] Creating Windows Scheduled Task..." -ForegroundColor Magenta
    $createTaskScript = Join-Path $scriptsDir "CREATE_SCHEDULED_TASK.ps1"
    
    if (Test-Path $createTaskScript) {
        try {
            & $createTaskScript -ProjectRoot $ProjectRoot -ExecutionTime $ExecutionTime
            Write-Host "  ✅ Scheduled task created (daily at $ExecutionTime)" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ Scheduled task creation failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  ❌ CREATE_SCHEDULED_TASK.ps1 not found" -ForegroundColor Red
    }
} else {
    Write-Host "[2/3] Skipping scheduled task creation" -ForegroundColor Gray
}

Write-Host ""

# Start FileSystemWatcher (optional)
if (-not $SkipWatcher) {
    Write-Host "[3/3] FileSystemWatcher setup..." -ForegroundColor Magenta
    $watchScript = Join-Path $scriptsDir "WATCH_FILE_CHANGES.ps1"
    
    if (Test-Path $watchScript) {
        $startWatcher = Read-Host "  Start FileSystemWatcher now? (y/N)"
        
        if ($startWatcher -eq 'y') {
            Write-Host "  Starting FileSystemWatcher (background process)..." -ForegroundColor Gray
            Start-Process pwsh -ArgumentList "-File", $watchScript, "-WatchPath", $ProjectRoot -WindowStyle Hidden
            Start-Sleep -Seconds 2
            
            $watcherProcess = Get-Process pwsh | Where-Object { $_.CommandLine -like "*WATCH_FILE_CHANGES*" }
            if ($watcherProcess) {
                Write-Host "  ✅ FileSystemWatcher started (PID: $($watcherProcess.Id))" -ForegroundColor Green
                Write-Host "     To stop: Stop-Process -Id $($watcherProcess.Id) -Force" -ForegroundColor Gray
            } else {
                Write-Host "  ❌ FileSystemWatcher failed to start" -ForegroundColor Red
            }
        } else {
            Write-Host "  ⏭️  Skipped (you can start it later with: pwsh scripts\WATCH_FILE_CHANGES.ps1)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ❌ WATCH_FILE_CHANGES.ps1 not found" -ForegroundColor Red
    }
} else {
    Write-Host "[3/3] Skipping FileSystemWatcher" -ForegroundColor Gray
}

Write-Host ""

# Run initial reindex
Write-Host "[Initial Reindex]" -ForegroundColor Yellow
$reindexNow = Read-Host "  Run full reindex now? (Y/n)"

if ($reindexNow -ne 'n') {
    $updateScript = Join-Path $scriptsDir "UPDATE_PROJECT_INDEX.ps1"
    if (Test-Path $updateScript) {
        Write-Host "  Running full reindex..." -ForegroundColor Gray
        & $updateScript -FullReindex -ProjectRoot $ProjectRoot
        Write-Host "  ✅ Initial reindex complete" -ForegroundColor Green
    } else {
        Write-Host "  ❌ UPDATE_PROJECT_INDEX.ps1 not found" -ForegroundColor Red
    }
} else {
    Write-Host "  ⏭️  Skipped" -ForegroundColor Gray
}

Write-Host ""

# Summary
Write-Host "=== Installation Summary ===" -ForegroundColor Cyan

$summary = @()
if (-not $SkipGitHook -and (Test-Path (Join-Path $ProjectRoot ".git" "hooks" "post-commit"))) {
    $summary += "  ✅ Git Hook: Active (triggers on commits)"
} else {
    $summary += "  ⏭️  Git Hook: Skipped"
}

if (-not $SkipScheduledTask -and (Get-ScheduledTask -TaskName "VSCode_Daily_Reindex" -ErrorAction SilentlyContinue)) {
    $summary += "  ✅ Scheduled Task: Active (daily at $ExecutionTime)"
} else {
    $summary += "  ⏭️  Scheduled Task: Skipped"
}

$watcherProcess = Get-Process pwsh -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*WATCH_FILE_CHANGES*" }
if ($watcherProcess) {
    $summary += "  ✅ FileSystemWatcher: Running (PID: $($watcherProcess.Id))"
} else {
    $summary += "  ⏭️  FileSystemWatcher: Not running"
}

$summary | ForEach-Object { Write-Host $_ }

Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
Write-Host "  1. Check index file: docs\project\INDEX.md" -ForegroundColor Gray
Write-Host "  2. Review logs: logs\*.log" -ForegroundColor Gray
Write-Host "  3. Customize config (optional): .vscode-indexation.json" -ForegroundColor Gray
Write-Host "`n  📖 Full documentation: README.md" -ForegroundColor Gray
Write-Host "  🛠️  Troubleshooting: TROUBLESHOOTING.md" -ForegroundColor Gray
Write-Host "  ⚙️  Configuration: CONFIGURATION.md`n" -ForegroundColor Gray

Write-Host "✅ Installation complete!" -ForegroundColor Green

exit 0
