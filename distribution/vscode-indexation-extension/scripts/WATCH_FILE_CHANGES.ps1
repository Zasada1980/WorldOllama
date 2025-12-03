<#
.SYNOPSIS
    Universal FileSystemWatcher for VS Code project indexing

.DESCRIPTION
    Monitors file changes and triggers automatic index updates
    Implements debounce logic and path filtering

.PARAMETER WatchPath
    Path to monitor (default: script directory parent)

.PARAMETER WatchPatterns
    File patterns to monitor (default: *.md)

.PARAMETER ExcludePatterns
    Patterns to exclude (default: venv, node_modules, archive)

.PARAMETER DebounceMs
    Debounce delay in milliseconds (default: 2000)

.PARAMETER HeartbeatIntervalMin
    Heartbeat interval in minutes (default: 10)

.EXAMPLE
    .\WATCH_FILE_CHANGES.ps1
    Run with default parameters

.EXAMPLE
    .\WATCH_FILE_CHANGES.ps1 -WatchPath "C:\MyProject" -DebounceMs 5000
    Custom path and debounce

.EXAMPLE
    .\WATCH_FILE_CHANGES.ps1 -WatchPatterns "*.md","*.rst" -ExcludePatterns "venv","build"
    Custom patterns

.NOTES
    Version: 2.0
    Author: GitHub Copilot Agent
    Date: December 3, 2025
    License: MIT
    Dependencies: PowerShell 7+, .NET FileSystemWatcher API
#>

param(
    [string]$WatchPath = "",
    [string[]]$WatchPatterns = @("*.md"),
    [string[]]$ExcludePatterns = @("venv", "node_modules", "archive", ".git", "build", "dist", "__pycache__", "llamaboard_cache"),
    [int]$DebounceMs = 2000,
    [int]$HeartbeatIntervalMin = 10
)

$ErrorActionPreference = "Stop"

# Auto-detect watch path if not specified
if ([string]::IsNullOrWhiteSpace($WatchPath)) {
    $WatchPath = Split-Path -Parent $PSScriptRoot
    Write-Verbose "Auto-detected WatchPath: $WatchPath"
}

# Ensure logs directory exists
$LogsDir = Join-Path $WatchPath "logs"
if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
}

$LogFile = Join-Path $LogsDir "file_watcher.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
    
    switch ($Level) {
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default   { Write-Host $logEntry -ForegroundColor White }
    }
}

function Test-ShouldExclude {
    param([string]$Path)
    
    foreach ($pattern in $ExcludePatterns) {
        if ($Path -like "*\$pattern\*" -or $Path -like "*/$pattern/*") {
            return $true
        }
    }
    return $false
}

function Update-Index {
    param([string]$ChangedFile, [string]$ChangeType)
    
    Write-Log "Update triggered: $ChangeType - $ChangedFile" "INFO"
    
    try {
        $updateScript = Join-Path $PSScriptRoot "UPDATE_PROJECT_INDEX.ps1"
        
        if (Test-Path $updateScript) {
            Write-Log "Running reindex..." "INFO"
            & $updateScript -IncrementalMode -TriggerFile $ChangedFile -ProjectRoot $WatchPath
            Write-Log "Reindex completed successfully" "SUCCESS"
        } else {
            Write-Log "UPDATE_PROJECT_INDEX.ps1 not found, skipping reindex" "WARNING"
        }
    }
    catch {
        Write-Log "Error updating index: $($_.Exception.Message)" "ERROR"
    }
}

# Debounce logic
$script:lastEventTime = @{}
$script:pendingUpdates = @{}
$script:debounceTimer = $null
$script:processLock = New-Object System.Threading.Mutex($false)

function Invoke-Debounced {
    param([string]$File, [string]$ChangeType)
    
    $key = "$File-$ChangeType"
    $now = Get-Date
    
    # Thread-safe update tracking
    [void]$script:processLock.WaitOne()
    try {
        $script:pendingUpdates[$key] = @{
            File = $File
            ChangeType = $ChangeType
            Timestamp = $now
        }
    }
    finally {
        [void]$script:processLock.ReleaseMutex()
    }
    
    # Reset debounce timer
    if ($null -ne $script:debounceTimer) {
        $script:debounceTimer.Stop()
        $script:debounceTimer.Dispose()
    }
    
    # Create new timer
    $script:debounceTimer = New-Object System.Timers.Timer
    $script:debounceTimer.Interval = $DebounceMs
    $script:debounceTimer.AutoReset = $false
    
    $script:debounceTimer.Add_Elapsed({
        [void]$script:processLock.WaitOne()
        try {
            $updates = $script:pendingUpdates.Clone()
            $script:pendingUpdates.Clear()
        }
        finally {
            [void]$script:processLock.ReleaseMutex()
        }
        
        if ($updates.Count -gt 0) {
            Write-Log "Processing $($updates.Count) pending updates after debounce" "INFO"
            
            foreach ($update in $updates.Values) {
                Update-Index -ChangedFile $update.File -ChangeType $update.ChangeType
            }
        }
    })
    
    $script:debounceTimer.Start()
}

