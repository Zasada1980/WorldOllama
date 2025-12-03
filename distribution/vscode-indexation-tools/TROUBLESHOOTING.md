# Troubleshooting Guide

## Common Issues and Solutions

### 1. FileSystemWatcher Not Starting

#### Symptoms
- Process starts but no logs appear
- No response to file changes
- Immediate exit without errors

#### Diagnosis

```powershell
# Check if already running
Get-Process pwsh | Where-Object { $_.CommandLine -like "*WATCH_FILE_CHANGES*" }

# Check logs
Get-Content logs\file_watcher.log -Tail 50

# Check PowerShell version
$PSVersionTable.PSVersion  # Must be 7.0+
```

#### Solutions

**Solution 1: Stop existing instance**
```powershell
Get-Process pwsh |
  Where-Object { $_.CommandLine -like "*WATCH_FILE_CHANGES*" } |
  Stop-Process -Force

# Restart
pwsh scripts\WATCH_FILE_CHANGES.ps1
```

**Solution 2: Check PowerShell version**
```powershell
# Upgrade to PowerShell 7+
winget install Microsoft.PowerShell

# Verify
$PSVersionTable.PSVersion
```

**Solution 3: Permission issues**
```powershell
# Run as Administrator
Start-Process pwsh -ArgumentList "-File", "scripts\WATCH_FILE_CHANGES.ps1" -Verb RunAs
```

**Solution 4: Invalid patterns**
```powershell
# Check config
Get-Content .vscode-indexation.json | ConvertFrom-Json

# Validate patterns (must be array)
# ❌ Wrong: "watchPatterns": "*.md"
# ✅ Correct: "watchPatterns": ["*.md"]
```

---

### 2. Git Hook Not Triggering

#### Symptoms
- Commits succeed but no reindex
- No entries in `logs\indexation.log`
- Manual script execution works

#### Diagnosis

```powershell
# 1. Hook exists?
Test-Path .git\hooks\post-commit

# 2. Hook has correct permissions?
git ls-files --stage .git/hooks/post-commit
# Should show 755 (executable)

# 3. Hook references correct script?
Get-Content .git\hooks\post-commit
# Should contain: UPDATE_PROJECT_INDEX.ps1

# 4. Test manually
git commit --allow-empty -m "test hook"
Get-Content logs\indexation.log -Tail 10
```

#### Solutions

**Solution 1: Reinstall hook**
```powershell
pwsh scripts\INSTALL_GIT_HOOK.ps1
```

**Solution 2: Fix permissions**
```powershell
# Set executable bit
git update-index --chmod=+x .git/hooks/post-commit

# Verify
git ls-files --stage .git/hooks/post-commit
```

**Solution 3: Check PowerShell path in hook**
```powershell
# Edit hook: .git\hooks\post-commit
# Line 15-20: Check PowerShell detection

# Manual test
pwsh --version
# or
powershell --version
```

**Solution 4: Verbose logging**
```powershell
# Edit post-commit hook
# Add debug output:
echo "[DEBUG] Git root: $PROJECT_ROOT"
echo "[DEBUG] Script: $UPDATE_SCRIPT"
echo "[DEBUG] Changed files: $CHANGED_FILES"
```

**Solution 5: File extension mismatch**
```powershell
# Edit post-commit hook line ~25
# Modify grep regex:
grep -E '\.(md|rst|adoc|txt)$'
# Change extensions as needed
```

---

### 3. Scheduled Task Failed

#### Symptoms
- Task shows "Ready" but LastResult ≠ 0
- No logs in `logs\scheduled_reindex.log`
- Manual execution works

#### Diagnosis

```powershell
# 1. Task info
Get-ScheduledTaskInfo -TaskName "VSCode_Daily_Reindex"

# 2. Last result (0=success, non-zero=failure)
(Get-ScheduledTaskInfo -TaskName "VSCode_Daily_Reindex").LastTaskResult

# Common error codes:
# 0x1 (1) = General error
# 0x2 (2) = File not found
# 0xFFFFFFFF = Timeout

# 3. Task history
Get-WinEvent -LogName "Microsoft-Windows-TaskScheduler/Operational" -MaxEvents 50 |
  Where-Object { $_.Message -like "*VSCode*" } |
  Select TimeCreated, LevelDisplayName, Message

# 4. Check logs
Get-Content logs\scheduled_reindex.log -Tail 100
```

