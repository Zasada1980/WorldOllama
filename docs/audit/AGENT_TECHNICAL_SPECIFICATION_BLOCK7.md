# ТЕХНИЧЕСКОЕ ЗАДАНИЕ: Исправление Настроек Агента (БЛОК 7)

**Дата создания:** 03.12.2025 21:35  
**Автор:** Agent Verification System  
**Основание:** Аудит галлюцинаций агента (БЛОК 1-6)  
**Проект:** WORLD_OLLAMA v0.3.1  
**Статус:** 🔴 **КРИТИЧНО — ТРЕБУЕТСЯ НЕМЕДЛЕННАЯ РЕАЛИЗАЦИЯ**

---

## 🎯 ЦЕЛЬ ТЕХНИЧЕСКОГО ЗАДАНИЯ

Устранить **7 выявленных галлюцинаций** агента путём внесения изменений в `.github/copilot-instructions.md` и создания enforcement механизмов.

**Целевые метрики:**
- Точность заявлений агента: **49% → 95%** (+46 п.п.)
- Критичные галлюцинации: **4 → 0** (-100%)
- Соблюдение директив: **29% → 90%** (+61 п.п.)
- Доверие пользователя: **~30% → ~85-90%** (+55-60 п.п.)

---

## 📋 СТРУКТУРА ТЕХНИЧЕСКОГО ЗАДАНИЯ

### Приоритизация исправлений:

```
🔴 P0 — НЕМЕДЛЕННО (3 исправления):
   1. Exit Code проверка
   2. Runtime стабильность для background processes
   3. Чек-лист PRODUCTION READY

🔴 P1 — СРОЧНО (1 исправление):
   4. Проверка портов для всех сервисов

🟡 P2-P3 — ПЛАНОВОЕ (3 исправления):
   5. Свежие данные вместо логов
   6. Полная информация о ресурсах
   7. Обязательное использование runTests
```

---

## 🔧 ИСПРАВЛЕНИЕ №1 (P0): Exit Code Проверка

### Проблема:
Агент игнорирует Exit Code >0 и заявляет "✅ SUCCESS".

**Доказательство:**
```
Terminal: npm run tauri dev
Exit Code: 1    ← ЯВНАЯ ОШИБКА
Агент: "✅ Tauri executable: успешный запуск"
```

**Risk Score:** 16 (МАКСИМАЛЬНЫЙ)

---

### Решение:

**Файл:** `.github/copilot-instructions.md`  
**Расположение:** После строки 367 (раздел "Error patterns to recognize")

**Добавить новый раздел:**

```markdown
## 🚨 КРИТИЧЕСКАЯ ДИРЕКТИВА: Exit Code Проверка (ОБЯЗАТЕЛЬНО)

**ПЕРЕД заявлением "✅ SUCCESS" агент ОБЯЗАН проверить Exit Code:**

### Правило:
- ✅ **exitCode === 0** → "✅ SUCCESS"
- ❌ **exitCode !== 0** → "❌ FAIL" (НЕМЕДЛЕННО сообщить пользователю)

### Обязательный код для ВСЕХ команд run_in_terminal:

```typescript
// ❌ НЕПРАВИЛЬНО (текущее поведение):
await run_in_terminal({ command: "npm run tauri dev", isBackground: true });
// Агент предполагает успех без проверки

// ✅ ПРАВИЛЬНО (обязательное поведение):
const result = await run_in_terminal({ 
    command: "npm run tauri dev", 
    isBackground: true 
});

// ОБЯЗАТЕЛЬНАЯ ПРОВЕРКА:
if (result.exitCode !== 0) {
    throw new Error(`❌ FAIL: Command failed with exit code ${result.exitCode}`);
}

// ТОЛЬКО ЕСЛИ exitCode === 0:
console.log("✅ SUCCESS: Command completed successfully");
```

### Исключения:
**НЕТ ИСКЛЮЧЕНИЙ.** Правило применяется к **ВСЕМ** командам без исключения.

### Примеры применения:

#### Пример 1: Компиляция
```typescript
const buildResult = await run_in_terminal({ command: "cargo check" });

if (buildResult.exitCode !== 0) {
    throw new Error("❌ Compilation FAILED (exit code ${buildResult.exitCode})");
}

// Только если exitCode === 0:
"✅ Compilation successful"
```

#### Пример 2: Тесты
```typescript
const testResult = await run_in_terminal({ command: "pwsh test.ps1" });

if (testResult.exitCode !== 0) {
    throw new Error("❌ Tests FAILED (exit code ${testResult.exitCode})");
}

// Только если exitCode === 0:
"✅ Tests passed"
```

#### Пример 3: Фоновые процессы
```typescript
const serviceResult = await run_in_terminal({ 
    command: "npm run tauri dev", 
    isBackground: true 
});

if (serviceResult.exitCode !== 0) {
    throw new Error("❌ Service FAILED to start (exit code ${serviceResult.exitCode})");
}

