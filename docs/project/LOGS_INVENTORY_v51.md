# 📋 LOGS & REPORTS INVENTORY — ORDER 51

**Версия:** v51  
**Дата:** 02.12.2025  
**Цель:** Полная инвентаризация журналов, отчётов и документации проекта

---

## 📊 EXECUTIVE SUMMARY

**Всего файлов документации:** 48  
**Канонических (active):** 15  
**Legacy/Archive:** 33  
**Требуют перемещения:** 4

---

## 1️⃣ СТАТУСНЫЕ ЖУРНАЛЫ (PROJECT_STATUS_SNAPSHOT)

| Файл | Путь | Размер | Дата | Статус | Действие |
|------|------|--------|------|--------|----------|
| **PROJECT_STATUS_SNAPSHOT_v4.0.md** | `/` | 13.03 KB | 01.12.2025 | ✅ **CANONICAL** | KEEP |
| PROJECT_STATUS_SNAPSHOT_v3.9.md | `docs/project/snapshots/archive/` | 12.79 KB | — | 📁 ARCHIVED | KEEP (already moved) |
| PROJECT_STATUS_SNAPSHOT_v3.8.md | `docs/project/snapshots/archive/` | 10.00 KB | — | 📁 ARCHIVED | KEEP (already moved) |
| PROJECT_STATUS_SNAPSHOT_v3.3.md | `docs/project/snapshots/archive/` | 33.66 KB | — | 📁 ARCHIVED | KEEP (already moved) |

**Решение:**
- ✅ Канонический: `PROJECT_STATUS_SNAPSHOT_v4.0.md` (корень)
- ✅ Старые версии уже перемещены в `docs/project/snapshots/archive/`

---

## 2️⃣ CHANGELOGS

| Файл | Путь | Размер | Дата | Статус | Действие |
|------|------|--------|------|--------|----------|
| **CHANGELOG.md** | `/` | 13.00 KB | 01.12.2025 | ✅ **CANONICAL** | KEEP |
| CHANGELOG_v0.2.0.md | `/` | 14.03 KB | 28.11.2025 | 📦 RELEASE SPECIFIC | → `backups/archived_reports/changelog/` |
| CHANGELOG_v0.3.0.md | `/` | 8.28 KB | 30.11.2025 | 📦 RELEASE SPECIFIC | → `backups/archived_reports/changelog/` |

**Решение:**
- ✅ Канонический: `CHANGELOG.md` (корень)
- 🔄 Release-specific changelogs → архивировать после релиза v0.3.1

---

## 3️⃣ ИНДЕКСЫ ДОКУМЕНТАЦИИ

| Файл | Путь | Размер | Статус | Действие |
|------|------|--------|--------|----------|
| **DOCUMENTATION_INDEX.md** | `/` | — | ✅ **CANONICAL** | KEEP |
| docs/project/INDEX_NEW.md | `docs/project/` | — | 🟡 DUPLICATE | Verify & merge into DOCUMENTATION_INDEX.md |

**Решение:**
- ✅ Канонический: `DOCUMENTATION_INDEX.md` (корень)
- ⚠️ Проверить INDEX_NEW.md на уникальный контент → merge → удалить

---

## 4️⃣ КАРТА ПРОЕКТА

| Файл | Путь | Статус | Действие |
|------|------|--------|----------|
| **PROJECT_MAP.md** | `/` | ✅ **CANONICAL** | KEEP |

**Решение:**
- ✅ Единственный файл, дубликатов нет

---

## 5️⃣ TASK REPORTS (Детальные отчёты)

### 📁 Консолидированный отчёт (PRIMARY SOURCE)

| Файл | Путь | Охват | Статус |
|------|------|-------|--------|
| **TASKS_CONSOLIDATED_REPORT.md** | `docs/tasks/` | TASK 4-16, ORDER 33-34 | ✅ **CANONICAL** |

### 📁 Детальные TASK отчёты (Archive)

| Файл | Путь | Тип | Статус | Действие |
|------|------|-----|--------|----------|
| TASK4_REPORT.md | `client/` | System Status Panel | 📁 ARCHIVED | Keep (detailed reference) |
| TASK5_REPORT.md | `client/` | Settings Panel | 📁 ARCHIVED | Keep |
| TASK_6_COMPLETION_REPORT.md | `client/` | Library Panel | 📁 ARCHIVED | Keep |
| TASK_7_COMPLETION_REPORT.md | `client/` | Library + Indexation | 📁 ARCHIVED | Keep |
| TASK_8_COMPLETION_REPORT.md | `client/` | Commands Panel DSL | 📁 ARCHIVED | Keep |
| TASK_9_COMPLETION_REPORT.md | `client/docs/` | Core Bridge | 📁 ARCHIVED | Keep |
| TASK_13_INDEXATION_REPORT.md | `client/` | Indexation Backend | 📁 ARCHIVED | Keep |
| TASK_15_COMPLETION_REPORT.md | `client/` | Training Backend | 📁 ARCHIVED | Keep |
| TASK_16_COMPLETION_REPORT.md | `docs/tasks/` | PULSE v1 Protocol | 📁 ARCHIVED | Keep |
| TASK_16_1_16_2_COMPLETION_REPORT.md | `docs/tasks/` | PULSE v1 subphases | 📁 ARCHIVED | Keep |
| TASK_16_2_COMPLIANCE_REPORT.md | `docs/tasks/` | PULSE v1 compliance | 📁 ARCHIVED | Keep |
| TASK_42_IMPLEMENTATION_PLAN.md | `docs/tasks/` | Training UI plan | 📁 ARCHIVED | Keep |

