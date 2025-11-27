#!/usr/bin/env pwsh
# TASK 4 TEST SCRIPT - Проверка System Status UI

Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🧪 TASK 4: SYSTEM STATUS UI - ТЕСТОВЫЕ СЦЕНАРИИ        ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Функция проверки статуса
function Get-ServiceStatus {
    param([string]$Name, [string]$Url)
    
    try {
        Invoke-RestMethod -Uri $Url -TimeoutSec 3 -ErrorAction Stop | Out-Null
        return @{ status = "UP"; color = "Green"; emoji = "✅" }
    } catch {
        return @{ status = "DOWN"; color = "Red"; emoji = "❌" }
    }
}

# ============================================================
# СЦЕНАРИЙ 1: ОБА СЕРВИСА UP
# ============================================================
Write-Host "`n━━━ СЦЕНАРИЙ 1: ОБА СЕРВИСА UP ━━━" -ForegroundColor Cyan

$ollama = Get-ServiceStatus -Name "Ollama" -Url "http://localhost:11434/api/tags"
$cortex = Get-ServiceStatus -Name "CORTEX" -Url "http://localhost:8004/health"

Write-Host "`n📊 Текущее состояние:" -ForegroundColor Yellow
Write-Host "  Ollama (11434):  $($ollama.emoji) $($ollama.status)" -ForegroundColor $ollama.color
Write-Host "  CORTEX (8004):   $($cortex.emoji) $($cortex.status)" -ForegroundColor $cortex.color

if ($ollama.status -eq "UP" -and $cortex.status -eq "UP") {
    Write-Host "`n✅ СЦЕНАРИЙ 1 ГОТОВ К ПРОВЕРКЕ" -ForegroundColor Green
    Write-Host "`n📋 Действия:" -ForegroundColor Yellow
    Write-Host "  1. Откройте приложение Tauri (должно быть запущено)" -ForegroundColor White
    Write-Host "  2. Перейдите на вкладку '📡 System Status'" -ForegroundColor White
    Write-Host "  3. Проверьте:" -ForegroundColor White
    Write-Host "     • Оба сервиса показывают 🟢 Работает" -ForegroundColor Gray
    Write-Host "     • 'Последняя проверка' отображает время" -ForegroundColor Gray
    Write-Host "     • Через 15 сек статус обновится автоматически" -ForegroundColor Gray
    Write-Host "     • Кнопка 'Обновить статус' работает мгновенно" -ForegroundColor Gray
    Write-Host "     • Нет ошибок в красном блоке" -ForegroundColor Gray
} else {
    Write-Host "`n⚠️  ВНИМАНИЕ: Не все сервисы запущены!" -ForegroundColor Yellow
    Write-Host "   Запустите недостающие сервисы для тестирования:" -ForegroundColor White
    if ($ollama.status -eq "DOWN") {
        Write-Host "   • Ollama: ollama serve" -ForegroundColor Red
    }
    if ($cortex.status -eq "DOWN") {
        Write-Host "   • CORTEX: pwsh scripts\START_ALL.ps1" -ForegroundColor Red
    }
}

Read-Host "`nНажмите Enter после проверки для перехода к Сценарию 2"

# ============================================================
# СЦЕНАРИЙ 2: ТОЛЬКО CORTEX DOWN
# ============================================================
Write-Host "`n━━━ СЦЕНАРИЙ 2: CORTEX ОТКЛЮЧЕН ━━━" -ForegroundColor Cyan

Write-Host "`n📋 Подготовка:" -ForegroundColor Yellow
Write-Host "  Остановка CORTEX..." -ForegroundColor White

try {
    pwsh E:\WORLD_OLLAMA\scripts\STOP_ALL.ps1 2>$null | Out-Null
    Start-Sleep -Seconds 2
    Write-Host "  ✅ CORTEX остановлен" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  Не удалось остановить через скрипт, попробуйте вручную" -ForegroundColor Yellow
}

$ollama = Get-ServiceStatus -Name "Ollama" -Url "http://localhost:11434/api/tags"
$cortex = Get-ServiceStatus -Name "CORTEX" -Url "http://localhost:8004/health"

Write-Host "`n📊 Текущее состояние:" -ForegroundColor Yellow
Write-Host "  Ollama (11434):  $($ollama.emoji) $($ollama.status)" -ForegroundColor $ollama.color
Write-Host "  CORTEX (8004):   $($cortex.emoji) $($cortex.status)" -ForegroundColor $cortex.color

Write-Host "`n📋 Действия:" -ForegroundColor Yellow
Write-Host "  1. В приложении Tauri нажмите 'Обновить статус'" -ForegroundColor White
Write-Host "  2. Проверьте:" -ForegroundColor White
Write-Host "     • Ollama: 🟢 Работает" -ForegroundColor Gray
Write-Host "     • CORTEX: 🔴 Не работает" -ForegroundColor Gray
Write-Host "     • Подсказки внизу видны и актуальны" -ForegroundColor Gray
Write-Host "     • UI не зависает, можно переключиться в Chat" -ForegroundColor Gray

Read-Host "`nНажмите Enter после проверки для перехода к Сценарию 3"

# ============================================================
# СЦЕНАРИЙ 3: ОБА СЕРВИСА DOWN
# ============================================================
Write-Host "`n━━━ СЦЕНАРИЙ 3: ОБА СЕРВИСА ОТКЛЮЧЕНЫ ━━━" -ForegroundColor Cyan

Write-Host "`n📋 Подготовка:" -ForegroundColor Yellow
Write-Host "  Остановка Ollama..." -ForegroundColor White

