# КОМАНДНЫЙ ОРДЕР №19-VERIFY-v0.2.0

**Дата выдачи:** 28 ноября 2025 г.  
**Приоритет:** 🔴 CRITICAL  
**Статус:** 🟡 PENDING EXECUTION  
**Цель:** Перевести v0.2.0-rc1 из "Static Fire Readiness" в "v0.2.0 RELEASED"

---

## EXECUTIVE SUMMARY

**Constraint:** НЕ добавлять новых фич. Только верификация существующего кода.

**Success Criteria:**
1. ✅ Compilation: 0 errors (Rust + TypeScript)
2. ✅ E2E Tests: PULSE-1 + GIT-1 pass
3. ✅ GitHub Release v0.2.0 created
4. ✅ Documentation updated (STATUS, README, Handover)

---

## 🛠️ КОМАНДА 1: V0.2.0 TOOLCHAIN & BUILD ENV

**Приоритет:** 🔴 CRITICAL  
**Estimated Time:** 30 минут

### Задачи

#### 1.1 Установка Rust Toolchain (Windows MSVC)

```powershell
# Download rustup-init.exe
# URL: https://rustup.rs/

# Run installer
.\rustup-init.exe

# Select:
# 1) Proceed with installation (default)

# Verify installation
rustc --version
cargo --version

# Expected output:
# rustc 1.75.0+ (или новее)
# cargo 1.75.0+ (или новее)
```

#### 1.2 Проверка Node/Svelte окружения

```powershell
# Verify Node.js
node --version   # Expected: v20+

# Verify npm
npm --version    # Expected: 10+

# Navigate to client
cd E:\WORLD_OLLAMA\client

# Install dependencies (if not done)
npm install

# Verify SvelteKit
npm list @sveltejs/kit
# Expected: 2.x (SvelteKit 5)
```

#### 1.3 Документирование окружения

**Создать:** `E:\WORLD_OLLAMA\BUILD_ENVIRONMENT.md`

**Содержание:**
```markdown
# Build Environment — WORLD_OLLAMA v0.2.0

**Дата:** 28 ноября 2025 г.  
**OS:** Windows 10/11 (64-bit)

## Toolchain Versions

### Rust
- **rustc:** 1.75.0 (или указать фактическую версию)
- **cargo:** 1.75.0
- **Target:** x86_64-pc-windows-msvc

### Node.js / JavaScript
- **Node.js:** v20.10.0
- **npm:** 10.2.3
- **SvelteKit:** 2.0.0
- **Tauri CLI:** 2.0.0

### Python (Services)
- **Python:** 3.11.5
- **LLaMA Factory:** Custom fork
- **LightRAG:** v1.4.9.8

## System Requirements (минимальные)

- **RAM:** 16 GB (рекомендуется 32 GB)
- **VRAM:** 12 GB (для qwen2.5:14b + training)
- **Disk:** 50 GB свободного места
- **Ports:** 11434, 8004, 8501 (свободны)

## Verification Commands

```powershell
# Rust
rustc --version && cargo --version

# Node
node --version && npm --version

# Python
python --version

# Ollama
ollama --version
```
```

#### 1.4 Обновление README (System Requirements)

**Файл:** `E:\WORLD_OLLAMA\README.md`

**Добавить секцию:**
```markdown
## 📋 System Requirements

### Minimum
- **OS:** Windows 10/11 (64-bit)
- **RAM:** 16 GB
- **VRAM:** 12 GB (NVIDIA GPU recommended)
- **Disk:** 50 GB free space

### Toolchain
- **Rust:** 1.75+ (https://rustup.rs/)
- **Node.js:** v20+ (https://nodejs.org/)
- **Python:** 3.11+
- **Ollama:** Latest (https://ollama.ai/)

### Build Environment
See [BUILD_ENVIRONMENT.md](BUILD_ENVIRONMENT.md) for detailed version info.
```

### Критерий завершения КОМАНДЫ 1

- ✅ `rustup` установлен, `cargo check` доступен
- ✅ `BUILD_ENVIRONMENT.md` создан с фактическими версиями
- ✅ README обновлен (System Requirements)
- ✅ Любой разработчик может воспроизвести окружение

---

## 🧪 КОМАНДА 2: КОМПИЛЯЦИЯ + E2E v0.2.0