**Решение:**
- ✅ Основной источник: `TASKS_CONSOLIDATED_REPORT.md`
- ✅ Детальные отчёты остаются как архивная справка

---

## 6️⃣ ORDER REPORTS

### 📁 Active/Recent ORDERs

| Файл | Путь | Статус | Содержание |
|------|------|--------|------------|
| **ORDER_50_COMPLETION_REPORT.md** | `docs/tasks/` | ✅ COMPLETE | Global Green Audit |
| ORDER_50_GLOBAL_GREEN_AUDIT.md | `docs/tasks/` | 📄 TRACKING | Initial audit doc |
| ORDER_50_AUDIT_REPORT.md | `docs/tasks/` | 📄 DUPLICATE? | Check vs COMPLETION |
| **ORDER_42_TRACKING.md** | `docs/tasks/` | ✅ ACTIVE | Training UI tracking |
| ORDER_42_1_COMPLETION_REPORT.md | `docs/tasks/` | ✅ COMPLETE | Profile UX |
| ORDER_42_1_REAPPLY_VERIFICATION.md | `docs/tasks/` | 📄 VERIFICATION | Re-apply check |
| ORDER_42_1_VERIFY.md | `docs/tasks/` | 📄 VERIFICATION | Initial verify |
| ORDER_42_FIX.md | `docs/tasks/` | 📄 FIX DOC | Diagnostics |
| **ORDER_43_MODEL_HF_READINESS.md** | `docs/tasks/` | 📋 PLANNED | HF Auth issue |
| **ORDER_37_FIX.md** | `docs/tasks/` | 🔴 BLOCKER | INDEX path resolution |
| ORDER_37_FIX_COMPLETION.md | `docs/tasks/` | ✅ COMPLETE | Fix implementation |
| ORDER_37_FIX_PROGRESS.md | `docs/tasks/` | 📄 PROGRESS | Interim progress |
| ORDER_33_TERMINAL_SAFETY_REPORT.md | `docs/tasks/` | ✅ COMPLETE | Terminal Safety |
| ORDER_34_DISPLAY_SETTINGS_REPORT.md | `docs/tasks/` | ✅ COMPLETE | Display Settings |
| ORDER_33_34_ACTION_PLAN.md | `docs/tasks/` | 📄 PLAN | Combined plan |

### 📁 Legacy ORDERs

| Файл | Путь | Статус | Действие |
|------|------|--------|----------|
| ORDER_19_VERIFY_v020.md | `docs/orders/` | 📁 LEGACY | Keep (v0.2.0 verification) |

### 📁 Testing Guides

| Файл | Путь | Статус | Действие |
|------|------|--------|----------|
| ORDER_34_TESTING_GUIDE.md | `client/` | 📄 GUIDE | Keep (testing reference) |
| ORDER_34_TEST_RESULTS_TEMPLATE.md | `client/` | 📄 TEMPLATE | Keep (template) |

**Решение:**
- ✅ Completion reports — сохранить как canonical
- 🔄 Tracking/Progress/Verify docs — можно удалить после завершения ORDER
- ⚠️ Проверить дубликаты (ORDER_50_AUDIT_REPORT vs ORDER_50_COMPLETION_REPORT)

---

## 7️⃣ INFRASTRUCTURE DOCS

| Файл | Путь | Тип | Статус |
|------|------|-----|--------|
| TERMINAL_SAFETY_IMPLEMENTATION_GUIDE.md | `docs/infra/` | Implementation Guide | ✅ ACTIVE |

---

## 8️⃣ HANDOVER/PROJECT DOCS

| Файл | Путь | Размер | Статус | Действие |
|------|------|--------|--------|----------|
| PROJECT_HANDOVER_REPORT.md | `/` | — | 📁 HISTORICAL | → `backups/archived_reports/` |

**Решение:**
- Handover report устарел → перенести в архив

---

## 🎯 CANONICAL FILES (SOURCES OF TRUTH)

### Primary Documentation

