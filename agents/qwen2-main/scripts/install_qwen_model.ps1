param(
    [string]$OllamaHost = "http://127.0.0.1:11434",
    [string]$ModelName = "qwen2.5:14b-instruct-q4_k_m",
    [switch]$CreateContextVariant
)

$ErrorActionPreference = "Stop"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path (Split-Path $scriptRoot) "configs\Modelfile_qwen2_main"

$env:OLLAMA_HOST = $OllamaHost
Write-Host "Using OLLAMA_HOST=$OllamaHost"

Write-Host "Pulling model $ModelName ..."
ollama pull $ModelName

if ($CreateContextVariant) {
    if (-not (Test-Path $configPath)) {
        throw "Modelfile not found: $configPath"
    }

    $variantName = "qwen2.5-4k"
    Write-Host "Creating $variantName from $configPath"
    ollama create $variantName -f $configPath
}
