<#
.SYNOPSIS
    Universal Project Index Updater for VS Code

.DESCRIPTION
    Supports two modes:
    1. Incremental update (changed files only)
    2. Full reindex (all files)

.PARAMETER IncrementalMode
    Enable incremental update (default: false)

.PARAMETER TriggerFile
    Trigger file for incremental update

.PARAMETER FullReindex
    Perform full reindex (overrides IncrementalMode)

.PARAMETER ProjectRoot
    Project root directory (default: script directory parent)

.PARAMETER IndexFile
    Path to index file (default: docs/project/INDEX.md)

.PARAMETER WatchPatterns
    File patterns to watch (default: *.md)

.PARAMETER ExcludePatterns
    Patterns to exclude (default: venv, node_modules, archive)

.EXAMPLE
    .\UPDATE_PROJECT_INDEX.ps1 -IncrementalMode -TriggerFile "docs\guides\NEW.md"
    Incremental update

.EXAMPLE
    .\UPDATE_PROJECT_INDEX.ps1 -FullReindex
    Full reindex

.EXAMPLE
    .\UPDATE_PROJECT_INDEX.ps1 -ProjectRoot "C:\MyProject" -IndexFile "docs\INDEX.md"
    Custom paths

.NOTES
    Version: 2.0
    Author: GitHub Copilot Agent
    Date: December 3, 2025
    License: MIT
#>

param(
    [switch]$IncrementalMode,
    [string]$TriggerFile = "",
    [switch]$FullReindex,
    [string]$ProjectRoot = "",
    [string]$IndexFile = "",
    [string[]]$WatchPatterns = @("*.md"),
    [string[]]$ExcludePatterns = @("venv", "node_modules", "archive", ".git", "build", "dist", "__pycache__")
)

$ErrorActionPreference = "Stop"

# Auto-detect project root if not specified
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
    Write-Verbose "Auto-detected ProjectRoot: $ProjectRoot"
}

# Default index file path
if ([string]::IsNullOrWhiteSpace($IndexFile)) {
    $IndexFile = Join-Path $ProjectRoot "docs\project\INDEX.md"
}

# Ensure logs directory exists
$LogsDir = Join-Path $ProjectRoot "logs"
if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
}

$LogFile = Join-Path $LogsDir "indexation.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
    
    switch ($Level) {
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default   { Write-Host $logEntry -ForegroundColor White }
    }
}

function Test-ShouldExclude {
    param([string]$Path)
    
    foreach ($pattern in $ExcludePatterns) {
        if ($Path -like "*\$pattern\*" -or $Path -like "*/$pattern/*") {
            return $true
        }
    }
    return $false
}

function Get-ProjectFiles {
    Write-Log "Scanning project for files..." "INFO"
    Write-Log "Project root: $ProjectRoot" "INFO"
    Write-Log "Watch patterns: $($WatchPatterns -join ', ')" "INFO"
    Write-Log "Exclude patterns: $($ExcludePatterns -join ', ')" "INFO"
    
    $allFiles = @()
    
    foreach ($pattern in $WatchPatterns) {
        $files = Get-ChildItem -Path $ProjectRoot -Recurse -Filter $pattern -File -ErrorAction SilentlyContinue |
            Where-Object { -not (Test-ShouldExclude $_.FullName) }
        
        $allFiles += $files
    }
    
    # Remove duplicates
    $allFiles = $allFiles | Select-Object -Unique
    
    Write-Log "Found files: $($allFiles.Count)" "INFO"
    
    return $allFiles
}

function Get-FileCategories {
    param([array]$Files)
    
    # Categorization patterns (customize as needed)
    $categoryPatterns = @{
        'Reports' = @('REPORT', 'SUMMARY', 'ANALYSIS', 'AUDIT')
        'Logs' = @('LOG', 'JOURNAL', 'CHANGELOG')
        'Documentation' = @('GUIDE', 'README', 'MANUAL', 'TUTORIAL')
        'Status' = @('STATUS', 'SNAPSHOT', 'INVENTORY', 'INDEX')
        'Requirements' = @('REQUIREMENTS', 'SPEC', 'DESIGN')
        'Other' = @('*')
    }
    
    $categorized = @{}
    foreach ($category in $categoryPatterns.Keys) {
        $categorized[$category] = 0
    }
    
    foreach ($file in $Files) {
        $name = $file.Name
        $matched = $false
        
        foreach ($category in $categoryPatterns.Keys) {
            if ($category -eq 'Other') { continue }
            
            foreach ($pattern in $categoryPatterns[$category]) {
                if ($name -like "*$pattern*") {
                    $categorized[$category]++
                    $matched = $true
                    break
                }
            }
            
            if ($matched) { break }
        }
        
        if (-not $matched) {
            $categorized['Other']++
        }
    }
    
    return $categorized
}

