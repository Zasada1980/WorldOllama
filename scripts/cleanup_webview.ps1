<#
.SYNOPSIS
    PowerShell cleanup script for WebView2 zombie processes (Phase 2B fallback)

.DESCRIPTION
    Kills orphaned msedgewebview2.exe processes that don't have a parent Tauri process.
    This is a FALLBACK mechanism for cases where Job Objects don't work:
    - Force termination (Stop-Process -Force, taskkill /F)
    - System crashes / BSOD
    - Elevated mode restrictions
    - Job Objects disabled by enterprise policy

.NOTES
    Author: WORLD_OLLAMA Team
    Date: 04.12.2025
    Version: 1.0
    Phase: 2B (Core Stability)
    Related: Phase 2A (Job Objects - primary mechanism)

.PARAMETER Aggressive
    Kill ALL msedgewebview2.exe processes (even with running parents)

.PARAMETER DryRun
    Show what would be killed without actually killing

.EXAMPLE
    .\cleanup_webview.ps1
    # Kills only zombie processes (no parent)

.EXAMPLE
    .\cleanup_webview.ps1 -Aggressive
    # Kills ALL WebView2 processes

.EXAMPLE
    .\cleanup_webview.ps1 -DryRun
    # Shows what would be killed
#>

param(
    [switch]$Aggressive,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# ANSI Colors
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$CYAN = "`e[36m"
$RESET = "`e[0m"

function Write-ColorLog {
    param(
        [string]$Message,
        [string]$Color = $RESET
    )
    Write-Host "${Color}${Message}${RESET}"
}

function Get-ProcessParent {
    param([int]$ProcessId)
    
    try {
        $proc = Get-CimInstance Win32_Process -Filter "ProcessId = $ProcessId" -ErrorAction SilentlyContinue
        return $proc.ParentProcessId
    } catch {
        return $null
    }
}

function Test-ParentExists {
    param([int]$ParentId)
    
    if ($null -eq $ParentId -or $ParentId -eq 0) {
        return $false
    }
    
    try {
        $parent = Get-Process -Id $ParentId -ErrorAction SilentlyContinue
        return $null -ne $parent
    } catch {
        return $false
    }
}

# Main logic
Write-ColorLog "`n=== WebView2 Zombie Cleanup (Phase 2B) ===" $CYAN

# Get all WebView2 processes
$webview2Procs = Get-Process -Name msedgewebview2 -ErrorAction SilentlyContinue

if ($null -eq $webview2Procs -or $webview2Procs.Count -eq 0) {
    Write-ColorLog "✅ No WebView2 processes found. System is clean." $GREEN
    exit 0
}

Write-ColorLog "Found $($webview2Procs.Count) WebView2 process(es)" $YELLOW

# Check for running Tauri processes
$tauriProcs = Get-Process -Name tauri_fresh -ErrorAction SilentlyContinue

if ($tauriProcs) {
    Write-ColorLog "⚠️  WARNING: Tauri is currently running (PID: $($tauriProcs.Id))" $YELLOW
    
    if (-not $Aggressive) {
        Write-ColorLog "Skipping cleanup. Use -Aggressive to force kill all WebView2." $YELLOW
        Write-ColorLog "Current behavior: Only kill orphaned processes." $CYAN
    }
}

# Analyze each WebView2 process
$zombieList = @()
$validList = @()

foreach ($proc in $webview2Procs) {
    $parentId = Get-ProcessParent -ProcessId $proc.Id
    $parentExists = Test-ParentExists -ParentId $parentId
    
    $uptimeMin = [math]::Round(((Get-Date) - $proc.StartTime).TotalMinutes, 1)
    $memoryMB = [math]::Round($proc.WS / 1MB, 2)
    
    if (-not $parentExists) {
        # Zombie process (no parent)
        $zombieList += [PSCustomObject]@{
            PID = $proc.Id
            ParentPID = $parentId
            UptimeMin = $uptimeMin
            MemoryMB = $memoryMB
        }
    } else {
        # Valid process (has parent)
        $validList += [PSCustomObject]@{
            PID = $proc.Id
            ParentPID = $parentId
            UptimeMin = $uptimeMin
            MemoryMB = $memoryMB
        }
    }
}

# Report
Write-ColorLog "`nAnalysis:" $CYAN
Write-ColorLog "  Zombie processes (no parent): $($zombieList.Count)" $(if ($zombieList.Count -gt 0) { $RED } else { $GREEN })
Write-ColorLog "  Valid processes (has parent):  $($validList.Count)" $GREEN

if ($zombieList.Count -gt 0) {
    Write-ColorLog "`nZombie Processes:" $RED
    $zombieList | ForEach-Object {
        Write-ColorLog "  PID $($_.PID) | Parent: $($_.ParentPID) | Uptime: $($_.UptimeMin) min | Memory: $($_.MemoryMB) MB" $RED
    }
}

if ($validList.Count -gt 0 -and -not $Aggressive) {
    Write-ColorLog "`nValid Processes (will NOT be killed):" $GREEN
    $validList | ForEach-Object {
        Write-ColorLog "  PID $($_.PID) | Parent: $($_.ParentPID) | Uptime: $($_.UptimeMin) min | Memory: $($_.MemoryMB) MB" $GREEN
    }
}

# Kill logic
$toKill = if ($Aggressive) {
    Write-ColorLog "`n🔥 AGGRESSIVE MODE: Killing ALL WebView2 processes" $YELLOW
    $zombieList + $validList
} else {
    Write-ColorLog "`n🎯 SELECTIVE MODE: Killing only zombie processes" $CYAN
    $zombieList
}

if ($toKill.Count -eq 0) {
    Write-ColorLog "`n✅ Nothing to clean. System is healthy." $GREEN
    exit 0
}

if ($DryRun) {
    Write-ColorLog "`n[DRY RUN] Would kill $($toKill.Count) process(es):" $YELLOW
    $toKill | ForEach-Object {
        Write-ColorLog "  PID $($_.PID)" $YELLOW
    }
    Write-ColorLog "`nRe-run without -DryRun to actually kill." $CYAN
    exit 0
}

# KILL
Write-ColorLog "`nKilling $($toKill.Count) process(es)..." $YELLOW

$killed = 0
$failed = 0

foreach ($proc in $toKill) {
    try {
        Stop-Process -Id $proc.PID -Force -ErrorAction Stop
        Write-ColorLog "  ✓ Killed PID $($proc.PID)" $GREEN
        $killed++
    } catch {
        Write-ColorLog "  ✗ Failed to kill PID $($proc.PID): $_" $RED
        $failed++
    }
}

# Final report
Write-ColorLog "`n=== Cleanup Results ===" $CYAN
Write-ColorLog "Killed:  $killed" $(if ($killed -gt 0) { $GREEN } else { $YELLOW })
Write-ColorLog "Failed:  $failed" $(if ($failed -gt 0) { $RED } else { $GREEN })

# Verify
Start-Sleep -Seconds 1
$remaining = (Get-Process -Name msedgewebview2 -ErrorAction SilentlyContinue).Count

if ($remaining -eq 0) {
    Write-ColorLog "`n✅✅✅ SUCCESS: System is now clean (0 WebView2 processes)" $GREEN
    exit 0
} elseif ($remaining -lt ($webview2Procs.Count / 2)) {
    Write-ColorLog "`n⚠️  PARTIAL: $remaining process(es) still running" $YELLOW
    exit 1
} else {
    Write-ColorLog "`n❌ FAIL: Cleanup failed ($remaining processes remain)" $RED
    exit 2
}
