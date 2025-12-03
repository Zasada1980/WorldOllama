<#
.SYNOPSIS
    Комплексные тесты системной целостности после внедрения обновлений

.DESCRIPTION
    Проверяет:
    1. Существование всех скриптов
    2. Синтаксис PowerShell
    3. Синтаксис Shell скрипта (Git hook)
    4. Зависимости и пути
    5. Права доступа к файлам

.EXAMPLE
    .\TEST_SYSTEM_INTEGRITY.ps1

.NOTES
    Версия: 1.0
    Автор: AI Agent (GitHub Copilot)
    Дата: 03.12.2025
#>

$ErrorActionPreference = "Continue"
$ProjectRoot = "E:\WORLD_OLLAMA"

$results = @{
    passed = 0
    failed = 0
    warnings = 0
    tests = @()
}

function Test-Item {
    param(
        [string]$Name,
        [scriptblock]$TestBlock,
        [string]$Category = "GENERAL"
    )
    
    Write-Host "`n[$Category] Тест: $Name" -ForegroundColor Cyan
    
    try {
        $result = & $TestBlock
        
        if ($result.Success) {
            Write-Host "  ✅ PASS" -ForegroundColor Green
            if ($result.Message) {
                Write-Host "     $($result.Message)" -ForegroundColor Gray
            }
            $script:results.passed++
        } else {
            Write-Host "  ❌ FAIL" -ForegroundColor Red
            Write-Host "     $($result.Message)" -ForegroundColor Yellow
            $script:results.failed++
        }
        
        if ($result.Warning) {
            Write-Host "  ⚠️  WARNING: $($result.Warning)" -ForegroundColor Yellow
            $script:results.warnings++
        }
        
        $script:results.tests += @{
            category = $Category
            name = $Name
            success = $result.Success
            message = $result.Message
            warning = $result.Warning
        }
    }
    catch {
        Write-Host "  ❌ EXCEPTION: $($_.Exception.Message)" -ForegroundColor Red
        $script:results.failed++
        
        $script:results.tests += @{
            category = $Category
            name = $Name
            success = $false
            message = $_.Exception.Message
            warning = $null
        }
    }
}

Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  ТЕСТЫ СИСТЕМНОЙ ЦЕЛОСТНОСТИ — WORLD_OLLAMA INDEXATION     ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# ============================================================================
# КАТЕГОРИЯ 1: СУЩЕСТВОВАНИЕ ФАЙЛОВ
# ============================================================================

Test-Item "WATCH_FILE_CHANGES.ps1 существует" {
    $path = "$ProjectRoot\scripts\WATCH_FILE_CHANGES.ps1"
    if (Test-Path $path) {
        return @{ Success = $true; Message = "Размер: $((Get-Item $path).Length) байт" }
    }
    return @{ Success = $false; Message = "Файл не найден: $path" }
} -Category "FILES"

Test-Item "UPDATE_PROJECT_INDEX.ps1 существует" {
    $path = "$ProjectRoot\scripts\UPDATE_PROJECT_INDEX.ps1"
    if (Test-Path $path) {
        return @{ Success = $true; Message = "Размер: $((Get-Item $path).Length) байт" }
    }
    return @{ Success = $false; Message = "Файл не найден: $path" }
} -Category "FILES"

Test-Item "post-commit.hook существует" {
    $path = "$ProjectRoot\scripts\post-commit.hook"
    if (Test-Path $path) {
        return @{ Success = $true; Message = "Размер: $((Get-Item $path).Length) байт" }
    }
    return @{ Success = $false; Message = "Файл не найден: $path" }
} -Category "FILES"

Test-Item "CREATE_SCHEDULED_TASK.ps1 существует" {
    $path = "$ProjectRoot\scripts\CREATE_SCHEDULED_TASK.ps1"
    if (Test-Path $path) {
        return @{ Success = $true; Message = "Размер: $((Get-Item $path).Length) байт" }
    }
    return @{ Success = $false; Message = "Файл не найден: $path" }
} -Category "FILES"

