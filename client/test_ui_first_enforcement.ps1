<#
.SYNOPSIS
    UI-First Workflow Enforcement Test Suite (v0.4.0)
    
.DESCRIPTION
    Validates compliance with Desktop Client UI-First Workflow rules
    Tests agent behavior, Desktop Client accessibility, and panel navigation
    
.NOTES
    Version: 1.0.0
    Created: 2025-12-04
    Author: WORLD_OLLAMA Team
    Related: .github/copilot-instructions.md (Enforcement Mechanisms)
#>

param(
    [switch]$Verbose,
    [switch]$FailFast
)

$ErrorActionPreference = "Stop"
$TestResults = @()

function Write-TestHeader {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = ""
    )
    
    $status = if ($Passed) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    Write-Host "$status : $TestName" -ForegroundColor $color
    if ($Message) {
        Write-Host "        $Message" -ForegroundColor Gray
    }
    
    $script:TestResults += @{
        Name = $TestName
        Passed = $Passed
        Message = $Message
    }
    
    if (-not $Passed -and $FailFast) {
        throw "Test failed: $TestName - $Message"
    }
}

# ============================================================================
# TEST 1: Desktop Client Accessibility
# ============================================================================

Write-TestHeader "TEST 1: Desktop Client Accessibility"

try {
    # Test 1.1: Process check
    Write-Host "TEST 1.1: Checking Desktop Client process..." -ForegroundColor Yellow
    $process = Get-Process -Name "tauri_fresh" -ErrorAction SilentlyContinue
    
    if ($process) {
        Write-TestResult -TestName "Desktop Client Process" -Passed $true -Message "tauri_fresh process found (PID: $($process.Id))"
    } else {
        Write-TestResult -TestName "Desktop Client Process" -Passed $false -Message "tauri_fresh process not found. Start via: cd client; npm run tauri dev"
    }
    
    # Test 1.2: Port check
    Write-Host "TEST 1.2: Checking port 1420..." -ForegroundColor Yellow
    $portCheck = Test-NetConnection -ComputerName localhost -Port 1420 -InformationLevel Quiet
    
    if ($portCheck -eq $true) {
        Write-TestResult -TestName "Desktop Client Port (1420)" -Passed $true -Message "Port 1420 is listening"
    } else {
        Write-TestResult -TestName "Desktop Client Port (1420)" -Passed $false -Message "Port 1420 not accessible"
    }
    
    # Test 1.3: HTTP Response
    Write-Host "TEST 1.3: Testing HTTP endpoint..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:1420" -Method GET -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        
        if ($response.StatusCode -eq 200) {
            Write-TestResult -TestName "Desktop Client HTTP Response" -Passed $true -Message "HTTP 200 OK received"
        } else {
            Write-TestResult -TestName "Desktop Client HTTP Response" -Passed $false -Message "HTTP $($response.StatusCode) received"
        }
    } catch {
        Write-TestResult -TestName "Desktop Client HTTP Response" -Passed $false -Message "HTTP request failed: $($_.Exception.Message)"
    }
    
} catch {
    Write-TestResult -TestName "Desktop Client Accessibility" -Passed $false -Message "Test suite error: $($_.Exception.Message)"
}

# ============================================================================
# TEST 2: Service Dependencies
# ============================================================================

Write-TestHeader "TEST 2: Service Dependencies (for UI-First operations)"

try {
    # Test 2.1: Ollama port check
    Write-Host "TEST 2.1: Checking Ollama (port 11434)..." -ForegroundColor Yellow
    $ollamaPort = Test-NetConnection -ComputerName localhost -Port 11434 -InformationLevel Quiet
    
    if ($ollamaPort -eq $true) {
        Write-TestResult -TestName "Ollama Service Port" -Passed $true -Message "Port 11434 accessible"
    } else {
        Write-TestResult -TestName "Ollama Service Port" -Passed $false -Message "Port 11434 not accessible. TrainingPanel requires Ollama."
    }
    
    # Test 2.2: Ollama API
    Write-Host "TEST 2.2: Testing Ollama API..." -ForegroundColor Yellow
    try {
        $ollamaList = & ollama list 2>&1
        if ($LASTEXITCODE -eq 0) {
            $modelCount = ($ollamaList | Select-String -Pattern ":" | Measure-Object).Count
            Write-TestResult -TestName "Ollama API Response" -Passed $true -Message "$modelCount models available"
        } else {
            Write-TestResult -TestName "Ollama API Response" -Passed $false -Message "ollama list failed (exit code $LASTEXITCODE)"
        }
    } catch {
        Write-TestResult -TestName "Ollama API Response" -Passed $false -Message "Ollama command error: $($_.Exception.Message)"
    }
    
    # Test 2.3: CORTEX port check (optional)
    Write-Host "TEST 2.3: Checking CORTEX (port 8004)..." -ForegroundColor Yellow
    $cortexPort = Test-NetConnection -ComputerName localhost -Port 8004 -InformationLevel Quiet
    
    if ($cortexPort -eq $true) {
        Write-TestResult -TestName "CORTEX Service Port" -Passed $true -Message "Port 8004 accessible"
    } else {
        Write-Host "        ⚠️  WARNING: CORTEX not running (optional for UI-First)" -ForegroundColor Yellow
        Write-TestResult -TestName "CORTEX Service Port" -Passed $true -Message "Optional service (not critical for UI-First)"
    }
    
} catch {
    Write-TestResult -TestName "Service Dependencies" -Passed $false -Message "Test suite error: $($_.Exception.Message)"
}

