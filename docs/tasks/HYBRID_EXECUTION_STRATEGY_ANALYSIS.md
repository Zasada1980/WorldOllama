# 🔄 HYBRID EXECUTION STRATEGY ANALYSIS

**Дата:** 02.12.2025  
**Версия:** 1.0  
**Статус:** Analysis Complete

---

## 🎯 EXECUTIVE SUMMARY

**Стратегия:** Гибридное использование двух инструментов выполнения команд агентом

| Инструмент | Назначение | Преимущества | Ограничения |
|-----------|------------|--------------|-------------|
| **`myshell/execute_command`** (MCP) | Тесты, задачи, валидация | Изолированный процесс, structured output (JSON) | Нет интерактивности, MCP overhead |
| **`run_in_terminal`** (VS Code) | Презентации, демо, отладка | Визуальный output, интерактивность, background процессы | Зависит от активного терминала |

**Результат:** Оптимальное разделение ответственности, минимизация рисков, максимальная эффективность.

---

## 📊 МАТРИЦА ПРИНЯТИЯ РЕШЕНИЙ

### Используй `myshell/execute_command` (MCP) когда:

✅ **Automated Testing & Validation**
```powershell
# ✅ CORRECT - MCP для автоматизации
myshell/execute_command: "cargo check"
myshell/execute_command: "npm run check"
myshell/execute_command: "Get-Command script.ps1"
```

**Причина:**
- Нужен **structured JSON output** (`exitCode`, `stdout`, `stderr`)
- Требуется **изоляция процесса** (не влияет на терминал пользователя)
- Результат используется для **автоматического анализа** (parsing)

✅ **Health Checks & Status Validation**
```powershell
# ✅ CORRECT - MCP для проверок статуса
myshell/execute_command: "Test-NetConnection localhost -Port 8004"
myshell/execute_command: "Get-Process python | Where-Object {$_.CommandLine -like '*lightrag*'}"
```

**Причина:**
- Результат нужен агенту для **логического ветвления**
- Агент принимает решения на основе `exitCode`
- Не требуется визуальное представление для пользователя

✅ **Quick Information Retrieval**
```powershell
# ✅ CORRECT - MCP для быстрых запросов
myshell/execute_command: "Get-Content file.json | ConvertFrom-Json | Select-Object version"
myshell/execute_command: "git status --porcelain"
```

**Причина:**
- Одноразовая команда с **моментальным результатом**
- Output используется в коде агента
- Классифицируется как "fast" в `terminal_timeout_policy.json` (<60s)

---

### Используй `run_in_terminal` (VS Code) когда:

✅ **Presentation & Demonstration**
```powershell
# ✅ CORRECT - Terminal для демонстрации
run_in_terminal: "pwsh scripts/START_ALL.ps1"
run_in_terminal: "npm run tauri dev"
run_in_terminal: "nvidia-smi --query-gpu=memory.used --format=csv"
```

**Причина:**
- Пользователь должен **видеть output в реальном времени**
- Команда демонстрирует **визуальный прогресс** (progress bars, colors)
- Результат предназначен для **человека**, не для парсинга агентом

✅ **Background Processes**
```powershell
# ✅ CORRECT - Terminal для фоновых процессов
run_in_terminal(isBackground=true): "pwsh scripts/start_lightrag.ps1"
run_in_terminal(isBackground=true): "npm run dev"
```

**Причина:**
- Процесс должен **продолжать работу** после завершения команды
- Пользователь может **вернуться к терминалу** для мониторинга
- VS Code управляет **lifecycle** процесса (может убить через UI)

✅ **Interactive Debugging**
```powershell
# ✅ CORRECT - Terminal для интерактивности
run_in_terminal: "python -m pdb script.py"
run_in_terminal: "cargo run --bin debug_tool"
```

**Причина:**
- Команда требует **пользовательского ввода**
- Отладочный вывод должен быть **цветным** (ANSI colors)
- Пользователь может **взаимодействовать** с процессом

✅ **Long-Running Operations (>2 min)**
```powershell
# ✅ CORRECT - Terminal для длительных операций
run_in_terminal: "cargo build --release"
run_in_terminal: "npm install"
run_in_terminal: "pwsh scripts/train_model.ps1"
```

**Причина:**
- Команда классифицируется как "long" в policy (>120s)
- Пользователь ожидает **визуального прогресса**
- MCP может timeout, терминал — нет (пользователь контролирует)

---

## 🔍 CASE STUDIES (Примеры из TASK 51)

### ✅ Case 1: Health Check (Правильно использован MCP)

**Задача:** Проверить компиляцию Rust кода

**Решение:**
```typescript
// ✅ CORRECT - MCP для валидации
myshell/execute_command({
  command: "cd E:\\WORLD_OLLAMA\\client\\src-tauri && cargo check",
  cwd: "E:/WORLD_OLLAMA"
})
```

