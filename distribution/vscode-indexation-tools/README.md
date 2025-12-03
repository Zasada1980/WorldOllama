# VS Code Automatic Indexation Tools

**Version:** 2.0  
**Release Date:** December 3, 2025  
**License:** MIT  
**Platform:** Windows 10/11, PowerShell 7+  

## Overview

Automated documentation indexing system with 3 complementary mechanisms:
- **FileSystemWatcher** — Real-time monitoring (2-5s latency)
- **Git Post-Commit Hook** — CI/CD integration (<1s latency)
- **Windows Scheduled Task** — Daily safety net (03:00)

**Tested with:**
- ✅ AI Agent simulation (95.8% understanding rate)
- ✅ Production environment (166 .md files, 3+ months)
- ✅ MCP Shell Server integration (circuit breaker, auto-retry)

---

## Features

### Core Capabilities
- ✅ **Incremental indexing** (<500ms for 1-5 files)
- ✅ **Full reindexing** (~870ms for 166 files)
- ✅ **Smart debounce** (2s sliding window, prevents excessive updates)
- ✅ **Path filtering** (excludes venv, node_modules, archive, cache dirs)
- ✅ **Heartbeat monitoring** (every 10 minutes)
- ✅ **Comprehensive logging** (indexation.log, file_watcher.log, scheduled_reindex.log)
- ✅ **Atomic operations** (safe concurrent access)
- ✅ **Error recovery** (fallback to full reindex on corruption)

### Integration
- **VS Code Tasks** — Native tasks.vs.json support
- **MCP Shell Server** — Circuit breaker, Base64 encoding, smart retries
- **Git Workflow** — Automatic trigger on commits with .md changes
- **Windows Task Scheduler** — Enterprise-grade scheduling with GPO support

---

## Quick Start

### Prerequisites
- Windows 10/11
- PowerShell 7.0+
- Git (for post-commit hook)
- Admin rights (for Scheduled Task only)

### Installation (3 steps)

**Step 1: Git Post-Commit Hook** (instant, no admin)
```powershell
pwsh scripts\INSTALL_GIT_HOOK.ps1
```
Verify:
```powershell
Test-Path .git\hooks\post-commit  # Should return True
```

**Step 2: Windows Scheduled Task** (requires admin)
```powershell
# Run PowerShell as Administrator
pwsh scripts\CREATE_SCHEDULED_TASK.ps1
```
Verify:
```powershell
Get-ScheduledTask -TaskName "VSCode_Daily_Reindex"
```

**Step 3: FileSystemWatcher** (development only, on-demand)
```powershell
# Via MCP Shell (recommended)
# Or via terminal:
pwsh scripts\WATCH_FILE_CHANGES.ps1
```
Verify:
```powershell
Get-Process pwsh | Where-Object { $_.CommandLine -like "*WATCH_FILE_CHANGES*" }
```

---

## File Structure

```
vscode-indexation-tools/
├── README.md                        # This file
├── LICENSE.txt                      # MIT License
├── INSTALL.md                       # Detailed installation guide
├── CONFIGURATION.md                 # Configuration options
├── TROUBLESHOOTING.md               # Common issues & solutions
├── scripts/
│   ├── UPDATE_PROJECT_INDEX.ps1     # Core reindexing engine
│   ├── WATCH_FILE_CHANGES.ps1       # FileSystemWatcher daemon
│   ├── CREATE_SCHEDULED_TASK.ps1    # Task Scheduler setup
│   ├── INSTALL_GIT_HOOK.ps1         # Git hook installer
│   └── post-commit.hook             # Git hook template
├── templates/
│   ├── PROJECT_INDEX_TEMPLATE.md    # Index file template
│   └── .vscode-indexation.json      # Configuration template
└── tests/
    ├── test_incremental.ps1         # Test incremental indexing
    ├── test_full_reindex.ps1        # Test full reindexing
    └── test_integration.ps1         # E2E integration test
```

---

## Configuration

### Minimal Setup (works out of the box)

```json
{
  "projectRoot": "${workspaceFolder}",
  "indexFile": "docs/project/INDEX.md",
  "watchPatterns": ["**/*.md"],
  "excludePatterns": ["**/node_modules/**", "**/venv/**", "**/archive/**"],
  "debounceMs": 2000
}
```

