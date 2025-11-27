# ============================================================================
# TASK 5.7: TESTING SETTINGS + AGENT PROFILES
# Тестирование всех сценариев использования настроек
# ============================================================================

Write-Host "`n┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" -ForegroundColor Cyan
Write-Host "┃  TASK 5.7: ТЕСТИРОВАНИЕ SETTINGS + AGENT PROFILES      ┃" -ForegroundColor Green
Write-Host "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛`n" -ForegroundColor Cyan

# ============================================================================
# Сценарий 1: Проверка файла настроек
# ============================================================================
Write-Host "📋 СЦЕНАРИЙ 1: Проверка файла settings.json" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────`n" -ForegroundColor DarkGray

$settingsPath = "$env:APPDATA\tauri_fresh\settings.json"
Write-Host "Путь к файлу настроек:" -ForegroundColor White
Write-Host "  $settingsPath`n" -ForegroundColor Gray

if (Test-Path $settingsPath) {
    Write-Host "✅ Файл настроек существует" -ForegroundColor Green
    Write-Host "`nСодержимое файла:" -ForegroundColor White
    $settings = Get-Content $settingsPath | ConvertFrom-Json
    $settings | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor Cyan
    
    Write-Host "`n📊 Текущие значения:" -ForegroundColor White
    Write-Host "  • Модель Ollama:      $($settings.ollama_model)" -ForegroundColor Gray
    Write-Host "  • Max Tokens:         $($settings.max_tokens)" -ForegroundColor Gray
    Write-Host "  • CORTEX top_k:       $($settings.cortex_top_k)" -ForegroundColor Gray
    Write-Host "  • CORTEX mode:        $($settings.cortex_mode)" -ForegroundColor Gray
    Write-Host "  • Активный профиль:   $($settings.active_agent_profile)" -ForegroundColor Gray
} else {
    Write-Host "⚠️  Файл настроек не найден (будет создан при первом запуске)" -ForegroundColor Yellow
}

Write-Host "`n" -NoNewline

# ============================================================================
# Сценарий 2: Проверка работы сервисов
# ============================================================================
Write-Host "🔌 СЦЕНАРИЙ 2: Проверка сервисов (Ollama + CORTEX)" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────`n" -ForegroundColor DarkGray

# Проверка Ollama
Write-Host "Проверка Ollama (localhost:11434)..." -ForegroundColor White
try {
    $ollamaResponse = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 3
    Write-Host "✅ Ollama работает" -ForegroundColor Green
    Write-Host "   Доступные модели:" -ForegroundColor Gray
    $ollamaResponse.models | Select-Object -First 5 | ForEach-Object {
        Write-Host "     • $($_.name)" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "❌ Ollama не доступен" -ForegroundColor Red
    Write-Host "   Запустите: ollama serve" -ForegroundColor Yellow
}

Write-Host ""

# Проверка CORTEX
Write-Host "Проверка CORTEX (localhost:8004)..." -ForegroundColor White
try {
    $cortexResponse = Invoke-RestMethod -Uri "http://localhost:8004/health" -TimeoutSec 3
    Write-Host "✅ CORTEX работает" -ForegroundColor Green
    Write-Host "   Статус: $($cortexResponse.status)" -ForegroundColor Gray
} catch {
    Write-Host "❌ CORTEX не доступен" -ForegroundColor Red
    Write-Host "   Запустите: pwsh E:\WORLD_OLLAMA\scripts\start_lightrag.ps1" -ForegroundColor Yellow
}

Write-Host "`n" -NoNewline

# ============================================================================
# Сценарий 3: Инструкции по тестированию в UI
# ============================================================================
Write-Host "🧪 СЦЕНАРИЙ 3: Тестирование в интерфейсе" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────`n" -ForegroundColor DarkGray

Write-Host "Запустите приложение:" -ForegroundColor White
Write-Host "  cd E:\WORLD_OLLAMA\client" -ForegroundColor Cyan
Write-Host "  npm run tauri dev`n" -ForegroundColor Cyan