**Приоритет:** 🔴 BLOCKING GATE  
**Estimated Time:** 1-2 часа

### 2.1 Компиляция

#### 2.1.1 Rust Backend

```powershell
cd E:\WORLD_OLLAMA\client\src-tauri

# Syntax check (no build)
cargo check

# Expected output:
#    Checking tauri_fresh v0.1.0
#    Finished `dev` profile [unoptimized + debuginfo] target(s) in X.XXs

# If warnings → fix or document in COMPILATION_REPORT
```

**Возможные проблемы:**
- Missing dependencies → `cargo fetch`
- MSVC not found → install Visual Studio Build Tools
- Linker errors → check Windows SDK

#### 2.1.2 Frontend

```powershell
cd E:\WORLD_OLLAMA\client

# Install deps (if stale)
npm install

# TypeScript/Svelte check
npm run check

# Expected output:
# 0 errors, 0 warnings
```

**Возможные проблемы:**
- TS errors → check `TrainingPanel.svelte`, `GitPanel.svelte`
- Svelte syntax errors → unlikely (статический анализ clean)

#### 2.1.3 Создать TASK_19_COMPILATION_REPORT.md

**Template:**

```markdown
# TASK 19: Compilation Report — v0.2.0

**Дата:** [DATE]  
**Executor:** [NAME]  
**Status:** ✅ PASS / ❌ FAIL

## Rust Backend (cargo check)

**Command:**
```powershell
cd E:\WORLD_OLLAMA\client\src-tauri
cargo check
```

**Output:**
```
[PASTE ACTUAL OUTPUT]
```

**Result:** ✅ 0 errors, X warnings (list below if any)

**Warnings:**
- [List any warnings here]

## Frontend (npm run check)

**Command:**
```powershell
cd E:\WORLD_OLLAMA\client
npm run check
```

**Output:**
```
[PASTE ACTUAL OUTPUT]
```

**Result:** ✅ 0 errors

## Fixes Applied (if any)

- [None] or [List fixes]

## Conclusion

✅ v0.2.0-rc1 compiles cleanly. Ready for E2E testing.
```

### 2.2 E2E Тесты (Critical Scenarios)

#### Scenario PULSE-1: Basic Training Flow

**Prerequisite:**
1. Все сервисы запущены: `pwsh scripts\START_ALL.ps1`
2. Desktop Client запущен: `npm run tauri dev`

**Steps:**
1. Открыть TrainingPanel (вкладка "Training")
2. Выбрать профиль: `triz_smoketest` (или создать тестовый)
3. Выбрать датасет: `triz_mini` (50 samples)
4. Нажать "Start Training"
5. Наблюдать:
   - Статус: `idle` → `running` → `done`
   - Progress bar обновляется (epoch / total_epochs)
   - Loss отображается
6. Проверить файл:
   ```powershell
   Get-Content E:\WORLD_OLLAMA\services\llama_factory\training_status.json
   ```
7. Убедиться, что JSON соответствует PULSE schema (6 полей)

**Expected Result:**
- ✅ UI responsive (no freezes)
- ✅ Status transitions correctly
- ✅ JSON file atomically updated
- ✅ localStorage context persisted (profile/dataset)

#### Scenario GIT-1: Safe Git Plan + Execute (Happy Path)

**Prerequisite:**
1. Чистое рабочее дерево: `git status` (no uncommitted changes)
2. 1-2 свежих коммита в локальной ветке (не запушены)

**Steps:**
1. Открыть GitPanel (вкладка "Git Push Safety")
2. Нажать "Plan Push"
3. Проверить:
   - Status: `ready`
   - Commits to push: [list displayed]
   - Files changed: [list displayed]
   - Blocked reasons: [empty]
4. Нажать "Execute Push"
5. Дождаться результата:
   - Success message: "✅ Push successful"
   - Auto-refresh → status теперь `clean`
6. Проверить в терминале:
   ```powershell
   git log --oneline -3
   # Убедиться, что коммиты запушены
   ```

**Expected Result:**
- ✅ Plan correctly identifies commits
- ✅ Execute performs git push
- ✅ No crashes, no stuck states

#### 2.2.3 Создать TASK_19_E2E_REPORT.md

**Template:**