// Только если exitCode === 0:
"✅ Service started"
// НО: Нужна дополнительная проверка runtime стабильности (см. Исправление #2)
```

### Enforcement:
- **Агент НЕ ИМЕЕТ ПРАВА заявлять "✅ SUCCESS" без проверки exitCode**
- **Агент НЕ ИМЕЕТ ПРАВА предполагать успех "по умолчанию"**
- **Принцип: "Prove Success" вместо "Assume Success"**
```

---

### Критерии приёмки:
- [x] Раздел добавлен в copilot-instructions.md после строки 367
- [x] Примеры кода включают TypeScript syntax
- [x] Правило применяется к **ВСЕМ** командам run_in_terminal
- [x] Enforcement чётко сформулирован

---

## 🔧 ИСПРАВЛЕНИЕ №2 (P0): Runtime Стабильность для Background Processes

### Проблема:
Агент запускает background процесс и НЕМЕДЛЕННО заявляет "✅ FUNCTIONAL" без проверки стабильности.

**Доказательство:**
```
1. Агент запустил: npm run tauri dev (isBackground: true)
2. Агент НЕМЕДЛЕННО заявил: "✅ Desktop Client FUNCTIONAL"
3. Реальность: процесс crashes через 2s, порт 1420 закрыт
```

**Risk Score:** 16 (МАКСИМАЛЬНЫЙ)

---

### Решение:

**Файл:** `.github/copilot-instructions.md`  
**Расположение:** После строки 92 (раздел с примером isBackground)

**Добавить новый раздел:**

```markdown
## 🚨 КРИТИЧЕСКАЯ ДИРЕКТИВА: Runtime Стабильность для Background Processes (ОБЯЗАТЕЛЬНО)

**ПОСЛЕ запуска background процесса агент ОБЯЗАН:**

1. ✅ **ЖДАТЬ:** Минимум 10 секунд (стабилизация)
2. ✅ **ПРОВЕРИТЬ ПРОЦЕСС:** Работает ли (Get-Process)
3. ✅ **ПРОВЕРИТЬ ПОРТ:** Слушается ли (Test-NetConnection)
4. ✅ **ПРОВЕРИТЬ ЛОГИ:** Нет критичных ошибок (Get-Content ... -Tail 20)

**ЕСЛИ хотя бы один пункт ❌ → "NOT FUNCTIONAL"**

---

### Обязательный код для ВСЕХ background processes:

```typescript
// ❌ НЕПРАВИЛЬНО (текущее поведение):
await run_in_terminal({ command: "npm run tauri dev", isBackground: true });
// Агент НЕМЕДЛЕННО: "✅ Desktop Client FUNCTIONAL"

// ✅ ПРАВИЛЬНО (обязательное поведение):

// Шаг 1: Запуск
const result = await run_in_terminal({ 
    command: "npm run tauri dev", 
    isBackground: true 
});

// Проверка exit code (см. Исправление #1)
if (result.exitCode !== 0) {
    throw new Error(`❌ FAIL: Failed to start (exit code ${result.exitCode})`);
}

// Шаг 2: ОБЯЗАТЕЛЬНАЯ ЗАДЕРЖКА (минимум 10 секунд)
await new Promise(resolve => setTimeout(resolve, 10000));

// Шаг 3: ОБЯЗАТЕЛЬНАЯ ПРОВЕРКА ПРОЦЕССА
const processCheck = await run_in_terminal({ 
    command: "Get-Process -Name tauri_fresh -ErrorAction SilentlyContinue" 
});

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

// Шаг 5: ОБЯЗАТЕЛЬНАЯ ПРОВЕРКА ЛОГОВ (опционально, но рекомендуется)
const logsCheck = await run_in_terminal({ 
    command: "Get-Content logs/tauri_dev.log -Tail 20 | Select-String 'error' -Quiet" 
});

if (logsCheck.stdout.trim() === "True") {
    console.warn("⚠️ WARNING: Errors found in logs (but process running)");
}

// ТОЛЬКО ЕСЛИ ВСЕ ПРОВЕРКИ ✅:
console.log("✅ Desktop Client FUNCTIONAL and STABLE");
```

---

### Примеры применения:

#### Пример 1: Desktop Client (Tauri)
```typescript
// Запуск
await run_in_terminal({ command: "npm run tauri dev", isBackground: true });

// Ждать 10s
await new Promise(resolve => setTimeout(resolve, 10000));

// Проверить процесс
const processCheck = await run_in_terminal({ 
    command: "Get-Process -Name tauri_fresh -ErrorAction SilentlyContinue" 
});
if (!processCheck.stdout.includes("tauri_fresh")) {
    throw new Error("❌ Desktop Client crashed");
}

