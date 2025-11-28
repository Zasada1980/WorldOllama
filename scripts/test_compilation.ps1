# ОРДЕР №19 - КОМАНДА 2.1: Автоматическая проверка компиляции
# Дата: 28 ноября 2025 г.
# Цель: Проверить Rust + TypeScript компиляцию без ошибок

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "ОРДЕР №19 - КОМАНДА 2.1: КОМПИЛЯЦИЯ v0.2.0" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Continue"
$results = @()

# ═══════════════════════════════════════════════════════════════
# ПРОВЕРКА ВЕРСИЙ TOOLCHAIN
# ═══════════════════════════════════════════════════════════════

Write-Host "[1/6] Проверка версий toolchain..." -ForegroundColor Yellow

$rustc_version = rustc --version 2>&1
$cargo_version = cargo --version 2>&1
$node_version = node --version 2>&1
$npm_version = npm --version 2>&1
$python_version = python --version 2>&1

Write-Host "  Rust : $rustc_version" -ForegroundColor Green
Write-Host "  Cargo: $cargo_version" -ForegroundColor Green
Write-Host "  Node : $node_version" -ForegroundColor Green
Write-Host "  npm  : $npm_version" -ForegroundColor Green
Write-Host "  Python: $python_version" -ForegroundColor Green
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# RUST BACKEND: cargo check
# ═══════════════════════════════════════════════════════════════

Write-Host "[2/6] Rust Backend: cargo check..." -ForegroundColor Yellow
Push-Location "client\src-tauri"

$cargo_output = cargo check 2>&1
$cargo_exitcode = $LASTEXITCODE

if ($cargo_exitcode -eq 0) {
    Write-Host "  ✅ PASS: Rust компиляция успешна" -ForegroundColor Green
    $results += @{Step="Rust Backend"; Status="PASS"; Output=$cargo_output}
} else {
    Write-Host "  ❌ FAIL: Rust компиляция провалена" -ForegroundColor Red
    $results += @{Step="Rust Backend"; Status="FAIL"; Output=$cargo_output}
}

Pop-Location
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# FRONTEND: npm run check
# ═══════════════════════════════════════════════════════════════

Write-Host "[3/6] Frontend: npm run check..." -ForegroundColor Yellow
Push-Location "client"

# Убедимся что node_modules установлены
if (-not (Test-Path "node_modules")) {
    Write-Host "  ⚠️ node_modules не найдены, запуск npm install..." -ForegroundColor Yellow
    npm install 2>&1 | Out-Null
}

$npm_output = npm run check 2>&1
$npm_exitcode = $LASTEXITCODE

if ($npm_exitcode -eq 0) {
    Write-Host "  ✅ PASS: TypeScript/Svelte проверка успешна" -ForegroundColor Green
    $results += @{Step="Frontend"; Status="PASS"; Output=$npm_output}
} else {
    Write-Host "  ❌ FAIL: TypeScript/Svelte проверка провалена" -ForegroundColor Red
    $results += @{Step="Frontend"; Status="FAIL"; Output=$npm_output}
}

Pop-Location
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# РЕЗУЛЬТАТ
# ═══════════════════════════════════════════════════════════════

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "РЕЗУЛЬТАТ КОМПИЛЯЦИИ" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$pass_count = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$fail_count = ($results | Where-Object { $_.Status -eq "FAIL" }).Count

foreach ($result in $results) {
    $color = if ($result.Status -eq "PASS") { "Green" } else { "Red" }
    Write-Host "$($result.Step): $($result.Status)" -ForegroundColor $color
}

Write-Host ""
Write-Host "Успешно: $pass_count / $($results.Count)" -ForegroundColor $(if ($fail_count -eq 0) { "Green" } else { "Yellow" })

if ($fail_count -eq 0) {
    Write-Host ""
    Write-Host "🎉 ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ! Готов к E2E тестам." -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "⚠️ ОБНАРУЖЕНЫ ОШИБКИ! Смотрите детали выше." -ForegroundColor Red
    exit 1
}
