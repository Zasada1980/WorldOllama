# ═══════════════════════════════════════════════════════════════════════════════
# ОБНОВЛЕНИЕ ГЛОБАЛЬНЫХ НАСТРОЕК MCP SHELL
# Заменяет устаревшую конфигурацию npx tsx на node dist/server.js
# ═══════════════════════════════════════════════════════════════════════════════

$settingsPath = "$env:APPDATA\Code\User\settings.json"

Write-Host "`n📝 Обновление глобальных настроек VS Code..." -ForegroundColor Cyan
Write-Host "   Файл: $settingsPath`n" -ForegroundColor Gray

# Читаем файл как текст (чтобы сохранить форматирование и комментарии)
$content = Get-Content $settingsPath -Raw

# Бэкап
$backupPath = "$settingsPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item $settingsPath $backupPath
Write-Host "✓ Создан бэкап: $backupPath" -ForegroundColor Green

# Ищем и заменяем старую конфигурацию MCP
if ($content -match '"myshell":\s*{[^}]+}') {
    Write-Host "⚠ Найдена старая конфигурация MCP 'myshell'" -ForegroundColor Yellow
    
    # Новая конфигурация
    $newMcpConfig = @'
"myshell": {
      "command": "node",
      "args": ["E:/WORLD_OLLAMA/mcp-shell/dist/server.js"],
      "env": {
        "WORLD_OLLAMA_ROOT": "E:/WORLD_OLLAMA",
        "MCP_LOG_MIRROR_ROOT": "1"
      }
    }
'@
    
    # Заменяем
    $content = $content -replace '"myshell":\s*\{[^}]+\}', $newMcpConfig
    
    # Убеждаемся что mcp.enabled = true
    if ($content -notmatch '"github\.copilot\.chat\.mcp\.enabled":\s*true') {
        Write-Host "⚠ Добавляем 'github.copilot.chat.mcp.enabled': true" -ForegroundColor Yellow
        
        # Ищем секцию github.copilot.chat.mcp.servers
        if ($content -match '("github\.copilot\.chat\.mcp\.servers":\s*\{)') {
            $content = $content -replace '("github\.copilot\.chat\.mcp\.servers":\s*\{)', '"github.copilot.chat.mcp.enabled": true,' + "`n  " + '$1'
        }
    }
    
    # Сохраняем
    $content | Out-File -FilePath $settingsPath -Encoding UTF8 -NoNewline
    
    Write-Host "✅ Конфигурация обновлена!" -ForegroundColor Green
    Write-Host "`n📋 Изменения:" -ForegroundColor Cyan
    Write-Host "   • command: npx → node" -ForegroundColor White
    Write-Host "   • args: tsx mcp-shell/server.ts → E:/WORLD_OLLAMA/mcp-shell/dist/server.js" -ForegroundColor White
    Write-Host "   • env: добавлен MCP_LOG_MIRROR_ROOT=1" -ForegroundColor White
    Write-Host "   • enabled: true (если не было)" -ForegroundColor White
    
    Write-Host "`n⚠ ТРЕБУЕТСЯ ПЕРЕЗАПУСК VS CODE!" -ForegroundColor Yellow
    Write-Host "   Ctrl+Shift+P → 'Developer: Reload Window'`n" -ForegroundColor White
    
} else {
    Write-Host "❌ Конфигурация 'myshell' не найдена в ожидаемом формате" -ForegroundColor Red
    Write-Host "   Проверьте файл вручную: code `"$settingsPath`"`n" -ForegroundColor Yellow
}
