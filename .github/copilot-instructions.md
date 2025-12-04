````instructions
# AI Agent Quickstart — WORLD_OLLAMA

**Project Type:** Local-first AI stack — Tauri/Svelte desktop client + LightRAG GraphRAG + Ollama + LLaMA Factory fine-tuning  
**Target Platform:** Windows 11, RTX GPU (16GB VRAM), PowerShell-first automation  
**Current Version:** v0.3.1 (Preview Release) — Flows automation + bugfix pack  
**Release Date:** 02.12.2025  
**GitHub:** https://github.com/Zasada1980/WorldOllama

## 🎯 First Steps for AI Agents

**BEFORE starting any task:**
1. Check `PROJECT_STATUS_SNAPSHOT_v4.0.md` for current phase (v0.3.1), known blockers (ORDER 43)
2. Review relevant consolidated report: `docs/tasks/TASKS_CONSOLIDATED_REPORT.md` (UI), `docs/models/MODELS_CONSOLIDATED_REPORT.md` (training), or `docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md` (services)
3. Verify project root is accessible: Use `get_project_root()` (Rust), `WORLD_OLLAMA_ROOT` env var (Python), `$PSScriptRoot` (PowerShell)

**Quick health check (development):**
```powershell
# Verify all services (use MCP Shell recommended)
pwsh scripts/CHECK_STATUS.ps1 -Detailed
# Expected: Ollama UP, CORTEX UP, GPU visible
```

## 🚨 ABSOLUTE RULE: DESKTOP CLIENT FIRST

**ВСЯ РАБОТА ДОЛЖНА ВЫПОЛНЯТЬСЯ ТОЛЬКО ЧЕРЕЗ DESKTOP CLIENT UI.**

---

### ⛔ КРИТИЧНОЕ ПРАВИЛО: UI-FIRST WORKFLOW

