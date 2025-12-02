# 🧬 LEGACY FEATURES & ABANDONED DEVELOPMENTS — ORDER 51

**Версия:** v51  
**Дата:** 02.12.2025  
**Цель:** Инвентаризация "забытых" разработок, DEFERRED фич и LEGACY кода

---

## 📋 EXECUTIVE SUMMARY

**Всего найдено:** 14 LEGACY зон  
**DEFERRED features:** 6  
**ABANDONED код:** 0  
**Файлы с суффиксами:** 2 (`.bak`, `_legacy`)  

**Статус:** ⚠️ Требует решений по архивации/очистке

---

## 1️⃣ LEGACY MODELS & DATA

### 🤖 Model Archives

| Название | Путь | Статус | Причина | Действие |
|----------|------|--------|---------|----------|
| **TD-010v2 (triz_extended)** | `archive/TD010v2_triz_extended/` | 📁 LEGACY | eval_loss 0.9358 (superseded by triz_full: 0.8591) | ✅ KEEP (already archived) |
| **qwen2-triz-merged** | `models/qwen2-triz-merged/` | 📁 LEGACY | Old LoRA adapters structure | ⚠️ VERIFY if used → archive if not |
| **Qwen2-7B_checkpoint** | `archive/Qwen2-7B_checkpoint/` | 📁 R&D ARCHIVE | 539 MB potential checkpoint | ✅ KEEP (R&D reference) |

**Рекомендация:**
- ✅ TD-010v2 extended уже в `archive/` — OK
- ⚠️ Проверить `models/qwen2-triz-merged/` — используется ли? Если нет → `archive/`
- ✅ Qwen2-7B checkpoint оставить как R&D reference

---

### 📚 Legacy Library Data

