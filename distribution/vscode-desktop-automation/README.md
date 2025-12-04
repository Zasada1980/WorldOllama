# Desktop Automation Tools for VS Code

**Version:** 1.0.0  
**Project:** WORLD_OLLAMA  
**Status:** ✅ READY FOR USE

## 📋 Description

VS Code extension for Desktop Automation Tools - provides UI automation commands via PowerShell bridge to Tauri automation modules built in ЭТАП 0-2.

**Key Features:**
- 🖥️ Get screen state (monitors, resolutions)
- 📸 Capture screenshots (PNG)
- 🖱️ Click simulation (x, y coordinates)
- ⌨️ Keyboard simulation (type text)
- 🪟 Get active windows (placeholder in ЭТАП 2)
- 🧪 Run test scenarios (ЭТАП 1-2 integration tests)

## 🚀 Installation

### Method 1: Install from VSIX (Recommended)

1. Package the extension:
```powershell
cd distribution/vscode-desktop-automation
npm install
vsce package
```

2. Install in VS Code:
```powershell
code --install-extension vscode-desktop-automation-1.0.0.vsix
```

### Method 2: Development Mode

1. Copy extension to VS Code extensions folder:
```powershell
$ExtPath = "$env:USERPROFILE\.vscode\extensions\worldollama.vscode-desktop-automation-1.0.0"
Copy-Item -Recurse distribution/vscode-desktop-automation $ExtPath
```

2. Reload VS Code: `Ctrl+Shift+P` → "Developer: Reload Window"

## 🎯 Commands

Open Command Palette (`Ctrl+Shift+P`) and type "Automation":

| Command | Description |
|---------|-------------|
| **Automation: Get Screen State** | Retrieve monitor information |
| **Automation: Capture Screenshot** | Take screenshot of monitor |
| **Automation: Click at Coordinates** | Simulate mouse click (x, y) |
| **Automation: Type Text** | Simulate keyboard input |
| **Automation: Get Active Windows** | List active windows (placeholder) |
| **Automation: Run Test Scenario** | Execute ЭТАП 1-2 tests |
| **Automation: Show Logs** | Open output channel |
| **Automation: Open Configuration** | Open extension settings |

## ⚙️ Configuration

Open Settings (`Ctrl+,`) → Search "automation":

```json
{
  "automation.tauriAppPath": "",              // Path to Tauri executable (auto-detect)
  "automation.defaultMonitor": 0,             // Primary monitor index
  "automation.clickDelay": 500,               // Delay after click (ms)
  "automation.screenshotsPath": "automation/screenshots",
  "automation.logLevel": "info",              // debug|info|warn|error
  "automation.autoStartTauri": false          // Auto-start Tauri on activation
}
```

## 📖 Usage Examples

### Example 1: Get Screen State
1. Open Command Palette: `Ctrl+Shift+P`
2. Type: `Automation: Get Screen State`
3. Check Output channel for monitor info

### Example 2: Capture Screenshot
1. Configure default monitor: Settings → `automation.defaultMonitor`
2. Run: `Automation: Capture Screenshot`
3. Check logs for result

### Example 3: Run Test Scenario
1. Run: `Automation: Run Test Scenario`
2. Select: "ЭТАП 2: E2E Tests"
3. Wait for completion (~5s)

### Example 4: Click Simulation
1. Run: `Automation: Click at Coordinates`
2. Enter X: `850`
3. Enter Y: `450`
4. (Requires Tauri app running)

## 🧪 Testing

**Built-in test scenarios:**
- **ЭТАП 1: Integration Tests** - 5 crate tests
- **ЭТАП 2: E2E Tests** - 6 integration tests
- **ЭТАП 2: Simple Scenario** - Basic validation

**Run tests:**
```powershell
# From workspace root
pwsh client/test_stage1_automation.ps1  # ЭТАП 1
pwsh client/test_stage2_e2e.ps1         # ЭТАП 2 E2E
pwsh client/test_stage2_scenario.ps1    # ЭТАП 2 Simple
```

## ⚠️ Requirements

1. **VS Code** ≥ 1.80.0
2. **PowerShell** 7+ (pwsh.exe)
3. **Workspace:** WORLD_OLLAMA project
4. **Tauri app** (optional, for live commands)

**Dependencies:**
- Node.js (for extension development)
- VSCE (for packaging): `npm install -g vsce`

## 🔧 Troubleshooting

### Extension not showing in Command Palette
- Reload window: `Ctrl+Shift+P` → "Developer: Reload Window"
- Check extensions: `Ctrl+Shift+X` → Search "Desktop Automation"

### "Test script not found" error
- Ensure workspace is WORLD_OLLAMA root
- Check paths: `client/test_stage*.ps1` exist

### Commands require Tauri app
- Live commands (click, type, screenshot) need Tauri running
- Test scenarios work without Tauri (PowerShell validation)

### PowerShell errors
- Ensure PowerShell 7+ installed: `pwsh --version`
- Check execution policy: `Get-ExecutionPolicy` (should be RemoteSigned)

## 📊 Architecture

**Extension Flow:**
```
VS Code Command → extension.js
  ↓
PowerShell Bridge (executePowerShell)
  ↓
Test Scripts (test_stage*.ps1)
  ↓
Tauri Commands (client/src-tauri/src/automation_commands.rs)
  ↓
Automation Modules (executor.rs, mod.rs, etc.)
```

**Key Files:**
- `extension.js` - Main extension logic
- `package.json` - Manifest (commands, config, activation)
- `resources/icon.png` - Extension icon

## 🗺️ Roadmap

**Current Version: 1.0.0 (ЭТАП 2 Integration)**
- ✅ 8 commands registered
- ✅ PowerShell bridge
- ✅ Test scenario runner
- ✅ Configuration support

**Future Versions:**
- **v1.1 (ЭТАП 3):** MCP Server integration
- **v1.2 (ЭТАП 3):** WinAPI full windows list
- **v2.0 (ЭТАП 4):** CI/CD automation, visual regression

## 📄 License

MIT License - See project root LICENSE file

## 👥 Author

**WORLD_OLLAMA Project**  
GitHub: https://github.com/Zasada1980/WorldOllama

---

**Related Documentation:**
- Desktop Automation: `.github/copilot-instructions.md` (line 271+)
- STAGE2 Report: `docs/automation/STAGE2_COMPLETION_REPORT.md`
- Roadmap: `docs/automation/FULL_AUTOMATION_ROADMAP.md`
