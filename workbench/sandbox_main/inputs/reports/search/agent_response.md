# ОТВЕТЫ НА ВОПРОСЫ АГЕНТА QWEN2.5

## 1. Какую версию LightRAG (или форк) вы используете?

**Пакет:** `lightrag-hku`  
**Версия:** `1.4.9.8`  
**Установка:** `pip install lightrag-hku`

**Импорты в коде:**
```python
from lightrag import LightRAG, QueryParam
from lightrag.llm.ollama import ollama_model_complete, ollama_embed
from lightrag.utils import EmbeddingFunc
```

---

## 2. Где размещён граф и векторный индекс?

**Местоположение:** Локальный диск Windows (НЕ API/облако)

**Путь:** `E:\AI_Librarian_Core\lightrag_cache\`

**Структура файлов:**
```
lightrag_cache/
├── graph_chunk_entity_relation.graphml    # 4 MB - граф знаний
├── kv_store_full_entities.json            # 0.26 MB - список сущностей
├── kv_store_full_relations.json           # 0.40 MB - список связей
├── vdb_entities.json                      # 29 MB - векторы сущностей
├── vdb_relationships.json                 # 24 MB - векторы связей
├── vdb_chunks.json                        # 12 MB - векторы чанков
├── kv_store_doc_status.json               # 0.42 MB - статус индексации
└── kv_store_text_chunks.json              # 6.30 MB - текстовые чанки
```

**Конфигурация в коде:**
```python
WORKING_DIR = Path(r"E:\AI_Librarian_Core\lightrag_cache")
```

**Backend векторного поиска:** Встроенный в LightRAG (JSON-based), НЕ используем Qdrant/Weaviate/Pinecone

---

## 3. Backend LightRAG - стандартный или кастомный?

**Собственная адаптация:** `lightrag_server.py` - FastAPI обёртка над LightRAG

**Архитектура:**
```python
# Инициализация через @asynccontextmanager
@asynccontextmanager
async def lifespan(app: FastAPI):
    global rag
    
    # STARTUP
    rag = LightRAG(
        working_dir=str(WORKING_DIR),
        workspace="",
        llm_model_func=llm_model_func,          # Кастомная функция для Ollama
        llm_model_name="qwen2.5:14b-instruct-q4_k_m",
        llm_model_max_async=1,                  # Ограничение параллелизма
        embedding_func=EmbeddingFunc(
            embedding_dim=768,
            max_token_size=8192,
            func=embedding_func                  # Кастомная функция для nomic-embed-text
        ),
        rerank_model_func=rerank_func,          # Кастомная функция переранжирования
    )
    
    await rag.initialize_storages()             # Инициализация хранилищ
    await initialize_pipeline_status()          # Инициализация статуса pipeline
    
    yield  # Сервер работает

app = FastAPI(lifespan=lifespan)
```

**Кастомизация:**
1. **LLM обёртки для Ollama:**
   - `llm_model_func()` - вызов qwen2.5:14b через `ollama.AsyncClient`
   - `embedding_func()` - вызов nomic-embed-text через `ollama.AsyncClient`
   - `rerank_func()` - переранжирование через qwen2.5:14b

2. **Ограничения для 16GB VRAM:**
   - `llm_model_max_async=1` (строго 1, не перегружаем GPU)

3. **Chunk size:** 700 символов (нестандартно малый)

---

## 4. Пример вызова aquery() и структура параметров

### Текущий код (НЕ РАБОТАЕТ):

```python
@app.post("/query")
async def query_graph(request: QueryRequest):
    try:
        result = await rag.aquery(
            request.query,
            param=QueryParam(mode=request.mode)  # mode: "naive"/"local"/"global"/"hybrid"
        )
        
        if not result:
            result = "Информация не найдена в базе знаний."
        
        return {
            "query": request.query,
            "mode": request.mode,
            "response": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

### Структура RequestModel:

```python
class QueryRequest(BaseModel):
    query: str           # Запрос пользователя (например, "как разогнать видеокарту")
    mode: str = "hybrid" # Режим: naive/local/global/hybrid
```

### Тестовые запросы (все возвращают пустоту):

```bash
# Тест 1: Русский запрос
curl -X POST http://localhost:8003/query \
  -H "Content-Type: application/json" \
  -d '{"query": "как разогнать видеокарту", "mode": "hybrid"}'
# Ответ: {"query": "...", "mode": "hybrid", "response": "Информация не найдена в базе знаний."}

# Тест 2: Английский запрос
curl -X POST http://localhost:8003/query \
  -H "Content-Type: application/json" \
  -d '{"query": "GPU memory clock settings", "mode": "hybrid"}'
# Ответ: {"query": "...", "mode": "hybrid", "response": "Информация не найдена в базе знаний."}

# Тест 3: Простой термин
curl -X POST http://localhost:8003/query \
  -H "Content-Type: application/json" \
  -d '{"query": "RTX 5060 Ti", "mode": "naive"}'
# Ответ: {"query": "...", "mode": "naive", "response": "Информация не найдена в базе знаний."}
```

**ВСЕ РЕЖИМЫ** (naive, local, global, hybrid) возвращают пустоту!

---

## ДОПОЛНИТЕЛЬНАЯ ИНФОРМАЦИЯ

### Конфигурация Ollama:

```python
OLLAMA_BASE_URL = "http://localhost:11434"  # Локальный Windows Ollama (НЕ Docker!)
LLM_MODEL = "qwen2.5:14b-instruct-q4_k_m"
EMBEDDING_MODEL = "nomic-embed-text"
RERANK_MODEL = "qwen2.5:14b-instruct-q4_k_m"  # Та же модель для rerank
```

### Статус VRAM:

```
nvidia-smi: 11471 MB используется (модели загружены)
qwen2.5:14b-instruct-q4_k_m: ~9.67 GB
nomic-embed-text: ~0.74 GB
```

### Процесс lightrag_server.py:

- **Память:** 410 MB (подозрительно мало - граф 65 MB не загружен?)
- **Время работы:** 47 минут (перезапускался недавно)

### Индексация:

- **Завершена:** 423/427 документов (99.1%)
- **Ошибки:** 4 документа failed
- **Граф создан:** 4689 узлов, 3812 связей (файл 4 MB существует)

### Chunk strategy:

```python
# В ingest_library.py
chunk_size = 700  # символов (нестандартно малый!)
```

---

## ГЛАВНЫЙ ВОПРОС

**Почему `rag.aquery()` возвращает пустоту, если:**
- Граф создан (4689 nodes, 3812 edges)
- Векторы существуют (65 MB vdb_*.json)
- `initialize_storages()` вызван при startup
- Модели загружены в VRAM

**Возможные гипотезы:**
1. Граф не загружается в память при `initialize_storages()`
2. Векторный поиск не находит совпадений (embedding проблема)
3. Chunk size 700 символов → entities не извлекаются корректно
4. Нужны дополнительные параметры в `QueryParam` кроме `mode`

---

**Дата:** 24 ноября 2025  
**Система:** Windows 11, RTX 5060 Ti 16GB  
**Задача:** Найти причину пустых результатов без потери проиндексированных данных