# Create FileSystemWatcher instances (one per pattern)
Write-Log "=== FileSystemWatcher Initialization ===" "INFO"
Write-Log "Watch path: $WatchPath" "INFO"
Write-Log "Watch patterns: $($WatchPatterns -join ', ')" "INFO"
Write-Log "Exclude patterns: $($ExcludePatterns -join ', ')" "INFO"
Write-Log "Debounce: $DebounceMs ms" "INFO"
Write-Log "Heartbeat: every $HeartbeatIntervalMin minutes" "INFO"

$watchers = @()
$handlers = @()

foreach ($pattern in $WatchPatterns) {
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $WatchPath
    $watcher.Filter = $pattern
    $watcher.IncludeSubdirectories = $true
    $watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor 
                             [System.IO.NotifyFilters]::LastWrite -bor
                             [System.IO.NotifyFilters]::CreationTime
    
    # Event handlers
    $onCreated = {
        $file = $Event.SourceEventArgs.FullPath
        if (-not (Test-ShouldExclude $file)) {
            Invoke-Debounced -File $file -ChangeType "Created"
        }
    }
    
    $onChanged = {
        $file = $Event.SourceEventArgs.FullPath
        if (-not (Test-ShouldExclude $file)) {
            Invoke-Debounced -File $file -ChangeType "Changed"
        }
    }
    
    $onDeleted = {
        $file = $Event.SourceEventArgs.FullPath
        if (-not (Test-ShouldExclude $file)) {
            Invoke-Debounced -File $file -ChangeType "Deleted"
        }
    }
    
    $onRenamed = {
        $file = $Event.SourceEventArgs.FullPath
        $oldFile = $Event.SourceEventArgs.OldFullPath
        if (-not (Test-ShouldExclude $file)) {
            Invoke-Debounced -File "$oldFile → $file" -ChangeType "Renamed"
        }
    }
    
    # Register events
    $handlers += Register-ObjectEvent -InputObject $watcher -EventName Created -Action $onCreated
    $handlers += Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $onChanged
    $handlers += Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $onDeleted
    $handlers += Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $onRenamed
    
    # Start monitoring
    $watcher.EnableRaisingEvents = $true
    $watchers += $watcher
    
    Write-Log "Started watcher for pattern: $pattern" "SUCCESS"
}

Write-Log "FileSystemWatcher(s) started successfully ✅" "SUCCESS"
Write-Log "Press Ctrl+C to stop..." "INFO"

try {
    $lastHeartbeat = Get-Date
    
    # Infinite loop (keeps script alive)
    while ($true) {
        Start-Sleep -Seconds 10
        
        # Heartbeat
        $now = Get-Date
        $elapsed = ($now - $lastHeartbeat).TotalMinutes
        
        if ($elapsed -ge $HeartbeatIntervalMin) {
            Write-Log "Heartbeat: FileSystemWatcher active (monitoring $($watchers.Count) patterns in $WatchPath)" "INFO"
            $lastHeartbeat = $now
        }
    }
}
finally {
    # Cleanup on exit
    Write-Log "Stopping FileSystemWatcher..." "INFO"
    
    foreach ($watcher in $watchers) {
        $watcher.EnableRaisingEvents = $false
        $watcher.Dispose()
    }
    
    foreach ($handler in $handlers) {
        Unregister-Event -SubscriptionId $handler.Id -ErrorAction SilentlyContinue
    }
    
    if ($null -ne $script:debounceTimer) {
        $script:debounceTimer.Dispose()
    }
    
    if ($null -ne $script:processLock) {
        $script:processLock.Dispose()
    }
    
    Write-Log "FileSystemWatcher stopped ✅" "SUCCESS"
}
