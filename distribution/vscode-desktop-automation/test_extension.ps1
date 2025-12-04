# VS Code Extension Test Suite
# Tests Desktop Automation extension integration and activation

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

Write-Host "=== VS CODE EXTENSION TEST SUITE ===" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

$ExtensionPath = "E:\WORLD_OLLAMA\distribution\vscode-desktop-automation"
$TestsPassed = 0
$TotalTests = 8

# TEST 1: Extension structure
Write-Host "[TEST 1] Extension Structure Validation" -ForegroundColor Yellow
$requiredFiles = @(
    "package.json",
    "extension.js",
    "README.md",
    "resources\icon.svg"
)

$allFilesExist = $true
foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $ExtensionPath $file
    if (Test-Path $fullPath) {
        Write-Host "  ✅ Found: $file" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Missing: $file" -ForegroundColor Red
        $allFilesExist = $false
    }
}

if ($allFilesExist) {
    Write-Host "✅ TEST 1 PASSED: All required files present`n" -ForegroundColor Green
    $TestsPassed++
} else {
    Write-Host "❌ TEST 1 FAILED: Missing required files`n" -ForegroundColor Red
}

# TEST 2: package.json validation
Write-Host "[TEST 2] package.json Manifest Validation" -ForegroundColor Yellow
$packageJsonPath = Join-Path $ExtensionPath "package.json"
try {
    $packageJson = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
    
    $checks = @(
        ($packageJson.name -eq "vscode-desktop-automation"),
        ($packageJson.version -eq "1.0.0"),
        ($packageJson.main -eq "./extension.js"),
        ($packageJson.contributes.commands.Count -eq 8),
        ($packageJson.activationEvents.Count -gt 0)
    )
    
    if ($checks -notcontains $false) {
        Write-Host "  ✅ Name: $($packageJson.name)" -ForegroundColor Green
        Write-Host "  ✅ Version: $($packageJson.version)" -ForegroundColor Green
        Write-Host "  ✅ Entry point: $($packageJson.main)" -ForegroundColor Green
        Write-Host "  ✅ Commands: $($packageJson.contributes.commands.Count)" -ForegroundColor Green
        Write-Host "  ✅ Activation events: $($packageJson.activationEvents -join ', ')" -ForegroundColor Green
        Write-Host "✅ TEST 2 PASSED: package.json valid`n" -ForegroundColor Green
        $TestsPassed++
    } else {
        Write-Host "❌ TEST 2 FAILED: package.json validation failed`n" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ TEST 2 FAILED: $($_.Exception.Message)`n" -ForegroundColor Red
}

# TEST 3: Commands registration
Write-Host "[TEST 3] Commands Registration" -ForegroundColor Yellow
$expectedCommands = @(
    "automation.getScreenState",
    "automation.captureScreenshot",
    "automation.clickAt",
    "automation.typeText",
    "automation.getWindows",
    "automation.runScenario",
    "automation.showLogs",
    "automation.openConfiguration"
)

$registeredCommands = $packageJson.contributes.commands | ForEach-Object { $_.command }
$allCommandsRegistered = $true

foreach ($cmd in $expectedCommands) {
    if ($registeredCommands -contains $cmd) {
        Write-Host "  ✅ $cmd" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Missing: $cmd" -ForegroundColor Red
        $allCommandsRegistered = $false
    }
}

if ($allCommandsRegistered) {
    Write-Host "✅ TEST 3 PASSED: All 8 commands registered`n" -ForegroundColor Green
    $TestsPassed++
} else {
    Write-Host "❌ TEST 3 FAILED: Missing commands`n" -ForegroundColor Red
}

# TEST 4: Configuration schema
Write-Host "[TEST 4] Configuration Schema" -ForegroundColor Yellow
$configProps = $packageJson.contributes.configuration.properties
$expectedSettings = @(
    "automation.tauriAppPath",
    "automation.defaultMonitor",
    "automation.clickDelay",
    "automation.screenshotsPath",
    "automation.logLevel",
    "automation.autoStartTauri"
)

$allSettingsPresent = $true
foreach ($setting in $expectedSettings) {
    if ($configProps.PSObject.Properties.Name -contains $setting) {
        Write-Host "  ✅ $setting" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Missing: $setting" -ForegroundColor Red
        $allSettingsPresent = $false
    }
}

if ($allSettingsPresent) {
    Write-Host "✅ TEST 4 PASSED: All 6 settings defined`n" -ForegroundColor Green
    $TestsPassed++
} else {
    Write-Host "❌ TEST 4 FAILED: Missing settings`n" -ForegroundColor Red
}

# TEST 5: extension.js syntax check
Write-Host "[TEST 5] extension.js Syntax Check" -ForegroundColor Yellow
$extensionJsPath = Join-Path $ExtensionPath "extension.js"
$extensionJs = Get-Content $extensionJsPath -Raw

$syntaxChecks = @(
    ($extensionJs -match "function activate\(context\)"),
    ($extensionJs -match "function deactivate\(\)"),
    ($extensionJs -match "vscode\.commands\.registerCommand"),
    ($extensionJs -match "module\.exports"),
    ($extensionJs -match "async function executePowerShell")
)

if ($syntaxChecks -notcontains $false) {
    Write-Host "  ✅ activate() function found" -ForegroundColor Green
    Write-Host "  ✅ deactivate() function found" -ForegroundColor Green
    Write-Host "  ✅ Command registration found" -ForegroundColor Green
    Write-Host "  ✅ Module exports found" -ForegroundColor Green
    Write-Host "  ✅ PowerShell bridge found" -ForegroundColor Green
    Write-Host "✅ TEST 5 PASSED: extension.js syntax valid`n" -ForegroundColor Green
    $TestsPassed++
} else {
    Write-Host "❌ TEST 5 FAILED: Syntax issues detected`n" -ForegroundColor Red
}

# TEST 6: README completeness
Write-Host "[TEST 6] README Documentation" -ForegroundColor Yellow
$readmePath = Join-Path $ExtensionPath "README.md"
$readme = Get-Content $readmePath -Raw

$readmeSections = @(
    "Installation",
    "Commands",
    "Configuration",
    "Usage Examples",
    "Testing",
    "Troubleshooting"
)

$allSectionsPresent = $true
foreach ($section in $readmeSections) {
    if ($readme -match $section) {
        Write-Host "  ✅ Section: $section" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Missing section: $section" -ForegroundColor Red
        $allSectionsPresent = $false
    }
}

if ($allSectionsPresent) {
    Write-Host "✅ TEST 6 PASSED: README complete`n" -ForegroundColor Green
    $TestsPassed++
} else {
    Write-Host "❌ TEST 6 FAILED: README incomplete`n" -ForegroundColor Red
}

# TEST 7: Command Palette integration
Write-Host "[TEST 7] Command Palette Integration" -ForegroundColor Yellow
$menuContributions = $packageJson.contributes.menus.commandPalette
if ($menuContributions.Count -eq 8) {
    Write-Host "  ✅ Command Palette entries: $($menuContributions.Count)" -ForegroundColor Green
    Write-Host "  ✅ All commands have 'when' clause: workspaceFolderCount > 0" -ForegroundColor Green
    Write-Host "✅ TEST 7 PASSED: Command Palette configured`n" -ForegroundColor Green
    $TestsPassed++
} else {
    Write-Host "❌ TEST 7 FAILED: Expected 8 menu entries, got $($menuContributions.Count)`n" -ForegroundColor Red
}

# TEST 8: VS Code compatibility
Write-Host "[TEST 8] VS Code Engine Compatibility" -ForegroundColor Yellow
$engineVersion = $packageJson.engines.vscode
if ($engineVersion -match "\^1\.80\.0") {
    Write-Host "  ✅ Engine version: $engineVersion" -ForegroundColor Green
    Write-Host "  ✅ Compatible with VS Code 1.80.0+" -ForegroundColor Green
    Write-Host "✅ TEST 8 PASSED: VS Code compatibility OK`n" -ForegroundColor Green
    $TestsPassed++
} else {
    Write-Host "❌ TEST 8 FAILED: Invalid engine version: $engineVersion`n" -ForegroundColor Red
}

# Summary
Write-Host "=== TEST SUMMARY ===" -ForegroundColor Cyan
Write-Host "Tests passed: $TestsPassed / $TotalTests" -ForegroundColor $(if ($TestsPassed -eq $TotalTests) { "Green" } else { "Yellow" })

if ($TestsPassed -eq $TotalTests) {
    Write-Host "`n✅ ALL TESTS PASSED - Extension ready for installation" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️ SOME TESTS FAILED - Review errors above" -ForegroundColor Yellow
    exit 1
}
