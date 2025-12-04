# AUTONOMOUS DESKTOP AGENT — Компоненты и Зависимости

**Дата создания:** 03.12.2025 16:10  
**Последнее обновление:** 03.12.2025 16:32 (добавлена таблица Current vs Target State)  
**Статус:** Технический анализ  
**Связанный документ:** `FULL_AUTOMATION_ROADMAP.md`

---

## ⚠️ ТЕКУЩЕЕ СОСТОЯНИЕ vs ЦЕЛЕВОЕ (03.12.2025)

**Критическая информация:** Desktop Automation Agent находится на стадии **планирования**, реализация **0%**.

### Таблица Состояния Компонентов

| Компонент | Текущее Состояние | Целевое Состояние | Gap | Этап реализации |
|-----------|-------------------|-------------------|-----|-----------------|
| **Desktop Automation MCP Server** | ❌ Не существует | Rust binary, 12 tools, MCP protocol | 100% | ЭТАП 1-2 |
| **enigo crate** | ❌ Нет в Cargo.toml | v0.1.12 установлен | 100% | ЭТАП 0 |
| **uiautomation crate** | ❌ Нет в Cargo.toml | v0.5.0 установлен | 100% | ЭТАП 0 |
| **accesskit crate** | ❌ Нет в Cargo.toml | v0.12 установлен | 100% | ЭТАП 0 |
| **notify crate** | ❌ Нет в Cargo.toml | v6.1 установлен | 100% | ЭТАП 0 |
| **AI Orchestrator** | ❌ Не создан | Python, LangChain, 10 scenarios | 100% | ЭТАП 2 |
| **langchain** | ❌ Не установлен | v0.1.0+ в venv | 100% | ЭТАП 0 |
| **Test Scenarios Library** | ❌ Не создан | 10 YAML scenarios | 100% | ЭТАП 3 |
| **Error Pattern Database** | ❌ Не создан | YAML patterns (20+ errors) | 100% | ЭТАП 2 |
| **CI/CD Pipeline** | ❌ Не создан | GitHub Actions workflow | 100% | ЭТАП 3 |
| **Tauri Client** | ✅ v0.3.1 (релиз 02.12.2025) | v0.3.1 (без изменений) | 0% | Готов |
| **MCP Shell Server** | ✅ Production | Production (без изменений) | 0% | Готов |
| **PowerShell Scripts** | ✅ 38 скриптов | 38+ scripts (паттерны готовы) | 0% | Готов |
| **Ollama** | ✅ qwen2.5:14b работает | qwen2.5:14b (без изменений) | 0% | Готов |

**Легенда:**
- ✅ Готов — компонент существует и работает
- ❌ Не реализован — компонент не существует, требует создания с нуля
- Gap — процент работы, необходимой для достижения целевого состояния

---

## 🏗️ АРХИТЕКТУРА СИСТЕМЫ

```
┌──────────────────────────────────────────────────────────────────────┐
│                     AUTONOMOUS QA AGENT (Layer 6)                    │
│  • Python orchestrator (LangChain + Ollama)                         │
│  • Test scenario planner                                             │
│  • Error analyzer                                                    │
│  • Fix generator & validator                                         │
│  • Release decision maker                                            │
└────────────────────────────┬─────────────────────────────────────────┘
                             │ MCP Protocol (JSON-RPC over stdio)
┌────────────────────────────▼─────────────────────────────────────────┐
│               DESKTOP AUTOMATION MCP SERVER (Layer 5)                │
│  • Rust binary (automation-server)                                  │
│  • 12 MCP tools (5 original + 7 autonomous)                         │
│  • Circuit breaker & retry logic                                     │
│  • Event logging (JSON lines)                                        │
└──────┬───────────┬────────────┬────────────┬──────────────────────────┘
       │           │            │            │
┌──────▼──────┐ ┌──▼─────────┐ ┌▼──────────┐ ┌▼───────────────────────┐
│ Visualizer  │ │  Executor  │ │ Monitor   │ │  Verification Layer    │
│  (Layer 4)  │ │ (Layer 3)  │ │(Layer 2)  │ │     (Layer 1)          │
└─────────────┘ └────────────┘ └───────────┘ └────────────────────────┘
│ Accessibility│ │ enigo      │ │ notify    │ │ Screenshot hash        │
│ Tree dump    │ │ (mouse/kbd)│ │ Log tail  │ │ Accessibility diff     │
│ uiautomation │ │ Debounce   │ │ Pattern   │ │ Log correlation        │
│ Screenshot   │ │ (100ms)    │ │ matching  │ │ Code compilation check │
└──────┬───────┘ └─────┬──────┘ └─────┬─────┘ └──────┬─────────────────┘
       │               │              │              │
       └───────────────┴──────────────┴──────────────┘
                             │
        ┌────────────────────▼─────────────────────────────────────┐
        │           WORLD_OLLAMA DESKTOP CLIENT                    │
        │  • Tauri (Rust backend + Svelte frontend)               │
        │  • 11 existing modules (commands.rs, flow_manager.rs)   │
        │  • Logs: orchestrator, cortex, training, mcp, indexation│
        │  • IPC bridge (invoke commands from JS)                 │
        └──────────────────────────────────────────────────────────┘
```

