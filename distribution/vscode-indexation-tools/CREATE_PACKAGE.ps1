# Create Distribution Archive
# Packages all files into vscode-indexation-tools-v2.0.zip

param(
    [string]$OutputPath = (Join-Path $PSScriptRoot "vscode-indexation-tools-v2.0.zip"),
    [switch]$CalculateChecksum
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Creating Distribution Archive ===" -ForegroundColor Cyan

$packageRoot = $PSScriptRoot
$version = "2.0"

# Files to include
$includeFiles = @(
    "README.md",
    "INSTALL.md",
    "CONFIGURATION.md",
    "TROUBLESHOOTING.md",
    "PACKAGE_SUMMARY.md",
    "LICENSE.txt",
    "QUICK_INSTALL.ps1"
)

$includeDirs = @(
    "scripts",
    "templates",
    "tests",
    ".vscode"
)

# Check all files exist
Write-Host "`n[Verification] Checking files..." -ForegroundColor Yellow

$allFiles = @()
$totalSize = 0

foreach ($file in $includeFiles) {
    $fullPath = Join-Path $packageRoot $file
    if (Test-Path $fullPath) {
        $item = Get-Item $fullPath
        $allFiles += $fullPath
        $totalSize += $item.Length
        Write-Host "  ✅ $file ($([math]::Round($item.Length/1KB, 2)) KB)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $file (NOT FOUND)" -ForegroundColor Red
        throw "Missing file: $file"
    }
}

foreach ($dir in $includeDirs) {
    $fullPath = Join-Path $packageRoot $dir
    if (Test-Path $fullPath) {
        $files = Get-ChildItem -Path $fullPath -Recurse -File
        $dirSize = ($files | Measure-Object -Property Length -Sum).Sum
        $allFiles += $fullPath
        $totalSize += $dirSize
        Write-Host "  ✅ $dir\ ($($files.Count) files, $([math]::Round($dirSize/1KB, 2)) KB)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $dir\ (NOT FOUND)" -ForegroundColor Red
        throw "Missing directory: $dir"
    }
}

Write-Host "`n  Total files to package: $(($allFiles | Measure-Object).Count)" -ForegroundColor Gray
Write-Host "  Total size: $([math]::Round($totalSize/1KB, 2)) KB" -ForegroundColor Gray

# Create archive
Write-Host "`n[Archive] Creating ZIP file..." -ForegroundColor Yellow

# Remove existing archive
if (Test-Path $OutputPath) {
    Remove-Item $OutputPath -Force
    Write-Host "  Removed existing archive" -ForegroundColor Gray
}

# Compress-Archive with all files
try {
    $compressParams = @{
        Path = $allFiles
        DestinationPath = $OutputPath
        CompressionLevel = "Optimal"
    }
    
    Compress-Archive @compressParams
    
    $archiveInfo = Get-Item $OutputPath
    Write-Host "  ✅ Archive created: $($archiveInfo.Name)" -ForegroundColor Green
    Write-Host "     Size: $([math]::Round($archiveInfo.Length/1KB, 2)) KB" -ForegroundColor Gray
    Write-Host "     Compression ratio: $([math]::Round(($archiveInfo.Length / $totalSize) * 100, 1))%" -ForegroundColor Gray
    Write-Host "     Path: $OutputPath" -ForegroundColor Gray
} catch {
    Write-Host "  ❌ Archive creation failed: $($_.Exception.Message)" -ForegroundColor Red
    throw
}

# Calculate checksum
if ($CalculateChecksum) {
    Write-Host "`n[Checksum] Calculating SHA256..." -ForegroundColor Yellow
    
    $hash = Get-FileHash -Path $OutputPath -Algorithm SHA256
    $checksumFile = "$OutputPath.sha256"
    
    $checksumContent = @"
$($hash.Hash)  $($archiveInfo.Name)

# Verification
# PowerShell:
#   Get-FileHash -Path "$($archiveInfo.Name)" -Algorithm SHA256
# Expected: $($hash.Hash)

# Linux/macOS:
#   sha256sum "$($archiveInfo.Name)"
# Expected: $($hash.Hash.ToLower())

# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Package: VS Code Indexation Tools v$version
"@
    
    Set-Content -Path $checksumFile -Value $checksumContent -Encoding UTF8
    
    Write-Host "  ✅ Checksum file created: $checksumFile" -ForegroundColor Green
    Write-Host "     SHA256: $($hash.Hash)" -ForegroundColor Gray
}

# Verify archive contents
Write-Host "`n[Verification] Checking archive contents..." -ForegroundColor Yellow

try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($OutputPath)
    
    $entryCount = $zip.Entries.Count
    Write-Host "  ✅ Archive contains $entryCount entries" -ForegroundColor Green
    
    # Check critical files
    $criticalFiles = @(
        "README.md",
        "QUICK_INSTALL.ps1",
        "scripts/UPDATE_PROJECT_INDEX.ps1",
        "scripts/WATCH_FILE_CHANGES.ps1",
        "scripts/CREATE_SCHEDULED_TASK.ps1",
        "scripts/INSTALL_GIT_HOOK.ps1",
        "scripts/post-commit.hook"
    )
    
    foreach ($file in $criticalFiles) {
        $entry = $zip.Entries | Where-Object { $_.FullName -replace '\\', '/' -like "*$file" }
        if ($entry) {
            Write-Host "     ✅ $file" -ForegroundColor Green
        } else {
            Write-Host "     ❌ $file (MISSING)" -ForegroundColor Red
            throw "Critical file missing from archive: $file"
        }
    }
    
    $zip.Dispose()
} catch {
    Write-Host "  ❌ Archive verification failed: $($_.Exception.Message)" -ForegroundColor Red
    throw
}

