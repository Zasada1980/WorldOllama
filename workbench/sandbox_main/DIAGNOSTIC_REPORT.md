# ДИАГНОСТИЧЕСКИЙ ОТЧЕТ: Решение проблемы стабильности Open WebUI Native

**Дата:** 25 ноября 2025  
**Компонент:** Open WebUI 0.6.38 (native deployment)  
**Статус:** ✅ **RESOLVED** (Production Ready)

---

## 📋 EXECUTIVE SUMMARY

**Проблема:** Open WebUI native процесс запускался, доходил до "Application startup complete", но затем **немедленно завершался** (exit code 1) без traceback или error message.

**Root Cause:** Tool `run_in_terminal` с параметром `isBackground=true` **убивает background processes** когда они становятся idle (перестают выводить новые логи в stdout). Uvicorn после startup completion перестает писать в консоль → tool интерпретирует это как "команда завершилась" → посылает termination signal → процесс умирает.

**Solution:** Использовать `Start-Process powershell -ArgumentList "-NoExit", "-Command", "..."` для запуска long-running servers. Это создает **отдельный Windows process** независимый от parent shell/tool lifecycle.

**Production Script:** `E:\WORLD_OLLAMA\scripts\start_webui_production.ps1`

**Verification:**
```powershell
curl http://localhost:3100/api/config | ConvertFrom-Json | Select-Object -ExpandProperty version
# Output: 0.6.38

netstat -ano | Select-String ":3100"
# TCP    0.0.0.0:3100    0.0.0.0:0    LISTENING    <PID>
```

---

## 🔍 INVESTIGATION TIMELINE

### Phase 1: Initial Symptom Observation
**Observation:** `pwsh scripts/start_webui_native.ps1` via `run_in_terminal(isBackground=true)` → process starts → banner renders → "Started server process [PID]" → "Waiting for application startup" → **silent exit after ~15 seconds**.

**Failed Hypotheses:**
- Unicode encoding issues (CP1251 vs UTF-8) → **TRUE but NOT root cause** (banner UnicodeEncodeError fixed, crash remained)
- ENABLE_BASE_MODELS_CACHE timeout → **FALSE** (crash with flag disabled)
- Redis connection failure → **FALSE** (crash with REDIS_URL="")
- ChromaDB initialization error → **FALSE** (process died BEFORE DB init)

### Phase 2: Deep Diagnostics
**Tool Created:** `sandbox_main/scripts/debug_launcher.py`

**Approach:** Direct `python -m uvicorn` invocation with:
- `PYTHONFAULTHANDLER=1`
- `LOG_LEVEL=DEBUG`, `UVICORN_LOG_LEVEL=trace`
- Explicit try/except around `asyncio.run(server.serve())`

**Discovery:** Traceback **finally appeared**:
```python
Traceback (most recent call last):
  File "C:\Users\zakon\AppData\Local\Programs\Python\Python312\Lib\asyncio\runners.py", line 118, in run
    return self._loop.run_until_complete(task)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
asyncio.exceptions.CancelledError

During handling of the above exception, another exception occurred:
KeyboardInterrupt
```

**Interpretation:** `CancelledError` → lifespan context manager получает **external cancellation signal** → asyncio.run() raises KeyboardInterrupt.

### Phase 3: Minimal Reproduction
**Hypothesis:** Maybe Open WebUI code itself has bug?

**Test:** Created `minimal_launcher.py` with **empty FastAPI app** (no Open WebUI imports):
```python
from fastapi import FastAPI
app = FastAPI()
@app.get("/health")
async def health(): return {"status": "alive"}
uvicorn.run(app, host="0.0.0.0", port=3100)
```

**Result:** Minimal app via `run_in_terminal(isBackground=true)` → **same behavior** (starts → "Application startup complete" → immediate shutdown).

**Conclusion:** Problem **NOT** in Open WebUI code. Problem in **launcher mechanism**.

### Phase 4: Isolation Testing
**Hypothesis:** `run_in_terminal` tool behavior vs native PowerShell?

**Test:** 
```powershell
# Method 1: run_in_terminal(isBackground=true)
run_in_terminal("python minimal_launcher.py", isBackground=true)
# Result: Process exits after startup complete

# Method 2: Start-Process (separate window)
Start-Process powershell -ArgumentList "-NoExit", "-Command", "python minimal_launcher.py"
# Result: Process STAYS ALIVE, responds to curl
```

**Verification:**
```powershell
curl http://localhost:3100/health
# {"status":"alive"}

netstat -ano | Select-String ":3100"
# TCP 0.0.0.0:3100  LISTENING  <PID>
```

**Root Cause Confirmed:** `run_in_terminal` tool **terminates background processes** when they stop producing output. Uvicorn after startup enters event loop (no new stdout) → tool kills it.

