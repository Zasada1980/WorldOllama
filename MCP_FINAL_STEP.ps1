# ═══════════════════════════════════════════════════════════════════════════════
# ФИНАЛЬНАЯ НАСТРОЙКА MCP SHELL — РУЧНОЕ РЕДАКТИРОВАНИЕ
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   ФИНАЛЬНЫЙ ШАГ НАСТРОЙКИ MCP              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "✅ Конфигурация MCP 'myshell' обновлена в глобальных настройках" -ForegroundColor Green
Write-Host "✅ Команда изменена: npx → node" -ForegroundColor Green
Write-Host "✅ Путь к серверу: E:/WORLD_OLLAMA/mcp-shell/dist/server.js" -ForegroundColor Green

Write-Host "`n⚠  ОСТАЛОСЬ 2 ДЕЙСТВИЯ:" -ForegroundColor Yellow

Write-Host "`n1️⃣  Откройте глобальные настройки VS Code:" -ForegroundColor Cyan
Write-Host "   Ctrl+Shift+P → 'Preferences: Open User Settings (JSON)'" -ForegroundColor White
Write-Host "   (или файл уже открыт в редакторе)" -ForegroundColor Gray

Write-Host "`n2️⃣  Найдите секцию:" -ForegroundColor Cyan
Write-Host '   "github.copilot.chat.mcp.servers": {' -ForegroundColor White

Write-Host "`n3️⃣  ПЕРЕД этой строкой добавьте:" -ForegroundColor Cyan
Write-Host '   "github.copilot.chat.mcp.enabled": true,' -ForegroundColor Green

Write-Host "`n📝 Пример итоговой конфигурации:" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

$example = @'
  "github.copilot.chat.mcp.enabled": true,
  "github.copilot.chat.mcp.servers": {
    "myshell": {
      "command": "node",
      "args": ["E:/WORLD_OLLAMA/mcp-shell/dist/server.js"],
      "env": {
        "WORLD_OLLAMA_ROOT": "E:/WORLD_OLLAMA",
        "MCP_LOG_MIRROR_ROOT": "1"
      }
    }
  }
'@

Write-Host $example -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

Write-Host "4️⃣  Сохраните файл (Ctrl+S)" -ForegroundColor Cyan

Write-Host "`n5️⃣  ПЕРЕЗАПУСТИТЕ VS Code:" -ForegroundColor Yellow
Write-Host "   Ctrl+Shift+P → 'Developer: Reload Window'" -ForegroundColor White

Write-Host "`n6️⃣  После перезапуска скажите мне:" -ForegroundColor Cyan
Write-Host '   "Проверь myshell/health_check"' -ForegroundColor Green

Write-Host "`n🎯 Ожидаемый результат:" -ForegroundColor Cyan
Write-Host '   Я должен увидеть инструменты myshell/* и вызвать health_check' -ForegroundColor White
Write-Host '   Ответ: {"status": "ok", "breakerState": "CLOSED"}' -ForegroundColor Green

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray
