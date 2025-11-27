# ========================================
# WORLD_OLLAMA - Service Health Check
# CHECK_STATUS.ps1
# Версия: 1.0
# Дата: 27 ноября 2025
# ========================================

param(
    [switch]$Detailed = $false,
    [switch]$Continuous = $false,
    [int]$IntervalSeconds = 5
)

function Test-ServiceHealth {
    param(
        [string]$Name,
        [int]$Port,
        [string]$HealthEndpoint
    )
    
    $result = @{
        Name = $Name
        Port = $Port
        Status = "Unknown"
        StatusIcon = "⚪"
        Color = "Gray"
        Details = ""
        ResponseTime = $null
    }
    
    try {
        # Test TCP connection
        $portTest = Test-NetConnection -ComputerName "localhost" -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
        
        if (-not $portTest) {
            $result.Status = "Down"
            $result.StatusIcon = "❌"
            $result.Color = "Red"
            $result.Details = "Port not listening"
            return $result
        }
        
        # Test HTTP health endpoint
        if ($HealthEndpoint) {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            try {
                $response = Invoke-RestMethod -Uri $HealthEndpoint -TimeoutSec 3 -ErrorAction Stop
                $stopwatch.Stop()
                
                $result.Status = "Running"
                $result.StatusIcon = "✅"
                $result.Color = "Green"
                $result.ResponseTime = $stopwatch.ElapsedMilliseconds
                $result.Details = "Response: $($stopwatch.ElapsedMilliseconds)ms"
                
            } catch {
                $stopwatch.Stop()
                $result.Status = "Unhealthy"
                $result.StatusIcon = "⚠️"
                $result.Color = "Yellow"
                $result.Details = "Health check failed: $($_.Exception.Message)"
            }
        } else {
            $result.Status = "Running"
            $result.StatusIcon = "✅"
            $result.Color = "Green"
            $result.Details = "Port listening (no health endpoint)"
        }
        
    } catch {
        $result.Status = "Error"
        $result.StatusIcon = "❌"
        $result.Color = "Red"
        $result.Details = $_.Exception.Message
    }
    
    return $result
}

function Show-StatusReport {
    param([array]$Services)
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "WORLD_OLLAMA Service Status" -ForegroundColor Cyan
    Write-Host "Time: $timestamp" -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($svc in $Services) {
        Write-Host "$($svc.StatusIcon) " -NoNewline -ForegroundColor $svc.Color
        Write-Host "$($svc.Name) " -NoNewline -ForegroundColor White
        Write-Host "(Port $($svc.Port)): " -NoNewline -ForegroundColor Gray
        Write-Host "$($svc.Status)" -ForegroundColor $svc.Color
        
        if ($Detailed -and $svc.Details) {
            Write-Host "   Details: $($svc.Details)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    
    # Summary
    $running = ($Services | Where-Object { $_.Status -eq "Running" }).Count
    $total = $Services.Count
    
    if ($running -eq $total) {
        Write-Host "✓ All services operational ($running/$total)" -ForegroundColor Green
    } elseif ($running -gt 0) {
        Write-Host "⚠ Partial system ($running/$total running)" -ForegroundColor Yellow
    } else {
        Write-Host "✗ All services down (0/$total)" -ForegroundColor Red
    }
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

# ========================================
# SERVICE DEFINITIONS
# ========================================

$services = @(
    @{
        Name = "Ollama"
        Port = 11434
        HealthEndpoint = "http://localhost:11434/api/tags"
    },
    @{
        Name = "CORTEX (LightRAG)"
        Port = 8004
        HealthEndpoint = "http://localhost:8004/health"
    },
    @{
        Name = "Neuro-Terminal"
        Port = 8501
        HealthEndpoint = "http://localhost:8501"
    }
)

# ========================================
# MAIN EXECUTION
# ========================================

if ($Continuous) {
    Write-Host "Continuous monitoring mode (Ctrl+C to stop)" -ForegroundColor Cyan
    Write-Host "Checking every $IntervalSeconds seconds..." -ForegroundColor Gray
    Write-Host ""
    
    while ($true) {
        $results = @()
        foreach ($svc in $services) {
            $results += Test-ServiceHealth @svc
        }
        
        Clear-Host
        Show-StatusReport -Services $results
        
        Start-Sleep -Seconds $IntervalSeconds
    }
} else {
    # Single check
    $results = @()
    foreach ($svc in $services) {
        $results += Test-ServiceHealth @svc
    }
    
    Show-StatusReport -Services $results
}

# Additional info
if ($Detailed) {
    Write-Host "Service Endpoints:" -ForegroundColor Cyan
    Write-Host "  Ollama API:     http://localhost:11434/api" -ForegroundColor Gray
    Write-Host "  CORTEX API:     http://localhost:8004" -ForegroundColor Gray
    Write-Host "  Neuro-Terminal: http://localhost:8501" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "Usage:" -ForegroundColor Cyan
Write-Host "  pwsh CHECK_STATUS.ps1              # Single check" -ForegroundColor Gray
Write-Host "  pwsh CHECK_STATUS.ps1 -Detailed    # Show details" -ForegroundColor Gray
Write-Host "  pwsh CHECK_STATUS.ps1 -Continuous  # Monitor continuously" -ForegroundColor Gray
Write-Host ""
