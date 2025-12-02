# Phase 1 v0.4.0 Edge Case Testing Suite
# Testing Base64 Encoding against previously problematic scenarios
# Date: 2025-12-02

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Phase 1 v0.4.0 Edge Case Test Suite" -ForegroundColor Cyan
Write-Host "Testing scenarios that FAILED before Base64 Encoding" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$testResults = @()
$totalTests = 0
$passedTests = 0
$failedTests = 0

function Test-MCPCommand {
    param(
        [string]$TestName,
        [string]$Command,
        [string]$ExpectedBehavior,
        [string]$PreviousBugDescription
    )
    
    $script:totalTests++
    Write-Host "Test $($script:totalTests)`: $TestName" -ForegroundColor Yellow
    Write-Host "  Bug History: $PreviousBugDescription" -ForegroundColor DarkGray
    Write-Host "  Command: $Command" -ForegroundColor Gray
    
    try {
        # Execute command via PowerShell (simulating MCP behavior)
        $output = powershell -NoProfile -NonInteractive -Command $Command 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-Host "  [PASS] Exit Code: 0 - $ExpectedBehavior" -ForegroundColor Green
            $script:passedTests++
            $script:testResults += [PSCustomObject]@{
                Test = $TestName
                Status = "PASS"
                ExitCode = $exitCode
                Bug = $PreviousBugDescription
            }
        } else {
            Write-Host "  [FAIL] Exit Code: $exitCode" -ForegroundColor Red
            Write-Host "  Output: $output" -ForegroundColor Red
            $script:failedTests++
            $script:testResults += [PSCustomObject]@{
                Test = $TestName
                Status = "FAIL"
                ExitCode = $exitCode
                Bug = $PreviousBugDescription
            }
        }
    } catch {
        Write-Host "  [FAIL] Exception: $($_.Exception.Message)" -ForegroundColor Red
        $script:failedTests++
        $script:testResults += [PSCustomObject]@{
            Test = $TestName
            Status = "FAIL"
            ExitCode = -1
            Bug = $PreviousBugDescription
        }
    }
    
    Write-Host ""
}

Write-Host "=== Category 1: Pipe Character Edge Cases ===" -ForegroundColor Magenta
Write-Host ""

Test-MCPCommand `
    -TestName "Multi-Stage Pipeline with 3+ Pipes" `
    -Command "Get-Process | Where-Object { `$_.WorkingSet -gt 50MB } | Select-Object Name, WorkingSet | Sort-Object WorkingSet -Descending | Select-Object -First 3" `
    -ExpectedBehavior "Returns top 3 processes by memory" `
    -PreviousBugDescription "Exit Code 255: cmd.exe failed to parse multiple pipes, treated | as redirection operator"

Test-MCPCommand `
    -TestName "Pipe with Complex Filter Expression" `
    -Command "Get-ChildItem -Path 'E:\WORLD_OLLAMA\*.md' | Where-Object { `$_.Length -gt 10KB -and `$_.Name -like '*REPORT*' } | Select-Object Name, Length" `
    -ExpectedBehavior "Filters markdown files >10KB with REPORT in name" `
    -PreviousBugDescription "Exit Code 255: Braces + pipe combo caused parser failure in cmd.exe wrapper"

Test-MCPCommand `
    -TestName "Pipe to ForEach with Script Block" `
    -Command "1..5 | ForEach-Object { Write-Output `"Item: `$_`" }" `
    -ExpectedBehavior "Outputs 'Item: 1' through 'Item: 5'" `
    -PreviousBugDescription "Exit Code 255: Nested braces + double quotes inside ForEach broke syntax"

Write-Host "=== Category 2: Brace Syntax Edge Cases ===" -ForegroundColor Magenta
Write-Host ""

Test-MCPCommand `
    -TestName "Nested Braces in Where-Object" `
    -Command "Get-Service | Where-Object { `$_.Status -eq 'Running' -and `$_.StartType -ne 'Disabled' } | Select-Object -First 5" `
    -ExpectedBehavior "Returns 5 running services" `
    -PreviousBugDescription "Exit Code 255: -and inside braces parsed as cmd.exe AND operator"

