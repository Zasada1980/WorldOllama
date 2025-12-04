# RESEARCH REQUEST: Tauri 2.0 Desktop Client Crash — Windows 11 + WebView2

**Date:** 04.12.2025  
**Project:** WORLD_OLLAMA (Tauri 2.0 + Svelte 5 + Rust)  
**Severity:** CRITICAL BLOCKER  
**Current Version:** Tauri CLI 2.9.4, @tauri-apps/api ^2, Vite 6.0.3

---

## 🎯 ТРЕБУЕМЫЙ РЕЗУЛЬТАТ ИССЛЕДОВАНИЯ

**Агент должен найти и предоставить:**

1. ✅ **Работающее решение** для стабильного запуска Tauri dev server на Windows 11
2. ✅ **Конкретные команды/изменения конфигурации** (step-by-step инструкция)
3. ✅ **Ссылки на GitHub issues/discussions** с подтверждённым решением этой проблемы
4. ✅ **Workaround для Error 1411** (Chrome_WidgetWin_0 window class conflict)
5. ✅ **Альтернативный подход** (если dev mode не работает): как перейти на production build для локальной разработки

**НЕ требуется:**
- ❌ Теоретические объяснения причин
- ❌ Решения для других ОС (только Windows 11)
- ❌ Миграция на другие фреймворки

---

## 📋 ГЛУБОКИЙ АНАЛИЗ ПРОБЛЕМЫ

### Симптомы

**Проблема:** Desktop Client (Tauri 2.0 + Svelte 5) crash при запуске в dev режиме  
**Команда:** `npm run tauri dev` (или `cargo run` в src-tauri/)  
**Результат:** Процесс crashes с exit code 1 через 2-3 секунды после запуска

### Три Независимые Root Causes

#### 1. Error 1411 — Window Class Already Registered
```
Failed to unregister class Chrome_WidgetWin_0. Error = 1411.
```

**Технический контекст:**
- Windows GDI+ API возвращает код 1411 при попытке регистрации класса окна, который уже существует
- Происходит из-за "zombie" процесса WebView2 от предыдущего запуска Tauri
- Процессы `msedgewebview2.exe` (13 инстансов) остаются активными после Ctrl+C в терминале

**Воспроизведение:**
```powershell
# Шаг 1: Запустить Tauri dev
npm run tauri dev

# Шаг 2: Прервать через Ctrl+C

# Шаг 3: Проверить процессы
Get-Process msedgewebview2
# Output: 13 активных процессов (каждый 10-110 MB RAM)

# Шаг 4: Повторный запуск
npm run tauri dev
# Error 1411: Chrome_WidgetWin_0 already registered
```

**Попытки решения (НЕ сработали):**
- ❌ `Stop-Process msedgewebview2 -Force` перед каждым запуском — работает 1-2 раза, потом снова crash
- ❌ Очистка реестра `HKEY_CURRENT_USER\Software\Microsoft\Edge\WebView2`
- ❌ Переустановка WebView2 Runtime

#### 2. STATUS_CONTROL_C_EXIT (0xc000013a)
```
Process terminated with code: 0xc000013a (STATUS_CONTROL_C_EXIT)
```

**Технический контекст:**
- Tauri runtime crashes сразу после инициализации WebView2
- Код 0xc000013a = Windows Native Exception (аварийное завершение процесса)
- Происходит даже БЕЗ пользовательского Ctrl+C (автоматический crash)

**Воспроизведение:**
```powershell
# Шаг 1: Убить все WebView2 процессы
Get-Process msedgewebview2 | Stop-Process -Force

# Шаг 2: Запустить Tauri БЕЗ прерываний
cargo run --no-default-features

# Шаг 3: Наблюдать crash через 2-3 секунды
# Output: 
# Finished `dev` profile [unoptimized + debuginfo] target(s) in 1.02s
# Running `target\debug\tauri_fresh.exe`
# [2 seconds pass]
# Process terminated with code: 0xc000013a
```

**Попытки решения (НЕ сработали):**
- ❌ `cargo run --no-default-features` (минимальная конфигурация)
- ❌ `--release` build — компилируется, но не решает dev mode crash
- ❌ Отключение HMR (hot module reload) в Vite
- ❌ Запуск от имени администратора

