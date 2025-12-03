# ═══════════════════════════════════════════════════════════════════════════════
# ОБНОВЛЕНИЕ MCP.JSON — ГЛОБАЛЬНЫЙ ПУТЬ (НЕЗАВИСИМЫЙ ОТ ПРОЕКТА)
# ═══════════════════════════════════════════════════════════════════════════════

$mcpPath = "C:\Users\zakon\AppData\Roaming\Code\User\mcp.json"

Write-Host "`n📝 Обновление mcp.json на глобальный путь..." -ForegroundColor Cyan

# Создаём бэкап
$backup = "$mcpPath.backup_global_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item $mcpPath $backup
Write-Host "✓ Бэкап: $backup" -ForegroundColor Gray

# Новая конфигурация с глобальным путём
$config = @{
    servers = @{
        "github/github-mcp-server" = @{
            type = "http"
            url = "https://api.githubcopilot.com/mcp/"
            gallery = "https://api.mcp.github.com/2025-09-15/v0/servers/ab12cd34-5678-90ef-1234-567890abcdef"
            version = "0.13.0"
        }
        "myshell" = @{
            type = "stdio"
            command = "node"
            args = @("C:/Users/zakon/AppData/Roaming/Code/User/mcp-servers/myshell/dist/server.js")
            env = @{
                MCP_LOG_MIRROR_ROOT = "1"
            }
        }
    }
    inputs = @()
}

# Сохраняем в JSON
$config | ConvertTo-Json -Depth 10 | Out-File -FilePath $mcpPath -Encoding UTF8

Write-Host "✅ mcp.json обновлён!" -ForegroundColor Green
Write-Host "`n📋 Изменения:" -ForegroundColor Cyan
Write-Host "   • Путь изменён:" -ForegroundColor Yellow
Write-Host "     БЫЛО: E:/WORLD_OLLAMA/mcp-shell/dist/server.js" -ForegroundColor Red
Write-Host "     СТАЛО: C:/Users/zakon/AppData/Roaming/Code/User/mcp-servers/myshell/dist/server.js" -ForegroundColor Green
Write-Host "   • Удалена переменная WORLD_OLLAMA_ROOT (больше не нужна)" -ForegroundColor Gray
Write-Host "   • Оставлена MCP_LOG_MIRROR_ROOT=1 для логирования" -ForegroundColor Gray

Write-Host "`n✅ MCP Shell теперь ГЛОБАЛЬНЫЙ инструмент VS Code!" -ForegroundColor Green
Write-Host "   • Независим от проекта WORLD_OLLAMA" -ForegroundColor White
Write-Host "   • Работает во всех проектах" -ForegroundColor White
Write-Host "   • Выдержит удаление/перенос репозитория" -ForegroundColor White

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray
