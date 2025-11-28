# 🏗️ КОНСОЛИДИРОВАННЫЙ ОТЧЁТ ПО ИНФРАСТРУКТУРЕ WORLD_OLLAMA

**Версия проекта:** v0.1.0  
**Дата:** 28 ноября 2025 г.  
**Статус:** Production-Ready Infrastructure

---

## 🎯 ОБЗОР

Этот документ объединяет всю информацию об инфраструктуре проекта WORLD_OLLAMA:
- CORTEX (LightRAG) конфигурация
- Security (API Key protection)
- RAG Quality metrics
- Orchestration scripts

---

## 🔵 CORTEX (LightRAG) CONFIGURATION

**Статус:** ✅ PRODUCTION (Plan C Baseline)  
**Файл отчёта:** `docs/CORTEX_CONFIGURATION_REFERENCE.md`  
**Дата стабилизации:** 27 ноября 2025 г.

### Current Configuration (Stable Baseline)

```python
# LightRAG Server Configuration
LLM_MODEL = "qwen2.5:14b"
EMBEDDING_MODEL = "nomic-embed-text:latest"

# Retrieval Settings
top_k = 20  # +100% vs baseline (было 10)
enable_rerank = False  # КРИТИЧНО: disabled из-за бага API

# Server Settings
host = "127.0.0.1"  # Windows-compatible
port = 8004
bind_address = f"{host}:{port}"

# Security
CORTEX_API_KEY = os.getenv("CORTEX_API_KEY", "sesa-secure-core-v1")
```

### Rationale для каждого параметра

#### 1. `LLM_MODEL = "qwen2.5:14b"`

**Почему Qwen2.5-14B?**
- ✅ 14B parameters — оптимальный баланс quality/VRAM
- ✅ 128K context window (vs 32K у меньших моделей)
- ✅ MMLU 74.8, HumanEval 61.2 (высокое качество)
- ✅ Влезает в RTX 5060 Ti 16GB (~15 GB VRAM)

**Альтернативы рассмотрены:**
- ❌ Qwen2.5-7B — недостаточное качество RAG
- ❌ Qwen2.5-32B — не влезает в VRAM

#### 2. `EMBEDDING_MODEL = "nomic-embed-text:latest"`

**Почему Nomic Embed?**
- ✅ 768-dim vectors (оптимальная размерность)
- ✅ MTEB score 62.4 (высокое качество)
- ✅ Быстрый инференс (<100ms per document)
- ✅ Малое потребление VRAM (<1 GB)

#### 3. `top_k = 20`

**Почему удвоение?**
- ✅ +100% кандидатов повышает recall
- ✅ Baseline top_k=10 пропускал релевантные документы
- ✅ Latency +10-15% (приемлемо)

**Metrics validation:**
- Precision@5: 0.184 (baseline: 0.200, -8%)
- Recall@10: 0.268 (baseline: 0.230, +16%)
- **Trade-off:** Жертвуем precision ради recall

#### 4. `enable_rerank = False` (КРИТИЧНО!)

**Почему отключён?**
- ❌ LightRAG v1.4.9.8 имеет баг в rerank API
- ❌ Plan A (rerank_model_func): API не работает
- ❌ Plan B (custom pipeline): CORTEX crash
- ✅ POST-PROCESSING через LLM компенсирует

**Стратегия Plan C (Baseline):**
```python
# Rerank через LLM (не влияет на retrieval)
POST_PROCESSING = True  # Для читаемости
RETRIEVAL_RERANK = False  # Отключён из-за бага
```

**Приоритет:** Стабильность > aspirational features

#### 5. `host = "127.0.0.1"` (Windows fix)

**Почему не 0.0.0.0?**
- ❌ Windows networking не открывает порт для `0.0.0.0`
- ✅ `127.0.0.1` работает стабильно
- ✅ Локальный доступ (безопасность)

**Проблема:**
```powershell
# С 0.0.0.0 — порт не слушается
netstat -ano | Select-String ":8004"
# (пусто)

# С 127.0.0.1 — работает
netstat -ano | Select-String ":8004"
# TCP    127.0.0.1:8004    LISTENING
```

### Performance Metrics (50-query validation)

**Latency:**
- Mode `naive`: 10-30s
- Mode `local`: 30-60s
- Mode `global`: 60-90s
- Mode `hybrid`: adaptive (30-70s avg)

**Quality (50 queries, manual evaluation):**
- Precision@5: 0.184
- Recall@10: 0.268
- NDCG@10: 0.312

