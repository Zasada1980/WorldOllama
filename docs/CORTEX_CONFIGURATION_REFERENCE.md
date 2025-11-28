# CORTEX Configuration Reference

**Версия:** v1.0 (Baseline Stable)  
**Дата:** 28 ноября 2025 г.  
**Статус:** ✅ Production-ready (Plan C)

---

## 🎯 Текущая конфигурация

### Основные параметры

**Файл:** `E:\WORLD_OLLAMA\services\lightrag\lightrag_server.py`

```python
# LLM Configuration
LLM_MODEL = "qwen2.5:14b"              # Production-verified model
EMBEDDING_MODEL = "nomic-embed-text:latest"
OLLAMA_BASE_URL = "http://localhost:11434"

# Rerank Configuration (FROZEN до отдельного решения)
RERANK_MODEL = "qwen2.5:14b"           # ТОЛЬКО для post-processing
# rerank_model_func закомментирован в LightRAG init
# enable_rerank=False в QueryParam

# Server Configuration
host = "127.0.0.1"                     # Windows-compatible bind
port = 8004                            # CORTEX API port
```

### Поисковые параметры

```python
# Retrieval Configuration (Plan C Optimization)
top_k = 20                             # Увеличено с 10 до 20 (+100%)
only_need_context = True
enable_rerank = False                  # КРИТИЧНО: явно отключен

# Mode Priority Chain
# local → global → naive (hybrid excluded)
```

### Директории

```python
WORKING_DIR = Path(r"E:\WORLD_OLLAMA\services\lightrag\data")
LIBRARY_DIR = Path(r"E:\WORLD_OLLAMA\library\raw_documents")
```

---

## 📊 Метрики производительности

**Baseline Performance (50-query validation, 27.11.2025):**

| Метрика | Значение | Целевой показатель | Статус |
|---------|----------|-------------------|--------|
| **Precision@5** | 0.184 (18.4%) | ≥0.18 | ✅ |
| **Recall@10** | 0.268 (26.8%) | ≥0.25 | ✅ |
| **MRR** | 0.630 | - | ✅ |
| **Avg Latency** | 6.7s | ≤90s | ✅ (13.4× margin) |
| **Stability** | 50/50 (100%) | 100% | ✅ |

**Индекс состояния:**
- 687 документов
- 3688 entities (nodes)
- 3496 relations (edges)
- Размер графа: ~340 KB (`graph_chunk_entity_relation.graphml`)

---

## 🔧 Почему именно такая конфигурация?

### 1. Rerank отключён (enable_rerank=False)

**Причина:**  
LightRAG v1.4.9.8 имеет баг с API перерейжирования:
- `rerank_model_func` parameter не функционирует (подтверждено тестами 27.11)
- Кастомный rerank pipeline вызывает системный crash
- Emergency rollback к baseline показал стабильность 100%

**Решение:**  
Использование POST-PROCESSING rerank через LLM для улучшения читаемости (не влияет на retrieval):
```python
# POST-PROCESSING (не влияет на WARNING)
if RERANK_MODEL:
    # Переформулирование через LLM для улучшения структуры ответа
    reranked_response = await ollama_client.generate(...)
```

### 2. LLM Model = qwen2.5:14b

**Причина:**
- Модель существует в Ollama (`ollama list` → `qwen2.5:14b`)
- 14B параметров — оптимальный баланс качество/VRAM для RTX 5060 Ti 16GB
- Поддерживает русский и английский языки
- Используется та же модель, что и для fine-tuning (TASK 15)

**Альтернативы:**
- ❌ `qwen2.5:14b-instruct-q4_k_m` — несуществующая модель (ошибка в legacy конфиге)
- ⚠️ `qwen2.5:3b` — слишком слабая для сложных рассуждений
- ⚠️ `qwen2.5:32b` — превышает VRAM-лимит (>16GB)

### 3. Bind Address = 127.0.0.1 (не 0.0.0.0)

**Причина:**
- Windows firewall/networking проблемы с `0.0.0.0` bind
- Uvicorn запускался, но порт не слушался (подтверждено `netstat`)
- `127.0.0.1` гарантирует работу на Windows без дополнительных настроек

**Ограничение:**  
Сервер доступен ТОЛЬКО локально (не из сети). Для продакшена с удалённым доступом:
```python
# В production.yaml (если нужен сетевой доступ)
host = "0.0.0.0"  # + настройка Windows Firewall
```

### 4. top_k = 20 (увеличено с 10)

**Причина:**
- Больше кандидатов для retrieval → лучший recall
- Измеренное улучшение: +17% recall (0.23 → 0.268)
- POST-PROCESSING фильтрует до топ-8 для финального ответа

**Trade-off:**  
Latency +1.6s (5.1s → 6.7s), но всё ещё в пределах SLA (90s).

---

## 🚀 Запуск и мониторинг

### Запуск CORTEX