Write-Host "После запуска выполните следующие тесты:`n" -ForegroundColor White

Write-Host "1️⃣  ТЕСТ НАВИГАЦИИ:" -ForegroundColor Yellow
Write-Host "   • Нажмите на вкладку ⚙️ Settings" -ForegroundColor Gray
Write-Host "   • Убедитесь, что панель настроек загрузилась" -ForegroundColor Gray
Write-Host "   • Проверьте, что все 3 секции видны (LLM, CORTEX, Профили)`n" -ForegroundColor Gray

Write-Host "2️⃣  ТЕСТ СМЕНЫ МОДЕЛИ:" -ForegroundColor Yellow
Write-Host "   • В Settings измените модель (например, на qwen2.5:3b-instruct)" -ForegroundColor Gray
Write-Host "   • Нажмите 'Сохранить настройки'" -ForegroundColor Gray
Write-Host "   • Дождитесь сообщения '✅ Настройки сохранены успешно!'" -ForegroundColor Gray
Write-Host "   • Перейдите на вкладку Chat" -ForegroundColor Gray
Write-Host "   • Выберите Backend: Ollama" -ForegroundColor Gray
Write-Host "   • Отправьте вопрос: 'Расскажи о себе'" -ForegroundColor Gray
Write-Host "   • Проверьте в консоли браузера (F12), что используется новая модель`n" -ForegroundColor Gray

Write-Host "3️⃣  ТЕСТ CORTEX ПАРАМЕТРОВ:" -ForegroundColor Yellow
Write-Host "   • В Settings измените top_k (например, с 20 на 10)" -ForegroundColor Gray
Write-Host "   • Измените mode (с local на hybrid)" -ForegroundColor Gray
Write-Host "   • Сохраните настройки" -ForegroundColor Gray
Write-Host "   • Перейдите на Chat, Backend: CORTEX" -ForegroundColor Gray
Write-Host "   • Отправьте вопрос: 'Что такое ТРИЗ?'" -ForegroundColor Gray
Write-Host "   • Проверьте в консоли, что параметры top_k и mode изменились`n" -ForegroundColor Gray

Write-Host "4️⃣  ТЕСТ ПРОФИЛЕЙ АГЕНТА:" -ForegroundColor Yellow
Write-Host "   • В Settings выберите профиль 'ТРИЗ-инженер'" -ForegroundColor Gray
Write-Host "   • Сохраните настройки" -ForegroundColor Gray
Write-Host "   • Затем выберите 'Документалист' и сохраните снова" -ForegroundColor Gray
Write-Host "   • Проверьте в файле $settingsPath," -ForegroundColor Gray
Write-Host "     что поле active_agent_profile меняется`n" -ForegroundColor Gray

Write-Host "5️⃣  ТЕСТ ПЕРСИСТЕНТНОСТИ:" -ForegroundColor Yellow
Write-Host "   • Установите уникальные значения (например, top_k=15, mode=hybrid)" -ForegroundColor Gray
Write-Host "   • Сохраните настройки" -ForegroundColor Gray
Write-Host "   • Закройте приложение (Ctrl+C в терминале npm)" -ForegroundColor Gray
Write-Host "   • Запустите снова: npm run tauri dev" -ForegroundColor Gray
Write-Host "   • Откройте Settings и убедитесь, что значения восстановились" -ForegroundColor Gray
Write-Host "   • Проверьте файл настроек:" -ForegroundColor Gray
Write-Host "     Get-Content $settingsPath | ConvertFrom-Json`n" -ForegroundColor Cyan

Write-Host "`n" -NoNewline