**Агент ОБЯЗАН использовать Desktop Client (http://localhost:1420) для ВСЕХ операций:**

1. ❌ **ЗАПРЕЩЕНО** давать команды для ручного выполнения в терминале
2. ❌ **ЗАПРЕЩЕНО** инструктировать пользователя "выполните команду X"
3. ✅ **ОБЯЗАТЕЛЬНО** использовать Desktop Client UI для всех задач

---

### 📋 Таблица UI-First операций:

| Задача | ❌ ЗАПРЕЩЕНО | ✅ ОБЯЗАТЕЛЬНО |
|--------|--------------|----------------|
| **Обучение модели** | `pwsh start_agent_training.ps1` | TrainingPanel → Select profile → Start Training |
| **Проверка статуса** | `pwsh CHECK_STATUS.ps1` | SystemStatusPanel → View Services |
| **Git операции** | `git status`, `git push` | GitPanel → Plan Push → Execute |
| **Запуск команд** | `pwsh scripts/*.ps1` | CommandsPanel → Select command → Execute |
| **Настройки** | Редактирование конфигов | SettingsPanel → Adjust settings → Save |
| **Flows автоматизация** | Ручной запуск скриптов | FlowsPanel → Select flow → Run |
| **Просмотр библиотеки** | `Get-ChildItem library/` | LibraryPanel → Browse files |

---

### 🎯 Desktop Client адрес:

**URL:** http://localhost:1420

**Панели (7):**
1. **SystemStatusPanel** - статус сервисов (Ollama, CORTEX, GPU)
2. **SettingsPanel** - настройки проекта
3. **LibraryPanel** - просмотр файлов библиотеки
4. **CommandsPanel** - выполнение команд через Command DSL
5. **TrainingPanel** - запуск обучения моделей (LLaMA Factory)
6. **GitPanel** - Git операции с Safe Git Assistant
7. **FlowsPanel** - автоматизация через JSON flows

---

### ⚠️ ИСКЛЮЧЕНИЯ (когда можно использовать терминал):

**Только для внутренних операций агента (НЕ для пользователя):**
- ✅ Проверка статуса процессов: `Get-Process tauri_fresh`
- ✅ Проверка портов: `Test-NetConnection -Port 1420`
- ✅ Чтение логов: `Get-Content logs/*.log -Tail 20`
- ✅ Запуск тестов: `runTests({ files: [...] })`

**ВСЕ остальные операции → Desktop Client UI**

---

### Enforcement:

- **Агент НЕ ИМЕЕТ ПРАВА давать пользователю терминальные команды**
- **Агент ОБЯЗАН направлять пользователя в Desktop Client UI**
- **Агент может использовать терминал только для внутренних проверок**
- **Принцип: "UI-First Workflow" вместо "Terminal-First"**

---

### 📋 ЧЕКЛИСТ ЗАВИСИМЫХ СЕРВИСОВ (для обучения моделей):

**ПЕРЕД запуском обучения через TrainingPanel агент ОБЯЗАН проверить:**

1. ✅ **Ollama доступен:**
   ```typescript
   const ollamaPort = await run_in_terminal({ 
       command: "Test-NetConnection -Port 11434 -InformationLevel Quiet" 
   });
   if (ollamaPort.stdout.trim() !== "True") {
       throw new Error("❌ Ollama not accessible (port 11434 closed)");
   }
   ```

2. ✅ **Модель доступна:**
   ```typescript
   const modelCheck = await run_in_terminal({ 
       command: "ollama list | Select-String 'qwen2.5:7b'" 
   });
   if (modelCheck.exitCode !== 0 || !modelCheck.stdout.includes('qwen2.5')) {
       // Проверить альтернативы (см. ТАБЛИЦА АЛЬТЕРНАТИВ)
       console.log("⚠️ qwen2.5:7b not found, checking alternatives...");
   }
   ```

3. ✅ **GPU доступен (опционально):**
   ```typescript
   const gpuCheck = await run_in_terminal({ 
       command: "nvidia-smi --query-gpu=memory.free --format=csv,noheader" 
   });
   if (gpuCheck.exitCode === 0) {
       console.log("✅ GPU available for training");
   }
   ```

**ЕСЛИ хотя бы один сервис недоступен → сообщить пользователю ДО инструкции по обучению**

## 🚨 ABSOLUTE RULE: PRODUCTION READY VERIFICATION

**Агент НЕ ИМЕЕТ ПРАВА заявлять "🟢 PRODUCTION READY" без ПОЛНОГО чек-листа.**

---

### 📋 ОБЯЗАТЕЛЬНЫЙ ЧЕК-ЛИСТ (ВСЕ ПУНКТЫ)

#### 1. Компиляция и Сборка
- ✅ `cargo check` → exitCode === 0, 0 compilation errors
- ✅ `cargo build --release` → exitCode === 0
- ✅ Release executable: файл существует и размер >5 MB

#### 2. Автоматизированные Тесты
- ✅ `runTests({ files: ["client/run_auto_tests.ps1"] })` → все passed
- ✅ `runTests({ files: ["client/test_stage1_automation.ps1"] })` → все passed
- ✅ `runTests({ files: ["client/test_stage2_e2e.ps1"] })` → все passed
- ⚠️ **ВАЖНО:** Использовать `runTests` tool, НЕ `run_in_terminal` (см. директиву runTests ниже)

#### 3. Desktop Client RUNTIME (КРИТИЧНО)
**См. 🚨 ABSOLUTE RULE: RUNTIME STABILITY (line 354) для деталей**

- ✅ **Выполнить 4 шага Runtime Стабильности:**
  1. Запустить: `npm run tauri dev` (isBackground: true)
  2. ЖДАТЬ: 10 секунд (стабилизация)
  3. Проверить процесс: `Get-Process tauri_fresh` → найден
  4. Проверить порт: `Test-NetConnection -Port 1420` → True
- ✅ **Проверить UI доступен:** `Invoke-RestMethod http://localhost:1420` → 200 OK
- ✅ **Проверить логи:** нет "error" в последних 20 строках

#### 4. Сервисы (КРИТИЧНО)
- ✅ **Ollama:**
  - Порт 11434 доступен: `Test-NetConnection -Port 11434` → True
  - API работает: `ollama list` → exitCode === 0
  - Модели доступны: минимум 1 модель в списке
- ✅ **CORTEX (LightRAG):**
  - Порт 8004 доступен: `Test-NetConnection -Port 8004` → True
  - API работает: `Invoke-RestMethod http://localhost:8004/health` → "healthy"
- ⚠️ **Neuro-Terminal (опционально):**
  - Если запущен: порт 8000 доступен

#### 5. GPU Телеметрия (для систем с GPU)
- ✅ `nvidia-smi --query-gpu=memory.used --format=csv,noheader` → >6 GB (embeddings загружены)
- ✅ GPU доступен для Ollama

#### 6. Exit Codes (КРИТИЧНО)
- ✅ **ВСЕ команды вернули exitCode === 0** (см. директиву Exit Code ниже)
- ❌ **ЕСЛИ хотя бы ОДНА команда exitCode !== 0 → NOT PRODUCTION READY**

---

### ⛔ AUTOMATIC FAILURE CONDITIONS:

**АВТОМАТИЧЕСКОЕ ПРЕРЫВАНИЕ ВЫПОЛНЕНИЯ ПРИ:**

1. ⛔ Агент заявляет "🟢 PRODUCTION READY" без ПОЛНОГО чек-листа → STOP EXECUTION
2. ⛔ Агент пропускает хотя бы ОДИН пункт чек-листа → STOP EXECUTION
3. ⛔ Агент игнорирует exitCode !== 0 в любой команде → STOP EXECUTION

**ДЕЙСТВИЕ:** STOP EXECUTION → Report to user → "Cannot verify production readiness without complete checklist"

**Принцип:** "Comprehensive Verification" (полная верификация) вместо "Partial Check" (частичная проверка)

**ЕСЛИ хотя бы ОДИН пункт ❌ → "NOT PRODUCTION READY"**

## ⚠️ ОБЯЗАТЕЛЬНАЯ ДИРЕКТИВА: Проверка Портов для Всех Сервисов

**ДЛЯ ВСЕХ СЕРВИСОВ агент ОБЯЗАН проверять доступность портов:**

---

### 📋 Таблица портов проекта WORLD_OLLAMA

| Сервис | Порт | Процесс | Команда проверки |
|--------|------|---------|------------------|
| **Desktop Client** | 1420 | tauri_fresh, node | `Test-NetConnection -Port 1420 -InformationLevel Quiet` |
| **Ollama** | 11434 | ollama | `Test-NetConnection -Port 11434 -InformationLevel Quiet` |
| **CORTEX (LightRAG)** | 8004 | python | `Test-NetConnection -Port 8004 -InformationLevel Quiet` |
| **Neuro-Terminal** | 8000 | chainlit | `Test-NetConnection -Port 8000 -InformationLevel Quiet` |

---

### ✅ Обязательный код для проверки портов:

```typescript
// Функция проверки одного порта
async function checkPort(port: number, serviceName: string): Promise<void> {
    const result = await run_in_terminal({ 
        command: `Test-NetConnection -ComputerName localhost -Port ${port} -InformationLevel Quiet` 
    });

    if (result.stdout.trim() !== "True") {
        throw new Error(`❌ ${serviceName} not accessible (port ${port} closed)`);
    }

    console.log(`✅ ${serviceName} accessible on port ${port}`);
}

// Проверка всех критичных портов
async function checkAllPorts(): Promise<void> {
    await checkPort(1420, "Desktop Client");
    await checkPort(11434, "Ollama");
    await checkPort(8004, "CORTEX");
    // Neuro-Terminal опционально (может быть выключен)
}
```

---

### Примеры применения:

#### Пример 1: Проверка Desktop Client
```typescript
// После запуска Desktop Client (см. директиву Runtime Стабильность):
await new Promise(resolve => setTimeout(resolve, 10000)); // 10s

const portCheck = await run_in_terminal({ 
    command: "Test-NetConnection -Port 1420 -InformationLevel Quiet" 
});

if (portCheck.exitCode !== 0 || portCheck.stdout.trim() !== "True") {
    throw new Error("❌ Desktop Client UI not accessible (port 1420 closed, exit code: " + portCheck.exitCode + ")");
}

console.log("✅ SUCCESS: Desktop Client UI accessible on http://localhost:1420 (exit code 0)");
```

#### Пример 2: Проверка Ollama
```typescript
const ollamaPortCheck = await run_in_terminal({ 
    command: "Test-NetConnection -Port 11434 -InformationLevel Quiet" 
});

if (ollamaPortCheck.stdout.trim() !== "True") {
    throw new Error("❌ Ollama not accessible (port 11434 closed)");
}

// Дополнительная проверка API
const ollamaApiCheck = await run_in_terminal({ command: "ollama list" });
if (ollamaApiCheck.exitCode !== 0) {
    throw new Error("❌ Ollama API not responding");
}

console.log("✅ Ollama running on http://localhost:11434");
```

#### Пример 3: Проверка CORTEX
```typescript
const cortexPortCheck = await run_in_terminal({ 
    command: "Test-NetConnection -Port 8004 -InformationLevel Quiet" 
});

if (cortexPortCheck.exitCode !== 0 || cortexPortCheck.stdout.trim() !== "True") {
    throw new Error("❌ CORTEX not accessible (port 8004 closed, exit code: " + cortexPortCheck.exitCode + ")");
}

// Дополнительная проверка health endpoint
const healthCheck = await run_in_terminal({ 
    command: "Invoke-RestMethod -Uri http://localhost:8004/health -TimeoutSec 3" 
});

if (healthCheck.exitCode !== 0 || !healthCheck.stdout.includes("healthy")) {
    throw new Error("❌ CORTEX health check failed (exit code: " + healthCheck.exitCode + ")");
}

console.log("✅ SUCCESS: CORTEX running on http://localhost:8004 (exit code 0)");
```

#### Пример 4: Проверка ВСЕХ критичных портов СРАЗУ (для обучения)
```typescript
// Функция для проверки всех сервисов перед обучением
async function checkAllServicesForTraining(): Promise<void> {
    // 1. Desktop Client
    const port1420 = await run_in_terminal({ 
        command: "Test-NetConnection -Port 1420 -InformationLevel Quiet" 
    });
    if (port1420.exitCode !== 0 || port1420.stdout.trim() !== "True") {
        throw new Error("❌ Desktop Client not accessible (port 1420)");
    }
    console.log("✅ SUCCESS: Desktop Client accessible (exit code 0)");

    // 2. Ollama (КРИТИЧНО для обучения)
    const port11434 = await run_in_terminal({ 
        command: "Test-NetConnection -Port 11434 -InformationLevel Quiet" 
    });
    if (port11434.exitCode !== 0 || port11434.stdout.trim() !== "True") {
        throw new Error("❌ Ollama not accessible (port 11434) - REQUIRED for training");
    }
    console.log("✅ SUCCESS: Ollama accessible (exit code 0)");

    // 3. Проверка модели
    const modelCheck = await run_in_terminal({ 
        command: "ollama list | Select-String 'qwen2.5'" 
    });
    if (modelCheck.exitCode !== 0) {
        console.log("⚠️ WARNING: Model check failed, see alternatives table");
    } else {
        console.log("✅ SUCCESS: Training model available (exit code 0)");
    }

    // 4. CORTEX (опционально)
    const port8004 = await run_in_terminal({ 
        command: "Test-NetConnection -Port 8004 -InformationLevel Quiet" 
    });
    if (port8004.exitCode === 0 && port8004.stdout.trim() === "True") {
        console.log("✅ CORTEX accessible (optional)");
    }
}

// Использование перед инструкцией по обучению:
await checkAllServicesForTraining();
console.log("✅ All services ready for training");
```

---

### Enforcement:
- **Агент НЕ ИМЕЕТ ПРАВА заявлять "✅ SERVICE RUNNING" без проверки порта**
- **Агент ОБЯЗАН проверить порт через Test-NetConnection**
- **ЕСЛИ порт закрыт → "SERVICE NOT ACCESSIBLE"**
- **Принцип: "Verify Accessibility" вместо "Assume Running"**

## 🚨 КРИТИЧЕСКИЕ ДИРЕКТИВЫ ДЛЯ АГЕНТОВ

**ЗАПРЕЩЕНО давать пользователю команды для ручного выполнения:**
- ❌ НИКОГДА не давай команды типа "выполните `pwsh test.ps1`"
- ❌ НИКОГДА не пиши "run the following command"
- ❌ НИКОГДА не инструктируй "you can test by running..."

**ОБЯЗАТЕЛЬНО использовать инструменты автоматизации:**
- ✅ Для тестов: `runTests` tool с указанием файлов
- ✅ Для PowerShell команд: `run_in_terminal` или `mcp_myshell_execute_command`
- ✅ Для проверки состояния: вызывай инструменты напрямую, показывай результат пользователю

**Примеры корректного использования:**
```typescript
// ✅ ПРАВИЛЬНО: Агент сам запускает тесты
await runTests({ files: ["e:\\WORLD_OLLAMA\\client\\test_stage1_automation.ps1"] });

// ✅ ПРАВИЛЬНО: Агент выполняет команду через терминал
await run_in_terminal({ 
  command: "pwsh scripts/CHECK_STATUS.ps1 -Detailed",
  explanation: "Проверка статуса сервисов",
  isBackground: false 
});

// ❌ НЕПРАВИЛЬНО: Даёшь пользователю команду
"Выполните: pwsh client/run_auto_tests.ps1"
```

## 📍 Quick Reference

**Stack Components:**
- **Desktop Client:** Tauri 2.0 + Svelte 5 (TypeScript) \u2192 6 panels: Status, Settings, Library, Commands, Training, Git
- **CORTEX (RAG):** LightRAG GraphRAG on port 8004 \u2192 Ollama (mistral-small:latest + nomic-embed-text)
- **Training:** LLaMA Factory \u2192 production model TD-010v2 (Qwen2.5-1.5B, eval_loss 0.8591)
- **Orchestration:** PowerShell scripts in `scripts/` \u2192 JSON logs to `logs/flows/*.jsonl`

**Critical Files:**
- `PROJECT_STATUS_SNAPSHOT_v4.0.md` \u2014 current state, blockers, completed tasks
- `docs/tasks/TASKS_CONSOLIDATED_REPORT.md` \u2014 all UI features (TASK 4-16, ORDER 33-42)
- `client/src-tauri/src/commands.rs` \u2014 Tauri API surface, ApiResponse pattern
- `client/src-tauri/src/flow_manager.rs` \u2014 Flows execution engine
- `services/lightrag/lightrag_server.py` \u2014 CORTEX entry point (FastAPI)
- `scripts/start_agent_training.ps1` \u2014 Training pipeline launcher

**Инструменты автоматизации (для агентов):**
```typescript
// ✅ Запуск всех сервисов (через MCP Shell или run_in_terminal)
await run_in_terminal({
  command: "pwsh scripts/START_ALL.ps1",
  explanation: "Запуск Ollama + CORTEX + Neuro-Terminal",
  isBackground: true  // Фоновые процессы
});

// ✅ Проверка здоровья сервисов (через MCP Shell - быстрая команда)
await mcp_myshell_execute_command({
  command: "pwsh scripts/CHECK_STATUS.ps1 -Detailed"
});

// ✅ Запуск Desktop Client (через run_in_terminal с background)
await run_in_terminal({
  command: "Set-Location client; npm run tauri dev",
  explanation: "Запуск Tauri Desktop Client в dev режиме",
  isBackground: true
});

// ✅ Сборка релиза (run_in_terminal, может занять время)
await run_in_terminal({
  command: "pwsh scripts/BUILD_RELEASE.ps1",
  explanation: "Компиляция production build",
  isBackground: false
});

// ✅ Smoke tests (через runTests tool)
await runTests({ 
  files: ["e:\\WORLD_OLLAMA\\client\\run_auto_tests.ps1"] 
});
```

## 💡 ДИРЕКТИВА: Полная Информация о Ресурсах (Alternatives Disclosure)

**ПРИ ОТСУТСТВИИ РЕСУРСА агент ОБЯЗАН сообщить об альтернативах:**

---

### Правило:
1. ✅ Сообщить о missing ресурсе
2. ✅ **ОБЯЗАТЕЛЬНО** показать альтернативы (если есть)
3. ✅ Дать рекомендацию по установке/использованию

---

### Примеры правильного формата:

#### Пример 1: Ollama Models
```
❌ НЕПРАВИЛЬНО:
"⚠️ Model missing: mistral-small:latest"

✅ ПРАВИЛЬНО:
"⚠️ Recommended model mistral-small:latest not found

✅ Available alternatives:
   • qwen2.5:3b-instruct (1.9 GB) — smaller, faster variant
   • llama3.1:8b (4.9 GB) — alternative architecture

💡 To install recommended model:
   ollama pull mistral-small:latest

💡 To use alternative:
   Update CORTEX config in services/lightrag/lightrag_server.py"
```

---

### 📋 ТАБЛИЦА АЛЬТЕРНАТИВ (Ollama Models):

| Рекомендуемая модель | Альтернатива 1 | Альтернатива 2 | Команда установки |
|---------------------|----------------|----------------|-------------------|
| mistral-small:latest | qwen2.5:3b-instruct | llama3.1:8b | `ollama pull mistral-small:latest` |
| nomic-embed-text | mxbai-embed-large | bge-m3 | `ollama pull nomic-embed-text` |
| qwen2.5:7b | llama3.1:8b | mistral:7b | `ollama pull qwen2.5:7b` |

---

### Применяется к:

- **Ollama models:** Всегда показывать `ollama list` альтернативы (см. таблицу выше)
- **Python packages:** Показывать `pip list` установленные версии
- **npm packages:** Показывать `npm list` установленные версии
- **Файлы:** Если файл не найден, проверить похожие (regex search)

---

### Enforcement:
- **Агент НЕ ИМЕЕТ ПРАВА сообщать только "missing" без проверки альтернатив**
- **Агент ОБЯЗАН выполнить команду для проверки альтернатив (ollama list, pip list, etc.)**
- **Агент ОБЯЗАН показать рекомендацию по установке/использованию**
- **Принцип: "Full Disclosure" вместо "Partial Information"**

## Path Resolution (CRITICAL)
**NEVER hardcode `E:\WORLD_OLLAMA`.** Always use:
- **Rust:** `crate::utils::get_project_root()` returns `PathBuf`
- **Python:** Check `WORLD_OLLAMA_ROOT` env var, fallback to `Path(__file__).resolve().parent.parent.parent`
- **PowerShell:** `$ProjectRoot = $PSScriptRoot` or param with default

Example (Rust):
```rust
let project_root = crate::utils::get_project_root();
let script_path = project_root.join("scripts").join("ingest_watcher.ps1");
```

## MCP Shell Server — Production Tool
**Use `myshell/execute_command` for all PowerShell** unless visual progress needed. Provides:
- **Auto Base64 encoding:** Eliminates Exit Code 255 for pipes `|`, braces `{}`, variables `$` (94.44% test coverage)
- **Circuit Breaker:** After 3 failures → `fallbackSuggested=true`, switch to `run_in_terminal`
- **Smart Retries:** Fast cmds retry 2×1s, medium 1×5s, long no retry (idempotent only)
- **Watchdog:** Kills hung processes after 30s no output; adaptive timeouts 60s/120s/900s
- **Error UX:** Russian `userMessage` for common failures (file not found, access denied)

**When to use MCP:**
- Health checks: `Test-NetConnection`, `ollama list | Select-String`, `nvidia-smi`
- Git operations: `git status --porcelain`, `git log origin/main..HEAD`
- Quick reads: `Get-Content`, `Test-Path`, complex pipelines

**When to fallback to terminal:**
- `meta.fallbackSuggested=true` (circuit breaker open)
- Visual progress: `npm run tauri dev`, `START_ALL.ps1`, training UI
- Background services: `isBackground=true` for long-running servers

**Verify:** `pwsh mcp-shell/test_phase1_edge_cases.ps1` → 17/18 PASS. Logs: `logs/mcp/mcp-events.log`

## 🚨 ABSOLUTE RULE: RUNTIME STABILITY FOR BACKGROUND PROCESSES

**ПОСЛЕ запуска background процесса агент ОБЯЗАН:**

---

### 📋 ОБЯЗАТЕЛЬНЫЕ ШАГИ ВЕРИФИКАЦИИ:

1. ✅ **ЖДАТЬ:** Минимум 10 секунд (стабилизация)
2. ✅ **ПРОВЕРИТЬ ПРОЦЕСС:** Работает ли (Get-Process)
3. ✅ **ПРОВЕРИТЬ ПОРТ:** Слушается ли (Test-NetConnection)
4. ✅ **ПРОВЕРИТЬ ЛОГИ:** Нет критичных ошибок (Get-Content ... -Tail 20)

**ЕСЛИ хотя бы один пункт ❌ → "NOT FUNCTIONAL"**

---

### 🔍 DETECTION PATTERN (обязательный паттерн):

```typescript
// ❌ НЕПРАВИЛЬНО (текущее поведение):
await run_in_terminal({ command: "npm run tauri dev", isBackground: true });
// Агент НЕМЕДЛЕННО: "✅ Desktop Client FUNCTIONAL" ← КРИТИЧНАЯ ОШИБКА!

// ✅ ПРАВИЛЬНО (обязательное поведение):

// Шаг 1: Запуск
const result = await run_in_terminal({ 
    command: "npm run tauri dev", 
    isBackground: true 
});

// Проверка exit code (см. директиву Exit Code ниже)
if (result.exitCode !== 0) {
    throw new Error(`❌ FAIL: Failed to start (exit code ${result.exitCode})`);
}

// Шаг 2: ОБЯЗАТЕЛЬНАЯ ЗАДЕРЖКА (минимум 10 секунд)
await new Promise(resolve => setTimeout(resolve, 10000));

// Шаг 3: ОБЯЗАТЕЛЬНАЯ ПРОВЕРКА ПРОЦЕССА
const processCheck = await run_in_terminal({ 
    command: "Get-Process -Name tauri_fresh -ErrorAction SilentlyContinue" 
});

if (processCheck.exitCode !== 0) {
    throw new Error("❌ NOT FUNCTIONAL: Process tauri_fresh not found (exit code " + processCheck.exitCode + ")");
}

if (!processCheck.stdout.includes("tauri_fresh")) {
    throw new Error("❌ NOT FUNCTIONAL: Process crashed after startup");
}

// Шаг 4: ОБЯЗАТЕЛЬНАЯ ПРОВЕРКА ПОРТА
const portCheck = await run_in_terminal({ 
    command: "Test-NetConnection -ComputerName localhost -Port 1420 -InformationLevel Quiet" 
});

if (portCheck.stdout.trim() !== "True") {
    throw new Error("❌ NOT FUNCTIONAL: UI not accessible (port 1420 closed)");
}

// ТОЛЬКО ЕСЛИ ВСЕ ПРОВЕРКИ ✅:
console.log("✅ Desktop Client FUNCTIONAL and STABLE");
```

---

### 📋 Таблица портов (для reference):

| Сервис | Порт | Процесс | Проверка |
|--------|------|---------|----------|
| Desktop Client | 1420 | tauri_fresh | Test-NetConnection -Port 1420 |
| Ollama | 11434 | ollama | ollama list |
| CORTEX | 8004 | python | Invoke-RestMethod http://localhost:8004/health |
| Neuro-Terminal | 8000 | chainlit | Test-NetConnection -Port 8000 |

---

### ⚠️ AUTOMATIC FAILURE CONDITIONS:

**АВТОМАТИЧЕСКОЕ ПРЕРЫВАНИЕ ВЫПОЛНЕНИЯ ПРИ:**

1. ⛔ Агент заявляет "✅ FUNCTIONAL" сразу после запуска
2. ⛔ Агент НЕ ждёт минимум 10 секунд перед проверкой
3. ⛔ Агент НЕ проверяет процесс + порт

**ДЕЙСТВИЕ:** STOP EXECUTION → Report to user → "Cannot verify runtime stability without proper checks"

**Принцип:** "Runtime Verification" (проверка во время выполнения) вместо "Launch Assumption" (предположение о запуске)

## Automatic Indexation Tools (v2.0 — 03.12.2025)

**Three automation mechanisms** for keeping `RUNTIME_LOGS_JOURNAL_INDEX.md` up-to-date (Consensus.app Research + Agent Testing validated):

### 1. FileSystemWatcher (Real-time)
**Script:** `scripts/WATCH_FILE_CHANGES.ps1`  
**Purpose:** Monitor `.md` files and trigger incremental reindexing on changes  
**Features:**
- Debounce 2s (prevents excessive updates)
- Excludes: venv, node_modules, archive, llamaboard_cache
- Heartbeat every 10 min
- Logs: `logs/file_watcher.log`

**Usage (Terminal — recommended for background tasks):**
```powershell
# MCP Shell does NOT support isBackground parameter
# Use run_in_terminal for long-running/background processes
pwsh -File scripts\WATCH_FILE_CHANGES.ps1
```
**Notes:** MCP Shell **NOT suitable** for infinite loops or background processes. Use `run_in_terminal` with `isBackground: true` instead.

**Usage (Terminal — fallback):**
```powershell
# From repo root
pwsh -File scripts\WATCH_FILE_CHANGES.ps1
```

**Management:**
```powershell
# Check status
Get-Process pwsh | Where-Object { $_.CommandLine -like "*WATCH_FILE_CHANGES*" }

# Stop watcher
$watcher = Get-Process pwsh | Where-Object { $_.CommandLine -like "*WATCH_FILE_CHANGES*" }
if ($watcher) { Stop-Process -Id $watcher.Id -Force }

# Tail logs
Get-Content logs\file_watcher.log -Tail 20 -Wait
```

### 2. Git Post-Commit Hook (On-commit)
**Scripts:** `scripts/post-commit.hook` + `scripts/INSTALL_GIT_HOOK.ps1`  
**Purpose:** Automatic reindexing after Git commits with `.md` changes  
**Installation:**
```powershell
pwsh scripts\INSTALL_GIT_HOOK.ps1
```
**Verification:**
```powershell
Test-Path .git\hooks\post-commit  # Should return True
```
**Trigger:** Runs after each `git commit` if `.md` files changed (non-blocking, won't fail commit on errors)

### 3. Windows Scheduled Task (Daily)
**Script:** `scripts/CREATE_SCHEDULED_TASK.ps1`  
**Purpose:** Full reindexing daily at 03:00 (cleanup accumulated errors)  
**Installation (requires admin):**
```powershell
# Create task (default: daily at 03:00)
pwsh scripts\CREATE_SCHEDULED_TASK.ps1

# Create with custom time
pwsh scripts\CREATE_SCHEDULED_TASK.ps1 -ExecutionTime "02:30"

# Remove task
pwsh scripts\CREATE_SCHEDULED_TASK.ps1 -RemoveTask
```
**Verification:**
```powershell
Get-ScheduledTask -TaskName "WORLD_OLLAMA_Daily_Reindex"
# Manually trigger (test)
Start-ScheduledTask -TaskName "WORLD_OLLAMA_Daily_Reindex"
# Check result (0=success)
(Get-ScheduledTaskInfo -TaskName "WORLD_OLLAMA_Daily_Reindex").LastTaskResult
```

### Core Reindexing Script
**Script:** `scripts/UPDATE_PROJECT_INDEX.ps1`  
**Modes:**
```powershell
# Incremental (1-5 files, <500ms)
pwsh scripts\UPDATE_PROJECT_INDEX.ps1 -IncrementalMode -TriggerFile "path.md"

# Full (all files, ~870ms for 166 files)
pwsh scripts\UPDATE_PROJECT_INDEX.ps1 -FullReindex
```
**Updates:** `docs/project/RUNTIME_LOGS_JOURNAL_INDEX.md` metadata (file counts, timestamps, coverage period)  
**Logs:** `logs/indexation.log`

**Summary:** Use all three mechanisms together — FileSystemWatcher (development), Git Hook (CI/CD), Scheduled Task (safety net). Overhead: ~0.001% (1s/day).

## Architecture & Data Flows

### Training Pipeline (UI → Rust → PowerShell → Python)
```
TrainingPanel.svelte (UI validation: epochs 1-5, profile whitelist)
  ↓ POST /api/training/start
client/src/lib/api/client.ts (startTrainingJob)
  ↓ Tauri invoke
client/src-tauri/src/commands.rs (start_training_job)
  ↓ PowerShell call
scripts/start_agent_training.ps1 (params validation)
  ↓ llamafactory-cli
services/llama_factory/src/train.py
  ↓ writes atomically (os.replace)
training_status.json
  ↑ polled by training_manager.rs (2-10s adaptive)
  ↓ emit Tauri event
UI updates (PULSE v1 protocol: idle/running/done/error)
```
**Key files:** `commands.rs::start_training_job`, `start_agent_training.ps1`, `training_manager.rs::start_polling`, `TrainingPanel.svelte`

### CORTEX RAG Pipeline (GraphRAG with LightRAG)
```
UI query → client/src/lib/api/client.ts
  ↓ POST http://localhost:8004/query
services/lightrag/lightrag_server.py (FastAPI)
  ↓ LightRAG(mode="hybrid", enable_rerank=False)
  ↓ ollama_model_complete("mistral-small:latest")
  ↓ ollama_embed("nomic-embed-text")
Ollama (http://localhost:11434)
  ↓ returns context + answer
lightrag_server.py → JSON response
  ↓ back to UI
ChatPanel.svelte renders sources + chain-of-thought
```
**Health check:** `Invoke-RestMethod http://localhost:8004/health` or `curl http://localhost:11434/api/tags`  
**GPU telemetry:** `nvidia-smi --query-gpu=memory.used --format=csv,noheader` (>6 GB = embeddings loaded)  
**Chunking:** Fixed ~10 KB in `lightrag_server.py`, token budget <4k/chunk for Ollama limits

## Documentation Compass

**ALWAYS start with consolidated reports** before touching code:
- **UI tasks** (TASK 4-16, ORDER 33-42, ORDER 52) → `docs/tasks/TASKS_CONSOLIDATED_REPORT.md` (полные спецификации + тестирование)
- **Models/training** (TD-010v2/v3, fine-tuning) → `docs/models/MODELS_CONSOLIDATED_REPORT.md`
- **Infrastructure** (CORTEX, security, RAG, tools audit) → `docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md`
- **Tools cleanup** (VS Code extensions) → `docs/infra/TOOLS_CLEANUP_RESULTS.md` (71 → 51 расширений, конфликты решены)

**Architecture/status questions:**
1. `PROJECT_MAP.md` — directory structure, ignored folders, generation protocol
2. `PROJECT_STATUS_SNAPSHOT_v4.0.md` — current phase (v0.3.1 Released 02.12.2025), ORDER 40+52 COMPLETE, known blockers (ORDER 43 - HF gated models)
3. `README.md` — user-facing features, quick start, troubleshooting, релиз v0.3.1
4. `DOCUMENTATION_INDEX.md` — полная карта документации (68 файлов, консолидированные отчёты)

**Task-specific deep dives:** Cross-referenced in consolidated reports (e.g., `client/TASK8_COMPLETION_REPORT.md` for Command DSL details)

## Core Workflows
- **Start stack:** `pwsh scripts/START_ALL.ps1`, then `pwsh scripts/CHECK_STATUS.ps1 -Detailed`. Desktop client (6 panels + ⚡ Flows) expects CORTEX up before `npm run tauri dev`.
- **Flows automation:** JSON definitions live in `automation/flows/*.json`, executed through `FlowExecutor` in `client/src-tauri/src/flow_manager.rs`. Every run logs JSON lines to `logs/flows/flow_{id}_{timestamp}.jsonl`; inspect there when troubleshooting multi-step failures.
- **Training:** Allowed epochs 1-5, profiles restricted to whitelisted names (see `start_training_job` and `scripts/start_agent_training.ps1`). If the HF base model is gated (ORDER 43), either `huggingface-cli login` or switch to the open config in `services/llama_factory/config/llama3_lora_sft.yaml`. Track progress via `services/llama_factory/training_status.json` and `logs/training/train-*.log`.
- **Safe Git Assistant:** Tauri command `plan_git_push` enforces seven blockers (unstaged changes, wrong branch, remote ahead, etc.) before `execute_git_push`. Always re-run the plan right before pushing; UI mirrors the Rust validations.

## Project Conventions

**PowerShell automation:**
- Use JSON logs (one object per line) for all orchestration — compatible with `FlowLogger` in `flow_manager.rs`
- Always use `$ErrorActionPreference = "Stop"` for fail-fast behavior
- Log format: `[timestamp] [LEVEL] message` to `logs/orchestrator.log`

**RAG/CORTEX constraints:**
- LightRAG chunking: fixed ~10 KB in `lightrag_server.py`
- Token budget: <4k per chunk (Ollama context window limits)
- Never re-index without checking `services/lightrag/data/kv_store_doc_status.json`
- Rerank disabled (`enable_rerank=False`) due to stability issues (see PLAN C baseline)

**Tauri/Rust patterns:**
- All Tauri commands return `ApiResponse<T>` with `{ok: bool, data?: T, error?: {type: string, message: string}}` (see `commands.rs::ApiResponse`)
- **Always check `ok` field:** `if (!result.ok) { console.error(result.error.message); return; }`
- Use `crate::utils::get_project_root()` for path operations — never `current_exe()` directly
- Settings persistence: `%APPDATA%/WorldOllama` via `settings.rs`
- Profile switching: check `client/src/lib/stores/settings.ts` for state management
- Command execution: Parse DSL with `command_parser.rs` → route through `flow_manager.rs` for STATUS/GIT_PUSH/TRAIN/INDEX

**Code style:**
- Rust: Follow existing pattern of extensive comments with ORDER/TASK references
- Svelte: Reactive statements (`$:`) for derived state, avoid imperative updates
- Python: Type hints required, use `Path` objects not string concatenation for file paths

**Error patterns to recognize:**
- `Exit Code 255` in PowerShell → pipes/special chars issue, use MCP Shell (auto Base64 encoding)
- `current_exe()` path errors → switch to `crate::utils::get_project_root()` pattern
- `FileNotFoundError` in Python services → verify `WORLD_OLLAMA_ROOT` env var or use `Path(__file__).parent.parent.parent`
- Training crash at tokenizer loading → ORDER 43 blocker (HuggingFace gated model)
- CORTEX 500 errors → check `services/lightrag/data/kv_store_doc_status.json` exists, verify embeddings loaded (>6GB VRAM)

## 🚨 ABSOLUTE RULE: ALWAYS CHECK EXIT CODE

**КАЖДАЯ команда run_in_terminal ОБЯЗАНА проверять Exit Code. БЕЗ ИСКЛЮЧЕНИЙ.**

---

### 📋 ОБЯЗАТЕЛЬНАЯ ТАБЛИЦА ДЕЙСТВИЙ:

| Exit Code | Статус | Действие агента | Сообщение пользователю |
|-----------|--------|-----------------|------------------------|
| **0** | ✅ SUCCESS | Продолжить работу | "✅ SUCCESS: [операция] completed" |
| **1-255** | ❌ FAIL | ОСТАНОВИТЬ, сообщить пользователю | "❌ FAIL: Command failed with exit code N" |

---

### 📋 ТАБЛИЦА КРИТИЧНЫХ КОМАНД:

| Команда | Ожидаемый Exit Code | Действие при ошибке |
|---------|----------------------|-------------------------|
| `cargo check` | 0 | ❌ FAIL: Compilation failed |
| `cargo build --release` | 0 | ❌ FAIL: Build failed |
| `npm run tauri dev` | 0 | ❌ FAIL: Service failed to start |
| `npm run tauri build` | 0 | ❌ FAIL: Production build failed |
| `ollama list` | 0 | ❌ FAIL: Ollama not accessible |
| `pwsh scripts/CHECK_STATUS.ps1` | 0 | ❌ FAIL: Status check failed |
| `pwsh scripts/START_ALL.ps1` | 0 | ❌ FAIL: Services failed to start |
| `Test-NetConnection -Port 1420` | 0 | ❌ FAIL: Port check failed |
| `Test-NetConnection -Port 11434` | 0 | ❌ FAIL: Ollama port closed |
| `Test-NetConnection -Port 8004` | 0 | ❌ FAIL: CORTEX port closed |
| `nvidia-smi` | 0 | ❌ FAIL: GPU not accessible |
| `Get-Process tauri_fresh` | 0 | ❌ FAIL: Process not found |

---

### 🔍 DETECTION PATTERN (автоматическое применение):

```typescript
// ПОСЛЕ КАЖДОГО run_in_terminal:
const result = await run_in_terminal({ command: "..." });

// ШАГ 1: ОБЯЗАТЕЛЬНАЯ ПРОВЕРКА
if (result.exitCode !== 0) {
    // ШАГ 2: НЕМЕДЛЕННО СООБЩИТЬ ПОЛЬЗОВАТЕЛЮ
    throw new Error(`❌ FAIL: Command failed with exit code ${result.exitCode}`);
}

// ШАГ 3: ТОЛЬКО ЕСЛИ exitCode === 0 → продолжить
console.log("✅ SUCCESS: Command completed");
```

---

### ❌ ЗАПРЕЩЁННЫЕ ДЕЙСТВИЯ:

1. ❌ Запустить `run_in_terminal` без проверки `exitCode`
2. ❌ Заявлять "✅ SUCCESS" при `exitCode !== 0`
3. ❌ Повторять команду после `exitCode !== 0` без анализа ошибки
4. ❌ Игнорировать `exitCode` для фоновых процессов (`isBackground: true`)

---

### ✅ ОБЯЗАТЕЛЬНЫЕ ПРИМЕРЫ:

#### Пример 1: Компиляция
```typescript
const buildResult = await run_in_terminal({ command: "cargo check" });

// ОБЯЗАТЕЛЬНАЯ ЯВНАЯ ПРОВЕРКА
if (buildResult.exitCode !== 0) {
    throw new Error(`❌ FAIL: Compilation failed (exit code ${buildResult.exitCode})`);
}

// ОБЯЗАТЕЛЬНО СООБЩИТЬ ПОЛЬЗОВАТЕЛЮ
console.log("✅ SUCCESS: cargo check completed (exit code 0)");
```

#### Пример 2: Запуск сервиса
```typescript
const serviceResult = await run_in_terminal({ 
    command: "npm run tauri dev", 
    isBackground: true 
});

if (serviceResult.exitCode !== 0) {
    throw new Error(`❌ FAIL: Service failed to start (exit code ${serviceResult.exitCode})`);
}

console.log("✅ SUCCESS: Service started");
// ВНИМАНИЕ: Для background процессов нужна дополнительная проверка runtime (см. Runtime Стабильность)
```

#### Пример 3: Проверка статуса
```typescript
const statusResult = await run_in_terminal({ command: "pwsh scripts/CHECK_STATUS.ps1" });

if (statusResult.exitCode !== 0) {
    throw new Error(`❌ FAIL: Status check failed (exit code ${statusResult.exitCode})`);
}

console.log("✅ SUCCESS: Status check completed");
```

---

### ⚠️ AUTOMATIC FAILURE CONDITIONS:

**АВТОМАТИЧЕСКОЕ ПРЕРЫВАНИЕ ВЫПОЛНЕНИЯ ПРИ:**

1. ⛔ Агент заявляет "✅ SUCCESS" без проверки `exitCode === 0`
2. ⛔ Агент игнорирует `exitCode !== 0` и продолжает выполнение
3. ⛔ Агент повторяет команду после `exitCode !== 0` без анализа ошибки

**ДЕЙСТВИЕ:** STOP EXECUTION → Report to user → "Cannot proceed due to command failure"

**Принцип:** "Prove Success" (доказать успех) вместо "Assume Success" (предполагать успех)

**НЕТ ИСКЛЮЧЕНИЙ.** Правило применяется к ВСЕМ командам `run_in_terminal`.

## Testing & Verification

## 🚨 ABSOLUTE RULE: TESTS REQUIRE runTests TOOL

**ЗАПРЕЩЕНО использовать `run_in_terminal` для тестов. ОБЯЗАТЕЛЬНО использовать `runTests` tool.**

---

### 📋 ТАБЛИЦА ПРАВИЛЬНЫХ ИНСТРУМЕНТОВ:

| Тип задачи | Паттерн файла | ❌ ЗАПРЕЩЕНО | ✅ ОБЯЗАТЕЛЬНО |
|------------|---------------|--------------|----------------|
| **Запуск тестов** | `*test*.ps1`, `*test*.py`, `*.test.ts`, `test_*.py` | `run_in_terminal` | `runTests` |
| **Компиляция** | `cargo check`, `npm build` | — | `run_in_terminal` |
| **Проверка статуса** | `CHECK_STATUS.ps1`, `ollama list` | — | `run_in_terminal` |
| **Запуск сервисов** | `START_ALL.ps1`, `npm run tauri dev` | — | `run_in_terminal` |

---

### 🔍 DETECTION PATTERN (автоматическое определение):

**Если команда содержит:**
- `"test"` в имени файла (case-insensitive) → использовать `runTests`
- `"_test.py"` или `"test_*.py"` → использовать `runTests`
- `"*.test.ts"` или `"*.spec.ts"` → использовать `runTests`
- `".ps1"` И "test" в пути → использовать `runTests`

**Примеры автоопределения:**
```typescript
// Команда содержит "test" → DETECTION: использовать runTests
"pwsh client/run_auto_tests.ps1" → runTests({ files: ["e:\\WORLD_OLLAMA\\client\\run_auto_tests.ps1"] })
"pwsh client/test_stage1_automation.ps1" → runTests({ files: [...] })
"pytest services/tests/test_cortex.py" → runTests({ files: [...] })

// Команда НЕ содержит "test" → DETECTION: использовать run_in_terminal
"pwsh scripts/CHECK_STATUS.ps1" → run_in_terminal({ command: "pwsh scripts/CHECK_STATUS.ps1" })
"cargo check" → run_in_terminal({ command: "cargo check" })
```

---

### ❌ ЗАПРЕЩЁННЫЕ КОМАНДЫ:

```typescript
// ❌ КРИТИЧНАЯ ОШИБКА:
await run_in_terminal({ command: "pwsh client/run_auto_tests.ps1" });
await run_in_terminal({ command: "pytest services/tests/" });
await run_in_terminal({ command: "npm test" });
```

---

### ✅ ОБЯЗАТЕЛЬНЫЕ ПРИМЕРЫ:

#### Пример 1: Одиночный тест (PowerShell)
```typescript
// ❌ НЕПРАВИЛЬНО:
await run_in_terminal({ command: "pwsh client/run_auto_tests.ps1" });

// ✅ ПРАВИЛЬНО:
await runTests({ files: ["e:\\WORLD_OLLAMA\\client\\run_auto_tests.ps1"] });
```

#### Пример 2: Множественные тесты
```typescript
// ❌ НЕПРАВИЛЬНО:
await run_in_terminal({ command: "pwsh client/test_stage1_automation.ps1" });
await run_in_terminal({ command: "pwsh client/test_stage2_e2e.ps1" });

// ✅ ПРАВИЛЬНО (одним вызовом):
await runTests({ 
    files: [
        "e:\\WORLD_OLLAMA\\client\\test_stage1_automation.ps1",
        "e:\\WORLD_OLLAMA\\client\\test_stage2_e2e.ps1"
    ]
});
```

#### Пример 3: Python тесты
```typescript
// ❌ НЕПРАВИЛЬНО:
await run_in_terminal({ command: "pytest services/tests/test_cortex.py" });

// ✅ ПРАВИЛЬНО:
await runTests({ files: ["e:\\WORLD_OLLAMA\\services\\tests\\test_cortex.py"] });
```

---

### ⚠️ AUTOMATIC FAILURE CONDITIONS:

**АВТОМАТИЧЕСКОЕ ПРЕРЫВАНИЕ ВЫПОЛНЕНИЯ ПРИ:**

1. ⛔ Агент использует `run_in_terminal` для файлов с "test" в имени
2. ⛔ Агент использует `run_in_terminal` для `*.ps1` тестов
3. ⛔ Агент использует `run_in_terminal` для `pytest` или `npm test`

**ДЕЙСТВИЕ:** STOP EXECUTION → Report to user → "Cannot run tests without runTests tool"

**Принцип:** "Tool Consistency" — правильный инструмент для правильной задачи

**Последствия:** Потеря структурированного вывода тестов, отсутствие интеграции с VS Code Test Explorer

---

**🚨 АГЕНТ ДОЛЖЕН САМ ЗАПУСКАТЬ ТЕСТЫ** через `runTests` tool:
```typescript
// ✅ ПРАВИЛЬНО: UI/bridge smoke tests
await runTests({ 
  files: [
    "e:\\WORLD_OLLAMA\\client\\run_auto_tests.ps1",
    "e:\\WORLD_OLLAMA\\client\\test_task4_scenarios.ps1",
    "e:\\WORLD_OLLAMA\\client\\test_task5_settings.ps1"
  ]
});

// ✅ ПРАВИЛЬНО: Release builds
await run_in_terminal({
  command: "pwsh scripts/BUILD_RELEASE.ps1",
  explanation: "Сборка production релиза",
  isBackground: false
});
// Альтернатива (если BUILD_RELEASE.ps1 недоступен):
await run_in_terminal({
  command: "Set-Location client; npm run tauri build",
  explanation: "Direct build через npm (output: client/src-tauri/target/release)",
  isBackground: false
});
```

**Проверка успешности GPU-интенсивных задач:**
Перед отчётом о завершении GPU-задач **агент обязан** предоставить телеметрию:
```typescript
// ✅ Проверка GPU через MCP Shell
const gpuCheck = await mcp_myshell_execute_command({
  command: "nvidia-smi --query-gpu=memory.used --format=csv,noheader"
});

// ✅ Проверка Ollama моделей
const ollamaModels = await mcp_myshell_execute_command({
  command: "ollama list | Select-String 'mistral-small'"
});

// ✅ Tail logs
const cortexLogs = await mcp_myshell_execute_command({
  command: "Get-Content logs/services/cortex.log -Tail 20"
});
```

## ⚠️ ДИРЕКТИВА: Свежие Данные Вместо Кэшированных Логов

**ЗАПРЕЩЕНО использовать устаревшие лог-файлы для проверки состояния:**

---

### ❌ ЗАПРЕЩЁННЫЕ ФАЙЛЫ (для проверки состояния):

- `client/src-tauri/warnings_rust.log` — может быть устаревшим
- `services/llama_factory/training_status.json` — если старше 5 минут
- Любые `*.log` файлы без проверки timestamp

---

### ✅ ОБЯЗАТЕЛЬНО выполнять свежие команды:

| Вместо читать файл | Выполнить команду |
|--------------------|-------------------|
| ❌ `warnings_rust.log` | ✅ `cargo check 2>&1` |
| ❌ Старые логи Ollama | ✅ `ollama list` |
| ❌ Предположения о моделях | ✅ `ollama list \| Select-String 'qwen'` |
| ❌ Старые training_status.json | ✅ `Get-Content ... \| ConvertFrom-Json` + проверка timestamp |

---

### Примеры правильного использования:

#### Пример 1: Компиляция Rust
```typescript
// ❌ НЕПРАВИЛЬНО:
const log = await read_file("client/src-tauri/warnings_rust.log");
// Может быть устаревшим

// ✅ ПРАВИЛЬНО:
const buildResult = await run_in_terminal({ command: "cargo check 2>&1" });
if (buildResult.exitCode !== 0) {
    console.error("❌ Compilation failed:", buildResult.stderr);
}
```

#### Пример 2: Ollama Models
```typescript
// ❌ НЕПРАВИЛЬНО:
// Предполагать, что модель есть/нет без проверки

// ✅ ПРАВИЛЬНО:
const modelsResult = await run_in_terminal({ command: "ollama list" });
const hasMistralSmall = modelsResult.stdout.includes("mistral-small");

if (!hasMistralSmall) {
    console.log("⚠️ mistral-small:latest not found");
    // Проверить альтернативы (см. директиву Полная Информация)
    const hasQwen3b = modelsResult.stdout.includes("qwen2.5:3b");
    if (hasQwen3b) {
        console.log("✅ Alternative available: qwen2.5:3b-instruct");
    }
}
```

---

### Исключения (разрешено читать файлы):

✅ **Конфигурационные файлы** (не меняются часто):
- `package.json`
- `Cargo.toml`
- `client/src-tauri/tauri.conf.json`
- `*.yaml`, `*.json` конфиги

✅ **Статические документы:**
- `README.md`
- `PROJECT_MAP.md`
- `DOCUMENTATION_INDEX.md`

---

### Enforcement:
- **Агент ОБЯЗАН выполнять свежие команды для проверки состояния**
- **Агент НЕ ИМЕЕТ ПРАВА читать *.log файлы без проверки timestamp**
- **ЕСЛИ файл старше 5 минут → выполнить свежую команду**
- **Принцип: "Fresh Data" вместо "Cached Logs"**

## When Things Break
- Dockerized Ollama is unsupported on this host—if you see `/usr/bin/ollama runner` in logs, stop/remove the container and ensure native Ollama answers `curl http://localhost:11434/api/tags`.
- If the MCP circuit breaker opens (meta `breakerState="OPEN"`), pause MCP usage, switch the next command to a terminal, then probe `myshell/health_check` after ~5 s before resuming structured calls.
- **MCP meta field reference:** Every `execute_command` response includes `meta: { breakerState, classification, consecutiveFailures, fallbackSuggested, durationMs, retryAttempt, maxRetries, errorCode?, userMessage? }`. Use `classification` for debugging: `timeout_exec` (>120s), `no_output_timeout` (hung), `exec_error` (Exit Code >0), `spawn_error`, `file_not_found`, `access_denied`, `path_issue`. Agent should report `userMessage` to user when present.
- **Performance thresholds:** Fast commands <500ms, medium <5s, long 30-300s expected. If `durationMs` exceeds 2× → investigate system load. Check `logs/mcp/mcp-events.log` for execution history.
- **Concurrency limit:** Max 5 concurrent `execute_command` calls. Requests beyond this queue automatically (no agent action needed).

**⚠️ CRITICAL MCP Shell Limitations:**
- ❌ **NO isBackground support** — parameter does not exist in MCP Shell v1.3.1
- ❌ **NOT for START_ALL.ps1** — creates detached processes, MCP hangs waiting for close event
- ❌ **NOT for WATCH_FILE_CHANGES.ps1** — infinite loop, no termination
- ❌ **NOT for chainlit/servers** — long-running processes block MCP Shell
- ✅ **USE run_in_terminal instead** for background tasks with `isBackground: true`

**Commands that MUST use run_in_terminal:**
```powershell
# ❌ NEVER use MCP Shell for these:
START_ALL.ps1           # Spawns CORTEX + Neuro-Terminal (detached)
WATCH_FILE_CHANGES.ps1  # Infinite FileSystemWatcher loop
chainlit run app.py     # Long-running server
npm run tauri dev       # Background development server

# ✅ Use run_in_terminal with isBackground: true
```

## MCP Testing & Verification
- **Smoke test:** `myshell/health_check` → expect `{status: "ok", breakerState: "CLOSED"}`. If degraded, wait 5s and retry.
- **Edge case suite:** `pwsh mcp-shell/test_phase1_edge_cases.ps1` → 17/18 PASS validates Base64 encoding. Test 16 (port 8004 check) fails if CORTEX down (expected).
- **E2E tests:** `mcp-shell/e2e/` contains concurrency stress, watchdog, soft kill, long command tests. Run with `npx tsx mcp-shell/e2e/test_*.ts` from project root.
- **Logs:** All executions logged to `logs/mcp/mcp-events.log` (JSON lines): `EXEC cmd=...`, `SUCCESS durationMs=...`, `FAIL classification=...`, `STATE_CHANGE CLOSED→OPEN`. Mirror to project root when running from subfolders (controlled by `MCP_LOG_MIRROR_ROOT=1` env var).

## VS Code Tooling (After Cleanup 03.12.2025)

**Status:** 51 расширений (было 71, удалено 20 за -28%)  
**Конфликты:** Все решены ✅ (AI дубликаты, MCP конфликт, Azure ecosystem)

**Критичные расширения (6):**
- `github.copilot` + `github.copilot-chat` — единственный AI ассистент с MCP интеграцией
- `ms-vscode.powershell` — PowerShell automation (проект core)
- `ms-python.python` — Python services (LightRAG, LLaMA Factory)
- `svelte.svelte-vscode` — Svelte UI framework
- `ms-mssql.mssql` — MCP MSSQL server integration

**Autoapprove whitelist (8 команд):**
```json
{
  "pwsh": true,
  "Get-NetTCPConnection": true,
  "nvidia-smi": true,
  "Test-NetConnection": true,
  "ollama": true,
  "git": true,
  "npm": true,
  "/.*/": true
}
```

**⚠️ Безопасность:** Удалены хардкод токены (Invoice API, Telegram bot) из старого autoapprove (67 записей из проектов REVIZOR/Telegram bot).

**Детали:** См. `docs/infra/TOOLS_CLEANUP_RESULTS.md` и `docs/infra/TOOLS_AUDIT_REPORT.md`

---

## Desktop Automation Tool (ЭТАП 0-2 COMPLETE — 03.12.2025)

**Инструмент для автоматизации UI тестирования** через Tauri IPC commands. Предоставляет агенту консоли возможность:
- Получать состояние экранов (мониторы, разрешения)
- Делать скриншоты (PNG capture)
- Симулировать клики мышью (координаты x, y)
- Вводить текст (keyboard simulation)
- Получать список активных окон (placeholder для ЭТАПА 3)

**Статус:** ✅ ГОТОВ К ИСПОЛЬЗОВАНИЮ (интеграция в Tauri завершена)  
**Roadmap:** `docs/automation/FULL_AUTOMATION_ROADMAP.md`  
**Отчёты:** `docs/automation/STAGE0_COMPLETION_REPORT.md`, `STAGE1_COMPLETION_REPORT.md`, `STAGE2_COMPLETION_REPORT.md`

### Доступные Tauri Commands

**1. automation_get_screen_state()**
```typescript
// Получить информацию о мониторах
const result = await invoke('automation_get_screen_state');
// Returns: ApiResponse<ScreenState>
// ScreenState: { timestamp, screens_available, active_monitors[] }
```

**Пример использования:**
```typescript
const state = await invoke('automation_get_screen_state');
console.log(`Обнаружено ${state.data.screens_available} монитор(а)`);
// Output: Обнаружено 2 монитор(а)
```

**2. automation_capture_screenshot(monitor_index)**
```typescript
// Сделать скриншот монитора (PNG bytes)
const result = await invoke('automation_capture_screenshot', { monitorIndex: 0 });
// Returns: ApiResponse<Vec<u8>> (PNG image)
```

**Пример использования:**
```typescript
const screenshot = await invoke('automation_capture_screenshot', { monitorIndex: 0 });
if (screenshot.success) {
    // Сохранить PNG в файл или отправить на анализ
    const blob = new Blob([new Uint8Array(screenshot.data)], { type: 'image/png' });
}
```

**3. automation_click(x, y)**
```typescript
// Кликнуть мышью по координатам
const result = await invoke('automation_click', { x: 100, y: 200 });
// Returns: ApiResponse<String> ("Clicked at (100, 200)")
```

**Пример использования:**
```typescript
// Кликнуть по кнопке "Start Training" (координаты примерные)
await invoke('automation_click', { x: 850, y: 450 });
await new Promise(resolve => setTimeout(resolve, 500)); // Wait for UI update
```

**4. automation_type_text(text)**
```typescript
// Ввести текст через keyboard simulation
const result = await invoke('automation_type_text', { text: "Hello World" });
// Returns: ApiResponse<String> ("Typed: Hello World")
```

**Пример использования:**
```typescript
// Ввести текст в активное поле
await invoke('automation_click', { x: 400, y: 300 }); // Focus input
await invoke('automation_type_text', { text: "test query" });
```

**5. automation_get_windows()**
```typescript
// Получить список активных окон (placeholder)
const result = await invoke('automation_get_windows');
// Returns: ApiResponse<Vec<WindowInfo>>
// WindowInfo: { title, process_id, has_focus }
```

**Примечание:** В ЭТАПЕ 2 возвращает placeholder (1 окно "VS Code - WORLD_OLLAMA"). Полная реализация в ЭТАПЕ 3.

### API Response Format

**Все команды возвращают:**
```rust
pub struct ApiResponse<T> {
    pub success: bool,       // true = success, false = error
    pub data: Option<T>,     // Результат (если success=true)
    pub error: Option<String>, // Сообщение об ошибке (если success=false)
}
```

**Пример обработки:**
```typescript
const result = await invoke('automation_get_screen_state');
if (result.success) {
    console.log('Data:', result.data);
} else {
    console.error('Error:', result.error);
}
```

### Rust Implementation (Internal)

**Модули:**
- `client/src-tauri/src/automation/mod.rs` — Core API (get_screen_state, capture_screenshot)
- `client/src-tauri/src/automation/executor.rs` — Mouse/keyboard (click_at, type_text via enigo)
- `client/src-tauri/src/automation/monitor.rs` — File system watcher (notify integration)
- `client/src-tauri/src/automation/visualizer.rs` — Windows info (placeholder для ЭТАПА 3)
- `client/src-tauri/src/automation_commands.rs` — Tauri IPC bridge (5 async commands)

**Dependencies (в Cargo.toml):**
```toml
enigo = "0.2.0-rc2"      # Mouse/keyboard simulation
accesskit = "0.12"       # Accessibility API (ЭТАП 3)
notify = "6.1"           # File system watcher
image = "0.24"           # PNG processing
screenshots = "0.8"      # Screen capture
```

### Testing & Verification

**Smoke tests:**
```powershell
# ЭТАП 1: Integration tests (5 crates)
pwsh client/test_stage1_automation.ps1
# Expected: ✅ ALL TESTS PASSED (5/5)

# ЭТАП 2: E2E integration tests (6 tests)
pwsh client/test_stage2_e2e.ps1
# Expected: ✅ ALL E2E TESTS PASSED (6/6)
```

**Проверка компиляции:**
```powershell
cd client/src-tauri
cargo check
# Expected: Finished `dev` profile in ~1.5s
# Warnings: 10 (6 automation "never used" + 4 pre-existing) — нормально
```

**Manual UI test (optional):**
```typescript
// В DevTools console (когда Tauri dev запущен)
const state = await window.__TAURI__.core.invoke('automation_get_screen_state');
console.log(state);
// Expected: { success: true, data: { screens_available: 2, ... } }
```

### Когда использовать Desktop Automation

**✅ Подходит для:**
- UI smoke tests (проверка состояния экрана перед тестами)
- Screenshot capture для visual regression
- Automation сценарии (click → type → screenshot → validate)
- Мониторинг доступности UI элементов

**❌ НЕ подходит для:**
- Production user workflows (это инструмент для тестирования)
- Полноценная Accessibility Tree навигация (будет в ЭТАПЕ 3)
- Self-healing AI orchestrator (roadmap ЭТАП 4, опционально)

### Ограничения (ЭТАП 2)

1. **get_active_windows()** — placeholder (возвращает 1 окно). Полная реализация требует WinAPI (`EnumWindows`, `GetForegroundWindow`) в ЭТАПЕ 3.
2. **Visual Tree Parsing** — не реализован. Для поиска элементов используйте фиксированные координаты.
3. **Debounce/Retry logic** — не реализован. Агент должен сам обрабатывать задержки и повторы.
4. **Cross-platform** — только Windows (enigo v0.2 поддерживает macOS/Linux, но не тестировалось).

### Roadmap & Future Work

**ЭТАП 3 (INTEGRATION):** MCP Server для Claude Desktop (опционально)
- Standalone JSON-RPC server (stdio protocol)
- 5 MCP tools: get_screen_state, capture_screenshot, click, type, get_windows
- Wrapper поверх существующих Tauri commands

**ЭТАП 4 (HARDENING):** CI/CD & Regression Suite (опционально)
- GitHub Actions workflow для automation tests
- Visual regression testing (screenshot diff)
- Self-healing logic (LLM-based fix generation) — только если требуется

**Примечание:** Для агента консоли текущей интеграции (ЭТАП 2) достаточно. ЭТАП 3-4 нужны только если планируется полноценный QA automation framework.

### Troubleshooting

**Ошибка: "Monitor X not found"**
```typescript
// Сначала проверьте доступные мониторы
const state = await invoke('automation_get_screen_state');
console.log(`Available monitors: ${state.data.screens_available}`);
// Используйте index < screens_available
```

**Ошибка: "enigo initialization failed"**
```powershell
# Проверьте cargo check
cd client/src-tauri
cargo check
# Если ошибки компиляции → см. STAGE1_COMPLETION_REPORT.md
```

**Клик не работает (координаты неправильные):**
```typescript
// 1. Сделать скриншот для проверки
const screenshot = await invoke('automation_capture_screenshot', { monitorIndex: 0 });
// 2. Проверить реальное разрешение монитора
const state = await invoke('automation_get_screen_state');
// 3. Пересчитать координаты (origin: top-left, y вниз)
```

**Logs & Debugging:**
- Rust logs: `logs/tauri/app.log` (если настроен logger)
- MCP logs: `logs/mcp/mcp-events.log` (для PowerShell команд)
- Компиляция: `client/src-tauri/target/debug/` (errors при `cargo build`)

### 🔌 VS Code Extension Integration

**Статус:** ✅ УСТАНОВЛЕНО (v1.0.0, 03.12.2025)  
**Расположение:** `C:\Users\zakon\.vscode\extensions\worldollama.vscode-desktop-automation-1.0.0`

**8 команд доступны в Command Palette:**
```
Ctrl+Shift+P → Type "Automation"

1. Automation: Get Screen State          → Runs test_stage1_automation.ps1
2. Automation: Capture Screenshot        → Runs test_stage2_e2e.ps1
3. Automation: Click at Coordinates      → Input x, y (logs to Output)
4. Automation: Type Text                 → Input text (logs to Output)
5. Automation: Get Active Windows        → Shows ЭТАП 2 placeholder note
6. Automation: Run Test Scenario         → QuickPick → runs selected test
7. Automation: Show Logs                 → Opens Output channel
8. Automation: Open Configuration        → Opens Settings UI
```

**Configuration (Settings → "automation"):**
```json
{
  "automation.defaultMonitor": 0,       // Primary monitor index
  "automation.clickDelay": 500,         // Delay after click (ms)
  "automation.logLevel": "info"         // debug|info|warn|error
}
```

**Проверка активации:**
```powershell
# Verify extension installed
pwsh distribution/vscode-desktop-automation/verify_activation.ps1

# Reload VS Code to activate
# Ctrl+Shift+P → "Developer: Reload Window"

# Check Output panel
# Ctrl+Shift+U → Select "Desktop Automation"
```

**Документация:** `distribution/vscode-desktop-automation/EXTENSION_COMPLETION_REPORT.md`

---

_Questions or missing details? Let me know which section feels light so I can expand it._
````
