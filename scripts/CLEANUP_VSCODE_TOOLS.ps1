# ========================================
# WORLD_OLLAMA - VS Code Tools Cleanup
# CLEANUP_VSCODE_TOOLS.ps1
# Версия: 1.0
# Дата: 03 декабря 2025
# ========================================
#
# Назначение: Удаление избыточных VS Code расширений и очистка автоапрува
# Основание: docs/infra/TOOLS_AUDIT_REPORT.md
#
# Режимы:
#   -Critical    Удалить только критичные конфликты (6 расширений)
#   -Full        Удалить все рекомендованные (16 расширений)
#   -DryRun      Показать что будет удалено без выполнения
#   -Backup      Создать backup settings.json перед очисткой

param(
    [switch]$Critical = $false,
    [switch]$Full = $false,
    [switch]$DryRun = $false,
    [switch]$Backup = $true
)

$ErrorActionPreference = "Stop"

# ============================================================================
# Конфигурация
# ============================================================================

$ProjectRoot = Split-Path -Parent $PSScriptRoot

# Критичные конфликты (Приоритет 1)
$CriticalExtensions = @(
    "google.geminicodeassist",                      # Дубликат GitHub Copilot
    "ms-azuretools.vscode-azure-mcp-server",        # Конфликт с myshell MCP
    "ms-azuretools.vscode-azure-github-copilot",    # Azure интеграция (не используется)
    "ms-mssql.mssql",                               # MSSQL (не используется)
    "ms-mssql.data-workspace-vscode",               # MSSQL workspaces
    "ms-mssql.sql-bindings-vscode",                 # SQL bindings
    "ms-mssql.sql-database-projects-vscode"         # SQL projects
)

# Azure ecosystem (Приоритет 2)
$AzureExtensions = @(
    "ms-azuretools.vscode-azureappservice",
    "ms-azuretools.vscode-azurestaticwebapps",
    "ms-azuretools.vscode-azurestorage",
    "ms-azuretools.vscode-azurevirtualmachines",
    "ms-azuretools.vscode-cosmosdb",
    "ms-azuretools.vscode-azureresourcegroups",
    "ms-vscode.vscode-node-azure-pack"
)

# Опциональные (Приоритет 3)
$OptionalExtensions = @(
    "docker.labs-ai-tools-vscode",
    "mijur.copilot-terminal-tools",
    "ericsia.pythonsnippets3"
)

# Чистый набор автоапрува для WORLD_OLLAMA
$CleanAutoApprove = @{
    "pwsh" = $true
    "Get-NetTCPConnection" = $true
    "nvidia-smi" = $true
    "Test-NetConnection" = $true
    "ollama" = $true
    "git" = $true
    "npm" = $true
    "/.*/}" = $true
}

# ============================================================================
# Функции
# ============================================================================

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        default { "Cyan" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Get-InstalledExtensions {
    Write-Log "Получение списка установленных расширений..."
    
    $output = code --list-extensions 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Не удалось получить список расширений" "ERROR"
        return @()
    }
    
    return $output
}

function Remove-Extension {
    param(
        [string]$ExtensionId,
        [bool]$DryRunMode = $false
    )
    
    if ($DryRunMode) {
        Write-Log "[DRY-RUN] Будет удалено: $ExtensionId" "WARNING"
        return $true
    }
    
    Write-Log "Удаление: $ExtensionId..."
    
    $output = code --uninstall-extension $ExtensionId 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "✅ Удалено: $ExtensionId" "SUCCESS"
        return $true
    } else {
        Write-Log "❌ Не удалось удалить: $ExtensionId" "ERROR"
        Write-Log "Вывод: $output" "ERROR"
        return $false
    }
}

function Backup-Settings {
    param([string]$SettingsPath)
    
    if (-not (Test-Path $SettingsPath)) {
        Write-Log "Settings.json не найден: $SettingsPath" "WARNING"
        return $false
    }
    
    $backupPath = "$SettingsPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    
    try {
        Copy-Item $SettingsPath $backupPath -Force
        Write-Log "✅ Backup создан: $backupPath" "SUCCESS"
        return $true
    } catch {
        Write-Log "❌ Не удалось создать backup: $_" "ERROR"
        return $false
    }
}