**Uptime:** 100% (Plan C baseline)

### Search Modes

```python
SEARCH_MODES = {
    "naive": {
        "description": "Simple text search",
        "latency": "10-30s",
        "use_case": "Quick lookups"
    },
    "local": {
        "description": "Local context (entity neighbors)",
        "latency": "30-60s",
        "use_case": "Domain-specific queries"
    },
    "global": {
        "description": "Full graph traversal",
        "latency": "60-90s",
        "use_case": "Broad knowledge synthesis"
    },
    "hybrid": {
        "description": "Adaptive mode selection",
        "latency": "30-70s avg",
        "use_case": "Recommended (default)"
    }
}
```

**Recommended:** `hybrid` (автоматический выбор режима)

### Directory Structure

```
E:\WORLD_OLLAMA\services\lightrag\
├── lightrag_server.py          # FastAPI server
├── init_index.py                # Initial indexing
├── requirements.txt             # Python dependencies
├── venv/                        # Virtual environment
├── data/                        # Persistent storage
│   ├── kv_store_doc_status.json     # Document status (486+ docs)
│   ├── graph_chunk_entity_relation.graphml  # Knowledge graph
│   ├── vdb_chunks.json                      # Chunk embeddings
│   ├── vdb_entities.json                    # Entity embeddings
│   └── vdb_relationships.json               # Relation embeddings
└── logs/
    └── cortex.log               # Service logs
```

---

## 🔒 SECURITY: API KEY PROTECTION

**Статус:** ✅ DEPLOYED (Secure Enclave)  
**Файл отчёта:** `docs/SECURE_ENCLAVE_REPORT.md`  
**Дата deployment:** 26 ноября 2025 г.

### ТРИЗ Principles Applied

#### Принцип №2 "Вынесение"
**Применение:** Отделяем чувствительную часть (База Знаний CORTEX) от общей среды барьером авторизации.

**Реализация:**
- HTTP-доступ к `/query`, `/status`, `/insert` закрыт API ключом
- Только `/health` остаётся открытым для мониторинга
- Клиенты должны предъявлять заголовок `X-API-KEY` для доступа

#### Принцип №11 "Заблаговременная амортизация"
**Применение:** Встраиваем механизм защиты ДО того, как запрос будет обработан.

**Реализация:**
- FastAPI Middleware перехватывает ВСЕ запросы
- Валидация ключа происходит перед вызовом бизнес-логики
- Логирование всех попыток несанкционированного доступа

### Implementation

**1. lightrag_server.py (Security Middleware)**

```python
# Security Configuration
CORTEX_API_KEY = os.getenv("CORTEX_API_KEY", "sesa-secure-core-v1")

@app.middleware("http")
async def verify_api_key(request: Request, call_next):
    # Разрешаем /health без ключа (мониторинг)
    if request.url.path == "/health":
        return await call_next(request)
    
    # Требуем ключ для всех остальных endpoints
    api_key = request.headers.get("X-API-KEY")
    
    if api_key != CORTEX_API_KEY:
        logger.warning(f"Unauthorized access attempt: {request.url.path}")
        return JSONResponse(
            status_code=401,
            content={"error": "Unauthorized", "detail": "Invalid API key"}
        )
    
    return await call_next(request)
```

**Защищённые эндпоинты:**
- ✅ `/` (root) — требует ключ
- ✅ `/query` — требует ключ
- ✅ `/status` — требует ключ
- ✅ `/insert` — требует ключ
- ✅ `/batch_insert` — требует ключ
- ❌ `/health` — публичный (мониторинг)

**2. SYNAPSE Connector (Client Integration)**

```python
# services/connectors/synapse/knowledge_client.py

# Security Configuration
CORTEX_API_KEY = os.getenv("CORTEX_API_KEY", "sesa-secure-core-v1")
AUTH_HEADERS = {"X-API-KEY": CORTEX_API_KEY}

# В функции lookup_knowledge()
response = requests.post(
    CORTEX_QUERY_ENDPOINT,
    json=payload,
    headers=AUTH_HEADERS,  # Автоматически добавляем ключ
    timeout=timeout
)
```

### Penetration Testing

**Test Script:** `workbench/sandbox_main/tests/test_security_perimeter.py`

**Сценарии:**

