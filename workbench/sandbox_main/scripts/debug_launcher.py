"""
SESA DEBUG LAUNCHER for Open WebUI
Цель: Перехват скрытых исключений при запуске, которые глушатся uvicorn/fastapi
"""
import os
import sys

# Принудительно ставим UTF-8 внутри Python до всего
sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')

print("--> SESA DEBUG: Python version:", sys.version)
print("--> SESA DEBUG: Working directory:", os.getcwd())
print("--> SESA DEBUG: Environment check:")
print(f"    DATA_DIR: {os.getenv('DATA_DIR', 'NOT SET')}")
print(f"    OLLAMA_BASE_URL: {os.getenv('OLLAMA_BASE_URL', 'NOT SET')}")
print(f"    PYTHONUTF8: {os.getenv('PYTHONUTF8', 'NOT SET')}")

try:
    print("--> SESA DEBUG: Attempting import open_webui.main")
    from open_webui.main import app
    print("--> SESA DEBUG: Import successful, starting UVICORN with explicit Server control")
    
    import uvicorn
    import asyncio
    
    # Явный контроль через Server API для перехвата lifespan errors
    config = uvicorn.Config(app, host="0.0.0.0", port=3100, log_level="debug")
    server = uvicorn.Server(config)
    
    print("--> SESA DEBUG: Running server.serve()")
    asyncio.run(server.serve())
    
except Exception as e:
    print(f"!!! CRITICAL ERROR !!! {type(e).__name__}: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
