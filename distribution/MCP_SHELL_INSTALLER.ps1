#Requires -Version 7.0

<#
.SYNOPSIS
    MCP-SHELL v1.3.1 — Автоматический установщик для VS Code
    
.DESCRIPTION
    Установочный файл с графическим интерфейсом для автоматической установки 
    MCP-SHELL расширения в Visual Studio Code.
    
    Возможности:
    - Автопоиск VS Code на локальной машине
    - GUI диалог с кнопками Да/Нет
    - Полная автоматическая установка
    - Проверка требований (Node.js, PowerShell)
    - Автоматическая настройка VS Code
    
.NOTES
    Версия: 1.0.0
    Дата: 05.12.2025
    Автор: WORLD_OLLAMA Agent System
    
.EXAMPLE
    # Двойной клик на файле MCP_SHELL_INSTALLER.ps1
    # ИЛИ запуск из PowerShell:
    pwsh -File MCP_SHELL_INSTALLER.ps1
#>

# ============================================================================
# КОНСТАНТЫ И КОНФИГУРАЦИЯ
# ============================================================================

$script:VERSION = "1.0.0"
$script:MCP_SHELL_VERSION = "v1.3.1"
$script:INSTALLER_TITLE = "MCP-SHELL $MCP_SHELL_VERSION Installer"

# URL для скачивания исходных файлов (GitHub Release)
$script:DOWNLOAD_URL = "https://github.com/Zasada1980/WorldOllama/releases/download/mcp-shell-v1.3.1/mcp-shell-files.zip"

# Временная директория
$script:TEMP_DIR = Join-Path $env:TEMP "mcp_shell_installer_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# Целевая директория установки
$script:INSTALL_DIR = Join-Path $env:APPDATA "Code\User\mcp-servers\myshell"

# Путь к конфигурации MCP в VS Code
$script:MCP_SETTINGS_PATH = Join-Path $env:APPDATA "Code\User\globalStorage\rooveterinaryinc.roo-cline\settings\mcp_settings.json"

# Логирование
$script:LOG_FILE = Join-Path $script:TEMP_DIR "installation.log"

# ============================================================================
# ФУНКЦИИ УТИЛИТЫ
# ============================================================================

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Вывод в консоль
    switch ($Level) {
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        default { Write-Host $logMessage -ForegroundColor Cyan }
    }
    
    # Запись в лог-файл
    if (Test-Path $script:LOG_FILE) {
        Add-Content -Path $script:LOG_FILE -Value $logMessage
    }
}

function Show-ErrorDialog {
    param(
        [string]$Title = "Ошибка установки",
        [string]$Message
    )
    
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        $Message,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
}

function Show-InfoDialog {
    param(
        [string]$Title = "MCP-SHELL Installer",
        [string]$Message
    )
    
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        $Message,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}

function Show-ConfirmDialog {
    param(
        [string]$Title = "Подтверждение установки",
        [string]$Message
    )
    
    Add-Type -AssemblyName System.Windows.Forms
    $result = [System.Windows.Forms.MessageBox]::Show(
        $Message,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    
    return $result -eq [System.Windows.Forms.DialogResult]::Yes
}

# ============================================================================
# ФУНКЦИИ ПРОВЕРКИ ТРЕБОВАНИЙ
# ============================================================================

function Test-PowerShellVersion {
    Write-Log "Проверка версии PowerShell..."
    
    $version = $PSVersionTable.PSVersion
    Write-Log "Обнаружена версия PowerShell: $version"
    
    if ($version.Major -lt 7) {
        Write-Log "Требуется PowerShell 7.x или выше" -Level ERROR
        Show-ErrorDialog -Message "Требуется PowerShell 7.x или выше.`n`nУстановите PowerShell 7:`nwinget install Microsoft.PowerShell"
        return $false
    }
    
    Write-Log "✅ PowerShell версия корректна" -Level SUCCESS
    return $true
}

function Test-NodeJsInstalled {
    Write-Log "Проверка установки Node.js..."
    
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            Write-Log "Обнаружена версия Node.js: $nodeVersion"
            
            # Проверка версии (нужен 18.0.0+)
            $versionNumber = [int]($nodeVersion -replace 'v(\d+)\..*', '$1')
            if ($versionNumber -lt 18) {
                Write-Log "Требуется Node.js 18.0.0 или выше" -Level ERROR
                Show-ErrorDialog -Message "Требуется Node.js 18.0.0 или выше.`n`nУстановите Node.js:`nwinget install OpenJS.NodeJS.LTS"
                return $false
            }
            
            Write-Log "✅ Node.js версия корректна" -Level SUCCESS
            return $true
        }
    }
    catch {
        Write-Log "Node.js не найден" -Level ERROR
        Show-ErrorDialog -Message "Node.js не установлен.`n`nУстановите Node.js 18.0.0+:`nwinget install OpenJS.NodeJS.LTS"
        return $false
    }
    
    return $false
}

