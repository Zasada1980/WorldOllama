# VS Code Indexation Tools Extension

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

Automatic documentation indexation extension for VS Code. Provides global commands for managing project documentation indices across any workspace.

## Features

✅ **Global Commands** — Available in any workspace through Command Palette  
✅ **10 Automation Commands** — Full reindex, incremental updates, file watcher, Git hooks, scheduled tasks  
✅ **Auto-Detection** — Automatically finds scripts or uses embedded versions  
✅ **Real-time Monitoring** — FileSystemWatcher with debounce and exclusions  
✅ **Multi-Mechanism** — Combines file watching, Git hooks, and Task Scheduler  
✅ **Configurable** — VS Code settings integration for patterns, paths, exclusions  

## Installation

### Option 1: From VSIX (Recommended)

1. Download `vscode-indexation-tools-2.0.0.vsix`
2. Open VS Code
3. Press `Ctrl+Shift+P` and run: `Extensions: Install from VSIX...`
4. Select downloaded VSIX file
5. Restart VS Code

### Option 2: PowerShell Installer

```powershell
pwsh -File INSTALL_EXTENSION.ps1
```

### Option 3: Manual Installation

```powershell
# Copy to VS Code extensions directory
$extensionsPath = "$env:USERPROFILE\.vscode\extensions"
Copy-Item -Path "vscode-indexation-extension" -Destination "$extensionsPath\gatevibe-vscode-indexation-tools-2.0.0" -Recurse
```

## Commands

All commands available via `Ctrl+Shift+P`:

| Command | Description |
|---------|-------------|
| `Indexation: Full Reindex` | Rebuild entire index from scratch |
| `Indexation: Incremental Update` | Update index for current file |
| `Indexation: Start File Watcher` | Monitor file changes in real-time |
| `Indexation: Stop File Watcher` | Stop file monitoring |
| `Indexation: Install Git Post-Commit Hook` | Auto-reindex after commits |
| `Indexation: Create Scheduled Task` | Daily automatic reindex |
| `Indexation: Remove Scheduled Task` | Remove scheduled task |
| `Indexation: Show Logs` | Open indexation logs |
| `Indexation: Run Tests` | Execute test suite |
| `Indexation: Open Configuration File` | Edit `.vscode-indexation.json` |

## Configuration

Access via **File → Preferences → Settings** → Search "indexation":

```json
{
  "indexation.scriptsPath": "",
  "indexation.indexFile": "docs/project/RUNTIME_LOGS_JOURNAL_INDEX.md",
  "indexation.filePatterns": ["*.md", "*.rst", "*.adoc"],
  "indexation.excludePaths": [
    "node_modules",
    ".git",
    "venv",
    "__pycache__"
  ],
  "indexation.autoWatch": false,
  "indexation.notifyOnUpdate": true
}
```

### Settings Reference

- **scriptsPath** — Custom scripts location (auto-detected if empty)
- **indexFile** — Relative path to index file from workspace root
- **filePatterns** — File patterns to monitor (supports wildcards)
- **excludePaths** — Directories to ignore
- **autoWatch** — Start file watcher automatically on workspace open
- **notifyOnUpdate** — Show notifications after index updates

## Usage Examples

### Basic Workflow

1. **Initial Setup:**
   ```
   Ctrl+Shift+P → Indexation: Full Reindex
   ```

2. **Enable Auto-Updates:**
   ```
   Ctrl+Shift+P → Indexation: Install Git Post-Commit Hook
   Ctrl+Shift+P → Indexation: Start File Watcher
   ```

3. **Optional Daily Safety Net:**
   ```
   Ctrl+Shift+P → Indexation: Create Scheduled Task
   Enter time: 03:00
   ```

### Manual Update

```
Edit documentation file → Save
Ctrl+Shift+P → Indexation: Incremental Update
```

### Check Status

```
Ctrl+Shift+P → Indexation: Show Logs
View Output → Indexation Tools channel
```

## Architecture

```
Extension (extension.js)
  ↓ detects
Scripts Directory
  ├── UPDATE_PROJECT_INDEX.ps1
  ├── WATCH_FILE_CHANGES.ps1
  ├── INSTALL_GIT_HOOK.ps1
  └── CREATE_SCHEDULED_TASK.ps1
  ↓ updates
Index File (*.md)
```

**Auto-Detection Logic:**
1. Check `indexation.scriptsPath` setting
2. Fallback to `<extension>/scripts/`
3. Fallback to `<workspace>/scripts/`

## Requirements

- **VS Code:** 1.80.0 or higher
- **PowerShell:** 7.0+ (pwsh)
- **OS:** Windows (PowerShell scripts)
- **Disk Space:** ~500 KB

## Troubleshooting

### Commands Not Appearing

- Ensure workspace is open (`workspaceFolderCount > 0`)
- Reload window: `Ctrl+Shift+P → Developer: Reload Window`

### Scripts Not Found

1. Check **Output → Indexation Tools** for errors
2. Set `indexation.scriptsPath` manually:
   ```json
   {
     "indexation.scriptsPath": "E:\\path\\to\\scripts"
   }
   ```

### File Watcher Not Working

- Check exclusion patterns in settings
- Verify `logs/file_watcher.log` for errors
- Restart watcher: Stop → Start

### Permission Errors (Scheduled Task)

- Run VS Code as Administrator for task creation
- Or use Task Scheduler GUI manually

## Development

### Building VSIX

```powershell
npm install
npm run package
# Creates: vscode-indexation-tools-2.0.0.vsix
```

### Testing

```powershell
# Install in development mode
code --install-extension vscode-indexation-tools-2.0.0.vsix

# View logs
code --log-level trace
```

## License

MIT License

Copyright (c) 2025 GateVibe Israel Ltd

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Credits

**Developed by:** Andrey Grushin  
**Company:** GateVibe Israel Ltd  
**Support:** support@gatevibe.com

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
