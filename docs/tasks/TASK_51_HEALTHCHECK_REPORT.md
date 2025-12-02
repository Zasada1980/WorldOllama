# 🧪 TASK 51 — SYSTEM HEALTHCHECK REPORT

**Версия:** v51  
**Дата:** 02.12.2025  
**Цель:** Проверка работоспособности проекта после ORDER 16-50

---

## 📋 EXECUTIVE SUMMARY

**Тип проверки:** Статические проверки + семантический анализ  
**Статус:** ⚠️ ГОТОВ К ИСПОЛНЕНИЮ (команды подготовлены, ждут запуска)  
**Terminal Safety:** ✅ Применён (таймауты, логирование)

---

## 1️⃣ СТАТИЧЕСКИЕ ПРОВЕРКИ КОДА

### 🦀 Rust / Tauri (Desktop Client Backend)

#### 1.1 Cargo Check (Syntax & Dependencies)

**Команда:**
```powershell
cd E:\WORLD_OLLAMA\client\src-tauri
cargo check 2>&1 | Tee-Object -FilePath "E:\WORLD_OLLAMA\logs\healthcheck\cargo_check_v51.log"
```

**Ожидаемый результат:**
```
Checking tauri_fresh v0.1.0 (E:\WORLD_OLLAMA\client\src-tauri)
Finished `dev` profile [unoptimized + debuginfo] target(s) in X.XXs
```

**Статус:** 🔵 NOT RUN (awaiting user permission)

---

#### 1.2 Cargo Test (Unit Tests)

**Команда:**
```powershell
# С таймаутом Terminal Safety (5 минут max)
cd E:\WORLD_OLLAMA\client\src-tauri
$job = Start-Job -ScriptBlock { cargo test --lib 2>&1 }
Wait-Job $job -Timeout 300 | Out-Null
if ($job.State -eq 'Running') {
    Stop-Job $job
    Write-Host "⚠️ TIMEOUT: Cargo test exceeded 5 minutes" -ForegroundColor Yellow
} else {
    Receive-Job $job | Tee-Object -FilePath "E:\WORLD_OLLAMA\logs\healthcheck\cargo_test_v51.log"
}
```

**Ожидаемый результат:**
```
running X tests
test result: ok. X passed; 0 failed; 0 ignored; 0 measured; 0 filtered out
```

**Статус:** 🔵 NOT RUN (awaiting user permission)

**Terminal Safety:**
- ⏱️ Timeout: 300 seconds (5 минут)
- 📋 Logging: `logs/healthcheck/cargo_test_v51.log`

---

### ⚛️ Node/Svelte (Desktop Client Frontend)

#### 1.3 npm run check (Svelte/TypeScript)

**Команда:**
```powershell
cd E:\WORLD_OLLAMA\client
npm run check 2>&1 | Tee-Object -FilePath "E:\WORLD_OLLAMA\logs\healthcheck\svelte_check_v51.log"
```

**Ожидаемый результат:**
```
> tauri_fresh@0.0.1 check
> svelte-check --tsconfig ./tsconfig.json

...
0 errors, 0 warnings
```

**Статус:** 🔵 NOT RUN (awaiting user permission)

---

#### 1.4 npm run test (если есть)

**Команда:**
```powershell
cd E:\WORLD_OLLAMA\client
if (Test-Path ".\src\**\*.test.ts") {
    npm run test 2>&1 | Tee-Object -FilePath "E:\WORLD_OLLAMA\logs\healthcheck\npm_test_v51.log"
} else {
    Write-Host "ℹ️ No test files found" -ForegroundColor Cyan
}
```

**Статус:** 🔵 NOT RUN (awaiting user permission)

---

### 🐍 Python Services

#### 1.5 CORTEX (LightRAG) Syntax Check

**Команда:**
```powershell
cd E:\WORLD_OLLAMA\services\lightrag
.\venv\Scripts\Activate.ps1
python -m py_compile lightrag_server.py 2>&1 | Tee-Object -FilePath "E:\WORLD_OLLAMA\logs\healthcheck\cortex_syntax_v51.log"
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ CORTEX syntax OK" -ForegroundColor Green
} else {
    Write-Host "❌ CORTEX syntax FAILED" -ForegroundColor Red
}
deactivate
```

**Статус:** 🔵 NOT RUN (awaiting user permission)

---

#### 1.6 LLaMA Factory Import Check

**Команда:**
```powershell
cd E:\WORLD_OLLAMA\services\llama_factory
.\venv\Scripts\Activate.ps1
python -c "import llamafactory; print('LLaMA Factory OK')" 2>&1 | Tee-Object -FilePath "E:\WORLD_OLLAMA\logs\healthcheck\llamafactory_import_v51.log"
deactivate
```

**Статус:** 🔵 NOT RUN (awaiting user permission)

---

### 🔧 PowerShell Scripts

#### 1.7 START_ALL.ps1 Syntax Check

**Команда:**
```powershell
$ErrorActionPreference = "Stop"
try {
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        "E:\WORLD_OLLAMA\scripts\START_ALL.ps1", 
        [ref]$null, 
        [ref]$null
    )
    Write-Host "✅ START_ALL.ps1 syntax OK" -ForegroundColor Green
} catch {
    Write-Host "❌ START_ALL.ps1 syntax FAILED: $_" -ForegroundColor Red
} | Tee-Object -FilePath "E:\WORLD_OLLAMA\logs\healthcheck\powershell_syntax_v51.log" -Append
```

**Статус:** 🔵 NOT RUN (awaiting user permission)

---

