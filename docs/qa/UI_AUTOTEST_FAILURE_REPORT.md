# UI AUTOTESTS FAILURE ANALYSIS REPORT

**Дата:** 03.12.2025 15:30  
**Версия:** v0.3.1  
**Статус:** ❌ FAILED

---

## 📊 РЕЗУЛЬТАТЫ ТЕСТОВ

| Тест | Статус | Ошибка |
|------|--------|---------|
| ChatPanel | ❌ FAIL | ERR_CONNECTION_REFUSED |
| SystemStatusPanel | ❌ FAIL | ERR_CONNECTION_REFUSED |
| TrainingPanel | ❌ FAIL | ERR_CONNECTION_REFUSED |
| FlowsPanel | ❌ FAIL | ERR_CONNECTION_REFUSED |

**Успешность:** 0/4 (0%)

---

## 🔍 ПРОБЛЕМЫ НАЙДЕНЫ

### 1. 🔴 КРИТИЧНО: Desktop Client не удерживает порт 1420

**Описание:**
- Tauri dev запускается успешно (`npm run tauri dev`)
- Vite поднимается на http://localhost:1420/
- Процесс работает ~15-30 секунд, затем самопроизвольно завершается
- Порт 1420 становится недоступным

**Доказательства:**
```powershell
# Проверка порта ПОСЛЕ запуска
PS> Test-NetConnection -ComputerName localhost -Port 1420
# Result: False (Connection refused)

# Проверка процессов
PS> Get-Process | Where-Object { $_.ProcessName -like "*tauri*" }
# Result: No matching processes
```

**Логи терминала:**
```
VITE v6.4.1  ready in 559 ms
➜  Local:   http://localhost:1420/

# После ~15-30 секунд:
[ERROR:ui\gfx\win\window_impl.cc:124] Failed to unregister class Chrome_WidgetWin_0. Error = 1412
Завершить выполнение пакетного файла [Y(да)/N(нет)]? error: process didn't exit successfully
exit code: 0xc000013a, STATUS_CONTROL_C_EXIT
```

**Причина:**
- `STATUS_CONTROL_C_EXIT` (0xc000013a) = процесс получил сигнал Ctrl+C
- Возможно, фоновый терминал закрывается автоматически
- Возможно, Tauri процесс падает из-за ошибки Chrome widget

---

### 2. 🟡 ВАЖНО: PowerShell Execution Policy блокирует npm/npx

**Описание:**
- При запуске через MCP Shell (`mcp_myshell_execute_command`) npm/npx блокируются
- Ошибка: `UnauthorizedAccess` - выполнение скриптов отключено в системе

**Доказательства:**
```powershell
npm : Невозможно загрузить файл C:\Program Files\nodejs\npm.ps1,
так как выполнение сценариев отключено в этой системе.
CategoryInfo : Ошибка безопасности: (:) [], PSSecurityException
FullyQualifiedErrorId : UnauthorizedAccess
```

**Workaround (временный):**
```powershell
# Работает:
powershell -ExecutionPolicy Bypass -Command "npm run tauri dev"
cmd /c "npx playwright test ..."
```

---

### 3. 🟢 НЕКРИТИЧНО: Warnings в Rust/Svelte

**Rust warnings (4):**
- `unused import: tauri::AppHandle`
- `method calculate_progress is never used`
- `function get_current_timestamp is never used`
- `fields profile and mode are never read`

**Svelte warnings (6):**
- Unused CSS selectors (.message, .error-box, .toggle input[type="checkbox"])
- Self-closing HTML tag `<textarea />` вместо `<textarea></textarea>`

**Статус:** Не блокируют работу, но требуют cleanup

---

## 🎯 РЕКОМЕНДАЦИИ

### 1. Исправить Tauri stability (КРИТИЧНО)

**Проблема:** Процесс Tauri dev завершается через 15-30 секунд

**Решения:**
1. **Вариант A:** Запускать Tauri dev не в фоне, а в отдельном окне PowerShell:
   ```powershell
   Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd E:\WORLD_OLLAMA\client; npm run tauri dev"
   ```

2. **Вариант B:** Использовать production build вместо dev:
   ```powershell
   npm run tauri build
   # Запуск: E:\WORLD_OLLAMA\client\src-tauri\target\release\tauri_fresh.exe
   ```

3. **Вариант C:** Добавить retry-механизм в тесты (ожидание готовности порта):
   ```typescript
   // playwright.config.ts
   use: {
     baseURL: 'http://localhost:1420',
     timeout: 60000, // 60s для готовности
   },
   webServer: {
     command: 'npm run tauri dev',
     url: 'http://localhost:1420',
     timeout: 120 * 1000,
     reuseExistingServer: true,
   }
   ```

---

### 2. Настроить Execution Policy (ВАЖНО)

**Проблема:** npm/npx блокируются из-за Execution Policy

**Решение (постоянное):**
```powershell
# Включить RemoteSigned для текущего пользователя (безопасно)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# Или обойти через RUN_UI_AUTOTESTS.ps1:
powershell -ExecutionPolicy Bypass -File scripts\RUN_UI_AUTOTESTS.ps1
```

---

### 3. Cleanup Warnings (ОПЦИОНАЛЬНО)

**Rust:**
```powershell
cd client\src-tauri
cargo fix --lib -p tauri_fresh
```

**Svelte:**
- Удалить неиспользуемые CSS селекторы
- Исправить `<textarea />` → `<textarea></textarea>`

---

## 📝 СЛЕДУЮЩИЕ ШАГИ

1. ✅ **Сервисы запущены:** Ollama ✅, CORTEX ✅
2. ❌ **Desktop Client:** Требует стабилизации (выбрать Вариант A/B/C)
3. ❌ **UI Тесты:** Заблокированы до исправления п.2

**Приоритет:**
1. 🔴 Исправить Tauri stability (выбрать Вариант B — production build)
2. 🟡 Настроить Execution Policy (RemoteSigned)
3. 🟢 Cleanup warnings (опционально)

---

**Автор:** AI Agent (GitHub Copilot)  
**Методология:** Automated Testing + Manual Debugging  
**Связанные файлы:**
- `scripts/RUN_UI_AUTOTESTS.ps1`
- `client/tests/ui/basic_panels.spec.ts`
- `docs/qa/UI_AUTOTEST_REPORT.md` (шаблон)
