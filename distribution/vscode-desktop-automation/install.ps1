# Install Desktop Automation Extension to VS Code
# Installs extension in development mode (no packaging required)

param(
    [switch]$Uninstall,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "=== DESKTOP AUTOMATION EXTENSION INSTALLER ===" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

$SourcePath = "E:\WORLD_OLLAMA\distribution\vscode-desktop-automation"
$ExtensionId = "worldollama.vscode-desktop-automation-1.0.0"
$TargetPath = "$env:USERPROFILE\.vscode\extensions\$ExtensionId"

if ($Uninstall) {
    Write-Host "🗑️ UNINSTALL MODE" -ForegroundColor Yellow
    if (Test-Path $TargetPath) {
        Write-Host "Removing: $TargetPath"
        Remove-Item -Recurse -Force $TargetPath
        Write-Host "✅ Extension uninstalled successfully`n" -ForegroundColor Green
        Write-Host "⚠️ Reload VS Code to complete uninstallation" -ForegroundColor Yellow
    } else {
        Write-Host "Extension not found: $TargetPath" -ForegroundColor Yellow
    }
    exit 0
}

# Check if already installed
if (Test-Path $TargetPath) {
    if ($Force) {
        Write-Host "⚠️ Extension already installed - removing old version" -ForegroundColor Yellow
        Remove-Item -Recurse -Force $TargetPath
    } else {
        Write-Host "❌ Extension already installed at: $TargetPath" -ForegroundColor Red
        Write-Host "Use -Force to reinstall or -Uninstall to remove`n" -ForegroundColor Yellow
        exit 1
    }
}

# Validate source
if (-not (Test-Path $SourcePath)) {
    Write-Host "❌ Source not found: $SourcePath" -ForegroundColor Red
    exit 1
}

Write-Host "📦 Installing extension..." -ForegroundColor Cyan
Write-Host "  Source: $SourcePath"
Write-Host "  Target: $TargetPath`n"

# Copy extension
try {
    Copy-Item -Recurse -Force $SourcePath $TargetPath
    Write-Host "✅ Extension files copied successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to copy extension: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verify installation
Write-Host "`n📋 Verification:" -ForegroundColor Cyan
$requiredFiles = @(
    "package.json",
    "extension.js",
    "README.md"
)

$allFilesPresent = $true
foreach ($file in $requiredFiles) {
    $filePath = Join-Path $TargetPath $file
    if (Test-Path $filePath) {
        Write-Host "  ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Missing: $file" -ForegroundColor Red
        $allFilesPresent = $false
    }
}

if (-not $allFilesPresent) {
    Write-Host "`n❌ Installation verification failed" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "`n📌 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Reload VS Code: Ctrl+Shift+P → 'Developer: Reload Window'"
Write-Host "  2. Open Command Palette: Ctrl+Shift+P"
Write-Host "  3. Type: 'Automation' to see available commands"
Write-Host "  4. Check extensions: Ctrl+Shift+X → Search 'Desktop Automation'`n"

Write-Host "🧪 Test command:" -ForegroundColor Yellow
Write-Host "  Automation: Get Screen State`n"

exit 0