**Output:**
```json
{
  "exitCode": 0,
  "stdout": "Checking tauri_fresh v0.1.0...\nwarning: unused imports...\nFinished `dev` profile",
  "stderr": ""
}
```

**Анализ агентом:**
```python
if result['exitCode'] == 0:
    if 'warning:' in result['stdout']:
        status = "⚠️ PASSED with warnings"
        warnings = parse_warnings(result['stdout'])  # Structured parsing
    else:
        status = "✅ PASSED"
else:
    status = "❌ FAILED"
```

**Почему MCP, а не Terminal:**
- Агент **парсит output** для создания отчёта
- Нужен **structured JSON** для логики ветвления
- Пользователь **не смотрит** на вывод cargo в реальном времени

---

### ✅ Case 2: Service Start (Правильно использован Terminal)

**Задача:** Запустить все сервисы (Ollama + CORTEX + Neuro-Terminal)

**Решение:**
```typescript
// ✅ CORRECT - Terminal для демонстрации
run_in_terminal({
  command: "pwsh E:\\WORLD_OLLAMA\\scripts\\START_ALL.ps1",
  explanation: "Запускаю все сервисы проекта",
  isBackground: false  // Показываем output, но не держим процесс
})
```

**Output (визуальный):**
```
🚀 Starting WORLD_OLLAMA Services...
✓ Ollama (11434): Running
✓ CORTEX (8004): Starting...
  ⏳ Waiting for health check...
  ✓ CORTEX: Ready!
○ Neuro-Terminal (8501): Skipped (optional)

✅ All services started successfully!
```

**Почему Terminal, а не MCP:**
- Пользователь **наблюдает прогресс** запуска
- Вывод **форматирован с цветами** (🚀, ✓, ⏳)
- Скрипт может занять **30-60 секунд** (близко к timeout MCP)
- Это **презентационная команда**, не валидационная

---

### ❌ Case 3: Anti-pattern — MCP для презентации

**Задача:** Показать использование GPU

**Неправильно (MCP):**
```typescript
// ❌ WRONG - Пользователь не увидит красивый вывод
myshell/execute_command({
  command: "nvidia-smi"
})
```

**Output (JSON, неудобно читать):**
```json
{
  "exitCode": 0,
  "stdout": "+-----------------------------------------------------------------------------+\n| NVIDIA-SMI 535.104.05   Driver Version: 535.104.05   CUDA Version: 12.2     |\n|-------------------------------+----------------------+----------------------+\n..."
}
```

**Правильно (Terminal):**
```typescript
// ✅ CORRECT - Визуальная таблица в терминале
run_in_terminal({
  command: "nvidia-smi",
  explanation: "Проверяю статус GPU",
  isBackground: false
})
```

**Output (визуальный):**
```
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 535.104.05   Driver Version: 535.104.05   CUDA Version: 12.2     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  NVIDIA GeForce ...  Off  | 00000000:01:00.0 Off |                  N/A |
| 30%   45C    P0    25W / 220W |   8500MiB / 16384MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+
```

---

## 🛡️ БЕЗОПАСНОСТЬ И TIMEOUT POLICY

### MCP `execute_command` — Timeout Limits

**Источник:** `config/terminal_timeout_policy.json`

| Команда | Timeout | Policy Rule |
|---------|---------|-------------|
| `dir`, `ls`, `cat` | 60s | `fast.max_timeout_sec` |
| `cargo check`, `npm run check` | 120s | `medium.max_timeout_sec` |
| `cargo build --release` | 600s | `long_running_overrides.cargo_build` |
| `npm install` | 600s | `long_running_overrides.npm_install` |
| `train_agent` | 900s | `long_running_overrides.train_agent` (MAX) |

**Проблема MCP:**
- MCP не поддерживает **динамические timeout** из policy
- Hardcoded timeout в `server.ts` (нет таймаута = infinite wait)
- Если команда зависает → MCP зависает навсегда

**Решение:**
```typescript
// TODO (v0.3.1): Добавить timeout в MCP server
const TIMEOUT_MS = 120_000; // 2 min default

const timeoutPromise = new Promise((_, reject) => {
    setTimeout(() => reject(new Error('Command timeout')), TIMEOUT_MS);
});

return Promise.race([commandPromise, timeoutPromise]);
```

---

### VS Code `run_in_terminal` — No Timeout

**Преимущество:**
- Пользователь **контролирует** выполнение (может убить через UI)
- Терминал может работать **бесконечно** (e.g., `npm run dev`)
- Нет риска timeout для длительных операций

**Недостаток:**
- Агент **не получает** exitCode автоматически
- Требуется **manual polling** через `get_terminal_output`

---

## 🧪 TESTING STRATEGY

### Unit Tests → MCP

