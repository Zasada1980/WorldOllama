# VS Code Indexation Tools Extension v2.0.0

**Distribution Package Summary**

## Package Information

- **Name:** vscode-indexation-tools
- **Version:** 2.0.0
- **Type:** VS Code Extension (VSIX)
- **Publisher:** GateVibe Israel Ltd
- **Developer:** Andrey Grushin
- **License:** MIT
- **Release Date:** December 3, 2025

## Installation Methods

### Method 1: PowerShell Installer (Recommended)

```powershell
pwsh -File INSTALL_EXTENSION.ps1
```

**Features:**
- Automatic prerequisite checks (VS Code, PowerShell 7+)
- Copies all scripts, templates, and tests
- Creates extension directory structure
- Provides post-installation instructions

### Method 2: Manual Installation

```powershell
$extensionsPath = "$env:USERPROFILE\.vscode\extensions"
Copy-Item -Path "vscode-indexation-extension" -Destination "$extensionsPath\gatevibe-vscode-indexation-tools-2.0.0" -Recurse
```

Restart VS Code after installation.

### Method 3: Build and Install VSIX

```powershell
# Build VSIX package
pwsh -File INSTALL_EXTENSION.ps1 -BuildVSIX

# Install VSIX
code --install-extension vscode-indexation-tools-2.0.0.vsix
```

## Extension Structure

```
vscode-indexation-extension/
├── package.json              # Extension manifest
├── extension.js              # Main extension logic (450 lines)
├── README.md                 # User documentation
├── LICENSE.txt               # MIT License
├── INSTALL_EXTENSION.ps1     # Installation script
├── .vscode-indexation.json   # Configuration template
├── .vscodeignore             # VSIX packaging exclusions
├── scripts/                  # PowerShell automation scripts
│   ├── UPDATE_PROJECT_INDEX.ps1
│   ├── WATCH_FILE_CHANGES.ps1
│   ├── INSTALL_GIT_HOOK.ps1
│   ├── CREATE_SCHEDULED_TASK.ps1
│   └── post-commit.hook
├── templates/
│   ├── PROJECT_INDEX_TEMPLATE.md
│   └── .vscode-indexation.json
└── tests/
    ├── test_incremental.ps1
    ├── test_full_reindex.ps1
    └── test_integration.ps1
```

## Global Commands (10)

All available via **Ctrl+Shift+P**:

| Command | Shortcut | Description |
|---------|----------|-------------|
| `Indexation: Full Reindex` | — | Rebuild entire documentation index |
| `Indexation: Incremental Update` | — | Update index for current file |
| `Indexation: Start File Watcher` | — | Monitor file changes in real-time |
| `Indexation: Stop File Watcher` | — | Stop file monitoring |
| `Indexation: Install Git Post-Commit Hook` | — | Auto-reindex after Git commits |
| `Indexation: Create Scheduled Task` | — | Daily automatic reindex (Windows Task Scheduler) |
| `Indexation: Remove Scheduled Task` | — | Remove scheduled task |
| `Indexation: Show Logs` | — | Open `logs/indexation.log` |
| `Indexation: Run Tests` | — | Execute test suite |
| `Indexation: Open Configuration File` | — | Edit `.vscode-indexation.json` |

## Configuration Settings

Access via **File → Preferences → Settings** → Search "indexation":

```json
{
  "indexation.scriptsPath": "",
  "indexation.indexFile": "docs/project/RUNTIME_LOGS_JOURNAL_INDEX.md",
  "indexation.filePatterns": ["*.md", "*.rst", "*.adoc"],
  "indexation.excludePaths": ["node_modules", ".git", "venv"],
  "indexation.autoWatch": false,
  "indexation.notifyOnUpdate": true
}
```

### Auto-Detection Logic

1. Check `indexation.scriptsPath` setting (if configured)
2. Fallback to `<extension>/scripts/` (embedded scripts)
3. Fallback to `<workspace>/scripts/` (workspace scripts)

## Key Features

✅ **Global Availability** — Commands work in any workspace  
✅ **Auto-Detection** — Automatically finds scripts or uses embedded versions  
✅ **Real-time Monitoring** — FileSystemWatcher with 2s debounce  
✅ **Multi-Mechanism** — File watcher + Git hooks + Task Scheduler  
✅ **Configurable** — VS Code settings integration  
✅ **Extensible** — Supports custom file patterns (*.md, *.rst, *.adoc)  
✅ **Logging** — Comprehensive logs in Output channel  
✅ **Testing** — Integrated test suite (3 test scripts)  

## Technical Details

### Extension Metadata (package.json)

- **Activation:** `onStartupFinished` (loads after VS Code startup)
- **VS Code Version:** Requires 1.80.0+
- **Categories:** Other, Snippets
- **Main Entry:** `extension.js`
- **Commands:** 10 registered commands
- **Configuration:** 6 user settings

### Extension Logic (extension.js)

- **Size:** ~450 lines
- **Dependencies:** vscode, path, fs, child_process
- **Output Channel:** `Indexation Tools`
- **Watcher:** Persistent background process
- **PowerShell:** Executes via `pwsh -NoProfile -ExecutionPolicy Bypass`

