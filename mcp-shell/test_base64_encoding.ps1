# Phase 1 v0.4.0: Base64 Encoding Test Suite
# Tests commands that previously failed with Exit Code 255

Write-Host "=== Phase 1 v0.4.0: Base64 Encoding Tests ===" -ForegroundColor Cyan
Write-Host ""

# Function to test encoding logic
function Test-Base64Encoding {
    param($Command, $Description)
    
    Write-Host "Test: $Description" -ForegroundColor Yellow
    Write-Host "  Command: $Command" -ForegroundColor Gray
    
    # Check if command has dangerous characters
    $hasDangerousChars = $Command -match '[|{}$"'']'
    Write-Host "  Requires encoding: $(if ($hasDangerousChars) { 'YES (detected special chars)' } else { 'NO' })" -ForegroundColor $(if ($hasDangerousChars) { "Green" } else { "Gray" })
    
    # Simulate encoding (what MCP server will do)
    if ($hasDangerousChars) {
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($Command)
        $encoded = [Convert]::ToBase64String($bytes)
        Write-Host "  Encoded length: $($encoded.Length) chars" -ForegroundColor Gray
        
        # Test execution via -EncodedCommand
        try {
            $result = powershell -NoProfile -NonInteractive -EncodedCommand $encoded 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -eq 0) {
                Write-Host "  ✅ SUCCESS (Exit Code: $exitCode)" -ForegroundColor Green
                if ($result) {
                    Write-Host "  Output: $($result | Select-Object -First 3)" -ForegroundColor Gray
                }
            } else {
                Write-Host "  ❌ FAILED (Exit Code: $exitCode)" -ForegroundColor Red
                Write-Host "  Error: $result" -ForegroundColor Red
            }
        } catch {
            Write-Host "  ❌ EXCEPTION: $_" -ForegroundColor Red
        }
    } else {
        # Direct execution (no encoding needed)
        try {
            $result = powershell -Command $Command 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -eq 0) {
                Write-Host "  ✅ SUCCESS without encoding (Exit Code: $exitCode)" -ForegroundColor Green
            } else {
                Write-Host "  ⚠️ Exit Code: $exitCode (consider encoding)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  ❌ EXCEPTION: $_" -ForegroundColor Red
        }
    }
    
    Write-Host ""
}

# === Test Cases (from research report) ===

Write-Host "1. Pipe Character (|) Tests" -ForegroundColor Cyan
Test-Base64Encoding "Get-Service | Select-Object -First 5" "Services with pipe filter"
Test-Base64Encoding "Get-Process | Where-Object { `$_.CPU -gt 10 }" "Process filter with braces"

Write-Host "2. Braces and Variables Tests" -ForegroundColor Cyan
Test-Base64Encoding "Get-ChildItem | Where-Object { `$_.Name -like '*test*' }" "File filter with wildcard"
Test-Base64Encoding "1..5 | ForEach-Object { Write-Host `$_ }" "Loop with braces"

Write-Host "3. Special Characters Tests" -ForegroundColor Cyan
Test-Base64Encoding 'Write-Host "Hello `$USER"' "Double quotes with variable"
Test-Base64Encoding "Write-Host 'Single `$quotes'" "Single quotes test"

Write-Host "4. Complex Commands (Multi-pipe)" -ForegroundColor Cyan
Test-Base64Encoding "Get-Service | Where-Object { `$_.Status -eq 'Running' } | Select-Object Name, Status" "Multi-stage pipeline"

Write-Host "5. No Encoding Needed (Simple Commands)" -ForegroundColor Cyan
Test-Base64Encoding "Get-Date" "Simple command without special chars"
Test-Base64Encoding "dir" "Directory listing"
Test-Base64Encoding "echo test" "Echo without pipes"

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Base64 Encoding automatically applied for commands with: | {} `$ `" '" -ForegroundColor Gray
Write-Host "This fixes Exit Code 255 when passing through cmd.exe" -ForegroundColor Gray
Write-Host ""
Write-Host "NOTE: MCP server v1.2.0 auto-detects encoding requirement." -ForegroundColor Yellow
Write-Host "Can also force via useEncodedCommand: true parameter" -ForegroundColor Yellow