### Advanced Setup

```json
{
  "projectRoot": "${workspaceFolder}",
  "indexFile": "docs/project/INDEX.md",
  "watchPatterns": ["**/*.md", "**/*.rst", "**/*.adoc"],
  "excludePatterns": [
    "**/node_modules/**",
    "**/venv/**",
    "**/.venv/**",
    "**/archive/**",
    "**/build/**",
    "**/__pycache__/**"
  ],
  "debounceMs": 2000,
  "heartbeatIntervalMin": 10,
  "scheduledTask": {
    "enabled": true,
    "time": "03:00",
    "taskName": "VSCode_Daily_Reindex"
  },
  "gitHook": {
    "enabled": true,
    "incrementalMode": true
  },
  "logging": {
    "indexationLog": "logs/indexation.log",
    "watcherLog": "logs/file_watcher.log",
    "scheduledLog": "logs/scheduled_reindex.log",
    "verbosity": "INFO"
  }
}
```

---

## Usage Examples

### Scenario 1: Development Workflow

```powershell
# Start FileSystemWatcher in background
Start-Process pwsh -ArgumentList "-File", "scripts\WATCH_FILE_CHANGES.ps1" -WindowStyle Hidden

# Edit .md files in VS Code
# → Index updates automatically after 2s debounce

# Commit changes
git add docs/guides/NEW_GUIDE.md
git commit -m "Add new guide"
# → Git hook triggers incremental reindex

# Stop FileSystemWatcher (end of workday)
Stop-Process -Name pwsh -Force
```

### Scenario 2: CI/CD Pipeline

```yaml
# .github/workflows/docs.yml
name: Update Documentation Index

on:
  push:
    paths:
      - '**.md'

jobs:
  reindex:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run full reindex
        run: pwsh scripts\UPDATE_PROJECT_INDEX.ps1 -FullReindex
      - name: Commit updated index
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add docs/project/INDEX.md
          git commit -m "Auto-update documentation index" || exit 0
          git push
```

### Scenario 3: Enterprise Deployment (GPO)

```powershell
# Export task to XML
$task = Get-ScheduledTask -TaskName "VSCode_Daily_Reindex"
Export-ScheduledTask -TaskName "VSCode_Daily_Reindex" -TaskPath "\" |
  Out-File "\\domain\SYSVOL\contoso.com\Policies\VSCode_Reindex.xml"

# Deploy via GPO
# Computer Configuration → Preferences → Control Panel Settings → Scheduled Tasks
# Import: \\domain\SYSVOL\contoso.com\Policies\VSCode_Reindex.xml
```

---

## MCP Shell Integration

### Basic Usage

```json
{
  "tool": "mcp_myshell_execute_command",
  "parameters": {
    "command": "pwsh -File scripts\\WATCH_FILE_CHANGES.ps1",
    "isBackground": true
  }
}
```

### Response Monitoring

```json
{
  "output": "FileSystemWatcher started successfully",
  "meta": {
    "breakerState": "CLOSED",
    "classification": "success",
    "durationMs": 245,
    "consecutiveFailures": 0,
    "fallbackSuggested": false
  }
}
```

### Circuit Breaker Handling

```javascript
// Monitor circuit breaker state
if (response.meta.breakerState === "OPEN" || response.meta.fallbackSuggested) {
  // Fallback to terminal
  await runInTerminal("pwsh -File scripts\\WATCH_FILE_CHANGES.ps1", {
    isBackground: true
  });
}
```

---

## Performance Benchmarks

**Environment:** Windows 11, Ryzen 9 5900X, NVMe SSD

| Operation | File Count | Duration | Throughput |
|-----------|------------|----------|------------|
| Incremental (1 file) | 1 | 120ms | 8.3 files/sec |
| Incremental (5 files) | 5 | 480ms | 10.4 files/sec |
| Full reindex | 166 | 870ms | 190 files/sec |
| Debounce latency | N/A | 2000ms | 0.5 Hz max rate |
| Memory footprint | N/A | 18 MB | Constant |
| CPU usage (idle) | N/A | <0.1% | Minimal |

**Overhead:** 0.001% (1 second per day for Scheduled Task)

---

