<#
.SYNOPSIS
    Living Map Generator - автоматическая генерация карты проекта WORLD_OLLAMA
.DESCRIPTION
    Реализация TD-005: Система "Living Map" (Принцип 10 ТРИЗ - Предварительное действие)
    
    Принцип работы:
    1. Рекурсивный обход структуры E:\WORLD_OLLAMA
    2. Фильтрация шумовых папок (.git, venv, node_modules, etc.)
    3. Обогащение описаниями из README.md/MANUAL.md (первая строка H1)
    4. Генерация Markdown-дерева в PROJECT_MAP.md (корень проекта)
    
    Цель: Устранение "Контекстной Слепоты" агента
.NOTES
    Версия: 1.0 PRODUCTION (25.11.2025 - TD-005 Deployment)
    Автор: SESA Development Protocol
    Локация: PRODUCTION (E:\WORLD_OLLAMA\scripts\)
    SESA Status: APPROVED & DEPLOYED
.EXAMPLE
    # Стандартный запуск (из корня проекта)
    pwsh .\scripts\generate_map.ps1
    
    # С подробным выводом
    pwsh .\scripts\generate_map.ps1 -Verbose
    
    # С ограничением глубины (для больших проектов)
    pwsh .\scripts\generate_map.ps1 -MaxDepth 4
#>

[CmdletBinding()]
param(
    [string]$RootPath = "E:\WORLD_OLLAMA",
    [string]$OutputPath = "E:\WORLD_OLLAMA\PROJECT_MAP.md",  # PRODUCTION: корень мира
    [int]$MaxDepth = 6,  # Ограничение глубины (было 10, уменьшено до 6)
    [switch]$IncludeLogs,  # По умолчанию логи игнорируем
    [switch]$ShowEmptyFolders  # По умолчанию пустые папки скрываем
)

# === КОНСТАНТЫ ФИЛЬТРАЦИИ (ANTI-NOISE PROTOCOL) ===

$ignoredFolders = @(
    '.git',
    'venv',
    '.venv',  # Добавлено: виртуальное окружение Python
    'node_modules',
    '__pycache__',
    'lightrag_cache',
    '.vscode',
    'tmp',
    'temp',
    '.pytest_cache',
    '.mypy_cache',
    'dist',
    'build',
    'eggs',
    '.eggs',
    'htmlcov',
    'downloads',
    'uploads',
    'cache',
    'assets',  # Обычно много файлов, мало информации
    'static',  # То же самое
    'media',
    'site-packages',  # Добавлено: библиотеки Python
    'blobs',  # Ollama blobs
    'manifests'  # Ollama manifests
)

$ignoredFiles = @(
    '.DS_Store',
    'Thumbs.db',
    'desktop.ini',
    '*.pyc',
    '*.pyo',
    '*.pyd',
    '*.so',
    '*.dll',
    '*.dylib'
)

# Если IncludeLogs не установлен, игнорируем все .log файлы
if (-not $IncludeLogs) {
    $ignoredFiles += '*.log'
}

# === ФУНКЦИИ ОБРАБОТКИ ===

