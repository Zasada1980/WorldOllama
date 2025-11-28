# ОРДЕР №19 - Docker Build Script
# Автоматическая компиляция через Docker

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "ОРДЕР №19 - DOCKER COMPILATION" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Continue"

# Build Docker image
Write-Host "[1/2] Building Docker image..." -ForegroundColor Yellow
docker build -f Dockerfile.build -t world-ollama-build:v0.2.0 .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Docker image built successfully" -ForegroundColor Green
Write-Host ""

# Run compilation inside container
Write-Host "[2/2] Running compilation..." -ForegroundColor Yellow
docker run --rm world-ollama-build:v0.2.0

$exitCode = $LASTEXITCODE

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "РЕЗУЛЬТАТ" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan

if ($exitCode -eq 0) {
    Write-Host "✅ Компиляция успешна!" -ForegroundColor Green
}
else {
    Write-Host "❌ Компиляция провалена (exit code: $exitCode)" -ForegroundColor Red
}

exit $exitCode
