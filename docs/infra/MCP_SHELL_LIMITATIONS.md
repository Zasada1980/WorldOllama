# MCP Shell Limitations & Workarounds

**Дата:** 03.12.2025  
**Статус:** ✅ ПРИМЕНЕНО (copilot-instructions.md + terminal_timeout_policy.json обновлены)  
**Версия MCP Shell:** v1.3.1 (Phase 2.3)

## 🚨 КРИТИЧЕСКИЕ ОГРАНИЧЕНИЯ

### 1. Отсутствие поддержки `isBackground` параметра

**Проблема:**
- Параметр `isBackground` **НЕ СУЩЕСТВУЕТ** в MCP Shell v1.3.1
- Copilot-instructions.md ошибочно указывал использование этого параметра
- Нет механизма detached process management (`proc.unref()`)

**Проявление:**
```typescript
// ❌ ЭТО НЕ РАБОТАЕТ (параметр игнорируется/вызывает ошибку)
await invoke('mcp_myshell_execute_command', {
    command: "pwsh -File scripts\\START_ALL.ps1",
    isBackground: true  // ← ПАРАМЕТР НЕ СУЩЕСТВУЕТ
});
```

**Решение:**
```typescript
// ✅ ПРАВИЛЬНО: использовать run_in_terminal
await invoke('run_in_terminal', {
    command: "pwsh -File E:\\WORLD_OLLAMA\\scripts\\START_ALL.ps1",
    explanation: "Starting CORTEX and Neuro-Terminal services",
    isBackground: true  // ← ЗДЕСЬ ПОДДЕРЖИВАЕТСЯ
});
```

**Статус:** ✅ ИСПРАВЛЕНО в copilot-instructions.md (строки 108-150)

---

### 2. START_ALL.ps1 — несовместимость с MCP Shell

**Корневая причина:**
```powershell
# scripts/START_ALL.ps1 (строки 166, 200)
Start-Process powershell -ArgumentList "-NoExit", "-Command", $cortexCmd
Start-Process powershell -ArgumentList "-NoExit", "-Command", $neuroCmd
```

**Цепочка проблем:**
1. `Start-Process -NoExit` создаёт 2 фоновых процесса (CORTEX + Neuro-Terminal)
2. Родительский процесс **не завершается** пока дочерние живы
3. MCP Shell ждёт `close` event от родительского процесса
4. **БЕСКОНЕЧНОЕ ЗАВИСАНИЕ** агента

**Решение:**

**Вариант A: Использовать run_in_terminal (РЕКОМЕНДУЕТСЯ)**
```typescript
// Для интерактивного запуска с визуальным прогрессом
await invoke('run_in_terminal', {
    command: "pwsh -File E:\\WORLD_OLLAMA\\scripts\\START_ALL.ps1",
    explanation: "Starting all services (CORTEX + Neuro-Terminal)",
    isBackground: true
});
```

**Вариант B: Запускать сервисы напрямую (для автоматизации)**
```typescript
// 1. Проверить Ollama
const ollamaCheck = await invoke('mcp_myshell_execute_command', {
    command: "ollama list | Select-Object -First 1"
});

// 2. Запустить CORTEX (через run_in_terminal)
await invoke('run_in_terminal', {
    command: "cd E:\\WORLD_OLLAMA\\services\\lightrag; .venv\\Scripts\\Activate.ps1; chainlit run lightrag_server.py -w --port 8004",
    explanation: "Starting CORTEX on port 8004",
    isBackground: true
});

// 3. Проверить доступность (через MCP Shell)
await new Promise(resolve => setTimeout(resolve, 5000));
const cortexCheck = await invoke('mcp_myshell_execute_command', {
    command: "Test-NetConnection -ComputerName localhost -Port 8004 | Select-Object -Property TcpTestSucceeded"
});
```

**Статус:** ✅ ДОКУМЕНТИРОВАНО в copilot-instructions.md (строки 151-165)

---

## ⚠️ СРЕДНИЕ ОГРАНИЧЕНИЯ

### 3. Watchdog убивает процессы через 30s без вывода

**Проблема:**
- `Wait-ForService` использует `Start-Sleep` → нет output
- Watchdog срабатывает через `no_output_timeout_sec: 30`
- Процесс убивается **преждевременно**

**Пример из логов:**
```log
[2025-12-02T18:53:50.081Z] NO_OUTPUT_TIMEOUT cmd=Start-Sleep -Seconds 35 sinceLastMs=30166
[2025-12-02T18:53:55.096Z] FAIL classification=no_output_timeout count=1
```

**Решение:**

**Применено:** Увеличение таймаута в `config/terminal_timeout_policy.json`
```json
{
  "timeouts": {
    "no_output_timeout_sec": 60  // было 30, стало 60
  }
}
```

