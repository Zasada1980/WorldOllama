#!/usr/bin/env pwsh
# ЭТАП 1 - Минимальные E2E тесты для агента консоли
# Проверяет работу automation commands через Tauri API

$ErrorActionPreference = "Stop"

Write-Host "=== ЭТАП 1: Минимальные тесты automation ===" -ForegroundColor Cyan

# Test 1: Cargo check компиляция
Write-Host "`n[Test 1/5] Проверка компиляции automation модулей..." -ForegroundColor Yellow
Push-Location "E:\WORLD_OLLAMA\client\src-tauri"
try {
    $result = cargo check 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Компиляция успешна" -ForegroundColor Green
    } else {
        Write-Host "❌ Ошибка компиляции" -ForegroundColor Red
        Write-Host $result
        exit 1
    }
} finally {
    Pop-Location
}

# Test 2: Проверка наличия automation файлов
Write-Host "`n[Test 2/5] Проверка структуры файлов..." -ForegroundColor Yellow
$requiredFiles = @(
    "E:\WORLD_OLLAMA\client\src-tauri\src\automation\mod.rs",
    "E:\WORLD_OLLAMA\client\src-tauri\src\automation\executor.rs",
    "E:\WORLD_OLLAMA\client\src-tauri\src\automation\monitor.rs",
    "E:\WORLD_OLLAMA\client\src-tauri\src\automation\visualizer.rs",
    "E:\WORLD_OLLAMA\client\src-tauri\src\automation\tests.rs",
    "E:\WORLD_OLLAMA\client\src-tauri\src\automation_commands.rs"
)

$allExist = $true
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  ✅ $($file.Split('\')[-1])" -ForegroundColor Green
    } else {
        Write-Host "  ❌ MISSING: $file" -ForegroundColor Red
        $allExist = $false
    }
}

if (-not $allExist) {
    Write-Host "`n❌ Не все файлы созданы" -ForegroundColor Red
    exit 1
}

# Test 3: Проверка зависимостей в Cargo.toml
Write-Host "`n[Test 3/5] Проверка Cargo.toml зависимостей..." -ForegroundColor Yellow
$cargoToml = Get-Content "E:\WORLD_OLLAMA\client\src-tauri\Cargo.toml" -Raw
$requiredDeps = @("enigo", "accesskit", "notify", "image", "screenshots", "chrono", "serde")

$allDepsPresent = $true
foreach ($dep in $requiredDeps) {
    if ($cargoToml -match $dep) {
        Write-Host "  ✅ $dep" -ForegroundColor Green
    } else {
        Write-Host "  ❌ MISSING: $dep" -ForegroundColor Red
        $allDepsPresent = $false
    }
}

if (-not $allDepsPresent) {
    Write-Host "`n❌ Не все зависимости в Cargo.toml" -ForegroundColor Red
    exit 1
}

# Test 4: Проверка Python orchestrator
Write-Host "`n[Test 4/5] Проверка Python orchestrator..." -ForegroundColor Yellow
Push-Location "E:\WORLD_OLLAMA\automation\orchestrator"
try {
    $pythonOutput = & .\venv\Scripts\python.exe src\main.py 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Python orchestrator запускается" -ForegroundColor Green
        Write-Host "  Output: $($pythonOutput -join ' | ')" -ForegroundColor Gray
    } else {
        Write-Host "❌ Python orchestrator ошибка" -ForegroundColor Red
        Write-Host $pythonOutput
        exit 1
    }
} finally {
    Pop-Location
}

# Test 5: Проверка screenshots API (базовая инициализация)
Write-Host "`n[Test 5/5] Smoke test screenshots crate..." -ForegroundColor Yellow
$testCode = @"
use screenshots::Screen;

fn main() {
    match Screen::all() {
        Ok(screens) => {
            println!("Detected {} screen(s)", screens.len());
            for (i, screen) in screens.iter().enumerate() {
                println!("  Screen {}: {}x{}", i, screen.display_info.width, screen.display_info.height);
            }
            std::process::exit(0);
        }
        Err(e) => {
            eprintln!("Error: {}", e);
            std::process::exit(1);
        }
    }
}
"@

$tempTestDir = "E:\WORLD_OLLAMA\client\src-tauri\target\automation_smoke_test"
New-Item -ItemType Directory -Path $tempTestDir -Force | Out-Null
New-Item -ItemType Directory -Path "$tempTestDir\src" -Force | Out-Null

# Создаём временный Cargo.toml
$testCargoToml = @"
[package]
name = "automation_smoke_test"
version = "0.1.0"
edition = "2021"

[dependencies]
screenshots = "0.8"
"@

Set-Content -Path "$tempTestDir\Cargo.toml" -Value $testCargoToml
Set-Content -Path "$tempTestDir\src\main.rs" -Value $testCode

Push-Location $tempTestDir
try {
    Write-Host "  Компиляция smoke test..." -ForegroundColor Gray
    $buildResult = cargo build --release --quiet 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Запуск smoke test..." -ForegroundColor Gray
        $runResult = & .\target\release\automation_smoke_test.exe 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Screenshots API работает" -ForegroundColor Green
            Write-Host "  $runResult" -ForegroundColor Gray
        } else {
            Write-Host "❌ Screenshots runtime error" -ForegroundColor Red
            Write-Host $runResult
            exit 1
        }
    } else {
        Write-Host "❌ Smoke test компиляция failed" -ForegroundColor Red
        Write-Host $buildResult
        exit 1
    }
} finally {
    Pop-Location
    Remove-Item -Path $tempTestDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Итоговый отчёт
Write-Host "`n=== ✅ ВСЕ ТЕСТЫ ПРОЙДЕНЫ ===" -ForegroundColor Green
Write-Host "ЭТАП 1.1-1.2 ЗАВЕРШЁН:" -ForegroundColor Cyan
Write-Host "  - Automation модули скомпилированы" -ForegroundColor White
Write-Host "  - Все файлы созданы (6 Rust files)" -ForegroundColor White
Write-Host "  - Зависимости установлены (7 crates)" -ForegroundColor White
Write-Host "  - Python orchestrator работает" -ForegroundColor White
Write-Host "  - Screenshots API функционален" -ForegroundColor White

Write-Host "`n📋 Следующий шаг: ЭТАП 1.3 (E2E тесты с Tauri commands)" -ForegroundColor Yellow
exit 0