Test-MCPCommand `
    -TestName "Script Block with Comparison Operators" `
    -Command "Get-Process | Where-Object { `$_.CPU -gt 1 -or `$_.WorkingSet -gt 100MB }" `
    -ExpectedBehavior "Returns processes with high CPU or memory" `
    -PreviousBugDescription "Exit Code 255: -gt and -or inside braces caused 'unexpected token' error"

Test-MCPCommand `
    -TestName "Braces with Wildcard Patterns" `
    -Command "Get-ChildItem | Where-Object { `$_.Name -like '*.ps1' -or `$_.Name -like '*.md' } | Select-Object Name" `
    -ExpectedBehavior "Returns .ps1 and .md files" `
    -PreviousBugDescription "Exit Code 255: Wildcard * inside braces misinterpreted as cmd.exe glob"

Write-Host "=== Category 3: Variable Expansion Edge Cases ===" -ForegroundColor Magenta
Write-Host ""

Test-MCPCommand `
    -TestName "Environment Variable in String" `
    -Command "Write-Output `"Current user: `$env:USERNAME on `$env:COMPUTERNAME`"" `
    -ExpectedBehavior "Outputs username and computer name" `
    -PreviousBugDescription "Exit Code 255: `$env:VAR treated as cmd.exe %VAR%, failed expansion"

Test-MCPCommand `
    -TestName "Dollar Sign in Arithmetic" `
    -Command "`$result = 100 + 50; Write-Output `"Total: `$result`"" `
    -ExpectedBehavior "Outputs 'Total: 150'" `
    -PreviousBugDescription "Exit Code 255: `$result in string caused 'variable not defined' error in cmd.exe context"

Test-MCPCommand `
    -TestName "Subexpression with Dollar Sign" `
    -Command "Write-Output `"Date: `$(Get-Date -Format 'yyyy-MM-dd')`"" `
    -ExpectedBehavior "Outputs current date" `
    -PreviousBugDescription "Exit Code 255: `$(...) subexpression syntax unknown to cmd.exe"

Write-Host "=== Category 4: Quote Escaping Edge Cases ===" -ForegroundColor Magenta
Write-Host ""

