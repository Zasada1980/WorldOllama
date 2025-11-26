import os
import json
import time
import requests
from pathlib import Path
import sys

# === НАСТРОЙКИ ===
SERVER_URL = "http://localhost:8003"
LIBRARY_DIR = r"E:\AGENTS\Documents_cleaned"
# БЕЗОПАСНО: 700 символов (~175 токенов для быстрой обработки)
CHUNK_SIZE_CHARS = 700  

def wait_for_server():
    print("Waiting for server...")
    for i in range(30):
        try:
            resp = requests.get(f"{SERVER_URL}/health", timeout=2)
            if resp.status_code == 200:
                print("Server ready!")
                return True
        except:
            time.sleep(2)
            if i % 5 == 0: print(".", end="", flush=True)
    return False

def ingest_file(file_path):
    print(f"\nProcessing: {file_path.name}")
    try:
        # Читаем файл целиком
        text = file_path.read_text(encoding="utf-8", errors="ignore")
        if not text.strip():
            print("   Empty file, skip.")
            return
            
        total_chars = len(text)
        
        # Если файл меньше лимита, отправляем целиком
        if total_chars < CHUNK_SIZE_CHARS:
            print(f"   Sending whole ({total_chars} chars)...")
            payload = {"text": text, "metadata": {"source": file_path.name}}
            try:
                response = requests.post(f"{SERVER_URL}/insert", json=payload, timeout=300)
                if response.status_code == 200:
                    print("   OK")
                else:
                    print(f"   Error: {response.status_code}")
            except Exception as e:
                print(f"   Network error: {e}")
            return

        # Если файл большой - РЕЖЕМ
        print(f"   Large file ({total_chars} chars). Chunking by {CHUNK_SIZE_CHARS}...")
        chunks = [text[i:i+CHUNK_SIZE_CHARS] for i in range(0, total_chars, CHUNK_SIZE_CHARS)]
        total_chunks = len(chunks)
        
        for i, chunk in enumerate(chunks):
            chunk_part = i + 1
            print(f"   Chunk {chunk_part}/{total_chunks} ({len(chunk)} chars)... ", end="", flush=True)
            
            payload = {
                "text": chunk, 
                "metadata": {"source": f"{file_path.name}_part_{chunk_part}"}
            }
            
            try:
                response = requests.post(f"{SERVER_URL}/insert", json=payload, timeout=180)  # 3 минуты
                if response.status_code == 200:
                    print("OK")
                    time.sleep(20)  # Пауза 20 сек между чанками
                else:
                    print(f"ERROR {response.status_code}: {response.text}")
                    time.sleep(30)
            except requests.Timeout:
                print(f"TIMEOUT after 900s")
                time.sleep(30)
            except Exception as e:
                print(f"FAILURE: {type(e).__name__}: {e}")
                time.sleep(10)

    except Exception as e:
        print(f"Critical error reading file: {e}")

def main():
    # 1. Проверяем сервер
    if not wait_for_server():
        print("Server unavailable. Run lightrag_server.py in another window.")
        return

    # 2. Ищем файлы
    root_path = Path(LIBRARY_DIR)
    if not root_path.exists():
        print(f"Directory not found: {LIBRARY_DIR}")
        return

    files = list(root_path.glob("**/*.txt")) + list(root_path.glob("**/*.md")) + list(root_path.glob("**/*.json"))
    print(f"Found files: {len(files)}")
    
    # 3. Загружаем
    for file in files:
        ingest_file(file)
        
    print("\nIngestion complete!")

if __name__ == "__main__":
    main()
