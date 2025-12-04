# АНАЛИЗ ЗАВИСАНИЯ АГЕНТА ПРИ ВЫПОЛНЕНИИ START_ALL.ps1

**Дата анализа:** 03.12.2025  
**Команда:** `pwsh -File E:\WORLD_OLLAMA\scripts\START_ALL.ps1`  
**Проблема:** Агент зависает при выполнении команды через MCP Shell  
**Статус:** ✅ ПРИЧИНЫ ВЫЯВЛЕНЫ

---

## 🔍 ОБНАРУЖЕННЫЕ ПРОБЛЕМЫ

### ПРОБЛЕМА 1: START_ALL.ps1 запускает фоновые процессы (КРИТИЧНО)

**Место в коде:** `scripts/START_ALL.ps1`, строки 166 и 200

```powershell
# Строка 166 - CORTEX
Start-Process powershell -ArgumentList "-NoExit", "-Command", $cortexCmd -WindowStyle Normal

# Строка 200 - Neuro-Terminal  
Start-Process powershell -ArgumentList "-NoExit", "-Command", $neuroCmd -WindowStyle Normal
```

**Анализ проблемы:**
- `Start-Process` создаёт **новый независимый процесс PowerShell**
- Флаг `-NoExit` держит окно открытым после выполнения
- Родительский процесс (`START_ALL.ps1`) **НЕ ЗАВЕРШАЕТСЯ** пока дочерние процессы живы
- MCP Shell ждёт завершения `START_ALL.ps1` → **ЗАВИСАНИЕ**

**Почему это проблема для MCP:**
1. MCP Shell использует `spawn("powershell", [...])` и ждёт событие `close`
2. `START_ALL.ps1` запускает 2 фоновых процесса (CORTEX + Neuro-Terminal)
3. Процесс `START_ALL.ps1` не завершается пока дочерние процессы живы
4. MCP Shell **висит в ожидании** → агент блокируется

**Тайминги:**
- `Wait-ForService` ждёт до 30s (CORTEX) + 120s (Neuro-Terminal) = **150 секунд**
- После запуска сервисов процесс **не завершается** (ждёт дочерние процессы)
- Итого: **бесконечное ожидание**

---

### ПРОБЛЕМА 2: MCP Shell не поддерживает фоновые команды

**Текущая реализация:** `mcp-shell/dist/server.js`

```javascript
// Строки 217-231: execute_command tool
{
    name: "execute_command",
    description: "Execute a PowerShell command. Adds meta: breakerState, fallbackSuggested.",
    inputSchema: {
        type: "object",
        properties: {
            command: { type: "string", description: "PowerShell command to execute" },
            cwd: { type: "string", description: "Working directory (optional)" },
            useEncodedCommand: { type: "boolean", description: "Force Base64 encoding override." }
        },
        required: ["command"],
    },
}
```

**Отсутствующие параметры:**
- ❌ `isBackground` — нет поддержки фоновых команд
- ❌ `detach` — нет механизма отсоединения процессов
- ❌ `timeout` override — только автоматический расчёт

**Сравнение с инструкциями:**

Из `.github/copilot-instructions.md` (строки 105-115):
```json
{
  "tool": "mcp_myshell_execute_command",
  "parameters": {
    "command": "pwsh -File scripts\\WATCH_FILE_CHANGES.ps1",
    "isBackground": true  // ← НЕ РЕАЛИЗОВАНО в MCP Shell
  }
}
```

**Вывод:** Инструкции агента указывают использовать `isBackground: true`, но **MCP Shell этого не поддерживает**.

---

### ПРОБЛЕМА 3: Таймауты недостаточны для START_ALL.ps1

**Текущие таймауты:** `config/terminal_timeout_policy.json`

```json
{
  "timeouts": {
    "default_exec_timeout_sec": 120,      // 2 минуты
    "max_exec_timeout_sec": 900,          // 15 минут
    "no_output_timeout_sec": 30           // 30 секунд без вывода
  },
  "command_classification": {
    "medium": { 
      "max_timeout_sec": 120, 
      "patterns": ["pwsh", "node", "python"] 
    }
  }
}
```

**Классификация START_ALL.ps1:**
- Команда содержит `pwsh` → **medium** category
- Таймаут: **120 секунд** (2 минуты)

**Фактическое время выполнения:**
1. Ollama check: ~2s
2. CORTEX start + wait: ~30s (Wait-ForService timeout)
3. Neuro-Terminal start + wait: ~120s (Wait-ForService timeout)
4. **Дочерние процессы продолжают работать бесконечно**