**Автоматический (рекомендуется):**
```powershell
pwsh E:\WORLD_OLLAMA\scripts\START_ALL.ps1 -SkipNeuroTerminal
```

**Вручную (для отладки):**
```powershell
cd E:\WORLD_OLLAMA\services\lightrag
.\venv\Scripts\Activate.ps1
python lightrag_server.py
```

**Проверка статуса:**
```powershell
# Health check
curl http://localhost:8004/health

# Комплексная проверка (включая RAG test)
pwsh E:\WORLD_OLLAMA\scripts\CHECK_STATUS.ps1 -Detailed
```

### Типичные проблемы

#### ❌ WARNING: Rerank is enabled but no rerank model

**Решение:**  
Проверить, что в коде есть `enable_rerank=False`:
```powershell
Select-String -Path "E:\WORLD_OLLAMA\services\lightrag\lightrag_server.py" `
    -Pattern "enable_rerank"
```

Если параметр отсутствует — код устарел, нужен перезапуск с актуальной версией.

#### ❌ Model 'qwen2.5:14b-instruct-q4_k_m' NOT FOUND

**Решение:**  
Исправить в `lightrag_server.py` и `start_lightrag.ps1`:
```python
LLM_MODEL = "qwen2.5:14b"  # Убрать -instruct-q4_k_m
```

#### ❌ Port 8004 занят

**Диагностика:**
```powershell
netstat -ano | Select-String ":8004.*LISTENING"
# Показывает PID процесса

Stop-Process -Id <PID> -Force
```

#### ❌ Uvicorn running, но порт не слушается

**Причина:** `host="0.0.0.0"` на Windows  
**Решение:** Изменить на `host="127.0.0.1"` в `lightrag_server.py`

---

## 📖 API Reference

### Health Check

```http
GET http://localhost:8004/health
```

**Response:**
```json
{
  "status": "healthy",
  "working_dir_exists": true,
  "library_dir_exists": true
}
```

### Query (с авторизацией)

```http
POST http://localhost:8004/query
Content-Type: application/json
X-API-KEY: sesa-secure-core-v1

{
  "query": "архитектура проекта",
  "mode": "local"
}
```

**Response:**
```json
{
  "query": "архитектура проекта",
  "mode": "local",
  "effective_mode": "local",
  "tried_modes": ["local"],
  "detected_language": "ru",
  "augmented_terms": [],
  "response": "..."
}
```

**Режимы поиска:**
- `naive` — простой векторный поиск (fast, low precision)
- `local` — поиск с локальным контекстом (balanced, **рекомендуется**)
- `global` — глобальный граф (slow, high coverage)
- `hybrid` — адаптивный режим (**отключён в Plan C**)

---

## 🔐 Безопасность

### API Key

**По умолчанию:** `sesa-secure-core-v1` (hardcoded для локального использования)

**Production setup:**
```powershell
$env:CORTEX_API_KEY = "your-secure-key-here"
# Перезапустить CORTEX
```

**Middleware:**  
Все эндпоинты кроме `/health` требуют заголовок `X-API-KEY`.

### CORS

Текущая конфигурация: CORS отключён (локальный доступ только).  
Для интеграции с веб-интерфейсом добавить в `lightrag_server.py`:
```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:1420"],  # Tauri dev port
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## 📚 Дополнительные ресурсы

**Документация проекта:**
- [`PROJECT_STATUS_SNAPSHOT_v3.3.md`](../PROJECT_STATUS_SNAPSHOT_v3.3.md) — Phase 1 метрики
- [`PLAN_C_RESULTS.md`](../CORTEX_QA/PLAN_C_RESULTS.md) — детальный отчёт по baseline
- [`RERANK_ATTEMPT_LOG.md`](../CORTEX_QA/RERANK_ATTEMPT_LOG.md) — почему rerank отключён

**Скрипты:**
- `scripts/START_ALL.ps1` — запуск всех сервисов
- `scripts/CHECK_STATUS.ps1` — проверка здоровья (включая RAG test)
- `scripts/start_lightrag.ps1` — standalone CORTEX launcher

**Логи:**
- `services/lightrag/logs/cortex.log` — основной лог сервера

---

## ✅ Checklist для production

- [x] enable_rerank = False (подтверждено в коде)
- [x] LLM_MODEL = qwen2.5:14b (существует в Ollama)
- [x] host = 127.0.0.1 (Windows-compatible)
- [x] Модели загружены (ollama pull qwen2.5:14b, nomic-embed-text)
- [x] Граф проиндексирован (687 документов)
- [x] Health check работает (200 OK)
- [x] RAG query работает (response не пустой)
- [x] Логи чистые (нет WARNING о rerank)
- [x] Скрипты синхронизированы (START_ALL, start_lightrag)

---

**Версия документа:** 1.0  
**Автор:** SESA Development Protocol  
**Последнее обновление:** 28 ноября 2025 г. 14:40
