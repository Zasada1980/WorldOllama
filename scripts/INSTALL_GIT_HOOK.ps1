<#
.SYNOPSIS
    Установщик Git-хука post-commit для WORLD_OLLAMA

.DESCRIPTION
    Копирует post-commit.hook в .git/hooks/post-commit и делает его исполняемым

.EXAMPLE
    .\INSTALL_GIT_HOOK.ps1

.NOTES
    Версия: 1.0
    Автор: AI Agent (GitHub Copilot)
    Дата: 03.12.2025
#>

$ErrorActionPreference = "Stop"

$ProjectRoot = "E:\WORLD_OLLAMA"
$SourceHook = "$ProjectRoot\scripts\post-commit.hook"
$TargetHook = "$ProjectRoot\.git\hooks\post-commit"

Write-Host "`n🔧 УСТАНОВКА GIT-ХУКА POST-COMMIT`n" -ForegroundColor Cyan

# Проверить наличие исходного файла
if (-not (Test-Path $SourceHook)) {
    Write-Host "❌ ОШИБКА: Файл $SourceHook не найден" -ForegroundColor Red
    exit 1
}

# Проверить наличие .git директории
if (-not (Test-Path "$ProjectRoot\.git")) {
    Write-Host "❌ ОШИБКА: .git директория не найдена в $ProjectRoot" -ForegroundColor Red
    Write-Host "   Убедитесь, что скрипт запускается из корня Git-репозитория" -ForegroundColor Yellow
    exit 1
}

# Создать директорию hooks если не существует
$hooksDir = "$ProjectRoot\.git\hooks"
if (-not (Test-Path $hooksDir)) {
    Write-Host "📁 Создание директории hooks..." -ForegroundColor Gray
    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
}

# Резервная копия существующего хука
if (Test-Path $TargetHook) {
    $backupFile = "$TargetHook.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Host "💾 Резервная копия существующего хука: $backupFile" -ForegroundColor Yellow
    Copy-Item $TargetHook $backupFile -Force
}

# Копировать хук
Write-Host "📋 Копирование хука: $SourceHook → $TargetHook" -ForegroundColor Gray
Copy-Item $SourceHook $TargetHook -Force

# Сделать исполняемым (для Git Bash on Windows)
try {
    # Использовать Git для установки executable bit
    $gitExe = (Get-Command git -ErrorAction SilentlyContinue).Source
    if ($gitExe) {
        & git update-index --chmod=+x .git/hooks/post-commit 2>$null
        Write-Host "✅ Установлен executable bit (Git)" -ForegroundColor Green
    }
}
catch {
    Write-Host "⚠️  Не удалось установить executable bit через Git (игнорируется)" -ForegroundColor Yellow
}

# Проверить содержимое хука
$hookContent = Get-Content $TargetHook -Raw
if ($hookContent -match 'UPDATE_PROJECT_INDEX\.ps1') {
    Write-Host "✅ Хук содержит ссылку на UPDATE_PROJECT_INDEX.ps1" -ForegroundColor Green
} else {
    Write-Host "⚠️  ПРЕДУПРЕЖДЕНИЕ: Хук не содержит ожидаемую ссылку на скрипт" -ForegroundColor Yellow
}

Write-Host "`n✅ GIT-ХУК УСТАНОВЛЕН УСПЕШНО`n" -ForegroundColor Green
Write-Host "Теперь при каждом коммите с изменениями .md файлов будет автоматически" -ForegroundColor White
Write-Host "обновляться индекс RUNTIME_LOGS_JOURNAL_INDEX.md`n" -ForegroundColor White

Write-Host "Для проверки работы хука выполните тестовый коммит:" -ForegroundColor Cyan
Write-Host "  git add README.md" -ForegroundColor Gray
Write-Host "  git commit -m 'test: проверка post-commit hook'`n" -ForegroundColor Gray

exit 0
