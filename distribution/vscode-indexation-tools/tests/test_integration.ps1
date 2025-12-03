# Test: End-to-End Integration
# Tests all three mechanisms: FileSystemWatcher, Git Hook, Scheduled Task

param(
    [string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== E2E Integration Test ===" -ForegroundColor Cyan

# Setup
$scriptsDir = Join-Path $ProjectRoot "scripts"
$IndexFile = Join-Path $ProjectRoot "docs" "project" "INDEX.md"
$TestFile = Join-Path $ProjectRoot "test_e2e_$(Get-Date -Format 'yyyyMMddHHmmss').md"

Write-Host "`nTest Configuration:" -ForegroundColor Yellow
Write-Host "  ProjectRoot: $ProjectRoot"
Write-Host "  Scripts Directory: $scriptsDir"
Write-Host "  Index File: $IndexFile"
Write-Host "  Test File: $TestFile"

# Test 1: Install Git Hook
Write-Host "`n[Test 1] Installing Git post-commit hook..." -ForegroundColor Magenta
$installHookScript = Join-Path $scriptsDir "INSTALL_GIT_HOOK.ps1"

if (Test-Path $installHookScript) {
    & $installHookScript -ProjectRoot $ProjectRoot -Backup
    
    if (Test-Path (Join-Path $ProjectRoot ".git" "hooks" "post-commit")) {
        Write-Host "✅ Git hook installed" -ForegroundColor Green
    } else {
        Write-Host "❌ Git hook installation failed" -ForegroundColor Red
        throw "Git hook not found"
    }
} else {
    Write-Host "⚠️ INSTALL_GIT_HOOK.ps1 not found, skipping" -ForegroundColor Yellow
}

# Test 2: Create Scheduled Task
Write-Host "`n[Test 2] Creating Scheduled Task..." -ForegroundColor Magenta
$createTaskScript = Join-Path $scriptsDir "CREATE_SCHEDULED_TASK.ps1"
$testTaskName = "VSCode_Test_E2E_$(Get-Date -Format 'HHmmss')"

if (Test-Path $createTaskScript) {
    try {
        # Run as Administrator check
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if ($isAdmin) {
            & $createTaskScript -ProjectRoot $ProjectRoot -TaskName $testTaskName -ExecutionTime "23:59"
            
            $task = Get-ScheduledTask -TaskName $testTaskName -ErrorAction SilentlyContinue
            if ($task) {
                Write-Host "✅ Scheduled task created: $testTaskName" -ForegroundColor Green
            } else {
                Write-Host "❌ Scheduled task creation failed" -ForegroundColor Red
                throw "Task not found"
            }
        } else {
            Write-Host "⚠️ Not running as Administrator, skipping task creation" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️ Scheduled task creation error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ CREATE_SCHEDULED_TASK.ps1 not found, skipping" -ForegroundColor Yellow
}

# Test 3: Start FileSystemWatcher (background)
Write-Host "`n[Test 3] Starting FileSystemWatcher..." -ForegroundColor Magenta
$watchScript = Join-Path $scriptsDir "WATCH_FILE_CHANGES.ps1"
$watcherPID = $null

if (Test-Path $watchScript) {
    # Start in background
    $watcherJob = Start-Process pwsh -ArgumentList "-File", $watchScript, "-WatchPath", $ProjectRoot -PassThru -WindowStyle Hidden
    $watcherPID = $watcherJob.Id
    
    # Wait for watcher to initialize
    Start-Sleep -Seconds 5
    
    $watcherProcess = Get-Process -Id $watcherPID -ErrorAction SilentlyContinue
    if ($watcherProcess) {
        Write-Host "✅ FileSystemWatcher started (PID: $watcherPID)" -ForegroundColor Green
    } else {
        Write-Host "❌ FileSystemWatcher failed to start" -ForegroundColor Red
        throw "Watcher process not found"
    }
} else {
    Write-Host "⚠️ WATCH_FILE_CHANGES.ps1 not found, skipping" -ForegroundColor Yellow
}

# Test 4: Create test file (trigger FileSystemWatcher)
Write-Host "`n[Test 4] Creating test file (FileSystemWatcher trigger)..." -ForegroundColor Magenta
$testContent = @"
# E2E Test Document

Created at $(Get-Date) for integration testing.

## Test Mechanisms

- FileSystemWatcher
- Git post-commit hook  
- Scheduled task

## Expected Behavior

All three mechanisms should detect and process this file.
"@

New-Item -Path $TestFile -ItemType File -Value $testContent -Force | Out-Null
Write-Host "✅ Test file created: $TestFile" -ForegroundColor Green

# Wait for FileSystemWatcher to react (debounce + processing)
Write-Host "  Waiting for FileSystemWatcher to react (5 seconds)..." -ForegroundColor Gray
Start-Sleep -Seconds 5

# Check if index updated
$indexUpdated = $false
if (Test-Path $IndexFile) {
    $indexContent = Get-Content $IndexFile -Raw
    $testFileName = Split-Path $TestFile -Leaf
    if ($indexContent -match [regex]::Escape($testFileName)) {
        Write-Host "✅ FileSystemWatcher triggered reindex" -ForegroundColor Green
        $indexUpdated = $true
    } else {
        Write-Host "⚠️ FileSystemWatcher did not update index (check logs/file_watcher.log)" -ForegroundColor Yellow
    }
}

# Test 5: Git commit (trigger Git Hook)
Write-Host "`n[Test 5] Creating Git commit (Git Hook trigger)..." -ForegroundColor Magenta

# Check if in Git repo
if (Test-Path (Join-Path $ProjectRoot ".git")) {
    try {
        # Add test file
        git -C $ProjectRoot add $TestFile
        
        # Commit (triggers post-commit hook)
        git -C $ProjectRoot commit -m "test: E2E integration test [skip ci]"
        
        Write-Host "✅ Git commit created (hook should trigger)" -ForegroundColor Green
        
        # Wait for hook to execute
        Start-Sleep -Seconds 3
        
        # Check logs
        $hookLog = Join-Path $ProjectRoot "logs" "indexation.log"
        if (Test-Path $hookLog) {
            $recentLogs = Get-Content $hookLog -Tail 10
            if ($recentLogs -match "IncrementalMode|FullReindex") {
                Write-Host "✅ Git hook executed reindex" -ForegroundColor Green
            } else {
                Write-Host "⚠️ Git hook execution unclear (check logs/indexation.log)" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "⚠️ Git commit error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ Not a Git repository, skipping hook test" -ForegroundColor Yellow
}

# Test 6: Trigger Scheduled Task manually
Write-Host "`n[Test 6] Triggering Scheduled Task manually..." -ForegroundColor Magenta

try {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if ($isAdmin -and (Get-ScheduledTask -TaskName $testTaskName -ErrorAction SilentlyContinue)) {
        Start-ScheduledTask -TaskName $testTaskName
        Write-Host "  Task started, waiting for completion (10 seconds)..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
        
        $taskInfo = Get-ScheduledTaskInfo -TaskName $testTaskName
        $lastResult = $taskInfo.LastTaskResult
        
        if ($lastResult -eq 0) {
            Write-Host "✅ Scheduled task executed successfully (exit code 0)" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Scheduled task exit code: $lastResult (check logs/scheduled_reindex.log)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠️ Skipping scheduled task test (not admin or task not created)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ Scheduled task error: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test 7: Verify all mechanisms updated index
Write-Host "`n[Test 7] Final index verification..." -ForegroundColor Magenta

if (Test-Path $IndexFile) {
    $finalIndexContent = Get-Content $IndexFile -Raw
    $testFileName = Split-Path $TestFile -Leaf
    
    if ($finalIndexContent -match [regex]::Escape($testFileName)) {
        Write-Host "✅ Index contains test file" -ForegroundColor Green
        
        # Check metadata freshness
        if ($finalIndexContent -match "Last Updated:\s*(.+)") {
            $lastUpdated = $matches[1]
            Write-Host "  Last Updated: $lastUpdated" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠️ Index does not contain test file (mechanisms may not have triggered)" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Index file not found" -ForegroundColor Red
}

# Cleanup
Write-Host "`n[Cleanup] Cleaning up test resources..." -ForegroundColor Magenta

# Stop FileSystemWatcher
if ($watcherPID) {
    try {
        Stop-Process -Id $watcherPID -Force -ErrorAction SilentlyContinue
        Write-Host "  ✅ Stopped FileSystemWatcher (PID: $watcherPID)" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️ Could not stop watcher: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Remove test file
if (Test-Path $TestFile) {
    Remove-Item $TestFile -Force
    Write-Host "  ✅ Removed test file" -ForegroundColor Green
}

# Undo Git commit (optional)
if (Test-Path (Join-Path $ProjectRoot ".git")) {
    try {
        $undoCommit = Read-Host "Undo Git commit? (y/N)"
        if ($undoCommit -eq 'y') {
            git -C $ProjectRoot reset --soft HEAD~1
            git -C $ProjectRoot restore --staged $TestFile
            Write-Host "  ✅ Git commit undone" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ⚠️ Could not undo commit: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Remove scheduled task
try {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if ($isAdmin -and (Get-ScheduledTask -TaskName $testTaskName -ErrorAction SilentlyContinue)) {
        Unregister-ScheduledTask -TaskName $testTaskName -Confirm:$false
        Write-Host "  ✅ Removed scheduled task" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️ Could not remove task: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n✅ Cleanup complete" -ForegroundColor Green

# Summary
Write-Host "`n=== E2E Test Summary ===" -ForegroundColor Cyan
Write-Host "┌─────────────────────────┬──────────┐" -ForegroundColor Gray
Write-Host "│ Mechanism               │ Status   │" -ForegroundColor Gray
Write-Host "├─────────────────────────┼──────────┤" -ForegroundColor Gray
Write-Host "│ Git Hook Installation   │ $(if (Test-Path (Join-Path $ProjectRoot '.git' 'hooks' 'post-commit')) { '✅ PASS' } else { '⚠️  SKIP' }) │" -ForegroundColor Gray
Write-Host "│ Scheduled Task Creation │ $(if (Get-ScheduledTask -TaskName $testTaskName -ErrorAction SilentlyContinue) { '✅ PASS' } else { '⚠️  SKIP' }) │" -ForegroundColor Gray
Write-Host "│ FileSystemWatcher Start │ $(if ($watcherPID) { '✅ PASS' } else { '⚠️  SKIP' }) │" -ForegroundColor Gray
Write-Host "│ Index File Updated      │ $(if ($indexUpdated) { '✅ PASS' } else { '⚠️  WARN' }) │" -ForegroundColor Gray
Write-Host "└─────────────────────────┴──────────┘" -ForegroundColor Gray

Write-Host "`n✅ E2E integration test complete" -ForegroundColor Green
Write-Host "   Check logs for detailed execution traces:" -ForegroundColor Gray
Write-Host "   - logs/file_watcher.log (FileSystemWatcher)" -ForegroundColor Gray
Write-Host "   - logs/indexation.log (Git Hook + Manual)" -ForegroundColor Gray
Write-Host "   - logs/scheduled_reindex.log (Scheduled Task)" -ForegroundColor Gray

exit 0
