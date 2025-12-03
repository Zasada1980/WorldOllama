# Configuration Reference

## Overview

VS Code Indexation Tools supports configuration via:

1. **Configuration File** (`.vscode-indexation.json`)
2. **Command-Line Parameters** (override config file)
3. **Environment Variables** (advanced scenarios)

---

## Configuration File Format

### Location

Place `.vscode-indexation.json` in project root:

```
YourProject/
├── .vscode-indexation.json  ← Configuration file
├── scripts/
│   └── UPDATE_PROJECT_INDEX.ps1
└── docs/
    └── project/
        └── INDEX.md
```

### Minimal Configuration

```json
{
  "indexFile": "docs/project/INDEX.md"
}
```

**Note:** All other values auto-detected.

### Full Configuration

```json
{
  "projectRoot": "${workspaceFolder}",
  "indexFile": "docs/project/RUNTIME_LOGS_JOURNAL_INDEX.md",
  "watchPatterns": [
    "**/*.md",
    "**/*.rst",
    "**/*.adoc"
  ],
  "excludePatterns": [
    "**/node_modules/**",
    "**/venv/**",
    "**/.venv/**",
    "**/build/**",
    "**/dist/**",
    "**/__pycache__/**",
    "**/archive/**",
    "**/.git/**"
  ],
  "debounceMs": 2000,
  "heartbeatIntervalMin": 10,
  "scheduledTask": {
    "taskName": "VSCode_Daily_Reindex",
    "executionTime": "03:00",
    "enabled": true
  },
  "gitHook": {
    "enabled": true,
    "fileExtensions": ["md", "rst", "adoc", "txt"]
  },
  "logging": {
    "logDir": "logs",
    "maxLogSizeMB": 10,
    "retentionDays": 30
  }
}
```

---

## Parameter Reference

### Core Parameters

#### `projectRoot` (string)
- **Default:** Auto-detected (parent of scripts directory)
- **Description:** Absolute path to project root
- **Example:** `"C:\\Projects\\MyApp"` or `"${workspaceFolder}"`
- **Notes:** Use forward slashes (`/`) or escaped backslashes (`\\`) in JSON

#### `indexFile` (string)
- **Default:** `"docs/project/RUNTIME_LOGS_JOURNAL_INDEX.md"`
- **Description:** Relative path to index file (from projectRoot)
- **Example:** `"DOCUMENTATION_INDEX.md"`
- **Notes:** Creates parent directories automatically

#### `watchPatterns` (string[])
- **Default:** `["**/*.md"]`
- **Description:** Glob patterns for files to monitor
- **Example:**
  ```json
  [
    "**/*.md",       // All Markdown files
    "docs/**/*.rst", // reStructuredText in docs/
    "*.adoc"         // AsciiDoc in root only
  ]
  ```
- **Notes:** Uses PowerShell `Get-ChildItem -Include` syntax

#### `excludePatterns` (string[])
- **Default:** `["**/node_modules/**", "**/venv/**", "**/.git/**"]`
- **Description:** Glob patterns for files/directories to ignore
- **Example:**
  ```json
  [
    "**/archive/**",
    "**/temp/**",
    "**/*.backup.md"
  ]
  ```
- **Notes:** Applied after `watchPatterns`

---

### FileSystemWatcher Parameters

#### `debounceMs` (number)
- **Default:** `2000` (2 seconds)
- **Range:** `500` - `10000` ms
- **Description:** Wait time before processing file change events
- **Example:** `5000` (5 seconds for slow disks)
- **Command-Line Override:**
  ```powershell
  pwsh scripts\WATCH_FILE_CHANGES.ps1 -DebounceMs 5000
  ```

#### `heartbeatIntervalMin` (number)
- **Default:** `10` minutes
- **Range:** `1` - `60` min
- **Description:** Interval for heartbeat log messages
- **Example:** `5` (heartbeat every 5 minutes)
- **Command-Line Override:**
  ```powershell
  pwsh scripts\WATCH_FILE_CHANGES.ps1 -HeartbeatIntervalMin 5
  ```

---

### Scheduled Task Parameters

#### `scheduledTask.taskName` (string)
- **Default:** `"VSCode_Daily_Reindex"`
- **Description:** Windows Task Scheduler task name
- **Example:** `"MyProject_Reindex"`
- **Command-Line Override:**
  ```powershell
  pwsh scripts\CREATE_SCHEDULED_TASK.ps1 -TaskName "MyProject_Reindex"
  ```