#### 3. Port 1420 Conflicts (Secondary Issue)
```
Port 1420 is already in use
```

**Технический контекст:**
- Old Node.js процессы (от Vite dev server) занимают порт 1420 после crash
- Vite конфиг `strictPort: true` → fail если порт занят

**Воспроизведение:**
```powershell
# После crash проверить порт
Get-NetTCPConnection -LocalPort 1420
# OwningProcess: 51656 (node.exe), State: Listen

# Попытка повторного запуска
npm run dev
# Error: Port 1420 is already in use
```

**Попытки решения (ЧАСТИЧНО сработали):**
- ✅ `Stop-Process -Id <PID> -Force` — освобождает порт
- ✅ Автоматический cleanup в retry script
- ❌ НЕ решает основные проблемы #1 и #2

### Текущая Конфигурация

**Tauri Config (tauri.conf.json):**
```json
{
  "$schema": "https://schema.tauri.app/config/2",
  "productName": "WORLD_OLLAMA",
  "version": "0.3.1",
  "identifier": "com.zasada.worldollama",
  "build": {
    "beforeDevCommand": "npm run dev",
    "devUrl": "http://localhost:1420",
    "beforeBuildCommand": "npm run build",
    "frontendDist": "../build"
  },
  "app": {
    "windows": [
      {
        "title": "WORLD_OLLAMA v0.3.1 (Preview Release)",
        "width": 1280,
        "height": 800,
        "minWidth": 1024,
        "minHeight": 768,
        "resizable": true
      }
    ],
    "security": { "csp": null }
  }
}
```

**Vite Config (vite.config.js):**
```javascript
export default defineConfig(async () => ({
  plugins: [sveltekit()],
  clearScreen: false,
  server: {
    port: 1420,
    strictPort: true,  // ← Fail if port occupied
    host: host || false,
    hmr: host ? { protocol: "ws", host, port: 1421 } : undefined,
    watch: { ignored: ["**/src-tauri/**"] }
  }
}));
```

**Package Versions:**
```json
{
  "@tauri-apps/api": "^2",
  "@tauri-apps/cli": "^2",
  "@tauri-apps/plugin-opener": "^2",
  "@sveltejs/kit": "^2.9.0",
  "svelte": "^5.0.0",
  "vite": "^6.0.3"
}
```

**Environment:**
- OS: Windows 11 Pro (64-bit)
- WebView2 Runtime: 10.0.26100.1 ✅ (installed)
- Rust: Latest stable (cargo check → 0 errors)
- Node.js: Active (Vite works independently)

### Верифицированные Факты

**✅ ЧТО РАБОТАЕТ:**
1. Vite dev server запускается отдельно: `npm run dev` → http://localhost:1420 (OK)
2. Rust компиляция успешна: `cargo check` → exit code 0 (10 warnings, 0 errors)
3. Production build компилируется: `cargo build --release` → executable создаётся
4. Backend сервисы работают: Ollama (port 11434) + CORTEX (port 8004) ✅
5. WebView2 Runtime установлен: `Get-AppxPackage *WebView*` → Version 10.0.26100.1

**❌ ЧТО НЕ РАБОТАЕТ:**
1. `npm run tauri dev` → STATUS_CONTROL_C_EXIT + Error 1411
2. `cargo run` (в src-tauri/) → тот же crash
3. Повторный запуск после Ctrl+C → zombie msedgewebview2 процессы
4. PowerShell Jobs + npm → networking bug (localhost resolves to 13.107.4.52)

### Попытки Решения (Хронология)

**Попытка 1: Manual Vite + Tauri Separation**
```powershell
# Terminal 1
npm run dev  # Vite starts OK

# Terminal 2
cargo run  # Tauri crashes with Error 1411
```
**Результат:** ❌ FAIL (Error 1411 + STATUS_CONTROL_C_EXIT)

**Попытка 2: Process Cleanup Before Each Run**
```powershell
Get-Process tauri*, msedgewebview2, node | Stop-Process -Force
npm run tauri dev
```
**Результат:** ❌ FAIL (работает 1-2 раза, потом снова crash)