---

## ✅ PREREQUISITES CHECKLIST (Обязательные Предварительные Требования)

**Перед началом ЭТАПА 1 необходимо выполнить:**

### Системные Требования

- [ ] **Ollama работает:**
  ```powershell
  ollama list | Select-String "qwen2.5:14b"
  # Ожидаемый результат: qwen2.5:14b ... 8.7 GB
  ```

- [ ] **CORTEX (LightRAG) работает:**
  ```powershell
  Invoke-RestMethod http://localhost:8004/health
  # Ожидаемый результат: {"status":"healthy"}
  ```

- [ ] **Tauri Client собирается:**
  ```powershell
  cd client
  npm run tauri build
  # Ожидаемый результат: *.msi в src-tauri/target/release/bundle/
  ```

- [ ] **rust-analyzer установлен:**
  ```powershell
  code --list-extensions | Select-String rust-analyzer
  # Ожидаемый результат: rust-lang.rust-analyzer
  ```

### ЭТАП 0 Завершён

- [ ] **Cargo.toml обновлён:**
  ```powershell
  cargo tree | Select-String "enigo|uiautomation|notify"
  # Ожидаемый результат: все 3 crates видны
  ```

- [ ] **Python venv создан:**
  ```powershell
  cd automation\orchestrator
  .\venv\Scripts\Activate.ps1
  pip list | Select-String langchain
  # Ожидаемый результат: langchain 0.1.0, langchain-ollama 0.1.0
  ```

- [ ] **Структура директорий создана:**
  ```powershell
  Test-Path "client\src-tauri\src\automation"
  Test-Path "automation\orchestrator\src"
  # Оба должны вернуть: True
  ```

- [ ] **Placeholder файлы компилируются:**
  ```powershell
  cd client\src-tauri
  cargo build
  # Ожидаемый результат: успех за <2 минут
  ```

**Статус ЭТАПА 0:**
- Если ВСЕ 8 пунктов выполнены → можно начинать ЭТАП 1
- Если хотя бы 1 пункт НЕ выполнен → вернуться к ЭТАПУ 0 (см. `FULL_AUTOMATION_ROADMAP.md`)

---

## 📦 КРИТИЧЕСКИЕ КОМПОНЕНТЫ

### 1. Desktop Automation MCP Server (Новый компонент)

**Назначение:** Мост между AI Orchestrator и Desktop Client, предоставляет 12 MCP tools для управления UI и мониторинга.

**Технологии:**
- **Язык:** Rust (integration с Tauri, zero overhead)
- **Протокол:** MCP (JSON-RPC over stdio, совместим с Claude Desktop / LangChain)
- **Архитектура:** Multi-module (visualizer, executor, monitor, verifier)

**⚠️ КРИТИЧЕСКОЕ ОГРАНИЧЕНИЕ (из инвентаризации 03.12.2025):**
- **НЕ создавать новый проект** — интеграция в СУЩЕСТВУЮЩИЙ `client/src-tauri/`
- **Использовать существующую структуру:** 11 модулей уже есть (commands.rs, flow_manager.rs, training_manager.rs и др.)
- **НЕ дублировать:** MCP Shell Server уже работает (logs/mcp/mcp-events.log), использовать для PowerShell вызовов
- **Расширение, НЕ замена:** Добавить новые модули `automation/` в существующий Cargo workspace

**Зависимости (Rust crates):**