#### Solutions

**Solution 1: Script path incorrect**
```powershell
# View task action
$task = Get-ScheduledTask -TaskName "VSCode_Daily_Reindex"
$task.Actions

# Should show correct path:
# Arguments: -File "C:\YourProject\scripts\UPDATE_PROJECT_INDEX.ps1"

# Fix: Recreate task
pwsh scripts\CREATE_SCHEDULED_TASK.ps1
```

**Solution 2: Execution timeout**
```powershell
# Task taking >10 minutes (default limit)

# Option A: Increase timeout
Unregister-ScheduledTask -TaskName "VSCode_Daily_Reindex" -Confirm:$false

# Edit CREATE_SCHEDULED_TASK.ps1 line ~50:
# Change: $settings.ExecutionTimeLimit = "PT30M"  # 30 minutes

pwsh scripts\CREATE_SCHEDULED_TASK.ps1

# Option B: Disable timeout
# In Task Scheduler GUI:
# Task → Properties → Settings → Execution time limit → Uncheck
```

**Solution 3: Permissions issue**
```powershell
# Run as Administrator to recreate
# Right-click PowerShell → "Run as administrator"
pwsh scripts\CREATE_SCHEDULED_TASK.ps1

# Verify SYSTEM account
$task = Get-ScheduledTask -TaskName "VSCode_Daily_Reindex"
$task.Principal  # Should show UserId: SYSTEM
```

**Solution 4: Working directory wrong**
```powershell
# Task should run from project root

# View task settings
$task = Get-ScheduledTask -TaskName "VSCode_Daily_Reindex"
$task.Actions.WorkingDirectory

# Should be: C:\YourProject

# Fix in Task Scheduler GUI:
# Task → Properties → Actions → Edit → Start in: C:\YourProject
```

**Solution 5: PowerShell not found**
```powershell
# Check if pwsh exists on system
Get-Command pwsh -ErrorAction SilentlyContinue

# If not, task falls back to powershell.exe
Get-Command powershell

# Install PowerShell 7+
winget install Microsoft.PowerShell

# Recreate task
pwsh scripts\CREATE_SCHEDULED_TASK.ps1
```

---

### 4. Index File Not Updating

#### Symptoms
- Scripts run without errors
- Logs show "SUCCESS"
- Index file unchanged or empty

#### Diagnosis

```powershell
# 1. Check index file exists
Test-Path docs\project\INDEX.md

# 2. Check file permissions
Get-Acl docs\project\INDEX.md

# 3. Check logs for write errors
Select-String -Path logs\indexation.log -Pattern "ERROR|WARNING" | Select-Object -Last 20

# 4. Run with verbose logging
pwsh scripts\UPDATE_PROJECT_INDEX.ps1 -FullReindex -Verbose
```

#### Solutions

**Solution 1: File locked**
```powershell
# Check if file open in editor
# Close VS Code or other editors

# Or run with force
# (Add to UPDATE_PROJECT_INDEX.ps1 line ~120)
# Out-File -FilePath $IndexFile -Encoding UTF8 -Force
```

**Solution 2: UTF-8 BOM issue**
```powershell
# Check encoding
Get-Content docs\project\INDEX.md -Encoding Byte -TotalCount 3
# Should not start with EF BB BF (UTF-8 BOM)

# Fix: Re-save without BOM
$content = Get-Content docs\project\INDEX.md -Raw
[System.IO.File]::WriteAllText("docs\project\INDEX.md", $content, (New-Object System.Text.UTF8Encoding $false))
```

