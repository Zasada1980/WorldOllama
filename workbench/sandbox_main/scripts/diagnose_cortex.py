#!/usr/bin/env python3
"""
CORTEX BIOPSY - Diagnostic Tool for LightRAG
TD-006 Troubleshooting (SESA3002a Protocol)

Direct test of LightRAG brain without FastAPI layer
"""

import os
import sys
from pathlib import Path

# --- КОНФИГУРАЦИЯ (Сверить с реальными путями!) ---
WORKING_DIR = Path(r"E:\WORLD_OLLAMA\services\lightrag\data")  # Где лежит индекс
OLLAMA_HOST = "http://localhost:11434"
LLM_MODEL = "qwen2.5:14b-instruct-q4_k_m"
EMBED_MODEL = "nomic-embed-text"

print("=" * 60)
print("CORTEX BIOPSY - LightRAG Diagnostic")
print("=" * 60)

print(f"\n--> PROBE: Checking directory {WORKING_DIR}")
if not WORKING_DIR.exists():
    print("!!! CRITICAL: Working directory does not exist!")
    sys.exit(1)
else:
    print("✅ Working directory exists")

# Проверка файлов
print(f"\n--> PROBE: Scanning files in {WORKING_DIR}")
files = list(WORKING_DIR.glob("*"))
for f in files:
    size_mb = f.stat().st_size / (1024 * 1024) if f.is_file() else 0
    print(f"  {'[DIR]' if f.is_dir() else '[FILE]'} {f.name:40s} {size_mb:8.2f} MB")

# Проверка критических файлов
critical_files = [
    "graph_chunk_entity_relation.graphml",
    "kv_store_full_docs.json",
    "vdb_entities.json",
    "vdb_chunks.json"
]

print("\n--> PROBE: Critical files check:")
missing = []
for cf in critical_files:
    if (WORKING_DIR / cf).exists():
        size = (WORKING_DIR / cf).stat().st_size / (1024 * 1024)
        print(f"  ✅ {cf:40s} ({size:.2f} MB)")
    else:
        print(f"  ❌ {cf:40s} MISSING!")
        missing.append(cf)

if missing:
    print(f"\n!!! CRITICAL: Missing files: {missing}")
    print("Index may be corrupted or incomplete")
    sys.exit(1)

# Импорт LightRAG
print("\n--> PROBE: Importing LightRAG...")
try:
    from lightrag import LightRAG, QueryParam
    from lightrag.llm.ollama import ollama_model_complete, ollama_embed
    from lightrag.utils import EmbeddingFunc
    print("✅ LightRAG imported successfully")
except ImportError as e:
    print(f"!!! CRITICAL: Failed to import LightRAG: {e}")
    sys.exit(1)

async def test_brain():
    """Test LightRAG brain directly"""
    print("\n" + "=" * 60)
    print("INITIALIZING LIGHTRAG BRAIN")
    print("=" * 60)
    
    try:
        # Создание embedding function
        print("--> Creating embedding function...")
        embedding_func = EmbeddingFunc(
            embedding_dim=768,
            max_token_size=8192,
            func=lambda texts: ollama_embed(
                texts, 
                embed_model=EMBED_MODEL,
                host=OLLAMA_HOST
            )
        )
        print("✅ Embedding function created")
        
        # Инициализация LightRAG
        print(f"--> Initializing LightRAG with working_dir={WORKING_DIR}")
        rag = LightRAG(
            working_dir=str(WORKING_DIR),
            llm_model_func=ollama_model_complete,
            llm_model_name=LLM_MODEL,
            llm_model_kwargs={"host": OLLAMA_HOST, "options": {"num_ctx": 4096}},
            embedding_func=embedding_func
        )
        print("✅ LightRAG initialized")
        
        # --- [SESA FIX: FORCE IGNITION] ---
        print("\n--> PROBE: ⚡ WARMING UP STORAGE ENGINES...")
        try:
            if hasattr(rag, 'initialize_storages'):
                await rag.initialize_storages()
                print("✅ Engines STARTED via initialize_storages()")
            elif hasattr(rag, 'storage_init'):
                await rag.storage_init()
                print("✅ Engines STARTED via storage_init()")
            else:
                print("⚠️ No initialization method found, attempting direct access...")
        except Exception as e:
            print(f"⚠️ Storage initialization warning: {e}")
            print("    Continuing anyway...")
        # ----------------------------------
        
        # Проверка графа (если доступно)
        print("\n--> PROBE: Checking graph structure...")
        if hasattr(rag, 'chunk_entity_relation_graph'):
            graph = rag.chunk_entity_relation_graph
            if graph is not None:
                num_nodes = graph.number_of_nodes() if hasattr(graph, 'number_of_nodes') else "N/A"
                num_edges = graph.number_of_edges() if hasattr(graph, 'number_of_edges') else "N/A"
                print(f"✅ Graph loaded: {num_nodes} nodes, {num_edges} edges")
            else:
                print("⚠️ Graph attribute is None")
        else:
            print("⚠️ No graph attribute found")
        
        # Тестовые запросы
        print("\n" + "=" * 60)
        print("TEST QUERIES")
        print("=" * 60)
        
        test_queries = [
            ("WORLD_OLLAMA", "local"),
            ("SSL certificate", "hybrid"),
            ("LightRAG", "naive")
        ]
        
        for query_text, mode in test_queries:
            print(f"\n--> Query: '{query_text}' (mode={mode})")
            try:
                result = await rag.aquery(
                    query_text, 
                    param=QueryParam(mode=mode, top_k=3)
                )
                
                if result and len(result.strip()) > 0:
                    preview = result[:300] + "..." if len(result) > 300 else result
                    print(f"✅ RESULT ({len(result)} chars):\n{preview}")
                else:
                    print("❌ Empty result")
                    
            except Exception as e:
                print(f"❌ Query failed: {e}")
        
        print("\n" + "=" * 60)
        print("BIOPSY COMPLETE")
        print("=" * 60)
        
    except Exception as e:
        print(f"\n!!! CRITICAL ERROR during initialization:")
        print(f"{type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    return True

if __name__ == "__main__":
    import asyncio
    
    print("\n--> Starting async test...")
    try:
        success = asyncio.run(test_brain())
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️ Interrupted by user")
        sys.exit(130)
    except Exception as e:
        print(f"\n!!! FATAL ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
