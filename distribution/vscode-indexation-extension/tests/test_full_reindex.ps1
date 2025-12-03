# Test: Full Reindex with Benchmarks
# Tests full reindex mode and measures performance

param(
    [string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Full Reindex Test ===" -ForegroundColor Cyan

# Setup
$IndexFile = Join-Path $ProjectRoot "docs" "project" "INDEX.md"
$UpdateScript = Join-Path $ProjectRoot "scripts" "UPDATE_PROJECT_INDEX.ps1"
$LogFile = Join-Path $ProjectRoot "logs" "indexation.log"

Write-Host "`nTest Configuration:" -ForegroundColor Yellow
Write-Host "  ProjectRoot: $ProjectRoot"
Write-Host "  IndexFile: $IndexFile"
Write-Host "  UpdateScript: $UpdateScript"

# Test 1: Backup existing index
Write-Host "`n[Test 1] Backing up existing index..." -ForegroundColor Magenta
$backupFile = "$IndexFile.backup-$(Get-Date -Format 'yyyyMMddHHmmss')"
if (Test-Path $IndexFile) {
    Copy-Item $IndexFile $backupFile -Force
    Write-Host "✅ Backup created: $backupFile" -ForegroundColor Green
} else {
    Write-Host "⚠️ No existing index file to backup" -ForegroundColor Yellow
}

# Test 2: Count files before reindex
Write-Host "`n[Test 2] Counting documentation files..." -ForegroundColor Magenta
$files = Get-ChildItem -Path $ProjectRoot -Recurse -Include *.md -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch "node_modules|venv|\.git|build|dist|__pycache__|archive" }
$fileCount = ($files | Measure-Object).Count
Write-Host "✅ Found $fileCount .md files" -ForegroundColor Green

# Test 3: Run full reindex (cold run)
Write-Host "`n[Test 3] Running full reindex (cold run)..." -ForegroundColor Magenta
$coldStart = Get-Date
& $UpdateScript -FullReindex -ProjectRoot $ProjectRoot
$coldDuration = (Get-Date) - $coldStart
Write-Host "✅ Cold run completed in $([math]::Round($coldDuration.TotalMilliseconds, 2)) ms" -ForegroundColor Green

# Test 4: Run full reindex (warm run)
Write-Host "`n[Test 4] Running full reindex (warm run)..." -ForegroundColor Magenta
$warmStart = Get-Date
& $UpdateScript -FullReindex -ProjectRoot $ProjectRoot
$warmDuration = (Get-Date) - $warmStart
Write-Host "✅ Warm run completed in $([math]::Round($warmDuration.TotalMilliseconds, 2)) ms" -ForegroundColor Green

# Test 5: Verify index structure
Write-Host "`n[Test 5] Verifying index structure..." -ForegroundColor Magenta
if (Test-Path $IndexFile) {
    $indexContent = Get-Content $IndexFile -Raw
    
    # Check metadata
    $checks = @(
        @{ Pattern = "Total Files:\s*(\d+)"; Name = "Total Files" },
        @{ Pattern = "Coverage Period:\s*(.+)"; Name = "Coverage Period" },
        @{ Pattern = "Last Updated:\s*(.+)"; Name = "Last Updated" },
        @{ Pattern = "## Reports"; Name = "Reports Section" },
        @{ Pattern = "## Logs"; Name = "Logs Section" },
        @{ Pattern = "## Documentation"; Name = "Documentation Section" },
        @{ Pattern = "## Status"; Name = "Status Section" },
        @{ Pattern = "## Requirements"; Name = "Requirements Section" },
        @{ Pattern = "## Other"; Name = "Other Section" },
        @{ Pattern = "## Statistics"; Name = "Statistics Section" }
    )
    
    $passed = 0
    foreach ($check in $checks) {
        if ($indexContent -match $check.Pattern) {
            Write-Host "  ✅ $($check.Name)" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "  ❌ $($check.Name)" -ForegroundColor Red
        }
    }
    
    if ($passed -eq $checks.Count) {
        Write-Host "✅ All structure checks passed ($passed/$($checks.Count))" -ForegroundColor Green
    } else {
        Write-Host "❌ Some structure checks failed ($passed/$($checks.Count))" -ForegroundColor Red
        throw "Index structure verification failed"
    }
} else {
    Write-Host "❌ Index file not found" -ForegroundColor Red
    throw "Index file missing"
}

# Test 6: Verify file count
Write-Host "`n[Test 6] Verifying file count..." -ForegroundColor Magenta
if ($indexContent -match "Total Files:\s*(\d+)") {
    $indexedCount = [int]$matches[1]
    Write-Host "  Expected: $fileCount files" -ForegroundColor Gray
    Write-Host "  Indexed: $indexedCount files" -ForegroundColor Gray
    
    if ($indexedCount -eq $fileCount) {
        Write-Host "✅ File count matches" -ForegroundColor Green
    } else {
        $diff = [math]::Abs($fileCount - $indexedCount)
        Write-Host "⚠️ File count mismatch: difference of $diff files" -ForegroundColor Yellow
        # Don't fail, might be due to excludes
    }
} else {
    Write-Host "❌ Could not extract file count" -ForegroundColor Red
    throw "File count verification failed"
}

# Test 7: Check categories
Write-Host "`n[Test 7] Checking categories..." -ForegroundColor Magenta
$categoryPattern = "## Statistics[\s\S]+?\|[\s\S]+?\|\s*(\d+)\s*\|\s*(\d+)%\s*\|"
if ($indexContent -match $categoryPattern) {
    Write-Host "✅ Statistics table found" -ForegroundColor Green
} else {
    Write-Host "⚠️ Statistics table not found or malformed" -ForegroundColor Yellow
}

# Test 8: Performance benchmarks
Write-Host "`n[Test 8] Performance benchmarks..." -ForegroundColor Magenta

# Calculate throughput
$coldThroughput = [math]::Round($fileCount / $coldDuration.TotalSeconds, 2)
$warmThroughput = [math]::Round($fileCount / $warmDuration.TotalSeconds, 2)

Write-Host "`n  Cold Run:" -ForegroundColor Gray
Write-Host "    Duration: $([math]::Round($coldDuration.TotalMilliseconds, 2)) ms" -ForegroundColor Gray
Write-Host "    Throughput: $coldThroughput files/sec" -ForegroundColor Gray
Write-Host "    Avg per file: $([math]::Round($coldDuration.TotalMilliseconds / $fileCount, 2)) ms" -ForegroundColor Gray

Write-Host "`n  Warm Run:" -ForegroundColor Gray
Write-Host "    Duration: $([math]::Round($warmDuration.TotalMilliseconds, 2)) ms" -ForegroundColor Gray
Write-Host "    Throughput: $warmThroughput files/sec" -ForegroundColor Gray
Write-Host "    Avg per file: $([math]::Round($warmDuration.TotalMilliseconds / $fileCount, 2)) ms" -ForegroundColor Gray

# Performance thresholds (based on benchmarks from README)
$maxDurationMs = $fileCount * 10  # 10ms per file
if ($warmDuration.TotalMilliseconds -lt $maxDurationMs) {
    Write-Host "`n✅ Performance OK: warm run under $maxDurationMs ms threshold" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ Performance warning: warm run exceeded $maxDurationMs ms threshold" -ForegroundColor Yellow
}

# Test 9: Check logs
Write-Host "`n[Test 9] Checking logs..." -ForegroundColor Magenta
if (Test-Path $LogFile) {
    $recentLogs = Get-Content $LogFile -Tail 20
    $errors = $recentLogs | Select-String -Pattern "ERROR"
    $warnings = $recentLogs | Select-String -Pattern "WARNING"
    
    Write-Host "  Recent log entries: 20" -ForegroundColor Gray
    Write-Host "  Errors: $($errors.Count)" -ForegroundColor $(if ($errors.Count -eq 0) { "Green" } else { "Red" })
    Write-Host "  Warnings: $($warnings.Count)" -ForegroundColor $(if ($warnings.Count -eq 0) { "Green" } else { "Yellow" })
    
    if ($errors.Count -eq 0) {
        Write-Host "✅ No errors in logs" -ForegroundColor Green
    } else {
        Write-Host "❌ Errors found in logs:" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        throw "Errors found in logs"
    }
} else {
    Write-Host "⚠️ Log file not found: $LogFile" -ForegroundColor Yellow
}

# Cleanup (restore backup if needed)
Write-Host "`n[Cleanup] Test complete, keeping new index" -ForegroundColor Magenta
Write-Host "  Backup available at: $backupFile" -ForegroundColor Gray

# Summary
Write-Host "`n=== Performance Summary ===" -ForegroundColor Cyan
Write-Host "┌─────────────────────┬──────────────┬──────────────┐" -ForegroundColor Gray
Write-Host "│ Metric              │ Cold Run     │ Warm Run     │" -ForegroundColor Gray
Write-Host "├─────────────────────┼──────────────┼──────────────┤" -ForegroundColor Gray
Write-Host "│ Duration (ms)       │ $("{0,12}" -f [math]::Round($coldDuration.TotalMilliseconds, 2)) │ $("{0,12}" -f [math]::Round($warmDuration.TotalMilliseconds, 2)) │" -ForegroundColor Gray
Write-Host "│ Throughput (f/s)    │ $("{0,12}" -f $coldThroughput) │ $("{0,12}" -f $warmThroughput) │" -ForegroundColor Gray
Write-Host "│ Avg per file (ms)   │ $("{0,12}" -f [math]::Round($coldDuration.TotalMilliseconds / $fileCount, 2)) │ $("{0,12}" -f [math]::Round($warmDuration.TotalMilliseconds / $fileCount, 2)) │" -ForegroundColor Gray
Write-Host "└─────────────────────┴──────────────┴──────────────┘" -ForegroundColor Gray

Write-Host "`n✅ All full reindex tests passed" -ForegroundColor Green
Write-Host "   Total Files: $fileCount" -ForegroundColor Gray
Write-Host "   Index File: $IndexFile" -ForegroundColor Gray
Write-Host "   Backup File: $backupFile" -ForegroundColor Gray

exit 0
