# HEALTH_CHECK_ALL.ps1
# Автоматическая проверка работоспособности всех сервисов WORLD_OLLAMA
# Версия: 1.0
# Дата создания: 03.12.2025

<#
.SYNOPSIS
    Комплексная проверка статуса всех критичных сервисов проекта

.DESCRIPTION
    Проверяет доступность и работоспособность:
    - Ollama API (порт 11434)
    - CORTEX GraphRAG (порт 8004)
    - Наличие необходимых моделей
    - Доступность библиотеки документов
    
.PARAMETER Detailed
    Выводить подробную информацию о каждом компоненте

.PARAMETER Json
    Вывод в JSON формате (для автоматизации)

.EXAMPLE
    .\HEALTH_CHECK_ALL.ps1
    # Быстрая проверка всех сервисов

.EXAMPLE
    .\HEALTH_CHECK_ALL.ps1 -Detailed
    # Подробная информация о каждом компоненте

.EXAMPLE
    .\HEALTH_CHECK_ALL.ps1 -Json | ConvertFrom-Json
    # JSON вывод для парсинга
#>

param(
    [switch]$Detailed,
    [switch]$Json
)

$ErrorActionPreference = "Continue"

# Результаты проверки
$results = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    overall_status = "healthy"
    checks = @()
    critical_failures = @()
}

# Функция проверки HTTP endpoint
function Test-HttpEndpoint {
    param(
        [string]$Name,
        [string]$Url,
        [bool]$Critical = $true,
        [int]$TimeoutSec = 3
    )
    
    $check = @{
        name = $Name
        url = $Url
        critical = $Critical
        status = "unknown"
        response_time_ms = 0
        message = ""
    }
    
    try {
        $startTime = Get-Date
        $response = Invoke-RestMethod -Uri $Url -TimeoutSec $TimeoutSec -ErrorAction Stop
        $endTime = Get-Date
        
        $check.status = "healthy"
        $check.response_time_ms = [int](($endTime - $startTime).TotalMilliseconds)
        $check.message = "OK"
        
        if (-not $Json) {
            Write-Host "✅ $Name`: " -NoNewline -ForegroundColor Green
            Write-Host "OK ($($check.response_time_ms)ms)"
        }
        
    } catch {
        $check.status = "down"
        $check.message = $_.Exception.Message
        
        if ($Critical) {
            $results.overall_status = "degraded"
            $results.critical_failures += $Name
            
            if (-not $Json) {
                Write-Host "❌ $Name`: " -NoNewline -ForegroundColor Red
                Write-Host "DOWN (CRITICAL)" -ForegroundColor Red
                if ($Detailed) {
                    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor DarkRed
                }
            }
        } else {
            if (-not $Json) {
                Write-Host "⚠️  $Name`: " -NoNewline -ForegroundColor Yellow
                Write-Host "DOWN (optional)" -ForegroundColor Yellow
            }
        }
    }
    
    return $check
}

# Функция проверки Ollama моделей
function Test-OllamaModels {
    param(
        [string[]]$RequiredModels = @("qwen2.5:14b", "nomic-embed-text:latest")
    )
    
    $check = @{
        name = "Ollama Models"
        critical = $true
        status = "unknown"
        models_found = @()
        models_missing = @()
        message = ""
    }
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 3
        $availableModels = $response.models.name
        
        foreach ($model in $RequiredModels) {
            if ($availableModels -contains $model) {
                $check.models_found += $model
            } else {
                $check.models_missing += $model
            }
        }
        
        if ($check.models_missing.Count -eq 0) {
            $check.status = "healthy"
            $check.message = "$($check.models_found.Count) required models loaded"
            
            if (-not $Json) {
                Write-Host "✅ Ollama Models: " -NoNewline -ForegroundColor Green
                Write-Host "$($check.models_found.Count)/$($RequiredModels.Count) loaded"
                if ($Detailed) {
                    foreach ($model in $check.models_found) {
                        Write-Host "   ✓ $model" -ForegroundColor DarkGreen
                    }
                }
            }
        } else {
            $check.status = "degraded"
            $check.message = "$($check.models_missing.Count) models missing"
            $results.overall_status = "degraded"
            
            if (-not $Json) {
                Write-Host "⚠️  Ollama Models: " -NoNewline -ForegroundColor Yellow
                Write-Host "$($check.models_found.Count)/$($RequiredModels.Count) loaded" -ForegroundColor Yellow
                if ($Detailed) {
                    foreach ($model in $check.models_missing) {
                        Write-Host "   ✗ $model (missing)" -ForegroundColor Red
                    }
                }
            }
        }
        
    } catch {
        $check.status = "down"
        $check.message = "Failed to check models: $($_.Exception.Message)"
        $results.overall_status = "degraded"
        $results.critical_failures += "Ollama Models"
        
        if (-not $Json) {
            Write-Host "❌ Ollama Models: " -NoNewline -ForegroundColor Red
            Write-Host "Cannot check (Ollama down?)" -ForegroundColor Red
        }
    }
    
    return $check
}

