#!/usr/bin/env python3
"""
LightRAG Server для AI Librarian
Граф знаний с поддержкой векторного поиска
Оптимизирован для 16GB VRAM (RTX 5060 Ti)
"""

import os
import re
import asyncio
from pathlib import Path
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Request, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import nest_asyncio
from lightrag import LightRAG, QueryParam
from lightrag.llm.ollama import ollama_model_complete, ollama_embed
from lightrag.utils import EmbeddingFunc
import uvicorn
import logging

# Настройка логирования
logging.basicConfig(level=logging.INFO)

# ============================================================
# TASK 16.1: Dynamic Project Root Detection
# ============================================================

# Method 1: Environment variable (for testing/deployment)
if "WORLD_OLLAMA_ROOT" in os.environ:
    PROJECT_ROOT = Path(os.environ["WORLD_OLLAMA_ROOT"])
else:
    # Method 2: Calculate from script location
    # Script: services/lightrag/lightrag_server.py → root = 2 levels up
    PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

logging.info(f"[TASK 16.1] Project root: {PROJECT_ROOT}")

# ============================================================
# SECURITY CONFIGURATION (ОПЕРАЦИЯ "SECURE ENCLAVE")
# ============================================================

# КРИТИЧНО: API Key для изоляции CORTEX (ТРИЗ Принцип №2 "Вынесение")
# Загружается из переменной окружения или использует значение по умолчанию
CORTEX_API_KEY = os.getenv("CORTEX_API_KEY", "sesa-secure-core-v1")

# Логируем режим безопасности при старте
if os.getenv("CORTEX_API_KEY"):
    logging.info("[SECURITY] API Key loaded from environment variable")
else:
    logging.warning("[SECURITY] Using default API Key - set CORTEX_API_KEY env variable for production")

# ============================================================
# КОНФИГУРАЦИЯ ПОД 16GB VRAM
# ============================================================

# Пути (WORLD_OLLAMA - TD-006 CORTEX) - TASK 16.1: Dynamic
# ИСПРАВЛЕНО: Переход с legacy E:\AI_Librarian_Core на WORLD_OLLAMA структуру
WORKING_DIR = PROJECT_ROOT / "services" / "lightrag" / "data"
LIBRARY_DIR = PROJECT_ROOT / "library" / "raw_documents"

# Ollama настройки
OLLAMA_BASE_URL = "http://localhost:11434"
LLM_MODEL = "qwen2.5:14b"  # Совпадает с ollama list (без -instruct-q4_k_m)
EMBEDDING_MODEL = "nomic-embed-text:latest"  # ИСПРАВЛЕНО: добавлен тег :latest
# [PLAN C] Rerank временно ЗАМОРОЖЕН до 10.12.2025 из-за падений CORTEX.
# См. инцидент "Custom Rerank Pipeline crashes CORTEX, 27.11.2025".
# POST-PROCESSING rerank (строки ~416-431) оставлен для улучшения читаемости ответов.
RERANK_MODEL = "qwen2.5:14b"  # Используем ТОЛЬКО для post-processing (НЕ для retrieval)

# КРИТИЧНО: Ограничение параллелизма для 16GB VRAM
LLM_MAX_ASYNC = 1  # СТРОГО 1 (не перегружаем GPU)

# ============================================================
# СОЗДАНИЕ ДИРЕКТОРИЙ
# ============================================================

WORKING_DIR.mkdir(exist_ok=True, parents=True)

# Сообщение по умолчанию при отсутствии информации
NO_INFO_MESSAGE = "Информация не найдена в базе знаний."

# Карта технических терминов для расширения запросов (RU/EN)
TERM_SYNONYMS = [
    {
        "keywords_en": ["memory clock", "memoryclock", "vram clock"],
        "ru_expansions": [
            "частота памяти", "скорость памяти GPU",
            "разгон памяти видеокарты", "память видеокарты разгон"
        ]
    },
    {
        "keywords_en": ["msi afterburner", "afterburner"],
        "ru_expansions": [
            "MSI Afterburner настройки", "разгон через MSI Afterburner",
            "профили MSI Afterburner"
        ]
    },
    {
        "keywords_en": ["overclock", "gpu overclock"],
        "ru_expansions": [
            "разгон видеокарты", "разгон GPU", "профили разгона"
        ]
    }
]

