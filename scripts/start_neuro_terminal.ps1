param(
    [int]$Port = 8501
)

$projectRoot = "E:\WORLD_OLLAMA\services\neuro_terminal"
$venvActivate = Join-Path $projectRoot ".venv\Scripts\Activate.ps1"

if (-not (Test-Path $venvActivate)) {
    Write-Error "Virtual environment not found at $venvActivate"
    exit 1
}

Push-Location $projectRoot
try {
    . $venvActivate

    if (-not $env:NEURO_OLLAMA_HOST) {
        $env:NEURO_OLLAMA_HOST = "http://127.0.0.1:11434"
    }

    chainlit run app.py --host 0.0.0.0 --port $Port
}
finally {
    Pop-Location
}