## Troubleshooting

### FileSystemWatcher not starting

```powershell
# Check logs
Get-Content logs\file_watcher.log -Tail 50

# Common issues:
# 1. Port already in use → Stop existing watcher first
# 2. Access denied → Check folder permissions
# 3. PowerShell version <7 → Upgrade to PowerShell 7+
```

### Git Hook not triggering

```powershell
# Verify hook installed
Test-Path .git\hooks\post-commit  # Should be True

# Check hook executable
git ls-files --stage .git/hooks/post-commit  # Should show 755

# Test manually
git commit --allow-empty -m "Test hook"
Get-Content logs\indexation.log -Tail 10
```

### Scheduled Task failed (LastTaskResult=1)

```powershell
# Check task info
Get-ScheduledTaskInfo -TaskName "VSCode_Daily_Reindex"

# View Event Viewer
Get-WinEvent -LogName "Microsoft-Windows-TaskScheduler/Operational" |
  Where-Object { $_.Message -like "*VSCode*" } |
  Select-Object TimeCreated, Message -First 5

# Check logs
Get-Content logs\scheduled_reindex.log -Tail 50

# Manual test
Start-ScheduledTask -TaskName "VSCode_Daily_Reindex"
```

---

## Uninstallation

```powershell
# Stop FileSystemWatcher (if running)
Get-Process pwsh | 
  Where-Object { $_.CommandLine -like "*WATCH_FILE_CHANGES*" } |
  Stop-Process -Force

# Remove Scheduled Task (requires admin)
Unregister-ScheduledTask -TaskName "VSCode_Daily_Reindex" -Confirm:$false

# Remove Git Hook
Remove-Item .git\hooks\post-commit -Force

# Remove logs
Remove-Item logs\indexation.log, logs\file_watcher.log, logs\scheduled_reindex.log -Force -ErrorAction SilentlyContinue
```

---

## FAQ

**Q: Can I use this with non-.md files?**  
A: Yes, edit `watchPatterns` in `.vscode-indexation.json`:
```json
"watchPatterns": ["**/*.md", "**/*.rst", "**/*.adoc", "**/*.txt"]
```

**Q: Does this work on Linux/Mac?**  
A: FileSystemWatcher and core script work on Linux/Mac (PowerShell Core 7+). Scheduled Task is Windows-only (use cron on Linux/Mac).

**Q: Can I run multiple FileSystemWatchers?**  
A: Not recommended (duplicate events). Use single watcher with multiple `watchPatterns`.

**Q: How much disk space for logs?**  
A: ~1 MB per month (with log rotation). Configure max size in scripts if needed.

**Q: Does this support Git LFS files?**  
A: Yes, monitors file paths regardless of LFS status.

**Q: Can I customize index format?**  
A: Yes, edit `templates/PROJECT_INDEX_TEMPLATE.md` and modify `UPDATE_PROJECT_INDEX.ps1` parsing logic.

---

## License

MIT License - see LICENSE.txt for details.

---

## Credits

- **Company:** GateVibe Israel Ltd
- **Developer:** Andrey Grushin
- **Tested by:** AI Agent simulation (95.8% understanding rate, 34.5/36 criteria)
- **Validation:** Production environment (166 .md files, 3-month use)
- **MCP Integration:** MCP Shell Server v1.3.1 (circuit breaker, Base64 encoding)

---

## Support

**Issues:** Report via GitHub Issues  
**Documentation:** See INSTALL.md, CONFIGURATION.md, TROUBLESHOOTING.md  
**Updates:** Check releases for new versions

---

## Changelog

### v2.0 (December 3, 2025)
- ✅ Path Resolution compliance (100% relative paths, no hardcoded paths)
- ✅ MCP Shell Server integration (circuit breaker, auto-retry, Base64 encoding)
- ✅ Management commands (check status, stop watcher, tail logs)
- ✅ Verification commands (immediate feedback after installation)
- ✅ AI agent testing (95.8% understanding rate)
- ✅ Production validation (166 files, 3 months)

### v1.0 (Initial Release)
- FileSystemWatcher (real-time monitoring)
- Git Post-Commit Hook (CI/CD integration)
- Windows Scheduled Task (daily safety net)
- Core reindexing engine (incremental + full)