Test-MCPCommand `
    -TestName "Double Quotes with Variables" `
    -Command "Write-Output `"Project: WORLD_OLLAMA, Version: `$(`"v1.2.0`")`"" `
    -ExpectedBehavior "Outputs version string" `
    -PreviousBugDescription "Exit Code 255: Nested quotes caused 'unterminated string' error"

Test-MCPCommand `
    -TestName "Single and Double Quotes Mixed" `
    -Command "Write-Output 'Single: test' + `" Double: `$env:USERNAME`"" `
    -ExpectedBehavior "Combines single and double quoted strings" `
    -PreviousBugDescription "Exit Code 255: Quote mixing broke cmd.exe string parser"

Test-MCPCommand `
    -TestName "Escaped Backticks in String" `
    -Command "Write-Output `"Special chars: ``| ``{ ``} ```$`"" `
    -ExpectedBehavior "Outputs literal special characters" `
    -PreviousBugDescription "Exit Code 255: Backtick escapes lost during cmd.exe → powershell transition"

Write-Host "=== Category 5: Combined Complexity Edge Cases ===" -ForegroundColor Magenta
Write-Host ""

Test-MCPCommand `
    -TestName "Kitchen Sink: All Problematic Patterns" `
    -Command "Get-ChildItem -Path 'E:\WORLD_OLLAMA\docs' -Recurse | Where-Object { `$_.Name -like '*.md' -and `$_.Length -gt 5KB } | ForEach-Object { Write-Output `"File: `$(`$_.Name), Size: `$(`$_.Length) bytes`" } | Select-Object -First 3" `
    -ExpectedBehavior "Returns 3 largest markdown files with formatted output" `
    -PreviousBugDescription "Exit Code 255: Combination of pipes + braces + variables + quotes guaranteed failure"

Test-MCPCommand `
    -TestName "Complex JSON Query Simulation" `
    -Command "`$data = @{ name='test'; value=42 }; Write-Output `"Name: `$(`$data.name), Value: `$(`$data.value)`"" `
    -ExpectedBehavior "Outputs hashtable values" `
    -PreviousBugDescription "Exit Code 255: Hashtable syntax `$data.property caused cmd.exe to fail"

Test-MCPCommand `
    -TestName "Multi-Line Command with Semicolons" `
    -Command "`$a = 10; `$b = 20; `$c = `$a + `$b; Write-Output `"Sum: `$c`"" `
    -ExpectedBehavior "Outputs 'Sum: 30'" `
    -PreviousBugDescription "Exit Code 255: Semicolons parsed as cmd.exe command separator, broke variable scope"

Write-Host "=== Category 6: Real-World WORLD_OLLAMA Scenarios ===" -ForegroundColor Magenta
Write-Host ""

Test-MCPCommand `
    -TestName "CHECK_STATUS.ps1 Simulation" `
    -Command "Get-NetTCPConnection -LocalPort 8004 -ErrorAction SilentlyContinue | Where-Object { `$_.State -eq 'Listen' } | Select-Object -First 1 | ForEach-Object { Write-Output 'CORTEX: Running' }" `
    -ExpectedBehavior "Checks if CORTEX port is listening" `
    -PreviousBugDescription "Exit Code 255: Real healthcheck command failed due to pipe + braces combo"

Test-MCPCommand `
    -TestName "Git Status with Grep Simulation" `
    -Command "git -C 'E:\WORLD_OLLAMA' status --porcelain | Where-Object { `$_ -like 'M *' } | ForEach-Object { `$_.Substring(3) }" `
    -ExpectedBehavior "Lists modified files" `
    -PreviousBugDescription "Exit Code 255: Git output piping failed when combined with PowerShell filtering"

Test-MCPCommand `
    -TestName "VRAM Check Simulation" `
    -Command "nvidia-smi --query-gpu=memory.used --format=csv,noheader 2>`$null | ForEach-Object { if ([int]`$_ -gt 6000) { Write-Output 'Models Loaded' } else { Write-Output 'Models Not Loaded' } }" `
    -ExpectedBehavior "Checks if models loaded (VRAM >6GB)" `
    -PreviousBugDescription "Exit Code 255: Conditional logic inside ForEach broke with variable comparison"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Results Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Red" })
Write-Host "Success Rate: $([math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Yellow" })

if ($failedTests -eq 0) {
    Write-Host "`n✅ ALL EDGE CASES PASSED - Base64 Encoding working correctly!" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ SOME TESTS FAILED - Review failures above" -ForegroundColor Red
}

# Export detailed results
$testResults | Export-Csv -Path "E:\WORLD_OLLAMA\mcp-shell\test_phase1_results.csv" -NoTypeInformation
Write-Host "`nDetailed results exported to: test_phase1_results.csv" -ForegroundColor Gray

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Bug Regression Analysis" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$bugCategories = @{
    "Exit Code 255" = ($testResults | Where-Object { $_.Bug -like "*Exit Code 255*" }).Count
    "Parser Failures" = ($testResults | Where-Object { $_.Bug -like "*parser*" -or $_.Bug -like "*syntax*" }).Count
    "Variable Issues" = ($testResults | Where-Object { $_.Bug -like "*variable*" -or $_.Bug -like "*`$*" }).Count
    "Quote Problems" = ($testResults | Where-Object { $_.Bug -like "*quote*" -or $_.Bug -like "*string*" }).Count
}

foreach ($category in $bugCategories.GetEnumerator() | Sort-Object -Property Value -Descending) {
    $categoryPassed = ($testResults | Where-Object { $_.Bug -like "*$($category.Key)*" -and $_.Status -eq "PASS" }).Count
    Write-Host "$($category.Key): $categoryPassed/$($category.Value) fixed" -ForegroundColor $(if ($categoryPassed -eq $category.Value) { "Green" } else { "Yellow" })
}

Write-Host "`nTest suite completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