**Альтернатива:** Добавлять вывод в Wait-ForService
```powershell
function Wait-ForService {
    param([int]$TimeoutSec = 30)
    $elapsed = 0
    while ($elapsed -lt $TimeoutSec) {
        Write-Host "." -NoNewline  # ← Вывод для watchdog
        Start-Sleep -Seconds 5
        $elapsed += 5
    }
}
```

**Статус:** ✅ ИСПРАВЛЕНО в terminal_timeout_policy.json

---

### 4. Отсутствие паттерна "start_all" в long_running_overrides

**Проблема:**
- START_ALL.ps1 классифицируется как "medium" (120s timeout)
- Реальное время запуска: 60-180s (CORTEX + Neuro-Terminal)
- Таймаут недостаточен для гарантированного успеха

**Решение:**

**Применено:** Добавление в `config/terminal_timeout_policy.json`
```json
{
  "long_running_overrides": {
    "start_all": 300  // ← ДОБАВЛЕНО
  }
}
```

**Статус:** ✅ ИСПРАВЛЕНО в terminal_timeout_policy.json

---

## 📋 СПИСОК КОМАНД, ТРЕБУЮЩИХ run_in_terminal

**❌ НИКОГДА не использовать MCP Shell для:**

| Команда | Причина | Решение |
|---------|---------|---------|
| `START_ALL.ps1` | Создаёт detached процессы (`Start-Process -NoExit`) | `run_in_terminal` с `isBackground: true` |
| `WATCH_FILE_CHANGES.ps1` | Бесконечный FileSystemWatcher loop | `run_in_terminal` с `isBackground: true` |
| `chainlit run app.py` | Long-running server (не завершается) | `run_in_terminal` с `isBackground: true` |
| `npm run tauri dev` | Development server с hot reload | `run_in_terminal` с `isBackground: true` |
| `cargo run --release` | Долгая компиляция + запуск | `run_in_terminal` (без isBackground) |
| `.venv\Scripts\Activate.ps1` | Меняет shell state (env vars) | `run_in_terminal` для сохранения сессии |

**✅ МОЖНО использовать MCP Shell для:**

| Категория | Примеры команд | Примечания |
|-----------|----------------|------------|
| Health checks | `Test-NetConnection -Port 8004`, `ollama list`, `nvidia-smi` | Быстрые, детерминированные |
| Git operations | `git status --porcelain`, `git log --oneline -5` | Read-only, <5s |
| File reads | `Get-Content file.txt -Tail 20`, `Test-Path path` | Не меняют состояние |
| Pipelines | `Get-Process \| Where-Object { ... } \| Select-Object` | Base64 encoding защищает |

---

## 🔧 ТЕХНИЧЕСКИЕ ДЕТАЛИ

### Архитектура MCP Shell (v1.3.1)

**Файл:** `mcp-shell/dist/server.js` (467 строк)

**Ключевые функции:**
- `encodeCommandToBase64()` — UTF-16LE encoding (защита от Exit Code 255)
- `getCommandTimeout()` — классификация fast/medium/long
- `execute_command` tool — spawn PowerShell с watchdog
- `recordFailure()` — Circuit Breaker (3 failures → OPEN)

**Отсутствующие функции:**
```typescript
// ❌ НЕ РЕАЛИЗОВАНО в v1.3.1
{
  name: "execute_command",
  inputSchema: {
    properties: {
      command: { type: "string" },
      // isBackground: { type: "boolean" }  ← НЕТ
    }
  }
}

// ❌ НЕТ detached process management
spawn("powershell", args, {
  cwd,
  shell: true
  // detached: true,  ← НЕТ
  // stdio: 'ignore' ← НЕТ
});
// process.unref();  ← НЕТ
```

### Circuit Breaker поведение

**Логика:**
1. **CLOSED** (норма) → 3 последовательных провала → **OPEN**
2. **OPEN** (блокировка) → 5s wait → **HALF_OPEN**
3. **HALF_OPEN** (проба) → успех → **CLOSED**, провал → **OPEN**

**Meta поля в ответе:**
```typescript
{
  meta: {
    breakerState: "CLOSED" | "OPEN" | "HALF_OPEN",
    classification: "fast" | "medium" | "long" | "timeout_exec" | "no_output_timeout" | "exec_error",
    consecutiveFailures: number,
    fallbackSuggested: boolean,  // true если circuit breaker OPEN
    durationMs: number,
    retryAttempt?: number,
    maxRetries?: number,
    errorCode?: number,
    userMessage?: string  // Русское описание ошибки
  }
}
```

**Агент должен:**
1. Проверять `meta.fallbackSuggested === true`
2. При OPEN → переключаться на `run_in_terminal`
3. Проверять `myshell/health_check` перед возобновлением

---

## 📊 СТАТУС ПРИМЕНЕНИЯ