| Название | Путь | Статус | Рекомендация |
|----------|------|--------|--------------|
| **workbench/sandbox_main/inputs/** | Legacy data (archived) | 📁 ARCHIVED | ✅ KEEP (уже помечен как archived) |

---

## 2️⃣ DEFERRED FEATURES (UX_SPEC)

### 📱 Post-MVP UX Features

| Feature | Упоминание в | Статус | Target Version |
|---------|-------------|--------|----------------|
| **Conversation History Panel** | `UX_SPEC/06_UI_PATTERNS_AND_COMPONENTS.md:140` | 🔮 DEFERRED to Post-MVP | v0.4.0+ |
| **Chat Sidebar** | `UX_SPEC/06_UI_PATTERNS_AND_COMPONENTS.md:836` | 🔮 DEFERRED to Post-MVP | v0.4.0+ |
| **Dark Mode** | `UX_SPEC/06_UI_PATTERNS_AND_COMPONENTS.md:849` | 🔮 DEFERRED | v0.4.0+ |
| **Post-MVP Screens** | `UX_SPEC/05_MVP_SCOPE_AND_PRIORITIES.md:454` | 🔮 DEFERRED | v0.4.0+ |

**Рекомендация:**
- ✅ ОСТАВИТЬ как есть (явно помечены DEFERRED)
- 📝 Добавить в PROJECT_STATUS v4.0 раздел "Roadmap v0.4.0+" если нет

---

## 3️⃣ DEFERRED TECHNICAL FEATURES (PULSE v2)

### ⚡ PULSE Protocol Evolution

| Feature | Упоминание в | Статус | Target Version |
|---------|-------------|--------|----------------|
| **PULSE v2 Schema** | `docs/tasks/TASK_16_COMPLETION_REPORT.md:891` | 🔮 DEFERRED | v0.4.0 |
| **Advanced Training Fields** | `docs/tasks/TASK_16_2_FINAL_QUICKCHECK.md:159` | 🔮 DEFERRED to v0.3.0+ | v0.4.0 |
| **Profile/Dataset/Version Fields** | `services/llama_factory/pulse_wrapper.py:469` | 🔮 DEFERRED to PULSE v2 | v0.4.0 |

**Контекст:**
- PULSE v1 — ✅ FROZEN schema (6 полей): `status`, `epoch`, `total_epochs`, `loss`, `message`, `timestamp`
- PULSE v2 — planned extensions: `profile`, `dataset`, `version`, `step`, `gpu_memory`

**Рекомендация:**
- ✅ ОСТАВИТЬ как DEFERRED
- 📝 Создать `docs/tasks/PULSE_V2_ROADMAP.md` (optional)

---

## 4️⃣ LEGACY CODE PATTERNS

### 🦀 Rust Code

| Файл | Строка | Описание | Статус | Действие |
|------|--------|----------|--------|----------|
| `client/TASK_15_COMPLETION_REPORT.md` | 149 | "Legacy profile" comment | 📝 DOCUMENTATION | ✅ KEEP (historical context) |

**Примечание:** Реальный код `commands.rs` НЕ содержит legacy профиля (проверено в ORDER 42)

---

### 🐍 Python Code

| Файл | Контекст | Статус | Действие |
|------|----------|--------|----------|
| `services/lightrag/lightrag_server.py:59` | Comment: "Переход с legacy E:\AI_Librarian_Core" | ✅ RESOLVED | KEEP comment (explains migration) |

**Контекст:** Раньше CORTEX был в `E:\AI_Librarian_Core`, теперь в `services/lightrag/`. Комментарий поясняет миграцию.

---

### 🔧 PowerShell Scripts

| Файл | Строка | Описание | Статус | Действие |
|------|--------|----------|--------|----------|
| `scripts/start_agent_training.ps1` | 84 | "TRIZ Engineer (Active)" | ✅ RESOLVED | ✅ FIXED (ORDER 51.3) |
| `scripts/cleanup_project.ps1` | 48-49 | "Archive Legacy Version" | ✅ COMPLETED | KEEP script (archival done) |

**Рекомендация:**
- 🔄 Исправить комментарий в `start_agent_training.ps1` → `"TRIZ Engineer (Active)"`

---

## 5️⃣ LEGACY FILES (суффиксы)

### 📁 Files with Legacy Suffixes

| Файл | Путь | Размер | Статус | Действие |
|------|------|--------|--------|----------|
| **RAEDME_legacy.md** | `backups/archived_reports/RAEDME_legacy.md` | — | 📁 ARCHIVED | ✅ KEEP (already in backups) |
| **TrainingPanel.svelte.bak** | `client/src/lib/components/TrainingPanel.svelte.bak` | — | ✅ RESOLVED | ✅ DELETED (ORDER 51.3) |

**Рекомендация:**
- ✅ RAEDME_legacy уже в backups — OK
- ✅ `TrainingPanel.svelte.bak` — DELETED (ORDER 51.3)

---

## 6️⃣ PLANNED BUT NOT STARTED (ORDERs)

### 📋 Pending ORDERs

| ORDER | Название | Статус | Target Version | Документ |
|-------|----------|--------|----------------|----------|
| **ORDER 43** | Model & HF Readiness | 📋 PLANNED | v0.3.1 | `docs/tasks/ORDER_43_MODEL_HF_READINESS.md` |
| **ORDER 40** | Bugfix Pack | 📋 PLANNED | v0.3.1+ | `docs/tasks/ORDER_50_AUDIT_REPORT.md:51` |

**Контекст:**
- **ORDER 43** — внешний блокер (HuggingFace auth), не критично
- **ORDER 40** — не создан (упоминается только в аудите)

**Рекомендация:**
- ✅ ORDER 43 — оставить как PLANNED (блокирует training, но не UI)
- ⚠️ ORDER 40 — создать файл `docs/tasks/ORDER_40_BUGFIX_PACK.md` или удалить упоминание

---

## 7️⃣ DEFERRED IN ORDER REPORTS

### 🔄 Deferred Technical Items

| Компонент | Deferred Item | Упоминание в | Целевая версия |
|-----------|--------------|-------------|----------------|
| **commands.rs** | INDEX path hardcode cleanup | `docs/tasks/ORDER_37_FIX_COMPLETION.md:23` | v0.3.1+ (4 uses remaining) |

**Контекст:**
- ORDER 37 FIX — частично завершён (2/6 uses fixed)
- Остались 4 use в `commands.rs` — DEFERRED для следующего ORDER

**Рекомендация:**
- ✅ DEFERRED явно документирован — OK
- 📝 Создать ORDER 37.2 для оставшихся 4 uses (optional)

---

## 8️⃣ EMPTY/UNUSED FILES

### 📄 Suspicious Empty Files

| Файл | Статус | Найдено в | Рекомендация |
|------|--------|-----------|--------------|
| **task.md** | ACTIVE (78 lines, tracks FALSE GREENS) | Root directory | ✅ KEEP (active task tracker, updated 01.12.2025) |

**Рекомендация:**
- ❌ Удалить `task.md` из корня проекта (пустой, не используется)

---

## 🎯 SUMMARY BY CATEGORY

### By Status

| Статус | Количество | Действие |
|--------|-----------|----------|
| ✅ KEEP (already archived) | 5 | No action needed |
| 🔮 DEFERRED (documented) | 9 | Keep as-is (roadmap items) |
| ⚠️ VERIFY | 1 | Check if `models/qwen2-triz-merged/` used |
| 🔄 UPDATE | 1 | Fix comment in `start_agent_training.ps1` |
| ✅ RESOLVED | 2 | `TrainingPanel.svelte.bak` (deleted), `task.md` (verified active) |

### By Component

| Компонент | LEGACY зон | Основной статус |
|-----------|-----------|-----------------|
| Models | 3 | ✅ Archived |
| UX Features | 4 | 🔮 Deferred to Post-MVP |
| PULSE Protocol | 3 | 🔮 Deferred to v2 |
| Code Comments | 3 | ✅ OK (historical context) |
| Files | 2 | ❌ 1 to delete |
| ORDERs | 2 | 📋 Planned |

---

## 🗂️ RECOMMENDED ACTIONS

### Immediate (ORDER 51 scope)

1. ✅ **COMPLETED - Delete outdated backup:**
   ```powershell
   git rm "client/src/lib/components/TrainingPanel.svelte.bak"
   # Executed in ORDER 51.3
   ```

2. ✅ **VERIFIED - task.md is ACTIVE:**
   ```powershell
   # DECISION: KEEP (78 lines, tracks FALSE GREENS, updated 01.12.2025)
   # Initial report incorrectly identified as empty
   ```

3. ✅ **COMPLETED - Fix misleading comment:**
   ```powershell
   # В scripts/start_agent_training.ps1:84
   # Было: "TRIZ Engineer (Legacy)"
   # Стало: "TRIZ Engineer (Active)"
   # Syntax verified: Get-Command start_agent_training.ps1 -Syntax → OK
   ```

---

### Verification Tasks (before v0.3.1)

4. ⚠️ **Verify qwen2-triz-merged usage:**
   ```powershell
   # Поиск ссылок на models/qwen2-triz-merged
   Get-ChildItem -Path "E:\WORLD_OLLAMA" -Recurse -Include "*.ps1","*.rs","*.py","*.md" |
       Select-String "qwen2-triz-merged"
   
   # Если не используется → переместить в archive/
   ```

5. 📝 **Create ORDER 40 or remove reference:**
   - Либо создать `docs/tasks/ORDER_40_BUGFIX_PACK.md`
   - Либо убрать упоминание из ORDER_50_AUDIT_REPORT.md

---

### Future Enhancements (v0.4.0+)

6. 🔮 **Document DEFERRED features in roadmap:**
   - Create `docs/project/ROADMAP_v0.4.0.md` with:
     - PULSE v2 schema
     - Post-MVP UX features (Chat sidebar, Dark mode)

---

## 📊 HEALTH STATUS

| Категория | Оценка | Комментарий |
|-----------|--------|-------------|
| **Model Archives** | 🟢 HEALTHY | Все legacy модели правильно архивированы |
| **DEFERRED Features** | 🟢 HEALTHY | Чётко документированы, не мешают |
| **Code Comments** | 🟡 MINOR ISSUE | 1 misleading comment (easy fix) |
| **Legacy Files** | 🟡 MINOR ISSUE | 2 файла к удалению (non-critical) |
| **Planned ORDERs** | 🟢 HEALTHY | Explicit in tracking |

**Overall:** 🟢 **HEALTHY** — нет критичных ABANDONED разработок, всё явно помечено

---

## 🎯 ORDER 51.3-IMMEDIATE RESOLUTION

**Выполнено:** 02.12.2025

| Действие | Статус | Результат |
|----------|--------|----------|
| Delete `TrainingPanel.svelte.bak` | ✅ DONE | `git rm` executed |
| Delete `task.md` | ✅ VERIFIED ACTIVE | KEPT (78 lines, FALSE GREENS tracker) |
| Fix comment in `start_agent_training.ps1` | ✅ DONE | "Legacy" → "Active", syntax verified |

**Git Status:**
```powershell
# Staged for commit:
# deleted: client/src/lib/components/TrainingPanel.svelte.bak
# modified: scripts/start_agent_training.ps1
# modified: docs/project/LEGACY_FEATURES_REPORT_v51.md
```

---

**Статус ORDER 51.3:** ✅ COMPLETE  
**Найдено критичных блокеров:** 0  
**Немедленных действий:** 0 (все 3 resolved)  
**Next:** 51.4 — Очистка директорий