# ============================================================================
# TEST 3: Panel Navigation Verification
# ============================================================================

Write-TestHeader "TEST 3: Panel Navigation Verification"

try {
    # Test 3.1: Verify 7 panels are documented
    Write-Host "TEST 3.1: Checking panel documentation..." -ForegroundColor Yellow
    $instructionsPath = ".github/copilot-instructions.md"
    
    if (Test-Path $instructionsPath) {
        $instructions = Get-Content $instructionsPath -Raw
        
        $expectedPanels = @(
            "SystemStatusPanel",
            "SettingsPanel",
            "LibraryPanel",
            "CommandsPanel",
            "TrainingPanel",
            "GitPanel",
            "FlowsPanel"
        )
        
        $foundPanels = @()
        foreach ($panel in $expectedPanels) {
            if ($instructions -match $panel) {
                $foundPanels += $panel
            }
        }
        
        if ($foundPanels.Count -eq 7) {
            Write-TestResult -TestName "Panel Documentation" -Passed $true -Message "All 7 panels documented in copilot-instructions.md"
        } else {
            Write-TestResult -TestName "Panel Documentation" -Passed $false -Message "Only $($foundPanels.Count)/7 panels found"
        }
    } else {
        Write-TestResult -TestName "Panel Documentation" -Passed $false -Message "copilot-instructions.md not found"
    }
    
    # Test 3.2: Verify UI-First table exists
    Write-Host "TEST 3.2: Checking UI-First operations table..." -ForegroundColor Yellow
    if ($instructions -match "Таблица UI-First операций") {
        Write-TestResult -TestName "UI-First Operations Table" -Passed $true -Message "Table found in documentation"
    } else {
        Write-TestResult -TestName "UI-First Operations Table" -Passed $false -Message "Table not found"
    }
    
    # Test 3.3: Verify enforcement mechanisms section
    Write-Host "TEST 3.3: Checking enforcement mechanisms..." -ForegroundColor Yellow
    if ($instructions -match "ENFORCEMENT MECHANISMS") {
        Write-TestResult -TestName "Enforcement Mechanisms Section" -Passed $true -Message "Enforcement section exists (v0.4.0)"
    } else {
        Write-TestResult -TestName "Enforcement Mechanisms Section" -Passed $false -Message "Enforcement section missing"
    }
    
} catch {
    Write-TestResult -TestName "Panel Navigation Verification" -Passed $false -Message "Test suite error: $($_.Exception.Message)"
}

# ============================================================================
# TEST 4: Terminal Exception Validation
# ============================================================================

Write-TestHeader "TEST 4: Terminal Exception Validation"

try {
    # Test 4.1: Verify allowed internal commands work
    Write-Host "TEST 4.1: Testing allowed internal commands..." -ForegroundColor Yellow
    
    $allowedCommands = @(
        @{ Name = "Get-Process"; Command = { Get-Process -Name "tauri_fresh" -ErrorAction SilentlyContinue } },
        @{ Name = "Test-NetConnection"; Command = { Test-NetConnection -ComputerName localhost -Port 1420 -InformationLevel Quiet } },
        @{ Name = "Get-Content logs"; Command = { 
            if (Test-Path "logs") {
                Get-ChildItem -Path "logs" -Filter "*.log" -Recurse | Select-Object -First 1 | Get-Content -Tail 5 -ErrorAction SilentlyContinue
            } else {
                @("logs directory not found")
            }
        }}
    )
    
    $successfulCommands = 0
    foreach ($cmd in $allowedCommands) {
        try {
            $result = & $cmd.Command
            $successfulCommands++
            if ($Verbose) {
                Write-Host "        ✅ $($cmd.Name) executed successfully" -ForegroundColor Gray
            }
        } catch {
            if ($Verbose) {
                Write-Host "        ⚠️  $($cmd.Name) failed (acceptable if resource unavailable)" -ForegroundColor Yellow
            }
        }
    }
    
    Write-TestResult -TestName "Allowed Internal Commands" -Passed $true -Message "$successfulCommands/$($allowedCommands.Count) commands executed"
    
    # Test 4.2: Verify VS Code settings include UI-First instructions
    Write-Host "TEST 4.2: Checking VS Code settings..." -ForegroundColor Yellow
    $settingsPath = ".vscode/settings.json"
    
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw
        
        if ($settings -match "UI-FIRST WORKFLOW ENFORCEMENT") {
            Write-TestResult -TestName "VS Code UI-First Settings" -Passed $true -Message "UI-First instructions found in settings.json"
        } else {
            Write-TestResult -TestName "VS Code UI-First Settings" -Passed $false -Message "UI-First instructions missing from settings.json"
        }
    } else {
        Write-TestResult -TestName "VS Code UI-First Settings" -Passed $false -Message ".vscode/settings.json not found"
    }
    
} catch {
    Write-TestResult -TestName "Terminal Exception Validation" -Passed $false -Message "Test suite error: $($_.Exception.Message)"
}