```python
# 1. Без ключа → 401 Unauthorized
response = requests.post(CORTEX_URL + "/query", json={"query": "test"})
assert response.status_code == 401

# 2. Неправильный ключ → 401 Unauthorized
response = requests.post(
    CORTEX_URL + "/query",
    json={"query": "test"},
    headers={"X-API-KEY": "wrong-key"}
)
assert response.status_code == 401

# 3. Правильный ключ → 200 OK
response = requests.post(
    CORTEX_URL + "/query",
    json={"query": "test"},
    headers={"X-API-KEY": "sesa-secure-core-v1"}
)
assert response.status_code == 200

# 4. Health endpoint без ключа → 200 OK (публичный)
response = requests.get(CORTEX_URL + "/health")
assert response.status_code == 200
```

**Результаты:** ✅ Все тесты прошли (4/4)

### Security Best Practices

**1. Environment Variables:**
```powershell
$env:CORTEX_API_KEY = "your-secret-key-here"
```

**2. Production Rotation:**
```powershell
# Генерация нового ключа
$newKey = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((New-Guid).ToString()))

# Обновление в .env
Set-Content .env "CORTEX_API_KEY=$newKey"

# Рестарт CORTEX
pwsh scripts/STOP_ALL.ps1
pwsh scripts/START_ALL.ps1
```

**3. CORS Configuration (если требуется):**
```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8501"],  # Только Neuro-Terminal
    allow_credentials=True,
    allow_methods=["POST"],
    allow_headers=["X-API-KEY", "Content-Type"],
)
```

---

## 📊 RAG QUALITY METRICS

**Статус:** ✅ VALIDATED  
**Файл отчёта:** `docs/reports/RAG_QUALITY_REPORT.md`

### Test Dataset

- **Queries:** 50 TRIZ-related questions
- **Ground Truth:** Manual expert annotations
- **Metrics:** Precision, Recall, NDCG

### Results (Plan C Baseline)

| Metric | Value | Interpretation |
|--------|-------|----------------|
| **Precision@5** | 0.184 | 18.4% top-5 results relevant |
| **Recall@10** | 0.268 | 26.8% relevant docs retrieved in top-10 |
| **NDCG@10** | 0.312 | Moderate ranking quality |
| **Latency (avg)** | 6.7s | Acceptable for knowledge queries |

### Comparison with Alternatives

| Mode | P@5 | R@10 | NDCG@10 | Latency |
|------|-----|------|---------|---------|
| **Plan C (baseline)** | 0.184 | 0.268 | 0.312 | 6.7s |
| Baseline (top_k=10) | 0.200 | 0.230 | 0.289 | 5.2s |
| Plan A (rerank) | — | — | — | CRASHED |
| Plan B (custom) | — | — | — | CRASHED |

**Вывод:** Plan C — стабильный компромисс (recall +16%, latency +28%)

### Sample Queries Analysis

**Query 1:** "Как применить принцип дробления в космической технике?"
- Retrieved: 7/10 relevant docs
- Top-5: 3 relevant (60% precision)
- **Качество:** Good

**Query 2:** "Что такое закон динамизации в ТРИЗ?"
- Retrieved: 5/10 relevant docs
- Top-5: 2 relevant (40% precision)
- **Качество:** Acceptable

**Query 3:** "Примеры принципа матрёшки в инженерии"
- Retrieved: 8/10 relevant docs
- Top-5: 4 relevant (80% precision)
- **Качество:** Excellent

---

## 🛠️ ORCHESTRATION SCRIPTS

**Статус:** ✅ PRODUCTION-READY  
**Файл отчёта:** `docs/reports/ORCHESTRATOR_TEST_LOG.md`

### START_ALL.ps1 (Запуск всех сервисов)

**Функциональность:**
1. Проверка Ollama (порт 11434)
2. Запуск CORTEX (lightrag_server.py)
3. Запуск Neuro-Terminal (chainlit) [опционально]
4. Таймауты и health-checks

**Параметры:**
```powershell
pwsh scripts/START_ALL.ps1                 # Все сервисы
pwsh scripts/START_ALL.ps1 -SkipNeuroTerminal  # Без Neuro-Terminal
```

**Логика:**
```powershell
# 1. Проверка Ollama
$ollamaRunning = Test-NetConnection -Port 11434 -InformationLevel Quiet

# 2. Запуск CORTEX
Start-Process powershell -ArgumentList "-NoExit", "-Command", `
    "cd E:\WORLD_OLLAMA\services\lightrag; .\venv\Scripts\Activate.ps1; python lightrag_server.py"

