# ============================================================================
# ЗАПУСК FINE-TUNING TD-009: ТРИЗ-СИНТЕЗ
# Дата: 26.11.2025
# Описание: Обучение Qwen2-7B-Instruct с LoRA на датасете ТРИЗ (300 примеров)
# ============================================================================

Write-Host "`n🚀 ИНИЦИАЛИЗАЦИЯ FINE-TUNING TD-009`n" -ForegroundColor Yellow

# Путь к директории LLaMA Factory
$LLAMA_FACTORY_DIR = "E:\WORLD_OLLAMA\services\llama_factory"

# Проверка существования venv
if (-not (Test-Path "$LLAMA_FACTORY_DIR\venv\Scripts\python.exe")) {
    Write-Host "❌ ОШИБКА: venv не найден в $LLAMA_FACTORY_DIR\venv" -ForegroundColor Red
    Read-Host "Нажмите Enter для выхода"
    exit 1
}

# Проверка конфигурации
if (-not (Test-Path "$LLAMA_FACTORY_DIR\triz_safe_config.yaml")) {
    Write-Host "❌ ОШИБКА: Конфигурация triz_safe_config.yaml не найдена" -ForegroundColor Red
    Read-Host "Нажмите Enter для выхода"
    exit 1
}

# Проверка датасета
if (-not (Test-Path "$LLAMA_FACTORY_DIR\data\triz_synthesis_v1.jsonl")) {
    Write-Host "❌ ОШИБКА: Датасет triz_synthesis_v1.jsonl не найден" -ForegroundColor Red
    Read-Host "Нажмите Enter для выхода"
    exit 1
}

# Переход в директорию
Set-Location $LLAMA_FACTORY_DIR

Write-Host "📋 КОНФИГУРАЦИЯ ОБУЧЕНИЯ:" -ForegroundColor Cyan
Write-Host "  Модель: Qwen/Qwen2-7B-Instruct" -ForegroundColor White
Write-Host "  Датасет: triz_synthesis_v1.jsonl (300 примеров)" -ForegroundColor White
Write-Host "  Метод: LoRA (Rank: 8, Alpha: 16)" -ForegroundColor White
Write-Host "  Batch Size: 1, Gradient Accumulation: 4" -ForegroundColor White
Write-Host "  Epochs: 3, Learning Rate: 5e-5" -ForegroundColor White
Write-Host "  Output: saves/Qwen2-7B-Instruct/lora/triz_safe" -ForegroundColor White
Write-Host ""

Write-Host "⏱️ Обучение займет примерно 30-60 минут" -ForegroundColor Yellow
Write-Host "💾 Чекпоинты сохраняются каждые 20 шагов" -ForegroundColor Yellow
Write-Host "📊 Прогресс логируется каждые 5 шагов" -ForegroundColor Yellow
Write-Host ""

Write-Host "⚠️  НЕ ЗАКРЫВАЙТЕ ЭТО ОКНО ДО ЗАВЕРШЕНИЯ ОБУЧЕНИЯ!" -ForegroundColor Red
Write-Host ""

# Запуск обучения
& .\venv\Scripts\python.exe src\train.py triz_safe_config.yaml

# Обработка завершения
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ ОБУЧЕНИЕ ЗАВЕРШЕНО УСПЕШНО!" -ForegroundColor Green
    Write-Host "📁 LoRA адаптеры сохранены в: saves\Qwen2-7B-Instruct\lora\triz_safe" -ForegroundColor Green
    Write-Host ""
    Write-Host "Следующие шаги:" -ForegroundColor Cyan
    Write-Host "  1. Проверить сохраненные файлы адаптеров" -ForegroundColor White
    Write-Host "  2. Закоммитить в GitHub (Git LFS автоматически обработает .safetensors)" -ForegroundColor White
    Write-Host "  3. Создать скрипт sync_to_cloud.ps1 для автоматизации" -ForegroundColor White
} else {
    Write-Host "`n❌ ОБУЧЕНИЕ ПРЕРВАНО С ОШИБКОЙ!" -ForegroundColor Red
    Write-Host "Код выхода: $LASTEXITCODE" -ForegroundColor Red
    Write-Host ""
    Write-Host "Возможные причины:" -ForegroundColor Yellow
    Write-Host "  - Недостаточно VRAM (требуется >8GB свободной)" -ForegroundColor White
    Write-Host "  - Проблема с датасетом или конфигурацией" -ForegroundColor White
    Write-Host "  - Процесс был прерван вручную (Ctrl+C)" -ForegroundColor White
}

Write-Host "`nНажмите Enter для закрытия окна..." -ForegroundColor Gray
Read-Host