```markdown
# TASK 19: E2E Test Report — v0.2.0

**Дата:** [DATE]  
**Executor:** [NAME]  
**Status:** ✅ PASS / ❌ FAIL

## Scenario PULSE-1: Basic Training Flow

**Setup:**
- Services running: Ollama ✅, CORTEX ✅
- Desktop Client: `npm run tauri dev`

**Execution:**

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | Open TrainingPanel | Panel loads | [описание] | ✅ |
| 2 | Select profile/dataset | UI responsive | [описание] | ✅ |
| 3 | Start training | Status → running | [описание] | ✅ |
| 4 | Wait for completion | Status → done | [описание] | ✅ |
| 5 | Check JSON file | 6 fields, valid | [описание] | ✅ |

**Screenshots:** [Attach if needed]

**Result:** ✅ PASS

**Notes:** [Any observations]

---

## Scenario GIT-1: Safe Git Plan + Execute

**Setup:**
- Clean working tree
- 2 local commits ready to push

**Execution:**

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | Open GitPanel | Panel loads | [описание] | ✅ |
| 2 | Plan Push | Status=ready, commits shown | [описание] | ✅ |
| 3 | Execute Push | Success message | [описание] | ✅ |
| 4 | Verify git log | Commits on remote | [описание] | ✅ |

**Result:** ✅ PASS

---

## Summary

- ✅ PULSE v1: Training monitoring works as designed
- ✅ Safe Git: Plan-Execute flow works as designed

**Conclusion:** v0.2.0-rc1 passes critical E2E tests. Ready for release.
```

### GATE RULE

**До 100% completion КОМАНДЫ 2:**
- ❌ ЗАПРЕЩЕНО ставить git tag v0.2.0
- ❌ ЗАПРЕЩЕНО писать "v0.2.0 Released" в README/STATUS

**После 100% completion:**
- ✅ Переход к КОМАНДЕ 3 (Release)

---

## 📦 КОМАНДА 3: РЕЛИЗ v0.2.0 И ОБНОВЛЕНИЕ АРТЕФАКТОВ

**Приоритет:** 🟠 HIGH  
**Depends On:** КОМАНДА 2 = 100%  
**Estimated Time:** 30-60 минут

### 3.1 Git Tag + GitHub Release

#### 3.1.1 Create Git Tag

```powershell
cd E:\WORLD_OLLAMA

# Ensure on main/release branch
git checkout main

# Create annotated tag
git tag -a v0.2.0 -m "v0.2.0 - Static Fire Readiness (Verified)"

# Push tag to remote
git push origin v0.2.0
```

#### 3.1.2 Build Release Executable

```powershell
cd E:\WORLD_OLLAMA

# Run existing build script (from TASK 11)
pwsh scripts\BUILD_RELEASE.ps1

# Output: client/src-tauri/target/release/tauri_fresh.exe
# Expected size: ~8-10 MB
```

#### 3.1.3 Create GitHub Release

1. Navigate to: https://github.com/Zasada1980/WorldOllama/releases
2. Click "Draft a new release"
3. **Tag:** v0.2.0
4. **Title:** v0.2.0 — Static Fire Readiness (Verified)
5. **Body:** Copy from `CHANGELOG_v0.2.0.md`
6. **Attach:** `tauri_fresh.exe` (release build)
7. **Publish release**

### 3.2 Обновление документации

#### 3.2.1 PROJECT_STATUS_SNAPSHOT

**Файл:** `E:\WORLD_OLLAMA\PROJECT_STATUS_SNAPSHOT_v3.6.md`

**Changes:**
```markdown
# PROJECT STATUS SNAPSHOT — 28 ноября 2025 (v0.2.0 RELEASED) ← UPDATE

**Версия:** v3.7 ← INCREMENT
**Статус:** ✅ Phase 4 ЗАВЕРШЕНА (v0.2.0 Released) ← UPDATE

---

## 📊 ОБЩИЙ ПРОГРЕСС ПРОЕКТА

```
Фаза 4 ████████████████████ 100% ✅ ЗАВЕРШЕНА (v0.2.0 Released) ← UPDATE

ОБЩИЙ ПРОГРЕСС: ████████████████████ 100% ← UPDATE
```

**MILESTONE 28.11.2025:**
v0.2.0 RELEASED! TASK 16 (PULSE v1) + TASK 17 (Safe Git) verified and deployed. ← UPDATE
```

#### 3.2.2 README.md