# Функция проверки файловой системы
function Test-FileSystemComponent {
    param(
        [string]$Name,
        [string]$Path,
        [bool]$Critical = $false
    )
    
    $check = @{
        name = $Name
        path = $Path
        critical = $Critical
        status = "unknown"
        message = ""
    }
    
    if (Test-Path $Path) {
        $check.status = "healthy"
        
        if ((Get-Item $Path) -is [System.IO.DirectoryInfo]) {
            $itemCount = (Get-ChildItem $Path -File -Recurse -ErrorAction SilentlyContinue).Count
            $check.message = "$itemCount files"
            
            if (-not $Json) {
                Write-Host "✅ $Name`: " -NoNewline -ForegroundColor Green
                Write-Host "$itemCount files"
            }
        } else {
            $check.message = "exists"
            if (-not $Json) {
                Write-Host "✅ $Name`: exists" -ForegroundColor Green
            }
        }
    } else {
        $check.status = "missing"
        $check.message = "Path not found"
        
        if ($Critical) {
            $results.overall_status = "degraded"
            $results.critical_failures += $Name
        }
        
        if (-not $Json) {
            $color = if ($Critical) { "Red" } else { "Yellow" }
            $prefix = if ($Critical) { "❌" } else { "⚠️ " }
            Write-Host "$prefix $Name`: " -NoNewline -ForegroundColor $color
            Write-Host "NOT FOUND" -ForegroundColor $color
        }
    }
    
    return $check
}

# ==========================
# ОСНОВНАЯ ПРОВЕРКА
# ==========================

if (-not $Json) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "WORLD_OLLAMA Health Check" -ForegroundColor Cyan
    Write-Host "Checking all services..." -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

# 1. Ollama Service
$results.checks += Test-HttpEndpoint -Name "Ollama Service" -Url "http://localhost:11434/api/tags" -Critical $true

# 2. CORTEX Service
$results.checks += Test-HttpEndpoint -Name "CORTEX Service" -Url "http://localhost:8004/health" -Critical $true

# 3. Ollama Models
$results.checks += Test-OllamaModels -RequiredModels @("qwen2.5:14b", "nomic-embed-text:latest", "triz-td010v2:latest")

# 4. Library Documents
$results.checks += Test-FileSystemComponent -Name "Library Documents" -Path "E:\WORLD_OLLAMA\library\raw_documents" -Critical $false

# 5. LightRAG Data
$results.checks += Test-FileSystemComponent -Name "LightRAG Data" -Path "E:\WORLD_OLLAMA\services\lightrag\data" -Critical $false

# 6. Training Datasets
$results.checks += Test-FileSystemComponent -Name "Training Datasets" -Path "E:\WORLD_OLLAMA\services\llama_factory\data" -Critical $false

# 7. Flow Definitions
$results.checks += Test-FileSystemComponent -Name "Flow Definitions" -Path "E:\WORLD_OLLAMA\automation\flows" -Critical $false

# ==========================
# ИТОГОВАЯ СТАТИСТИКА
# ==========================

$totalChecks = $results.checks.Count
$healthyChecks = ($results.checks | Where-Object { $_.status -eq "healthy" }).Count
$degradedChecks = ($results.checks | Where-Object { $_.status -in @("degraded", "down", "missing") }).Count

if (-not $Json) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Total checks: $totalChecks"
    Write-Host "Healthy: $healthyChecks" -ForegroundColor Green
    Write-Host "Issues: $degradedChecks" -ForegroundColor $(if ($degradedChecks -gt 0) { "Yellow" } else { "Green" })
    
    if ($results.critical_failures.Count -gt 0) {
        Write-Host ""
        Write-Host "⚠️  CRITICAL FAILURES:" -ForegroundColor Red
        foreach ($failure in $results.critical_failures) {
            Write-Host "   • $failure" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "Overall Status: " -NoNewline
    switch ($results.overall_status) {
        "healthy" { 
            Write-Host "🟢 HEALTHY" -ForegroundColor Green 
            exit 0
        }
        "degraded" { 
            Write-Host "🟡 DEGRADED" -ForegroundColor Yellow 
            exit 1
        }
        default { 
            Write-Host "🔴 UNKNOWN" -ForegroundColor Red 
            exit 2
        }
    }
} else {
    # JSON вывод
    $results | ConvertTo-Json -Depth 10
    exit $(if ($results.overall_status -eq "healthy") { 0 } else { 1 })
}