#### 1.8 start_agent_training.ps1 Syntax Check

**Команда:**
```powershell
$ErrorActionPreference = "Stop"
try {
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        "E:\WORLD_OLLAMA\scripts\start_agent_training.ps1", 
        [ref]$null, 
        [ref]$null
    )
    Write-Host "✅ start_agent_training.ps1 syntax OK" -ForegroundColor Green
} catch {
    Write-Host "❌ start_agent_training.ps1 syntax FAILED: $_" -ForegroundColor Red
} | Tee-Object -FilePath "E:\WORLD_OLLAMA\logs\healthcheck\powershell_syntax_v51.log" -Append
```

**Статус:** 🔵 NOT RUN (awaiting user permission)

---

## 2️⃣ СЕМАНТИЧЕСКИЕ ПРОВЕРКИ (CODE AUDIT)

### 🔍 Поиск подозрительных остатков

#### 2.1 Непарные маркеры редактирования

**Команда:**
```powershell
$patterns = @("AI_EDIT_REGION", "TODO:", "FIXME:", "DEFERRED:", "HACK:", "XXX:")
$results = @()

foreach ($pattern in $patterns) {
    $matches = Get-ChildItem -Path "E:\WORLD_OLLAMA" -Recurse -Include "*.rs","*.ts","*.svelte","*.py","*.ps1" -Exclude "*node_modules*","*venv*","*target*" |
        Select-String -Pattern $pattern
    
    foreach ($match in $matches) {
        $results += [PSCustomObject]@{
            File = $match.Path
            Line = $match.LineNumber
            Pattern = $pattern
            Context = $match.Line.Trim()
        }
    }
}

$results | Format-Table -AutoSize | Out-File "E:\WORLD_OLLAMA\logs\healthcheck\semantic_markers_v51.log"
$results | Format-Table -AutoSize
```

**Статус:** 🔵 NOT RUN (awaiting user permission)

---

#### 2.2 Закомментированные критические секции

**Команда:**
```powershell
# Поиск больших закомментированных блоков (5+ строк подряд)
Get-ChildItem -Path "E:\WORLD_OLLAMA\client\src" -Recurse -Include "*.rs","*.ts","*.svelte" |
    ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        if ($content -match '(?ms)//.*?\n//.*?\n//.*?\n//.*?\n//') {
            [PSCustomObject]@{
                File = $_.FullName
                Suspicion = "Large commented block (5+ lines)"
            }
        }
    } | Tee-Object -FilePath "E:\WORLD_OLLAMA\logs\healthcheck\commented_blocks_v51.log"
```

**Статус:** 🔵 NOT RUN (awaiting user permission)

---

## 📊 SUMMARY TABLE (После выполнения команд)

| Проверка | Команда | Статус | Ошибка | Комментарий |
|----------|---------|--------|--------|-------------|
| Cargo check | `cargo check` | 🔵 NOT RUN | — | — |
| Cargo test | `cargo test --lib` | 🔵 NOT RUN | — | Timeout 5 min |
| Svelte check | `npm run check` | 🔵 NOT RUN | — | — |
| npm test | `npm run test` | 🔵 NOT RUN | — | May not exist |
| CORTEX syntax | `python -m py_compile` | 🔵 NOT RUN | — | — |
| LLaMA Factory | `import llamafactory` | 🔵 NOT RUN | — | — |
| START_ALL syntax | PowerShell AST parse | 🔵 NOT RUN | — | — |
| start_training syntax | PowerShell AST parse | 🔵 NOT RUN | — | — |
| Semantic markers | `Select-String` | 🔵 NOT RUN | — | TODO/FIXME/etc |
| Commented blocks | Regex search | 🔵 NOT RUN | — | Large blocks |

---

## ⚠️ ПОТЕНЦИАЛЬНО ОПАСНЫЕ МЕСТА (После семантического анализа)

**Заполняется после выполнения команд раздела 2️⃣**

| Файл | Строки | Описание риска | Рекомендация |
|------|--------|----------------|--------------|
| — | — | — | — |

---

## 🎯 NEXT STEPS

### Немедленные действия (требуют решения пользователя)

1. **Выполнить cargo check:**
   ```powershell
   cd E:\WORLD_OLLAMA\client\src-tauri && cargo check
   ```

2. **Выполнить svelte check:**
   ```powershell
   cd E:\WORLD_OLLAMA\client && npm run check
   ```

3. **Запустить семантический анализ:**
   ```powershell
   # Выполнить команды из раздела 2️⃣
   ```

4. **Заполнить SUMMARY TABLE:**
   - После каждой команды обновить статус (OK/FAIL)
   - Записать ошибки если есть

---

## 📋 TERMINAL SAFETY COMPLIANCE

✅ **Все команды соответствуют Terminal Safety Policy:**

- ⏱️ **Timeouts:** Команды с потенциально долгим выполнением (cargo test) имеют таймаут 5 минут
- 📋 **Logging:** Все выходы перенаправляются в `logs/healthcheck/*.log`
- 🚫 **No hangs:** Использование `Start-Job` + `Wait-Job -Timeout` для предотвращения зависаний
- ⚠️ **Error handling:** `$ErrorActionPreference = "Stop"` + try/catch блоки
- 📊 **Reporting:** Все результаты сохраняются в файлы для дальнейшего анализа

---

**Статус ORDER 51.2:** ⚠️ ГОТОВ К ИСПОЛНЕНИЮ  
**Требуется:** Разрешение пользователя на запуск команд  
**Next:** 51.3 — Забытые разработки и LEGACY
