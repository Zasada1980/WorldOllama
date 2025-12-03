<#
.SYNOPSIS
    Universal Windows Scheduled Task creator for VS Code indexing

.DESCRIPTION
    Registers a Windows Task Scheduler task for daily automatic reindexing
    Supports custom execution time, task name, and project paths

.PARAMETER TaskName
    Task name (default: VSCode_Daily_Reindex)

.PARAMETER ExecutionTime
    Execution time HH:MM format (default: 03:00)

.PARAMETER ProjectRoot
    Project root directory (default: script directory parent)

.PARAMETER RemoveTask
    Remove existing task instead of creating

.EXAMPLE
    .\CREATE_SCHEDULED_TASK.ps1
    Create task with defaults

.EXAMPLE
    .\CREATE_SCHEDULED_TASK.ps1 -ExecutionTime "02:30"
    Create task at 02:30

.EXAMPLE
    .\CREATE_SCHEDULED_TASK.ps1 -RemoveTask
    Remove existing task

.EXAMPLE
    .\CREATE_SCHEDULED_TASK.ps1 -TaskName "MyProject_Reindex" -ProjectRoot "C:\MyProject"
    Custom task name and project path

.NOTES
    Version: 2.0
    Author: GitHub Copilot Agent
    Date: December 3, 2025
    License: MIT
    Requirements: Administrator rights
#>

param(
    [string]$TaskName = "VSCode_Daily_Reindex",
    [string]$ExecutionTime = "03:00",
    [string]$ProjectRoot = "",
    [switch]$RemoveTask
)

# Check administrator privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "`n❌ ERROR: Administrator privileges required`n" -ForegroundColor Red
    Write-Host "Run PowerShell as Administrator:" -ForegroundColor Yellow
    Write-Host "  1. Right-click PowerShell" -ForegroundColor Gray
    Write-Host "  2. Select 'Run as administrator'" -ForegroundColor Gray
    Write-Host "  3. Retry the command`n" -ForegroundColor Gray
    exit 1
}

# Auto-detect project root if not specified
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}

$ScriptPath = Join-Path $ProjectRoot "scripts\UPDATE_PROJECT_INDEX.ps1"
$LogPath = Join-Path $ProjectRoot "logs\scheduled_reindex.log"

# REMOVE TASK
if ($RemoveTask) {
    Write-Host "`n🗑️  REMOVING SCHEDULED TASK`n" -ForegroundColor Cyan
    
    try {
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        
        if ($existingTask) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Write-Host "✅ Task '$TaskName' removed successfully`n" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Task '$TaskName' not found`n" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "❌ ERROR removing task: $($_.Exception.Message)`n" -ForegroundColor Red
        exit 1
    }
    
    exit 0
}

# CREATE TASK
Write-Host "`n📅 CREATING WINDOWS SCHEDULED TASK`n" -ForegroundColor Cyan

# Check script exists
if (-not (Test-Path $ScriptPath)) {
    Write-Host "❌ ERROR: Script not found: $ScriptPath`n" -ForegroundColor Red
    Write-Host "Please ensure UPDATE_PROJECT_INDEX.ps1 exists in scripts/ directory`n" -ForegroundColor Yellow
    exit 1
}

Write-Host "Task parameters:" -ForegroundColor White
Write-Host "  Name: $TaskName" -ForegroundColor Gray
Write-Host "  Schedule: Daily at $ExecutionTime" -ForegroundColor Gray
Write-Host "  Project root: $ProjectRoot" -ForegroundColor Gray
Write-Host "  Script: $ScriptPath" -ForegroundColor Gray
Write-Host "  Log: $LogPath`n" -ForegroundColor Gray

try {
    # Remove existing task if present
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "⚠️  Existing task '$TaskName' found, removing..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }
    
    # Parse execution time
    $timeParts = $ExecutionTime.Split(':')
    if ($timeParts.Count -ne 2) {
        throw "Invalid time format. Use HH:MM (e.g., 03:00)"
    }
    
    # Create action (PowerShell script execution)
    $pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
    if (-not $pwshPath) {
        # Fallback to Windows PowerShell
        $pwshPath = "powershell.exe"
    }
    
    $actionArgs = "-NoProfile -WindowStyle Hidden -File `"$ScriptPath`" -FullReindex -ProjectRoot `"$ProjectRoot`" > `"$LogPath`" 2>&1"
    $action = New-ScheduledTaskAction -Execute $pwshPath -Argument $actionArgs
    
    # Create trigger (daily at specified time)
    $trigger = New-ScheduledTaskTrigger -Daily -At $ExecutionTime
    
    # Create settings
    $settings = New-ScheduledTaskSettingsSet `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable:$false `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 10) `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1)
    
    # Create principal (run as SYSTEM for reliability)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Register task
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description "Automatic documentation index update for VS Code project (created by VS Code Indexation Tools v2.0)" |
        Out-Null
    
    Write-Host "✅ TASK CREATED SUCCESSFULLY`n" -ForegroundColor Green
    
    # Display task info
    $taskInfo = Get-ScheduledTask -TaskName $TaskName
    $taskStatus = Get-ScheduledTaskInfo -TaskName $TaskName
    
    Write-Host "Task details:" -ForegroundColor Cyan
    Write-Host "  State: $($taskInfo.State)" -ForegroundColor White
    Write-Host "  Next run: $($taskStatus.NextRunTime)" -ForegroundColor White
    Write-Host "  Last run: $($taskStatus.LastRunTime)" -ForegroundColor Gray
    Write-Host "  Last result: $($taskStatus.LastTaskResult)" -ForegroundColor Gray
    
    # Manual test option
    Write-Host "`nManual test (optional):" -ForegroundColor Cyan
    Write-Host "  Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
    Write-Host "  Get-Content '$LogPath' -Tail 20`n" -ForegroundColor Gray
}
catch {
    Write-Host "❌ ERROR creating task: $($_.Exception.Message)`n" -ForegroundColor Red
    exit 1
}

exit 0
