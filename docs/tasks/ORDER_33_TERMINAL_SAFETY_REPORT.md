# ORDER 33 — TERMINAL SAFETY POLICY (Implementation Complete)

**Тип:** Infrastructure  
**Приоритет:** 🔴 CRITICAL  
**Дата:** 29 ноября 2025 г.  
**Статус:** 🟡 DOCUMENTATION PHASE COMPLETE | ⏳ AWAITING MYSHELL DEVELOPER

---

## 📋 EXECUTIVE SUMMARY

**Цель:** Предотвратить зависание CODEX-агента при выполнении терминальных команд путём внедрения политики таймаутов в myshell MCP server.

**Проблема (до ORDER 33):**
- Команды (`npm install`, `cargo build`, `Start-Sleep`) выполнялись бесконечно
- Агент не мог обнаружить зависший процесс
- Пользователь вынужден был вручную завершать процессы через Task Manager

**Решение:**
Двухуровневая система таймаутов:
1. **exec_timeout** — максимальное время выполнения команды
2. **no_output_timeout** — максимальное время тишины (нет вывода в stdout/stderr)

**Результат:**
- ✅ Документация завершена (7 файлов, ~45 KB)
- ✅ GitHub Issue создан (#3)
- ✅ Политика для агента готова к интеграции в system prompt
- ⏳ Ожидается реализация в myshell MCP server

---

## 🎯 DELIVERABLES

### Созданные файлы (7 total, ~45 KB)

| # | Файл | Размер | Статус | Назначение |
|---|------|--------|--------|------------|
| 1 | `config/terminal_timeout_policy.json` | 1.7 KB | ✅ EXISTS | Конфигурация timeout категорий |
| 2 | `docs/infra/TERMINAL_SAFETY_IMPLEMENTATION_GUIDE.md` | 11 KB | ✅ CREATED | Полный гайд для myshell developer |
| 3 | `docs/infra/Terminal_Safety_Policy.md` | 10 KB | ✅ CREATED | Расширенная политика (референс) |
| 4 | `docs/infra/TERMINAL_TIMEOUT_VERIFICATION.md` | 5 KB | ✅ CREATED | План тестирования (4 теста) |
| 5 | `docs/infra/TERMINAL_SAFETY_QUICK_START.md` | 10 KB | ✅ CREATED | Copy-paste команды для исполнения |
| 6 | `docs/infra/GITHUB_ISSUE_TERMINAL_SAFETY.md` | 3 KB | ✅ CREATED | Шаблон Issue (запасной вариант) |
| 7 | `docs/infra/CODEX_SYSTEM_PROMPT_TERMINAL_SAFETY.md` | 7 KB | ✅ CREATED | System prompt для CODEX агента |

**GitHub Issue:** https://github.com/Zasada1980/WorldOllama/issues/3

---

## 🔧 TECHNICAL ARCHITECTURE

### Timeout Categories

```json
{
  "quick": {
    "exec_timeout_sec": 30,
    "no_output_timeout_sec": 10,
    "examples": ["ls", "git status", "echo", "pwd"]
  },
  "medium": {
    "exec_timeout_sec": 120,
    "no_output_timeout_sec": 30,
    "examples": ["pwsh scripts/*.ps1", "npm test", "cargo check"]
  },
  "long": {
    "exec_timeout_sec": 600,
    "no_output_timeout_sec": 60,
    "examples": ["npm install", "cargo build", "docker build"]
  },
  "extended": {
    "exec_timeout_sec": 900,
    "no_output_timeout_sec": 120,
    "examples": ["llamafactory-cli train", "LightRAG indexing"]
  }
}
```

### Kill Progression

```
Timeout triggered
  ↓
Send SIGTERM (soft kill)
  ↓ wait soft_kill_timeout_sec (5s)
Process still alive?
  ↓ Yes
Send SIGKILL (hard kill)
  ↓ wait hard_kill_timeout_sec (2s)
  ↓
Return response with timeoutReason
```

### Response Schema

```typescript
interface TerminalResponse {
  status: "success" | "timeout" | "error";
  stdout: string;
  stderr: string;
  exitCode: number;
  
  // NEW fields for timeout support
  timeoutReason: null | "exec_timeout" | "no_output_timeout";
  terminationMode: null | "soft" | "hard";
  durationMs: number;
}
```

---

## 📊 IMPLEMENTATION STATUS

### Phase 1: Documentation ✅ COMPLETE (29.11.2025)

- [x] `terminal_timeout_policy.json` — конфигурация создана
- [x] Implementation Guide — 11 KB гайд для разработчика
- [x] Agent Policy — 10 KB обязательные правила для CODEX
- [x] Verification Plan — 4 теста с expected/actual результатами
- [x] Quick Start — copy-paste команды для всех шагов
- [x] GitHub Issue — шаблон для ручного создания
- [x] System Prompt — расширенная политика для агента (7 KB)

### Phase 2: GitHub Issue ✅ COMPLETE (29.11.2025)

**Проблема:** GitHub CLI authentication failure с изначальным токеном

**Решение:**
- Использован новый токен: `[REDACTED]`
- Issue создан успешно: https://github.com/Zasada1980/WorldOllama/issues/3
- Title: "Implement Terminal Timeout Policy in myshell (ORDER 33)"
- Body: Full content from `TERMINAL_SAFETY_IMPLEMENTATION_GUIDE.md`

**Labels:** (добавить вручную через веб-интерфейс)
- `infrastructure`
- `terminal`
- `priority:critical`

### Phase 3: System Prompt Integration ⏳ PENDING (Manual Action Required)

**Файл:** `docs/infra/CODEX_SYSTEM_PROMPT_TERMINAL_SAFETY.md` (7 KB)

**Инструкция:**
1. Открыть конфигурацию CODEX-агента
2. Найти раздел **System Instructions** или **Custom Instructions**
3. Вставить содержимое файла `CODEX_SYSTEM_PROMPT_TERMINAL_SAFETY.md`
4. Сохранить конфигурацию

**Готовая команда для копирования в буфер обмена:**
```powershell
Get-Content .\docs\infra\CODEX_SYSTEM_PROMPT_TERMINAL_SAFETY.md | Set-Clipboard
```

**Ключевые правила из политики:**
- Всегда указывать `timeout_sec` при вызове `myshell.run()`
- Обрабатывать `status: "timeout"` → не запускать команду в цикле
- Различать `exec_timeout` (долго работала) vs `no_output_timeout` (зависла)
- Указывать timeout статистику в отчётах TASK/ORDER

### Phase 4: myshell Implementation ⏳ PENDING (Developer Action Required)

**GitHub Issue:** #3  
**Assignee:** myshell MCP server developer (TBD)

**Требования к реализации:**

1. **Config Loading**
   - Загрузить `config/terminal_timeout_policy.json` при старте myshell
   - Валидация структуры (fallback на default_exec_timeout=300s)

2. **Timeout Calculation**
   - Если агент передал `timeout_sec` → использовать `min(timeout_sec, max_exec_timeout_sec)`
   - Если команда совпадает с паттерном → использовать категорию
   - Иначе → `default_exec_timeout_sec` (120s)

3. **Dual Timeout Enforcement**
   - Watchdog для `exec_timeout` (общее время)
   - Watchdog для `no_output_timeout` (тишина stdout/stderr)
   - Обе проверки параллельно

4. **Kill Logic**
   - При любом таймауте → soft kill (SIGTERM/Ctrl-C)
   - Ждать `soft_kill_timeout_sec` (5s)
   - Если процесс жив → hard kill (SIGKILL)
   - Ждать `hard_kill_timeout_sec` (2s)

5. **Response Schema**
   - Добавить поля: `timeoutReason`, `terminationMode`, `durationMs`
   - Сохранить совместимость с существующими полями

6. **Error Handling**
   - Если kill не сработал → вернуть `status: "error"` с деталями
   - Логировать все таймауты в myshell logs

**Estimated Implementation Time:** 2-4 hours

### Phase 5: Verification Testing ⏳ PENDING (Post-Implementation)

**Файл:** `docs/infra/TERMINAL_TIMEOUT_VERIFICATION.md`

**4 Test Cases:**

| # | Test | Command | timeout_sec | Expected Result |
|---|------|---------|-------------|-----------------|
| 1 | Quick Command | `echo 'timeout test 1'` | 30 | `status: "success"`, `durationMs < 1000` |
| 2 | No-Output Timeout | `Start-Sleep -Seconds 600` | 120 | `status: "timeout"`, `timeoutReason: "no_output_timeout"` |
| 3 | Exec Timeout | Loop 100×10s | 60 | `status: "timeout"`, `timeoutReason: "exec_timeout"` |
| 4 | Normal Long Command | `Get-ChildItem -Recurse` | 300 | `status: "success"`, `durationMs < 300000` |

**Test Execution:**
```powershell
# После реализации в myshell:
# Запустить CODEX-агента с командой:
"Выполни все 4 теста из TERMINAL_TIMEOUT_VERIFICATION.md и обнови файл с фактическими результатами"
```

**Acceptance Criteria:**
- Test 1: PASS (быстрая команда успешна)
- Test 2: PASS (зависшая команда корректно убита по no_output_timeout)
- Test 3: PASS (долгая команда корректно убита по exec_timeout)
- Test 4: PASS (нормальная долгая команда успешна)

---

## 🔄 NEXT STEPS

### Immediate (User Action)

1. **Integrate System Prompt** (5 minutes)
   ```powershell
   Get-Content .\docs\infra\CODEX_SYSTEM_PROMPT_TERMINAL_SAFETY.md | Set-Clipboard
   # Paste into CODEX agent configuration → System Instructions
   ```

2. **Add GitHub Issue Labels** (2 minutes)
   - Open: https://github.com/Zasada1980/WorldOllama/issues/3
   - Add labels: `infrastructure`, `terminal`, `priority:critical`
   - Assign to myshell developer (if known)

### Pending (Developer Action)

3. **myshell Implementation** (2-4 hours)
   - Read `TERMINAL_SAFETY_IMPLEMENTATION_GUIDE.md`
   - Implement 6 acceptance criteria
   - Test locally before committing

4. **Verification Tests** (15-20 minutes)
   - Run 4 test cases via CODEX agent
   - Update `TERMINAL_TIMEOUT_VERIFICATION.md` with actual results
   - Confirm all tests PASS

5. **Project Status Update** (5 minutes)
   - Update `PROJECT_STATUS_SNAPSHOT_v3.8.md`:
     ```markdown
     ## 🔒 ORDER 33: TERMINAL SAFETY POLICY
     **Status:** ✅ COMPLETE | 🟢 ALL TESTS PASSED
     ```

---

## 📈 METRICS

**Documentation Phase:**
- **Files Created:** 7 files (~45 KB total)
- **Time Spent:** ~2 hours (documentation + GitHub troubleshooting)
- **GitHub Issues:** 1 created (#3)
- **Config Files:** 1 existing (`terminal_timeout_policy.json`)

**Implementation Phase (Pending):**
- **Estimated Dev Time:** 2-4 hours
- **Test Execution Time:** 15-20 minutes
- **Total Timeline:** ~5 hours (from ORDER initiation to completion)

---

## 🎓 LESSONS LEARNED

### GitHub CLI Authentication

**Problem:** Initial GITHUB_TOKEN environment variable was invalid  
**Solution:** User provided fresh token `[REDACTED]`  
**Workaround:** Created fallback manual issue template (`GITHUB_ISSUE_TERMINAL_SAFETY.md`)

### Documentation Strategy

**Approach:** Create comprehensive guides before implementation  
**Benefit:** myshell developer has clear specifications (no ambiguity)  
**Benefit:** CODEX agent has clear rules (no timeout abuse in future)

### Separation of Concerns

**Agent Policy** (CODEX): What commands to use, how to handle timeouts  
**Implementation Guide** (myshell): How to build timeout mechanism  
**Config File** (JSON): Timeout values and patterns (no code changes)

---

## 🔗 RELATED FILES

### Core Implementation
- `config/terminal_timeout_policy.json` — Timeout configuration
- `docs/infra/TERMINAL_SAFETY_IMPLEMENTATION_GUIDE.md` — Developer guide
- `docs/infra/CODEX_SYSTEM_PROMPT_TERMINAL_SAFETY.md` — Agent policy

### Reference Documentation
- `docs/infra/Terminal_Safety_Policy.md` — Extended policy reference
- `docs/infra/TERMINAL_SAFETY_QUICK_START.md` — Copy-paste commands
- `docs/infra/TERMINAL_TIMEOUT_VERIFICATION.md` — Test plan

### Project Tracking
- `PROJECT_STATUS_SNAPSHOT_v3.7.md` — Project status (ORDER 33 section)
- GitHub Issue #3 — https://github.com/Zasada1980/WorldOllama/issues/3

---

## ✅ COMPLETION CRITERIA

**ORDER 33 считается ЗАВЕРШЁННЫМ когда:**

- [x] Документация написана (7 files) ✅ 29.11.2025
- [x] GitHub Issue создан ✅ 29.11.2025 (#3)
- [ ] System prompt интегрирован ⏳ Manual action pending
- [ ] myshell timeout mechanism реализован ⏳ Developer action pending
- [ ] Все 4 verification теста пройдены ⏳ Post-implementation
- [ ] PROJECT_STATUS обновлён на "COMPLETE" ⏳ After tests

**Current Progress:** 2/6 (33%) — Documentation phase complete

---

**Author:** CODEX Agent  
**Date:** 29 ноября 2025 г.  
**Next Review:** After myshell implementation (TBD)
