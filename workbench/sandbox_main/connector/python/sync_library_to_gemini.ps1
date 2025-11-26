# Автоматическая синхронизация библиотеки знаний с Gemini Files API
# 
# Этот скрипт выполняет полный цикл:
# 1. Экспорт данных из LightRAG кэша
# 2. Загрузка файлов в Gemini Files API
# 3. Отчет о выполнении
#
# Использование:
#   .\sync_library_to_gemini.ps1
#
# Для автоматической синхронизации каждый день в 03:00:
#   1. Откройте Планировщик заданий (Task Scheduler)
#   2. Создайте задачу с триггером "Ежедневно в 03:00"
#   3. Действие: powershell.exe -File "E:\WORLD_OLLAMA\workbench\sandbox_main\connector\python\sync_library_to_gemini.ps1"

param(
    [string]$CacheDir = "E:\AI_Librarian_Core\lightrag_cache",
    [string]$OutputDir = "E:\WORLD_OLLAMA\workbench\sandbox_main\connector\python\gemini_export",
    [string]$PythonVenv = "E:\WORLD_OLLAMA\workbench\sandbox_main\.venv",
    [switch]$AutoCleanup = $false
)

# Функция логирования
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Начало синхронизации
Write-Log "========================================" "INFO"
Write-Log "СИНХРОНИЗАЦИЯ БИБЛИОТЕКИ С GEMINI" "INFO"
Write-Log "========================================" "INFO"

# Проверка наличия Python venv
if (-not (Test-Path "$PythonVenv\Scripts\Activate.ps1")) {
    Write-Log "Виртуальное окружение не найдено: $PythonVenv" "ERROR"
    Write-Log "Создайте venv командой: python -m venv $PythonVenv" "ERROR"
    exit 1
}

# Активация виртуального окружения
Write-Log "Активация Python venv: $PythonVenv" "INFO"
& "$PythonVenv\Scripts\Activate.ps1"

# Проверка установленных пакетов
Write-Log "Проверка зависимостей..." "INFO"
$requiredPackages = @("google-generativeai")

foreach ($package in $requiredPackages) {
    $installed = & python -m pip list | Select-String -Pattern $package -Quiet
    
    if (-not $installed) {
        Write-Log "Установка пакета: $package" "WARNING"
        & python -m pip install $package
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Ошибка установки пакета $package" "ERROR"
            exit 1
        }
    } else {
        Write-Log "Пакет $package установлен" "SUCCESS"
    }
}

# Определение путей к скриптам
$exportScript = Join-Path $PSScriptRoot "export_for_gemini.py"
$uploadScript = Join-Path $PSScriptRoot "upload_to_gemini.py"

# Проверка наличия скриптов
if (-not (Test-Path $exportScript)) {
    Write-Log "Скрипт экспорта не найден: $exportScript" "ERROR"
    exit 1
}

if (-not (Test-Path $uploadScript)) {
    Write-Log "Скрипт загрузки не найден: $uploadScript" "ERROR"
    exit 1
}

# ШАГ 1: Экспорт данных из LightRAG кэша
Write-Log "" "INFO"
Write-Log "========================================" "INFO"
Write-Log "ШАГ 1: ЭКСПОРТ ДАННЫХ ИЗ LIGHTRAG" "INFO"
Write-Log "========================================" "INFO"

Write-Log "Кэш LightRAG: $CacheDir" "INFO"
Write-Log "Выходная папка: $OutputDir" "INFO"

& python $exportScript --cache-dir $CacheDir --output-dir $OutputDir

if ($LASTEXITCODE -ne 0) {
    Write-Log "Ошибка экспорта данных" "ERROR"
    exit 1
}

Write-Log "Экспорт данных завершен успешно" "SUCCESS"

# ШАГ 2: Загрузка файлов в Gemini Files API
Write-Log "" "INFO"
Write-Log "========================================" "INFO"
Write-Log "ШАГ 2: ЗАГРУЗКА В GEMINI FILES API" "INFO"
Write-Log "========================================" "INFO"

$uploadArgs = @("--input-dir", $OutputDir)

if ($AutoCleanup) {
    Write-Log "Режим автоматической очистки включен" "WARNING"
    $uploadArgs += "--auto-cleanup"
}

& python $uploadScript $uploadArgs

if ($LASTEXITCODE -ne 0) {
    Write-Log "Ошибка загрузки файлов в Gemini" "ERROR"
    exit 1
}

Write-Log "Загрузка в Gemini завершена успешно" "SUCCESS"

# Итоговый отчет
Write-Log "" "INFO"
Write-Log "========================================" "INFO"
Write-Log "✅ СИНХРОНИЗАЦИЯ ЗАВЕРШЕНА" "SUCCESS"
Write-Log "========================================" "INFO"

# Информация о файлах
if (Test-Path $OutputDir) {
    $exportedFiles = Get-ChildItem -Path $OutputDir -Filter "*.txt"
    
    Write-Log "" "INFO"
    Write-Log "Экспортированные файлы:" "INFO"
    
    foreach ($file in $exportedFiles) {
        $sizeMB = [math]::Round($file.Length / 1MB, 2)
        Write-Log "  • $($file.Name) ($sizeMB MB)" "INFO"
    }
}

# Следующая синхронизация
$nextSync = (Get-Date).AddDays(1).Date.AddHours(3)
Write-Log "" "INFO"
Write-Log "Следующая синхронизация: $($nextSync.ToString('yyyy-MM-dd HH:mm:ss'))" "INFO"
Write-Log "Срок действия файлов в Gemini: 48 часов с момента загрузки" "WARNING"

# Рекомендации по настройке автозапуска
Write-Log "" "INFO"
Write-Log "💡 Для автоматической ежедневной синхронизации:" "INFO"
Write-Log "   1. Откройте Планировщик заданий Windows (Task Scheduler)" "INFO"
Write-Log "   2. Создайте новую задачу:" "INFO"
Write-Log "      - Триггер: Ежедневно в 03:00" "INFO"
Write-Log "      - Действие: powershell.exe" "INFO"
Write-Log "      - Аргументы: -File `"$PSCommandPath`"" "INFO"
Write-Log "   3. Убедитесь, что задача запускается с правами пользователя" "INFO"

exit 0