**Solution 3: Invalid metadata format**
```powershell
# Check index file structure
Get-Content docs\project\INDEX.md | Select-String "##|Total Files|Coverage Period|Last Updated"

# Should have:
# ## Metadata
# - **Total Files:** ...
# - **Coverage Period:** ...
# - **Last Updated:** ...

# Fix: Delete index file, script recreates
Remove-Item docs\project\INDEX.md
pwsh scripts\UPDATE_PROJECT_INDEX.ps1 -FullReindex
```

**Solution 4: No matching files**
```powershell
# Check if files match patterns
Get-ChildItem -Path . -Recurse -Include *.md |
  Where-Object { $_.FullName -notmatch "node_modules|venv|\.git" }

# If empty, adjust patterns in config
```

---

### 5. High CPU/Memory Usage

#### Symptoms
- FileSystemWatcher consumes >500 MB RAM
- CPU usage >20% when idle
- System slow after starting watcher

#### Diagnosis

```powershell
# Monitor resource usage
Get-Process pwsh | Where-Object { $_.CommandLine -like "*WATCH_FILE_CHANGES*" } |
  Select Name, CPU, WorkingSet64

# Check number of monitored files
Get-ChildItem -Path . -Recurse -Include *.md |
  Where-Object { $_.FullName -notmatch "node_modules|venv|\.git" } |
  Measure-Object | Select Count
```

#### Solutions

**Solution 1: Increase debounce**
```json
{
  "debounceMs": 5000  // 5 seconds (default: 2)
}
```

**Solution 2: Add more exclude patterns**
```json
{
  "excludePatterns": [
    "**/node_modules/**",
    "**/venv/**",
    "**/.venv/**",
    "**/build/**",
    "**/dist/**",
    "**/__pycache__/**",
    "**/archive/**",
    "**/backup/**",
    "**/temp/**",
    "**/.git/**"
  ]
}
```

**Solution 3: Limit watch patterns**
```json
{
  // Instead of watching all directories
  "watchPatterns": ["**/*.md"],
  
  // Watch only specific directories
  "watchPatterns": ["docs/**/*.md", "README.md"]
}
```

**Solution 4: Use Git Hook + Scheduled Task only**
```powershell
# Stop FileSystemWatcher
Get-Process pwsh |
  Where-Object { $_.CommandLine -like "*WATCH_FILE_CHANGES*" } |
  Stop-Process -Force

# Rely on Git Hook for commits + Scheduled Task for daily cleanup
```

---

### 6. Logs Growing Too Large

#### Symptoms
- `logs\*.log` files >100 MB
- Disk space warnings
- Slow log parsing

#### Diagnosis

```powershell
# Check log sizes
Get-ChildItem logs\*.log | Select Name, @{N="SizeMB";E={[math]::Round($_.Length/1MB,2)}} | Sort SizeMB -Descending
```

#### Solutions

**Solution 1: Configure log rotation**
```json
{
  "logging": {
    "maxLogSizeMB": 10,    // Rotate at 10 MB
    "retentionDays": 30    // Keep 30 days
  }
}
```

**Solution 2: Manual cleanup**
```powershell
# Delete logs older than 30 days
Get-ChildItem logs\*.log |
  Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
  Remove-Item -Force

# Compress old logs
Get-ChildItem logs\*.log |
  Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
  Compress-Archive -DestinationPath logs\archive_$(Get-Date -Format 'yyyyMMdd').zip
```

**Solution 3: Reduce logging verbosity**
```powershell
# Edit scripts, comment out INFO logs
# Keep only ERROR and WARNING

# Example in UPDATE_PROJECT_INDEX.ps1:
# Write-Host "[INFO] ..." -ForegroundColor Green  # Comment this
# Write-Host "[ERROR] ..." -ForegroundColor Red   # Keep this
```

---

### 7. Cross-Platform Issues

#### Linux/macOS

**Issue: post-commit hook not executable**
```bash
# Symptoms: Hook doesn't run on commit

# Solution: Set executable bit
chmod +x .git/hooks/post-commit
```

**Issue: PowerShell not found**
```bash
# Symptoms: /usr/bin/env: 'pwsh': No such file or directory

# Solution: Install PowerShell
# Ubuntu/Debian
wget https://aka.ms/powershell.deb
sudo dpkg -i powershell.deb

# macOS
brew install powershell
```

