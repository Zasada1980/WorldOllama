#!/usr/bin/env python3
"""
Initial Indexing Script for CORTEX (TD-006)
SESA3002a Protocol: Clean index creation from 131 files

This script builds the LightRAG index from scratch using
documents in E:\\WORLD_OLLAMA\\library\\raw_documents

NO OLD CACHE - Pure WORLD_OLLAMA state
"""

import os
import time
import requests
from pathlib import Path
import sys

# === TASK 16.1: Dynamic Project Root ===
if "WORLD_OLLAMA_ROOT" in os.environ:
    PROJECT_ROOT = Path(os.environ["WORLD_OLLAMA_ROOT"])
else:
    # Script: services/lightrag/init_index.py → root = 2 levels up
    PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

print(f"[TASK 16.1] Project root: {PROJECT_ROOT}")

# === CONFIGURATION ===
SERVER_URL = "http://localhost:8004"
API_KEY = os.getenv("CORTEX_API_KEY", "sesa-secure-core-v1")  # Default API key
LIBRARY_DIR = PROJECT_ROOT / "library" / "raw_documents"
CHUNK_SIZE_CHARS = 4000  # Increased chunk size (approx <= ~1k tokens)
DELAY_BETWEEN_CHUNKS = 20  # Seconds (GPU cooling)

# HTTP headers with authentication
HEADERS = {"X-API-KEY": API_KEY}

def wait_for_server(max_attempts=30):
    """Wait for LightRAG server to be ready"""
    print("Waiting for CORTEX server...")
    for i in range(max_attempts):
        try:
            resp = requests.get(f"{SERVER_URL}/health", timeout=2)
            if resp.status_code == 200:
                print("✅ CORTEX online!")
                return True
        except:
            time.sleep(2)
            if i % 5 == 0: 
                print(".", end="", flush=True)
    print("\n❌ Server timeout")
    return False

def ingest_file(file_path, chunk_index=0):
    """Ingest single file with chunking support"""
    print(f"\n📄 Processing: {file_path.name}")
    
    try:
        # Read file content
        text = file_path.read_text(encoding="utf-8", errors="ignore")
        if not text.strip():
            print("   ⚠️ Empty file, skipping")
            return chunk_index
            
        total_chars = len(text)
        
        # Small file: send whole
        if total_chars < CHUNK_SIZE_CHARS:
            print(f"   📦 Sending whole file ({total_chars} chars)...")
            payload = {
                "text": text, 
                "description": f"Source: {file_path.name}"
            }
            
            try:
                response = requests.post(
                    f"{SERVER_URL}/insert", 
                    json=payload, 
                    headers=HEADERS,
                    timeout=300
                )
                if response.status_code == 200:
                    chunk_index += 1
                    print(f"   ✅ OK (chunk #{chunk_index})")
                else:
                    print(f"   ❌ Error: {response.status_code} - {response.text[:200]}")
            except Exception as e:
                print(f"   ❌ Network error: {e}")
            
            return chunk_index

        # Large file: chunk it
        print(f"   📊 Large file ({total_chars} chars). Chunking by {CHUNK_SIZE_CHARS}...")
        chunks = [
            text[i:i+CHUNK_SIZE_CHARS] 
            for i in range(0, total_chars, CHUNK_SIZE_CHARS)
        ]
        total_chunks = len(chunks)
        
        for i, chunk in enumerate(chunks):
            chunk_part = i + 1
            print(f"   🔹 Chunk {chunk_part}/{total_chunks} ({len(chunk)} chars)... ", end="", flush=True)
            
            payload = {
                "text": chunk, 
                "description": f"Source: {file_path.name}_part_{chunk_part}"
            }
            
            try:
                response = requests.post(
                    f"{SERVER_URL}/insert", 
                    json=payload, 
                    headers=HEADERS,
                    timeout=180
                )
                if response.status_code == 200:
                    chunk_index += 1
                    print(f"✅ (chunk #{chunk_index})")
                    time.sleep(DELAY_BETWEEN_CHUNKS)  # GPU cooldown
                else:
                    print(f"❌ ERROR {response.status_code}: {response.text[:200]}")
                    time.sleep(30)
            except requests.Timeout:
                print(f"❌ TIMEOUT (180s)")
                time.sleep(30)
            except Exception as e:
                print(f"❌ {type(e).__name__}: {e}")
                time.sleep(10)
        
        return chunk_index
        
    except Exception as e:
        print(f"   ❌ File error: {e}")
        return chunk_index

def main():
    """Main indexing workflow"""
    print("=" * 60)
    print("CORTEX IGNITION - INITIAL INDEXING (TD-006)")
    print("=" * 60)
    print(f"📂 Library: {LIBRARY_DIR}")
    print(f"🌐 Server: {SERVER_URL}")
    print(f"🧬 Chunk size: {CHUNK_SIZE_CHARS} chars")
    print("=" * 60)
    
    # Check server health
    if not wait_for_server():
        print("\n❌ ABORT: Server not responding")
        sys.exit(1)
    
    # Get file list
    files = sorted(LIBRARY_DIR.glob("*.txt"))
    total_files = len(files)
    
    if total_files == 0:
        print(f"\n⚠️ No .txt files found in {LIBRARY_DIR}")
        sys.exit(1)
    
    print(f"\n📚 Found {total_files} files")
    print("=" * 60)
    
    # Process files
    start_time = time.time()
    chunk_counter = 0
    
    for idx, file_path in enumerate(files, 1):
        print(f"\n[{idx}/{total_files}] ", end="")
        chunk_counter = ingest_file(file_path, chunk_counter)
    
    # Summary
    elapsed = time.time() - start_time
    print("\n" + "=" * 60)
    print("✅ INDEXING COMPLETE")
    print("=" * 60)
    print(f"📊 Files processed: {total_files}")
    print(f"🧬 Total chunks: {chunk_counter}")
    print(f"⏱️ Time: {elapsed/60:.1f} minutes")
    print("=" * 60)

if __name__ == "__main__":
    main()
