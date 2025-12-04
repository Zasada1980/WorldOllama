# RUN_UI_AUTOTESTS.ps1
# Запуск UI автотестов (Playwright) для Desktop Client
# Usage: pwsh scripts/RUN_UI_AUTOTESTS.ps1

$ErrorActionPreference = "Stop"

Write-Host "Запуск UI автотестов Playwright..." -ForegroundColor Cyan
cd "E:\WORLD_OLLAMA\client"

# Установка Playwright (если не установлен)
if (-not (Test-Path "node_modules/@playwright/test")) {
    Write-Host "Установка Playwright..." -ForegroundColor Yellow
    npm i -D @playwright/test
    npx playwright install
}

# Запуск тестов
 npx playwright test tests/ui/basic_panels.spec.ts --reporter=html,json > E:\WORLD_OLLAMA\docs\qa\UI_AUTOTEST_REPORT.md

Write-Host "UI автотесты завершены. Отчёт: docs/qa/UI_AUTOTEST_REPORT.md" -ForegroundColor Green
