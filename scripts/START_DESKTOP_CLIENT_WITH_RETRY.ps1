# START_DESKTOP_CLIENT_WITH_RETRY.ps1
# Автоматический запуск Desktop Client с retry logic и проверками
# Priority: HIGH (Task #3 from self-test recommendations)

param(
    [int]$MaxRetries = 3,
    [int]$WaitSeconds = 15
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Desktop Client Launcher with Retry Logic" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Функция очистки процессов
function Clear-DesktopClientProcesses {
    Write-Host "[CLEANUP] Останов��а всех Tauri/Node/WebView2 процессов..." -ForegroundColor Yellow
    Get-Process -Name "tauri_fresh", "node", "msedgewebview2" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    Write-Host "[CLEANUP] Процессы очищены" -ForegroundColor Green
}

# Функция проверки WebView2
function Test-WebView2 {
    Write-Host "[CHECK] Проверка Microsoft Edge WebView2 Runtime..." -ForegroundColor Yellow
    $webview = Get-AppxPackage -Name "*WebView*" -ErrorAction SilentlyContinue
    
    if ($webview) {
        Write-Host "[CHECK] ✅ WebView2 установлен (Version: $($webview.Version))" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[CHECK] ❌ WebView2 НЕ УСТАНОВЛЕН" -ForegroundColor Red
        Write-Host "[CHECK] Установите WebView2 Runtime: https://developer.microsoft.com/en-us/microsoft-edge/webview2/" -ForegroundColor Red
        return $false
    }
}

# Функция запуска Vite
function Start-ViteServer {
    Write-Host "[VITE] Запуск Vite dev server..." -ForegroundColor Yellow
    
    $viteJob = Start-Job -ScriptBlock {
        Set-Location E:\WORLD_OLLAMA\client
        npm run dev
    }
    
    Write-Host "[VITE] Job ID: $($viteJob.Id)" -ForegroundColor Cyan
    
    # Ожидание запуска Vite (до 30 секунд)
    $timeout = 30
    $elapsed = 0
    
    while ($elapsed -lt $timeout) {
        Start-Sleep -Seconds 2
        $elapsed += 2
        
        $portCheck = Test-NetConnection -Port 1420 -InformationLevel Quiet -WarningAction SilentlyContinue
        
        if ($portCheck) {
            Write-Host "[VITE] ✅ Vite запущен на http://localhost:1420 (за $elapsed сек)" -ForegroundColor Green
            return $viteJob
        }
        
        Write-Host "[VITE] Ожидание... ($elapsed/$timeout сек)" -ForegroundColor DarkGray
    }
    
    Write-Host "[VITE] ❌ Timeout: Vite не запустился за $timeout секунд" -ForegroundColor Red
    return $null
}

# Функция запуска Tauri
function Start-TauriClient {
    Write-Host "[TAURI] Запуск Tauri executable..." -ForegroundColor Yellow
    
    $tauriJob = Start-Job -ScriptBlock {
        Set-Location E:\WORLD_OLLAMA\client\src-tauri
        cargo run --no-default-features 2>&1
    }
    
    Write-Host "[TAURI] Job ID: $($tauriJob.Id)" -ForegroundColor Cyan
    
    # Ожидание запуска Tauri (до 20 секунд)
    $timeout = 20
    $elapsed = 0
    
    while ($elapsed -lt $timeout) {
        Start-Sleep -Seconds 2
        $elapsed += 2
        
        $proc = Get-Process -Name "tauri_fresh" -ErrorAction SilentlyContinue
        
        if ($proc) {
            Write-Host "[TAURI] ✅ Tauri запущен (PID: $($proc.Id), за $elapsed сек)" -ForegroundColor Green
            return $tauriJob
        }
        
        # Проверка на краш
        $jobState = (Get-Job -Id $tauriJob.Id).State
        if ($jobState -eq "Failed" -or $jobState -eq "Completed") {
            Write-Host "[TAURI] ❌ Tauri crashed (Job State: $jobState)" -ForegroundColor Red
            $output = Receive-Job -Id $tauriJob.Id 2>&1 | Select-Object -Last 10
            Write-Host "[TAURI] Last output:" -ForegroundColor Yellow
            $output | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
            return $null
        }
        
        Write-Host "[TAURI] Ожидание... ($elapsed/$timeout сек)" -ForegroundColor DarkGray
    }
    
    Write-Host "[TAURI] ❌ Timeout: Tauri не запустился за $timeout секунд" -ForegroundColor Red
    return $null
}

# Функция финальной проверки
function Test-DesktopClient {
    Write-Host "[VERIFY] Финальная проверка Desktop Client..." -ForegroundColor Yellow
    
    # 1. Процесс
    $proc = Get-Process -Name "tauri_fresh" -ErrorAction SilentlyContinue
    if (!$proc) {
        Write-Host "[VERIFY] ❌ Процесс tauri_fresh НЕ НАЙДЕН" -ForegroundColor Red
        return $false
    }
    Write-Host "[VERIFY] ✅ Процесс: tauri_fresh (PID: $($proc.Id))" -ForegroundColor Green
    
    # 2. Порт 1420
    $portCheck = Test-NetConnection -Port 1420 -InformationLevel Quiet -WarningAction SilentlyContinue
    if (!$portCheck) {
        Write-Host "[VERIFY] ❌ Порт 1420 ЗАКРЫТ" -ForegroundColor Red
        return $false
    }
    Write-Host "[VERIFY] ✅ Порт 1420 ОТКРЫТ" -ForegroundColor Green
    
    # 3. HTTP endpoint
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:1420" -TimeoutSec 3 -ErrorAction Stop
        Write-Host "[VERIFY] ✅ UI доступен на http://localhost:1420" -ForegroundColor Green
    } catch {
        Write-Host "[VERIFY] ❌ UI недоступен (HTTP error)" -ForegroundColor Red
        return $false
    }
    
    Write-Host "[VERIFY] 🎉 Desktop Client FUNCTIONAL!" -ForegroundColor Green
    return $true
}

