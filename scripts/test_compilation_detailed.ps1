# ОРДЕР №19 - КОМАНДА 2.1: Детальная проверка компиляции
# Версия: 2.0 (с полным выводом ошибок)

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "ОРДЕР №19 - КОМАНДА 2.1: КОМПИЛЯЦИЯ v0.2.0 (DETAILED)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Continue"

# ═══════════════════════════════════════════════════════════════
# RUST BACKEND: cargo check
# ═══════════════════════════════════════════════════════════════

Write-Host "[RUST BACKEND] Запуск cargo check..." -ForegroundColor Yellow
Write-Host "Директория: client\src-tauri" -ForegroundColor Gray
Write-Host ""

Push-Location "client\src-tauri"

Write-Host "─────────────────── НАЧАЛО ВЫВОДА ───────────────────────" -ForegroundColor DarkGray
cargo check
$rust_exit = $LASTEXITCODE
Write-Host "─────────────────── КОНЕЦ ВЫВОДА ────────────────────────" -ForegroundColor DarkGray
Write-Host ""

if ($rust_exit -eq 0) {
    Write-Host "✅ RUST: PASS" -ForegroundColor Green
}
else {
    Write-Host "❌ RUST: FAIL (exit code: $rust_exit)" -ForegroundColor Red
}

Pop-Location
Write-Host ""
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# FRONTEND: npm run check
# ═══════════════════════════════════════════════════════════════

Write-Host "[FRONTEND] Запуск npm run check..." -ForegroundColor Yellow
Write-Host "Директория: client" -ForegroundColor Gray
Write-Host ""

Push-Location "client"

Write-Host "─────────────────── НАЧАЛО ВЫВОДА ───────────────────────" -ForegroundColor DarkGray
npm run check
$npm_exit = $LASTEXITCODE
Write-Host "─────────────────── КОНЕЦ ВЫВОДА ────────────────────────" -ForegroundColor DarkGray
Write-Host ""

if ($npm_exit -eq 0) {
    Write-Host "✅ FRONTEND: PASS" -ForegroundColor Green
}
else {
    Write-Host "❌ FRONTEND: FAIL (exit code: $npm_exit)" -ForegroundColor Red
}

Pop-Location
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# РЕЗУЛЬТАТ
# ═══════════════════════════════════════════════════════════════

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "ИТОГОВЫЙ РЕЗУЛЬТАТ" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

if ($rust_exit -eq 0 -and $npm_exit -eq 0) {
    Write-Host "🎉 ВСЕ ТЕСТЫ ПРОЙДЕНЫ!" -ForegroundColor Green
    Write-Host "Готов к переходу к КОМАНДЕ 2.2 (E2E тесты)" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "⚠️ ОБНАРУЖЕНЫ ОШИБКИ:" -ForegroundColor Red
    if ($rust_exit -ne 0) { Write-Host "  - Rust Backend провален" -ForegroundColor Red }
    if ($npm_exit -ne 0) { Write-Host "  - Frontend провален" -ForegroundColor Red }
    Write-Host ""
    Write-Host "Смотрите детальный вывод выше для диагностики." -ForegroundColor Yellow
    exit 1
}