| Файл | Изменение | Статус | Дата |
|------|-----------|--------|------|
| `.github/copilot-instructions.md` | Удалена ошибочная инструкция про `isBackground` | ✅ ПРИМЕНЕНО | 03.12.2025 |
| `.github/copilot-instructions.md` | Добавлен раздел "CRITICAL MCP Shell Limitations" | ✅ ПРИМЕНЕНО | 03.12.2025 |
| `.github/copilot-instructions.md` | Добавлен список команд для `run_in_terminal` | ✅ ПРИМЕНЕНО | 03.12.2025 |
| `config/terminal_timeout_policy.json` | `no_output_timeout_sec: 30 → 60` | ✅ ПРИМЕНЕНО | 03.12.2025 |
| `config/terminal_timeout_policy.json` | Добавлен `"start_all": 300` | ✅ ПРИМЕНЕНО | 03.12.2025 |
| `docs/infra/MCP_SHELL_LIMITATIONS.md` | Создана полная документация | ✅ СОЗДАНО | 03.12.2025 |

---

## 🎯 ДОЛГОСРОЧНЫЕ ЗАДАЧИ

### Опционально: Патч MCP Shell v1.4.0

**Добавить поддержку `isBackground`:**

```typescript
// mcp-shell/dist/server.js (новый код)
{
  name: "execute_command",
  inputSchema: {
    properties: {
      command: { type: "string" },
      isBackground: { 
        type: "boolean",
        description: "Run as detached process (won't wait for completion)"
      }
    }
  }
}

// В execute_command handler
if (params.isBackground) {
  const proc = spawn("powershell", args, {
    detached: true,
    stdio: 'ignore',
    cwd
  });
  proc.unref();
  
  return {
    content: [{
      type: "text",
      text: JSON.stringify({
        stdout: `Background process started (PID: ${proc.pid})`,
        stderr: "",
        exitCode: 0,
        meta: { 
          classification: "background_start",
          processId: proc.pid,
          durationMs: 10
        }
      })
    }]
  };
}
```

**Приоритет:** LOW (workaround через `run_in_terminal` работает)

### Опционально: Рефакторинг START_ALL.ps1

**Убрать `-NoExit` для совместимости с MCP:**

```powershell
# Вместо:
Start-Process powershell -ArgumentList "-NoExit", "-Command", $cortexCmd

# Использовать:
Start-Job -ScriptBlock { 
    cd E:\WORLD_OLLAMA\services\lightrag
    .venv\Scripts\Activate.ps1
    chainlit run lightrag_server.py -w --port 8004
}

# Или запускать напрямую без Start-Process
& "E:\WORLD_OLLAMA\services\lightrag\.venv\Scripts\chainlit.exe" run lightrag_server.py -w --port 8004 &
```

**Приоритет:** MEDIUM (повысит совместимость, но workaround достаточен)

---

## 📚 ССЫЛКИ

- **Основной анализ:** `ANALYSIS_START_ALL_HANGING.md` (483 строки)
- **Инструкции агента:** `.github/copilot-instructions.md` (строки 105-165)
- **MCP Shell source:** `mcp-shell/dist/server.js`
- **Timeout policy:** `config/terminal_timeout_policy.json`
- **Логи:** `logs/mcp/mcp-events.log`

---

## ✅ ИТОГОВЫЕ РЕКОМЕНДАЦИИ

**Для агента консоли:**

1. **ВСЕГДА проверяйте тип команды:**
   - Background process (START_ALL, WATCH, servers) → `run_in_terminal` с `isBackground: true`
   - Короткая команда (git status, health check) → `mcp_myshell_execute_command`

2. **НИКОГДА не используйте MCP Shell для:**
   - Команд с `Start-Process -NoExit`
   - Бесконечных циклов (`while ($true)`, FileSystemWatcher)
   - Development servers (`npm run dev`, `chainlit run`)

3. **Мониторьте `meta.fallbackSuggested`:**
   - `true` → переключайтесь на `run_in_terminal`
   - Проверяйте `myshell/health_check` перед возобновлением

4. **Используйте правильные timeout'ы:**
   - Fast commands: <60s (git, health checks)
   - Medium commands: 60-120s (pwsh scripts)
   - Long commands: 120-900s (npm install, cargo build)

**Для разработчиков:**

1. ✅ **ПРИМЕНЕНО:** Документация обновлена
2. ✅ **ПРИМЕНЕНО:** Timeout policy настроена
3. ⏸️ **ОПЦИОНАЛЬНО:** Патч MCP Shell v1.4.0 (добавить `isBackground`)
4. ⏸️ **ОПЦИОНАЛЬНО:** Рефакторинг START_ALL.ps1 (убрать `-NoExit`)

---

**Дата последнего обновления:** 03.12.2025 20:15  
**Статус:** ✅ ГОТОВО К ИСПОЛЬЗОВАНИЮ