#### `scheduledTask.executionTime` (string)
- **Default:** `"03:00"`
- **Format:** `"HH:MM"` (24-hour)
- **Description:** Daily execution time
- **Example:** `"02:30"` (2:30 AM)
- **Command-Line Override:**
  ```powershell
  pwsh scripts\CREATE_SCHEDULED_TASK.ps1 -ExecutionTime "02:30"
  ```

#### `scheduledTask.enabled` (boolean)
- **Default:** `true`
- **Description:** Whether to install scheduled task
- **Example:** `false` (skip installation)

---

### Git Hook Parameters

#### `gitHook.enabled` (boolean)
- **Default:** `true`
- **Description:** Whether to install Git post-commit hook
- **Example:** `false` (skip installation)

#### `gitHook.fileExtensions` (string[])
- **Default:** `["md", "rst", "adoc", "txt"]`
- **Description:** File extensions to trigger reindex
- **Example:** `["md", "markdown", "mdown"]`
- **Notes:** Modifies `grep -E` regex in `post-commit.hook`

---

### Logging Parameters

#### `logging.logDir` (string)
- **Default:** `"logs"`
- **Description:** Relative path to logs directory (from projectRoot)
- **Example:** `"logs/indexation"`
- **Notes:** Creates directory automatically

#### `logging.maxLogSizeMB` (number)
- **Default:** `10` MB
- **Range:** `1` - `100` MB
- **Description:** Maximum log file size before rotation
- **Example:** `50` (50 MB for high-volume projects)

#### `logging.retentionDays` (number)
- **Default:** `30` days
- **Range:** `7` - `365` days
- **Description:** Days to keep old log files
- **Example:** `90` (3 months retention)

---

## Command-Line Parameter Override

All scripts accept parameters that override config file values:

### UPDATE_PROJECT_INDEX.ps1

```powershell
pwsh scripts\UPDATE_PROJECT_INDEX.ps1 `
  -ProjectRoot "C:\MyProject" `
  -IndexFile "docs\INDEX.md" `
  -WatchPatterns @("*.md", "*.rst") `
  -ExcludePatterns @("archive\**") `
  -IncrementalMode `
  -TriggerFile "README.md"
```

**Full parameter list:**
- `-ProjectRoot` (string)
- `-IndexFile` (string)
- `-WatchPatterns` (string[])
- `-ExcludePatterns` (string[])
- `-IncrementalMode` (switch)
- `-FullReindex` (switch)
- `-TriggerFile` (string, for incremental mode)

### WATCH_FILE_CHANGES.ps1

```powershell
pwsh scripts\WATCH_FILE_CHANGES.ps1 `
  -WatchPath "C:\MyProject" `
  -WatchPatterns @("*.md", "*.rst", "*.adoc") `
  -ExcludePatterns @("node_modules\**", "venv\**") `
  -DebounceMs 5000 `
  -HeartbeatIntervalMin 5
```

**Full parameter list:**
- `-WatchPath` (string)
- `-WatchPatterns` (string[])
- `-ExcludePatterns` (string[])
- `-DebounceMs` (int)
- `-HeartbeatIntervalMin` (int)

### CREATE_SCHEDULED_TASK.ps1

```powershell
pwsh scripts\CREATE_SCHEDULED_TASK.ps1 `
  -ProjectRoot "C:\MyProject" `
  -TaskName "MyProject_Reindex" `
  -ExecutionTime "02:30"
```

**Full parameter list:**
- `-ProjectRoot` (string)
- `-TaskName` (string)
- `-ExecutionTime` (string, HH:MM format)
- `-RemoveTask` (switch, for uninstallation)

### INSTALL_GIT_HOOK.ps1

```powershell
pwsh scripts\INSTALL_GIT_HOOK.ps1 `
  -ProjectRoot "C:\MyProject" `
  -SourceHook "scripts\post-commit.hook" `
  -Backup
```

**Full parameter list:**
- `-ProjectRoot` (string)
- `-SourceHook` (string)
- `-Backup` (switch, default: enabled)

---

## Environment Variables

### Advanced Scenarios

```powershell
# 1. Override project root globally
$env:VSCODE_INDEXATION_ROOT = "C:\MyProject"

# 2. Enable verbose logging
$env:VSCODE_INDEXATION_VERBOSE = "1"

# 3. Custom log directory
$env:VSCODE_INDEXATION_LOGDIR = "C:\Logs\Indexation"

# 4. Disable file watcher (CI/CD)
$env:VSCODE_INDEXATION_DISABLE_WATCHER = "1"
```

**Environment variable precedence:**
```
Command-Line Parameters > Environment Variables > Config File > Defaults
```

---

## Multi-Project Configuration

### Scenario: Multiple Git Repositories

**Project structure:**
```
C:\Projects\
├── ProjectA\
│   ├── .vscode-indexation.json
│   └── scripts\
├── ProjectB\
│   ├── .vscode-indexation.json
│   └── scripts\
└── ProjectC\
    ├── .vscode-indexation.json
    └── scripts\