| Crate | Версия | Назначение | Критичность |
|-------|--------|------------|-------------|
| `enigo` | 0.1.12 | Mouse/keyboard simulation | 🔴 P0 (core functionality) |
| `uiautomation` | 0.5.0 | Windows UI Automation API | 🔴 P0 (Accessibility Tree) |
| `serde_json` | 1.0 | JSON serialization for MCP | 🔴 P0 (protocol) |
| `tokio` | 1.35+ | Async runtime для MCP stdio | 🔴 P0 (non-blocking I/O) |
| `notify` | 6.1 | File system watcher (logs) | 🟡 P1 (monitoring) |
| `image` | 0.24 | Screenshot capture/hashing | 🟡 P1 (verification) |
| `reqwest` | 0.11 | HTTP client (health checks) | 🟢 P2 (optional) |

**Файловая структура:**
```
client/src-tauri/src/
├── automation_server.rs         (main entry point)
├── automation/
│   ├── mod.rs
│   ├── visualizer.rs            (Accessibility Tree + Screenshot)
│   ├── executor.rs              (enigo wrapper with debounce)
│   ├── monitor.rs               (notify-based log tailing)
│   └── verifier.rs              (hash comparison, tree diff)
├── mcp/
│   ├── mod.rs
│   ├── protocol.rs              (JSON-RPC stdio handler)
│   └── tools.rs                 (12 MCP tools implementation)
└── utils.rs                     (shared utilities)
```

**Блокирующие зависимости:**
- ✅ Tauri client должен быть запущен (target process для uiautomation)
- ✅ Ollama должен работать (для AI Orchestrator, qwen2.5:14b)
- ⚠️ Windows API (uiautomation работает только на Windows в текущей фазе)

---

### 2. AI Orchestrator (Новый компонент)

**Назначение:** Мозг системы — планирует тесты, анализирует ошибки, генерирует фиксы, принимает решение о релизе.

**Технологии:**
- **Язык:** Python 3.11+
- **Framework:** LangChain (для ReAct agent pattern)
- **LLM:** Ollama (qwen2.5:14b) — локальная модель, no API calls
- **MCP Client:** Custom implementation (JSON-RPC over subprocess stdio)

**Зависимости (Python packages):**

| Package | Версия | Назначение | Критичность |
|---------|--------|------------|-------------|
| `langchain` | 0.1.0+ | Agent framework (ReAct) | 🔴 P0 (orchestration) |
| `langchain-ollama` | 0.1.0+ | Ollama integration | 🔴 P0 (local LLM) |
| `pyyaml` | 6.0+ | Config parsing (scenarios) | 🔴 P0 (test definitions) |
| `Pillow` | 10.0+ | Screenshot comparison | 🟡 P1 (verification) |
| `imagehash` | 4.3+ | Perceptual hashing | 🟡 P1 (diff detection) |
| `psutil` | 5.9+ | Process monitoring | 🟢 P2 (health checks) |

**Файловая структура:**
```
automation/orchestrator/
├── src/
│   ├── main.py                  (CLI entry point)
│   ├── agent.py                 (LangChain ReAct agent)
│   ├── mcp_client.py            (MCP protocol client)
│   ├── scenarios/
│   │   ├── __init__.py
│   │   ├── startup_test.py
│   │   ├── cortex_query_test.py
│   │   ├── training_test.py
│   │   └── flows_test.py        (10 total scenarios)
│   ├── validators/
│   │   ├── log_validator.py     (regex pattern matching)
│   │   └── ui_validator.py      (screenshot/tree diff)
│   └── fixers/
│       ├── code_fixer.py        (LLM-based fix generation)
│       └── config_fixer.py      (YAML/JSON config adjustments)
├── config/
│   ├── test_suite.yaml          (scenario definitions)
│   ├── error_patterns.yaml      (regex patterns for log errors)
│   └── fix_strategies.yaml      (error → fix mapping)
├── results/                     (test execution artifacts)
│   ├── *.json                   (structured results)
│   └── screenshots/             (before/after images)
└── requirements.txt
```

**Блокирующие зависимости:**
- ✅ Desktop Automation MCP Server должен быть запущен
- ✅ Ollama с моделью qwen2.5:14b должен быть доступен (port 11434)
- ⚠️ Достаточно VRAM (14B модель требует ~9 GB)

---

### 3. Verification Layer (Новый модуль в MCP Server)

**Назначение:** Anti-hallucination механизм — проверяет, что все действия агента подтверждены фактами из системы.

**Компоненты:**