**Issue: Path separators**
```bash
# Symptoms: File paths broken (C:\... on Unix)

# Solution: PowerShell handles this automatically
# Use Join-Path instead of string concatenation:
# ❌ "$ProjectRoot\scripts\file.ps1"
# ✅ Join-Path $ProjectRoot "scripts" "file.ps1"
```

---

### 8. Performance Issues

#### Large Projects (10,000+ files)

**Issue: Full reindex takes >5 minutes**

```powershell
# Diagnosis
Measure-Command { pwsh scripts\UPDATE_PROJECT_INDEX.ps1 -FullReindex }

# Solution 1: Use incremental mode
pwsh scripts\UPDATE_PROJECT_INDEX.ps1 -IncrementalMode -TriggerFile "README.md"

# Solution 2: Parallel processing (advanced)
# Edit UPDATE_PROJECT_INDEX.ps1, add ForEach-Object -Parallel:
Get-ChildItem -Path $ProjectRoot -Recurse -Include $WatchPatterns |
  Where-Object { $_.FullName -notmatch ($ExcludePatterns -join "|") } |
  ForEach-Object -Parallel {
    # Process file
  } -ThrottleLimit 4
```

**Issue: Debounce delay too long**

```powershell
# Diagnosis: FileSystemWatcher takes 5+ seconds to react

# Solution: Reduce debounce for development
pwsh scripts\WATCH_FILE_CHANGES.ps1 -DebounceMs 1000  # 1 second

# Keep 2-5s for production (prevents excessive reindexing)
```

---

## Error Code Reference

### EXIT CODES

| Code | Meaning | Solution |
|------|---------|----------|
| 0 | Success | No action needed |
| 1 | General error | Check logs for details |
| 2 | File not found | Verify paths in config |
| 3 | Permission denied | Run as Administrator |
| 4 | Invalid parameters | Check command syntax |
| 5 | Timeout | Increase timeout or reduce file count |

### Windows Error Codes (Scheduled Task)

| Code | Meaning | Solution |
|------|---------|----------|
| 0x0 (0) | Success | No action needed |
| 0x1 (1) | Incorrect function | Check script syntax |
| 0x2 (2) | File not found | Check script path in task |
| 0x5 (5) | Access denied | Run as Administrator, recreate task |
| 0x41301 | Task still running | Increase ExecutionTimeLimit |
| 0xFFFFFFFF | Timeout | Increase timeout or optimize script |

---

## Debugging Techniques

### Enable Verbose Logging

```powershell
# All scripts support -Verbose
pwsh scripts\UPDATE_PROJECT_INDEX.ps1 -FullReindex -Verbose

# Shows:
# VERBOSE: Resolved ProjectRoot: C:\MyProject
# VERBOSE: Resolved IndexFile: C:\MyProject\docs\project\INDEX.md
# VERBOSE: Found 47 files matching patterns
# VERBOSE: Excluded 12 files matching exclude patterns
# VERBOSE: Processing file: README.md
# ...
```

### Trace PowerShell Execution

```powershell
# Enable script tracing
Set-PSDebug -Trace 2

# Run script
pwsh scripts\WATCH_FILE_CHANGES.ps1

# Disable tracing
Set-PSDebug -Trace 0
```

### Monitor File System Events

```powershell
# Create test watcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "C:\YourProject"
$watcher.Filter = "*.md"
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# Log all events
Register-ObjectEvent -InputObject $watcher -EventName Changed -Action {
    Write-Host "Changed: $($Event.SourceEventArgs.FullPath)"
}

# Stop monitoring
$watcher.EnableRaisingEvents = $false
$watcher.Dispose()
```

---

## Log Analysis

### Parse Logs