function Show-Summary {
    param(
        [int]$Total,
        [int]$Success,
        [int]$Failed,
        [bool]$DryRunMode
    )
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    if ($DryRunMode) {
        Write-Host "  DRY-RUN SUMMARY" -ForegroundColor Yellow
    } else {
        Write-Host "  CLEANUP SUMMARY" -ForegroundColor Green
    }
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Total extensions:    $Total" -ForegroundColor White
    Write-Host "  Successfully removed: $Success" -ForegroundColor Green
    Write-Host "  Failed:              $Failed" -ForegroundColor $(if ($Failed -gt 0) { "Red" } else { "Green" })
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# Main Script
# ============================================================================

Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  WORLD_OLLAMA - VS Code Tools Cleanup" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Определить режим
if (-not $Critical -and -not $Full) {
    Write-Log "Режим не указан. Используйте -Critical или -Full" "ERROR"
    Write-Host ""
    Write-Host "Примеры использования:" -ForegroundColor Yellow
    Write-Host "  .\CLEANUP_VSCODE_TOOLS.ps1 -Critical        # Удалить только критичные конфликты (6 ext)" -ForegroundColor Cyan
    Write-Host "  .\CLEANUP_VSCODE_TOOLS.ps1 -Full            # Удалить все рекомендованные (16 ext)" -ForegroundColor Cyan
    Write-Host "  .\CLEANUP_VSCODE_TOOLS.ps1 -Critical -DryRun # Показать что будет удалено" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

# Получить установленные расширения
$installedExtensions = Get-InstalledExtensions

if ($installedExtensions.Count -eq 0) {
    Write-Log "Не удалось получить список установленных расширений" "ERROR"
    exit 1
}

Write-Log "Найдено расширений: $($installedExtensions.Count)"

# Собрать список для удаления
$toRemove = @()

if ($Critical -or $Full) {
    $toRemove += $CriticalExtensions
}

if ($Full) {
    $toRemove += $AzureExtensions
    $toRemove += $OptionalExtensions
}

Write-Log "Расширений к удалению: $($toRemove.Count)"

if ($DryRun) {
    Write-Log "=== DRY-RUN MODE ===" "WARNING"
}

# Backup settings.json
if ($Backup -and -not $DryRun) {
    $settingsPath = "$env:APPDATA\Code\User\settings.json"
    Backup-Settings -SettingsPath $settingsPath
}

# Удалить расширения
$successCount = 0
$failCount = 0

foreach ($ext in $toRemove) {
    # Проверить установлено ли расширение
    if ($installedExtensions -notcontains $ext) {
        Write-Log "Пропущено (не установлено): $ext" "WARNING"
        continue
    }
    
    $result = Remove-Extension -ExtensionId $ext -DryRunMode $DryRun
    
    if ($result) {
        $successCount++
    } else {
        $failCount++
    }
    
    Start-Sleep -Milliseconds 500
}

# Показать итоги
Show-Summary -Total $toRemove.Count -Success $successCount -Failed $failCount -DryRunMode $DryRun

# Рекомендации по автоапруву
if (-not $DryRun -and $successCount -gt 0) {
    Write-Host ""
    Write-Log "⚠️ СЛЕДУЮЩИЙ ШАГ: Очистить автоапрув терминала" "WARNING"
    Write-Host ""
    Write-Host "1. Откройте settings.json:" -ForegroundColor Yellow
    Write-Host "   code $env:APPDATA\Code\User\settings.json" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "2. Найдите секцию 'chat.tools.terminal.autoApprove'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "3. Замените на минимальный набор:" -ForegroundColor Yellow
    Write-Host '   "chat.tools.terminal.autoApprove": {' -ForegroundColor Cyan
    Write-Host '     "pwsh": true,' -ForegroundColor Cyan
    Write-Host '     "Get-NetTCPConnection": true,' -ForegroundColor Cyan
    Write-Host '     "nvidia-smi": true,' -ForegroundColor Cyan
    Write-Host '     "Test-NetConnection": true,' -ForegroundColor Cyan
    Write-Host '     "ollama": true,' -ForegroundColor Cyan
    Write-Host '     "git": true,' -ForegroundColor Cyan
    Write-Host '     "npm": true,' -ForegroundColor Cyan
    Write-Host '     "/.*/": true' -ForegroundColor Cyan
    Write-Host '   }' -ForegroundColor Cyan
    Write-Host ""
    Write-Host "4. Удалите все записи из REVIZOR/Telegram Bot (62 записи)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "5. Перезапустите VS Code" -ForegroundColor Yellow
    Write-Host ""
}

if ($DryRun) {
    Write-Host ""
    Write-Log "DRY-RUN завершён. Для реального удаления запустите без -DryRun" "WARNING"
    Write-Host ""
}

Write-Log "Скрипт завершён" "SUCCESS"