**Попытка 3: PowerShell Jobs for Isolation**
```powershell
$viteJob = Start-Job { Set-Location E:\WORLD_OLLAMA\client; npm run dev }
Start-Sleep -Seconds 5
cargo run
```
**Результат:** ❌ FAIL (Jobs resolves localhost to 13.107.4.52, Vite timeout)

**Попытка 4: Comprehensive Retry Script**
- Создан `START_DESKTOP_CLIENT_WITH_RETRY.ps1` (280 строк)
- Features: WebView2 check, process cleanup, timeouts, health checks
- **Результат:** ❌ FAIL (PowerShell Jobs networking bug)

**Попытка 5: Production Build as Workaround**
```powershell
npm run tauri build
# Executable: client\src-tauri\target\release\tauri_fresh.exe
```
**Результат:** ⏸️ UNTESTED (не подходит для dev workflow с HMR)

---

## 💡 КРАТКОЕ ОПИСАНИЕ ПРОБЛЕМЫ

**Проблема:** Tauri 2.0 Desktop Client crashes на Windows 11 при запуске в dev режиме

**Корневые причины:**
1. **Error 1411:** Zombie WebView2 процессы не освобождают window class `Chrome_WidgetWin_0`
2. **STATUS_CONTROL_C_EXIT:** Tauri runtime crashes сразу после инициализации WebView2 (без пользовательского прерывания)
3. **Port 1420 conflicts:** Old Node.js процессы блокируют Vite dev server

**Контекст:**
- Tauri CLI 2.9.4 (latest stable)
- Windows 11 + WebView2 Runtime 10.0.26100.1
- Vite 6.0.3 + Svelte 5 + @sveltejs/kit 2.9.0
- Backend сервисы работают ✅, только Desktop Client blocked

**Предыдущие попытки:**
- Process cleanup scripts → временное решение (1-2 запуска)
- PowerShell Jobs isolation → networking bug
- Retry logic с timeouts → блокируется теми же root causes

---

## 🔍 ЗАПРОС НА ИССЛЕДОВАНИЕ

**Агенту поручается:**

### Задача 1: Поиск Подтверждённых Решений (PRIORITY: CRITICAL)

Найти GitHub issues/discussions/Stack Overflow где разработчики **успешно решили** аналогичную проблему:

**Ключевые запросы (примеры):**
```
- "Tauri 2.0 Windows Error 1411 Chrome_WidgetWin_0"
- "Tauri STATUS_CONTROL_C_EXIT Windows 11 crash"
- "WebView2 zombie processes Tauri dev mode"
- "Tauri dev server won't start Windows"
- "msedgewebview2.exe not closing Tauri"
```

**Требуемая информация из найденных решений:**
1. ✅ Конкретные изменения в `tauri.conf.json` или `Cargo.toml`
2. ✅ Команды для cleanup/workaround (step-by-step)
3. ✅ Версии Tauri/WebView2/Windows где проблема решена
4. ✅ Ссылки на PRs/commits с фиксами

**Формат результата:**
```markdown
### Solution 1: [Brief Title]
**Source:** [GitHub Issue/PR URL]
**Status:** ✅ Confirmed Working / ⏸️ Partial Fix / ❌ Not Working
**Steps:**
1. [Конкретный шаг]
2. [Конкретный шаг]
...

**Expected Outcome:** [Что должно произойти]
**Tested On:** [OS Version, Tauri Version]
```

### Задача 2: Error 1411 Workaround (PRIORITY: HIGH)

Найти способ **полностью очищать** WebView2 window class между запусками:

**Возможные направления:**
- Registry cleanup команды (`REG DELETE HKEY_*`)
- WinAPI calls для force unregister window class
- Tauri CLI флаги для force cleanup
- WebView2 Runtime reinstallation процедура
- Альтернативные WebView2 modes (например, Fixed Version вместо Evergreen)

**Требуемый результат:**
- ✅ PowerShell скрипт для автоматического cleanup **ДО** каждого `npm run tauri dev`
- ✅ Проверка эффективности (работает ли 10+ последовательных запусков)

### Задача 3: Production Build Workflow (PRIORITY: MEDIUM)

Исследовать возможность использования **production build** для локальной разработки:

**Вопросы для исследования:**
1. Можно ли запустить `tauri_fresh.exe` с live reload (file watcher)?
2. Есть ли Tauri plugin для HMR в production mode?
3. Как настроить Vite для работы с production Tauri executable?