function Test-VSCodeInstalled {
    Write-Log "Поиск VS Code на локальной машине..."
    
    # Возможные пути установки VS Code
    $possiblePaths = @(
        "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\Code.exe",
        "${env:ProgramFiles}\Microsoft VS Code\Code.exe",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\Code.exe",
        "${env:USERPROFILE}\AppData\Local\Programs\Microsoft VS Code\Code.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            Write-Log "✅ VS Code найден: $path" -Level SUCCESS
            
            # Проверка версии VS Code
            try {
                $vscodeVersion = & $path --version 2>$null | Select-Object -First 1
                Write-Log "Версия VS Code: $vscodeVersion"
                return $path
            }
            catch {
                Write-Log "Не удалось определить версию VS Code" -Level WARNING
                return $path
            }
        }
    }
    
    # VS Code не найден
    Write-Log "VS Code не найден на стандартных путях" -Level ERROR
    
    # Попытка найти через реестр Windows
    try {
        $regPath = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "*Visual Studio Code*" } |
        Select-Object -First 1
        
        if ($regPath -and $regPath.InstallLocation) {
            $codePath = Join-Path $regPath.InstallLocation "Code.exe"
            if (Test-Path $codePath) {
                Write-Log "✅ VS Code найден через реестр: $codePath" -Level SUCCESS
                return $codePath
            }
        }
    }
    catch {
        Write-Log "Ошибка поиска VS Code в реестре: $_" -Level WARNING
    }
    
    Show-ErrorDialog -Message "VS Code не найден на вашем компьютере.`n`nУстановите VS Code:`nhttps://code.visualstudio.com/"
    return $null
}

# ============================================================================
# ФУНКЦИИ УСТАНОВКИ
# ============================================================================

function New-InstallationDirectory {
    Write-Log "Создание директории установки: $script:INSTALL_DIR"
    
    try {
        if (Test-Path $script:INSTALL_DIR) {
            Write-Log "Директория уже существует, очистка..." -Level WARNING
            Remove-Item -Path $script:INSTALL_DIR -Recurse -Force -ErrorAction Stop
        }
        
        New-Item -Path $script:INSTALL_DIR -ItemType Directory -Force | Out-Null
        Write-Log "✅ Директория создана успешно" -Level SUCCESS
        return $true
    }
    catch {
        Write-Log "Ошибка создания директории: $_" -Level ERROR
        Show-ErrorDialog -Message "Не удалось создать директорию установки:`n$script:INSTALL_DIR`n`nОшибка: $_"
        return $false
    }
}

