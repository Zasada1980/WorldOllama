# Terminal Safety Implementation Guide for myshell

**Target:** myshell MCP Server Developer  
**Date:** 29 ноября 2025 г.  
**Priority:** 🔴 CRITICAL (Blocks CODEX agent operations)  
**Related Issue:** Terminal Timeout Policy Implementation

---

## 🎯 Objective

Implement terminal command timeout mechanism in myshell MCP server to prevent infinite hangs when executing commands through CODEX agent.

**Current Problem:**
- Commands like `npm install`, `cargo build`, or stuck processes run indefinitely
- Agent cannot detect hangs → waits forever → user session blocked
- No automatic termination after reasonable timeout

**Solution:**
Implement two-tier timeout system:
1. **Execution Timeout:** Maximum total command runtime
2. **No-Output Timeout:** Maximum silence period (no stdout/stderr)

---

## 📐 Architecture

### Input: Policy File

**Location:** `E:\WORLD_OLLAMA\config\terminal_timeout_policy.json`

**Schema:**
```json
{
  "version": "1.0",
  "description": "Terminal command timeout policy",
  "categories": {
    "quick": {
      "description": "Instant commands (ls, dir, echo, git status)",
      "exec_timeout_sec": 30,
      "no_output_timeout_sec": 10
    },
    "medium": {
      "description": "Scripts, tests, small compilations",
      "exec_timeout_sec": 120,
      "no_output_timeout_sec": 30
    },
    "long": {
      "description": "Package install, builds, indexing",
      "exec_timeout_sec": 600,
      "no_output_timeout_sec": 60
    },
    "extended": {
      "description": "Training, large builds (use sparingly)",
      "exec_timeout_sec": 900,
      "no_output_timeout_sec": 120
    }
  },
  "command_patterns": {
    "quick": [
      "^(ls|dir|pwd|echo|cat|type|Get-ChildItem|Write-Host|Test-Path)",
      "^git (status|branch|log|diff)(?!.*push|pull|clone)",
      "^(whoami|hostname|date)"
    ],
    "medium": [
      "^pwsh .+\\.ps1",
      "^(npm|cargo|dotnet) (test|run check)",
      "^python .+\\.py(?!.*train)"
    ],
    "long": [
      "^(npm|cargo|dotnet) (install|build|publish)",
      "^git (clone|pull|push|fetch)",
      "^pip install"
    ],
    "extended": [
      "llamafactory-cli train",
      "cargo build --release",
      "npm run build:prod"
    ]
  },
  "default_category": "medium"
}
```

### Command Flow

```
1. Agent calls myshell.run(command, timeout_sec=120)
   ↓
2. myshell reads config/terminal_timeout_policy.json
   ↓
3. If timeout_sec provided → use it
   If not → match command against patterns → get category timeouts
   ↓
4. Execute command with BOTH timeouts:
   - execTimeoutSec (total runtime)
   - noOutputTimeoutSec (silence period)
   ↓
5. Monitor stdout/stderr:
   - Reset noOutputTimer on each output line
   - Track totalExecutionTime
   ↓
6. If timeout triggered:
   - Send SIGTERM (soft kill, wait 5s)
   - If still alive → SIGKILL (hard kill)
   - Return status="timeout" with reason
   ↓
7. Return result:
   {
     "status": "success"|"timeout"|"error",
     "stdout": "...",
     "stderr": "...",
     "exitCode": 0,
     "timeoutReason": null|"exec_timeout"|"no_output_timeout",
     "terminationMode": null|"soft"|"hard",
     "durationMs": 12345
   }
```

---

## 🔧 Implementation Requirements

### 1. Config Loading (Startup)

**When:** myshell server starts  
**Action:**
```python
# Pseudocode (adjust to your language)
import json

POLICY_PATH = "E:/WORLD_OLLAMA/config/terminal_timeout_policy.json"

def load_timeout_policy():
    try:
        with open(POLICY_PATH, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        # Fallback to defaults
        return {
            "default_category": "medium",
            "categories": {
                "medium": {
                    "exec_timeout_sec": 120,
                    "no_output_timeout_sec": 30
                }
            }
        }

TIMEOUT_POLICY = load_timeout_policy()
```

### 2. Timeout Calculation (Per Command)

**When:** `myshell.run(command, timeout_sec?)` is called  
**Action:**
```python
def calculate_timeouts(command: str, user_timeout_sec: int = None):
    if user_timeout_sec:
        # User explicitly set timeout
        exec_timeout = user_timeout_sec
        no_output_timeout = min(user_timeout_sec // 4, 60)  # 25% or max 60s
        return exec_timeout, no_output_timeout
    
    # Match command against patterns
    for category_name, patterns in TIMEOUT_POLICY["command_patterns"].items():
        for pattern in patterns:
            if re.match(pattern, command, re.IGNORECASE):
                category = TIMEOUT_POLICY["categories"][category_name]
                return (
                    category["exec_timeout_sec"],
                    category["no_output_timeout_sec"]
                )
    
    # Fallback to default category
    default_cat = TIMEOUT_POLICY["default_category"]
    category = TIMEOUT_POLICY["categories"][default_cat]
    return category["exec_timeout_sec"], category["no_output_timeout_sec"]
```

### 3. Command Execution with Dual Timeout

**Key Requirements:**
- Monitor BOTH total execution time AND time since last output
- Reset `no_output_timer` on every stdout/stderr line
- Implement soft kill (SIGTERM) → hard kill (SIGKILL) progression