Test-Item "INSTALL_GIT_HOOK.ps1 существует" {
    $path = "$ProjectRoot\scripts\INSTALL_GIT_HOOK.ps1"
    if (Test-Path $path) {
        return @{ Success = $true; Message = "Размер: $((Get-Item $path).Length) байт" }
    }
    return @{ Success = $false; Message = "Файл не найден: $path" }
} -Category "FILES"

# ============================================================================
# КАТЕГОРИЯ 2: СИНТАКСИС POWERSHELL
# ============================================================================

Test-Item "WATCH_FILE_CHANGES.ps1 синтаксис" {
    $path = "$ProjectRoot\scripts\WATCH_FILE_CHANGES.ps1"
    $errors = $null
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $path -Raw), [ref]$errors)
    
    if ($errors.Count -eq 0) {
        return @{ Success = $true; Message = "Синтаксис корректен" }
    }
    return @{ Success = $false; Message = "Найдено ошибок: $($errors.Count)" }
} -Category "SYNTAX"

Test-Item "UPDATE_PROJECT_INDEX.ps1 синтаксис" {
    $path = "$ProjectRoot\scripts\UPDATE_PROJECT_INDEX.ps1"
    $errors = $null
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $path -Raw), [ref]$errors)
    
    if ($errors.Count -eq 0) {
        return @{ Success = $true; Message = "Синтаксис корректен" }
    }
    return @{ Success = $false; Message = "Найдено ошибок: $($errors.Count)" }
} -Category "SYNTAX"

Test-Item "CREATE_SCHEDULED_TASK.ps1 синтаксис" {
    $path = "$ProjectRoot\scripts\CREATE_SCHEDULED_TASK.ps1"
    $errors = $null
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $path -Raw), [ref]$errors)
    
    if ($errors.Count -eq 0) {
        return @{ Success = $true; Message = "Синтаксис корректен" }
    }
    return @{ Success = $false; Message = "Найдено ошибок: $($errors.Count)" }
} -Category "SYNTAX"

Test-Item "INSTALL_GIT_HOOK.ps1 синтаксис" {
    $path = "$ProjectRoot\scripts\INSTALL_GIT_HOOK.ps1"
    $errors = $null
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $path -Raw), [ref]$errors)
    
    if ($errors.Count -eq 0) {
        return @{ Success = $true; Message = "Синтаксис корректен" }
    }
    return @{ Success = $false; Message = "Найдено ошибок: $($errors.Count)" }
} -Category "SYNTAX"

# ============================================================================
# КАТЕГОРИЯ 3: SHELL СКРИПТ (Git hook)
# ============================================================================

Test-Item "post-commit.hook shebang корректен" {
    $path = "$ProjectRoot\scripts\post-commit.hook"
    $firstLine = (Get-Content $path -TotalCount 1)
    
    if ($firstLine -eq '#!/bin/sh') {
        return @{ Success = $true; Message = "Shebang найден: $firstLine" }
    }
    return @{ Success = $false; Message = "Некорректный shebang: $firstLine" }
} -Category "SHELL"

Test-Item "post-commit.hook содержит ссылку на UPDATE_PROJECT_INDEX.ps1" {
    $path = "$ProjectRoot\scripts\post-commit.hook"
    $content = Get-Content $path -Raw
    
    if ($content -match 'UPDATE_PROJECT_INDEX\.ps1') {
        return @{ Success = $true; Message = "Ссылка найдена" }
    }
    return @{ Success = $false; Message = "Ссылка на скрипт не найдена" }
} -Category "SHELL"

# ============================================================================
# КАТЕГОРИЯ 4: ЗАВИСИМОСТИ И ПУТИ
# ============================================================================

Test-Item "Индексный файл существует" {
    $path = "$ProjectRoot\docs\project\RUNTIME_LOGS_JOURNAL_INDEX.md"
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        return @{ Success = $true; Message = "Размер: $size байт" }
    }
    return @{ Success = $false; Message = "Файл не найден: $path" }
} -Category "DEPENDENCIES"