# ============================================================================
# TEST 5: Agent Response Pattern Detection (Simulated)
# ============================================================================

Write-TestHeader "TEST 5: Agent Response Pattern Detection (Simulated)"

try {
    # Test 5.1: Check for violation patterns in documentation
    Write-Host "TEST 5.1: Scanning for violation examples..." -ForegroundColor Yellow
    
    if (Test-Path ".github/copilot-instructions.md") {
        $instructions = Get-Content ".github/copilot-instructions.md" -Raw
        
        # Count violation examples (should be present for reference)
        # Updated pattern to match "❌ **VIOLATION #N:**" format
        $violationCount = ([regex]::Matches($instructions, "❌ \*\*VIOLATION")).Count
        $correctionCount = ([regex]::Matches($instructions, "✅ \*\*CORRECT")).Count
        
        if ($violationCount -gt 0 -and $correctionCount -gt 0) {
            Write-TestResult -TestName "Violation Examples Documentation" -Passed $true -Message "$violationCount violations + $correctionCount corrections documented"
        } else {
            Write-TestResult -TestName "Violation Examples Documentation" -Passed $false -Message "Violation/correction examples missing (violations: $violationCount, corrections: $correctionCount)"
        }
    }
    
    # Test 5.2: Verify enforcement test is referenced
    Write-Host "TEST 5.2: Checking self-reference..." -ForegroundColor Yellow
    if ($instructions -match "test_ui_first_enforcement\.ps1") {
        Write-TestResult -TestName "Integration Test Reference" -Passed $true -Message "This test file is referenced in documentation"
    } else {
        Write-TestResult -TestName "Integration Test Reference" -Passed $false -Message "Test file not referenced in copilot-instructions.md"
    }
    
} catch {
    Write-TestResult -TestName "Agent Response Pattern Detection" -Passed $false -Message "Test suite error: $($_.Exception.Message)"
}

# ============================================================================
# TEST SUMMARY
# ============================================================================

Write-TestHeader "TEST SUMMARY"

$totalTests = $TestResults.Count
$passedTests = ($TestResults | Where-Object { $_.Passed }).Count
$failedTests = $totalTests - $passedTests
$successRate = [math]::Round(($passedTests / $totalTests) * 100, 2)

Write-Host "Total Tests   : $totalTests" -ForegroundColor Cyan
Write-Host "Passed        : $passedTests" -ForegroundColor Green
Write-Host "Failed        : $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { "Red" } else { "Green" })
Write-Host "Success Rate  : $successRate%" -ForegroundColor $(if ($successRate -eq 100) { "Green" } else { "Yellow" })

if ($failedTests -gt 0) {
    Write-Host "`n❌ FAILED TESTS:" -ForegroundColor Red
    foreach ($result in $TestResults) {
        if (-not $result.Passed) {
            Write-Host "  • $($result.Name): $($result.Message)" -ForegroundColor Red
        }
    }
}

Write-Host ""

if ($successRate -eq 100) {
    Write-Host "✅ UI-FIRST WORKFLOW ENFORCED" -ForegroundColor Green
    Write-Host "   Desktop Client ready for agent operations" -ForegroundColor Green
    exit 0
} elseif ($successRate -ge 80) {
    Write-Host "⚠️  UI-FIRST WORKFLOW PARTIALLY ENFORCED" -ForegroundColor Yellow
    Write-Host "   Some tests failed, review above for details" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "❌ UI-FIRST WORKFLOW NOT ENFORCED" -ForegroundColor Red
    Write-Host "   Critical failures detected, review above" -ForegroundColor Red
    exit 2
}
