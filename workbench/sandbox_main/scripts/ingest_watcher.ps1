<#
.SYNOPSIS
    Data Tray Ingestion Watcher - автоматический перенос знаний в библиотеку
.DESCRIPTION
    Реализация TD-004: Система "Data Tray" (Принцип 10 ТРИЗ - Предварительное исполнение)
    
    Принцип работы:
    1. Сканирует папку inputs/data_tray на наличие .txt/.md/.pdf
    2. Выполняет санитизацию имени файла (убирает пробелы, спецсимволы)
    3. Проверяет кодировку (предпочтительно UTF-8)
    4. Атомарно перемещает в library/raw_documents
    5. Логирует результат в logs/ingestion.log
    
    Архитектура: "Пропускной пункт" с валидацией
.NOTES
    Версия: 1.0 (25.11.2025 - TD-004 Implementation)
    Автор: SESA Development Protocol
#>

[CmdletBinding()]
param(
    [switch]$WatchMode,      # Режим непрерывного наблюдения (пока не реализован)
    [switch]$DetailedOutput, # Подробный вывод (вместо Verbose для избежания конфликта)
    [switch]$DryRun          # Тестовый запуск без реального перемещения
)

# === КОНСТАНТЫ ПУТЕЙ ===
$sandboxRoot = Split-Path -Parent $PSScriptRoot
$trayPath = Join-Path $sandboxRoot "inputs\data_tray"
$libraryPath = "E:\WORLD_OLLAMA\library\raw_documents"
$logPath = Join-Path $sandboxRoot "logs\ingestion.log"

# Проверка существования директорий
if (-not (Test-Path $trayPath)) {
    throw "[FATAL] Data Tray not found: $trayPath. Create it first."
}

if (-not (Test-Path $libraryPath)) {
    throw "[FATAL] Library raw_documents not found: $libraryPath. Check WORLD_OLLAMA structure."
}

$logDir = Split-Path $logPath -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# === ФУНКЦИИ САНИТИЗАЦИИ ===

