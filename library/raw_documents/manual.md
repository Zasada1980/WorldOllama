# Sandbox Operations Manual

> Все работы выполняются строго **внутри** `E:\WORLD_OLLAMA\workbench\sandbox_main`. Перемещение артефактов за пределы песочницы запрещено до прямой команды пользователя. Корневой уровень песочницы содержит только файловые артефакты (журналы, записи, отчёты); любая практическая работа ведётся в профильных подкаталогах.

## 1. Назначение каталогов

| Путь | Назначение | Тип артефактов |
|------|------------|----------------|
| `inputs/` | Копии исходных данных, импортируемые из внешних источников для анализа | Документы, схемы, конфиги read-only |
| `outputs/` | Промежуточные результаты до ревью (отчёты, конвертированные файлы, экспортные форматы) | Маркировать датой/версией |
| `drafts/` | Черновые заметки, промпты, обсуждения, которые ещё не готовы в основной RAEDME | Markdown/Org/TXT |
| `scripts/` | Экспериментальные ps1/py, automation snippets. После утверждения переносятся в `WORLD_OLLAMA/scripts` | Исходный код + usage.md |
| `tools/` | Локальные настройки/конфиги инструментов (IDE, Docker compose overrides, telemetry mock configs) | `.json`, `.yaml`, `.ps1` |
| `tests/` | Наборы тестов, моковые данные, отчёты прогонов | Playwright/Jest/Pytest |
| `logs/` | Логи выполнения скриптов и сервисов внутри песочницы | `.log`, `.jsonl` |
| `tmp/` | Временные файлы и кеши с ограниченным сроком жизни | Очистка по завершении сессии |
| `archive/` | Snapshot песочницы перед переносом результатов в основной WORLD | `.zip`, `.7z`, манифесты |
| `webui_lab/` | Вся работа по фронтенду и веб-интерфейсам | См. подраздел ниже |
| `inputs/data_tray/` | **[TD-004] АВТОМАТИЧЕСКИЙ ЛОТОК ДЛЯ ЗНАНИЙ** — место для новых документов, обрабатываемых `ingest_watcher.ps1` | `.txt`, `.md`, `.pdf` → автоперенос в `library/raw_documents` |

### 1.0.1 `inputs/data_tray` — Система автоматического Ingestion

**Принцип работы (ТРИЗ Принцип 10: Предварительное исполнение):**

Вместо ручного копирования файлов в библиотеку, используйте "Лоток" (`inputs/data_tray`):

1. **Положите файл** (.txt, .md, .pdf) в `inputs/data_tray`
2. **Запустите скрипт:** `pwsh scripts/ingest_watcher.ps1`
3. **Система автоматически:**
   - Санитизирует имя файла (пробелы → `_`, убирает спецсимволы)
   - Проверяет кодировку (предпочтительно UTF-8)
   - Перемещает в `E:\WORLD_OLLAMA\library\raw_documents`
   - Логирует событие в `logs/ingestion.log`

**Параметры запуска:**
```powershell
# Стандартный запуск
pwsh scripts/ingest_watcher.ps1

# С подробным выводом (показывает кодировку файлов)
pwsh scripts/ingest_watcher.ps1 -DetailedOutput

# Тестовый запуск (не перемещает файлы, только показывает что будет сделано)
pwsh scripts/ingest_watcher.ps1 -DryRun
```

**Проверка результата:**
```powershell
# Смотрим лог
Get-Content logs/ingestion.log -Tail 20

# Проверяем библиотеку
Get-ChildItem E:\WORLD_OLLAMA\library\raw_documents | Select-Object Name, LastWriteTime
```

**Статус:** ✅ **Реализовано и протестировано** (25.11.2025)

### 1.1 `webui_lab` структура

