# TD-010v2: Безопасный запуск обучения с контролем процессов
# Создано: 27.11.2025
# КРИТИЧНО: Убивает все старые процессы Python перед запуском нового

param(
    [string]$ConfigFile = "triz_qwen1.5b_td010.yaml"
)

$ErrorActionPreference = "Stop"

Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🛡️ БЕЗОПАСНЫЙ ЗАПУСК ОБУЧЕНИЯ TD-010v2" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# ШАГ 1: УБИТЬ ВСЕ ПРОЦЕССЫ PYTHON ИЗ LLAMA_FACTORY
Write-Host "🔪 ШАГ 1: Убиваем все процессы Python (LLaMA Factory)..." -ForegroundColor Yellow
$pythonProcesses = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -like "*llama_factory*"
}

if ($pythonProcesses) {
    $count = ($pythonProcesses | Measure-Object).Count
    Write-Host "   Найдено процессов Python: $count" -ForegroundColor Red
    foreach ($proc in $pythonProcesses) {
        Write-Host "   Убиваю PID $($proc.Id) (RAM: $([math]::Round($proc.WorkingSet/1MB,0)) MB)" -ForegroundColor Red
        Stop-Process -Id $proc.Id -Force
    }
    Start-Sleep -Seconds 3
    Write-Host "   ✅ Все процессы Python убиты" -ForegroundColor Green
} else {
    Write-Host "   ✅ Активных процессов Python не найдено" -ForegroundColor Green
}

# ШАГ 2: ПРОВЕРКА VRAM (должно быть < 2 GB)
Write-Host "`n🎮 ШАГ 2: Проверка VRAM..." -ForegroundColor Yellow
$vramMB = (nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
Write-Host "   VRAM сейчас: $vramMB MB" -ForegroundColor Cyan

if ([int]$vramMB -gt 2000) {
    Write-Host "   ⚠️ VRAM > 2 GB! Ищу процессы, жрущие память..." -ForegroundColor Yellow
    
    # Убиваем Ollama если жив
    $ollamaProc = Get-Process ollama -ErrorAction SilentlyContinue
    if ($ollamaProc) {
        Write-Host "   Убиваю Ollama (PID $($ollamaProc.Id))..." -ForegroundColor Red
        Stop-Process -Name ollama -Force
    }
    
    # Убиваем WSL
    Write-Host "   Останавливаю WSL..." -ForegroundColor Red
    wsl --shutdown
    
    Start-Sleep -Seconds 5
    $vramMB = (nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
    Write-Host "   VRAM после очистки: $vramMB MB" -ForegroundColor Cyan
}

if ([int]$vramMB -lt 2000) {
    Write-Host "   ✅ VRAM готова для обучения" -ForegroundColor Green
} else {
    Write-Host "   ❌ VRAM всё ещё занята! Обучение может упасть!" -ForegroundColor Red
    $confirm = Read-Host "Продолжить всё равно? (y/N)"
    if ($confirm -ne 'y') {
        Write-Host "`n❌ Запуск отменён пользователем" -ForegroundColor Red
        exit 1
    }
}

# ШАГ 3: ПЕРЕХОД В ДИРЕКТОРИЮ LLAMA_FACTORY
Write-Host "`n📂 ШАГ 3: Переход в директорию LLaMA Factory..." -ForegroundColor Yellow
Set-Location E:\WORLD_OLLAMA\services\llama_factory
Write-Host "   ✅ Текущая директория: $PWD" -ForegroundColor Green

# ШАГ 4: ПРОВЕРКА КОНФИГУРАЦИОННОГО ФАЙЛА
Write-Host "`n📄 ШАГ 4: Проверка конфигурации..." -ForegroundColor Yellow
if (-not (Test-Path $ConfigFile)) {
    Write-Host "   ❌ Файл $ConfigFile не найден!" -ForegroundColor Red
    exit 1
}
Write-Host "   ✅ Конфигурация найдена: $ConfigFile" -ForegroundColor Green

# ШАГ 5: ЗАПУСК ОБУЧЕНИЯ
Write-Host "`n🚀 ШАГ 5: Запуск обучения..." -ForegroundColor Yellow
Write-Host "   Команда: .\venv\Scripts\python.exe .\src\train.py $ConfigFile" -ForegroundColor Cyan
Write-Host "   Ожидаемое время: ~10-15 минут (102 шага)" -ForegroundColor Cyan
Write-Host "`n" -ForegroundColor Cyan

# Активация venv и запуск
& .\venv\Scripts\Activate.ps1
& .\venv\Scripts\python.exe .\src\train.py $ConfigFile

# ШАГ 6: ПРОВЕРКА РЕЗУЛЬТАТА
$exitCode = $LASTEXITCODE
Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan

if ($exitCode -eq 0) {
    Write-Host "✅ ОБУЧЕНИЕ ЗАВЕРШЕНО УСПЕШНО!" -ForegroundColor Green
    
    # Проверяем артефакты
    $outputDir = "saves\Qwen2.5-1.5B\lora\triz_extended"
    if (Test-Path $outputDir) {
        Write-Host "`n📦 Артефакты обучения:" -ForegroundColor Cyan
        Get-ChildItem $outputDir -Filter "*.safetensors" | ForEach-Object {
            $sizeMB = [math]::Round($_.Length / 1MB, 2)
            Write-Host "   - $($_.Name): $sizeMB MB" -ForegroundColor Green
        }
    }
} else {
    Write-Host "❌ ОБУЧЕНИЕ ЗАВЕРШИЛОСЬ С ОШИБКОЙ (код $exitCode)" -ForegroundColor Red
    Write-Host "   Проверьте логи выше для диагностики" -ForegroundColor Yellow
}

Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# VRAM после обучения
$vramAfter = (nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
Write-Host "VRAM после обучения: $vramAfter MB`n" -ForegroundColor Cyan

exit $exitCode
