param(
    [switch]$Background
)

$ErrorActionPreference = "Stop"

# Определение корня проекта (скрипт в services\lightrag)
$ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
$ServerScript = Join-Path $ProjectRoot "services\lightrag\lightrag_server.py"
$VenvPython = Join-Path $ProjectRoot ".venv\Scripts\python.exe"

if (-not (Test-Path $ServerScript)) {
    throw "Файл сервера не найден: $ServerScript"
}

# Выбор интерпретатора Python
$PythonExe = if (Test-Path $VenvPython) { $VenvPython } else { "python" }

Write-Host "[START] LightRAG server" -ForegroundColor Cyan
Write-Host "Project root: $ProjectRoot"
Write-Host "Python: $PythonExe"
Write-Host "Script: $ServerScript"

if ($Background) {
    Start-Process -FilePath $PythonExe -ArgumentList $ServerScript -WorkingDirectory $ProjectRoot -WindowStyle Hidden
    Write-Host "Запущено в фоне. Проверка: Invoke-RestMethod http://127.0.0.1:8004/health" -ForegroundColor Green
} else {
    & $PythonExe $ServerScript
}