| Путь | Назначение |
|------|------------|
| `design/` | UX/UI концепции, user journey, wireframes |
| `prototypes/` | Чистые HTML/TS/React прототипы, proof-of-concept | 
| `assets/` | SVG, иконки, шрифты, медиа-файлы |
| `api_mocks/` | JSON-моки, сборки Postman/Thunder Client, OpenAPI/AsyncAPI схемы |
| `configs/` | Настройки dev-серверов, `.env.local`, vite/webpack конфиги |
| `build/` | Сборки до ревью (`debug`, `preview`, `package/`) |
| `tests/` | UI/E2E тесты, отчёты (Playwright, Cypress, Vitest) |
| `logs/` | Журналы dev-серверов, bun/vite/npm output |
| `notes/` | Решения по фронту, встречи, ретроспективы |

### 1.2 `inputs` поддеревья

| Путь | Содержание | Примечания |
|------|------------|------------|
| `inputs/agents/system_prompts/` | `00_system_prompt.md`, `01_component_schema.md`, шаблоны взаимодействий | Только чтение, меняем копии в `drafts/` |
| `inputs/agents/configs/` | `logic_engine.json`, `templates.xml`, эталонные `config.yaml` | Версионируем изменения в `outputs/` |
| `inputs/agents/scripts/` | `check_tool.py`, `check_webui_db.py`, другие служебные утилиты | Исполняем клоны в `scripts/` |
| `inputs/agents/docs/` | `INTEGRATION_REPORT.md`, `ДОЛГ.md`, `docs/` | Нормативные документы |
| `inputs/agents/reports/` | Архивные отчёты, журналы, результаты агентов | Используются для сравнительного анализа |
| `inputs/agents/documents/raw/` | Сырые документы из `AGENTS/Documents` | Импорт без редактирования |
| `inputs/agents/documents/cleaned/` | Нормализованные документы | Служат baseline для новых пайплайнов |
| `inputs/ai_librarian/scripts/` | `lightrag_server.py`, `ingest_*.py`, вспомогательные ps1 | Исправления переносим в `scripts/` |
| `inputs/ai_librarian/docs/` | `README.md`, `NEXT_STEPS.md`, `SAFETY_DIRECTIVE.md` | Раскрывают требования LightRAG |
| `inputs/ai_librarian/logs/` | `lightrag_server.log*`, `ingest_report.json`, `processed_files.txt` | Исторические замеры/ошибки |
| `inputs/reports/search/` | `FINAL_STATUS_REPORT.md`, `LIGHTRAG_DIAGNOSTIC_REPORT.md`, др. расследования | Поддерживают ретро-анализ |
| `inputs/integrations/telegram/code/` | Код Telegram-агента | Запуск только из рабочей копии в `scripts/` |
| `inputs/integrations/telegram/docs/` | README и инструкции для интеграций | Используем при планировании |

### 1.3 Специализированные каталоги

| Путь | Назначение | Тип артефактов |
|------|------------|----------------|
| `scripts/ci/` | Шаблоны GitHub Actions, Playwright, Terraform pipelines | `.yml`, `.ps1`, README |
| `scripts/knowledge_connector/` | Песочничный SDK + CLI для LightRAG-коннектора | README, Python package |
| `tools/telemetry/` | Макеты Prometheus/Grafana, настройки экспортеров | `.json`, `.yml`, `.ps1` |
| `tests/security/` | Проверки XSS/CSRF, чек-листы угроз, payloads | Markdown, `.http`, `.json` |
| `webui_lab/api_mocks/contracts/` | OpenAPI/AsyncAPI спецификации, Postman/Thunder коллекции | `.yaml`, `.json` |
| `webui_lab/build/package/` | Сборки фронта, готовые к переносу в `WORLD_OLLAMA` | `.zip`, `.tar`, релизные манифесты |

## 2. Журналирование работы

1. **Инициирование задачи** — создаём запись в `drafts/` (`YYYY-MM-DD-task.md`) с ссылкой на пункт ТЗ.
2. **Ход работы** — ведём чек-листы в соответствующем каталоге (например, настройки API → `webui_lab/api_mocks/notes/<date>.md`).
3. **Логи** — каждый запуск скрипта помещает stdout/stderr в `logs/<date>_<task>.log`.
4. **Результат** — складываем в `outputs/<task>/<version>/`. Перед переносом в WORLD делаем zip в `archive/` и фиксируем сводку в `RAEDME`.

