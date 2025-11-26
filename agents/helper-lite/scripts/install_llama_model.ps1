param(
    [string]$OllamaHost = "http://127.0.0.1:11434",
    [string]$ModelName = "llama3.1:8b",
    [switch]$CreateVariant
)

$ErrorActionPreference = "Stop"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path (Split-Path $scriptRoot) "configs\Modelfile_helper_llama3"

$env:OLLAMA_HOST = $OllamaHost
Write-Host "Using OLLAMA_HOST=$OllamaHost"

Write-Host "Pulling model $ModelName ..."
ollama pull $ModelName

if ($CreateVariant) {
    if (-not (Test-Path $configPath)) {
        throw "Modelfile not found: $configPath"
    }

    $variantName = "helper-llama3"
    Write-Host "Creating $variantName from $configPath"
    ollama create $variantName -f $configPath
}
