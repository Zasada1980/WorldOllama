try {
    $json = Get-Content "E:\WORLD_OLLAMA\client\src-tauri\tauri.conf.json" -Raw | ConvertFrom-Json
    Write-Host "✅ JSON валиден" -ForegroundColor Green
    Write-Host "Версия: $($json.version)" -ForegroundColor Cyan
    Write-Host "Размер окна: $($json.app.windows[0].width)x$($json.app.windows[0].height)" -ForegroundColor Cyan
    exit 0
}
catch {
    Write-Host "❌ JSON невалиден: $_" -ForegroundColor Red
    exit 1
}