function Copy-MCPShellFiles {
    Write-Log "Копирование файлов MCP-SHELL..."
    
    # Определяем путь к исходным файлам (рядом с установщиком)
    $scriptDir = Split-Path -Parent $PSCommandPath
    $sourceDir = Join-Path $scriptDir "mcp-shell"
    
    if (-not (Test-Path $sourceDir)) {
        Write-Log "Исходные файлы не найдены в: $sourceDir" -Level ERROR
        Write-Log "Попытка скачать файлы из GitHub..." -Level WARNING
        
        # TODO: Реализовать скачивание с GitHub Release
        Show-ErrorDialog -Message "Исходные файлы MCP-SHELL не найдены.`n`nУбедитесь, что папка 'mcp-shell' находится рядом с установщиком."
        return $false
    }
    
    try {
        # Копируем основные файлы
        $filesToCopy = @(
            "server.ts",
            "error_catalog.ts",
            "package.json",
            "package-lock.json",
            "tsconfig.json",
            "README.md"
        )
        
        foreach ($file in $filesToCopy) {
            $sourcePath = Join-Path $sourceDir $file
            $destPath = Join-Path $script:INSTALL_DIR $file
            
            if (Test-Path $sourcePath) {
                Copy-Item -Path $sourcePath -Destination $destPath -Force
                Write-Log "  ✓ Скопирован: $file"
            }
            else {
                Write-Log "  ⚠ Файл не найден: $file" -Level WARNING
            }
        }
        
        # Копируем config директорию
        $configSource = Join-Path $sourceDir "config"
        $configDest = Join-Path $script:INSTALL_DIR "config"
        
        if (Test-Path $configSource) {
            Copy-Item -Path $configSource -Destination $configDest -Recurse -Force
            Write-Log "  ✓ Скопирована директория: config"
        }
        
        Write-Log "✅ Файлы скопированы успешно" -Level SUCCESS
        return $true
    }
    catch {
        Write-Log "Ошибка копирования файлов: $_" -Level ERROR
        Show-ErrorDialog -Message "Ошибка копирования файлов MCP-SHELL:`n$_"
        return $false
    }
}

function Install-Dependencies {
    Write-Log "Установка зависимостей (npm install)..."
    
    try {
        Push-Location $script:INSTALL_DIR
        
        $npmOutput = npm install 2>&1
        Write-Log "npm install завершён"
        
        # Проверка успешной установки
        $nodeModulesPath = Join-Path $script:INSTALL_DIR "node_modules"
        if (-not (Test-Path $nodeModulesPath)) {
            throw "node_modules не создана"
        }
        
        Write-Log "✅ Зависимости установлены успешно" -Level SUCCESS
        Pop-Location
        return $true
    }
    catch {
        Pop-Location
        Write-Log "Ошибка установки зависимостей: $_" -Level ERROR
        Show-ErrorDialog -Message "Ошибка установки npm зависимостей:`n$_`n`nПроверьте подключение к интернету."
        return $false
    }
}

function Build-TypeScriptProject {
    Write-Log "Компиляция TypeScript (npm run build)..."
    
    try {
        Push-Location $script:INSTALL_DIR
        
        $buildOutput = npm run build 2>&1
        Write-Log "npm run build завершён"
        
        # Проверка создания dist/server.js
        $serverJsPath = Join-Path $script:INSTALL_DIR "dist\server.js"
        if (-not (Test-Path $serverJsPath)) {
            throw "dist/server.js не создан"
        }
        
        Write-Log "✅ TypeScript скомпилирован успешно" -Level SUCCESS
        Pop-Location
        return $true
    }
    catch {
        Pop-Location
        Write-Log "Ошибка компиляции TypeScript: $_" -Level ERROR
        Show-ErrorDialog -Message "Ошибка компиляции TypeScript:`n$_"
        return $false
    }
}

function Update-VSCodeMCPSettings {
    Write-Log "Обновление конфигурации VS Code (mcp_settings.json)..."
    
    try {
        # Проверка существования файла настроек
        $settingsDir = Split-Path -Parent $script:MCP_SETTINGS_PATH
        
        if (-not (Test-Path $settingsDir)) {
            Write-Log "Создание директории настроек: $settingsDir"
            New-Item -Path $settingsDir -ItemType Directory -Force | Out-Null
        }
        
        # Путь к server.js
        $serverJsPath = Join-Path $script:INSTALL_DIR "dist\server.js"
        $serverJsPathEscaped = $serverJsPath -replace '\\', '\\'
        
        # Создание или обновление конфигурации
        $mcpConfig = @{
            mcpServers = @{
                myshell = @{
                    command     = "node"
                    args        = @($serverJsPath)
                    env         = @{}
                    disabled    = $false
                    alwaysAllow = @()
                }
            }
        }
        
        if (Test-Path $script:MCP_SETTINGS_PATH) {
            # Обновление существующего файла
            Write-Log "Обновление существующего mcp_settings.json"
            
            $existingConfig = Get-Content $script:MCP_SETTINGS_PATH -Raw | ConvertFrom-Json
            
            # Добавляем или обновляем секцию myshell
            if (-not $existingConfig.mcpServers) {
                $existingConfig | Add-Member -MemberType NoteProperty -Name "mcpServers" -Value @{} -Force
            }
            
            $existingConfig.mcpServers | Add-Member -MemberType NoteProperty -Name "myshell" -Value $mcpConfig.mcpServers.myshell -Force
            
            $existingConfig | ConvertTo-Json -Depth 10 | Set-Content $script:MCP_SETTINGS_PATH -Force
        }
        else {
            # Создание нового файла
            Write-Log "Создание нового mcp_settings.json"
            $mcpConfig | ConvertTo-Json -Depth 10 | Set-Content $script:MCP_SETTINGS_PATH -Force
        }
        
        Write-Log "✅ Конфигурация VS Code обновлена" -Level SUCCESS
        return $true
    }
    catch {
        Write-Log "Ошибка обновления конфигурации VS Code: $_" -Level ERROR
        Show-ErrorDialog -Message "Ошибка обновления конфигурации VS Code:`n$_"
        return $false
    }
}