Test-Item "Директория logs существует" {
    $path = "$ProjectRoot\logs"
    if (Test-Path $path) {
        $count = (Get-ChildItem $path -Recurse -File).Count
        return @{ Success = $true; Message = "Файлов в logs: $count" }
    }
    return @{ Success = $false; Message = "Директория не найдена: $path" }
} -Category "DEPENDENCIES"

Test-Item ".git директория существует" {
    $path = "$ProjectRoot\.git"
    if (Test-Path $path) {
        return @{ Success = $true; Message = "Git репозиторий инициализирован" }
    }
    return @{ 
        Success = $false
        Message = ".git не найден"
        Warning = "Git-хук не может быть установлен без .git директории"
    }
} -Category "DEPENDENCIES"

Test-Item "pwsh.exe доступен в PATH" {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) {
        return @{ Success = $true; Message = "Версия: $($pwsh.Version)" }
    }
    return @{ 
        Success = $false
        Message = "pwsh.exe не найден"
        Warning = "FileSystemWatcher и Scheduled Task могут не работать"
    }
} -Category "DEPENDENCIES"

# ============================================================================
# КАТЕГОРИЯ 5: ПРАВА ДОСТУПА
# ============================================================================

Test-Item "Скрипты доступны для чтения" {
    $scripts = @(
        "$ProjectRoot\scripts\WATCH_FILE_CHANGES.ps1",
        "$ProjectRoot\scripts\UPDATE_PROJECT_INDEX.ps1",
        "$ProjectRoot\scripts\CREATE_SCHEDULED_TASK.ps1",
        "$ProjectRoot\scripts\INSTALL_GIT_HOOK.ps1"
    )
    
    $unreadable = @()
    foreach ($script in $scripts) {
        try {
            $null = Get-Content $script -TotalCount 1 -ErrorAction Stop
        }
        catch {
            $unreadable += $script
        }
    }
    
    if ($unreadable.Count -eq 0) {
        return @{ Success = $true; Message = "Все скрипты доступны для чтения" }
    }
    return @{ Success = $false; Message = "Недоступны: $($unreadable -join ', ')" }
} -Category "PERMISSIONS"

Test-Item "Директория logs доступна для записи" {
    $testFile = "$ProjectRoot\logs\test_write_access.tmp"
    try {
        "test" | Out-File $testFile -ErrorAction Stop
        Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        return @{ Success = $true; Message = "Запись разрешена" }
    }
    catch {
        return @{ Success = $false; Message = "Запись запрещена: $($_.Exception.Message)" }
    }
} -Category "PERMISSIONS"

# ============================================================================
# ИТОГОВАЯ СТАТИСТИКА
# ============================================================================

Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    ИТОГОВАЯ СТАТИСТИКА                       ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "✅ PASSED:   $($results.passed)" -ForegroundColor Green
Write-Host "❌ FAILED:   $($results.failed)" -ForegroundColor Red
Write-Host "⚠️  WARNINGS: $($results.warnings)" -ForegroundColor Yellow
Write-Host "📊 TOTAL:    $($results.tests.Count)`n" -ForegroundColor White

$successRate = [math]::Round(($results.passed / $results.tests.Count) * 100, 1)
Write-Host "Success Rate: $successRate%`n" -ForegroundColor $(if ($successRate -ge 90) { "Green" } elseif ($successRate -ge 70) { "Yellow" } else { "Red" })

# Сохранить результаты
$reportPath = "$ProjectRoot\logs\test_system_integrity_report.json"
$results | ConvertTo-Json -Depth 5 | Out-File $reportPath
Write-Host "📄 Детальный отчёт сохранён: $reportPath`n" -ForegroundColor Gray

if ($results.failed -eq 0) {
    Write-Host "✅ ВСЕ ТЕСТЫ ПРОЙДЕНЫ — СИСТЕМА ЦЕЛОСТНА`n" -ForegroundColor Green
    exit 0
} else {
    Write-Host "⚠️  ОБНАРУЖЕНЫ ПРОБЛЕМЫ — ТРЕБУЕТСЯ ИСПРАВЛЕНИЕ`n" -ForegroundColor Yellow
    exit 1
}