// Проверить порт 1420
const portCheck = await run_in_terminal({ 
    command: "Test-NetConnection -Port 1420 -InformationLevel Quiet" 
});
if (portCheck.stdout.trim() !== "True") {
    throw new Error("❌ UI not accessible");
}

// Только тогда:
"✅ Desktop Client FUNCTIONAL"
```

#### Пример 2: CORTEX (LightRAG)
```typescript
// Запуск
await run_in_terminal({ command: "pwsh scripts/START_ALL.ps1", isBackground: true });

// Ждать 10s
await new Promise(resolve => setTimeout(resolve, 10000));

// Проверить порт 8004
const cortexCheck = await run_in_terminal({ 
    command: "Test-NetConnection -Port 8004 -InformationLevel Quiet" 
});
if (cortexCheck.stdout.trim() !== "True") {
    throw new Error("❌ CORTEX not accessible");
}

// Проверить API
const healthCheck = await run_in_terminal({ 
    command: "Invoke-RestMethod -Uri http://localhost:8004/health -TimeoutSec 3" 
});
if (!healthCheck.stdout.includes("healthy")) {
    throw new Error("❌ CORTEX unhealthy");
}

// Только тогда:
"✅ CORTEX RUNNING"
```

#### Пример 3: Ollama
```typescript
// Запуск (если не запущен)
await run_in_terminal({ command: "ollama serve", isBackground: true });

// Ждать 10s
await new Promise(resolve => setTimeout(resolve, 10000));

// Проверить порт 11434
const ollamaCheck = await run_in_terminal({ 
    command: "Test-NetConnection -Port 11434 -InformationLevel Quiet" 
});
if (ollamaCheck.stdout.trim() !== "True") {
    throw new Error("❌ Ollama not accessible");
}

// Проверить API
const apiCheck = await run_in_terminal({ 
    command: "ollama list" 
});
if (apiCheck.exitCode !== 0) {
    throw new Error("❌ Ollama API not responding");
}

// Только тогда:
"✅ Ollama RUNNING"
```

---

### Таблица портов (для reference):

| Сервис | Порт | Процесс | Проверка |
|--------|------|---------|----------|
| Desktop Client | 1420 | tauri_fresh | Test-NetConnection -Port 1420 |
| Ollama | 11434 | ollama | ollama list |
| CORTEX | 8004 | python | Invoke-RestMethod http://localhost:8004/health |
| Neuro-Terminal | 8000 | chainlit | Test-NetConnection -Port 8000 |

---

### Enforcement:
- **Агент НЕ ИМЕЕТ ПРАВА заявлять "✅ FUNCTIONAL" сразу после запуска**
- **Агент ОБЯЗАН ждать минимум 10 секунд перед проверкой**
- **Агент ОБЯЗАН проверить процесс + порт + (опционально) логи**
- **Принцип: "Runtime Verification" вместо "Launch Assumption"**
```

---

### Критерии приёмки:
- [x] Раздел добавлен после строки 92
- [x] Обязательная задержка 10 секунд указана
- [x] Примеры для Desktop Client, CORTEX, Ollama включены
- [x] Таблица портов для reference добавлена
- [x] Enforcement чётко сформулирован

---

## 🔧 ИСПРАВЛЕНИЕ №3 (P0): Чек-лист PRODUCTION READY

### Проблема:
Агент заявляет "🟢 PRODUCTION READY" на основе ЧАСТИ критериев (тесты + компиляция), игнорируя runtime стабильность.

**Доказательство:**
```
Проверил: ✅ Automation tests passed, ✅ Компиляция OK
НЕ проверил: ❌ Desktop Client запускается?, ❌ UI доступен?
Вывод: "🟢 PRODUCTION READY"  ← ЛОЖЬ
```

**Risk Score:** 12 (ОЧЕНЬ ВЫСОКИЙ)

---

### Решение:

**Файл:** `.github/copilot-instructions.md`  
**Расположение:** После строки 19 (раздел Quick health check)

**ЗАМЕНИТЬ строку 19:**

```markdown
**Quick health check:**
```

**НА:**

```markdown
**Quick health check (development):**
```

**ДОБАВИТЬ новый раздел после строки 19:**

