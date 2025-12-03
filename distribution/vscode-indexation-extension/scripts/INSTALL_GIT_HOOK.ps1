<#
.SYNOPSIS
    Universal Git post-commit hook installer for VS Code indexing

.DESCRIPTION
    Copies post-commit.hook to .git/hooks/post-commit and makes it executable
    Supports custom project paths and hook templates

.PARAMETER ProjectRoot
    Project root directory (default: script directory parent)

.PARAMETER SourceHook
    Source hook file path (default: scripts/post-commit.hook)

.PARAMETER Backup
    Create backup of existing hook (default: true)

.EXAMPLE
    .\INSTALL_GIT_HOOK.ps1
    Install with defaults

.EXAMPLE
    .\INSTALL_GIT_HOOK.ps1 -ProjectRoot "C:\MyProject"
    Install for custom project

.EXAMPLE
    .\INSTALL_GIT_HOOK.ps1 -Backup:$false
    Install without backup

.NOTES
    Version: 2.0
    Author: GitHub Copilot Agent
    Date: December 3, 2025
    License: MIT
#>

param(
    [string]$ProjectRoot = "",
    [string]$SourceHook = "",
    [switch]$Backup = $true
)

$ErrorActionPreference = "Stop"

# Auto-detect project root if not specified
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}

# Default source hook path
if ([string]::IsNullOrWhiteSpace($SourceHook)) {
    $SourceHook = Join-Path (Join-Path $ProjectRoot "scripts") "post-commit.hook"
}

$TargetHook = Join-Path $ProjectRoot ".git\hooks\post-commit"

Write-Host "`n🔧 GIT POST-COMMIT HOOK INSTALLER`n" -ForegroundColor Cyan
Write-Host "Project root: $ProjectRoot" -ForegroundColor Gray
Write-Host "Source hook: $SourceHook" -ForegroundColor Gray
Write-Host "Target hook: $TargetHook`n" -ForegroundColor Gray

# Check source file exists
if (-not (Test-Path $SourceHook)) {
    Write-Host "❌ ERROR: Source hook file not found: $SourceHook" -ForegroundColor Red
    Write-Host "`nPlease ensure post-commit.hook exists in scripts/ directory`n" -ForegroundColor Yellow
    exit 1
}

# Check .git directory exists
if (-not (Test-Path (Join-Path $ProjectRoot ".git"))) {
    Write-Host "❌ ERROR: .git directory not found in $ProjectRoot" -ForegroundColor Red
    Write-Host "   Ensure this script runs from a Git repository root`n" -ForegroundColor Yellow
    exit 1
}

# Create hooks directory if missing
$hooksDir = Join-Path $ProjectRoot ".git\hooks"
if (-not (Test-Path $hooksDir)) {
    Write-Host "📁 Creating hooks directory..." -ForegroundColor Gray
    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
}

# Backup existing hook
if ($Backup -and (Test-Path $TargetHook)) {
    $backupFile = "$TargetHook.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Host "💾 Backing up existing hook: $backupFile" -ForegroundColor Yellow
    Copy-Item $TargetHook $backupFile -Force
}

# Copy hook
Write-Host "📋 Installing hook..." -ForegroundColor Gray
Copy-Item $SourceHook $TargetHook -Force

# Make executable (for Git Bash on Windows)
try {
    $gitExe = (Get-Command git -ErrorAction SilentlyContinue).Source
    if ($gitExe) {
        & git update-index --chmod=+x .git/hooks/post-commit 2>$null
        Write-Host "✅ Set executable bit (Git)" -ForegroundColor Green
    }
}
catch {
    Write-Host "⚠️  Could not set executable bit via Git (may be ignored on Windows)" -ForegroundColor Yellow
}

# Verify hook content
$hookContent = Get-Content $TargetHook -Raw
if ($hookContent -match 'UPDATE_PROJECT_INDEX\.ps1') {
    Write-Host "✅ Hook references UPDATE_PROJECT_INDEX.ps1" -ForegroundColor Green
} else {
    Write-Host "⚠️  WARNING: Hook does not reference expected script" -ForegroundColor Yellow
}

Write-Host "`n✅ GIT HOOK INSTALLED SUCCESSFULLY`n" -ForegroundColor Green
Write-Host "The hook will automatically trigger reindexing after commits with file changes" -ForegroundColor White
Write-Host "(matches patterns configured in UPDATE_PROJECT_INDEX.ps1)`n" -ForegroundColor White

Write-Host "Test the hook with a commit:" -ForegroundColor Cyan
Write-Host "  git add README.md" -ForegroundColor Gray
Write-Host "  git commit -m 'test: verify post-commit hook'" -ForegroundColor Gray
Write-Host "  # Check logs/indexation.log for reindex entry`n" -ForegroundColor Gray

exit 0