# ========================================
# MAIN LOOP с retry logic
# ========================================

# Проверка WebView2 (КРИТИЧНО)
if (-not (Test-WebView2)) {
    Write-Host "❌ КРИТИЧНАЯ ОШИБКА: WebView2 не установлен. Установите перед запуском." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[RETRY] Максимум попыток: $MaxRetries" -ForegroundColor Cyan
Write-Host "[RETRY] Ожидание между попытками: $WaitSeconds сек" -ForegroundColor Cyan
Write-Host ""

for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
    Write-Host "======================================== Попытка $attempt/$MaxRetries ========================================" -ForegroundColor Cyan
    
    # Очистка процессов перед каждой попыткой
    Clear-DesktopClientProcesses
    
    # Шаг 1: Запуск Vite
    $viteJob = Start-ViteServer
    if (!$viteJob) {
        Write-Host "❌ ПОПЫТКА $attempt НЕУДАЧНА: Vite не запустился" -ForegroundColor Red
        if ($attempt -lt $MaxRetries) {
            Write-Host "⏳ Ожидание $WaitSeconds сек перед следующей попыткой..." -ForegroundColor Yellow
            Start-Sleep -Seconds $WaitSeconds
        }
        continue
    }
    
    # Шаг 2: Запуск Tauri
    $tauriJob = Start-TauriClient
    if (!$tauriJob) {
        Write-Host "❌ ПОПЫТКА $attempt НЕУДАЧНА: Tauri не запустился" -ForegroundColor Red
        Stop-Job -Id $viteJob.Id
        if ($attempt -lt $MaxRetries) {
            Write-Host "⏳ Ожидание $WaitSeconds сек перед следующей попыткой..." -ForegroundColor Yellow
            Start-Sleep -Seconds $WaitSeconds
        }
        continue
    }
    
    # Шаг 3: Финальная проверка
    $isWorking = Test-DesktopClient
    if ($isWorking) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "✅ SUCCESS: Desktop Client запущен!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Vite Job ID: $($viteJob.Id)" -ForegroundColor Cyan
        Write-Host "Tauri Job ID: $($tauriJob.Id)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Для остановки используйте:" -ForegroundColor Yellow
        Write-Host "  Stop-Job -Id $($viteJob.Id), $($tauriJob.Id)" -ForegroundColor Yellow
        Write-Host "  Get-Process tauri_fresh | Stop-Process -Force" -ForegroundColor Yellow
        Write-Host ""
        exit 0
    } else {
        Write-Host "❌ ПОПЫТКА $attempt НЕУДАЧНА: Финальная проверка провалилась" -ForegroundColor Red
        Stop-Job -Id $viteJob.Id, $tauriJob.Id
        if ($attempt -lt $MaxRetries) {
            Write-Host "⏳ Ожидание $WaitSeconds сек перед следующей попыткой..." -ForegroundColor Yellow
            Start-Sleep -Seconds $WaitSeconds
        }
    }
}

# Все попытки исчерпаны
Write-Host ""
Write-Host "========================================" -ForegroundColor Red
Write-Host "❌ FAILED: Desktop Client не запустился после $MaxRetries попыток" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""
Write-Host "Возможные причины:" -ForegroundColor Yellow
Write-Host "  1. WebView2 Runtime corrupted (переустановите)" -ForegroundColor Yellow
Write-Host "  2. Конфликт портов (проверьте Get-NetTCPConnection -LocalPort 1420)" -ForegroundColor Yellow
Write-Host "  3. Tauri runtime bug (проверьте client/src-tauri/target/debug/tauri_fresh.exe вручную)" -ForegroundColor Yellow
Write-Host ""
exit 1