#### 3.1 Screenshot Hash Comparator
```rust
// automation/verifier.rs
use image::{DynamicImage, ImageBuffer};
use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};

pub struct ScreenshotVerifier {
    last_hash: Option<u64>,
}

impl ScreenshotVerifier {
    pub fn take_screenshot(&self) -> Result<DynamicImage, Error> {
        // Platform-specific implementation
        #[cfg(target_os = "windows")]
        {
            use screenshots::Screen;
            let screens = Screen::all()?;
            let screen = screens[0].capture()?;
            Ok(DynamicImage::ImageRgba8(screen))
        }
    }
    
    pub fn has_changed(&mut self) -> Result<bool, Error> {
        let screenshot = self.take_screenshot()?;
        let hash = self.compute_hash(&screenshot);
        
        if let Some(prev_hash) = self.last_hash {
            self.last_hash = Some(hash);
            Ok(hash != prev_hash)
        } else {
            self.last_hash = Some(hash);
            Ok(false) // First screenshot, nothing to compare
        }
    }
    
    fn compute_hash(&self, image: &DynamicImage) -> u64 {
        let mut hasher = DefaultHasher::new();
        image.as_bytes().hash(&mut hasher);
        hasher.finish()
    }
}
```

**Зависимости:**
- `screenshots` crate (0.8.5+) — cross-platform screenshot
- `image` crate (0.24+) — image processing

#### 3.2 Accessibility Tree Differ
```rust
// automation/verifier.rs
use serde_json::Value;

pub struct AccessibilityDiffer {
    last_tree: Option<Value>,
}

impl AccessibilityDiffer {
    pub fn detect_changes(&mut self, current_tree: Value) -> Vec<Change> {
        let Some(ref prev_tree) = self.last_tree else {
            self.last_tree = Some(current_tree);
            return vec![];
        };
        
        let mut changes = vec![];
        
        // Detect added elements
        let current_ids = self.extract_ids(&current_tree);
        let prev_ids = self.extract_ids(prev_tree);
        
        for id in &current_ids {
            if !prev_ids.contains(id) {
                changes.push(Change::ElementAdded(id.clone()));
            }
        }
        
        // Detect removed elements
        for id in &prev_ids {
            if !current_ids.contains(id) {
                changes.push(Change::ElementRemoved(id.clone()));
            }
        }
        
        self.last_tree = Some(current_tree);
        changes
    }
    
    fn extract_ids(&self, tree: &Value) -> Vec<String> {
        let mut ids = vec![];
        if let Some(elements) = tree["elements"].as_array() {
            for element in elements {
                if let Some(id) = element["id"].as_str() {
                    ids.push(id.to_string());
                }
            }
        }
        ids
    }
}

#[derive(Debug)]
pub enum Change {
    ElementAdded(String),
    ElementRemoved(String),
}
```

#### 3.3 Log Correlation Checker
```rust
// automation/verifier.rs
use std::time::{Duration, Instant};

pub struct LogCorrelator {
    monitor: LogMonitor,
}

impl LogCorrelator {
    pub fn verify_action_logged(
        &self, 
        action_name: &str, 
        log_file: &str, 
        timeout: Duration
    ) -> Result<(), Error> {
        let start = Instant::now();
        
        loop {
            if start.elapsed() > timeout {
                return Err(Error::ActionNotLogged(action_name.to_string()));
            }
            
            let logs = self.monitor.get_recent_logs(log_file, 50);
            if logs.iter().any(|line| line.contains(action_name)) {
                return Ok(());
            }
            
            std::thread::sleep(Duration::from_millis(100));
        }
    }
}
```

**Зависимости:** 
- LogMonitor (реализован в Шаге 1.5)

---

### 4. Test Scenarios Library (Новый компонент)

**Назначение:** Декларативные определения E2E тестов в YAML формате.

**Структура сценария:**
```yaml
# automation/orchestrator/config/test_suite.yaml
scenarios:
  - name: "Application Startup"
    id: "startup_test"
    priority: P0  # Critical path
    timeout: 60   # seconds
    
    steps:
      - action: start_process
        command: "npm run tauri dev"
        working_dir: "client"
        background: true
        
      - action: wait_for_window
        window_name: "WORLD_OLLAMA"
        timeout: 30
        
      - action: verify_logs
        log_file: "logs/orchestrator.log"
        pattern: "Step 1: Checking Ollama"
        timeout: 10
        
      - action: get_screen_state
        store_as: "startup_tree"
        
    success_criteria:
      - window_visible: true
      - no_errors_in_logs: ["orchestrator.log", "cortex.log"]
      - element_exists:
          tree_var: "startup_tree"
          element_name: "main-panel"
    
    on_failure:
      - collect_logs: ["orchestrator.log", "cortex.log", "mcp-events.log"]
      - take_screenshot: "failure_startup.png"
      - escalate_to: "github_issue"
```