function Sanitize-FileName {
    param([string]$FileName)
    
    # Шаг 1: Транслитерация кириллицы (критично для векторных БД)
    # Используем последовательные replace вместо hashtable для избежания encoding проблем
    $sanitized = $FileName
    
    # Строчные буквы
    $sanitized = $sanitized -creplace 'а', 'a'
    $sanitized = $sanitized -creplace 'б', 'b'
    $sanitized = $sanitized -creplace 'в', 'v'
    $sanitized = $sanitized -creplace 'г', 'g'
    $sanitized = $sanitized -creplace 'д', 'd'
    $sanitized = $sanitized -creplace 'е', 'e'
    $sanitized = $sanitized -creplace 'ё', 'yo'
    $sanitized = $sanitized -creplace 'ж', 'zh'
    $sanitized = $sanitized -creplace 'з', 'z'
    $sanitized = $sanitized -creplace 'и', 'i'
    $sanitized = $sanitized -creplace 'й', 'y'
    $sanitized = $sanitized -creplace 'к', 'k'
    $sanitized = $sanitized -creplace 'л', 'l'
    $sanitized = $sanitized -creplace 'м', 'm'
    $sanitized = $sanitized -creplace 'н', 'n'
    $sanitized = $sanitized -creplace 'о', 'o'
    $sanitized = $sanitized -creplace 'п', 'p'
    $sanitized = $sanitized -creplace 'р', 'r'
    $sanitized = $sanitized -creplace 'с', 's'
    $sanitized = $sanitized -creplace 'т', 't'
    $sanitized = $sanitized -creplace 'у', 'u'
    $sanitized = $sanitized -creplace 'ф', 'f'
    $sanitized = $sanitized -creplace 'х', 'h'
    $sanitized = $sanitized -creplace 'ц', 'ts'
    $sanitized = $sanitized -creplace 'ч', 'ch'
    $sanitized = $sanitized -creplace 'ш', 'sh'
    $sanitized = $sanitized -creplace 'щ', 'sch'
    $sanitized = $sanitized -creplace 'ъ', ''
    $sanitized = $sanitized -creplace 'ы', 'y'
    $sanitized = $sanitized -creplace 'ь', ''
    $sanitized = $sanitized -creplace 'э', 'e'
    $sanitized = $sanitized -creplace 'ю', 'yu'
    $sanitized = $sanitized -creplace 'я', 'ya'
    
    # Заглавные буквы
    $sanitized = $sanitized -creplace 'А', 'A'
    $sanitized = $sanitized -creplace 'Б', 'B'
    $sanitized = $sanitized -creplace 'В', 'V'
    $sanitized = $sanitized -creplace 'Г', 'G'
    $sanitized = $sanitized -creplace 'Д', 'D'
    $sanitized = $sanitized -creplace 'Е', 'E'
    $sanitized = $sanitized -creplace 'Ё', 'Yo'
    $sanitized = $sanitized -creplace 'Ж', 'Zh'
    $sanitized = $sanitized -creplace 'З', 'Z'
    $sanitized = $sanitized -creplace 'И', 'I'
    $sanitized = $sanitized -creplace 'Й', 'Y'
    $sanitized = $sanitized -creplace 'К', 'K'
    $sanitized = $sanitized -creplace 'Л', 'L'
    $sanitized = $sanitized -creplace 'М', 'M'
    $sanitized = $sanitized -creplace 'Н', 'N'
    $sanitized = $sanitized -creplace 'О', 'O'
    $sanitized = $sanitized -creplace 'П', 'P'
    $sanitized = $sanitized -creplace 'Р', 'R'
    $sanitized = $sanitized -creplace 'С', 'S'
    $sanitized = $sanitized -creplace 'Т', 'T'
    $sanitized = $sanitized -creplace 'У', 'U'
    $sanitized = $sanitized -creplace 'Ф', 'F'
    $sanitized = $sanitized -creplace 'Х', 'H'
    $sanitized = $sanitized -creplace 'Ц', 'Ts'
    $sanitized = $sanitized -creplace 'Ч', 'Ch'
    $sanitized = $sanitized -creplace 'Ш', 'Sh'
    $sanitized = $sanitized -creplace 'Щ', 'Sch'
    $sanitized = $sanitized -creplace 'Ъ', ''
    $sanitized = $sanitized -creplace 'Ы', 'Y'
    $sanitized = $sanitized -creplace 'Ь', ''
    $sanitized = $sanitized -creplace 'Э', 'E'
    $sanitized = $sanitized -creplace 'Ю', 'Yu'
    $sanitized = $sanitized -creplace 'Я', 'Ya'
    
    # Шаг 2: Пробелы → подчеркивания
    $sanitized = $sanitized -replace '\s+', '_'
    
    # Шаг 3: Убираем опасные символы Windows filesystem + спецсимволы
    $sanitized = $sanitized -replace '[<>:"/\\|?*#№]', ''
    
    # Шаг 4: Убираем множественные подчеркивания
    $sanitized = $sanitized -replace '_{2,}', '_'
    
    # Шаг 5: Убираем подчеркивания в начале/конце
    $sanitized = $sanitized.Trim('_')
    
    # Шаг 6: Приводим к lowercase для консистентности (snake_case)
    $sanitized = $sanitized.ToLower()
    
    return $sanitized
}

function Test-FileEncoding {
    param([string]$FilePath)
    
    # Простая эвристика: читаем первые байты
    # PowerShell 7+: используем AsByteStream вместо -Encoding Byte
    try {
        $bytes = Get-Content $FilePath -AsByteStream -TotalCount 4 -ErrorAction Stop
    }
    catch {
        # Fallback для PowerShell 5.1
        $bytes = Get-Content $FilePath -Encoding Byte -TotalCount 4 -ErrorAction SilentlyContinue
    }
    
    if ($null -eq $bytes -or $bytes.Count -eq 0) { return "UNKNOWN" }
    
    # UTF-8 BOM: EF BB BF
    if ($bytes.Count -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return "UTF8-BOM"
    }
    
    # UTF-16 LE BOM: FF FE
    if ($bytes.Count -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        return "UTF16-LE"
    }
    
    # UTF-16 BE BOM: FE FF
    if ($bytes.Count -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        return "UTF16-BE"
    }
    
    # Без BOM, предполагаем ASCII/UTF8
    return "UTF8-NOBOM"
}

