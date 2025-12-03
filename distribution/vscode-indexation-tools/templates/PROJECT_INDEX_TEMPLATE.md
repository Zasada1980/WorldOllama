# Project Documentation Index

> **Автоматически генерируемый индекс всех документационных файлов проекта**  
> Обновляется автоматически при изменениях через Git Hook, FileSystemWatcher или Scheduled Task

---

## Metadata

- **Total Files:** 0
- **Coverage Period:** Not specified
- **Last Updated:** Not specified
- **Categories:** Reports (0), Logs (0), Documentation (0), Status (0), Requirements (0), Other (0)

---

## Reports

*No files in this category yet*

---

## Logs

*No files in this category yet*

---

## Documentation

*No files in this category yet*

---

## Status

*No files in this category yet*

---

## Requirements

*No files in this category yet*

---

## Other

*No files in this category yet*

---

## Statistics

| Category | Count | Percentage |
|----------|-------|------------|
| Reports | 0 | 0% |
| Logs | 0 | 0% |
| Documentation | 0 | 0% |
| Status | 0 | 0% |
| Requirements | 0 | 0% |
| Other | 0 | 0% |
| **Total** | **0** | **100%** |

---

## How to Use This Index

### Automatic Updates

This index is automatically updated by three mechanisms:

1. **Git Post-Commit Hook** — Triggers on commits with documentation changes
2. **Windows Scheduled Task** — Runs daily at 03:00 for full reindex
3. **FileSystemWatcher** — Monitors file changes in real-time (optional)

### Manual Update

```powershell
# Incremental update (fast, single file)
pwsh scripts\UPDATE_PROJECT_INDEX.ps1 -IncrementalMode -TriggerFile "path\to\file.md"

# Full reindex (slow, all files)
pwsh scripts\UPDATE_PROJECT_INDEX.ps1 -FullReindex
```

### Customization

Edit `.vscode-indexation.json` in project root:

```json
{
  "indexFile": "docs/project/INDEX.md",
  "watchPatterns": ["**/*.md", "**/*.rst"],
  "excludePatterns": ["**/node_modules/**", "**/venv/**"]
}
```

---

## Категории файлов

- **Reports** — Аналитические отчёты, консолидированные документы
- **Logs** — Журналы выполнения, логи процессов
- **Documentation** — Общая документация, руководства, README
- **Status** — Статусные документы, снимки состояния проекта
- **Requirements** — Требования, спецификации, планы
- **Other** — Прочие документы

---

*Этот файл создан автоматически VS Code Indexation Tools v2.0*
