# sync_to_cloud.ps1
# Автоматическая загрузка новых LoRA адаптеров в GitHub через Git LFS
# Создано: 26.11.2025 после успешного Fine-Tuning TD-009

param(
    [string]$SavesDir = "E:\WORLD_OLLAMA\services\llama_factory\saves",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== SYNC TO CLOUD (Git LFS Upload) ===" -ForegroundColor Cyan
Write-Host "Saves Directory: $SavesDir" -ForegroundColor Gray

# Переход в корневой каталог репозитория
Set-Location "E:\WORLD_OLLAMA"

# Проверка наличия Git LFS
try {
    git lfs version | Out-Null
} catch {
    Write-Host "❌ Git LFS не установлен!" -ForegroundColor Red
    exit 1
}

# Поиск новых safetensors файлов
Write-Host "`n📦 Поиск новых .safetensors файлов..." -ForegroundColor Yellow

$newFiles = git status --porcelain | Where-Object {
    $_ -match "\.safetensors$" -and ($_ -match "^\?\?" -or $_ -match "^M ")
}

if ($newFiles.Count -eq 0) {
    Write-Host "✅ Нет новых файлов для загрузки" -ForegroundColor Green
    exit 0
}

Write-Host "Найдено файлов: $($newFiles.Count)" -ForegroundColor Magenta
$newFiles | ForEach-Object {
    $file = $_ -replace "^\?\?\s+", "" -replace "^M\s+", ""
    $size = (Get-Item $file -ErrorAction SilentlyContinue).Length / 1MB
    Write-Host "  - $file ($([math]::Round($size, 2)) MB)" -ForegroundColor Gray
}

if ($DryRun) {
    Write-Host "`n⚠️ DRY RUN режим - файлы НЕ будут загружены" -ForegroundColor Yellow
    exit 0
}

# Добавление файлов в Git
Write-Host "`n📤 Добавление файлов в Git..." -ForegroundColor Yellow
git add saves/**/*.safetensors

# Создание коммита с временной меткой
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$commitMessage = "TD-009 COMPLETE: LoRA adapters uploaded - $timestamp"

Write-Host "`n💾 Создание коммита..." -ForegroundColor Yellow
git commit -m $commitMessage

# Проверка размера файлов перед push
$totalSize = 0
$newFiles | ForEach-Object {
    $file = $_ -replace "^\?\?\s+", "" -replace "^M\s+", ""
    $totalSize += (Get-Item $file -ErrorAction SilentlyContinue).Length
}

$totalSizeMB = [math]::Round($totalSize / 1MB, 2)
Write-Host "Общий размер: $totalSizeMB MB" -ForegroundColor Cyan

if ($totalSizeMB -gt 100) {
    Write-Host "⚠️ Файлы > 100 MB будут загружены через Git LFS" -ForegroundColor Yellow
}

# Push в GitHub
Write-Host "`n🚀 Загрузка в GitHub..." -ForegroundColor Green
git push origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ УСПЕХ! Адаптеры загружены в GitHub" -ForegroundColor Green
    Write-Host "Репозиторий: https://github.com/Zasada1980/WorldOllama" -ForegroundColor Gray
} else {
    Write-Host "`n❌ Ошибка при загрузке!" -ForegroundColor Red
    exit 1
}

# Логирование операции
$logFile = "E:\WORLD_OLLAMA\logs\sync_to_cloud.log"
$logEntry = "[$timestamp] Uploaded $($newFiles.Count) files ($totalSizeMB MB)"
Add-Content -Path $logFile -Value $logEntry

Write-Host "`n📄 Лог операции: $logFile" -ForegroundColor Gray