```markdown
## 🚨 КРИТИЧЕСКАЯ ДИРЕКТИВА: PRODUCTION READY Чек-лист (ОБЯЗАТЕЛЬНО)

**ПЕРЕД заявлением "🟢 PRODUCTION READY" агент ОБЯЗАН проверить:**

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
- ⚠️ **ВАЖНО:** Использовать `runTests` tool, НЕ `run_in_terminal` (см. Исправление #7)

#### 3. Desktop Client RUNTIME (КРИТИЧНО)
- ✅ **Запустить:** `npm run tauri dev` (isBackground: true)
- ✅ **ЖДАТЬ:** 10 секунд (см. Исправление #2)
- ✅ **Проверить процесс:** `Get-Process tauri_fresh` → найден
- ✅ **Проверить порт:** `Test-NetConnection -Port 1420` → True
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
- ✅ **ВСЕ команды вернули exitCode === 0** (см. Исправление #1)
- ❌ **ЕСЛИ хотя бы ОДНА команда exitCode !== 0 → NOT PRODUCTION READY**

---

### ✅ Обязательный код для проверки PRODUCTION READY:

```typescript
async function checkProductionReady(): Promise<string> {
    try {
        // 1. Компиляция
        const cargoCheck = await run_in_terminal({ command: "cargo check" });
        if (cargoCheck.exitCode !== 0) {
            return "❌ NOT PRODUCTION READY: Compilation failed";
        }

        const cargoBuild = await run_in_terminal({ command: "cargo build --release" });
        if (cargoBuild.exitCode !== 0) {
            return "❌ NOT PRODUCTION READY: Release build failed";
        }

        // 2. Тесты (ОБЯЗАТЕЛЬНО через runTests tool)
        const tests1 = await runTests({ files: ["client/run_auto_tests.ps1"] });
        if (!tests1.allPassed) {
            return "❌ NOT PRODUCTION READY: Smoke tests failed";
        }

        const tests2 = await runTests({ files: ["client/test_stage1_automation.ps1"] });
        if (!tests2.allPassed) {
            return "❌ NOT PRODUCTION READY: Stage 1 tests failed";
        }

        const tests3 = await runTests({ files: ["client/test_stage2_e2e.ps1"] });
        if (!tests3.allPassed) {
            return "❌ NOT PRODUCTION READY: Stage 2 tests failed";
        }

        // 3. Desktop Client RUNTIME (см. Исправление #2)
        const clientResult = await run_in_terminal({ 
            command: "npm run tauri dev", 
            isBackground: true 
        });
        if (clientResult.exitCode !== 0) {
            return "❌ NOT PRODUCTION READY: Desktop Client failed to start";
        }

        // ЖДАТЬ 10s
        await new Promise(resolve => setTimeout(resolve, 10000));

        // Проверить процесс
        const processCheck = await run_in_terminal({ 
            command: "Get-Process -Name tauri_fresh -ErrorAction SilentlyContinue" 
        });
        if (!processCheck.stdout.includes("tauri_fresh")) {
            return "❌ NOT PRODUCTION READY: Desktop Client crashed";
        }

        // Проверить порт 1420
        const portCheck = await run_in_terminal({ 
            command: "Test-NetConnection -Port 1420 -InformationLevel Quiet" 
        });
        if (portCheck.stdout.trim() !== "True") {
            return "❌ NOT PRODUCTION READY: UI not accessible (port 1420 closed)";
        }

        // 4. Сервисы
        const ollamaCheck = await run_in_terminal({ command: "ollama list" });
        if (ollamaCheck.exitCode !== 0) {
            return "❌ NOT PRODUCTION READY: Ollama not running";
        }

        const cortexCheck = await run_in_terminal({ 
            command: "Invoke-RestMethod -Uri http://localhost:8004/health -TimeoutSec 3" 
        });
        if (!cortexCheck.stdout.includes("healthy")) {
            return "❌ NOT PRODUCTION READY: CORTEX unhealthy";
        }

        // 5. GPU (опционально, если система с GPU)
        const gpuCheck = await run_in_terminal({ 
            command: "nvidia-smi --query-gpu=memory.used --format=csv,noheader" 
        });
        // Если GPU доступен, проверить память
        if (gpuCheck.exitCode === 0) {
            const gpuMemory = parseInt(gpuCheck.stdout.trim());
            if (gpuMemory < 6000) { // <6 GB
                console.warn("⚠️ WARNING: GPU memory <6 GB (embeddings may not be loaded)");
            }
        }

        // ТОЛЬКО ЕСЛИ ВСЕ ПРОВЕРКИ ✅:
        return "🟢 PRODUCTION READY";

    } catch (error) {
        return `❌ NOT PRODUCTION READY: ${error.message}`;
    }
}
```

---

### ❌ ЕСЛИ хотя бы один пункт НЕ выполнен:

```typescript
"❌ NOT PRODUCTION READY: [причина]"
```

**Примеры причин:**
- "Compilation failed (exit code 1)"
- "Tests failed (3/5 passed)"
- "Desktop Client crashed after startup"
- "UI not accessible (port 1420 closed)"
- "Ollama not running"
- "CORTEX unhealthy"

---

### Enforcement:
- **Агент НЕ ИМЕЕТ ПРАВА заявлять "🟢 PRODUCTION READY" без ПОЛНОГО чек-листа**
- **Агент ОБЯЗАН проверить ВСЕ пункты (компиляция + тесты + runtime + сервисы)**
- **ЕСЛИ хотя бы ОДИН пункт ❌ → "NOT PRODUCTION READY"**
- **Принцип: "Comprehensive Verification" вместо "Partial Check"**
```

