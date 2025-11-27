# BUILD_RELEASE.ps1
# Скрипт сборки релизной версии WORLD_OLLAMA Desktop Client
# Версия: 0.1.0
# Дата: 27 ноября 2025

# ========================================
# КОНФИГУРАЦИЯ
# ========================================

$ErrorActionPreference = "Stop"
$ROOT = "E:\WORLD_OLLAMA"
$CLIENT_DIR = Join-Path $ROOT "client"
$RELEASE_INFO = @{
    Version = "0.1.0"
    ProductName = "WORLD_OLLAMA"
    BuildDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

# ========================================
# УТИЛИТЫ
# ========================================

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Test-Command {
    param([string]$Command)
    
    try {
        $null = Get-Command $Command -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# ========================================
# ПРОВЕРКА ОКРУЖЕНИЯ
# ========================================

Write-Step "Проверка окружения разработки"

# Node.js
if (-not (Test-Command "node")) {
    Write-Error "Node.js не найден. Установите Node.js 20+ с https://nodejs.org/"
    exit 1
}

$nodeVersion = (node --version) -replace 'v', ''
Write-Host "  Node.js: $nodeVersion" -ForegroundColor Gray

if ([version]$nodeVersion -lt [version]"20.0.0") {
    Write-Warning "Рекомендуется Node.js 20+, у вас $nodeVersion"
}

# npm
if (-not (Test-Command "npm")) {
    Write-Error "npm не найден. Переустановите Node.js."
    exit 1
}

$npmVersion = npm --version
Write-Host "  npm: $npmVersion" -ForegroundColor Gray

# Rust
if (-not (Test-Command "rustc")) {
    Write-Error "Rust не найден. Установите Rust с https://rustup.rs/"
    exit 1
}

$rustVersion = (rustc --version) -replace 'rustc ', ''
Write-Host "  Rust: $rustVersion" -ForegroundColor Gray

# Cargo
if (-not (Test-Command "cargo")) {
    Write-Error "Cargo не найден. Переустановите Rust."
    exit 1
}

$cargoVersion = (cargo --version) -replace 'cargo ', ''
Write-Host "  Cargo: $cargoVersion" -ForegroundColor Gray

Write-Success "Все зависимости установлены"

# ========================================
# ПРОВЕРКА СТРУКТУРЫ ПРОЕКТА
# ========================================

Write-Step "Проверка структуры проекта"

if (-not (Test-Path $CLIENT_DIR)) {
    Write-Error "Директория client не найдена: $CLIENT_DIR"
    exit 1
}

if (-not (Test-Path (Join-Path $CLIENT_DIR "package.json"))) {
    Write-Error "package.json не найден в $CLIENT_DIR"
    exit 1
}

if (-not (Test-Path (Join-Path $CLIENT_DIR "src-tauri"))) {
    Write-Error "src-tauri не найден в $CLIENT_DIR"
    exit 1
}

Write-Success "Структура проекта корректна"

# ========================================
# ПРОВЕРКА ВЕРСИИ В ФАЙЛАХ
# ========================================

Write-Step "Проверка версий в конфигурационных файлах"

$packageJson = Get-Content (Join-Path $CLIENT_DIR "package.json") | ConvertFrom-Json
$tauriConfig = Get-Content (Join-Path $CLIENT_DIR "src-tauri\tauri.conf.json") | ConvertFrom-Json

Write-Host "  package.json version: $($packageJson.version)" -ForegroundColor Gray
Write-Host "  tauri.conf.json version: $($tauriConfig.version)" -ForegroundColor Gray
Write-Host "  Ожидаемая версия: $($RELEASE_INFO.Version)" -ForegroundColor Gray

if ($packageJson.version -ne $RELEASE_INFO.Version -or $tauriConfig.version -ne $RELEASE_INFO.Version) {
    Write-Warning "Версия в файлах не соответствует ожидаемой!"
    Write-Host "  Продолжить сборку? (y/N): " -ForegroundColor Yellow -NoNewline
    $response = Read-Host
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "Сборка отменена."
        exit 0
    }
}

Write-Success "Версии проверены"

# ========================================
# УСТАНОВКА ЗАВИСИМОСТЕЙ
# ========================================

Write-Step "Установка npm зависимостей"

Set-Location $CLIENT_DIR

try {
    npm install
    Write-Success "npm зависимости установлены"
} catch {
    Write-Error "Ошибка установки npm зависимостей: $_"
    exit 1
}

# ========================================
# СБОРКА РЕЛИЗА
# ========================================

Write-Step "Запуск Tauri build"
Write-Host "  Это может занять несколько минут..." -ForegroundColor Gray

try {
    npm run tauri build
    Write-Success "Сборка завершена"
} catch {
    Write-Error "Ошибка сборки: $_"
    exit 1
}

# ========================================
# ПОИСК АРТЕФАКТОВ СБОРКИ
# ========================================

Write-Step "Поиск собранных артефактов"

$bundleDir = Join-Path $CLIENT_DIR "src-tauri\target\release\bundle"

if (-not (Test-Path $bundleDir)) {
    Write-Error "Директория bundle не найдена: $bundleDir"
    exit 1
}

# Найти все артефакты
$artifacts = @()

# MSI installer (Windows)
$msiPath = Join-Path $bundleDir "msi"
if (Test-Path $msiPath) {
    $msiFiles = Get-ChildItem -Path $msiPath -Filter "*.msi" -Recurse
    if ($msiFiles.Count -gt 0) {
        $artifacts += @{
            Type = "MSI Installer"
            Path = $msiFiles[0].FullName
            Size = [math]::Round($msiFiles[0].Length / 1MB, 2)
        }
    }
}

# NSIS installer (Windows)
$nsisPath = Join-Path $bundleDir "nsis"
if (Test-Path $nsisPath) {
    $exeFiles = Get-ChildItem -Path $nsisPath -Filter "*.exe" -Recurse
    if ($exeFiles.Count -gt 0) {
        $artifacts += @{
            Type = "NSIS Installer"
            Path = $exeFiles[0].FullName
            Size = [math]::Round($exeFiles[0].Length / 1MB, 2)
        }
    }
}

# Portable exe
$exePath = Join-Path $CLIENT_DIR "src-tauri\target\release"
$exeFile = Join-Path $exePath "$($RELEASE_INFO.ProductName).exe"
if (Test-Path $exeFile) {
    $exeFileInfo = Get-Item $exeFile
    $artifacts += @{
        Type = "Portable EXE"
        Path = $exeFileInfo.FullName
        Size = [math]::Round($exeFileInfo.Length / 1MB, 2)
    }
}

if ($artifacts.Count -eq 0) {
    Write-Warning "Артефакты сборки не найдены в $bundleDir"
} else {
    Write-Success "Найдено артефактов: $($artifacts.Count)"
    
    foreach ($artifact in $artifacts) {
        Write-Host "`n  📦 $($artifact.Type)" -ForegroundColor Cyan
        Write-Host "     Путь: $($artifact.Path)" -ForegroundColor Gray
        Write-Host "     Размер: $($artifact.Size) MB" -ForegroundColor Gray
    }
}

# ========================================
# ГЕНЕРАЦИЯ ОТЧЁТА
# ========================================

Write-Step "Генерация отчёта о сборке"

$reportPath = Join-Path $ROOT "BUILD_REPORT_v$($RELEASE_INFO.Version).md"

$reportContent = @"
# BUILD REPORT - WORLD_OLLAMA v$($RELEASE_INFO.Version)

**Дата сборки:** $($RELEASE_INFO.BuildDate)  
**Продукт:** $($RELEASE_INFO.ProductName)  
**Версия:** $($RELEASE_INFO.Version)

---

## 🔧 Окружение

| Инструмент | Версия |
|------------|--------|
| Node.js | $nodeVersion |
| npm | $npmVersion |
| Rust | $rustVersion |
| Cargo | $cargoVersion |

---

## 📦 Артефакты сборки

"@

if ($artifacts.Count -gt 0) {
    $reportContent += @"
| Тип | Путь | Размер (MB) |
|------|------|-------------|

"@
    foreach ($artifact in $artifacts) {
        $reportContent += "| $($artifact.Type) | ``$($artifact.Path)`` | $($artifact.Size) |`n"
    }
} else {
    $reportContent += "❌ Артефакты не найдены`n"
}

$reportContent += @"

---

## 📋 Следующие шаги

### 1. Smoke-тест (ручная проверка)

Запусти собранный exe/msi и проверь:

- ✅ Chat: отправка сообщения через Ollama
- ✅ System Status: мониторинг сервисов, автообновление
- ✅ Settings: сохранение/загрузка настроек
- ✅ Library: отображение статуса индексации
- ✅ Commands: парсинг и исполнение INDEX KNOWLEDGE

### 2. Git tag + GitHub Release

``````powershell
# Создать тег
git tag v$($RELEASE_INFO.Version)
git push origin v$($RELEASE_INFO.Version)

# Создать GitHub Release:
# 1. Перейти в https://github.com/Zasada1980/WorldOllama/releases
# 2. Draft a new release
# 3. Tag: v$($RELEASE_INFO.Version)
# 4. Title: WORLD_OLLAMA v$($RELEASE_INFO.Version) (Developer Preview)
# 5. Body: взять из CHANGELOG.md
# 6. Attach binaries: артефакты из таблицы выше
``````

### 3. Обновление документации

- ✅ CHANGELOG.md уже содержит v$($RELEASE_INFO.Version)
- ✅ README.md содержит версию
- ⏳ PROJECT_STATUS_SNAPSHOT обновить статус на "Released"

---

**Статус:** ✅ Сборка завершена успешно  
**Готовность к релизу:** Требуется smoke-тест
"@

Set-Content -Path $reportPath -Value $reportContent -Encoding UTF8
Write-Success "Отчёт сохранён: $reportPath"

# ========================================
# ЗАВЕРШЕНИЕ
# ========================================

Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Green
Write-Host "  СБОРКА ЗАВЕРШЕНА УСПЕШНО" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`n"

Write-Host "📄 Отчёт: $reportPath" -ForegroundColor Cyan
Write-Host "`n"

if ($artifacts.Count -gt 0) {
    Write-Host "🎯 Следующие шаги:" -ForegroundColor Yellow
    Write-Host "  1. Запустить smoke-тест (см. отчёт)" -ForegroundColor Gray
    Write-Host "  2. Создать git tag: git tag v$($RELEASE_INFO.Version)" -ForegroundColor Gray
    Write-Host "  3. Создать GitHub Release с артефактами" -ForegroundColor Gray
} else {
    Write-Warning "Артефакты не найдены! Проверьте логи сборки."
}

Set-Location $ROOT