```powershell
# ✅ Automated tests через MCP
myshell/execute_command: "cargo test"
myshell/execute_command: "npm run test"
myshell/execute_command: "pytest tests/"
```

**Причина:** Результат нужен для CI/CD pipeline, не для человека

---

### Integration Tests → Terminal (показываем пользователю)

```powershell
# ✅ E2E tests через Terminal
run_in_terminal: "pwsh client/run_auto_tests.ps1"
run_in_terminal: "pwsh client/test_task4_scenarios.ps1"
```

**Причина:**
- Пользователь видит **progress** тестирования
- Скрипты делают **interactive prompts** (опционально)
- Визуальная обратная связь (✅/❌ для каждого теста)

---

## 📋 DECISION TREE

```
Команда требует выполнения?
│
├─ Результат нужен агенту для анализа?
│  ├─ ДА → Время выполнения < 2 мин?
│  │  ├─ ДА → ✅ MCP (myshell/execute_command)
│  │  └─ НЕТ → ⚠️ Terminal (риск MCP timeout)
│  └─ НЕТ → Команда интерактивная/визуальная?
│     ├─ ДА → ✅ Terminal (run_in_terminal)
│     └─ НЕТ → ✅ MCP (structured output)
│
└─ Команда запускает фоновый процесс?
   ├─ ДА → ✅ Terminal (isBackground=true)
   └─ НЕТ → Пользователь наблюдает выполнение?
      ├─ ДА → ✅ Terminal (presentation)
      └─ НЕТ → ✅ MCP (automation)
```

---

## 🎯 РЕКОМЕНДАЦИИ ДЛЯ АГЕНТА

### Когда использовать MCP `myshell/execute_command`:

1. **Healthchecks & Validation** (TASK 51 use case)
   - `cargo check`, `npm run check`
   - `Get-Command script.ps1`
   - `Test-NetConnection`

2. **Information Retrieval** (для логики агента)
   - `git status --porcelain`
   - `Get-Content config.json | ConvertFrom-Json`
   - `ollama list`

3. **Quick Automated Tests** (<2 min)
   - `cargo test --lib`
   - `npm run lint`
   - `pytest tests/unit/`

---

### Когда использовать Terminal `run_in_terminal`:

1. **Presentation & Demo**
   - `pwsh scripts/START_ALL.ps1`
   - `nvidia-smi`
   - `cargo build --release` (показать прогресс)

2. **Background Services**
   - `npm run tauri dev` (isBackground=true)
   - `pwsh scripts/start_lightrag.ps1` (isBackground=true)

3. **Long Operations** (>2 min)
   - `npm install` (может быть долго)
   - `docker build .`
   - `pwsh scripts/train_model.ps1` (900s timeout)

4. **Interactive/Debugging**
   - `python -m pdb script.py`
   - `cargo run --example interactive`

---

## 🔄 MIGRATION PATH (ORDER 51.7)

### Текущее состояние (02.12.2025):

- ✅ MCP server установлен (`mcp-shell`)
- ✅ VS Code integration готова (`settings.json`)
- ⚠️ Агент использует ТОЛЬКО `run_in_terminal` (legacy)

### План миграции:

**Phase 1 (ORDER 51.7):** Hybrid use начинается
```python
# Healthchecks → MCP
if task_type == "healthcheck":
    use myshell/execute_command

# Presentation → Terminal
elif task_type == "demo" or user_visible:
    use run_in_terminal
```

**Phase 2 (v0.3.1):** Добавить timeout в MCP
```typescript
// mcp-shell/server.ts enhancement
const MAX_TIMEOUT = loadTimeoutPolicy();  // From config/terminal_timeout_policy.json
```

**Phase 3 (v0.4.0):** 100% coverage
- Все automated tasks → MCP
- Все presentation tasks → Terminal
- Документация в `.github/copilot-instructions.md`

---

## 📊 METRICS & SUCCESS CRITERIA

| Метрика | До миграции | После миграции (цель) |
|---------|-------------|------------------------|
| **MCP Usage** | 0% | 60% (automation) |
| **Terminal Usage** | 100% | 40% (presentation) |
| **Timeout Failures** | ~5% (long commands) | <1% (MCP < 2min) |
| **User Experience** | Medium (все в Terminal) | High (hybrid) |

---

## 🔗 СВЯЗАННЫЕ ДОКУМЕНТЫ

- `config/terminal_timeout_policy.json` — Timeout rules
- `docs/Terminal_Safety_Policy.md` — ORDER 33 (enforcement TBD)
- `docs/tasks/TASK_51_HEALTHCHECK_EXECUTION_REPORT.md` — First MCP use case
- `.github/copilot-instructions.md` — Agent guidelines

---

**Статус:** ✅ Analysis Complete  
**Next Steps:** ORDER 51.7 — Implement hybrid strategy in agent prompts  
**Owner:** AI Agent Development Team