**Файл:** `E:\WORLD_OLLAMA\README.md`

**Changes:**
```markdown
# WORLD_OLLAMA — Local-First AI Workstation

**Version:** v0.2.0 ← UPDATE (was v0.2.0-rc1)
**Status:** ✅ Production Ready ← UPDATE
**GitHub Release:** https://github.com/Zasada1980/WorldOllama/releases/tag/v0.2.0 ← UPDATE

---

## 🚀 Roadmap

- ✅ v0.1.0 (27 Nov 2025) — Developer Preview
- ✅ v0.2.0 (28 Nov 2025) — PULSE v1 + Safe Git ← UPDATE
- ⏳ v0.3.0 (Planned) — Windows Installer, PULSE v2, Git v2 ← ADD
```

#### 3.2.3 PROJECT_HANDOVER_REPORT

**Файл:** `E:\WORLD_OLLAMA\PROJECT_HANDOVER_REPORT.md`

**Add final section at bottom:**

```markdown
---

## 🎉 FINAL UPDATE: v0.2.0 RELEASED (28 Nov 2025)

**Status:** ✅ КОМАНДА 2 (Compilation + E2E) = 100%

**Verified:**
- ✅ Rust compilation: 0 errors
- ✅ TypeScript: 0 errors
- ✅ E2E PULSE-1: PASS
- ✅ E2E GIT-1: PASS

**Release:**
- ✅ Git tag v0.2.0 created
- ✅ GitHub Release published
- ✅ Documentation updated (STATUS, README)

**Next Shift:** v0.3.0 planning
- TASK 18: Windows Installer (WiX)
- TASK 19: PULSE v2 (WebSocket)
- TASK 20: Git v2 (Pre-flight checks)

**Handover complete.** 🚀
```

### 3.3 ADR-004: v0.2.0 Release Frozen

**Create:** `E:\WORLD_OLLAMA\docs\architecture\ADR-004_v020_RELEASE_FROZEN.md`

**Content:**

```markdown
# ADR-004: v0.2.0 Release Frozen

**Date:** 28 ноября 2025 г.  
**Status:** ✅ ACCEPTED  
**Context:** v0.2.0 verified and released

## Decision

Freeze PULSE v1 and Safe Git v1 as stable baseline.

**Implications:**
- Any changes to PULSE or Safe Git → v2 (breaking changes allowed)
- v0.2.x releases: Bug fixes only (no new features)
- v0.3.0+: New features (PULSE v2, Git v2)

## Rationale

v0.2.0 represents "Static Fire" verification:
- Architecture complete ✅
- Compilation clean ✅
- E2E tests pass ✅

Freezing v1 prevents scope creep and ensures stable base for future development.

## Consequences

**Positive:**
- Stable reference point for users
- Clear versioning for breaking changes
- Prevents feature creep

**Negative:**
- Known limitations (polling latency, no diff preview) remain in v1
- Users must wait for v2 for improvements

**Mitigation:**
- Document limitations in README
- Clear roadmap for v2 features in CHANGELOG v0.3.0

---

**Approved by:** Project Lead  
**Next Review:** v0.3.0 planning
```

---

## EXECUTION CHECKLIST

### Pre-flight
- [ ] Прочитать весь ордер
- [ ] Понять Gate Rule (КОМАНДА 2 blocking)
- [ ] Подготовить окружение (установка toolchain)

### Execution Order
1. ✅ КОМАНДА 1 (Setup) → 30 min
2. ✅ КОМАНДА 2 (Verify) → 1-2 hours **← GATE**
3. ✅ КОМАНДА 3 (Release) → 30-60 min

### Post-release
- [ ] Smoke test released .exe
- [ ] Update ARCHITECT_CHRONICLE.md (add v0.2.0 milestone)
- [ ] Archive ОРДЕР №19 as completed

---

**СТАТУС ОРДЕРА:** 🟡 PENDING EXECUTION  
**BLOCKING FACTOR:** Rust toolchain installation  
**ESTIMATED TOTAL TIME:** 2-4 hours

**CRITICAL PATH:** КОМАНДА 2 E2E tests (cannot skip)

---

**Issued by:** AI Agent (per user directive)  
**Issued to:** Next development shift  
**Date:** 28 ноября 2025 г.  
**Priority:** 🔴 CRITICAL