**Итого:** Даже если увеличить таймаут до 900s, процесс **не завершится** из-за фоновых процессов.

---

### ПРОБЛЕМА 4: No-output watchdog убивает процесс

**Механизм:** `mcp-shell/dist/server.js`, строки 325-335

```javascript
// P3: No-output watchdog
const noOutputInterval = setInterval(() => {
    const sinceLastOutput = Date.now() - lastOutputTs;
    if (sinceLastOutput > policy.timeouts.no_output_timeout_sec * 1000) {
        noOutputKilled = true;
        clearInterval(noOutputInterval);
        writeMcpLog(`NO_OUTPUT_TIMEOUT cmd=${command.substring(0, 50)} sinceLastMs=${sinceLastOutput}`);
        proc.kill("SIGTERM");
        setTimeout(() => { if (!proc.killed) proc.kill("SIGKILL"); }, 
                   policy.timeouts.hard_kill_timeout_sec * 1000);
    }
}, 1000);
```

**Сценарий убийства процесса:**
1. `START_ALL.ps1` запускает CORTEX → вывод на stderr/stdout
2. `Wait-ForService` ждёт порт 8004 (до 30s)
3. Если за **30 секунд** нет нового вывода → watchdog убивает процесс
4. Процесс прерывается **до завершения** всех шагов

**Проблема:** `Wait-ForService` использует `Start-Sleep` внутри, что не даёт вывода → watchdog срабатывает.

---

## 📊 ЛОГИ MCP SHELL

**Файл:** `logs/mcp/mcp-events.log`

**Последние события:**
```log
[2025-12-02T18:53:50.081Z] NO_OUTPUT_TIMEOUT cmd=Start-Sleep -Seconds 35 sinceLastMs=30166
[2025-12-02T18:53:55.096Z] FAIL classification=no_output_timeout count=1
[2025-12-02T18:54:26.921Z] NO_OUTPUT_TIMEOUT cmd=Start-Sleep -Seconds 200 sinceLastMs=30145
[2025-12-02T18:54:58.649Z] FAIL classification=exec_error count=1
```

**Анализ:**
- ✅ Watchdog работает корректно (убивает зависшие процессы)
- ✅ Circuit breaker срабатывал 3 раза подряд → OPEN state
- ⚠️ `Start-Sleep` вызывает NO_OUTPUT_TIMEOUT (ожидаемо)

**Проблема:** Для `START_ALL.ps1` watchdog **слишком агрессивен** (30s без вывода недостаточно для Wait-ForService).

---

## 🎯 КОРНЕВАЯ ПРИЧИНА ЗАВИСАНИЯ

**Основная причина:**
```
START_ALL.ps1 использует Start-Process с -NoExit
  ↓
Создаются фоновые процессы (CORTEX, Neuro-Terminal)
  ↓
Родительский процесс START_ALL.ps1 не завершается
  ↓
MCP Shell ждёт события 'close' от процесса
  ↓
Ожидание бесконечное → ЗАВИСАНИЕ АГЕНТА
```

**Вторичные факторы:**
1. **No-output watchdog** убивает процесс через 30s без вывода (при Wait-ForService)
2. **Отсутствие isBackground** в MCP Shell (нельзя запустить как фоновую задачу)
3. **Таймауты недостаточны** для полного цикла запуска (150s реально нужно)

---

## 🔧 РЕКОМЕНДАЦИИ ПО ИСПРАВЛЕНИЮ

### РЕШЕНИЕ 1: Добавить параметр isBackground в MCP Shell (РЕКОМЕНДУЕТСЯ)

**Что сделать:**
1. Добавить `isBackground: boolean` в `execute_command` inputSchema
2. Если `isBackground: true` → использовать `spawn(..., { detached: true })`
3. Не ждать события `close`, возвращать сразу с `exitCode: null`

**Изменения в `mcp-shell/dist/server.js`:**
```javascript
// Строка 224: добавить параметр
properties: {
    command: { type: "string", description: "PowerShell command to execute" },
    cwd: { type: "string", description: "Working directory (optional)" },
    useEncodedCommand: { type: "boolean", description: "Force Base64 encoding override." },
    isBackground: { type: "boolean", description: "Run as background process (detached)" }  // NEW
}

// Строка 310: spawn с detached
const proc = spawn("powershell", powershellArgs, {
    cwd: cwd || process.cwd(),
    shell: true,
    detached: isBackground ?? false,  // NEW
    stdio: isBackground ? 'ignore' : 'pipe'  // NEW
});

// Если isBackground - сразу вернуть результат
if (isBackground) {
    proc.unref();
    return {
        content: [{
            type: "text",
            text: JSON.stringify({
                exitCode: null,
                stdout: "",
                stderr: "",
                meta: {
                    breakerState: mcpState.breaker,
                    classification: "background_started",
                    processId: proc.pid,
                    durationMs: 0
                }
            }, null, 2)
        }]
    };
}
```