**Валидация сценариев:**
```python
# orchestrator/src/scenario_validator.py
import yaml
from jsonschema import validate

SCENARIO_SCHEMA = {
    "type": "object",
    "required": ["name", "id", "steps", "success_criteria"],
    "properties": {
        "name": {"type": "string"},
        "id": {"type": "string", "pattern": "^[a-z_]+$"},
        "priority": {"enum": ["P0", "P1", "P2"]},
        "timeout": {"type": "integer", "minimum": 1},
        "steps": {
            "type": "array",
            "items": {
                "type": "object",
                "required": ["action"],
                "properties": {
                    "action": {"enum": ["start_process", "wait_for_window", "click_element", 
                                       "type_text", "verify_logs", "get_screen_state"]}
                }
            }
        },
        "success_criteria": {"type": "object"},
        "on_failure": {"type": "array"}
    }
}

def validate_scenario(scenario_yaml):
    scenario = yaml.safe_load(scenario_yaml)
    validate(instance=scenario, schema=SCENARIO_SCHEMA)
    return scenario
```

**Зависимости:**
- `pyyaml` (YAML parsing)
- `jsonschema` (scenario validation)

---

### 5. Error Pattern Database (Новый компонент)

**Назначение:** Библиотека regex паттернов для обнаружения известных ошибок в логах.

**Формат:**
```yaml
# automation/orchestrator/config/error_patterns.yaml
patterns:
  - id: "err_001"
    name: "Ollama connection failed"
    category: "INFRASTRUCTURE"
    severity: "CRITICAL"
    regex: '\[ERROR\].*Failed to connect to Ollama|ConnectionRefused.*localhost:11434'
    contexts:
      - log_file: "orchestrator.log"
      - log_file: "cortex.log"
    suggested_fix:
      type: "manual_check"
      command: "ollama list"
      description: "Verify Ollama is running and models are available"
    
  - id: "err_002"
    name: "CORTEX startup timeout"
    category: "SERVICE"
    severity: "HIGH"
    regex: '\[ERROR\].*CORTEX failed to start within \d+s'
    contexts:
      - log_file: "orchestrator.log"
    suggested_fix:
      type: "code_fix"
      target_file: "scripts/START_ALL.ps1"
      description: "Increase CORTEX startup timeout from 30s to 60s"
      search_pattern: '\$cortexTimeout\s*=\s*30'
      replace_with: '$cortexTimeout = 60'
    
  - id: "err_003"
    name: "Training CUDA OOM"
    category: "TRAINING"
    severity: "HIGH"
    regex: 'CUDA out of memory|RuntimeError.*CUDA'
    contexts:
      - log_file: "logs/training/*.log"
    suggested_fix:
      type: "config_fix"
      target_file: "services/llama_factory/config/llama3_lora_sft.yaml"
      description: "Reduce batch_size to avoid VRAM exhaustion"
      yaml_path: "training_args.per_device_train_batch_size"
      transform: "divide_by_2"  # 8 → 4 → 2
```

**Парсер:**
```python
# orchestrator/src/validators/log_validator.py
import re
import yaml
from pathlib import Path

class ErrorPatternMatcher:
    def __init__(self, patterns_file: Path):
        with open(patterns_file) as f:
            data = yaml.safe_load(f)
            self.patterns = data['patterns']
    
    def scan_logs(self, log_file: Path, tail_lines: int = 100) -> list[dict]:
        """Scans recent log lines for error patterns."""
        errors = []
        
        with open(log_file) as f:
            lines = f.readlines()[-tail_lines:]
        
        for pattern in self.patterns:
            # Check if this pattern applies to this log file
            if not any(log_file.match(ctx['log_file']) for ctx in pattern['contexts']):
                continue
            
            for line in lines:
                if re.search(pattern['regex'], line):
                    errors.append({
                        'id': pattern['id'],
                        'name': pattern['name'],
                        'category': pattern['category'],
                        'severity': pattern['severity'],
                        'log_line': line.strip(),
                        'suggested_fix': pattern['suggested_fix']
                    })
        
        return errors
```

**Зависимости:**
- `pyyaml` (pattern definitions)
- `re` (standard library, regex matching)

---

### 6. Code Fix Generator (Новый компонент)

**Назначение:** LLM-based генерация фиксов с валидацией перед применением.