# === ОСНОВНАЯ ЛОГИКА INGESTION ===

function Process-TrayFiles {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] === INGESTION RUN START ==="
    $logEntry | Tee-Object -FilePath $logPath -Append | Write-Host -ForegroundColor Cyan
    
    $files = Get-ChildItem -Path $trayPath -File | Where-Object {
        $_.Extension -in @('.txt', '.md', '.pdf')
    }
    
    if ($files.Count -eq 0) {
        $emptyMsg = "[$timestamp] Data Tray empty. No files to process."
        $emptyMsg | Tee-Object -FilePath $logPath -Append | Write-Host -ForegroundColor Yellow
        return
    }
    
    $processed = 0
    $skipped = 0
    
    foreach ($file in $files) {
        $originalName = $file.Name
        $sanitizedName = Sanitize-FileName $file.BaseName
        $newName = "$sanitizedName$($file.Extension)"
        
        # Проверка на коллизию имени в целевой библиотеке
        $destPath = Join-Path $libraryPath $newName
        if (Test-Path $destPath) {
            # Добавляем timestamp к имени при коллизии
            $collision = Get-Date -Format "yyyyMMdd_HHmmss"
            $newName = "${sanitizedName}_$collision$($file.Extension)"
            $destPath = Join-Path $libraryPath $newName
            
            $warnMsg = "[$timestamp] [WARN] Name collision detected: $originalName -> $newName"
            $warnMsg | Tee-Object -FilePath $logPath -Append | Write-Host -ForegroundColor Yellow
        }
        
        # Проверка кодировки (для .txt/.md)
        if ($file.Extension -in @('.txt', '.md')) {
            $encoding = Test-FileEncoding -FilePath $file.FullName
            $encMsg = "[$timestamp] [INFO] $originalName encoding: $encoding"
            
            if ($DetailedOutput) {
                $encMsg | Tee-Object -FilePath $logPath -Append | Write-Host -ForegroundColor Gray
            }
            
            if ($encoding -notin @('UTF8-BOM', 'UTF8-NOBOM')) {
                $warnMsg = "[$timestamp] [WARN] Non-UTF8 encoding detected: $originalName ($encoding)"
                $warnMsg | Tee-Object -FilePath $logPath -Append | Write-Host -ForegroundColor Yellow
            }
        }
        
        # Перемещение (или dry run)
        if ($DryRun) {
            $dryMsg = "[$timestamp] [DRY-RUN] Would move: $originalName -> $newName"
            $dryMsg | Tee-Object -FilePath $logPath -Append | Write-Host -ForegroundColor Magenta
            $processed++
        }
        else {
            try {
                Move-Item -Path $file.FullName -Destination $destPath -Force -ErrorAction Stop
                
                $successMsg = "[$timestamp] [SUCCESS] Ingested: $originalName -> $newName"
                $successMsg | Tee-Object -FilePath $logPath -Append | Write-Host -ForegroundColor Green
                $processed++
            }
            catch {
                $errorMsg = "[$timestamp] [ERROR] Failed to move $originalName : $_"
                $errorMsg | Tee-Object -FilePath $logPath -Append | Write-Host -ForegroundColor Red
                $skipped++
            }
        }
    }
    
    # Итоговая сводка
    $summary = "[$timestamp] === INGESTION RUN COMPLETE === Processed: $processed | Skipped: $skipped | Total: $($files.Count)"
    $summary | Tee-Object -FilePath $logPath -Append | Write-Host -ForegroundColor Cyan
}

# === ТОЧКА ВХОДА ===

if ($WatchMode) {
    Write-Host "[WATCHER] Continuous watch mode not implemented yet. Running single pass." -ForegroundColor Yellow
    # TODO: Implement FileSystemWatcher for real-time monitoring
}

Process-TrayFiles

Write-Host "`n[INGESTION] Script complete. Check log: $logPath" -ForegroundColor Cyan
