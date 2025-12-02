# Generate PROJECT_INDEX_v51.json
# Part of ORDER 51.7

$ErrorActionPreference = "Stop"

$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$root = "E:/WORLD_OLLAMA"

# File type categorization
function Get-FileType {
    param($extension)
    
    switch -Regex ($extension) {
        '\.(rs|ts|js|svelte|py|ps1)$' { return "code" }
        '\.(md|txt)$' { return "doc" }
        '\.(json|yaml|yml|toml|ini)$' { return "config" }
        '\.(png|jpg|svg|ico)$' { return "asset" }
        '\.(ps1|sh|bat|cmd)$' { return "script" }
        default { return "other" }
    }
}

# Language detection
function Get-Language {
    param($extension)
    
    switch -Regex ($extension) {
        '\.rs$' { return "rust" }
        '\.ts$' { return "typescript" }
        '\.js$' { return "javascript" }
        '\.svelte$' { return "svelte" }
        '\.py$' { return "python" }
        '\.ps1$' { return "powershell" }
        '\.md$' { return "markdown" }
        '\.json$' { return "json" }
        '\.yaml$|\.yml$' { return "yaml" }
        '\.toml$' { return "toml" }
        default { return "unknown" }
    }
}

# Tags based on path
function Get-Tags {
    param($relativePath)
    
    $tags = @()
    
    # Subsystem tags
    if ($relativePath -match 'client') { $tags += "ui" }
    if ($relativePath -match 'src-tauri') { $tags += "backend" }
    if ($relativePath -match 'training|llama_factory') { $tags += "training" }
    if ($relativePath -match 'lightrag|cortex') { $tags += "rag" }
    if ($relativePath -match 'flows|automation') { $tags += "flows" }
    if ($relativePath -match 'git_manager|safe_git') { $tags += "git" }
    if ($relativePath -match 'pulse|training_status') { $tags += "pulse" }
    if ($relativePath -match 'models') { $tags += "models" }
    if ($relativePath -match 'docs|documentation') { $tags += "docs" }
    if ($relativePath -match 'scripts') { $tags += "infra" }
    if ($relativePath -match 'UX_SPEC') { $tags += "ux" }
    if ($relativePath -match 'release') { $tags += "release" }
    
    # Component tags
    if ($relativePath -match 'Training|training') { $tags += "training_ui" }
    if ($relativePath -match 'Settings') { $tags += "settings" }
    if ($relativePath -match 'SystemStatus') { $tags += "status" }
    if ($relativePath -match 'Commands') { $tags += "commands" }
    if ($relativePath -match 'Library') { $tags += "library" }
    if ($relativePath -match 'Flows') { $tags += "flows_ui" }
    
    return $tags | Select-Object -Unique
}

# Status detection
function Get-Status {
    param($relativePath)
    
    if ($relativePath -match 'archive|archived|backup') { return "archived" }
    if ($relativePath -match 'workbench|sandbox') { return "experimental" }
    if ($relativePath -match 'OLD|old|legacy') { return "legacy" }
    if ($relativePath -match 'docs/(tasks|models|infrastructure)/.*CONSOLIDATED') { return "active" }
    if ($relativePath -match 'README|PROJECT_MAP|CHANGELOG|PROJECT_STATUS') { return "active" }
    if ($relativePath -match 'client/src') { return "active" }
    if ($relativePath -match 'scripts/(START_ALL|CHECK_STATUS|start_agent_training)\.ps1') { return "active" }
    
    return "active"
}

# Collect files
$files = Get-ChildItem -Path $root -Recurse -File -Exclude @("*.exe", "*.dll", "*.so", "*.dylib") | Where-Object {
    $_.FullName -notmatch '\.(git|vscode|idea)\\' -and
    $_.FullName -notmatch '\\(target|node_modules|dist|build|__pycache__|\.venv|hf_home|llamaboard_cache)\\' -and
    $_.FullName -notmatch '\\\.next\\' -and
    $_.Length -lt 10MB  # Skip huge files
}

$fileList = @()

foreach ($file in $files) {
    $relativePath = $file.FullName.Replace("$root\", "").Replace("\", "/")
    $extension = $file.Extension
    
    $fileList += @{
        path = $relativePath
        type = Get-FileType $extension
        language = Get-Language $extension
        size_bytes = $file.Length
        tags = Get-Tags $relativePath
        status = Get-Status $relativePath
    }
}

# Build index
$index = @{
    version = "v51"
    generated_at = $timestamp
    root = $root
    files = $fileList
    stats = @{
        total_files = $fileList.Count
        by_type = @{}
        by_status = @{}
        by_language = @{}
    }
}

# Calculate stats
$index.stats.by_type = $fileList | Group-Object type | ForEach-Object { @{ $_.Name = $_.Count } } | Measure-Object | Select-Object -First 1
$index.stats.by_status = $fileList | Group-Object status | ForEach-Object { @{ $_.Name = $_.Count } } | Measure-Object | Select-Object -First 1
$index.stats.by_language = $fileList | Group-Object language | ForEach-Object { @{ $_.Name = $_.Count } } | Measure-Object | Select-Object -First 1

# Proper stats calculation
$typeStats = @{}
$fileList | Group-Object type | ForEach-Object { $typeStats[$_.Name] = $_.Count }
$index.stats.by_type = $typeStats

$statusStats = @{}
$fileList | Group-Object status | ForEach-Object { $statusStats[$_.Name] = $_.Count }
$index.stats.by_status = $statusStats

$langStats = @{}
$fileList | Group-Object language | ForEach-Object { $langStats[$_.Name] = $_.Count }
$index.stats.by_language = $langStats

# Write JSON
$outputPath = "$root/docs/project/PROJECT_INDEX_v51.json"
$index | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPath -Encoding UTF8

Write-Host "✅ PROJECT_INDEX_v51.json created" -ForegroundColor Green
Write-Host "   Total files indexed: $($fileList.Count)" -ForegroundColor Cyan
Write-Host "   Location: $outputPath" -ForegroundColor Cyan