**Pseudocode:**
```python
import subprocess
import time
import signal

def run_with_timeout(command, exec_timeout_sec, no_output_timeout_sec):
    start_time = time.time()
    last_output_time = start_time
    
    process = subprocess.Popen(
        command,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    stdout_lines = []
    stderr_lines = []
    
    while process.poll() is None:  # While process is running
        # Check exec timeout
        elapsed = time.time() - start_time
        if elapsed > exec_timeout_sec:
            return terminate_process(process, "exec_timeout", elapsed)
        
        # Check no_output timeout
        time_since_output = time.time() - last_output_time
        if time_since_output > no_output_timeout_sec:
            return terminate_process(process, "no_output_timeout", elapsed)
        
        # Read output (non-blocking)
        line = process.stdout.readline()
        if line:
            stdout_lines.append(line)
            last_output_time = time.time()  # RESET timer
        
        time.sleep(0.1)  # Small poll interval
    
    # Process finished normally
    duration_ms = int((time.time() - start_time) * 1000)
    return {
        "status": "success",
        "stdout": "".join(stdout_lines),
        "stderr": "".join(stderr_lines),
        "exitCode": process.returncode,
        "timeoutReason": None,
        "terminationMode": None,
        "durationMs": duration_ms
    }

def terminate_process(process, reason, elapsed):
    # Soft kill (SIGTERM)
    process.terminate()
    try:
        process.wait(timeout=5)  # Wait 5 seconds
        termination_mode = "soft"
    except subprocess.TimeoutExpired:
        # Hard kill (SIGKILL)
        process.kill()
        process.wait()
        termination_mode = "hard"
    
    return {
        "status": "timeout",
        "stdout": "(partial output)",
        "stderr": "(partial errors)",
        "exitCode": -1,
        "timeoutReason": reason,
        "terminationMode": termination_mode,
        "durationMs": int(elapsed * 1000)
    }
```

### 4. Response Schema

**MUST include these fields:**
```typescript
interface TerminalResponse {
  status: "success" | "timeout" | "error";
  stdout: string;
  stderr: string;
  exitCode: number;
  timeoutReason: null | "exec_timeout" | "no_output_timeout";
  terminationMode: null | "soft" | "hard";
  durationMs: number;
}
```

**Example responses:**

**Success:**
```json
{
  "status": "success",
  "stdout": "hello world\n",
  "stderr": "",
  "exitCode": 0,
  "timeoutReason": null,
  "terminationMode": null,
  "durationMs": 245
}
```

**Exec Timeout:**
```json
{
  "status": "timeout",
  "stdout": "(partial output from npm install)",
  "stderr": "",
  "exitCode": -1,
  "timeoutReason": "exec_timeout",
  "terminationMode": "soft",
  "durationMs": 600123
}
```

**No-Output Timeout (Hung Process):**
```json
{
  "status": "timeout",
  "stdout": "Starting build...\n",
  "stderr": "",
  "exitCode": -1,
  "timeoutReason": "no_output_timeout",
  "terminationMode": "hard",
  "durationMs": 75890
}
```

---

## 🧪 Testing Protocol

**After implementation, run these 4 tests:**

### Test 1: Quick Command (Success)
```powershell
# Through agent tool call:
myshell.run("echo 'timeout test 1'", timeout_sec=30)

# Expected result:
# status: "success"
# exitCode: 0
# timeoutReason: null
# durationMs: < 1000
```

### Test 2: Hung Process (No-Output Timeout)
```powershell
# Command that produces no output and hangs:
myshell.run("Start-Sleep -Seconds 600", timeout_sec=120)

# Expected result:
# status: "timeout"
# timeoutReason: "no_output_timeout"
# terminationMode: "soft" or "hard"
# durationMs: ~30,000-60,000 (depending on no_output_timeout_sec)
```

### Test 3: Long Command (Exec Timeout)
```powershell
# Command that takes too long (simulate with sleep + echo loop):
myshell.run("for ($i=0; $i -lt 100; $i++) { Start-Sleep -Seconds 10; Write-Host 'still running' }", timeout_sec=60)

# Expected result:
# status: "timeout"
# timeoutReason: "exec_timeout"
# durationMs: ~60,000
```

### Test 4: Normal Long Command (Success)
```powershell
# Command that's long but completes within timeout:
myshell.run("npm install --dry-run", timeout_sec=300)

# Expected result:
# status: "success" (if npm installed)
# exitCode: 0
# durationMs: < 300,000
```

---

## 📋 Acceptance Criteria

**Implementation is DONE when:**

1. ✅ `config/terminal_timeout_policy.json` is loaded at startup
2. ✅ Timeouts are calculated per command (user override OR pattern match)
3. ✅ BOTH `exec_timeout` AND `no_output_timeout` are enforced
4. ✅ Soft kill (SIGTERM) → hard kill (SIGKILL) progression implemented
5. ✅ Response includes `timeoutReason`, `terminationMode`, `durationMs`
6. ✅ All 4 tests pass with expected results
7. ✅ `docs/infra/TERMINAL_TIMEOUT_VERIFICATION.md` is updated with test results

---

## 🔗 Related Files

**Policy Config:**
- `config/terminal_timeout_policy.json` — Timeout rules and patterns

**Documentation:**
- `docs/infra/Terminal_Safety_Policy.md` — Agent-side policy (for CODEX)
- `docs/infra/TERMINAL_TIMEOUT_VERIFICATION.md` — Test results log

**Project Status:**
- `PROJECT_STATUS_SNAPSHOT_v3.8.md` — Overall project state
- `task.md` — ОРДЕР 29-TERMINAL-SAFETY tracking

---

## 📞 Questions?

**Contact:** SESA3002a (ТРИЗ Architect)  
**Priority:** 🔴 CRITICAL — Blocks agent operations  
**Deadline:** ASAP (agent currently cannot reliably run terminal commands)

---

**Date:** 29 ноября 2025 г.  
**Version:** 1.0  
**Status:** ✅ Ready for Implementation