function Get-FolderDescription {
    <#
    .SYNOPSIS
        Извлекает описание папки из README.md или MANUAL.md
    .DESCRIPTION
        Читает первый заголовок H1 (строка начинающаяся с #) из документации
        Возвращает краткое описание для добавления в карту
    #>
    param(
        [string]$FolderPath
    )
    
    $docFiles = @('README.md', 'RAEDME', 'MANUAL.md', 'README.txt')
    
    foreach ($docFile in $docFiles) {
        $docPath = Join-Path $FolderPath $docFile
        
        if (Test-Path $docPath) {
            try {
                # Читаем первые 20 строк для поиска H1
                $lines = Get-Content $docPath -TotalCount 20 -ErrorAction SilentlyContinue
                
                foreach ($line in $lines) {
                    # Ищем заголовок H1 (# Title)
                    if ($line -match '^#\s+(.+)$') {
                        $title = $matches[1].Trim()
                        # Убираем markdown formatting (**, __, etc.)
                        $title = $title -replace '\*\*', '' -replace '__', '' -replace '`', ''
                        return $title
                    }
                }
            }
            catch {
                Write-Verbose "Warning: Could not read $docPath"
            }
        }
    }
    
    return $null
}

function Build-TreeStructure {
    <#
    .SYNOPSIS
        Рекурсивно строит дерево структуры проекта
    .DESCRIPTION
        Обходит директории, фильтрует шум, обогащает описаниями
    #>
    param(
        [string]$Path,
        [int]$Depth = 0,
        [string]$Prefix = ""
    )
    
    # Защита от слишком глубокой рекурсии
    if ($Depth -gt $MaxDepth) {
        return @("$Prefix... (max depth reached)")
    }
    
    $result = @()
    
    try {
        # Получаем содержимое директории
        $items = Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue | 
                 Sort-Object { $_.PSIsContainer }, Name -Descending
        
        if ($null -eq $items) { return $result }
        
        # Разделяем на папки и файлы
        $folders = $items | Where-Object { $_.PSIsContainer }
        $files = $items | Where-Object { -not $_.PSIsContainer }
        
        # === ОБРАБОТКА ПАПОК ===
        foreach ($folder in $folders) {
            # Проверка на игнорируемые папки
            if ($ignoredFolders -contains $folder.Name) {
                Write-Verbose "Skipping ignored folder: $($folder.Name)"
                continue
            }
            
            # Пропускаем пустые папки если флаг ShowEmptyFolders не установлен
            if (-not $ShowEmptyFolders) {
                $hasContent = (Get-ChildItem -Path $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue | 
                               Where-Object { -not $_.PSIsContainer } | 
                               Select-Object -First 1)
                
                if (-not $hasContent) {
                    Write-Verbose "Skipping empty folder: $($folder.Name)"
                    continue
                }
            }
            
            # Получаем описание папки
            $description = Get-FolderDescription -FolderPath $folder.FullName
            
            # Формируем строку для папки
            if ($description) {
                $folderLine = "$Prefix├── $($folder.Name)/ # $description"
            }
            else {
                $folderLine = "$Prefix├── $($folder.Name)/"
            }
            
            $result += $folderLine
            
            # Рекурсивный обход подпапок
            $subItems = Build-TreeStructure -Path $folder.FullName -Depth ($Depth + 1) -Prefix "$Prefix│   "
            $result += $subItems
        }
        
        # === ОБРАБОТКА ФАЙЛОВ ===
        # Показываем только README/MANUAL/ключевые конфиги в корне папок
        $keyFiles = @('README.md', 'RAEDME', 'MANUAL.md', 'config.yaml', 'config.yml', 
                      'package.json', 'requirements.txt', 'setup.py', 'Dockerfile', 
                      'docker-compose.yaml', 'docker-compose.yml', '.env.example')
        
        foreach ($file in $files) {
            # Проверка на игнорируемые файлы
            $shouldIgnore = $false
            foreach ($pattern in $ignoredFiles) {
                if ($file.Name -like $pattern) {
                    $shouldIgnore = $true
                    break
                }
            }
            
            if ($shouldIgnore) {
                Write-Verbose "Skipping ignored file: $($file.Name)"
                continue
            }
            
            # Показываем только ключевые файлы (не все .ps1/.py)
            if ($keyFiles -contains $file.Name) {
                $result += "$Prefix├── $($file.Name)"
            }
        }
        
        # Убираем последний префикс "├──" на "└──" для красоты (опционально)
        # Для простоты оставляем как есть
        
    }
    catch {
        Write-Warning "Error processing ${Path}: $($_.Exception.Message)"
    }
    
    return $result
}

# === ОСНОВНАЯ ЛОГИКА ===

Write-Host "[INFO] Starting Living Map generation..." -ForegroundColor Cyan
Write-Host "[INFO] Root: $RootPath" -ForegroundColor Gray
Write-Host "[INFO] Output: $OutputPath" -ForegroundColor Gray

$startTime = Get-Date

# Проверка существования корневой директории
if (-not (Test-Path $RootPath)) {
    Write-Error "Root path not found: $RootPath"
    exit 1
}

# Создаем директорию для outputs если не существует
$outputDir = Split-Path $OutputPath -Parent
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Write-Verbose "Created output directory: $outputDir"
}

# Генерируем дерево
Write-Host "[INFO] Scanning directory structure..." -ForegroundColor Yellow
$treeLines = Build-TreeStructure -Path $RootPath -Depth 0 -Prefix ""

# Формируем финальный документ
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$mapContent = @"
# WORLD_OLLAMA Project Map

**Generated:** $timestamp  
**Root:** ``$RootPath``  
**Total Lines:** $($treeLines.Count)

---

## 📁 Directory Structure

``````
WORLD_OLLAMA/
$($treeLines -join "`n")
``````

---

## 🛡️ Filtering Rules

**Ignored Folders:**
$($ignoredFolders | ForEach-Object { "- ``$_``" } | Join-String -Separator "`n")

**Ignored Files:**
$($ignoredFiles | ForEach-Object { "- ``$_``" } | Join-String -Separator "`n")

---

**Generated by:** Living Map Generator (TD-005)  
**Script:** ``generate_map.ps1``  
**Version:** 1.0 (SESA3002a Protocol)
"@

# Сохраняем в файл
$mapContent | Out-File -FilePath $OutputPath -Encoding UTF8 -Force

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

# Статистика
$lineCount = $treeLines.Count
$fileSize = (Get-Item $OutputPath).Length

Write-Host "`n[SUCCESS] Map generated successfully!" -ForegroundColor Green
Write-Host "[STATS] Lines: $lineCount | Size: $fileSize bytes | Time: $([math]::Round($duration, 2))s" -ForegroundColor Cyan
Write-Host "[OUTPUT] $OutputPath" -ForegroundColor Gray

# Проверка критериев ИКР
if ($duration -gt 2) {
    Write-Warning "[IKR CHECK] Performance: FAILED (expected <2s, got $([math]::Round($duration, 2))s)"
}
else {
    Write-Host "[IKR CHECK] Performance: PASS (<2s)" -ForegroundColor Green
}

if ($lineCount -gt 400) {
    Write-Warning "[IKR CHECK] Readability: WARNING (>400 lines, might be too verbose)"
}
else {
    Write-Host "[IKR CHECK] Readability: PASS (<400 lines)" -ForegroundColor Green
}

Write-Host "`nMap saved to: $OutputPath" -ForegroundColor Cyan