### Scripts (Embedded)

- **UPDATE_PROJECT_INDEX.ps1** (220 lines) — Core reindexing logic
- **WATCH_FILE_CHANGES.ps1** (280 lines) — FileSystemWatcher with thread-safe debounce
- **INSTALL_GIT_HOOK.ps1** (100 lines) — Git hook installer
- **CREATE_SCHEDULED_TASK.ps1** (150 lines) — Task Scheduler integration
- **post-commit.hook** (45 lines) — Git hook template

## Usage Workflow

### Initial Setup

1. **Install Extension:**
   ```powershell
   pwsh -File INSTALL_EXTENSION.ps1
   ```

2. **Restart VS Code:**
   ```
   Ctrl+Shift+P → Developer: Reload Window
   ```

3. **Run Full Reindex:**
   ```
   Ctrl+Shift+P → Indexation: Full Reindex
   ```

### Enable Auto-Updates

1. **Start File Watcher:**
   ```
   Ctrl+Shift+P → Indexation: Start File Watcher
   ```

2. **Install Git Hook:**
   ```
   Ctrl+Shift+P → Indexation: Install Git Post-Commit Hook
   ```

3. **Create Scheduled Task (Optional):**
   ```
   Ctrl+Shift+P → Indexation: Create Scheduled Task
   Enter time: 03:00
   ```

### Daily Usage

- **Edit Documentation** → Auto-updates via file watcher
- **Git Commit** → Auto-reindex via post-commit hook
- **Manual Update:** `Ctrl+Shift+P → Indexation: Incremental Update`

## Persistence Guarantee

✅ **Global Installation** — Extension installed to `%USERPROFILE%\.vscode\extensions\`  
✅ **Works Across Workspaces** — Commands available in any project  
✅ **Survives VS Code Updates** — User extensions directory preserved  
✅ **No Workspace Dependencies** — No `.vscode/tasks.json` required  

**User Requirement Met:**  
_"При смене рабочей среды инструмент не пропадет и останется внутри консоли"_ ✅

## Testing

### Run All Tests

```
Ctrl+Shift+P → Indexation: Run Tests
Select: test_integration.ps1
```

### Manual Testing

```powershell
# From extension directory
pwsh tests\test_incremental.ps1
pwsh tests\test_full_reindex.ps1
pwsh tests\test_integration.ps1
```

## Troubleshooting

### Commands Not Appearing

- Ensure workspace is open (`workspaceFolderCount > 0`)
- Reload window: `Ctrl+Shift+P → Developer: Reload Window`

### Scripts Not Found

1. Check **Output → Indexation Tools** for errors
2. Set `indexation.scriptsPath` manually in settings
3. Verify scripts exist in extension directory

### Permission Errors (Scheduled Task)

- Run VS Code as Administrator
- Or use Task Scheduler GUI manually

## Distribution Contents

```
vscode-indexation-extension/
├── Core Files (6 files, ~25 KB)
│   ├── package.json (3.8 KB)
│   ├── extension.js (14.5 KB)
│   ├── README.md (5.2 KB)
│   ├── LICENSE.txt (1.7 KB)
│   ├── INSTALL_EXTENSION.ps1 (6.9 KB)
│   └── .vscode-indexation.json (1.2 KB)
├── Scripts (5 files, ~29 KB)
├── Templates (2 files, ~7.5 KB)
└── Tests (3 files, ~25 KB)

Total: ~87 KB uncompressed
Expected VSIX: ~30 KB (35% compression)
```

## Build VSIX Package

```powershell
# Install vsce (if not installed)
npm install -g vsce

# Build VSIX
pwsh -File INSTALL_EXTENSION.ps1 -BuildVSIX

# Output: vscode-indexation-tools-2.0.0.vsix (~30 KB)
```

## Uninstallation

```powershell
# Option 1: PowerShell script
pwsh -File INSTALL_EXTENSION.ps1 -Uninstall

# Option 2: VS Code UI
Extensions → Indexation Tools → Uninstall

# Option 3: Manual
Remove-Item "$env:USERPROFILE\.vscode\extensions\gatevibe-vscode-indexation-tools-2.0.0" -Recurse
```

## Support

- **Documentation:** See `README.md` in extension directory
- **Issues:** Check **Output → Indexation Tools** channel
- **Logs:** `logs/indexation.log` in workspace
- **Contact:** support@gatevibe.com

## Credits

**Developed by:** Andrey Grushin  
**Company:** GateVibe Israel Ltd  
**License:** MIT  
**Repository:** https://github.com/GateVibeIsrael/vscode-indexation-tools

## Changelog

### 2.0.0 (2025-12-03)

- ✨ Initial release as VS Code extension
- ✅ 10 global commands
- ✅ Auto-detection of scripts
- ✅ Configurable via VS Code settings
- ✅ Real-time file watcher
- ✅ Git hooks integration
- ✅ Windows Task Scheduler support
- ✅ Comprehensive logging
- ✅ Test suite integration
- ✅ PowerShell installer
- ✅ VSIX build support

---

**End of Distribution Package Summary**
