# ═══════════════════════════════════════════════════════════════════════════════
# MCP SHELL — ГЛОБАЛЬНЫЙ ИНСТРУМЕНТ VS CODE
# Полная независимость от проекта WORLD_OLLAMA
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n╔════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✅ MCP SHELL — ГЛОБАЛЬНЫЙ ИНСТРУМЕНТ     ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "📦 НОВОЕ РАСПОЛОЖЕНИЕ MCP SHELL:" -ForegroundColor Cyan
Write-Host "   C:\Users\zakon\AppData\Roaming\Code\User\mcp-servers\myshell\`n" -ForegroundColor White

Write-Host "📂 Структура глобальной директории:" -ForegroundColor Cyan
$items = @(
    "dist\server.js (скомпилированный сервер)",
    "dist\error_catalog.js (каталог ошибок)",
    "config\terminal_timeout_policy.json (конфигурация таймаутов)",
    "node_modules\ (зависимости)",
    "package.json (метаданные)",
    "server.ts, error_catalog.ts (исходники)"
)
foreach ($item in $items) {
    Write-Host "   • $item" -ForegroundColor Gray
}

Write-Host "`n🔧 ИЗМЕНЕНИЯ В КОДЕ:" -ForegroundColor Cyan
Write-Host "   • loadTimeoutPolicy(): теперь ищет config рядом с server.js" -ForegroundColor White
Write-Host "   • Убрана зависимость от WORLD_OLLAMA_ROOT" -ForegroundColor White
Write-Host "   • Логирование работает через process.cwd() (любой проект)" -ForegroundColor White

Write-Host "`n📝 ОБНОВЛЁННЫЕ КОНФИГУРАЦИИ:" -ForegroundColor Cyan
Write-Host "   1. C:\Users\zakon\AppData\Roaming\Code\User\mcp.json" -ForegroundColor Yellow
Write-Host "      • args: C:/Users/.../mcp-servers/myshell/dist/server.js" -ForegroundColor White
Write-Host "      • env: удалён WORLD_OLLAMA_ROOT" -ForegroundColor White
Write-Host "      • Backup: mcp.json.backup_global_20251203_104059`n" -ForegroundColor Gray

Write-Host "   2. C:\Users\zakon\AppData\Roaming\Code\User\prompts\mpc-shell.toolsets.jsonc" -ForegroundColor Yellow
Write-Host "      • Добавлен toolset 'myshell'" -ForegroundColor White
Write-Host "      • Описание и иконка terminal`n" -ForegroundColor White

Write-Host "✅ ПРЕИМУЩЕСТВА ГЛОБАЛЬНОГО MCP SHELL:" -ForegroundColor Green
Write-Host "   ✓ Работает во ВСЕХ проектах VS Code" -ForegroundColor White
Write-Host "   ✓ НЕ зависит от репозитория WORLD_OLLAMA" -ForegroundColor White
Write-Host "   ✓ Выдержит удаление проекта E:\WORLD_OLLAMA" -ForegroundColor White
Write-Host "   ✓ Выдержит перенос проекта на другой диск/компьютер" -ForegroundColor White
Write-Host "   ✓ Стал частью инструментов VS Code (как GitHub Copilot)" -ForegroundColor White
Write-Host "   ✓ Логи пишутся в текущий проект (logs/mcp/mcp-events.log)" -ForegroundColor White

Write-Host "`n⚠️  ПОСЛЕДНИЙ ШАГ — ПЕРЕЗАПУСК VS CODE:" -ForegroundColor Yellow
Write-Host "   Ctrl+Shift+P → 'Developer: Reload Window'`n" -ForegroundColor White

Write-Host "🧪 ПРОВЕРКА ПОСЛЕ ПЕРЕЗАПУСКА:" -ForegroundColor Cyan
Write-Host "   1. Откройте ЛЮБОЙ проект в VS Code (не обязательно WORLD_OLLAMA)" -ForegroundColor White
Write-Host "   2. Скажите Copilot: 'Проверь myshell/health_check'" -ForegroundColor White
Write-Host "   3. Ожидаемый ответ: JSON с status 'ok'`n" -ForegroundColor White

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

Write-Host "`n📊 СРАВНЕНИЕ ДО И ПОСЛЕ:`n" -ForegroundColor Cyan

Write-Host "❌ ДО (зависимость от проекта):" -ForegroundColor Red
Write-Host "   • Путь: E:/WORLD_OLLAMA/mcp-shell/dist/server.js" -ForegroundColor Gray
Write-Host "   • Env: WORLD_OLLAMA_ROOT=E:/WORLD_OLLAMA" -ForegroundColor Gray
Write-Host "   • Риск: удаление проекта → MCP Shell не работает" -ForegroundColor Gray
Write-Host "   • Область: только проект WORLD_OLLAMA`n" -ForegroundColor Gray

Write-Host "✅ ПОСЛЕ (глобальный инструмент):" -ForegroundColor Green
Write-Host "   • Путь: C:/Users/.../Code/User/mcp-servers/myshell/dist/server.js" -ForegroundColor Gray
Write-Host "   • Env: только MCP_LOG_MIRROR_ROOT=1" -ForegroundColor Gray
Write-Host "   • Риск: НЕТ — полностью автономный" -ForegroundColor Gray
Write-Host "   • Область: ВСЕ проекты в VS Code`n" -ForegroundColor Gray

Write-Host "🎉 MCP Shell готов к глобальному использованию!`n" -ForegroundColor Green