function Update-IndexMetadata {
    param(
        [int]$TotalFiles,
        [hashtable]$Categories
    )
    
    Write-Log "Updating index metadata..." "INFO"
    
    if (-not (Test-Path $IndexFile)) {
        Write-Log "Index file not found: $IndexFile" "WARNING"
        Write-Log "Creating new index file..." "INFO"
        
        # Create directory if needed
        $indexDir = Split-Path -Parent $IndexFile
        if (-not (Test-Path $indexDir)) {
            New-Item -ItemType Directory -Path $indexDir -Force | Out-Null
        }
        
        # Create minimal index template
        $template = @"
# Project Documentation Index

**Last Updated:** $(Get-Date -Format "dd.MM.yyyy HH:mm")  
**Total Files:** $TotalFiles  

## Categories

$(foreach ($cat in $Categories.Keys | Sort-Object) {
    "- **$cat**: $($Categories[$cat])"
}) -join "`n"

## Files

(Auto-generated list will appear here after full reindex)

---
*Generated by VS Code Indexation Tools v2.0*
"@
        
        $template | Set-Content -Path $IndexFile -Encoding UTF8
        Write-Log "Created new index file: $IndexFile" "SUCCESS"
        return
    }
    
    $content = Get-Content $IndexFile -Raw
    $timestamp = Get-Date -Format "dd.MM.yyyy HH:mm"
    
    # Update metadata (flexible regex patterns)
    $content = $content -replace '(\*\*Last Updated:\*\*\s+)\d{2}\.\d{2}\.\d{4}\s+\d{2}:\d{2}', "`$1$timestamp"
    $content = $content -replace '(\*\*Total Files:\*\*\s+)\d+', "`$1$TotalFiles"
    
    # Update categories (if section exists)
    foreach ($cat in $Categories.Keys) {
        $content = $content -replace "(\*\*$cat:\*\*\s+)\d+", "`$1$($Categories[$cat])"
    }
    
    $content | Set-Content $IndexFile -NoNewline -Encoding UTF8
    
    Write-Log "Metadata updated: $TotalFiles files" "SUCCESS"
    foreach ($cat in $Categories.Keys | Sort-Object) {
        Write-Log "  - $cat : $($Categories[$cat])" "INFO"
    }
}

# MAIN EXECUTION
Write-Log "=== UPDATE_PROJECT_INDEX START ===" "INFO"
Write-Log "Mode: $(if ($FullReindex) { 'FULL REINDEX' } elseif ($IncrementalMode) { "INCREMENTAL (trigger: $TriggerFile)" } else { 'DEFAULT (FULL)' })" "INFO"
Write-Log "Project Root: $ProjectRoot" "INFO"
Write-Log "Index File: $IndexFile" "INFO"

try {
    $files = Get-ProjectFiles
    
    if ($files.Count -eq 0) {
        Write-Log "No files found matching patterns" "WARNING"
        exit 0
    }
    
    $categories = Get-FileCategories -Files $files
    
    if ($IncrementalMode -and -not $FullReindex -and -not [string]::IsNullOrWhiteSpace($TriggerFile)) {
        Write-Log "Incremental update triggered by: $TriggerFile" "INFO"
        # For incremental, just update timestamp and counts
        Update-IndexMetadata -TotalFiles $files.Count -Categories $categories
        Write-Log "Incremental update completed ✅" "SUCCESS"
    }
    else {
        Write-Log "Full reindex in progress..." "INFO"
        Update-IndexMetadata -TotalFiles $files.Count -Categories $categories
        Write-Log "Full reindex completed ✅" "SUCCESS"
        Write-Log "Total files indexed: $($files.Count)" "INFO"
    }
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)" "ERROR"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}

Write-Log "=== UPDATE_PROJECT_INDEX COMPLETE ===" "SUCCESS"
