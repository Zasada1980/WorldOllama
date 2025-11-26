"""
Индексация папки Documents через LightRAG.
Автоматически находит все .txt файлы и отправляет с micro-chunking.
"""
import os
import json
import time
import requests
from pathlib import Path

# === НАСТРОЙКИ ===
SERVER_URL = "http://localhost:8003"
DOCUMENTS_DIR = r"E:\AGENTS\Documents"
CHUNK_SIZE_CHARS = 10000  # 10KB chunks для надежности
REQUEST_TIMEOUT = 600  # 10 минут на chunk
CHUNK_DELAY = 3  # Пауза между chunks (секунды)

def wait_for_server():
    """Проверка доступности сервера"""
    print("⏳ Проверка сервера LightRAG...")
    for i in range(30):
        try:
            resp = requests.get(f"{SERVER_URL}/health", timeout=2)
            if resp.status_code == 200:
                print("✅ Сервер готов!")
                return True
        except:
            time.sleep(2)
            if i % 5 == 0: 
                print(".", end="", flush=True)
    print("\n❌ Сервер не отвечает!")
    return False

def ingest_file(file_path):
    """Индексация одного файла"""
    print(f"\n📄 {file_path.name}")
    
    try:
        text = file_path.read_text(encoding="utf-8", errors="ignore")
        if not text.strip():
            print("   ⚠️ Пустой файл, пропуск")
            return {"status": "skipped", "reason": "empty"}
            
        total_chars = len(text)
        
        # Если файл меньше chunk size - отправляем целиком
        if total_chars < CHUNK_SIZE_CHARS:
            print(f"   📤 Отправка целиком ({total_chars} симв)... ", end="", flush=True)
            payload = {
                "text": text, 
                "description": f"Source: {file_path.name}"
            }
            try:
                response = requests.post(
                    f"{SERVER_URL}/insert", 
                    json=payload, 
                    timeout=REQUEST_TIMEOUT
                )
                if response.status_code == 200:
                    print("✅ OK")
                    return {"status": "success", "chunks": 1}
                else:
                    print(f"❌ Ошибка {response.status_code}")
                    return {"status": "error", "code": response.status_code}
            except requests.exceptions.Timeout:
                print("❌ Timeout")
                return {"status": "timeout"}
            except Exception as e:
                print(f"❌ {e}")
                return {"status": "error", "error": str(e)}
        
        # Большой файл - режем на chunks
        print(f"   🔪 Большой файл ({total_chars} симв). Chunks по {CHUNK_SIZE_CHARS}...")
        chunks = []
        for i in range(0, total_chars, CHUNK_SIZE_CHARS):
            chunks.append(text[i:i+CHUNK_SIZE_CHARS])
        
        total_chunks = len(chunks)
        success_count = 0
        
        for i, chunk in enumerate(chunks):
            chunk_num = i + 1
            print(f"   📤 Chunk {chunk_num}/{total_chunks} ({len(chunk)} симв)... ", end="", flush=True)
            
            payload = {
                "text": chunk, 
                "description": f"Source: {file_path.name} (part {chunk_num}/{total_chunks})"
            }
            
            try:
                response = requests.post(
                    f"{SERVER_URL}/insert", 
                    json=payload, 
                    timeout=REQUEST_TIMEOUT
                )
                if response.status_code == 200:
                    print("✅")
                    success_count += 1
                    time.sleep(CHUNK_DELAY)  # Пауза для стабильности
                else:
                    print(f"❌ {response.status_code}")
                    time.sleep(CHUNK_DELAY * 2)  # Длинная пауза при ошибке
            except requests.exceptions.Timeout:
                print("❌ Timeout")
                time.sleep(CHUNK_DELAY * 2)
            except Exception as e:
                print(f"❌ {e}")
                time.sleep(CHUNK_DELAY)
        
        return {
            "status": "success" if success_count == total_chunks else "partial",
            "chunks": total_chunks,
            "success": success_count
        }
        
    except Exception as e:
        print(f"   ❌ Критическая ошибка: {e}")
        return {"status": "critical_error", "error": str(e)}

def main():
    """Главная функция"""
    print("=" * 60)
    print("ИНДЕКСАЦИЯ БИБЛИОТЕКИ DOCUMENTS")
    print("=" * 60)
    
    # 1. Проверка сервера
    if not wait_for_server():
        return
    
    # 2. Поиск файлов
    root_path = Path(DOCUMENTS_DIR)
    if not root_path.exists():
        print(f"❌ Директория не найдена: {DOCUMENTS_DIR}")
        return
    
    files = sorted(root_path.glob("*.txt"))  # Сортируем для стабильного порядка
    total_files = len(files)
    
    # Проверяем сколько уже обработано из kv_store
    try:
        response = requests.get(f"{SERVER_URL}/status", timeout=10)
        if response.status_code == 200:
            data = response.json()
            already_processed = data.get("processed_count", 0)
            print(f"\n📊 Статус:")
            print(f"   Уже обработано: {already_processed} документов")
            print(f"   Всего файлов: {total_files}")
            print(f"   Осталось: {total_files - already_processed}")
            
            # Пропускаем первые N файлов (они уже в kv_store)
            if already_processed > 0:
                files = files[already_processed:]
                print(f"   ⏭️ Пропускаю первые {already_processed} файлов\n")
        else:
            print(f"\n⚠️ Не могу получить статус (HTTP {response.status_code}), индексирую все файлы\n")
    except Exception as e:
        print(f"\n⚠️ Ошибка при проверке статуса: {e}, индексирую все файлы\n")
    
    print(f"\n📚 К обработке: {len(files)} файлов")
    
    # 3. Индексация
    results = {}
    start_time = time.time()
    
    for idx, file in enumerate(files, 1):
        print(f"\n[{idx}/{total_files}]", end=" ")
        result = ingest_file(file)
        results[file.name] = result
    
    # 4. Итоги
    elapsed = time.time() - start_time
    print("\n" + "=" * 60)
    print("📊 ИТОГИ ИНДЕКСАЦИИ")
    print("=" * 60)
    
    success = sum(1 for r in results.values() if r["status"] == "success")
    partial = sum(1 for r in results.values() if r["status"] == "partial")
    errors = sum(1 for r in results.values() if r["status"] in ["error", "timeout", "critical_error"])
    skipped = sum(1 for r in results.values() if r["status"] == "skipped")
    
    total_chunks = sum(r.get("chunks", 0) for r in results.values())
    
    print(f"✅ Успешно: {success}/{total_files}")
    print(f"⚠️ Частично: {partial}/{total_files}")
    print(f"❌ Ошибки: {errors}/{total_files}")
    print(f"⏭️ Пропущено: {skipped}/{total_files}")
    print(f"📦 Всего chunks: {total_chunks}")
    print(f"⏱️ Время: {elapsed/60:.1f} минут")
    
    # Сохранение отчета
    report_path = Path("ingest_report.json")
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump({
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "total_files": total_files,
            "success": success,
            "partial": partial,
            "errors": errors,
            "skipped": skipped,
            "total_chunks": total_chunks,
            "elapsed_minutes": elapsed/60,
            "results": results
        }, f, ensure_ascii=False, indent=2)
    
    print(f"\n📄 Отчет сохранен: {report_path.absolute()}")
    print("\n🎉 Индексация завершена!")

if __name__ == "__main__":
    main()
