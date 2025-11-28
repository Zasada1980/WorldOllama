
# analyze_workspace.ps1
# Analyzes the WORLD_OLLAMA workspace and generates a summary report.

$rootPath = "E:\WORLD_OLLAMA"
$outputPath = Join-Path $rootPath "WORKSPACE_ANALYSIS.json"

$analysis = @{
    Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Root = $rootPath
    Directories = @()
    Files = @{
        Total = 0
        ByExtension = @{}
    }
    KeyFiles = @{
        Readme = $false
        ProjectMap = $false
        TaskReports = 0
    }
}

# 1. Directory Structure Analysis
Write-Host "Analyzing directory structure..."
$dirs = Get-ChildItem -Path $rootPath -Directory -Recurse | Where-Object { 
    $_.FullName -notmatch "\\.git" -and 
    $_.FullName -notmatch "\\node_modules" -and 
    $_.FullName -notmatch "\\venv" -and
    $_.FullName -notmatch "\\__pycache__"
}

foreach ($dir in $dirs) {
    $relPath = $dir.FullName.Substring($rootPath.Length + 1)
    $analysis.Directories += $relPath
}

# 2. File Analysis
Write-Host "Analyzing files..."
$files = Get-ChildItem -Path $rootPath -File -Recurse | Where-Object { 
    $_.FullName -notmatch "\\.git" -and 
    $_.FullName -notmatch "\\node_modules" -and 
    $_.FullName -notmatch "\\venv" -and
    $_.FullName -notmatch "\\__pycache__"
}

$analysis.Files.Total = $files.Count

foreach ($file in $files) {
    $ext = $file.Extension.ToLower()
    if (-not $analysis.Files.ByExtension.ContainsKey($ext)) {
        $analysis.Files.ByExtension[$ext] = 0
    }
    $analysis.Files.ByExtension[$ext]++
}

# 3. Key File Checks
Write-Host "Checking key files..."
$analysis.KeyFiles.Readme = Test-Path (Join-Path $rootPath "README.md")
$analysis.KeyFiles.ProjectMap = Test-Path (Join-Path $rootPath "PROJECT_MAP.md")
$analysis.KeyFiles.TaskReports = (Get-ChildItem -Path $rootPath -Recurse -Filter "*REPORT.md").Count

# 4. Output
$json = $analysis | ConvertTo-Json -Depth 5
$json | Out-File $outputPath -Encoding utf8

Write-Host "Analysis complete. Report saved to $outputPath"
Write-Host "Total Files: $($analysis.Files.Total)"
Write-Host "Directories: $($analysis.Directories.Count)"
