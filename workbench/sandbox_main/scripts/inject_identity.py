"""
SESA MEMORY INJECTOR
Операция: Принудительное внедрение system_identity.txt в граф знаний Cortex
Принцип ТРИЗ №16: Частичное действие (1% времени, 100% результата)
"""
import asyncio
import os
from lightrag import LightRAG, QueryParam
from lightrag.utils import EmbeddingFunc
from lightrag.kg.shared_storage import initialize_pipeline_status
from ollama import AsyncClient

# КОНФИГУРАЦИЯ
WORKING_DIR = r"E:\AI_Librarian_Core\lightrag_cache"
DOC_PATH = r"E:\WORLD_OLLAMA\library\raw_documents\system_identity.txt"
OLLAMA_BASE_URL = "http://localhost:11434"
LLM_MODEL = "qwen2.5:14b"
EMBEDDING_MODEL = "nomic-embed-text"

# Ollama клиент
ollama_client = AsyncClient(host=OLLAMA_BASE_URL)

async def llm_model_func(prompt, system_prompt=None, history_messages=[], **kwargs) -> str:
    """LLM wrapper для Ollama"""
    messages = []
    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})
    messages.extend(history_messages)
    messages.append({"role": "user", "content": prompt})
    
    response = await ollama_client.chat(model=LLM_MODEL, messages=messages)
    return response['message']['content']

async def embedding_func(texts: list[str]) -> list[list[float]]:
    """Embedding wrapper для Ollama"""
    results = []
    for text in texts:
        response = await ollama_client.embeddings(model=EMBEDDING_MODEL, prompt=text)
        results.append(response['embedding'])
    return results

async def main():
    print(f"\n💉 SESA INJECTOR: Загрузка идентичности из {DOC_PATH}...")
    
    # Инициализация (подключение к существующему графу)
    rag = LightRAG(
        working_dir=WORKING_DIR,
        workspace="",
        llm_model_func=llm_model_func,
        llm_model_name=LLM_MODEL,
        llm_model_max_async=1,
        embedding_func=EmbeddingFunc(
            embedding_dim=768,
            max_token_size=8192,
            func=embedding_func
        )
    )
    
    # КРИТИЧНО: Инициализация хранилищ
    print("🔧 Инициализация хранилищ...")
    await rag.initialize_storages()
    await initialize_pipeline_status()
    print("✅ Хранилища готовы")

    # Принудительная вставка
    if os.path.exists(DOC_PATH):
        with open(DOC_PATH, "r", encoding="utf-8") as f:
            content = f.read()
            print(f"📄 Размер документа: {len(content)} символов")
            print("🔄 Выполняется инъекция в граф...")
            await rag.ainsert(content)
        print("✅ SUCCESS: System Identity внедрён в граф знаний.")
    else:
        print(f"❌ ERROR: Файл {DOC_PATH} не найден!")
        return

    # Smoke Test на месте
    print("\n🔎 VERIFYING MEMORY (Smoke Test)...")
    try:
        ans = await rag.aquery(
            "Что такое CORTEX и на каком порту он работает? Из чего состоит Neuro-Terminal?", 
            param=QueryParam(mode="local")
        )
        print(f"\n{'='*60}")
        print("🗣️ CORTEX MEMORY CHECK (после инъекции):")
        print(f"{'='*60}")
        print(ans)
        print(f"{'='*60}\n")
        
        # Проверка на ключевые слова
        if "8004" in ans or "Cortex" in ans or "LightRAG" in ans:
            print("✅ MIRROR TEST PASSED: Система знает о себе!")
        else:
            print("⚠️ WARNING: Ответ не содержит ожидаемых данных самоидентификации.")
            
    except Exception as e:
        print(f"⚠️ Verification failed: {e}")

if __name__ == "__main__":
    asyncio.run(main())