**Алгоритм:**
```python
# orchestrator/src/fixers/code_fixer.py
from langchain_ollama import ChatOllama
from pathlib import Path
import subprocess

class CodeFixGenerator:
    def __init__(self, llm: ChatOllama):
        self.llm = llm
    
    def generate_fix(self, error: dict, codebase_context: str) -> dict:
        """
        Generates code fix using LLM.
        Returns: {
            'file_path': str,
            'old_code': str,
            'new_code': str,
            'explanation': str
        }
        """
        prompt = f"""
You are a code fixing AI for WORLD_OLLAMA project.

ERROR DETECTED:
- Name: {error['name']}
- Category: {error['category']}
- Log line: {error['log_line']}
- Suggested fix (high-level): {error['suggested_fix']['description']}

CODEBASE CONTEXT:
{codebase_context}

Generate a concrete code fix. Follow these rules:
1. Return EXACT code to replace (with 3 lines context before/after)
2. Match existing code style (indentation, naming)
3. Do NOT hallucinate code that doesn't exist
4. If fix is config change, return YAML/JSON diff

OUTPUT FORMAT:
FILE: <absolute_path>
OLD_CODE:
```
<exact old code>
```
NEW_CODE:
```
<fixed code>
```
EXPLANATION: <why this fixes the error>
"""
        
        response = self.llm.invoke(prompt)
        fix = self._parse_llm_response(response.content)
        
        # Validate fix before returning
        if not self.validate_fix(fix):
            raise ValueError(f"Generated fix failed validation: {fix}")
        
        return fix
    
    def validate_fix(self, fix: dict) -> bool:
        """
        Anti-hallucination validation:
        1. File exists
        2. OLD_CODE exactly matches file content
        3. NEW_CODE compiles/parses
        """
        file_path = Path(fix['file_path'])
        
        # Check 1: File exists
        if not file_path.exists():
            print(f"❌ Validation failed: {file_path} does not exist")
            return False
        
        # Check 2: OLD_CODE matches
        with open(file_path) as f:
            content = f.read()
            if fix['old_code'] not in content:
                print(f"❌ Validation failed: OLD_CODE not found in {file_path}")
                return False
        
        # Check 3: NEW_CODE compiles (for Rust)
        if file_path.suffix == '.rs':
            temp_file = self._apply_to_temp(fix)
            result = subprocess.run(
                ['cargo', 'check', '--manifest-path', temp_file.parent / 'Cargo.toml'],
                capture_output=True
            )
            if result.returncode != 0:
                print(f"❌ Validation failed: NEW_CODE does not compile")
                print(result.stderr.decode())
                return False
        
        # Check 3b: NEW_CODE parses (for YAML)
        elif file_path.suffix in ['.yaml', '.yml']:
            import yaml
            try:
                yaml.safe_load(fix['new_code'])
            except yaml.YAMLError as e:
                print(f"❌ Validation failed: NEW_CODE is invalid YAML: {e}")
                return False
        
        print(f"✅ Fix validated: {file_path}")
        return True
    
    def _apply_to_temp(self, fix: dict) -> Path:
        """Creates temporary copy of file with fix applied."""
        import tempfile
        import shutil
        
        original = Path(fix['file_path'])
        temp_dir = Path(tempfile.mkdtemp())
        temp_file = temp_dir / original.name
        
        shutil.copy(original, temp_file)
        
        with open(temp_file, 'r') as f:
            content = f.read()
        
        fixed_content = content.replace(fix['old_code'], fix['new_code'])
        
        with open(temp_file, 'w') as f:
            f.write(fixed_content)
        
        return temp_file
```

**Зависимости:**
- `langchain-ollama` (LLM integration)
- `subprocess` (cargo check validation)
- `pyyaml` (YAML validation)

---

### 7. CI/CD Pipeline (Новый компонент)

**Назначение:** GitHub Actions workflow для автоматического запуска тестов и релизов.

