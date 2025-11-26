"""
MINIMAL Open WebUI Launcher - обход lifespan проблемы
Стратегия: создать FastAPI app БЕЗ context manager
"""
import sys
sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')

print("==> MINIMAL: Importing FastAPI and Uvicorn")
from fastapi import FastAPI
import uvicorn

print("==> MINIMAL: Creating minimal FastAPI app")
app = FastAPI(title="OpenWebUI Minimal Test")

@app.get("/health")
async def health():
    return {"status": "alive", "mode": "minimal_launcher"}

@app.get("/")
async def root():
    return {"message": "Open WebUI Minimal Mode - diagnostic launcher"}

print("==> MINIMAL: Starting server on port 3100")
uvicorn.run(app, host="0.0.0.0", port=3100)