```powershell
# Find errors
Select-String -Path logs\indexation.log -Pattern "ERROR" | Select-Object -Last 10

# Find warnings
Select-String -Path logs\indexation.log -Pattern "WARNING" | Select-Object -Last 10

# Count events by type
Get-Content logs\indexation.log |
  Select-String "\[(ERROR|WARNING|INFO|SUCCESS)\]" |
  Group-Object { $_.Line -replace '.*\[(ERROR|WARNING|INFO|SUCCESS)\].*', '$1' } |
  Select Name, Count
```

### Monitor Logs Real-Time

```powershell
# Tail logs (like Linux tail -f)
Get-Content logs\indexation.log -Tail 20 -Wait

# Highlight errors
Get-Content logs\indexation.log -Tail 50 -Wait |
  ForEach-Object {
    if ($_ -match "ERROR") {
      Write-Host $_ -ForegroundColor Red
    } elseif ($_ -match "WARNING") {
      Write-Host $_ -ForegroundColor Yellow
    } else {
      Write-Host $_
    }
  }
```

---

## Getting Help

### Check Documentation

1. [README.md](README.md) — Overview, features, quick start
2. [INSTALL.md](INSTALL.md) — Detailed installation guide
3. [CONFIGURATION.md](CONFIGURATION.md) — Parameter reference
4. This file — Troubleshooting guide

### Collect Diagnostic Info

```powershell
# Run diagnostic script
# Save as: scripts\DIAGNOSTICS.ps1

$ProjectRoot = Split-Path -Parent $PSScriptRoot

Write-Host "=== VS Code Indexation Tools Diagnostics ===" -ForegroundColor Cyan

# PowerShell version
Write-Host "`nPowerShell Version:" -ForegroundColor Yellow
$PSVersionTable.PSVersion

# Git version
Write-Host "`nGit Version:" -ForegroundColor Yellow
git --version

# Check files
Write-Host "`nFile Check:" -ForegroundColor Yellow
@(
  "scripts\UPDATE_PROJECT_INDEX.ps1",
  "scripts\WATCH_FILE_CHANGES.ps1",
  "scripts\CREATE_SCHEDULED_TASK.ps1",
  ".git\hooks\post-commit",
  "logs\indexation.log"
) | ForEach-Object {
  $exists = Test-Path "$ProjectRoot\$_"
  $status = if ($exists) { "✅" } else { "❌" }
  Write-Host "$status $_"
}

# Scheduled Task
Write-Host "`nScheduled Task:" -ForegroundColor Yellow
try {
  $task = Get-ScheduledTask -TaskName "VSCode_Daily_Reindex" -ErrorAction Stop
  Write-Host "✅ Task exists"
  $info = Get-ScheduledTaskInfo -TaskName "VSCode_Daily_Reindex"
  Write-Host "  LastRunTime: $($info.LastRunTime)"
  Write-Host "  LastResult: $($info.LastTaskResult)"
} catch {
  Write-Host "❌ Task not found"
}

# FileSystemWatcher
Write-Host "`nFileSystemWatcher:" -ForegroundColor Yellow
$watcher = Get-Process pwsh -ErrorAction SilentlyContinue |
  Where-Object { $_.CommandLine -like "*WATCH_FILE_CHANGES*" }
if ($watcher) {
  Write-Host "✅ Running (PID: $($watcher.Id))"
} else {
  Write-Host "❌ Not running"
}

# Recent logs
Write-Host "`nRecent Log Entries:" -ForegroundColor Yellow
if (Test-Path "$ProjectRoot\logs\indexation.log") {
  Get-Content "$ProjectRoot\logs\indexation.log" -Tail 5
} else {
  Write-Host "❌ No logs found"
}
```

**Run diagnostics:**
```powershell
pwsh scripts\DIAGNOSTICS.ps1
```

---

## Contact & Support

- **GitHub Issues:** Report bugs, request features
- **Documentation:** See README.md for full guide
- **License:** MIT (see LICENSE.txt)

---

**Troubleshooting guide complete! 🛠️**

For most issues:
1. Check logs: `logs\*.log`
2. Run diagnostics: `pwsh scripts\DIAGNOSTICS.ps1`
3. Consult this guide for specific error codes
4. See [CONFIGURATION.md](CONFIGURATION.md) for parameter tuning