# ============================================================================
# Сценарий 4: Проверка логов
# ============================================================================
Write-Host "📝 СЦЕНАРИЙ 4: Проверка логов в консоли браузера" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────`n" -ForegroundColor DarkGray

Write-Host "Откройте DevTools (F12) и ищите сообщения:" -ForegroundColor White
Write-Host "  • '✅ Настройки загружены в ChatPanel:' - при запуске Chat" -ForegroundColor Gray
Write-Host "  • '✅ Настройки загружены:' - при открытии Settings" -ForegroundColor Gray
Write-Host "  • '✅ Настройки сохранены:' - при нажатии 'Сохранить'`n" -ForegroundColor Gray

Write-Host "Проверьте запросы к Tauri commands:" -ForegroundColor White
Write-Host "  • invoke('get_app_settings') - при монтировании компонентов" -ForegroundColor Gray
Write-Host "  • invoke('save_app_settings', {settings}) - при сохранении" -ForegroundColor Gray
Write-Host "  • invoke('send_ollama_chat', {model: '...'}) - с моделью из настроек" -ForegroundColor Gray
Write-Host "  • invoke('send_cortex_query', {topK: N, mode: '...'}) - с параметрами из настроек`n" -ForegroundColor Gray

Write-Host "`n" -NoNewline

# ============================================================================
# Сценарий 5: Критерии успешного прохождения
# ============================================================================
Write-Host "✅ КРИТЕРИИ УСПЕШНОГО ПРОХОЖДЕНИЯ ВСЕХ ТЕСТОВ:" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────`n" -ForegroundColor DarkGray

$criteria = @(
    "☑ Вкладка ⚙️ Settings появилась в навигации",
    "☑ Панель настроек загружается без ошибок",
    "☑ Файл settings.json создается в %APPDATA%\tauri_fresh\",
    "☑ Можно выбрать модель из dropdown и она сохраняется",
    "☑ Изменение top_k и mode сохраняется корректно",
    "☑ Профили агента переключаются (подсветка карточки)",
    "☑ Кнопка 'Сохранить настройки' работает, показывает success сообщение",
    "☑ ChatPanel использует модель из настроек для Ollama запросов",
    "☑ ChatPanel использует top_k/mode из настроек для CORTEX запросов",
    "☑ После перезапуска приложения настройки восстанавливаются",
    "☑ В консоли браузера видны логи загрузки/сохранения настроек",
    "☑ Нет ошибок компиляции (cargo check, npm build)"
)

foreach ($criterion in $criteria) {
    Write-Host "  $criterion" -ForegroundColor Gray
}

Write-Host "`n" -NoNewline

# ============================================================================
# Финальная информация
# ============================================================================
Write-Host "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" -ForegroundColor Cyan
Write-Host "┃  ГОТОВО К ТЕСТИРОВАНИЮ                                  ┃" -ForegroundColor Green
Write-Host "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛`n" -ForegroundColor Cyan

Write-Host "📌 Следующие шаги:" -ForegroundColor Yellow
Write-Host "  1. Запустите Ollama (если не запущен): ollama serve" -ForegroundColor White
Write-Host "  2. Запустите CORTEX: pwsh E:\WORLD_OLLAMA\scripts\start_lightrag.ps1" -ForegroundColor White
Write-Host "  3. Запустите приложение: cd E:\WORLD_OLLAMA\client && npm run tauri dev" -ForegroundColor White
Write-Host "  4. Выполните все 5 тестовых сценариев выше" -ForegroundColor White
Write-Host "  5. Проверьте все 12 критериев успешности`n" -ForegroundColor White

Write-Host "📊 Для отчета сохраните:" -ForegroundColor Yellow
Write-Host "  • Скриншоты интерфейса (3 вкладки: Chat, Status, Settings)" -ForegroundColor Gray
Write-Host "  • Содержимое settings.json до и после изменений" -ForegroundColor Gray
Write-Host "  • Логи из консоли браузера (F12)" -ForegroundColor Gray
Write-Host "  • Результаты всех 5 сценариев тестирования`n" -ForegroundColor Gray

Write-Host "Удачи в тестировании! 🚀`n" -ForegroundColor Green