```

**ProjectA config:**
```json
{
  "indexFile": "docs/A_INDEX.md",
  "watchPatterns": ["**/*.md"],
  "scheduledTask": {
    "taskName": "ProjectA_Reindex",
    "executionTime": "03:00"
  }
}
```

**ProjectB config:**
```json
{
  "indexFile": "DOCUMENTATION.md",
  "watchPatterns": ["**/*.rst"],
  "scheduledTask": {
    "taskName": "ProjectB_Reindex",
    "executionTime": "03:30"
  }
}
```

**Install tasks:**
```powershell
# ProjectA
cd C:\Projects\ProjectA
pwsh scripts\CREATE_SCHEDULED_TASK.ps1 -TaskName "ProjectA_Reindex"

# ProjectB
cd C:\Projects\ProjectB
pwsh scripts\CREATE_SCHEDULED_TASK.ps1 -TaskName "ProjectB_Reindex"
```

**Result:** Two independent tasks running at different times.

---

## CI/CD Configuration

### GitHub Actions Example

```yaml
name: Update Documentation Index

on:
  push:
    branches: [main]
    paths:
      - '**.md'
      - '**.rst'

jobs:
  reindex:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install PowerShell
        run: |
          winget install Microsoft.PowerShell
      
      - name: Full Reindex
        run: |
          pwsh scripts/UPDATE_PROJECT_INDEX.ps1 -FullReindex
      
      - name: Commit Index
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add docs/project/INDEX.md
          git diff --cached --quiet || git commit -m "docs: update index [skip ci]"
          git push
```

**Note:** Disable Git hook in CI (it's already in push event).

---

## Performance Tuning

### Large Projects (1000+ files)

```json
{
  "debounceMs": 5000,           // Longer debounce
  "heartbeatIntervalMin": 30,   // Less frequent heartbeat
  "excludePatterns": [
    "**/node_modules/**",
    "**/venv/**",
    "**/build/**",
    "**/dist/**",
    "**/archive/**"            // Exclude large archives
  ],
  "logging": {
    "maxLogSizeMB": 50,         // Larger log files
    "retentionDays": 14         // Shorter retention
  }
}
```

### Small Projects (<100 files)

```json
{
  "debounceMs": 1000,           // Faster response
  "heartbeatIntervalMin": 5,    // More frequent heartbeat
  "logging": {
    "maxLogSizeMB": 5,          // Smaller log files
    "retentionDays": 60         // Longer retention
  }
}
```

---

## Security Considerations

### Sensitive Data Exclusion

```json
{
  "excludePatterns": [
    "**/.env",
    "**/secrets/**",
    "**/credentials/**",
    "**/*.key",
    "**/*.pem"
  ]
}
```

### Scheduled Task Security

**Run as SYSTEM (default):**
- ✅ Runs when logged out
- ✅ No password required
- ⚠️ Full system access (ensure scripts are trusted)

**Run as specific user:**
```powershell
# Edit in Task Scheduler GUI
# Task → Properties → General → Change User/Group
# Select your user account
```

---

## Troubleshooting Configuration

### Validate JSON Syntax

```powershell
# PowerShell validation
Get-Content .vscode-indexation.json | ConvertFrom-Json
# No errors = valid JSON

# Or use online validator
# https://jsonlint.com
```

### Check Effective Configuration

```powershell
# Run with verbose logging
pwsh scripts\UPDATE_PROJECT_INDEX.ps1 -FullReindex -Verbose

# Logs show resolved values:
# [INFO] ProjectRoot: C:\Projects\MyApp
# [INFO] IndexFile: C:\Projects\MyApp\docs\project\INDEX.md
# [INFO] WatchPatterns: *.md, *.rst
# [INFO] ExcludePatterns: node_modules\**, venv\**
```

### Reset to Defaults

```powershell
# Delete config file
Remove-Item .vscode-indexation.json

# Scripts will use auto-detected defaults
pwsh scripts\UPDATE_PROJECT_INDEX.ps1 -FullReindex
```

---

## Next Steps

- ✅ Configuration complete → See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- ✅ Advanced scenarios → See [README.md](README.md) examples
- ✅ Installation guide → See [INSTALL.md](INSTALL.md)

---

**Configuration reference complete! 🎯**

For more examples, see:
- Minimal config: Quick start in [README.md](README.md)
- CI/CD config: GitHub Actions example above
- Multi-project: Enterprise deployment in [README.md](README.md)
