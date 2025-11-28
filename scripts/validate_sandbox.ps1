
# validate_sandbox.ps1
# Runs the autonomous smoke test in the sandbox environment.

$rootPath = "E:\WORLD_OLLAMA"
$sandboxPath = Join-Path $rootPath "workbench\sandbox_main"
$testScript = Join-Path $sandboxPath "tests\autonomous_smoke_test.py"
$venvPath = Join-Path $sandboxPath ".venv"

Write-Host "Starting Sandbox Validation..."
Write-Host "Target Test: $testScript"

if (-not (Test-Path $testScript)) {
    Write-Error "Test script not found!"
    exit 1
}

# Activate Virtual Environment if it exists
if (Test-Path $venvPath) {
    Write-Host "Activating virtual environment: $venvPath"
    $env:VIRTUAL_ENV = $venvPath
    $env:Path = "$venvPath\Scripts;$env:Path"
} else {
    Write-Warning "Virtual environment not found at $venvPath. Attempting to run with system Python."
}

# Run the test
Write-Host "Running smoke test..."
try {
    python $testScript
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Sandbox Validation PASSED" -ForegroundColor Green
    } else {
        Write-Host "❌ Sandbox Validation FAILED (Exit Code: $LASTEXITCODE)" -ForegroundColor Red
    }
} catch {
    Write-Error "Failed to execute python script: $_"
}
