# ORDER 42.2 - Direct API Test (bypassing UI)
# This script calls the Rust backend API directly to test start_training_job

Write-Host "🧪 ORDER 42.2 - Testing start_training_job API directly..." -ForegroundColor Cyan
Write-Host ""

# Параметры для теста
$profile = "default"
$dataPath = "E:\WORLD_OLLAMA\library\raw_documents"
$epochs = 1
$mode = "llama_factory"

Write-Host "Test parameters:" -ForegroundColor Yellow
Write-Host "  Profile: $profile"
Write-Host "  Data Path: $dataPath"
Write-Host "  Epochs: $epochs"
Write-Host "  Mode: $mode"
Write-Host ""

# NOTE: Этот скрипт НЕ МОЖЕТ напрямую вызвать Tauri команду
# Tauri команды доступны только через WebView (JavaScript invoke)
# 
# Для теста нужно:
# 1. Открыть Tauri приложение
# 2. Открыть DevTools (F12)
# 3. Выполнить в консоли:

$jsCode = @"
await window.__TAURI__.core.invoke('start_training_job', {
  profile: '$profile',
  dataPath: '$dataPath',
  epochs: $epochs,
  mode: '$mode'
})
"@

Write-Host "⚠️  PowerShell НЕ МОЖЕТ напрямую вызвать Tauri команду." -ForegroundColor Red
Write-Host ""
Write-Host "Для ручного теста через DevTools (F12):" -ForegroundColor Yellow
Write-Host "----------------------------------------"
Write-Host $jsCode -ForegroundColor Green
Write-Host "----------------------------------------"
Write-Host ""
Write-Host "ИЛИ просто нажми кнопку 'Запустить обучение' в UI! 🖱️" -ForegroundColor Cyan