**Требуемый результат:**
- ✅ Альтернативный dev workflow (если dev mode нерешаем)
- ✅ Сравнение производительности (rebuild time, startup time)

### Задача 4: Community Workarounds (PRIORITY: MEDIUM)

Найти временные решения от community:

**Примеры:**
- Custom Tauri build с patches
- Docker container для изоляции WebView2
- WSL2 с X11 forwarding (если Windows native не работает)
- Старые версии Tauri где проблемы нет (regression search)

**Требуемый результат:**
- ✅ Список работающих workarounds с оценкой сложности
- ✅ Trade-offs каждого подхода (что теряем, что получаем)

### Задача 5: Minimal Reproducible Example (PRIORITY: LOW)

Создать **minimal repro** для bug report (если решения не найдены):

**Требования:**
- Fresh Tauri 2.0 project (basic template)
- Воспроизведение Error 1411 на чистой установке Windows 11
- Точные шаги для reproduction

**Цель:** Подготовить quality bug report для Tauri GitHub issues

---

## 📊 EXPECTED OUTPUT FORMAT

**Агент должен предоставить структурированный отчёт:**

```markdown
# RESEARCH RESULTS: Tauri 2.0 Desktop Client Crash Solutions

## Executive Summary
[1-2 абзаца: что найдено, работает ли, recommended solution]

## Solution 1: [Title]
**Status:** ✅ Confirmed / ⏸️ Partial / ❌ Not Working
**Source:** [URL]
**Steps:**
1. ...
2. ...
**Verification:** [Как проверить что работает]

## Solution 2: [Title]
...

## Workarounds (если решения нет)
1. [Workaround with trade-offs]
2. ...

## Recommended Action
[Step-by-step план что делать]

## References
- [GitHub Issue #123]
- [Tauri Discussion #456]
- [Stack Overflow answer]
```

---

## ⚠️ ВАЖНЫЕ ОГРАНИЧЕНИЯ

**Агент ДОЛЖЕН:**
- ✅ Искать ТОЛЬКО **подтверждённые working solutions** (с тестами, PR merged, confirmed by users)
- ✅ Указывать точные версии (Tauri CLI, WebView2, Windows build)
- ✅ Предоставлять step-by-step команды (copy-paste ready)
- ✅ Тестировать найденные решения логически (нет противоречий)

**Агент НЕ ДОЛЖЕН:**
- ❌ Предлагать теоретические решения без подтверждения
- ❌ Копировать generic troubleshooting из документации
- ❌ Рекомендовать миграцию на другой framework
- ❌ Давать решения для macOS/Linux (только Windows 11)

---

## 📎 ДОПОЛНИТЕЛЬНЫЙ КОНТЕКСТ

**Проект:** WORLD_OLLAMA — Local-first AI workstation  
**Stack:** Tauri 2.0 + Svelte 5 + Rust + Ollama + LightRAG  
**Desktop Client роль:** UI для управления обучением моделей, RAG запросов, Git automation  
**Критичность:** BLOCKER для 71% функционала (все UI features blocked)

**Текущий workaround:** Использование backend сервисов через curl/PowerShell (без UI)

**Deadline:** НЕТ (quality важнее скорости, но чем быстрее — тем лучше)

---

## ✅ SUCCESS CRITERIA

**Исследование считается успешным если:**

1. ✅ Найдено **минимум 2 подтверждённых решения** с GitHub issues/discussions
2. ✅ Предоставлены **точные команды** для воспроизведения (step-by-step)
3. ✅ Указаны **ссылки на источники** (verifiable)
4. ✅ Описан **recommended action plan** (что делать сначала, что потом)
5. ✅ Указаны **trade-offs** каждого решения (плюсы/минусы)

**Бонус (опционально):**
- Minimal reproducible example для bug report
- Comparison с альтернативными Tauri configurations
- Regression analysis (когда проблема появилась, в какой версии)

---

**END OF REQUEST**

_Агент, пожалуйста, сфокусируйся на нахождении **working solutions** с подтверждением от community. Теория и объяснения — вторичны. Нужны **конкретные команды и изменения конфигурации**._