# Попытка остановить Ollama (если запущен как процесс)
$ollamaProcess = Get-Process -Name "ollama*" -ErrorAction SilentlyContinue
if ($ollamaProcess) {
    Stop-Process -Name "ollama*" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host "  ✅ Ollama остановлен" -ForegroundColor Green
} else {
    Write-Host "  ℹ️  Ollama не найден как процесс (возможно, сервис)" -ForegroundColor Gray
}

$ollama = Get-ServiceStatus -Name "Ollama" -Url "http://localhost:11434/api/tags"
$cortex = Get-ServiceStatus -Name "CORTEX" -Url "http://localhost:8004/health"

Write-Host "`n📊 Текущее состояние:" -ForegroundColor Yellow
Write-Host "  Ollama (11434):  $($ollama.emoji) $($ollama.status)" -ForegroundColor $ollama.color
Write-Host "  CORTEX (8004):   $($cortex.emoji) $($cortex.status)" -ForegroundColor $cortex.color

Write-Host "`n📋 Действия:" -ForegroundColor Yellow
Write-Host "  1. В приложении Tauri нажмите 'Обновить статус'" -ForegroundColor White
Write-Host "  2. Проверьте:" -ForegroundColor White
Write-Host "     • Оба сервиса: 🔴 Не работает" -ForegroundColor Gray
Write-Host "     • Подсказки внизу видны (про перезапуск системы)" -ForegroundColor Gray
Write-Host "     • UI остаётся живым (не крашится)" -ForegroundColor Gray
Write-Host "     • Переключение в Chat работает" -ForegroundColor Gray

Read-Host "`nНажмите Enter для восстановления сервисов"

# ============================================================
# ВОССТАНОВЛЕНИЕ СЕРВИСОВ
# ============================================================
Write-Host "`n━━━ ВОССТАНОВЛЕНИЕ СЕРВИСОВ ━━━" -ForegroundColor Cyan

Write-Host "`n📋 Запуск CORTEX..." -ForegroundColor Yellow
try {
    pwsh E:\WORLD_OLLAMA\scripts\START_ALL.ps1 -SkipNeuroTerminal 2>$null | Out-Null
    Start-Sleep -Seconds 3
    Write-Host "  ✅ CORTEX запущен" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  Запустите CORTEX вручную: pwsh scripts\START_ALL.ps1" -ForegroundColor Yellow
}

Write-Host "`n📋 Проверка Ollama..." -ForegroundColor Yellow
$ollama = Get-ServiceStatus -Name "Ollama" -Url "http://localhost:11434/api/tags"
if ($ollama.status -eq "DOWN") {
    Write-Host "  ⚠️  Запустите Ollama вручную: ollama serve" -ForegroundColor Yellow
} else {
    Write-Host "  ✅ Ollama работает" -ForegroundColor Green
}

Start-Sleep -Seconds 2

$ollama = Get-ServiceStatus -Name "Ollama" -Url "http://localhost:11434/api/tags"
$cortex = Get-ServiceStatus -Name "CORTEX" -Url "http://localhost:8004/health"

Write-Host "`n📊 Финальное состояние:" -ForegroundColor Yellow
Write-Host "  Ollama (11434):  $($ollama.emoji) $($ollama.status)" -ForegroundColor $ollama.color
Write-Host "  CORTEX (8004):   $($cortex.emoji) $($cortex.status)" -ForegroundColor $cortex.color

# ============================================================
# ИТОГОВЫЙ ОТЧЁТ
# ============================================================
Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  📊 ИТОГОВЫЙ ОТЧЁТ                                        ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n✅ Проверьте следующие пункты в приложении:" -ForegroundColor Green
Write-Host "`n  1. Навигация Chat ↔ System Status:" -ForegroundColor White
Write-Host "     □ Переключение между вкладками работает" -ForegroundColor Gray
Write-Host "     □ Выбранная вкладка подсвечена зелёным" -ForegroundColor Gray
Write-Host "     □ Hover эффекты на кнопках навигации" -ForegroundColor Gray

Write-Host "`n  2. System Status UI:" -ForegroundColor White
Write-Host "     □ Карточки Ollama и CORTEX видны" -ForegroundColor Gray
Write-Host "     □ Статусы отображаются корректно (🟢/🔴/🟡)" -ForegroundColor Gray
Write-Host "     □ 'Последняя проверка' обновляется" -ForegroundColor Gray
Write-Host "     □ Автообновление каждые 15 сек работает" -ForegroundColor Gray
Write-Host "     □ Кнопка 'Обновить статус' работает мгновенно" -ForegroundColor Gray

Write-Host "`n  3. Подсказки и UX:" -ForegroundColor White
Write-Host "     □ Блок 'Если что-то не работает' виден" -ForegroundColor Gray
Write-Host "     □ Подсказки содержат команды (код стиль)" -ForegroundColor Gray
Write-Host "     □ При ошибках появляется красный блок" -ForegroundColor Gray

Write-Host "`n  4. Сценарии (протестированы):" -ForegroundColor White
Write-Host "     □ Оба UP: всё зелёное, без ошибок" -ForegroundColor Gray
Write-Host "     □ CORTEX DOWN: Ollama 🟢, CORTEX 🔴" -ForegroundColor Gray
Write-Host "     □ Оба DOWN: всё красное, UI живой" -ForegroundColor Gray

Write-Host "`n  5. Стабильность:" -ForegroundColor White
Write-Host "     □ UI не крашится при недоступных сервисах" -ForegroundColor Gray
Write-Host "     □ Автообновление не вызывает зависаний" -ForegroundColor Gray
Write-Host "     □ Переключение в Chat из любого статуса работает" -ForegroundColor Gray

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

Write-Host "💡 Для финального отчёта отметьте все проверенные пункты выше.`n" -ForegroundColor Yellow