function New-UninstallScript {
    Write-Log "Создание скрипта удаления (UNINSTALL.ps1)..."
    
    try {
        $uninstallScriptPath = Join-Path $script:INSTALL_DIR "UNINSTALL.ps1"
        
        $uninstallContent = @"
#Requires -Version 7.0

<#
.SYNOPSIS
    Удаление MCP-SHELL из VS Code
    
.DESCRIPTION
    Автоматическое удаление MCP-SHELL сервера и конфигурации
#>

Write-Host "MCP-SHELL Uninstaller" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host ""

# Подтверждение удаления
`$confirmation = Read-Host "Вы уверены, что хотите удалить MCP-SHELL? (y/n)"
if (`$confirmation -ne 'y') {
    Write-Host "Удаление отменено." -ForegroundColor Yellow
    exit 0
}

Write-Host "Удаление MCP-SHELL..." -ForegroundColor Yellow

# 1. Удаление директории установки
`$installDir = "$script:INSTALL_DIR"
if (Test-Path `$installDir) {
    Remove-Item -Path `$installDir -Recurse -Force
    Write-Host "✓ Удалена директория: `$installDir" -ForegroundColor Green
}

# 2. Удаление конфигурации из mcp_settings.json
`$mcpSettingsPath = "$script:MCP_SETTINGS_PATH"
if (Test-Path `$mcpSettingsPath) {
    try {
        `$config = Get-Content `$mcpSettingsPath -Raw | ConvertFrom-Json
        if (`$config.mcpServers.myshell) {
            `$config.mcpServers.PSObject.Properties.Remove('myshell')
            `$config | ConvertTo-Json -Depth 10 | Set-Content `$mcpSettingsPath -Force
            Write-Host "✓ Удалена конфигурация из mcp_settings.json" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "⚠ Не удалось обновить mcp_settings.json: `$_" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "✅ MCP-SHELL успешно удалён" -ForegroundColor Green
Write-Host "Перезапустите VS Code для применения изменений." -ForegroundColor Cyan
"@
        
        Set-Content -Path $uninstallScriptPath -Value $uninstallContent -Force
        Write-Log "✅ Скрипт удаления создан: $uninstallScriptPath" -Level SUCCESS
        return $true
    }
    catch {
        Write-Log "Ошибка создания скрипта удаления: $_" -Level ERROR
        return $false
    }
}

# ============================================================================
# ГЛАВНАЯ ФУНКЦИЯ УСТАНОВКИ
# ============================================================================

function Start-Installation {
    Write-Log "════════════════════════════════════════════════════════"
    Write-Log "  MCP-SHELL $script:MCP_SHELL_VERSION Installer v$script:VERSION"
    Write-Log "════════════════════════════════════════════════════════"
    Write-Log ""
    
    # ШАГ 1: Проверка требований
    Write-Log "ШАГ 1/8: Проверка системных требований"
    Write-Log "─────────────────────────────────────────"
    
    if (-not (Test-PowerShellVersion)) { return $false }
    if (-not (Test-NodeJsInstalled)) { return $false }
    
    $vscodePath = Test-VSCodeInstalled
    if (-not $vscodePath) { return $false }
    
    Write-Log ""
    
    # ШАГ 2: Запрос разрешения на установку
    Write-Log "ШАГ 2/8: Запрос разрешения пользователя"
    Write-Log "─────────────────────────────────────────"
    
    $installMessage = @"
MCP-SHELL v$script:MCP_SHELL_VERSION будет установлен в:
$script:INSTALL_DIR

VS Code обнаружен:
$vscodePath

Продолжить установку?
"@
    
    $userConfirmed = Show-ConfirmDialog -Title "Подтверждение установки" -Message $installMessage
    
    if (-not $userConfirmed) {
        Write-Log "Установка отменена пользователем." -Level WARNING
        Show-InfoDialog -Message "Установка отменена."
        return $false
    }
    
    Write-Log "✅ Пользователь подтвердил установку" -Level SUCCESS
    Write-Log ""
    
    # ШАГ 3: Создание директории установки
    Write-Log "ШАГ 3/8: Создание директории установки"
    Write-Log "─────────────────────────────────────────"
    if (-not (New-InstallationDirectory)) { return $false }
    Write-Log ""
    
    # ШАГ 4: Копирование файлов
    Write-Log "ШАГ 4/8: Копирование файлов MCP-SHELL"
    Write-Log "─────────────────────────────────────────"
    if (-not (Copy-MCPShellFiles)) { return $false }
    Write-Log ""
    
    # ШАГ 5: Установка зависимостей
    Write-Log "ШАГ 5/8: Установка npm зависимостей"
    Write-Log "─────────────────────────────────────────"
    if (-not (Install-Dependencies)) { return $false }
    Write-Log ""
    
    # ШАГ 6: Компиляция TypeScript
    Write-Log "ШАГ 6/8: Компиляция TypeScript"
    Write-Log "─────────────────────────────────────────"
    if (-not (Build-TypeScriptProject)) { return $false }
    Write-Log ""
    
    # ШАГ 7: Обновление конфигурации VS Code
    Write-Log "ШАГ 7/8: Обновление конфигурации VS Code"
    Write-Log "─────────────────────────────────────────"
    if (-not (Update-VSCodeMCPSettings)) { return $false }
    Write-Log ""
    
    # ШАГ 8: Создание скрипта удаления
    Write-Log "ШАГ 8/8: Создание скрипта удаления"
    Write-Log "─────────────────────────────────────────"
    New-UninstallScript | Out-Null
    Write-Log ""
    
    # ЗАВЕРШЕНИЕ
    Write-Log "════════════════════════════════════════════════════════"
    Write-Log "  ✅ УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!"
    Write-Log "════════════════════════════════════════════════════════"
    Write-Log ""
    
    $successMessage = @"
MCP-SHELL v$script:MCP_SHELL_VERSION успешно установлен!

Директория установки:
$script:INSTALL_DIR

СЛЕДУЮЩИЕ ШАГИ:

1. Перезапустите VS Code
2. Откройте GitHub Copilot Chat
3. Проверьте работу: "Проверь здоровье MCP Shell"

Для удаления запустите:
$script:INSTALL_DIR\UNINSTALL.ps1
"@
    
    Show-InfoDialog -Title "Установка завершена" -Message $successMessage
    
    Write-Log $successMessage
    Write-Log ""
    Write-Log "Лог установки сохранён: $script:LOG_FILE"
    
    return $true
}

# ============================================================================
# ТОЧКА ВХОДА
# ============================================================================

try {
    # Создание временной директории и лог-файла
    New-Item -Path $script:TEMP_DIR -ItemType Directory -Force | Out-Null
    New-Item -Path $script:LOG_FILE -ItemType File -Force | Out-Null
    
    # Запуск установки
    $installResult = Start-Installation
    
    if (-not $installResult) {
        Write-Log "Установка завершилась с ошибками." -Level ERROR
        exit 1
    }
    
    exit 0
}
catch {
    Write-Log "Критическая ошибка установки: $_" -Level ERROR
    Show-ErrorDialog -Message "Критическая ошибка установки:`n$_`n`nЛог сохранён: $script:LOG_FILE"
    exit 1
}
finally {
    # Очистка временных файлов (опционально)
    # Remove-Item -Path $script:TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
}