def detect_language(text: str) -> str:
    """Простое определение языка (русский/английский) по алфавиту."""
    if re.search(r"[А-Яа-яЁё]", text):
        return "ru"
    return "en"


def build_augmented_query(original_query: str):
    """Расширяет запрос техническими синонимами для перекрытия RU/EN терминов."""
    lang = detect_language(original_query)
    lowered = original_query.lower()
    additions = []
    for entry in TERM_SYNONYMS:
        if any(keyword in lowered for keyword in entry.get("keywords_en", [])):
            additions.extend(entry.get("ru_expansions", []))
        if any(keyword in lowered for keyword in entry.get("keywords_ru", [])):
            additions.extend(entry.get("en_expansions", []))
    # Удаляем дубликаты, сохраняя порядок
    additions = list(dict.fromkeys(additions))

    if additions:
        prefix = "Helper keywords" if lang == "en" else "Дополнительные ключевые слова"
        augmented = f"{original_query}\n{prefix}: " + "; ".join(additions)
    else:
        augmented = original_query

    return augmented, additions, lang


def build_mode_chain(primary_mode: str) -> list[str]:
    """Формирует цепочку режимов с учётом fallback (TRIZ: динамичность).
    
    [PLAN C] Изменено: приоритет режима 'local' для стабильности.
    Hybrid временно исключён из цепочки из-за нестабильности.
    """
    preferred = primary_mode or "local"  # [PLAN C] Default: local вместо hybrid
    
    # [PLAN C] Новая цепочка: local → global → naive (без hybrid)
    if preferred == "naive":
        base_chain = ["naive", "local", "global"]
    elif preferred == "local":
        base_chain = ["local", "global", "naive"]
    elif preferred == "global":
        base_chain = ["global", "local", "naive"]
    elif preferred == "hybrid":
        # [PLAN C] Hybrid → local (более стабильный режим)
        base_chain = ["local", "global", "naive"]
    else:
        base_chain = ["local", "global", "naive"]
    
    # Сохраняем порядок, убираем дубликаты
    unique_chain = []
    for mode in base_chain:
        if mode not in unique_chain:
            unique_chain.append(mode)
    return unique_chain


def has_meaningful_result(result) -> bool:
    if not result:
        return False
    text = str(result).strip()
    if not text:
        return False
    normalized = text.lower()
    if NO_INFO_MESSAGE.lower() in normalized:
        return False
    # Короткие ответы чаще всего не содержат фактов
    return len(text) >= 60


async def execute_query_with_fallbacks(query_text: str, primary_mode: str):
    """Пытаемся получить ответ, переключаясь между режимами поиска.
    
    [PLAN C] Изменения для улучшения baseline:
    - top_k увеличен с 10 до 20 (больше кандидатов)
    - Приоритет режима 'local' для стабильности
    - enable_rerank=False для подавления WARNING (rerank модель не сконфигурирована)
    """
    tried_modes = []
    for mode in build_mode_chain(primary_mode):
        tried_modes.append(mode)
        result = await rag.aquery(
            query_text,
            param=QueryParam(
                mode=mode,
                top_k=20,  # [PLAN C] Увеличено с 10 до 20
                only_need_context=True,
                enable_rerank=False  # [FIX] Явно отключаем rerank для подавления WARNING
            )
        )
        if has_meaningful_result(result):
            return result, mode, tried_modes
    return NO_INFO_MESSAGE, tried_modes[-1] if tried_modes else primary_mode, tried_modes

# ============================================================
# LLM ОБЕРТКИ ДЛЯ OLLAMA
# ============================================================

# Создаём Ollama клиент с правильным base_url
from ollama import AsyncClient
ollama_client = AsyncClient(host=OLLAMA_BASE_URL)

async def llm_model_func(
    prompt, system_prompt=None, history_messages=[], **kwargs
) -> str:
    """LLM wrapper для Ollama (qwen2.5:14b) - ФИКСИРОВАННЫЙ"""
    messages = []
    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})
    messages.extend(history_messages)
    messages.append({"role": "user", "content": prompt})
    
    response = await ollama_client.chat(model=LLM_MODEL, messages=messages)
    return response['message']['content']

async def embedding_func(texts: list[str]) -> list[list[float]]:
    """Embedding wrapper для Ollama (nomic-embed-text) - ФИКСИРОВАННЫЙ"""
    results = []
    for text in texts:
        response = await ollama_client.embeddings(model=EMBEDDING_MODEL, prompt=text)
        results.append(response['embedding'])
    return results

async def rerank_func(query: str, documents: list[str], **kwargs) -> list[float]:
    """Rerank wrapper для переранжирования результатов поиска через qwen2.5:14b"""
    scores = []
    for doc in documents:
        # Формируем промпт для оценки релевантности (0-10)
        prompt = f"""Оцени релевантность документа для запроса по шкале 0-10.
Запрос: {query}

Документ: {doc[:500]}...

Ответь только числом от 0 до 10:"""
        
        response = await ollama_client.generate(model=RERANK_MODEL, prompt=prompt)
        try:
            score = float(response['response'].strip())
            scores.append(min(10.0, max(0.0, score)))  # Ограничение 0-10
        except:
            scores.append(5.0)  # Средний скор при ошибке парсинга
    
    return scores

# ============================================================
# ИНИЦИАЛИЗАЦИЯ LIGHTRAG
# ============================================================

# ВАЖНО: rag инициализируется в startup event, НЕ на уровне модуля
rag = None

# ============================================================
# FASTAPI СЕРВЕР С LIFESPAN
# ============================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager для управления startup/shutdown"""
    global rag
    
    # STARTUP
    print("=== Создание LightRAG instance ===")
    rag = LightRAG(
        working_dir=str(WORKING_DIR),
        workspace="",
        llm_model_func=llm_model_func,
        llm_model_name=LLM_MODEL,
        llm_model_max_async=LLM_MAX_ASYNC,
        embedding_func=EmbeddingFunc(
            embedding_dim=768,
            max_token_size=8192,
            func=embedding_func
        ),
        # ВРЕМЕННО ОТКЛЮЧЕН: rerank вызывает ошибку 'float' object has no attribute 'copy'
        # rerank_model_func=rerank_func,
    )
    print("[OK] LightRAG создан")
    print(f"[INFO] Rerank ОТКЛЮЧЕН (баг v1.4.9.8)")
    print(f"[INFO] Working dir: {WORKING_DIR}")
    
    print("=== Инициализация хранилищ ===")
    await rag.initialize_storages()
    print("[OK] Хранилища инициализированы")
    
    # Явная загрузка графа в память (рекомендация агента qwen2.5)
    graph_path = WORKING_DIR / "graph_chunk_entity_relation.graphml"
    if graph_path.exists():
        print(f"=== Попытка загрузки графа из {graph_path} ===")
        try:
            if hasattr(rag, 'load_graph'):
                await rag.load_graph(str(graph_path))
                print("[OK] ✅ Граф загружен в память методом load_graph()")
            elif hasattr(rag, 'graph_storage') and hasattr(rag.graph_storage, 'load_graph'):
                await rag.graph_storage.load_graph(str(graph_path))
                print("[OK] ✅ Граф загружен через graph_storage.load_graph()")
            else:
                print("[INFO] ⚠️ Метод load_graph() не найден, граф загружается автоматически")
        except Exception as e:
            logging.warning(f"Ошибка загрузки графа: {e}")
    else:
        logging.warning(f"Файл графа не найден: {graph_path}")
    
    from lightrag.kg.shared_storage import initialize_pipeline_status
    await initialize_pipeline_status()
    print("[OK] Pipeline status инициализирован")
    print("")
    
    yield  # Сервер работает
    
    # SHUTDOWN (если нужна очистка)
    print("[INFO] Shutdown - очистка ресурсов...")

app = FastAPI(
    title="AI Librarian - LightRAG Server",
    description="Граф знаний с векторным поиском на базе LightRAG",
    version="1.0.0",
    lifespan=lifespan
)

# ============================================================
# SECURITY MIDDLEWARE (ТРИЗ Принцип №11 "Заблаговременная амортизация")
# ============================================================

@app.middleware("http")
async def verify_api_key(request: Request, call_next):
    """
    Проверка API ключа для всех запросов (кроме /health).
    
    АРХИТЕКТУРНАЯ ИЗОЛЯЦИЯ:
    - /health — доступен без ключа (для мониторинга)
    - Все остальные эндпоинты — требуют заголовок X-API-KEY
    
    ТРИЗ Принцип №2 (Вынесение): Отделяем чувствительную часть барьером авторизации
    ТРИЗ Принцип №11 (Амортизация): Защита встроена ДО обработки запроса
    """
    # Разрешаем health check без авторизации (для мониторинга)
    if request.url.path == "/health":
        return await call_next(request)
    
    # Извлекаем API ключ из заголовков
    client_key = request.headers.get("X-API-KEY")
    
    # Валидация ключа
    if client_key != CORTEX_API_KEY:
        logging.warning(
            f"[SECURITY] Unauthorized access attempt from {request.client.host} "
            f"to {request.url.path} (key: {'missing' if not client_key else 'invalid'})"
        )
        return JSONResponse(
            status_code=status.HTTP_401_UNAUTHORIZED,
            content={
                "detail": "ACCESS DENIED: Cognitive Core is Isolated",
                "error": "Invalid or missing X-API-KEY header",
                "hint": "Provide valid X-API-KEY header for authentication"
            },
            headers={"WWW-Authenticate": "ApiKey"}
        )
    
    # Ключ валиден, пропускаем запрос
    logging.info(f"[SECURITY] Authorized access to {request.url.path}")
    return await call_next(request)

# Модели запросов
class QueryRequest(BaseModel):
    query: str
    mode: str = "hybrid"  # naive, local, global, hybrid

class InsertRequest(BaseModel):
    text: str
    description: str = ""

class BatchInsertRequest(BaseModel):
    texts: list[str]

# ============================================================
# API ENDPOINTS
# ============================================================

@app.get("/")
async def root():
    """Статус сервера"""
    return {
        "status": "online",
        "service": "AI Librarian LightRAG",
        "llm_model": LLM_MODEL,
        "embedding_model": EMBEDDING_MODEL,
        "working_dir": str(WORKING_DIR),
        "library_dir": str(LIBRARY_DIR)
    }

@app.get("/health")
async def health_check():
    """Проверка здоровья сервера"""
    return {
        "status": "healthy",
        "working_dir_exists": WORKING_DIR.exists(),
        "library_dir_exists": LIBRARY_DIR.exists()
    }