**Файл:**
```yaml
# .github/workflows/autonomous-qa.yml
name: Autonomous QA Suite

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
  schedule:
    - cron: '0 3 * * *'  # Daily at 3 AM
  workflow_dispatch:     # Manual trigger

env:
  RUST_BACKTRACE: 1
  CARGO_TERM_COLOR: always

jobs:
  build-automation-server:
    runs-on: windows-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Rust
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
          profile: minimal
      
      - name: Cache Cargo
        uses: actions/cache@v3
        with:
          path: |
            ~/.cargo/registry
            ~/.cargo/git
            client/src-tauri/target
          key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}
      
      - name: Build Automation Server
        run: |
          cd client/src-tauri
          cargo build --release --bin automation-server
      
      - name: Upload Binary
        uses: actions/upload-artifact@v4
        with:
          name: automation-server
          path: client/src-tauri/target/release/automation-server.exe
  
  run-e2e-tests:
    needs: build-automation-server
    runs-on: windows-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Download Automation Server
        uses: actions/download-artifact@v4
        with:
          name: automation-server
          path: ./bin
      
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Install Ollama
        run: |
          Invoke-WebRequest https://ollama.ai/download/OllamaSetup.exe -OutFile ollama.exe
          Start-Process ollama.exe /S -Wait
          Start-Process ollama serve
          Start-Sleep -Seconds 5
          ollama pull qwen2.5:14b
          ollama pull nomic-embed-text
      
      - name: Start CORTEX
        run: |
          cd services/lightrag
          pip install -r requirements.txt
          Start-Process python -ArgumentList "lightrag_server.py" -NoNewWindow
          Start-Sleep -Seconds 30
      
      - name: Build Desktop Client
        run: |
          cd client
          npm install
          npm run tauri build
      
      - name: Run Autonomous Test Suite
        run: |
          cd automation/orchestrator
          pip install -r requirements.txt
          python src/main.py --test-suite config/test_suite.yaml --mode ci
      
      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results-${{ github.sha }}
          path: |
            automation/orchestrator/results/*.json
            automation/orchestrator/results/screenshots/*.png
      
      - name: Report Failures
        if: failure()
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const results = JSON.parse(fs.readFileSync('./automation/orchestrator/results/summary.json'));
            
            const issueBody = `
            ## 🚨 Autonomous QA Suite Failed
            
            **Commit:** ${context.sha}
            **Branch:** ${context.ref}
            **Run:** ${context.runId}
            
            ### Failed Tests
            ${results.failed_tests.map(t => `- ❌ ${t.name}: ${t.error}`).join('\n')}
            
            ### Logs
            [View full results](${context.payload.repository.html_url}/actions/runs/${context.runId})
            `;
            
            await github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: `[AUTO-QA] ${results.failed_tests.length} test(s) failed on ${context.ref}`,
              body: issueBody,
              labels: ['automation', 'bug', 'ci-failure']
            });
```

**Зависимости:**
- GitHub Actions runners (windows-latest)
- Ollama (downloaded during workflow)
- Python 3.11, Node.js 20, Rust stable

---

## 🔗 МАТРИЦА ЗАВИСИМОСТЕЙ

### Inter-Component Dependencies

```
AI Orchestrator
  ├─ REQUIRES: Desktop Automation MCP Server (running process)
  ├─ REQUIRES: Ollama (qwen2.5:14b model)
  ├─ REQUIRES: Test Scenarios Library (YAML configs)
  ├─ REQUIRES: Error Pattern Database (YAML patterns)
  └─ REQUIRES: Code Fix Generator (LLM integration)

Desktop Automation MCP Server
  ├─ REQUIRES: Tauri Client (target process for UI Automation)
  ├─ REQUIRES: Verification Layer (screenshot/tree diff)
  ├─ REQUIRES: Log Monitor (notify file watcher)
  └─ PROVIDES: 12 MCP tools (stdio JSON-RPC)

Verification Layer
  ├─ REQUIRES: Screenshots crate (capture)
  ├─ REQUIRES: uiautomation crate (tree access)
  └─ PROVIDES: Change detection (bool results)

Test Scenarios Library
  ├─ REQUIRES: YAML validation (jsonschema)
  └─ PROVIDES: Declarative test definitions

Error Pattern Database
  ├─ REQUIRES: Regex engine (Python re)
  └─ PROVIDES: Error detection results

Code Fix Generator
  ├─ REQUIRES: LLM (Ollama via langchain)
  ├─ REQUIRES: Codebase context (semantic search)
  ├─ REQUIRES: Validation tools (cargo check, YAML parser)
  └─ PROVIDES: Validated code fixes

CI/CD Pipeline
  ├─ REQUIRES: All above components (built + running)
  ├─ REQUIRES: GitHub Actions infrastructure
  └─ PROVIDES: Automated testing + reporting
```

### Critical Path

**Minimum components needed for MVP (Phase 1 PoC):**
1. Desktop Automation MCP Server (with 2 tools: `get_screen_state`, `click_element`)
2. Tauri Client (running in dev mode)
3. AI Orchestrator (minimal, 1 scenario: "Click button test")

