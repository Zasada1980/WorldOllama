# ═══════════════════════════════════════════════════════════════════════════════
# НАСТРОЙКА MCP SHELL В ГЛОБАЛЬНЫХ НАСТРОЙКАХ VS CODE
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   MCP SHELL GLOBAL CONFIGURATION           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Путь к глобальным настройкам VS Code
$settingsPath = "$env:APPDATA\Code\User\settings.json"

Write-Host "Путь к настройкам: $settingsPath" -ForegroundColor Gray

if (-not (Test-Path $settingsPath)) {
    Write-Host "❌ Файл настроек не найден!" -ForegroundColor Red
    Write-Host "   Создайте файл вручную или откройте VS Code Settings (Ctrl+,)" -ForegroundColor Yellow
    exit 1
}

# Читаем текущие настройки
$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

# Проверяем наличие MCP конфигурации
if ($settings.'github.copilot.chat.mcp.servers'.myshell) {
    Write-Host "✅ MCP 'myshell' уже настроен в глобальных settings" -ForegroundColor Green
    Write-Host "   Command: $($settings.'github.copilot.chat.mcp.servers'.myshell.command)" -ForegroundColor Gray
    exit 0
}

Write-Host "⚠  MCP 'myshell' НЕ найден в глобальных настройках" -ForegroundColor Yellow
Write-Host "`nДобавьте следующую конфигурацию в VS Code User Settings:" -ForegroundColor Cyan
Write-Host "(Ctrl+Shift+P → 'Preferences: Open User Settings (JSON)')" -ForegroundColor Yellow

$config = @'

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

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host $config -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

Write-Host "После добавления:" -ForegroundColor Cyan
Write-Host "  1. Сохраните файл (Ctrl+S)" -ForegroundColor White
Write-Host "  2. Перезапустите VS Code" -ForegroundColor White
Write-Host "  3. Проверьте в Copilot Chat: 'test myshell/health_check'" -ForegroundColor White
Write-Host "`n"