1. ✅ **README.md** — главная страница проекта
2. ✅ **PROJECT_MAP.md** — архитектура системы
3. ✅ **PROJECT_STATUS_SNAPSHOT_v4.0.md** — текущий статус
4. ✅ **CHANGELOG.md** — история релизов
5. ✅ **DOCUMENTATION_INDEX.md** — навигация по документации

### Consolidated Reports

6. ✅ **docs/tasks/TASKS_CONSOLIDATED_REPORT.md** — все TASK 4-16
7. ✅ **docs/models/MODELS_CONSOLIDATED_REPORT.md** — модели TD-010
8. ✅ **docs/infrastructure/INFRASTRUCTURE_CONSOLIDATED_REPORT.md** — CORTEX/Security/RAG
9. ✅ **docs/project/DOCUMENTATION_STRUCTURE_ANALYSIS.md** — векторная карта

### Active Tracking

10. ✅ **ORDER_50_COMPLETION_REPORT.md** — Global Green Audit
11. ✅ **ORDER_42_TRACKING.md** — Training UI progress
12. ✅ **ORDER_37_FIX.md** — INDEX path blocker (production)
13. ✅ **ORDER_43_MODEL_HF_READINESS.md** — HF Auth (optional)

### Configuration & Guides

14. ✅ **.github/copilot-instructions.md** — AI agent guidance
15. ✅ **docs/infra/TERMINAL_SAFETY_IMPLEMENTATION_GUIDE.md** — Terminal Safety

---

## 🔄 FILES TO MOVE (ARCHIVING CANDIDATES)

### Immediate (v51)

| Файл | Текущий путь | Новый путь | Причина |
|------|--------------|------------|---------|
| PROJECT_HANDOVER_REPORT.md | `/` | `backups/archived_reports/project/` | Historical, no longer referenced |
| CHANGELOG_v0.2.0.md | `/` | `backups/archived_reports/changelog/` | Release-specific (superseded) |
| CHANGELOG_v0.3.0.md | `/` | `backups/archived_reports/changelog/` | Release-specific (will be superseded by v0.3.1) |

### After Verification

| Файл | Действие | Причина |
|------|----------|---------|
| docs/project/INDEX_NEW.md | Verify content → merge → delete | Potential duplicate of DOCUMENTATION_INDEX.md |
| ORDER_50_AUDIT_REPORT.md | Compare with ORDER_50_COMPLETION_REPORT → delete if duplicate | Redundancy check |
| ORDER_42_1_VERIFY.md | Delete after ORDER 42 fully complete | Interim verification doc |
| ORDER_42_1_REAPPLY_VERIFICATION.md | Delete after ORDER 42 fully complete | Interim verification doc |
| ORDER_37_FIX_PROGRESS.md | Delete after ORDER 37 fix complete | Interim progress doc |

---

## 📊 SUMMARY STATISTICS

### By Type

| Тип | Количество | Канонические | Legacy/Archive |
|-----|-----------|--------------|----------------|
| STATUS_SNAPSHOT | 4 | 1 | 3 (already archived) |
| CHANGELOG | 3 | 1 | 2 (to archive) |
| INDEX/MAP | 3 | 2 | 1 (to verify) |
| TASK_REPORTS | 12 | 1 consolidated | 11 detailed (keep as archive) |
| ORDER_REPORTS | 16 | 7 active | 9 interim/legacy |
| PROJECT_DOCS | 2 | 0 active | 2 (to archive) |
| **TOTAL** | **40** | **15** | **25** |

### By Status

| Статус | Количество | Действие |
|--------|-----------|----------|
| ✅ CANONICAL | 15 | KEEP в текущей локации |
| 📁 ARCHIVED | 18 | Уже в архиве или сохранить как reference |
| 🔄 TO ARCHIVE | 4 | Перенести в backups/ |
| ⚠️ VERIFY | 3 | Проверить на дубликаты |

---

## 🎯 NEXT ACTIONS (ORDER 51.1.2)

1. ✅ **Канонические файлы определены** — 15 источников правды
2. 🔄 **Create archive structure:**
   ```
   backups/archived_reports/
   ├── changelog/
   │   ├── CHANGELOG_v0.2.0.md
   │   └── CHANGELOG_v0.3.0.md
   ├── project/
   │   └── PROJECT_HANDOVER_REPORT.md
   └── tasks/
       └── (interim verification docs - after ORDER completion)
   ```

3. ⚠️ **Verification tasks:**
   - Compare INDEX_NEW.md vs DOCUMENTATION_INDEX.md
   - Compare ORDER_50_AUDIT_REPORT vs ORDER_50_COMPLETION_REPORT
   - Cleanup interim docs after ORDER 42/37 completion

---

**Статус ORDER 51.1:** ✅ ИНВЕНТАРИЗАЦИЯ ЗАВЕРШЕНА  
**Next:** 51.2 — Проверка работоспособности