**Full autonomous operation requires (Phase 3):**
1. All 12 MCP tools implemented
2. All 10 E2E scenarios defined
3. Error Pattern Database (20+ patterns)
4. Code Fix Generator with validation
5. CI/CD Pipeline

---

## 📊 РЕСУРСНЫЕ ТРЕБОВАНИЯ

### Development Environment

| Ресурс | Минимум | Рекомендуется | Примечание |
|--------|---------|---------------|------------|
| **RAM** | 16 GB | 32 GB | qwen2.5:14b требует ~9 GB |
| **VRAM** | 8 GB | 16 GB | CUDA для обучения |
| **CPU** | 8 cores | 16 cores | Параллельные тесты |
| **Disk** | 50 GB free | 100 GB free | Ollama models + logs |
| **OS** | Windows 11 | Windows 11 Pro | uiautomation crate |

### Runtime Dependencies

| Компонент | Версия | Порт | Startup Time |
|-----------|--------|------|--------------|
| **Ollama** | 0.1.20+ | 11434 | ~5s |
| **CORTEX** | v0.3.1 | 8004 | ~25s (with models loaded) |
| **Tauri Client** | v0.3.1 | N/A (desktop) | ~10s |
| **Automation Server** | v0.4.0 | stdio | <1s |
| **AI Orchestrator** | v0.4.0 | N/A | <2s |

### CI/CD Resources

| Resource | GitHub Actions Limit | Our Usage | Buffer |
|----------|---------------------|-----------|--------|
| **Runner time** | 6 hours | ~15 min (test suite) | 24× |
| **Storage** | 10 GB | ~500 MB (screenshots) | 20× |
| **Concurrent jobs** | 20 | 1-2 | 10× |

---

## ⚠️ БЛОКЕРЫ И MITIGATION

| Блокер | Вероятность | Impact | Mitigation Strategy |
|--------|-------------|--------|---------------------|
| **enigo не работает в GitHub Actions** | Средняя | Критическое | Self-hosted runner с реальным дисплеем |
| **uiautomation crate Windows-only** | Высокая | Высокое | Phase 1 только Windows, Phase 3 добавить accesskit (macOS/Linux) |
| **Ollama VRAM exhaustion** | Низкая | Среднее | Model offloading (CPU fallback) |
| **Flaky tests (Svelte animations)** | Высокая | Высокое | Mandatory 100ms debounce + smart wait |
| **LLM галлюцинирует фиксы** | Средняя | Критическое | 3-layer validation (file exists + code matches + compiles) |
| **CI timeout (10 min limit)** | Низкая | Среднее | Параллельные тесты + caching |

---

## 🎯 NEXT ACTIONS

**Для начала разработки (следующие 2 дня):**

```powershell
# 1. Создать структуру директорий
New-Item -ItemType Directory -Path "client\src-tauri\src\automation" -Force
New-Item -ItemType Directory -Path "client\src-tauri\src\mcp" -Force
New-Item -ItemType Directory -Path "automation\orchestrator\src\scenarios" -Force
New-Item -ItemType Directory -Path "automation\orchestrator\config" -Force

# 2. Создать Cargo.toml patch
@"
[dependencies]
enigo = "0.1.12"
uiautomation = "0.5.0"
serde_json = "1.0"
tokio = { version = "1", features = ["full"] }
notify = "6.1"
image = "0.24"
screenshots = "0.8"
"@ | Out-File -Append client\src-tauri\Cargo.toml

# 3. Создать requirements.txt для orchestrator
@"
langchain==0.1.0
langchain-ollama==0.1.0
pyyaml==6.0
Pillow==10.0
imagehash==4.3
psutil==5.9
jsonschema==4.20
"@ | Out-File automation\orchestrator\requirements.txt

# 4. Проверить зависимости
cargo --version
python --version
ollama --version
npm --version
```

**Первый код для валидации:**
1. Создать `automation/visualizer.rs` (код из Roadmap Шаг 1.3)
2. Запустить `cargo test test_accessibility_tree_dump`
3. Если проходит → MCP Server skeleton готов к разработке

**Трекинг прогресса:**
- GitHub Project: "Desktop Automation Agent v0.4.0"
- Milestones: Phase 1 (2 weeks), Phase 2 (2 weeks), Phase 3 (1 week), Phase 4 (1 week)
- Issues: По 1 issue на каждый шаг из Roadmap

---

**Версия:** 1.1  
**Дата создания:** 03.12.2025 16:10  
**Последнее обновление:** 03.12.2025 16:32  
**Автор:** AI Agent (GitHub Copilot)
