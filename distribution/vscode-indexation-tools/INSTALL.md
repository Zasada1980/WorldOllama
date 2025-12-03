# Detailed Installation Guide

## Prerequisites

Before installing VS Code Indexation Tools, ensure you have:

- ✅ **Windows 10/11** (64-bit)
- ✅ **PowerShell 7.0+** ([Download](https://aka.ms/powershell))
- ✅ **Git 2.30+** (for post-commit hook)
- ✅ **Administrator rights** (for Scheduled Task only)

**Check your PowerShell version:**
```powershell
$PSVersionTable.PSVersion
# Should show 7.0 or higher
```

**Upgrade if needed:**
```powershell
winget install Microsoft.PowerShell
```

---

## Installation Steps

### Option 1: Quick Install (All Mechanisms)

```powershell
# 1. Clone/extract to your project
cd C:\YourProject
# Extract vscode-indexation-tools.zip here

# 2. Install Git Hook (no admin)
pwsh scripts\INSTALL_GIT_HOOK.ps1

# 3. Install Scheduled Task (requires admin)
# Right-click PowerShell → Run as Administrator
pwsh scripts\CREATE_SCHEDULED_TASK.ps1

# 4. (Optional) Start FileSystemWatcher for development
pwsh scripts\WATCH_FILE_CHANGES.ps1
```

---

### Option 2: Step-by-Step Install

#### Step 1: Extract Files

1. Download `vscode-indexation-tools.zip`
2. Extract to your project root:
   ```
   C:\YourProject\
   ├── scripts\
   │   ├── UPDATE_PROJECT_INDEX.ps1
   │   ├── WATCH_FILE_CHANGES.ps1
   │   ├── CREATE_SCHEDULED_TASK.ps1
   │   ├── INSTALL_GIT_HOOK.ps1
   │   └── post-commit.hook
   ├── templates\
   │   ├── PROJECT_INDEX_TEMPLATE.md
   │   └── .vscode-indexation.json
   └── README.md
   ```

#### Step 2: Configuration (Optional)

Create `.vscode-indexation.json` in project root (or use template):

```json
{
  "projectRoot": "${workspaceFolder}",
  "indexFile": "docs/project/INDEX.md",
  "watchPatterns": ["**/*.md"],
  "excludePatterns": ["**/node_modules/**", "**/venv/**"],
  "debounceMs": 2000
}
```

**Note:** Scripts auto-detect project root if not configured.

#### Step 3: Install Git Post-Commit Hook

```powershell
# From project root
pwsh scripts\INSTALL_GIT_HOOK.ps1
```

**Verify installation:**
```powershell
Test-Path .git\hooks\post-commit  # Should return True
```

**Test manually:**
```powershell
# Make a commit with .md changes
git add README.md
git commit -m "test: verify post-commit hook"

# Check logs
Get-Content logs\indexation.log -Tail 10
```

#### Step 4: Install Windows Scheduled Task

**Important:** Requires Administrator privileges

```powershell
# Open PowerShell as Administrator
# Right-click PowerShell → "Run as administrator"

# Create task (daily at 03:00 by default)
pwsh scripts\CREATE_SCHEDULED_TASK.ps1
```

**Custom execution time:**
```powershell
pwsh scripts\CREATE_SCHEDULED_TASK.ps1 -ExecutionTime "02:30"
```

**Verify installation:**
```powershell
Get-ScheduledTask -TaskName "VSCode_Daily_Reindex"
```

**Test manually:**
```powershell
Start-ScheduledTask -TaskName "VSCode_Daily_Reindex"

# Check result
Get-ScheduledTaskInfo -TaskName "VSCode_Daily_Reindex" | Select LastTaskResult, LastRunTime
# LastTaskResult: 0 = success, 1 = failure

# Check logs
Get-Content logs\scheduled_reindex.log -Tail 20
```

#### Step 5: FileSystemWatcher (Optional, for Development)

**Note:** Not required if Git Hook + Scheduled Task installed

```powershell
# Start watcher (blocks terminal)
pwsh scripts\WATCH_FILE_CHANGES.ps1
```

**Run in background (hidden window):**
```powershell
Start-Process pwsh -ArgumentList "-File", "scripts\WATCH_FILE_CHANGES.ps1" -WindowStyle Hidden
```

**Verify running:**
```powershell
Get-Process pwsh | Where-Object { $_.CommandLine -like "*WATCH_FILE_CHANGES*" }
```

**Stop watcher:**
```powershell
$watcher = Get-Process pwsh | Where-Object { $_.CommandLine -like "*WATCH_FILE_CHANGES*" }
if ($watcher) { Stop-Process -Id $watcher.Id -Force }
```

---

## Customization

### Watch Patterns

Edit `UPDATE_PROJECT_INDEX.ps1` or create `.vscode-indexation.json`:

```json
{
  "watchPatterns": [
    "**/*.md",      // Markdown
    "**/*.rst",     // reStructuredText
    "**/*.adoc",    // AsciiDoc
    "**/*.txt"      // Plain text
  ]
}
```

### Exclude Patterns

```json
{
  "excludePatterns": [
    "**/node_modules/**",
    "**/venv/**",
    "**/.venv/**",
    "**/build/**",
    "**/dist/**",
    "**/__pycache__/**",
    "**/archive/**"
  ]
}
```

### Debounce Delay

```powershell
# Default: 2000ms (2 seconds)
pwsh scripts\WATCH_FILE_CHANGES.ps1 -DebounceMs 5000  # 5 seconds
```

### Index File Location

```json
{
  "indexFile": "docs/project/INDEX.md"  // Default
  // or
  "indexFile": "DOCUMENTATION_INDEX.md"
}
```

---

## Verification Checklist

- [ ] PowerShell 7+ installed (`$PSVersionTable.PSVersion`)
- [ ] Git installed (`git --version`)
- [ ] Git Hook installed (`Test-Path .git\hooks\post-commit`)
- [ ] Scheduled Task created (`Get-ScheduledTask -TaskName "VSCode_Daily_Reindex"`)
- [ ] FileSystemWatcher running (optional, `Get-Process pwsh`)
- [ ] Logs directory created (`Test-Path logs`)
- [ ] Index file exists (`Test-Path docs\project\INDEX.md`)
- [ ] Test commit triggers reindex (check `logs\indexation.log`)

---

## Integration with VS Code

### Tasks Configuration (tasks.json)

Create `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Start FileSystemWatcher",
      "type": "shell",
      "command": "pwsh",
      "args": ["-File", "scripts/WATCH_FILE_CHANGES.ps1"],
      "isBackground": true,
      "problemMatcher": []
    },
    {
      "label": "Stop FileSystemWatcher",
      "type": "shell",
      "command": "pwsh",
      "args": [
        "-Command",
        "$watcher = Get-Process pwsh | Where-Object { $_.CommandLine -like '*WATCH_FILE_CHANGES*' }; if ($watcher) { Stop-Process -Id $watcher.Id -Force }"
      ]
    },
    {
      "label": "Full Reindex",
      "type": "shell",
      "command": "pwsh",
      "args": ["-File", "scripts/UPDATE_PROJECT_INDEX.ps1", "-FullReindex"]
    },
    {
      "label": "Test Scheduled Task",
      "type": "shell",
      "command": "pwsh",
      "args": [
        "-Command",
        "Start-ScheduledTask -TaskName 'VSCode_Daily_Reindex'; Start-Sleep 5; Get-Content logs\\scheduled_reindex.log -Tail 20"
      ]
    }
  ]
}
```

**Usage:** `Ctrl+Shift+P` → "Tasks: Run Task" → Select task

---

## Troubleshooting

### Git Hook Not Triggering

**Check:**
```powershell
# 1. Hook installed?
Test-Path .git\hooks\post-commit

# 2. Hook executable?
git ls-files --stage .git/hooks/post-commit  # Should show 755

# 3. Manual test
git commit --allow-empty -m "test hook"
Get-Content logs\indexation.log -Tail 10
```

**Fix:**
```powershell
# Reinstall hook
pwsh scripts\INSTALL_GIT_HOOK.ps1
```

### Scheduled Task Failed

**Check:**
```powershell
# Task info
Get-ScheduledTaskInfo -TaskName "VSCode_Daily_Reindex"

# Last result (0=success, 1=failure)
(Get-ScheduledTaskInfo -TaskName "VSCode_Daily_Reindex").LastTaskResult

# Logs
Get-Content logs\scheduled_reindex.log -Tail 50

# Event Viewer
Get-WinEvent -LogName "Microsoft-Windows-TaskScheduler/Operational" |
  Where-Object { $_.Message -like "*VSCode*" } |
  Select TimeCreated, Message -First 5
```

**Common fixes:**
```powershell
# 1. Script path wrong
Get-ScheduledTask -TaskName "VSCode_Daily_Reindex" | Select Actions

# 2. Permissions issue
# Run as Administrator:
pwsh scripts\CREATE_SCHEDULED_TASK.ps1  # Recreate

# 3. Timeout (>10 min)
# Edit ExecutionTimeLimit in script or Task Scheduler GUI
```

### FileSystemWatcher Not Starting

**Check:**
```powershell
# 1. Already running?
Get-Process pwsh | Where-Object { $_.CommandLine -like "*WATCH_FILE_CHANGES*" }

# 2. Logs
Get-Content logs\file_watcher.log -Tail 50

# 3. PowerShell version
$PSVersionTable.PSVersion  # Must be 7.0+
```

**Fix:**
```powershell
# Stop existing watcher
Get-Process pwsh |
  Where-Object { $_.CommandLine -like "*WATCH_FILE_CHANGES*" } |
  Stop-Process -Force

# Restart
pwsh scripts\WATCH_FILE_CHANGES.ps1
```

---

## Next Steps

1. ✅ Installation complete → See [CONFIGURATION.md](CONFIGURATION.md) for advanced options
2. ✅ Need help? → See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
3. ✅ CI/CD integration → See [README.md](README.md) GitHub Actions example
4. ✅ Enterprise deployment → See [README.md](README.md) GPO deployment guide

---

## Uninstallation

```powershell
# 1. Stop FileSystemWatcher
Get-Process pwsh |
  Where-Object { $_.CommandLine -like "*WATCH_FILE_CHANGES*" } |
  Stop-Process -Force

# 2. Remove Scheduled Task (requires admin)
Unregister-ScheduledTask -TaskName "VSCode_Daily_Reindex" -Confirm:$false

# 3. Remove Git Hook
Remove-Item .git\hooks\post-commit -Force

# 4. Remove logs (optional)
Remove-Item logs\*.log -Force -ErrorAction SilentlyContinue

# 5. Remove scripts (optional)
Remove-Item scripts -Recurse -Force
```

---

**Installation complete! 🎉**

The indexation system will now:
- ✅ Trigger on commits (Git Hook)
- ✅ Run daily at 03:00 (Scheduled Task)
- ✅ Monitor files in real-time (FileSystemWatcher, if started)