@app.get("/status")
async def get_status():
    """Получить статус индексации из kv_store"""
    try:
        kv_store_path = WORKING_DIR / "kv_store_doc_status.json"
        if not kv_store_path.exists():
            return {
                "processed_count": 0,
                "processing_count": 0,
                "failed_count": 0,
                "total_count": 0
            }
        
        import json
        with open(kv_store_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        processed = sum(1 for item in data.values() if item.get("status") == "processed")
        processing = sum(1 for item in data.values() if item.get("status") == "processing")
        failed = sum(1 for item in data.values() if item.get("status") == "failed")
        
        return {
            "processed_count": processed,
            "processing_count": processing,
            "failed_count": failed,
            "total_count": len(data)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/query")
async def query_graph(request: QueryRequest):
    """
    Запрос к графу знаний
    
    Режимы:
    - naive: Простой векторный поиск
    - local: Поиск с учетом локального контекста
    - global: Глобальный граф знаний
    - hybrid: Комбинированный (рекомендуется)
    """
    try:
        augmented_query, augmented_terms, detected_lang = build_augmented_query(request.query)
        result, effective_mode, tried_modes = await execute_query_with_fallbacks(
            augmented_query,
            request.mode
        )

        # [PLAN C] POST-PROCESSING: Улучшение контекста перед LLM
        # 1. Дедупликация по содержимому (убираем повторяющиеся фрагменты)
        # 2. Фильтрация слишком коротких чанков (шум)
        # 3. Переформулирование через LLM для улучшения читаемости
        if has_meaningful_result(result):
            # Простая дедупликация: разбиваем на предложения, убираем дубликаты
            sentences = re.split(r'[.!?]+\s+', str(result))
            unique_sentences = []
            seen = set()
            for sent in sentences:
                normalized = sent.strip().lower()
                if len(normalized) > 30 and normalized not in seen:  # Фильтр коротких и дубликатов
                    unique_sentences.append(sent.strip())
                    seen.add(normalized)
            
            # Ограничиваем контекст топ-8 предложений (из ~20 кандидатов)
            result = '. '.join(unique_sentences[:8]) + '.'
            
            # POST-PROCESSING rerank для улучшения читаемости (НЕ для retrieval!)
            if RERANK_MODEL:
                rerank_prompt = f"""Ты получил ответ от системы поиска по базе знаний.
Твоя задача: переформулировать ответ, сделав его более точным и релевантным запросу.

Запрос пользователя: {request.query}

Исходный ответ системы:
{result}

Переформулируй ответ, сохранив все важные факты, но улучшив структуру и ясность:"""

                reranked_response = await ollama_client.generate(
                    model=RERANK_MODEL,
                    prompt=rerank_prompt
                )
                result = reranked_response['response']

        return {
            "query": request.query,
            "mode": request.mode,
            "effective_mode": effective_mode,
            "tried_modes": tried_modes,
            "detected_language": detected_lang,
            "augmented_terms": augmented_terms,
            "response": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Query error: {str(e)}")

@app.post("/insert")
async def insert_document(request: InsertRequest):
    """Добавить один документ в граф с обработкой"""
    print(f"\n[INSERT] Received text: {len(request.text)} chars")
    print(f"[INSERT] Description: {request.description}")
    
    try:
        print("[INSERT] Calling rag.ainsert()...")
        # Таймаут 120 секунд для 700-символьного чанка
        await asyncio.wait_for(rag.ainsert(request.text), timeout=120.0)
        print("[INSERT] Success!")
        
        return {
            "status": "success",
            "message": "Document inserted and processed",
            "description": request.description
        }
    except Exception as e:
        import traceback
        error_msg = f"Insert error: {str(e)}"
        stack_trace = traceback.format_exc()
        print(f"\n[ERROR] {error_msg}")
        print(f"[ERROR] Stack trace:\n{stack_trace}")
        raise HTTPException(status_code=500, detail=f"{error_msg}\n{stack_trace}")

@app.post("/insert_batch")
async def insert_batch(request: BatchInsertRequest):
    """Массовая вставка документов"""
    try:
        for text in request.texts:
            await rag.ainsert(text)
        return {
            "status": "success",
            "message": f"Inserted {len(request.texts)} documents"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Batch insert error: {str(e)}")

@app.post("/index_library")
async def index_library():
    """
    Индексация всей библиотеки (CONSOLIDATED_LIBRARY)
    ВНИМАНИЕ: Может занять 10-15 минут для больших библиотек
    """
    if not LIBRARY_DIR.exists():
        raise HTTPException(status_code=404, detail="Library directory not found")
    
    try:
        indexed_files = []
        md_files = list(LIBRARY_DIR.glob("*.md"))
        
        for md_file in md_files:
            with open(md_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            await rag.ainsert(content)
            indexed_files.append(md_file.name)
        
        return {
            "status": "success",
            "message": f"Indexed {len(indexed_files)} files",
            "files": indexed_files
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Indexing error: {str(e)}")

@app.delete("/clear_cache")
async def clear_cache():
    """Очистить кэш LightRAG (удалить все индексы)"""
    try:
        # Удаление файлов кэша
        for item in WORKING_DIR.glob("*"):
            if item.is_file():
                item.unlink()
            elif item.is_dir():
                import shutil
                shutil.rmtree(item)
        
        return {
            "status": "success",
            "message": "Cache cleared"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Clear cache error: {str(e)}")

@app.post("/api/reindex")
async def trigger_reindex(watch_dir: str = None):
    r"""
    Триггер ручной переиндексации документов из указанной директории
    
    Args:
        watch_dir: Путь к директории с документами (по умолчанию E:\AGENTS\Documents_cleaned)
    
    Returns:
        Статус индексации с количеством обработанных файлов
    """
    import os
    from pathlib import Path
    
    if watch_dir is None:
        watch_dir = r"E:\AGENTS\Documents_cleaned"
    
    watch_path = Path(watch_dir)
    if not watch_path.exists():
        raise HTTPException(status_code=404, detail=f"Directory not found: {watch_dir}")
    
    try:
        indexed_files = []
        skipped_files = []
        
        # Сканируем все MD файлы в директории
        md_files = list(watch_path.rglob("*.md"))
        
        for md_file in md_files:
            try:
                with open(md_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Индексируем через LightRAG
                await rag.ainsert(content)
                indexed_files.append(str(md_file.relative_to(watch_path)))
            except Exception as file_error:
                skipped_files.append({
                    "file": str(md_file.relative_to(watch_path)),
                    "error": str(file_error)
                })
        
        return {
            "status": "success",
            "watch_dir": watch_dir,
            "total_files": len(md_files),
            "indexed": len(indexed_files),
            "skipped": len(skipped_files),
            "indexed_files": indexed_files[:10],  # Первые 10 для обзора
            "skipped_files": skipped_files
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Reindex error: {str(e)}")

@app.post("/api/git/push")
async def push_to_github(commit_message: str, branch: str = "main"):
    """
    Пуш изменений библиотеки в GitHub репозиторий
    
    Args:
        commit_message: Сообщение коммита
        branch: Ветка для пуша (по умолчанию main)
    
    Returns:
        Статус операции с информацией о коммите
    """
    import subprocess
    from pathlib import Path
    
    # Путь к репозиторию (AGENTS - корневой репозиторий)
    repo_path = Path(r"E:\AGENTS")
    
    if not repo_path.exists():
        raise HTTPException(status_code=404, detail=f"Repository not found: {repo_path}")
    
    try:
        # Проверяем, что это Git репозиторий
        git_dir = repo_path / ".git"
        if not git_dir.exists():
            raise HTTPException(status_code=400, detail="Not a Git repository")
        
        # Git add (добавляем все изменения в Documents_cleaned и library)
        subprocess.run(
            ["git", "add", "Documents_cleaned/", "librarian-agent/library/"],
            cwd=repo_path,
            check=True,
            capture_output=True,
            text=True
        )
        
        # Git commit
        commit_result = subprocess.run(
            ["git", "commit", "-m", commit_message],
            cwd=repo_path,
            check=True,
            capture_output=True,
            text=True
        )
        
        # Git push
        push_result = subprocess.run(
            ["git", "push", "origin", branch],
            cwd=repo_path,
            check=True,
            capture_output=True,
            text=True
        )
        
        # Получаем хеш последнего коммита
        commit_hash_result = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=repo_path,
            check=True,
            capture_output=True,
            text=True
        )
        commit_hash = commit_hash_result.stdout.strip()
        
        # Получаем количество измененных файлов
        files_changed_result = subprocess.run(
            ["git", "diff", "--name-only", "HEAD~1", "HEAD"],
            cwd=repo_path,
            check=True,
            capture_output=True,
            text=True
        )
        files_changed = files_changed_result.stdout.strip().split('\n')
        files_changed = [f for f in files_changed if f]  # Убираем пустые строки
        
        return {
            "status": "success",
            "commit_hash": commit_hash,
            "commit_message": commit_message,
            "branch": branch,
            "files_changed": len(files_changed),
            "changed_files": files_changed[:10]  # Первые 10 для обзора
        }
    except subprocess.CalledProcessError as e:
        error_message = e.stderr if e.stderr else str(e)
        raise HTTPException(status_code=500, detail=f"Git operation failed: {error_message}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Git push error: {str(e)}")

# ============================================================
# ЗАПУСК СЕРВЕРА
# ============================================================

if __name__ == "__main__":
    print("=" * 50)
    print("AI LIBRARIAN - LIGHTRAG SERVER")
    print("=" * 50)
    print(f"Working Dir: {WORKING_DIR}")
    print(f"Library Dir: {LIBRARY_DIR}")
    print(f"LLM Model: {LLM_MODEL}")
    print(f"Embedding: {EMBEDDING_MODEL}")
    print(f"Max Async: {LLM_MAX_ASYNC} (optimized for 16GB VRAM)")
    print("=" * 50)
    print(f"\nAPI: http://localhost:8004")
    print(f"Docs: http://localhost:8004/docs\n")
    
    uvicorn.run(
        app,
        host="127.0.0.1",  # Windows-compatible bind address
        port=8004,
        log_level="info"
    )