# Summary
Write-Host "`n=== Package Summary ===" -ForegroundColor Cyan
Write-Host "┌─────────────────────────────┬──────────────────┐" -ForegroundColor Gray
Write-Host "│ Metric                      │ Value            │" -ForegroundColor Gray
Write-Host "├─────────────────────────────┼──────────────────┤" -ForegroundColor Gray
Write-Host "│ Version                     │ $("{0,-16}" -f $version) │" -ForegroundColor Gray
Write-Host "│ Total Files                 │ $("{0,-16}" -f $entryCount) │" -ForegroundColor Gray
Write-Host "│ Uncompressed Size           │ $("{0,-16}" -f "$([math]::Round($totalSize/1KB, 2)) KB") │" -ForegroundColor Gray
Write-Host "│ Compressed Size             │ $("{0,-16}" -f "$([math]::Round($archiveInfo.Length/1KB, 2)) KB") │" -ForegroundColor Gray
Write-Host "│ Compression Ratio           │ $("{0,-16}" -f "$([math]::Round(($archiveInfo.Length / $totalSize) * 100, 1))%") │" -ForegroundColor Gray
Write-Host "└─────────────────────────────┴──────────────────┘" -ForegroundColor Gray

Write-Host "`n✅ Distribution archive created successfully!" -ForegroundColor Green
Write-Host "`n📦 Archive: $OutputPath" -ForegroundColor Cyan
if ($CalculateChecksum) {
    Write-Host "🔒 Checksum: $checksumFile" -ForegroundColor Cyan
}

Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
Write-Host "  1. Test archive extraction:" -ForegroundColor Gray
Write-Host "     Expand-Archive -Path '$OutputPath' -DestinationPath 'C:\Temp\test'" -ForegroundColor Gray
Write-Host "`n  2. Test installation:" -ForegroundColor Gray
Write-Host "     cd C:\Temp\test" -ForegroundColor Gray
Write-Host "     pwsh QUICK_INSTALL.ps1" -ForegroundColor Gray
Write-Host "`n  3. Distribute package:" -ForegroundColor Gray
Write-Host "     - Upload to GitHub Releases" -ForegroundColor Gray
Write-Host "     - Share via network drive" -ForegroundColor Gray
Write-Host "     - Include in project templates" -ForegroundColor Gray

exit 0
