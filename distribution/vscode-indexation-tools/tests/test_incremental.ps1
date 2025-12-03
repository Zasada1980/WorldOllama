# Test: Incremental Reindex
# Tests incremental mode with single file changes

param(
    [string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Incremental Reindex Test ===" -ForegroundColor Cyan

# Setup
$TestFile = Join-Path $ProjectRoot "test_file_$(Get-Date -Format 'yyyyMMddHHmmss').md"
$IndexFile = Join-Path $ProjectRoot "docs" "project" "INDEX.md"
$UpdateScript = Join-Path $ProjectRoot "scripts" "UPDATE_PROJECT_INDEX.ps1"

Write-Host "`nTest Configuration:" -ForegroundColor Yellow
Write-Host "  ProjectRoot: $ProjectRoot"
Write-Host "  TestFile: $TestFile"
Write-Host "  IndexFile: $IndexFile"
Write-Host "  UpdateScript: $UpdateScript"

# Test 1: Create test file
Write-Host "`n[Test 1] Creating test file..." -ForegroundColor Magenta
$testContent = @"
# Test Document

This is a test file created at $(Get-Date).

## Purpose

Test incremental reindex functionality.

## Status

- Status: In Progress
- Priority: High
- Category: Testing
"@

New-Item -Path $TestFile -ItemType File -Value $testContent -Force | Out-Null
Write-Host "✅ Created: $TestFile" -ForegroundColor Green

# Test 2: Run incremental reindex
Write-Host "`n[Test 2] Running incremental reindex..." -ForegroundColor Magenta
$startTime = Get-Date
& $UpdateScript -IncrementalMode -TriggerFile $TestFile -ProjectRoot $ProjectRoot
$duration = (Get-Date) - $startTime

Write-Host "✅ Reindex completed in $($duration.TotalMilliseconds) ms" -ForegroundColor Green

# Test 3: Verify index updated
Write-Host "`n[Test 3] Verifying index file..." -ForegroundColor Magenta
if (Test-Path $IndexFile) {
    $indexContent = Get-Content $IndexFile -Raw
    $fileName = Split-Path $TestFile -Leaf
    
    if ($indexContent -match [regex]::Escape($fileName)) {
        Write-Host "✅ Index contains test file" -ForegroundColor Green
    } else {
        Write-Host "❌ Index does not contain test file" -ForegroundColor Red
        throw "Index verification failed"
    }
} else {
    Write-Host "❌ Index file not found" -ForegroundColor Red
    throw "Index file missing"
}

# Test 4: Check metadata
Write-Host "`n[Test 4] Verifying metadata..." -ForegroundColor Magenta
if ($indexContent -match "Total Files:\s*(\d+)") {
    $fileCount = [int]$matches[1]
    Write-Host "✅ Total Files: $fileCount" -ForegroundColor Green
} else {
    Write-Host "❌ Metadata not found" -ForegroundColor Red
    throw "Metadata verification failed"
}

if ($indexContent -match "Last Updated:\s*(.+)") {
    $lastUpdated = $matches[1]
    Write-Host "✅ Last Updated: $lastUpdated" -ForegroundColor Green
} else {
    Write-Host "❌ Last Updated not found" -ForegroundColor Red
    throw "Last Updated verification failed"
}

# Test 5: Performance check
Write-Host "`n[Test 5] Performance check..." -ForegroundColor Magenta
$threshold = 1000  # 1 second
if ($duration.TotalMilliseconds -lt $threshold) {
    Write-Host "✅ Performance OK: $($duration.TotalMilliseconds) ms < $threshold ms" -ForegroundColor Green
} else {
    Write-Host "⚠️ Performance warning: $($duration.TotalMilliseconds) ms > $threshold ms" -ForegroundColor Yellow
}

# Cleanup
Write-Host "`n[Cleanup] Removing test file..." -ForegroundColor Magenta
Remove-Item $TestFile -Force -ErrorAction SilentlyContinue
Write-Host "✅ Cleanup complete" -ForegroundColor Green

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "✅ All incremental reindex tests passed" -ForegroundColor Green
Write-Host "   Duration: $($duration.TotalMilliseconds) ms" -ForegroundColor Gray
Write-Host "   Index File: $IndexFile" -ForegroundColor Gray
Write-Host "   Total Files in Index: $fileCount" -ForegroundColor Gray

exit 0