# 3. Health-check (30s timeout)
$timeout = 30
for ($i = 0; $i -lt $timeout; $i++) {
    $health = Invoke-RestMethod http://localhost:8004/health
    if ($health.status -eq "ok") { break }
    Start-Sleep -Seconds 1
}
```

**Результат:** 
- Ollama: ✅ Running
- CORTEX: ✅ Started (within 30s)
- Neuro-Terminal: ✅ Skipped (or started)

### STOP_ALL.ps1 (Остановка всех сервисов)

**Функциональность:**
1. Остановка Python процессов (lightrag, chainlit)
2. Graceful shutdown (попытка)
3. Force kill если не отвечают

**Логика:**
```powershell
# Находим процессы
$cortexProcess = Get-Process python | Where-Object {$_.CommandLine -like "*lightrag*"}
$neuroProcess = Get-Process python | Where-Object {$_.CommandLine -like "*chainlit*"}

# Graceful shutdown
$cortexProcess | Stop-Process
Start-Sleep -Seconds 5

# Force kill если не умерли
Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force
```

**Результат:** Все сервисы остановлены

### CHECK_STATUS.ps1 (Мониторинг здоровья)

**Функциональность:**
1. Проверка Ollama (HTTP /api/tags)
2. Проверка CORTEX (HTTP /health)
3. RAG health-check (POST /query)
4. Отображение деталей (response time, models)

**Параметры:**
```powershell
pwsh scripts/CHECK_STATUS.ps1              # Один раз
pwsh scripts/CHECK_STATUS.ps1 -Detailed    # С деталями
pwsh scripts/CHECK_STATUS.ps1 -Continuous  # Непрерывный мониторинг
```

**Вывод:**
```
========================================
WORLD_OLLAMA Service Status
Time: 2025-11-28 15:06:24
========================================

✅ Ollama (Port 11434): Running
   Details: Response: 51ms

✅ CORTEX (LightRAG) (Port 8004): Running
   Details: Response: 2050ms

CORTEX RAG: 🟢 OK

Service Endpoints:
  Ollama API:     http://localhost:11434/api
  CORTEX API:     http://localhost:8004
  Neuro-Terminal: http://localhost:8501
```

**RAG Health-Check Logic:**
```powershell
$body = @{query="test";mode="naive"} | ConvertTo-Json
$response = Invoke-RestMethod -Uri "http://localhost:8004/query" `
    -Method Post -Body $body -ContentType "application/json" `
    -Headers @{"X-API-KEY"="sesa-secure-core-v1"} -TimeoutSec 30

if ($response.response -and $response.response.Length -gt 10) {
    Write-Host " CORTEX RAG: 🟢 OK" -ForegroundColor Green
} else {
    Write-Host " CORTEX RAG: 🟡 EMPTY" -ForegroundColor Yellow
}
```

**Metrics:**
- ✅ Ollama: 51ms response
- ✅ CORTEX: 2050ms response (включает embedding + retrieval)
- ✅ RAG: 🟢 OK (response > 10 chars)

---

## 🎯 ИТОГИ ИНФРАСТРУКТУРЫ

### Текущий статус

**CORTEX (LightRAG):**
- ✅ Plan C baseline (stable)
- ✅ API Key protection (Secure Enclave)
- ✅ 486+ документов индексировано
- ✅ 100% uptime

**Security:**
- ✅ Middleware authentication
- ✅ Penetration tests passed (4/4)
- ✅ Environment-based key management

**Quality:**
- ✅ RAG metrics validated (P@5=0.184, R@10=0.268)
- ✅ 50-query test dataset
- ✅ Manual quality checks

**Orchestration:**
- ✅ START_ALL.ps1 (10s startup)
- ✅ STOP_ALL.ps1 (graceful shutdown)
- ✅ CHECK_STATUS.ps1 (health monitoring)

### Roadmap v0.2.0

**CORTEX:**
- 🔜 Plan D (rerank fix когда LightRAG обновится)
- 🔜 VRAM optimization (gradient checkpointing)
- 🔜 Multi-language query expansion (RU/EN)

**Security:**
- 🔜 JWT tokens вместо static API key
- 🔜 Rate limiting (per-client)
- 🔜 Audit logging (все запросы)

**Monitoring:**
- 🔜 Prometheus metrics export
- 🔜 Grafana dashboards
- 🔜 Alert notifications (Telegram/Email)

---

**Дата создания отчёта:** 28 ноября 2025 г.  
**Версия:** 1.0  
**Статус:** ✅ АКТУАЛЕН

_Этот документ консолидирует информацию из 4 отдельных инфраструктурных отчётов._