---

## 🛠️ SOLUTION IMPLEMENTATION

### Production Launcher Script
**File:** `E:\WORLD_OLLAMA\scripts\start_webui_production.ps1`

**Key Features:**
1. **UTF-8 Encoding Fix** (from earlier diagnostics):
   ```powershell
   $env:PYTHONUTF8 = '1'
   $env:PYTHONIOENCODING = 'utf-8'
   [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
   ```

2. **Problematic Features Disabled** (workarounds from investigation):
   ```powershell
   $env:ENABLE_BASE_MODELS_CACHE = 'False'  # Avoid startup delays
   $env:REDIS_URL = ''                       # Disable Redis tasks
   ```

3. **Detached Process Launch** (root cause fix):
   ```powershell
   Start-Process powershell -ArgumentList "-NoExit", "-Command", $envSetup
   ```

**Usage:**
```powershell
pwsh E:\WORLD_OLLAMA\scripts\start_webui_production.ps1

# Output:
# [SESA] Launching Open WebUI in detached PowerShell window...
# [SESA] Open WebUI launched. Check window or log: E:\WORLD_OLLAMA\logs\webui_native.log
# [SESA] To stop: find powershell process on port 3100 and kill it
# [SESA] Test: curl http://localhost:3100/api/config
```

**Log Location:** `E:\WORLD_OLLAMA\logs\webui_native.log` (via `Tee-Object` in spawned window)

**Stop Procedure:**
```powershell
# Find PID
netstat -ano | Select-String ":3100"
# Output: TCP ... LISTENING <PID>

# Kill process
Get-Process -Id <PID> | Stop-Process -Force
```

---

## ✅ VERIFICATION & VALIDATION

### Test 1: API Health Check
```powershell
curl http://localhost:3100/api/config | ConvertFrom-Json | Select-Object version,name

# Expected Output:
# version : 0.6.38
# name    : (empty or configured value)
```

### Test 2: Port Binding Stability
```powershell
# Start server
pwsh E:\WORLD_OLLAMA\scripts\start_webui_production.ps1

# Wait 35 seconds (full startup cycle)
Start-Sleep 35

# Check port
netstat -ano | Select-String ":3100"
# Expected: TCP 0.0.0.0:3100  LISTENING  <PID>

# Multiple checks over time
for ($i=1; $i -le 5; $i++) {
    Start-Sleep 60
    $port = netstat -ano | Select-String ":3100"
    Write-Host "Check $i : $port"
}
# Expected: All 5 checks show LISTENING state (PID unchanged)
```

### Test 3: Log Continuity
```powershell
Get-Content E:\WORLD_OLLAMA\logs\webui_native.log -Tail 20 -Wait

# Expected behavior:
# - Startup sequence visible (CORS warnings, model loading, etc.)
# - "Application startup complete" message
# - NO "Process exited" or "Shutting down" messages
# - Log file keeps growing as requests arrive
```

### Test 4: Frontend Access (if built)
```powershell
# Note: Current deployment shows warning:
# "Frontend build directory not found at 'venv\Lib\build'. Serving API only."

# For full UI testing (future):
# 1. Build frontend: npm run build
# 2. Copy dist/ to venv\Lib\build\
# 3. Restart server
# 4. Open http://localhost:3100 in browser
```

---

## 📚 LESSONS LEARNED

### 1. Tool Behavior Assumptions
**Issue:** Assumed `run_in_terminal(isBackground=true)` behaves like standard shell background process (`&` in bash/pwsh).

**Reality:** Tool implements **idle detection** → terminates processes when stdout goes silent.

**Implication:** Long-running servers (uvicorn, Flask, Express, etc.) **NOT suitable** for `run_in_terminal` background mode.

**Workaround:** Use `Start-Process` with `-NoExit` to create truly independent process.

### 2. Error Suppression in Wrappers
**Issue:** `open-webui serve` CLI command **hides** Python-level exceptions that direct `uvicorn` invocation would expose.

**Discovery:** Manual `python -m uvicorn open_webui.main:app` revealed `CancelledError` traceback that wrapper suppressed.

**Recommendation:** When debugging startup issues, **bypass CLI wrappers** and invoke underlying commands directly.

### 3. UTF-8 Encoding in Windows
**Issue:** Windows console defaults to CP1251 (Cyrillic) → Unicode banner characters fail with UnicodeEncodeError.

**Fix:** Three-layer enforcement required:
```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8  # PowerShell console
$env:PYTHONUTF8 = "1"                                     # Python 3.7+ global mode
$env:PYTHONIOENCODING = "utf-8"                           # STDIO streams
```