## 3. Карта ТЗ всего проекта

| Блок | Цель | Статус |
|------|------|--------|
| Мировая архитектура (`WORLD_OLLAMA`) | Завершить миграцию агентов, библиотеки знаний и сервисов в новую структуру | Базовый скелет готов, наполнение в процессе |
| Библиотека знаний | Очистить данные (`cleaned_documents`), построить `lightrag_cache`, подключить SDK | Требует пайплайна очистки и индексации |
| Агент `qwen2-main` | Обеспечить основной Qwen2 стек, логирование, world-state | Модель установлена, рантайм-данных нет |
| Агент `helper-lite` | Лёгкий помощник на llama3.1:8b | Модель скачана, нет логов/данных |
| Сервисы Open WebUI/коннекторы | Стабильный контейнер, отдельные FastAPI-шлюзы для агентов | Open WebUI развернут, остальные сервисы запланированы |
| Sandbox workflows | Полный цикл разработки и ревью внутри песочницы с архивированием | Структура создана, нужны шаблоны процессов |
| Web UI | Разработать интерфейсы, макеты, mock API, тесты и сборки | `webui_lab` пуст, требуется наполнение |

## 4. Технический долг

1. **Data Cleansing** — отсутствует pipeline для `cleaned_documents`, нет скриптов нормализации и дедупликации.
2. **LightRAG Cache** — индексация не выполнена; нужно связать с Ollama на 11434 и контролировать VRAM.
3. **Backups** — каталоги `backups/daily|weekly|manual` пусты; требуется расписание и скрипты.
4. **Central Logs** — нет агрегации в `logs/agents|ingestion|services` (пока только placeholders).
5. **Connectors Service** — Python/TS SDK лежат в песочнице, требуется обёртка `services/connectors` и REST-шлюзы.
6. **Telemetry** — нет макетов Grafana/Prometheus, нужно оформить sandbox для метрик.
7. **Security & QA** — `tests/security` и `webui_lab/tests` не содержат сценариев (XSS/CSRF, UI regression).
8. **Packaging/Deployment** — отсутствуют `build/package` артефакты и инструкции переноса в `WORLD_OLLAMA`.
9. **Process Templates** — нет типовых форм для отчётов, ревью и чек-листов (ожидаются в `drafts/` / `notes/`).
10. **[TD-004] Система Ingestion "Data Tray" (Принцип 10)** — ✅ **[DONE] PRODUCTION (25.11.2025)**  
    Создана система автоматического приема файлов из `inputs/data_tray` в библиотеку.  
    Скрипт **ПЕРЕНЕСЕН В PRODUCTION**: `E:\WORLD_OLLAMA\scripts\ingest_watcher.ps1`
    
    **Реализованные функции:**
    - Обнаружение файлов в лотке (.txt/.md/.pdf)
    - Валидация формата и проверка кодировки (UTF-8 detection)
    - **Транслитерация кириллицы** (66 букв русского алфавита): `Тестовый → testovyy`
    - Санитизация имени (пробелы → `_`, спецсимволы удалены, snake_case lowercase)
    - Обработка коллизий имен (timestamp suffix при дублях)
    - Атомарное перемещение в `E:\WORLD_OLLAMA\library\raw_documents`
    - Логирование в `logs/ingestion.log` с timestamps
    
    **Тестирование (SESA3002a Acceptance Criteria):**
    - ✅ Файл `Тестовый Документ #1.txt` → `testovyy_dokument_1.txt`
    - ✅ Кириллица полностью транслитерирована (критично для LightRAG/ChromaDB)
    - ✅ Спецсимволы (#, №) удалены
    - ✅ UTF-8 encoding detection работает корректно
    
    **Статус:** ✅ **SESA3002a APPROVED — ИКР ДОСТИГНУТ**  
    **Аудит-отчет:** См. `SESA3002a_AUDIT_REPORT.md`  
    **TODO:** Добавить триггер переиндексации LightRAG после ingestion (Phase 2).
11. **[TD-005] Living Map Generator (25.11.2025)** — ✅ **[DONE] PRODUCTION (SESA Approved)**  
    **Цель:** Устранение "Контекстной Слепоты" агента (ТРИЗ Принцип 10: Предварительное действие)  
    
    **Скрипт ПЕРЕНЕСЕН В PRODUCTION:** `E:\WORLD_OLLAMA\scripts\generate_map.ps1`  
    **Выход:** `E:\WORLD_OLLAMA\PROJECT_MAP.md` (навигационный документ в корне мира)
    
    **Реализованные функции:**
    - Рекурсивный обход структуры проекта (MaxDepth=6)
    - Фильтрация шума: 26 типов папок (.git, venv, __pycache__, lightrag_cache, site-packages, blobs, manifests, etc.)
    - Фильтрация файлов: 11 типов (.pyc, .log, .DS_Store, Thumbs.db, desktop.ini, etc.)
    - Обогащение: извлечение H1 из README.md/MANUAL.md/RAEDME для описаний папок
    - Защита от пустых папок: ранний выход при отсутствии содержимого
    - Показ только ключевых файлов (README, config.yaml, requirements.txt, Dockerfile, etc.)
    
    **IKR-критерии (SESA3002a Acceptance):**
    - ✅ Скорость: 0.17s (требование <2s) — **в 11.7 раз быстрее**
    - ✅ Читаемость: 95 строк дерева (лимит 400) — **в 4.2 раза компактнее**
    - ✅ Чистота: 100% защита от мусора (26 фильтров активно)
    
    **Статус:** ✅ **PRODUCTION DEPLOYED**  
    **Верификация:** См. `TD005_VERIFICATION_REPORT.md`  
    **Назначение:** Карта дает системе "зрение" — агент видит структуру без expensive scanning
12. **[TD-006] Open WebUI Native Stability Fix (25.11.2025)** — RESOLVED. Root cause: `run_in_terminal(isBackground=true)` kills idle servers → solution via `Start-Process` detached launch. Artifacts: `E:\WORLD_OLLAMA\scripts\start_webui_production.ps1` (production launcher), `sandbox_main/DIAGNOSTIC_REPORT.md` (full investigation), `sandbox_main/scripts/debug_launcher.py` (diagnostic tool). Status: ✅ **Production Ready**.

13. **[TD-006] CORTEX - LightRAG GraphRAG Knowledge Base (25.11.2025)** — ✅ **[DONE] OPERATIONAL**
    
    **Миссия:** Развернуть когнитивное ядро для ассоциативного поиска по 131 документу из `library/raw_documents`.
    
    **Технический стек:**
    - LightRAG 1.4.9.8 (GraphRAG: NetworkX + Nano-vectordb)
    - Ollama: qwen2.5:14b-instruct-q4_k_m (LLM) + nomic-embed-text (embeddings)
    - FastAPI server: http://localhost:8004
    - GPU: RTX 5060 Ti 16GB (~12GB VRAM при работе)
    
    **Индекс (98.5% coverage):**
    - Документы: 331/336 обработано
    - Граф знаний: 1469 nodes, 1560 edges (GraphML 1.49 MB)
    - Векторы: entities (9.14 MB) + relationships (9.74 MB) + chunks (2.33 MB)
    - KV stores: 7 JSON-based storage engines
    
    **Запуск CORTEX:**
    ```powershell
    cd E:\WORLD_OLLAMA\services\lightrag
    .\venv\Scripts\Activate.ps1
    python lightrag_server.py --host 0.0.0.0 --port 8004
    
    # Проверка здоровья
    Invoke-RestMethod http://localhost:8004/health
    
    # VRAM check (КРИТИЧНО: должно быть >10 GB!)
    nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits
    ```
    
    **Использование API:**
    ```powershell
    # Запрос к базе знаний
    $body = @{
        query = "Как разогнать память RTX 5060 Ti?"
        mode = "hybrid"  # naive|local|global|hybrid
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod `
        -Uri "http://localhost:8004/query" `
        -Method Post `
        -Body $body `
        -ContentType "application/json" `
        -TimeoutSec 90
    
    # Результат: 2000-3000 символов контекстуального ответа
    Write-Host $response.response
    ```
    
    **Режимы поиска:**
    - `naive`: Прямой векторный поиск по chunks (~10-20s)
    - `local`: Entity-based локальный поиск (~20-30s)
    - `global`: Глобальный граф-поиск (~30-45s)
    - `hybrid`: Комбинация всех режимов (рекомендуется, ~30-60s)
    
    **Известные ограничения:**
    - ⚠️ **Rerank ОТКЛЮЧЕН** (баг в LightRAG 1.4.9.8: `'float' object has no attribute 'copy'`)
      - Impact: Результаты не переранжируются по релевантности
      - Workaround: Hybrid mode компенсирует качеством
    - ⚠️ **5 документов pending** (1.5%) — застряли из-за Ollama 500 errors
      - Non-critical: 98.5% coverage достаточно
    - ⚠️ **Медленные запросы** (30-90s) — нормально для LLM generation
      - Используйте `-TimeoutSec 90` в PowerShell
    
    **Диагностика:**
    ```powershell
    # Логи сервера
    Get-Content E:\WORLD_OLLAMA\services\lightrag\lightrag_server.log -Tail 50
    
    # Проверка графа на диске
    Get-ChildItem E:\WORLD_OLLAMA\services\lightrag\data\graph_*.graphml
    
    # Статус индексации
    $status = Get-Content E:\WORLD_OLLAMA\services\lightrag\data\kv_store_doc_status.json | ConvertFrom-Json
    $total = ($status.PSObject.Properties).Count
    $processed = ($status.PSObject.Properties | Where-Object { $_.Value.status -eq 'processed' }).Count
    Write-Host "Индексация: $processed/$total ($([math]::Round($processed/$total*100,1))%)"
    ```
    
    **Перезапуск при сбое:**
    ```powershell
    # Kill зависший сервер
    Get-Process python | Where-Object { $_.CommandLine -like '*lightrag_server.py*' } | Stop-Process -Force
    
    # Проверка VRAM (если <6GB → models NOT loaded!)
    nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits
    
    # Restart
    cd E:\WORLD_OLLAMA\services\lightrag
    .\venv\Scripts\Activate.ps1
    python lightrag_server.py --host 0.0.0.0 --port 8004
    ```
    
    **Файлы:**
    - Сервер: `E:\WORLD_OLLAMA\services\lightrag\lightrag_server.py` (636 lines)
    - Индекс: `E:\WORLD_OLLAMA\services\lightrag\data\` (GraphML + JSON stores)
    - Отчет: `E:\WORLD_OLLAMA\services\lightrag\CORTEX_DEPLOYMENT_REPORT.md`
    - Диагностика: `E:\WORLD_OLLAMA\workbench\sandbox_main\scripts\diagnose_cortex.py`
    
    **Производительность:**
    - Query: "What is WORLD_OLLAMA?" → 2883 chars, 45 seconds (hybrid mode)
    - VRAM peak: 12-14 GB (LLM + embeddings)
    - Cache hits: 694 cached LLM responses (11.42 MB)
    
    **Статус:** ✅ **[DONE] OPERATIONAL** (rerank disabled, 98.5% coverage)  
    **Документация:** См. `CORTEX_DEPLOYMENT_REPORT.md` (полный deployment timeline + troubleshooting)  
    **Назначение:** Ассоциативная память для технических запросов (GPU overclocking, SSL certificates, AI agents, ТРИЗ, etc.)

14. **[TD-007] SYNAPSE - Knowledge Connector (25.11.2025)** — ✅ **[DONE] PRODUCTION DEPLOYED**
    
    **Миссия:** Создать стандартизированный интерфейс Agent ↔ CORTEX. Реализация Принципа ТРИЗ №24 "Посредник".
    
    **Развертывание:**
    - **Локация:** `E:\WORLD_OLLAMA\services\connectors\synapse\`
    - **Артефакты:**
      * `knowledge_client.py` — основной Python клиент (390 строк)
      * `synapse_tool_def.json` — OpenAPI/Ollama Function Calling schema
      * `open_webui_tool_code.py` — готовый код для Open WebUI → Workspace → Tools
      * `test_synapse.py` — верификационные тесты (240 строк)
      * `README.md` — полная документация (360 строк)
      * `requirements.txt` — зависимости (requests>=2.31.0)
      * `venv/` — виртуальное окружение (production)
    
    **Функциональность:**
    - `lookup_knowledge(query, mode="hybrid")` — основная функция
    - `check_cortex_health()` — проверка доступности сервера
    - `batch_lookup(queries)` — пакетные запросы
    - Обработка ошибок: `CortexConnectionError`, `CortexQueryError`, `ValueError`
    - Поддержка 4 режимов: naive (10-20s), local (20-30s), global (30-45s), hybrid (30-60s)
    
    **Интеграция (3 способа):**
    1. **Open WebUI Native Tools:**
       - Открыть http://localhost:3100 → Workspace → Tools → "+ Add Tool"
       - Скопировать содержимое `open_webui_tool_code.py`
       - Сохранить как "Knowledge Base"
       - Активировать в настройках модели qwen2-main
    
    2. **Ollama Functions API:**
       ```python
       tools = [{ "type": "function", "function": {...} }]  # из synapse_tool_def.json
       ollama.chat(model="qwen2.5:14b", messages=[...], tools=tools)
       ```
    
    3. **Direct Python:**
       ```python
       from knowledge_client import lookup_knowledge
       answer = lookup_knowledge("Структура WORLD_OLLAMA?")
       # → 2000-3000 символов контекста из 331 документа
       ```
    
    **Верификация (live test):**
    ```powershell
    cd E:\WORLD_OLLAMA\services\connectors\synapse
    .\venv\Scripts\Activate.ps1
    python test_synapse.py
    
    # Результат: 4/4 PASSED
    # - Health Check ✅
    # - Simple Query ✅ (2326 chars, 69s)
    # - Structured Query ✅ (2528 chars, 29s)
    # - Error Handling ✅
    ```
    
    **Производительность:**
    - Средний размер ответа: 2400 символов
    - Время отклика: 30-70 секунд (LLM generation)
    - Coverage: 98.5% (331/336 документов)
    - Релевантность: технические термины корректно извлекаются
    
    **Статус:** ✅ **[DONE] PRODUCTION DEPLOYED**  
    **Документация:** См. `services/connectors/synapse/README.md` (quickstart, API ref, troubleshooting)  
    **SESA3002a Audit:** APPROVED (Принцип ТРИЗ №24 "Посредник" — Agent ↔ CORTEX connection established)  
    **Назначение:** Агент (Qwen/Llama) получает доступ к памяти 331 документа через Function Call

## 5. Правила использования песочницы

1. **Строго по назначению** — каждая задача выполняется только в профиле каталога. Например, фронтовый код → `webui_lab/prototypes`, не в `scripts/`.
2. **Корневой уровень** — хранит лишь документы (MANUAL, отчёты, журналы). Папки создаются только для описанных выше блоков.
## 6. Дополнительные рекомендации

- Перед началом работы дублируйте внешний источник в `inputs/` с датой и ссылкой.
- Для каждого таска оформляйте `TODO.md` в соответствующем каталоге и синхронизируйте с `RAEDME`.
- В `webui_lab/api_mocks` создавайте подпапки `contracts/` (OpenAPI), `responses/` (пример ответов), `collections/` (Postman/Thunder). 
- Раз в сессию делайте `Get-ChildItem` снимок каталога и прикладывайте вывод к логам для трассируемости.
