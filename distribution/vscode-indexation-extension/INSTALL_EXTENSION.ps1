# VS Code Indexation Tools Extension
# Installation Script
# Copyright (c) 2025 GateVibe Israel Ltd
# Author: Andrey Grushin

param(
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$BuildVSIX,
    [string]$VSCodePath = "$env:USERPROFILE\.vscode\extensions"
)

$ErrorActionPreference = "Stop"
$ExtensionName = "gatevibe-vscode-indexation-tools-2.0.0"
$ScriptRoot = $PSScriptRoot

function Write-Status {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host "`n$Message" -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Test-Prerequisites {
    Write-Status "Checking prerequisites..."
    
    # Check VS Code
    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
    if (-not $codeCmd) {
        Write-Error-Custom "VS Code not found in PATH"
        return $false
    }
    Write-Success "VS Code found: $($codeCmd.Source)"
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Error-Custom "PowerShell 7+ required (current: $($PSVersionTable.PSVersion))"
        return $false
    }
    Write-Success "PowerShell version: $($PSVersionTable.PSVersion)"
    
    return $true
}

function Copy-Scripts {
    param([string]$TargetPath)
    
    Write-Status "Copying scripts..."
    
    $scriptsSource = Join-Path $ScriptRoot ".." "vscode-indexation-tools" "scripts"
    $scriptsTarget = Join-Path $TargetPath "scripts"
    
    if (-not (Test-Path $scriptsSource)) {
        Write-Error-Custom "Scripts directory not found: $scriptsSource"
        return $false
    }
    
    # Copy scripts
    Copy-Item -Path $scriptsSource -Destination $scriptsTarget -Recurse -Force
    Write-Success "Scripts copied: $(Get-ChildItem $scriptsTarget -Filter *.ps1 | Measure-Object | Select-Object -ExpandProperty Count) files"
    
    # Copy templates
    $templatesSource = Join-Path $ScriptRoot ".." "vscode-indexation-tools" "templates"
    $templatesTarget = Join-Path $TargetPath "templates"
    
    if (Test-Path $templatesSource) {
        Copy-Item -Path $templatesSource -Destination $templatesTarget -Recurse -Force
        Write-Success "Templates copied"
    }
    
    # Copy tests
    $testsSource = Join-Path $ScriptRoot ".." "vscode-indexation-tools" "tests"
    $testsTarget = Join-Path $TargetPath "tests"
    
    if (Test-Path $testsSource) {
        Copy-Item -Path $testsSource -Destination $testsTarget -Recurse -Force
        Write-Success "Tests copied"
    }
    
    return $true
}

function Install-Extension {
    Write-Status "=== Installing VS Code Indexation Tools Extension ===" "Green"
    
    if (-not (Test-Prerequisites)) {
        return
    }
    
    $targetPath = Join-Path $VSCodePath $ExtensionName
    
    # Check if already installed
    if (Test-Path $targetPath) {
        $response = Read-Host "Extension already installed. Overwrite? (y/N)"
        if ($response -ne 'y') {
            Write-Host "Installation cancelled" -ForegroundColor Yellow
            return
        }
        Remove-Item $targetPath -Recurse -Force
    }
    
    # Create extension directory
    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
    Write-Success "Extension directory created: $targetPath"
    
    # Copy core files
    $coreFiles = @(
        "package.json",
        "extension.js",
        "README.md",
        "LICENSE.txt",
        ".vscode-indexation.json"
    )
    
    foreach ($file in $coreFiles) {
        $sourcePath = Join-Path $ScriptRoot $file
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $targetPath -Force
        } else {
            Write-Error-Custom "File not found: $file"
            return
        }
    }
    Write-Success "Core files copied: $($coreFiles.Count) files"
    
    # Copy scripts
    if (-not (Copy-Scripts -TargetPath $targetPath)) {
        return
    }
    
    # Create resources directory (placeholder for icon)
    $resourcesPath = Join-Path $targetPath "resources"
    New-Item -ItemType Directory -Path $resourcesPath -Force | Out-Null
    
    # Create placeholder icon if not exists
    $iconPath = Join-Path $resourcesPath "icon.png"
    if (-not (Test-Path $iconPath)) {
        # Create empty file (VS Code will use default icon)
        New-Item -ItemType File -Path $iconPath -Force | Out-Null
        Write-Host "⚠️ Placeholder icon created (replace with 128x128 PNG)" -ForegroundColor Yellow
    }
    
    Write-Success "Extension installed successfully!"
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Restart VS Code or run: Developer: Reload Window"
    Write-Host "2. Press Ctrl+Shift+P and search for 'Indexation' commands"
    Write-Host "3. Configure via: File → Preferences → Settings → Indexation"
}

function Uninstall-Extension {
    Write-Status "=== Uninstalling VS Code Indexation Tools Extension ===" "Yellow"
    
    $targetPath = Join-Path $VSCodePath $ExtensionName
    
    if (-not (Test-Path $targetPath)) {
        Write-Host "Extension not found at: $targetPath" -ForegroundColor Yellow
        return
    }
    
    Remove-Item $targetPath -Recurse -Force
    Write-Success "Extension uninstalled successfully!"
    Write-Host "Restart VS Code to complete uninstallation" -ForegroundColor Cyan
}

function Build-VSIX {
    Write-Status "=== Building VSIX Package ===" "Green"
    
    # Check npm
    $npmCmd = Get-Command npm -ErrorAction SilentlyContinue
    if (-not $npmCmd) {
        Write-Error-Custom "npm not found. Install Node.js first."
        return
    }
    
    # Check vsce
    $vsceCmd = Get-Command vsce -ErrorAction SilentlyContinue
    if (-not $vsceCmd) {
        Write-Status "Installing vsce..."
        npm install -g vsce
    }
    
    # Install dependencies
    if (Test-Path (Join-Path $ScriptRoot "package.json")) {
        Write-Status "Installing npm dependencies..."
        Push-Location $ScriptRoot
        npm install
        Pop-Location
    }
    
    # Build VSIX
    Write-Status "Building VSIX package..."
    Push-Location $ScriptRoot
    vsce package --out "../vscode-indexation-tools-2.0.0.vsix"
    Pop-Location
    
    $vsixPath = Join-Path $ScriptRoot ".." "vscode-indexation-tools-2.0.0.vsix"
    if (Test-Path $vsixPath) {
        Write-Success "VSIX created: $vsixPath"
        
        $fileSize = (Get-Item $vsixPath).Length / 1KB
        Write-Host "Size: $([math]::Round($fileSize, 2)) KB" -ForegroundColor Cyan
        
        Write-Host "`nInstall with:" -ForegroundColor Cyan
        Write-Host "code --install-extension `"$vsixPath`""
    } else {
        Write-Error-Custom "VSIX build failed"
    }
}

# Main execution
if ($BuildVSIX) {
    Build-VSIX
} elseif ($Uninstall) {
    Uninstall-Extension
} else {
    # Default: Install
    Install-Extension
}