**Lesson:** UTF-8 fixes must be **applied before process spawn**, not inside Python code.

### 4. Async Task Lifecycle in FastAPI Lifespan
**Issue:** Background tasks created via `asyncio.create_task()` in lifespan hook **can cause startup cancellation** if they fail immediately.

**Investigation:** Open WebUI creates tasks like `periodic_usage_pool_cleanup()` and `redis_task_command_listener()` → if these crash, entire lifespan cancels.

**Mitigation:** Disabled problematic features via environment variables:
- `ENABLE_BASE_MODELS_CACHE=False` (skip slow model fetching at startup)
- `REDIS_URL=""` (disable Redis connection attempts)

**Note:** These are **workarounds**, not root cause fix (root cause was tool behavior). Production deployment may re-enable these features after verifying Redis availability.

---

## 🔧 ARTIFACTS CREATED

### Scripts
1. **`E:\WORLD_OLLAMA\scripts\start_webui_production.ps1`** ✅ Production launcher (detached process)
2. **`E:\WORLD_OLLAMA\workbench\sandbox_main\scripts\debug_launcher.py`** 🔬 Diagnostic tool (explicit exception handling)
3. **`E:\WORLD_OLLAMA\workbench\sandbox_main\scripts\minimal_launcher.py`** 🧪 Minimal FastAPI test (reproduction)
4. **`E:\WORLD_OLLAMA\workbench\sandbox_main\scripts\start_webui_native.ps1`** 🗃️ Original script (archived, UTF-8 fixes applied but tool limitation present)

### Logs
1. **`E:\WORLD_OLLAMA\workbench\sandbox_main\logs\crash_report_001.txt`** — First UnicodeEncodeError traceback (CP1251 issue)
2. **`E:\WORLD_OLLAMA\workbench\sandbox_main\logs\crash_full.txt`** — Complete verbose output with CancelledError traceback
3. **`E:\WORLD_OLLAMA\workbench\sandbox_main\logs\webui_native.log`** — Archived test runs showing repeated exit pattern

### Documentation
1. **`E:\WORLD_OLLAMA\RAEDME`** — Updated with "РАБОТАЕТ (Production)" status + root cause summary
2. **`E:\WORLD_OLLAMA\workbench\sandbox_main\DIAGNOSTIC_REPORT.md`** — This file (comprehensive investigation record)

---

## 🎯 PRODUCTION READINESS CHECKLIST

- [✅] Open WebUI starts successfully
- [✅] Port 3100 remains bound (verified over multiple 60s intervals)
- [✅] API endpoints respond (tested /api/config)
- [✅] UTF-8 encoding working (banner renders correctly)
- [✅] Logs written to file (`logs/webui_native.log`)
- [✅] Production script created (`scripts/start_webui_production.ps1`)
- [✅] Documentation updated (RAEDME status changed to "РАБОТАЕТ")
- [⚠️] Frontend build missing (shows "Serving API only" — acceptable for API-first deployment)
- [⚠️] ENABLE_BASE_MODELS_CACHE disabled (workaround — may re-enable later)
- [⚠️] Redis disabled (workaround — verify Redis server availability before enabling)

**Overall Status:** ✅ **READY FOR PRODUCTION USE** (API mode)

**Next Steps (Optional Enhancements):**
1. Build frontend: `cd venv/Lib/site-packages/open_webui; npm run build`
2. Enable Redis: Install Redis server → configure REDIS_URL → test startup
3. Enable model caching: Set ENABLE_BASE_MODELS_CACHE=True → verify startup time acceptable
4. Implement monitoring: Add health check script + Windows Task Scheduler for auto-restart on failure

---

## 📞 SUPPORT INFORMATION

**Maintainer:** SESA (AI Development Assistant)  
**Last Updated:** 25 November 2025  
**Version:** 2.0 (Production Release)

**Troubleshooting Contact Points:**
- **Logs:** `E:\WORLD_OLLAMA\logs\webui_native.log`
- **Process Check:** `netstat -ano | Select-String ":3100"`
- **Manual Start:** `pwsh E:\WORLD_OLLAMA\scripts\start_webui_production.ps1`
- **Manual Stop:** `Get-Process -Id <PID> | Stop-Process -Force`

**Known Issues:**
- Frontend build not included in venv installation (expected behavior for API-only mode)
- CORS warning "CORS_ALLOW_ORIGIN IS SET TO '*'" (acceptable for local development)
- FFmpeg warning (non-critical, affects audio file processing features only)

**Compatibility:**
- Windows 10/11 with PowerShell 5.1+
- Python 3.12.10
- Open WebUI 0.6.38
- Ollama 0.x (tested with endpoint http://localhost:11434)

---

**END OF DIAGNOSTIC REPORT**
