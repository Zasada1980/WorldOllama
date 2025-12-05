#Requires -Version 7.0

<#
.SYNOPSIS
    Скрипт создания дистрибутива MCP-SHELL v1.3.1
    
.DESCRIPTION
    Собирает все необходимые файлы и создаёт ZIP-архив для распространения
#>

# ============================================================================
# КОНФИГУРАЦИЯ
# ============================================================================

$VERSION = "v1.3.1"
$PACKAGE_NAME = "MCP_SHELL_${VERSION}_Installer"

# Пути
$PROJECT_ROOT = "e:\WORLD_OLLAMA"
$DIST_DIR = Join-Path $PROJECT_ROOT "distribution"
$MCP_SHELL_SOURCE = Join-Path $PROJECT_ROOT "mcp-shell"
$DOCS_SOURCE = Join-Path $PROJECT_ROOT "docs\infrastructure"

$PACKAGE_DIR = Join-Path $DIST_DIR $PACKAGE_NAME
$ZIP_PATH = Join-Path $DIST_DIR "${PACKAGE_NAME}.zip"

# ============================================================================
# ФУНКЦИИ
# ============================================================================

function Write-Step {
    param([string]$Message, [string]$Color = "Yellow")
    Write-Host ""
    Write-Host $Message -ForegroundColor $Color
    Write-Host ("-" * 60) -ForegroundColor DarkGray
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✅ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "  ✓ $Message" -ForegroundColor Cyan
}

function Write-Error {
    param([string]$Message)
    Write-Host "  ❌ $Message" -ForegroundColor Red
}

# ============================================================================
# ГЛАВНАЯ ЛОГИКА
# ============================================================================

Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  MCP-SHELL $VERSION Distributor" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan

# ШАГ 1: Проверка исходных файлов
Write-Step "ШАГ 1/8: Проверка исходных файлов"

if (-not (Test-Path $MCP_SHELL_SOURCE)) {
    Write-Error "Директория mcp-shell не найдена: $MCP_SHELL_SOURCE"
    exit 1
}

$required_files = @(
    "server.ts",
    "error_catalog.ts",
    "package.json",
    "package-lock.json",
    "tsconfig.json",
    "README.md"
)

$missing_files = @()
foreach ($file in $required_files) {
    $path = Join-Path $MCP_SHELL_SOURCE $file
    if (-not (Test-Path $path)) {
        $missing_files += $file
    }
}

if ($missing_files.Count -gt 0) {
    Write-Error "Отсутствуют файлы: $($missing_files -join ', ')"
    exit 1
}

Write-Success "Все исходные файлы найдены ($($required_files.Count) файлов)"

# ШАГ 2: Очистка и создание директорий
Write-Step "ШАГ 2/8: Создание структуры пакета"

if (Test-Path $PACKAGE_DIR) {
    Remove-Item -Path $PACKAGE_DIR -Recurse -Force
}

New-Item -Path $PACKAGE_DIR -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path $PACKAGE_DIR "mcp-shell") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path $PACKAGE_DIR "docs") -ItemType Directory -Force | Out-Null

Write-Success "Директории созданы: $PACKAGE_DIR"

# ШАГ 3: Копирование файлов MCP-SHELL
Write-Step "ШАГ 3/8: Копирование файлов MCP-SHELL"

$mcp_target = Join-Path $PACKAGE_DIR "mcp-shell"

foreach ($file in $required_files) {
    $source = Join-Path $MCP_SHELL_SOURCE $file
    $dest = Join-Path $mcp_target $file
    Copy-Item -Path $source -Destination $dest -Force
    Write-Info $file
}

# Копирование config директории
$config_source = Join-Path $MCP_SHELL_SOURCE "config"
$config_dest = Join-Path $mcp_target "config"
if (Test-Path $config_source) {
    Copy-Item -Path $config_source -Destination $config_dest -Recurse -Force
    Write-Info "config/ (1 файл)"
}

Write-Success "Скопировано 7 файлов"

# ШАГ 4: Копирование установщика и README
Write-Step "ШАГ 4/8: Копирование установщика"

$installer_files = @(
    @{
        Source = Join-Path $DIST_DIR "MCP_SHELL_INSTALLER.ps1"
        Dest   = "MCP_SHELL_INSTALLER.ps1"
    },
    @{
        Source = Join-Path $DIST_DIR "MCP_SHELL_INSTALLER_README.md"
        Dest   = "README.md"
    }
)

foreach ($item in $installer_files) {
    $source = $item.Source
    $dest = Join-Path $PACKAGE_DIR $item.Dest
    
    if (Test-Path $source) {
        Copy-Item -Path $source -Destination $dest -Force
        Write-Info $item.Dest
    }
    else {
        Write-Error "Файл не найден: $source"
    }
}

Write-Success "Установщик скопирован"