**Применение:**
```json
{
  "command": "pwsh -File E:\\WORLD_OLLAMA\\scripts\\START_ALL.ps1",
  "isBackground": true
}
```

---

### РЕШЕНИЕ 2: Изменить START_ALL.ps1 для синхронного режима

**Вариант 2.1: Убрать -NoExit (быстрый фикс)**

```powershell
# Было:
Start-Process powershell -ArgumentList "-NoExit", "-Command", $cortexCmd -WindowStyle Normal

# Стало:
Start-Process powershell -ArgumentList "-Command", $cortexCmd -WindowStyle Hidden
```

**Проблема:** Окна сервисов закроются при ошибке → сложнее дебажить.

**Вариант 2.2: Использовать Start-Job вместо Start-Process**

```powershell
# CORTEX через background job
$cortexJob = Start-Job -ScriptBlock {
    cd $using:cortexPath
    & "$using:cortexPath\venv\Scripts\Activate.ps1"
    python lightrag_server.py
}

# Ждать порт без блокирования родительского процесса
Wait-ForService -Name "CORTEX" -Port 8004 -HealthEndpoint "http://localhost:8004/health"
```

**Преимущество:** Процесс `START_ALL.ps1` завершится после запуска всех сервисов.

---

### РЕШЕНИЕ 3: Увеличить no_output_timeout для START_ALL.ps1

**Изменения в `config/terminal_timeout_policy.json`:**

```json
{
  "long_running_overrides": {
    "start_all": 300,        // 5 минут для START_ALL.ps1
    "chainlit": 180          // 3 минуты для chainlit
  },
  "timeouts": {
    "no_output_timeout_sec": 60  // Увеличить с 30 до 60 секунд
  }
}
```

**Проблема:** Не решает корневую проблему (фоновые процессы всё равно не дадут завершиться).

---

### РЕШЕНИЕ 4: Использовать run_in_terminal вместо MCP Shell

**Применение:**
```typescript
// Вместо MCP Shell
const result = await invoke('mcp_myshell_execute_command', {
    command: "pwsh -File scripts\\START_ALL.ps1"
});

// Использовать Tauri run_in_terminal
const result = await invoke('run_in_terminal', {
    command: "pwsh -File E:\\WORLD_OLLAMA\\scripts\\START_ALL.ps1",
    isBackground: true  // Поддерживается в Tauri terminal
});
```

**Преимущество:** `run_in_terminal` поддерживает `isBackground` нативно.

---

## 📋 АУДИТ MCP SHELL

### ✅ Что работает корректно:

1. **Base64 encoding** (Phase 1 v0.4.0)
   - Правильно обнаруживает спецсимволы: `|`, `{}`, `$`, `"`
   - Кодирует в UTF-16LE для `-EncodedCommand`
   - ✅ 94.44% test coverage (17/18 тестов)

2. **Circuit Breaker** (Phase 2)
   - Срабатывает после 3 последовательных ошибок → OPEN
   - Half-open probe после 5s + jitter
   - Логи показывают корректную работу

3. **Watchdog** (Phase 3)
   - Убивает процессы без вывода >30s
   - Soft kill (SIGTERM) + hard kill (SIGKILL) через 5s
   - ✅ Работает как задумано

4. **Retry Logic** (Phase 4)
   - Fast commands: 2 retries × 1s backoff
   - Medium: 1 retry × 5s backoff
   - Только для идемпотентных команд (dir, ls, cat, git status)

5. **Concurrency Limiter** (Phase 5)
   - Max 5 concurrent execute_command
   - Очередь для превышения лимита
   - ✅ Предотвращает перегрузку

6. **Timeout Classification**
   - Fast (<60s): dir, ls, cat
   - Medium (<120s): pwsh, node, python
   - Long (<900s): npm, cargo, docker
   - ✅ `START_ALL.ps1` → medium (120s)

7. **Error Classification**
   - `timeout_exec`, `no_output_timeout`, `exec_error`
   - `spawn_error`, `file_not_found`, `access_denied`
   - UX-friendly `userMessage` на русском

---

### ❌ Что НЕ работает / отсутствует:

1. **isBackground параметр** ❌
   - Не реализован в inputSchema
   - Нельзя запустить фоновые команды (START_ALL.ps1, WATCH_FILE_CHANGES.ps1)
   - Инструкции агента указывают использовать `isBackground: true` → **рассинхрон**

2. **Detached process support** ❌
   - `spawn()` всегда с `detached: false`
   - Нет механизма `proc.unref()` для фоновых задач
   - Родительский процесс всегда ждёт дочерние

3. **Process management** ❌
   - Нет команды `list_background_processes`
   - Нет команды `kill_process(pid)`
   - Невозможно управлять фоновыми задачами

4. **Long-running command overrides** ⚠️
   - `long_running_overrides` существует в policy
   - Но **не применяется** к `START_ALL.ps1` (паттерн "start_all" не матчится)
   - Нужно добавить в policy: `"start_all": 300`

5. **Adaptive timeout** ⚠️
   - Watchdog использует фиксированный `no_output_timeout_sec: 30`
   - Для `Wait-ForService` (внутри START_ALL.ps1) этого мало
   - Нужно 60-90s для Neuro-Terminal запуска

---

## 🚨 КРИТИЧНОСТЬ ПРОБЛЕМ

| Проблема | Критичность | Блокирует | Решение |
|----------|-------------|-----------|---------|
| **START_ALL.ps1 не завершается** | 🔴 CRITICAL | Все фоновые команды | Добавить `isBackground` |
| **isBackground не реализован** | 🔴 CRITICAL | START_ALL, WATCH_FILE_CHANGES | Патч MCP Shell |
| **no_output_timeout слишком мал** | 🟡 MEDIUM | Долгие Wait-ForService | Увеличить до 60s |
| **long_running_overrides не работает** | 🟡 MEDIUM | START_ALL timeout | Добавить паттерн |

---

## 🎯 ИТОГОВЫЕ РЕКОМЕНДАЦИИ

### ДЛЯ НЕМЕДЛЕННОГО РЕШЕНИЯ (WORKAROUND):

**1. Использовать run_in_terminal для START_ALL.ps1:**
```typescript
// НЕ использовать MCP Shell для фоновых команд
await invoke('run_in_terminal', {
    command: "pwsh -File E:\\WORLD_OLLAMA\\scripts\\START_ALL.ps1",
    isBackground: true
});
```

**2. Обновить .github/copilot-instructions.md:**
```markdown
**⚠️ MCP Shell ограничения:**
- ❌ Не поддерживает isBackground (используйте run_in_terminal)
- ❌ Не подходит для START_ALL.ps1, WATCH_FILE_CHANGES.ps1
- ✅ Используйте для: health checks, git operations, quick reads
```

---

### ДЛЯ ДОЛГОСРОЧНОГО РЕШЕНИЯ (ПАТЧ MCP):

**1. Добавить isBackground в MCP Shell:**
- Патч `mcp-shell/src/server.ts` (или `dist/server.js`)
- Поддержка `detached: true` + `proc.unref()`
- Возврат `processId` вместо ожидания завершения

**2. Обновить terminal_timeout_policy.json:**
```json
{
  "long_running_overrides": {
    "start_all": 300,
    "watch_file_changes": 3600,
    "chainlit": 180
  },
  "timeouts": {
    "no_output_timeout_sec": 60  // Увеличить до 60s
  }
}
```

**3. Рефакторинг START_ALL.ps1 (опционально):**
- Использовать `Start-Job` вместо `Start-Process`
- Убрать `-NoExit` для неинтерактивного режима
- Логировать PID фоновых процессов в файл

---

## 📝 ЗАКЛЮЧЕНИЕ

**Корневая причина зависания:** MCP Shell не поддерживает фоновые команды (`isBackground`), а `START_ALL.ps1` создаёт долгоживущие процессы через `Start-Process -NoExit`.

**Быстрое решение:** Использовать `run_in_terminal` вместо MCP Shell для START_ALL.ps1.

**Долгосрочное решение:** Добавить поддержку `isBackground` в MCP Shell + увеличить `no_output_timeout` до 60s.

**MCP Shell аудит:** Инструмент работает корректно для коротких/средних команд, но **не подходит для фоновых процессов** из-за архитектурного ограничения.

---

**Дата:** 03.12.2025 20:00 UTC+2  
**Анализ выполнен:** GitHub Copilot (Claude Sonnet 4.5)  
**Статус:** ✅ ГОТОВ К ПРИМЕНЕНИЮ РЕКОМЕНДАЦИЙ
