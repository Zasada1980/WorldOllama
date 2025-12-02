# ORDER 51.7: Test MCP Server Timeout Implementation
# Tests fast/medium/long classification and timeout enforcement

Write-Host "=== ORDER 51.7: MCP Timeout Tests ===" -ForegroundColor Cyan
Write-Host ""

# Function to verify timeout classification
function Test-TimeoutClassification {
    param($Command, $ExpectedTimeoutSec)
    
    Write-Host "Testing: $Command" -ForegroundColor Yellow
    Write-Host "Expected timeout: ${ExpectedTimeoutSec}s" -ForegroundColor Gray
    
    # Note: This script CANNOT directly test MCP server (requires stdio communication)
    # Instead, we verify the LOGIC by checking terminal_timeout_policy.json patterns
    
    $policy = Get-Content "E:\WORLD_OLLAMA\config\terminal_timeout_policy.json" | ConvertFrom-Json
    
    # Classify command (matching TypeScript logic)
    $cmdLower = $Command.ToLower()
    $normalizedCmd = $cmdLower -replace '\s+', '_'  # Normalize spaces to underscores
    $actualTimeout = $policy.timeouts.default_exec_timeout_sec
    
    # Check overrides first (with normalization)
    foreach ($override in $policy.long_running_overrides.PSObject.Properties) {
        if ($normalizedCmd -match $override.Name.ToLower()) {
            $actualTimeout = $override.Value
            Write-Host "  ✓ Matched override: $($override.Name) → ${actualTimeout}s" -ForegroundColor Green
            return ($actualTimeout -eq $ExpectedTimeoutSec)
        }
    }
    
    # Check classifications
    foreach ($pattern in $policy.command_classification.fast.patterns) {
        if ($cmdLower -match $pattern) {
            $actualTimeout = $policy.command_classification.fast.max_timeout_sec
            Write-Host "  ✓ Matched fast pattern: $pattern → ${actualTimeout}s" -ForegroundColor Green
            return ($actualTimeout -eq $ExpectedTimeoutSec)
        }
    }
    
    foreach ($pattern in $policy.command_classification.medium.patterns) {
        if ($cmdLower -match $pattern) {
            $actualTimeout = $policy.command_classification.medium.max_timeout_sec
            Write-Host "  ✓ Matched medium pattern: $pattern → ${actualTimeout}s" -ForegroundColor Green
            return ($actualTimeout -eq $ExpectedTimeoutSec)
        }
    }
    
    foreach ($pattern in $policy.command_classification.long.patterns) {
        if ($cmdLower -match $pattern) {
            $actualTimeout = $policy.command_classification.long.max_timeout_sec
            Write-Host "  ✓ Matched long pattern: $pattern → ${actualTimeout}s" -ForegroundColor Green
            return ($actualTimeout -eq $ExpectedTimeoutSec)
        }
    }
    
    Write-Host "  ✓ Using default timeout: ${actualTimeout}s" -ForegroundColor Green
    return ($actualTimeout -eq $ExpectedTimeoutSec)
}

# Test Cases
Write-Host "1. Fast Commands (60s)" -ForegroundColor Cyan
$result1 = Test-TimeoutClassification "dir" 60
$result2 = Test-TimeoutClassification "ls -la" 60
$result3 = Test-TimeoutClassification "git status" 60
Write-Host ""

Write-Host "2. Medium Commands (120s)" -ForegroundColor Cyan
$result4 = Test-TimeoutClassification "pwsh scripts/CHECK_STATUS.ps1" 120
$result5 = Test-TimeoutClassification "node --version" 120
$result6 = Test-TimeoutClassification "python --version" 120
Write-Host ""

Write-Host "3. Long Commands (900s)" -ForegroundColor Cyan
$result7 = Test-TimeoutClassification "cargo check" 900
$result8 = Test-TimeoutClassification "npm run check" 900
$result9 = Test-TimeoutClassification "docker ps -a" 900
Write-Host ""

Write-Host "4. Override Commands (custom)" -ForegroundColor Cyan
$result10 = Test-TimeoutClassification "npm install" 600
$result11 = Test-TimeoutClassification "cargo build --release" 600
Write-Host ""

# Summary
$totalTests = 11
$passedTests = ($result1, $result2, $result3, $result4, $result5, $result6, $result7, $result8, $result9, $result10, $result11 | Where-Object {$_ -eq $true}).Count

Write-Host "=== Test Results ===" -ForegroundColor Cyan
Write-Host "Passed: $passedTests / $totalTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })

if ($passedTests -eq $totalTests) {
    Write-Host "✅ All timeout classification tests PASSED" -ForegroundColor Green
    Write-Host ""
    Write-Host "NOTE: This tests the LOGIC only. To test actual timeout enforcement:" -ForegroundColor Yellow
    Write-Host "1. Restart VS Code to reload MCP server" -ForegroundColor Gray
    Write-Host "2. Use agent to call: myshell/execute_command with 'pwsh -Command Start-Sleep -Seconds 200'" -ForegroundColor Gray
    Write-Host "3. Verify timeout after 120s with structured error" -ForegroundColor Gray
    exit 0
} else {
    Write-Host "❌ Some tests FAILED - check terminal_timeout_policy.json patterns" -ForegroundColor Red
    exit 1
}
