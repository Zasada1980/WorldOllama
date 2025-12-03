# ============================================================================
# ТЕСТОВЫЙ СКРИПТ ДЛЯ ДИАГНОСТИКИ DESKTOP CLIENT
# ============================================================================

Write-Host ""
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   ДИАГНОСТИКА DESKTOP CLIENT               ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Шаг 1: Проверка сервисов
Write-Host "[1/4] Проверка backend сервисов..." -ForegroundColor Yellow
Write-Host ""

$services = @{
    "Ollama (11434)" = "http://127.0.0.1:11434/api/tags"
    "CORTEX (8004)"  = "http://127.0.0.1:8004/health"
}

$allOk = $true
foreach ($name in $services.Keys) {
    Write-Host "  $name : " -NoNewline
    try {
        $response = Invoke-RestMethod -Uri $services[$name] -TimeoutSec 3 -ErrorAction Stop
        Write-Host "✅ OK" -ForegroundColor Green
    } catch {
        Write-Host "❌ FAILED" -ForegroundColor Red
        $allOk = $false
    }
}

if (-not $allOk) {
    Write-Host ""
    Write-Host "⚠ Сервисы не запущены! Запустите:" -ForegroundColor Yellow
    Write-Host "  pwsh scripts\START_ALL.ps1" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# Шаг 2: Остановка старого приложения
Write-Host ""
Write-Host "[2/4] Остановка старого Desktop Client..." -ForegroundColor Yellow
Get-Process tauri_fresh -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1
Write-Host "  ✓ Готово" -ForegroundColor Gray

# Шаг 3: Проверка exe файла
Write-Host ""
Write-Host "[3/4] Проверка exe файла..." -ForegroundColor Yellow
$exe = "E:\WORLD_OLLAMA\client\src-tauri\target\release\tauri_fresh.exe"

if (Test-Path $exe) {
    $file = Get-Item $exe
    Write-Host "  ✓ Файл найден" -ForegroundColor Gray
    Write-Host "    Размер: $([math]::Round($file.Length/1MB,2)) MB" -ForegroundColor Gray
    Write-Host "    Дата: $($file.LastWriteTime)" -ForegroundColor Gray
} else {
    Write-Host "  ❌ Файл не найден!" -ForegroundColor Red
    Write-Host "    Запустите: pwsh WORLD_OLLAMA_LAUNCH.ps1" -ForegroundColor Yellow
    exit 1
}

# Шаг 4: Запуск приложения
Write-Host ""
Write-Host "[4/4] Запуск Desktop Client..." -ForegroundColor Yellow
Start-Process $exe
Start-Sleep -Seconds 3

if (Get-Process tauri_fresh -ErrorAction SilentlyContinue) {
    Write-Host "  ✓ Приложение запущено" -ForegroundColor Green
} else {
    Write-Host "  ❌ Приложение не запустилось" -ForegroundColor Red
    exit 1
}

# Финальные инструкции
Write-Host ""
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✅ DESKTOP CLIENT ЗАПУЩЕН                ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "📋 ИНСТРУКЦИИ ПО ПРОВЕРКЕ:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Откройте окно Desktop Client" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. Проверьте КАЖДУЮ вкладку:" -ForegroundColor Yellow
Write-Host "   • Workflow Map (стартовая)" -ForegroundColor Gray
Write-Host "   • Chat" -ForegroundColor Gray
Write-Host "   • Status" -ForegroundColor Gray
Write-Host "   • Settings" -ForegroundColor Gray
Write-Host "   • Library" -ForegroundColor Gray
Write-Host "   • Commands" -ForegroundColor Gray
Write-Host "   • Training" -ForegroundColor Gray
Write-Host "   • Flows" -ForegroundColor Gray
Write-Host "   • Git Push" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Если видите 'ERR_CONNECTION_REFUSED localhost':" -ForegroundColor Yellow
Write-Host "   → Запишите НА КАКОЙ ВКЛАДКЕ появляется ошибка" -ForegroundColor Red
Write-Host "   → Сделайте скриншот" -ForegroundColor Red
Write-Host ""
Write-Host "4. Если ВСЕ вкладки работают:" -ForegroundColor Yellow
Write-Host "   → Проблема РЕШЕНА! ✅" -ForegroundColor Green
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