# ШАГ 5: Копирование документации
Write-Step "ШАГ 5/8: Копирование документации"

$docs_to_copy = @(
    "MCP_SHELL_EXTENSION_DOCUMENTATION.md",
    "MCP_SHELL_USER_MANUAL_RU.md",
    "MCP_SHELL_PRESENTATION.md"
)

$docs_target = Join-Path $PACKAGE_DIR "docs"
$docs_copied = 0

foreach ($doc in $docs_to_copy) {
    $source = Join-Path $DOCS_SOURCE $doc
    $dest = Join-Path $docs_target $doc
    
    if (Test-Path $source) {
        Copy-Item -Path $source -Destination $dest -Force
        Write-Info $doc
        $docs_copied++
    }
}

Write-Success "Скопировано $docs_copied документов"

# ШАГ 6: Подсчёт файлов и размера
Write-Step "ШАГ 6/8: Анализ содержимого пакета"

$all_files = Get-ChildItem -Path $PACKAGE_DIR -Recurse -File
$total_size = ($all_files | Measure-Object -Property Length -Sum).Sum
$total_size_mb = [math]::Round($total_size / 1MB, 2)

Write-Info "Всего файлов: $($all_files.Count)"
Write-Info "Общий размер: $total_size_mb MB"

# ШАГ 7: Создание ZIP архива
Write-Step "ШАГ 7/8: Создание ZIP архива"

if (Test-Path $ZIP_PATH) {
    Remove-Item -Path $ZIP_PATH -Force
}

Compress-Archive -Path "$PACKAGE_DIR\*" -DestinationPath $ZIP_PATH -CompressionLevel Optimal -Force

$zip_info = Get-Item $ZIP_PATH
$zip_size_mb = [math]::Round($zip_info.Length / 1MB, 2)

Write-Success "ZIP создан: $zip_size_mb MB"

# ШАГ 8: Контрольная сумма
Write-Step "ШАГ 8/8: Вычисление контрольной суммы"

$hash = Get-FileHash -Path $ZIP_PATH -Algorithm SHA256
$sha256 = $hash.Hash

$sha256_path = "$ZIP_PATH.sha256"
Set-Content -Path $sha256_path -Value "$sha256  ${PACKAGE_NAME}.zip"

Write-Info "SHA256: $sha256"
Write-Success "Контрольная сумма сохранена: $sha256_path"

# ============================================================================
# ФИНАЛЬНЫЙ ОТЧЁТ
# ============================================================================

Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ✅ ДИСТРИБУТИВ СОЗДАН УСПЕШНО!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "📦 Файл для распространения:" -ForegroundColor Yellow
Write-Host "   $ZIP_PATH"
Write-Host "   Размер: $zip_size_mb MB"
Write-Host ""

Write-Host "🔐 Контрольная сумма (SHA256):" -ForegroundColor Yellow
Write-Host "   $sha256"
Write-Host ""

Write-Host "📂 Содержимое архива:" -ForegroundColor Yellow
Write-Host "   ├── MCP_SHELL_INSTALLER.ps1  (установщик с GUI)"
Write-Host "   ├── README.md                 (инструкции)"
Write-Host "   ├── mcp-shell/                (7 файлов)"
Write-Host "   │   ├── server.ts"
Write-Host "   │   ├── error_catalog.ts"
Write-Host "   │   ├── package.json"
Write-Host "   │   ├── package-lock.json"
Write-Host "   │   ├── tsconfig.json"
Write-Host "   │   ├── README.md"
Write-Host "   │   └── config/"
Write-Host "   │       └── terminal_timeout_policy.json"
Write-Host "   └── docs/                     (3 документа)"
Write-Host "       ├── MCP_SHELL_EXTENSION_DOCUMENTATION.md"
Write-Host "       ├── MCP_SHELL_USER_MANUAL_RU.md"
Write-Host "       └── MCP_SHELL_PRESENTATION.md"
Write-Host ""

Write-Host "📋 Инструкции для пользователей:" -ForegroundColor Yellow
Write-Host "   1. Скачать: ${PACKAGE_NAME}.zip"
Write-Host "   2. Распаковать в любую папку"
Write-Host "   3. Двойной клик на MCP_SHELL_INSTALLER.ps1"
Write-Host "   4. Следовать инструкциям (GUI диалоги)"
Write-Host "   5. Перезапустить VS Code"
Write-Host ""

Write-Host "🚀 GitHub Release:" -ForegroundColor Yellow
Write-Host "   1. Создать новый Release: $VERSION"
Write-Host "   2. Загрузить файл: ${PACKAGE_NAME}.zip"
Write-Host "   3. Загрузить контрольную сумму: ${PACKAGE_NAME}.zip.sha256"
Write-Host "   4. Описание: 'MCP-SHELL расширение для VS Code (Production Ready)'"
Write-Host ""

Write-Host "✨ Готово к публикации!" -ForegroundColor Green