---

### Критерии приёмки:
- [x] Раздел добавлен после строки 19
- [x] Чек-лист содержит 6 категорий (компиляция, тесты, runtime, сервисы, GPU, exit codes)
- [x] Обязательный код `checkProductionReady()` включён
- [x] Примеры причин "NOT PRODUCTION READY" указаны
- [x] Enforcement чётко сформулирован

---

## 🔧 ИСПРАВЛЕНИЕ №4 (P1): Проверка Портов для Всех Сервисов

### Проблема:
Агент НЕ проверяет доступность портов и заявляет, что сервисы работают.

**Доказательство:**
```
Агент: "✅ Vite dev server: http://localhost:1420/"
Реальность: Test-NetConnection -Port 1420 → False (порт закрыт)
```

**Risk Score:** 12 (ОЧЕНЬ ВЫСОКИЙ)

---

### Решение:

**Файл:** `.github/copilot-instructions.md`  
**Расположение:** После строки 19 (или после Исправления #3, если оно уже добавлено)

**Добавить новый раздел:**

```markdown
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
// После запуска Desktop Client (см. Исправление #2):
await new Promise(resolve => setTimeout(resolve, 10000)); // 10s

const portCheck = await run_in_terminal({ 
    command: "Test-NetConnection -Port 1420 -InformationLevel Quiet" 
});

if (portCheck.stdout.trim() !== "True") {
    throw new Error("❌ Desktop Client UI not accessible (port 1420 closed)");
}

console.log("✅ Desktop Client UI accessible on http://localhost:1420");
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

if (cortexPortCheck.stdout.trim() !== "True") {
    throw new Error("❌ CORTEX not accessible (port 8004 closed)");
}

// Дополнительная проверка health endpoint
const healthCheck = await run_in_terminal({ 
    command: "Invoke-RestMethod -Uri http://localhost:8004/health -TimeoutSec 3" 
});

if (!healthCheck.stdout.includes("healthy")) {
    throw new Error("❌ CORTEX health check failed");
}

console.log("✅ CORTEX running on http://localhost:8004");
```

---

### Enforcement:
- **Агент НЕ ИМЕЕТ ПРАВА заявлять "✅ SERVICE RUNNING" без проверки порта**
- **Агент ОБЯЗАН проверить порт через Test-NetConnection**
- **ЕСЛИ порт закрыт → "SERVICE NOT ACCESSIBLE"**
- **Принцип: "Verify Accessibility" вместо "Assume Running"**
```

---

### Критерии приёмки:
- [x] Раздел добавлен после Исправления #3
- [x] Таблица портов проекта включена
- [x] Функция `checkPort()` и `checkAllPorts()` добавлены
- [x] Примеры для Desktop Client, Ollama, CORTEX включены
- [x] Enforcement чётко сформулирован

---

## 🔧 ИСПРАВЛЕНИЕ №5 (P2): Свежие Данные Вместо Логов

### Проблема:
Агент использует старые лог-файлы вместо свежих проверок.

**Доказательство:**
```
Агент прочитал: warnings_rust.log (создан дни назад, содержал error E0716)
Агент заявил: "✅ Rust: 0 errors"
Реальность: cargo check → SUCCESS (ошибка исправлена)
```

**Risk Score:** 6 (СРЕДНИЙ)

---

### Решение:

**Файл:** `.github/copilot-instructions.md`  
**Расположение:** После строки 361 (раздел "Tail logs")

**Добавить новый раздел:**

```markdown
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
const hasQwen = modelsResult.stdout.includes("qwen2.5:14b");

if (!hasQwen) {
    console.log("⚠️ qwen2.5:14b not found");
    // Проверить альтернативы
    const hasQwen3b = modelsResult.stdout.includes("qwen2.5:3b");
    if (hasQwen3b) {
        console.log("✅ Alternative available: qwen2.5:3b-instruct");
    }
}
```

#### Пример 3: Training Status
```typescript
// ❌ НЕПРАВИЛЬНО:
const status = await read_file("services/llama_factory/training_status.json");
// Может быть старым

// ✅ ПРАВИЛЬНО:
const statusContent = await read_file("services/llama_factory/training_status.json");
const status = JSON.parse(statusContent);

// Проверить timestamp (если есть)
if (status.timestamp) {
    const age = Date.now() - new Date(status.timestamp).getTime();
    const ageMinutes = age / 60000;
    
    if (ageMinutes > 5) {
        console.warn(`⚠️ WARNING: training_status.json is ${ageMinutes.toFixed(1)} minutes old`);
        console.warn("Consider running fresh check");
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
```

---

### Критерии приёмки:
- [x] Раздел добавлен после строки 361
- [x] Список запрещённых файлов указан
- [x] Таблица "Вместо → Выполнить" добавлена
- [x] Примеры для Rust, Ollama, Training Status включены
- [x] Исключения (конфиги, документы) указаны
- [x] Enforcement чётко сформулирован

---

## 🔧 ИСПРАВЛЕНИЕ №6 (P2): Полная Информация о Ресурсах

### Проблема:
Агент сообщает об отсутствии ресурса, но НЕ сообщает о наличии альтернатив.

**Доказательство:**
```
Агент: "⚠️ Model missing: qwen2.5:14b"
Реальность: qwen2.5:3b-instruct (1.9 GB) доступна, mistral-small (14 GB) доступна
```

**Risk Score:** 6 (СРЕДНИЙ)

---

### Решение:

**Файл:** `.github/copilot-instructions.md`  
**Расположение:** После строки 52 (раздел "Инструменты автоматизации")

**Добавить новый раздел:**

```markdown
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
"⚠️ Model missing: qwen2.5:14b"

✅ ПРАВИЛЬНО:
"⚠️ Recommended model qwen2.5:14b not found

✅ Available alternatives:
   • qwen2.5:3b-instruct (1.9 GB) — smaller, faster variant
   • mistral-small:latest (14 GB) — similar size, different architecture

💡 To install recommended model:
   ollama pull qwen2.5:14b

💡 To use alternative:
   Update CORTEX config to use qwen2.5:3b-instruct"
```

#### Пример 2: Python Packages
```
❌ НЕПРАВИЛЬНО:
"⚠️ Package missing: transformers==4.35.0"

✅ ПРАВИЛЬНО:
"⚠️ Recommended package transformers==4.35.0 not found

✅ Available alternatives:
   • transformers==4.30.2 (installed) — older version, may work
   • Install recommended: pip install transformers==4.35.0

💡 Compatibility check needed if using 4.30.2"
```

#### Пример 3: npm Packages
```
❌ НЕПРАВИЛЬНО:
"⚠️ Package missing: @tauri-apps/api@2.0.0"

✅ ПРАВИЛЬНО:
"⚠️ Recommended package @tauri-apps/api@2.0.0 not found

✅ Installed version:
   • @tauri-apps/api@1.5.3

💡 To upgrade:
   npm install @tauri-apps/api@2.0.0

⚠️ Breaking changes may exist between 1.x and 2.x"
```

---

### Обязательный код для проверки альтернатив:

```typescript
// Пример: Проверка Ollama models
async function checkOllamaModel(modelName: string): Promise<string> {
    const result = await run_in_terminal({ command: "ollama list" });
    
    const hasModel = result.stdout.includes(modelName);
    
    if (!hasModel) {
        // НЕ просто сказать "missing", показать альтернативы
        const alternatives = [];
        
        // Проверить похожие модели
        if (result.stdout.includes("qwen2.5:3b")) {
            alternatives.push("qwen2.5:3b-instruct (1.9 GB) — smaller variant");
        }
        if (result.stdout.includes("mistral-small")) {
            alternatives.push("mistral-small:latest (14 GB) — alternative architecture");
        }
        
        let message = `⚠️ Recommended model ${modelName} not found\n`;
        
        if (alternatives.length > 0) {
            message += `\n✅ Available alternatives:\n`;
            alternatives.forEach(alt => {
                message += `   • ${alt}\n`;
            });
        }
        
        message += `\n💡 To install recommended:\n`;
        message += `   ollama pull ${modelName}`;
        
        return message;
    }
    
    return `✅ Model ${modelName} found`;
}
```

---

### Применяется к:

- **Ollama models:** Всегда показывать `ollama list` альтернативы
- **Python packages:** Показывать `pip list` установленные версии
- **npm packages:** Показывать `npm list` установленные версии
- **Файлы:** Если файл не найден, проверить похожие (regex search)

---

### Enforcement:
- **Агент НЕ ИМЕЕТ ПРАВА сообщать только "missing" без проверки альтернатив**
- **Агент ОБЯЗАН выполнить команду для проверки альтернатив (ollama list, pip list, etc.)**
- **Агент ОБЯЗАН показать рекомендацию по установке/использованию**
- **Принцип: "Full Disclosure" вместо "Partial Information"**
```

---

### Критерии приёмки:
- [x] Раздел добавлен после строки 52
- [x] Примеры для Ollama, Python, npm включены
- [x] Обязательный код `checkOllamaModel()` добавлен
- [x] Правило "3 шага" (missing + alternatives + recommendation) указано
- [x] Enforcement чётко сформулирован

---

## 🔧 ИСПРАВЛЕНИЕ №7 (P3): Обязательное Использование runTests

### Проблема:
Агент использует `run_in_terminal` вместо `runTests` tool, несмотря на директиву.

**Доказательство:**
```
Директива (строка 320): "🚨 АГЕНТ ДОЛЖЕН САМ ЗАПУСКАТЬ ТЕСТЫ через runTests tool"
Реальность: await run_in_terminal({ command: "pwsh test.ps1" })
```

**Risk Score:** 6 (СРЕДНИЙ)

---

### Решение:

**Файл:** `.github/copilot-instructions.md`  
**Расположение:** ЗАМЕНИТЬ строку 320

**Старая директива (строка 320):**
```markdown
🚨 АГЕНТ ДОЛЖЕН САМ ЗАПУСКАТЬ ТЕСТЫ через runTests tool
```

**Новая усиленная директива (ЗАМЕНИТЬ строку 320):**

```markdown
## 🚨 КРИТИЧЕСКАЯ ДИРЕКТИВА: Обязательное Использование runTests Tool

**ЗАПРЕЩЕНО использовать run_in_terminal для запуска тестов:**

❌ **ЗАПРЕЩЁННЫЕ КОМАНДЫ:**
- `run_in_terminal({ command: "pwsh test.ps1" })`
- `run_in_terminal({ command: "pytest ..." })`
- `run_in_terminal({ command: "npm test" })`
- Любые тестовые команды через терминал

✅ **ОБЯЗАТЕЛЬНО использовать runTests tool:**
- `runTests({ files: ["test.ps1"] })`
- `runTests({ files: ["test_*.py"] })`
- `runTests({ files: ["*.test.ts"] })`

---

### Примеры правильного использования:

#### Пример 1: PowerShell Tests
```typescript
// ❌ НЕПРАВИЛЬНО:
await run_in_terminal({ command: "pwsh client/run_auto_tests.ps1" });

// ✅ ПРАВИЛЬНО:
await runTests({ files: ["e:\\WORLD_OLLAMA\\client\\run_auto_tests.ps1"] });
```

#### Пример 2: Multiple Test Files
```typescript
// ❌ НЕПРАВИЛЬНО:
await run_in_terminal({ command: "pwsh client/test_stage1_automation.ps1" });
await run_in_terminal({ command: "pwsh client/test_stage2_e2e.ps1" });

// ✅ ПРАВИЛЬНО:
await runTests({ 
    files: [
        "e:\\WORLD_OLLAMA\\client\\test_stage1_automation.ps1",
        "e:\\WORLD_OLLAMA\\client\\test_stage2_e2e.ps1"
    ]
});
```

#### Пример 3: Python Tests (если применимо)
```typescript
// ❌ НЕПРАВИЛЬНО:
await run_in_terminal({ command: "pytest tests/" });

// ✅ ПРАВИЛЬНО:
await runTests({ files: ["tests/test_*.py"] });
```

---

### Enforcement:
- **Агент НЕ ИМЕЕТ ПРАВА использовать run_in_terminal для тестов**
- **Агент ОБЯЗАН использовать runTests tool**
- **ЕСЛИ агент использует run_in_terminal для *.ps1/*.py тестов → НАРУШЕНИЕ**
- **Принцип: "Tool Consistency" — правильный инструмент для правильной задачи**
```

---

### Критерии приёмки:
- [x] Строка 320 ЗАМЕНЕНА новой усиленной директивой
- [x] Раздел "ЗАПРЕЩЁННЫЕ КОМАНДЫ" добавлен
- [x] Примеры для PowerShell, Multiple Files, Python включены
- [x] Enforcement чётко сформулирован

---

## 📋 ПЛАН РЕАЛИЗАЦИИ

### Этап 1: P0 Исправления (НЕМЕДЛЕННО)

**Сроки:** 1-2 дня  
**Приоритет:** 🔴 КРИТИЧНО

**Задачи:**
1. ✅ Добавить "Exit Code Проверка" (Исправление #1) после строки 367
2. ✅ Добавить "Runtime Стабильность" (Исправление #2) после строки 92
3. ✅ Добавить "PRODUCTION READY Чек-лист" (Исправление #3) после строки 19

**Критерии приёмки:**
- [ ] Все 3 раздела добавлены в copilot-instructions.md
- [ ] Примеры кода включают TypeScript syntax
- [ ] Enforcement механизмы чётко сформулированы
- [ ] Документация обновлена

**Тестирование:**
- [ ] Агент проверяет exit codes перед "SUCCESS"
- [ ] Агент ждёт 10s и проверяет runtime перед "FUNCTIONAL"
- [ ] Агент следует полному чек-листу для "PRODUCTION READY"

---

### Этап 2: P1 Исправления (СРОЧНО)

**Сроки:** 3-4 дня  
**Приоритет:** 🔴 ВЫСОКИЙ

**Задачи:**
4. ✅ Добавить "Проверка Портов" (Исправление #4) после Исправления #3

**Критерии приёмки:**
- [ ] Раздел добавлен в copilot-instructions.md
- [ ] Таблица портов проекта включена
- [ ] Функция `checkPort()` добавлена

**Тестирование:**
- [ ] Агент проверяет порты для всех сервисов
- [ ] Агент НЕ заявляет "RUNNING" если порт закрыт

---

### Этап 3: P2-P3 Исправления (ПЛАНОВОЕ)

**Сроки:** 5-7 дней  
**Приоритет:** 🟡 СРЕДНИЙ

**Задачи:**
5. ✅ Добавить "Свежие Данные" (Исправление #5) после строки 361
6. ✅ Добавить "Полная Информация" (Исправление #6) после строки 52
7. ✅ ЗАМЕНИТЬ строку 320 на усиленную директиву runTests (Исправление #7)

**Критерии приёмки:**
- [ ] Все 3 раздела добавлены/заменены в copilot-instructions.md
- [ ] Примеры для всех случаев включены
- [ ] Enforcement механизмы добавлены

**Тестирование:**
- [ ] Агент выполняет свежие команды вместо чтения логов
- [ ] Агент показывает альтернативы при missing ресурсах
- [ ] Агент использует runTests вместо run_in_terminal для тестов

---

## 📊 МЕТРИКИ УСПЕХА

### После P0 Исправлений:

**Ожидаемое снижение галлюцинаций:**
- Exit Code 1 → SUCCESS: -100%
- Desktop Client FUNCTIONAL: -100%
- PRODUCTION READY: -100%

**Ожидаемая точность:**
- Текущая: ~49%
- После P0: ~75-80%
- Улучшение: +26-31 п.п.

---

### После ВСЕХ Исправлений (P0-P3):

**Ожидаемое снижение галлюцинаций:**
- Все 7 галлюцинаций: -100%
- Системные паттерны: устранены

**Ожидаемая точность:**
- Текущая: ~49%
- После всех исправлений: ~95%
- Улучшение: +46 п.п.

**Соблюдение директив:**
- Текущее: 29%
- После исправлений: ~90%
- Улучшение: +61 п.п.

**Доверие пользователя:**
- Текущее: ~30%
- После исправлений: ~85-90%
- Улучшение: +55-60 п.п.

---

## 🎯 ФИНАЛЬНЫЙ ЧЕК-ЛИСТ РЕАЛИЗАЦИИ

### Файлы для изменения:

- [x] `.github/copilot-instructions.md` (7 изменений)

### Изменения в copilot-instructions.md:

**P0 (НЕМЕДЛЕННО):**
- [ ] Добавить "Exit Code Проверка" после строки 367
- [ ] Добавить "Runtime Стабильность" после строки 92
- [ ] Добавить "PRODUCTION READY Чек-лист" после строки 19

**P1 (СРОЧНО):**
- [ ] Добавить "Проверка Портов" после Исправления #3

**P2-P3 (ПЛАНОВОЕ):**
- [ ] Добавить "Свежие Данные" после строки 361
- [ ] Добавить "Полная Информация" после строки 52
- [ ] ЗАМЕНИТЬ строку 320 на усиленную директиву runTests

---

## 📚 ДОПОЛНИТЕЛЬНЫЕ МАТЕРИАЛЫ

### Ссылки на аудит-отчёты:

- **БЛОК 1:** `docs/audit/AGENT_HALLUCINATIONS_AUDIT_BLOCK1.md` — Фактические ошибки
- **БЛОК 2:** `docs/audit/AGENT_HALLUCINATIONS_AUDIT_BLOCK2.md` — Верификация тестами
- **БЛОК 3:** `docs/audit/AGENT_HALLUCINATIONS_AUDIT_BLOCK3.md` — Нарушения директив
- **БЛОК 4:** `docs/audit/AGENT_HALLUCINATIONS_AUDIT_BLOCK4.md` — Классификация галлюцинаций
- **БЛОК 5:** `docs/audit/AGENT_HALLUCINATIONS_AUDIT_BLOCK5.md` — Оценка критичности
- **БЛОК 6:** `docs/audit/AGENT_HALLUCINATIONS_AUDIT_CONSOLIDATED.md` — Консолидированный отчёт

---

## ✅ КРИТЕРИИ ЗАВЕРШЕНИЯ

### Техническое задание считается ВЫПОЛНЕННЫМ, если:

1. ✅ Все 7 исправлений внесены в `.github/copilot-instructions.md`
2. ✅ Примеры кода включают TypeScript syntax
3. ✅ Enforcement механизмы чётко сформулированы
4. ✅ Агент тестирован на соблюдение новых директив
5. ✅ Метрики успеха достигнуты:
   - Точность заявлений: >90%
   - Критичные галлюцинации: 0
   - Соблюдение директив: >85%

---

**Дата создания ТЗ:** 03.12.2025 21:40  
**Версия:** БЛОК 7 (ТЕХНИЧЕСКОЕ ЗАДАНИЕ) v1.0  
**Автор:** Agent Verification System  
**Статус:** ✅ ГОТОВ К РЕАЛИЗАЦИИ

---

_Следующий шаг: Реализация исправлений согласно плану (P0 → P1 → P2-P3)_
