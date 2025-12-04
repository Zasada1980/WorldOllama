# ПОЛНАЯ АВТОМАТИЗАЦИЯ WORLD_OLLAMA — Пошаговый Roadmap

**Дата создания:** 03.12.2025  
**Целевая версия:** v0.4.0 (Desktop Automation Agent)  
**Статус:** ⚡ ЭТАП 0 ЗАВЕРШЁН (03.12.2025) → В разработке  
**Базовый документ:** `docs/analysis/TAURI_AUTOMATION_AUDIT_REPORT.md`

---

## ✅ ПРОГРЕСС ВЫПОЛНЕНИЯ

| Этап | Статус | Дата завершения | Ключевые результаты |
|------|--------|-----------------|---------------------|
| **ЭТАП 0: SETUP** | ✅ ЗАВЕРШЁН | 03.12.2025 | rust-analyzer, Cargo.toml (5 crates), directories, venv, placeholders |
| **ЭТАП 1: FOUNDATION** | ✅ ЗАВЕРШЁН | 03.12.2025 | automation module, executor, monitor, visualizer, 5 Tauri commands |
| **ЭТАП 2: INTELLIGENCE** | ✅ ЗАВЕРШЁН | 03.12.2025 | Tauri integration, lib.rs registration, simple scenario testing |
| ЭТАП 3: INTEGRATION | ⏸️ Не начат | — | MCP server, test scenarios |
| ЭТАП 4: HARDENING | ⏸️ Не начат | — | CI/CD, regression suite |

---

## 🎯 ЦЕЛЬ ПРОЕКТА

**Создать полностью автономного AI-агента**, который:

1. ✅ Запускает Desktop Client (`npm run tauri dev`) — **СУЩЕСТВУЮЩИЙ КОД:** Tauri v2 + Svelte 5
2. ✅ Имитирует действия пользователя (клики, ввод текста, навигация) — **НОВОЕ:** enigo + uiautomation crates
3. ✅ Мониторит логи в реальном времени (CORTEX, training, MCP, orchestrator) — **СУЩЕСТВУЮЩЕЕ:** Logs infrastructure готова
4. ✅ Обнаруживает ошибки и исправляет их автоматически (code generation + hot reload) — **НОВОЕ:** LLM-based fix generator
5. ✅ Валидирует каждый релиз перед публикацией (E2E regression suite) — **НОВОЕ:** GitHub Actions workflow

**Критические требования:**
- ❌ **НЕТ ручных тестов** пользователем
- ❌ **НЕТ предположений** агентом о работе проекта
- ❌ **НЕТ галлюцинаций** (все действия верифицируются через Accessibility Tree + screenshot hash)
- ✅ **100% автоматизация** до релиза

**⚠️ ВАЖНЫЕ ОГРАНИЧЕНИЯ (из инвентаризации 03.12.2025):**
- **Windows-only в Phase 1-2:** uiautomation crate поддерживает только Windows
- **VRAM бюджет:** RTX 5060 Ti 16GB — Ollama (qwen2.5:14b ~9GB) + Desktop Automation (<1GB)
- **Существующая кодовая база:** 11 Rust модулей в `client/src-tauri/src/`, НЕ создавать дубликаты
- **MCP Shell Server:** Уже работает (logs/mcp/mcp-events.log), использовать для PowerShell команд

---

## 📊 ДЕКОМПОЗИЦИЯ ЗАДАЧИ

### Уровень 1: Компоненты Системы

```
┌──────────────────────────────────────────────────┐
│          AUTONOMOUS QA AGENT (AGI-like)         │
│  • Планирование тестов                          │
│  • Обнаружение багов                            │
│  • Генерация фиксов                             │
│  • Валидация исправлений                        │
└───────────────┬──────────────────────────────────┘
                │ MCP Protocol (JSON-RPC)
                ▼
┌──────────────────────────────────────────────────┐
│    DESKTOP AUTOMATION MCP SERVER (Rust)         │
│  ┌─────────────┬────────────┬─────────────────┐ │
│  │ Visualizer  │  Executor  │  Log Monitor    │ │
│  └─────────────┴────────────┴─────────────────┘ │
│  • Accessibility Tree dump                      │
│  • enigo (mouse/keyboard)                       │
│  • CDP client (WebView JS)                      │
│  • Real-time log tailing                        │
│  • Error pattern recognition                    │
└───────────────┬──────────────────────────────────┘
                │ OS API / Tauri IPC / File Watch
                ▼
┌──────────────────────────────────────────────────┐
│         WORLD_OLLAMA DESKTOP CLIENT              │
│  • Tauri + Svelte UI                            │
│  • Rust backend (11 modules)                    │
│  • Logs: orchestrator, CORTEX, training, MCP    │
└──────────────────────────────────────────────────┘
```

### Уровень 2: Workflow Цикла

```
START
  ↓
1. LAUNCH CLIENT
   ├─ npm run tauri dev (background process)
   ├─ Wait for window (Accessibility API)
   └─ Verify startup logs (orchestrator.log)
  ↓
2. EXECUTE TEST SCENARIO
   ├─ Navigate UI (click buttons, fill forms)
   ├─ Trigger actions (start training, query CORTEX)
   └─ Capture screenshots (before/after states)
  ↓
3. MONITOR LOGS (real-time)
   ├─ Tail logs/orchestrator.log
   ├─ Tail logs/services/cortex.log
   ├─ Tail logs/training/*.log
   └─ Tail logs/mcp/mcp-events.log
  ↓
4. DETECT ERRORS
   ├─ Parse log lines (regex patterns)
   ├─ Compare UI state (screenshot hash diff)
   └─ Accessibility Tree validation
  ↓
5. GENERATE FIX (if error found)
   ├─ AI Orchestrator analyzes error context
   ├─ Generate code fix (Rust/Svelte/PowerShell)
   └─ Apply patch (replace_string_in_file)
  ↓
6. HOT RELOAD & RE-TEST
   ├─ Tauri hot-reload (automatic for Svelte)
   ├─ Rust rebuild (cargo build, restart process)
   └─ Re-run failed scenario
  ↓
7. VALIDATION
   ├─ Success? → Continue to next scenario
   └─ Fail again? → Escalate to human (GitHub issue)
  ↓
END (all scenarios passed)
```

---

## ⚠️ PREREQUISITES (Критические Предварительные Требования)

**Перед началом ЭТАПА 1 необходимо проверить:**

### Системные Требования

- ✅ **Ollama работает:** `ollama list | Select-String "qwen2.5:14b"`
- ✅ **CORTEX работает:** `Invoke-RestMethod http://localhost:8004/health`
- ✅ **Tauri Client собирается:** `npm run tauri build` (успешно)
- ⚠️ **rust-analyzer установлен:** `code --list-extensions | Select-String rust-analyzer`

### Текущее Состояние Проекта (Baseline)

**По состоянию на 03.12.2025:**

| Компонент | Статус | Примечание |
|-----------|--------|------------|
| Desktop Automation MCP Server | ❌ Не реализован | 0% (только документация) |
| AI Orchestrator | ❌ Не создан | 0% (нет кода) |
| enigo/uiautomation crates | ❌ Не установлены | Нет в Cargo.toml |
| Test Scenarios Library | ❌ Не создан | Нет YAML файлов |
| CI/CD Pipeline | ❌ Не настроен | Нет workflow |
| Tauri Client v0.3.1 | ✅ Работает | Релиз 02.12.2025 |
| MCP Shell Server | ✅ Production | Работает |
| PowerShell Scripts | ✅ 38 скриптов | Готовы к переносу |

**Вывод:** Roadmap стартует с **0% реализации** Desktop Automation компонентов.

---

## 🛠️ ПОШАГОВАЯ РЕАЛИЗАЦИЯ

### ЭТАП 0: SETUP (3 дня) — Подготовка Инфраструктуры

**Цель:** Установить все зависимости и создать структуру проекта перед началом кодирования.

#### Шаг 0.1: Установка VS Code Extension (2 часа)

**Задача:** Установить rust-analyzer для IntelliSense и автодополнения Rust кода.

**Команда:**
```powershell
code --install-extension rust-lang.rust-analyzer
```

**Проверка:**
```powershell
code --list-extensions | Select-String rust-analyzer
# Ожидаем: rust-lang.rust-analyzer
```

**Критерии успеха:**
- ✅ Расширение установлено
- ✅ VS Code показывает Rust syntax highlighting
- ✅ Автодополнение работает в `.rs` файлах

#### Шаг 0.2: Обновление Cargo.toml (1 час)

**Задача:** Добавить 7 новых dependencies для Desktop Automation.

**Изменения в `client/src-tauri/Cargo.toml`:**
```toml
[dependencies]
# Existing dependencies
tauri = { version = "1.5", features = ["shell-open"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
tokio = { version = "1", features = ["full"] }
chrono = "0.4"

# NEW: Desktop Automation dependencies
enigo = "0.1.12"                    # Mouse/keyboard simulation
uiautomation = "0.5.0"              # Windows UI Automation API
accesskit = "0.12"                  # Cross-platform Accessibility (future)
notify = "6.1"                      # File system watcher (logs monitoring)
image = "0.24"                      # Screenshot processing
screenshots = "0.8"                 # Screenshot capture
```

**Проверка:**
```powershell
cd client\src-tauri
cargo check
# Ожидаем: Finished dev [unoptimized + debuginfo] target(s) in Xs
```

**Критерии успеха:**
- ✅ `cargo check` проходит без ошибок
- ✅ `cargo tree | Select-String enigo` показывает enigo v0.1.12
- ✅ Время компиляции <2 минут (baseline для hot reload)

#### Шаг 0.3: Создание Структуры Директорий (30 минут)

**Задача:** Создать папки для нового кода.

**Команды:**
```powershell
# Rust modules
New-Item -ItemType Directory -Path "client\src-tauri\src\automation" -Force
New-Item -ItemType Directory -Path "client\src-tauri\src\mcp" -Force

# Python orchestrator
New-Item -ItemType Directory -Path "automation\orchestrator\src" -Force
New-Item -ItemType Directory -Path "automation\orchestrator\src\scenarios" -Force
New-Item -ItemType Directory -Path "automation\orchestrator\src\validators" -Force
New-Item -ItemType Directory -Path "automation\orchestrator\src\fixers" -Force
New-Item -ItemType Directory -Path "automation\orchestrator\config" -Force
New-Item -ItemType Directory -Path "automation\orchestrator\results" -Force
```

**Проверка:**
```powershell
Test-Path "client\src-tauri\src\automation"
Test-Path "automation\orchestrator\src"
# Оба должны вернуть: True
```

**Критерии успеха:**
- ✅ Все 7 директорий созданы
- ✅ Структура соответствует roadmap

#### Шаг 0.4: Python Virtual Environment (1 час)

**Задача:** Создать изолированное окружение для AI Orchestrator.

**Команды:**
```powershell
cd automation\orchestrator
python -m venv venv
.\venv\Scripts\Activate.ps1

# Установить dependencies
pip install langchain==0.1.0
pip install langchain-ollama==0.1.0
pip install pyyaml==6.0
pip install Pillow==10.0
pip install imagehash==4.3
pip install psutil==5.9
pip install jsonschema==4.20

# Сохранить requirements
pip freeze > requirements.txt
```

**Проверка:**
```powershell
pip list | Select-String langchain
# Ожидаем: langchain 0.1.0, langchain-ollama 0.1.0
```

**Критерии успеха:**
- ✅ Virtual environment создан
- ✅ 7 packages установлено
- ✅ `requirements.txt` содержит все зависимости
- ✅ `python -c "import langchain"` работает без ошибок

#### Шаг 0.5: Создание Placeholder Файлов (30 минут)

**Задача:** Создать пустые модули для проверки структуры.

**Файлы для создания:**
```rust
// client/src-tauri/src/automation/mod.rs
pub mod visualizer;
pub mod executor;
pub mod monitor;
pub mod verifier;
```

```rust
// client/src-tauri/src/automation/visualizer.rs
// TODO: Implement Accessibility Tree dump
```

```python
# automation/orchestrator/src/main.py
"""AI Orchestrator for Desktop Automation."""

def main():
    print("Desktop Automation Orchestrator v0.4.0")

if __name__ == "__main__":
    main()
```

**Проверка:**
```powershell
# Rust
cd client\src-tauri
cargo build

# Python
cd automation\orchestrator
.\venv\Scripts\python.exe src\main.py
# Ожидаем: "Desktop Automation Orchestrator v0.4.0"
```

**Критерии успеха ЭТАПА 0:**
- ✅ rust-analyzer установлен
- ✅ Cargo.toml обновлён (7 новых crates)
- ✅ `cargo build` проходит
- ✅ Python venv создан (7 packages)
- ✅ Структура директорий готова
- ✅ Placeholder файлы компилируются/запускаются

**Время:** 3 дня  
**Блокирует:** ВСЕ последующие этапы (нельзя начинать ЭТАП 1 без завершения ЭТАПА 0)

---

### ЭТАП 1: FOUNDATION (Недели 1-2) — Базовая автоматизация

**⚠️ ПРЕДУСЛОВИЕ:** ЭТАП 0 завершён на 100% (все crates установлены, структура создана).

#### Шаг 1.1: Базовые Тесты Интеграции Crates (8 часов)

**Задача:** Проверить, что установленные crates работают корректно в WORLD_OLLAMA окружении.

**Тесты для создания:**

**Код для валидации:**
```rust
// client/src-tauri/src/automation_server.rs (новый файл)
use enigo::{Enigo, MouseControllable};
use uiautomation::UIAutomation;

#[test]
fn test_enigo_initialization() {
    let enigo = Enigo::new();
    assert!(true); // Enigo создаётся без паники
}

#[test]
fn test_uiautomation_connection() {
    let automation = UIAutomation::new().unwrap();
    let root = automation.get_root_element().unwrap();
    assert!(root.get_name().is_ok()); // Можем читать accessibility tree
}
```

#### Шаг 1.2: MCP Server Skeleton (8 часов)

**Задача:** Создать MCP сервер по образцу `mcp-shell`

**Структура:**
```
client/src-tauri/src/
├── automation_server.rs   (main entry point)
├── automation/
│   ├── mod.rs
│   ├── visualizer.rs      (Accessibility Tree + Screenshot)
│   ├── executor.rs        (enigo wrapper)
│   ├── bridge.rs          (Tauri IPC + CDP client)
│   └── log_monitor.rs     (Real-time log tailing)
└── mcp/
    ├── mod.rs
    ├── protocol.rs        (JSON-RPC stdio handler)
    └── tools.rs           (5 MCP tools implementation)
```

**MCP Tools API (минимальный набор):**

```rust
// automation/mcp/tools.rs
pub enum ToolName {
    GetScreenState,    // → Accessibility Tree JSON
    ClickElement,      // (element_id: String) → Result<(), Error>
    TypeText,          // (text: String) → Result<(), Error>
    ExecuteScript,     // (script: String) → Result<String, Error>
    GetRecentLogs,     // (log_file: String, lines: usize) → Vec<String>
}
```

**Критерии успеха:**
- ✅ MCP сервер стартует: `cargo run --bin automation-server`
- ✅ Claude Desktop видит 5 tools в списке
- ✅ `get_screen_state` возвращает JSON (даже пустой)

#### Шаг 1.3: Visualizer — Accessibility Tree Dump (12 часов)

**Задача:** Реализовать `get_screen_state` для Windows

**Алгоритм:**
```rust
// automation/visualizer.rs
use uiautomation::{UIAutomation, UIElement};
use serde_json::json;

pub fn dump_accessibility_tree() -> Result<serde_json::Value, Error> {
    let automation = UIAutomation::new()?;
    let root = automation.get_root_element()?;
    
    // Найти окно Tauri по имени
    let window = find_window_by_name(&root, "WORLD_OLLAMA")?;
    
    // Рекурсивный обход дерева
    let tree = traverse_element(&window, 0, 5)?; // max depth 5
    
    Ok(json!({
        "window_title": window.get_name()?,
        "elements": tree,
        "timestamp": chrono::Utc::now().to_rfc3339()
    }))
}

fn traverse_element(element: &UIElement, depth: usize, max_depth: usize) -> Result<Vec<serde_json::Value>, Error> {
    if depth >= max_depth { return Ok(vec![]); }
    
    let mut elements = vec![];
    let walker = element.get_children()?;
    
    for child in walker {
        let bounds = child.get_bounding_rectangle()?;
        elements.push(json!({
            "id": child.get_runtime_id()?,  // Уникальный ID
            "name": child.get_name().unwrap_or_default(),
            "type": child.get_control_type()?.to_string(),
            "bounds": {
                "x": bounds.get_left(),
                "y": bounds.get_top(),
                "width": bounds.get_width(),
                "height": bounds.get_height()
            },
            "children": traverse_element(&child, depth + 1, max_depth)?
        }));
    }
    
    Ok(elements)
}
```

**Критерии успеха:**
- ✅ JSON содержит >0 элементов (хотя бы кнопку window close)
- ✅ Координаты валидны (x, y > 0, width/height > 0)
- ✅ Runtime ID уникальны (нет дубликатов)

**Тест:**
```rust
#[test]
fn test_accessibility_tree_dump() {
    // Запустить Tauri client в фоне
    let app = std::process::Command::new("npm")
        .args(&["run", "tauri", "dev"])
        .spawn()
        .unwrap();
    
    std::thread::sleep(std::time::Duration::from_secs(10)); // Ждём загрузки
    
    let tree = dump_accessibility_tree().unwrap();
    assert!(tree["elements"].as_array().unwrap().len() > 0);
    
    // Cleanup
    app.kill().unwrap();
}
```

#### Шаг 1.4: Executor — Click & Type (8 часов)

**Задача:** Реализовать `click_element` и `type_text`

**Код:**
```rust
// automation/executor.rs
use enigo::{Enigo, MouseControllable, MouseButton, KeyboardControllable};

pub struct Executor {
    enigo: Enigo,
}

impl Executor {
    pub fn new() -> Self {
        Self { enigo: Enigo::new() }
    }
    
    pub fn click_element(&mut self, element_id: &str) -> Result<(), Error> {
        // 1. Получить элемент из Accessibility Tree
        let element = get_element_by_runtime_id(element_id)?;
        let bounds = element.get_bounding_rectangle()?;
        
        // 2. Вычислить центр
        let x = bounds.get_left() + bounds.get_width() / 2;
        let y = bounds.get_top() + bounds.get_height() / 2;
        
        // 3. Debounce check (координаты стабильны?)
        std::thread::sleep(Duration::from_millis(100));
        let bounds2 = element.get_bounding_rectangle()?;
        let x2 = bounds2.get_left() + bounds2.get_width() / 2;
        let y2 = bounds2.get_top() + bounds2.get_height() / 2;
        
        if (x - x2).abs() > 5 || (y - y2).abs() > 5 {
            return Err(Error::ElementNotStable);
        }
        
        // 4. Клик
        self.enigo.mouse_move_to(x, y);
        std::thread::sleep(Duration::from_millis(50)); // Hover эффект
        self.enigo.mouse_click(MouseButton::Left);
        
        Ok(())
    }
    
    pub fn type_text(&mut self, text: &str) -> Result<(), Error> {
        // Ввод с задержкой (имитация человека)
        for ch in text.chars() {
            self.enigo.key_sequence(&ch.to_string());
            std::thread::sleep(Duration::from_millis(30)); // 33 WPM
        }
        Ok(())
    }
}
```

**Критерии успеха:**
- ✅ Клик по кнопке → кнопка визуально нажимается (видно на скриншоте)
- ✅ Ввод текста в поле → текст появляется в UI
- ✅ Debounce работает → клик не происходит во время анимации

#### Шаг 1.5: Log Monitor — Real-time Tailing (8 часов)

**Задача:** Реализовать `get_recent_logs` с file watching

**Алгоритм:**
```rust
// automation/log_monitor.rs
use notify::{Watcher, RecursiveMode, Event};
use std::sync::mpsc::channel;

pub struct LogMonitor {
    watchers: HashMap<String, RecommendedWatcher>,
    buffers: Arc<Mutex<HashMap<String, VecDeque<String>>>>,
}

impl LogMonitor {
    pub fn new() -> Self {
        Self {
            watchers: HashMap::new(),
            buffers: Arc::new(Mutex::new(HashMap::new())),
        }
    }
    
    pub fn watch_log(&mut self, log_path: &str) -> Result<(), Error> {
        let (tx, rx) = channel();
        let mut watcher = notify::recommended_watcher(tx)?;
        watcher.watch(Path::new(log_path), RecursiveMode::NonRecursive)?;
        
        // Background thread для чтения новых строк
        let buffers = Arc::clone(&self.buffers);
        let log_path_clone = log_path.to_string();
        
        std::thread::spawn(move || {
            let mut file = BufReader::new(File::open(&log_path_clone).unwrap());
            let mut buffer = String::new();
            
            loop {
                if let Ok(Event { kind: EventKind::Modify(_), .. }) = rx.recv() {
                    while file.read_line(&mut buffer).unwrap() > 0 {
                        buffers.lock().unwrap()
                            .entry(log_path_clone.clone())
                            .or_insert_with(VecDeque::new)
                            .push_back(buffer.clone());
                        buffer.clear();
                    }
                }
            }
        });
        
        self.watchers.insert(log_path.to_string(), watcher);
        Ok(())
    }
    
    pub fn get_recent_logs(&self, log_path: &str, n: usize) -> Vec<String> {
        self.buffers.lock().unwrap()
            .get(log_path)
            .map(|buf| buf.iter().rev().take(n).rev().cloned().collect())
            .unwrap_or_default()
    }
}
```

**Критерии успеха:**
- ✅ При записи в лог → `get_recent_logs` возвращает новую строку за <100ms
- ✅ Буфер ограничен (max 1000 строк на файл, FIFO eviction)
- ✅ Поддерживает 4 лога одновременно (orchestrator, cortex, training, mcp)

---

### ЭТАП 2: INTELLIGENCE (Недели 3-4) — AI Orchestrator

#### Шаг 2.1: AI Orchestrator Architecture (16 часов)

**Задача:** Создать Python/TypeScript orchestrator с LangChain

**Структура:**
```
automation/orchestrator/
├── src/
│   ├── main.py               (entry point)
│   ├── agent.py              (LangChain ReAct agent)
│   ├── tools.py              (MCP tools wrapper)
│   ├── scenarios/
│   │   ├── startup_test.py   (Сценарий 1: Запуск приложения)
│   │   ├── cortex_query.py   (Сценарий 2: Запрос к CORTEX)
│   │   ├── training_test.py  (Сценарий 3: Запуск обучения)
│   │   └── flows_test.py     (Сценарий 4: Выполнение Flow)
│   └── validators/
│       ├── log_validator.py  (Парсинг ошибок из логов)
│       └── ui_validator.py   (Сравнение скриншотов)
└── config/
    ├── test_suite.yaml       (Список всех тестов)
    └── error_patterns.yaml   (Regex для обнаружения ошибок)
```

**Ключевой компонент — ReAct Agent:**
```python
# agent.py
from langchain.agents import create_react_agent
from langchain_ollama import ChatOllama  # Локальная модель!
from langchain.tools import Tool

class DesktopAutomationAgent:
    def __init__(self, mcp_server_process):
        self.llm = ChatOllama(model="qwen2.5:14b", base_url="http://localhost:11434")
        self.mcp_client = MCPClient(mcp_server_process)
        
        # Tools из MCP server
        self.tools = [
            Tool(
                name="GetScreenState",
                func=self.mcp_client.call_tool,
                description="Returns Accessibility Tree JSON of current UI state"
            ),
            Tool(
                name="ClickElement",
                func=self.mcp_client.call_tool,
                description="Clicks element by ID from Accessibility Tree"
            ),
            Tool(
                name="TypeText",
                func=self.mcp_client.call_tool,
                description="Types text into focused input field"
            ),
            Tool(
                name="GetRecentLogs",
                func=self.mcp_client.call_tool,
                description="Returns last N lines from log file (orchestrator.log, cortex.log, etc.)"
            ),
        ]
        
        self.agent = create_react_agent(
            llm=self.llm,
            tools=self.tools,
            prompt=self.load_prompt("agent_system_prompt.txt")
        )
    
    def execute_scenario(self, scenario_name: str) -> TestResult:
        """
        Выполняет тестовый сценарий с помощью AI агента.
        Агент сам решает, какие tools вызывать и в каком порядке.
        """
        scenario = self.load_scenario(scenario_name)
        
        result = self.agent.invoke({
            "input": f"""
            Execute test scenario: {scenario.name}
            
            Steps:
            {scenario.steps}
            
            Success criteria:
            {scenario.success_criteria}
            
            Available logs:
            - logs/orchestrator.log
            - logs/services/cortex.log
            - logs/training/*.log
            - logs/mcp/mcp-events.log
            
            IMPORTANT:
            1. Verify each step by checking UI state (GetScreenState)
            2. Monitor logs after each action (GetRecentLogs)
            3. If error detected → return error details, NOT "seems working"
            4. Use exact element IDs from Accessibility Tree for clicks
            """
        })
        
        return self.parse_agent_result(result)
```

**Критерии успеха:**
- ✅ Агент может выполнить простой сценарий ("Click button X")
- ✅ Агент читает логи и обнаруживает ошибку (test: добавить ERROR в лог)
- ✅ Агент НЕ галлюцинирует (проверка: убрать кнопку из UI → агент вернёт "element not found")

#### Шаг 2.2: Error Detection Patterns (8 часов)

**Задача:** Создать базу regex паттернов для обнаружения ошибок в логах

**Файл:**
```yaml
# config/error_patterns.yaml
patterns:
  - name: "Ollama connection failed"
    regex: '\[ERROR\].*Failed to connect to Ollama|ConnectionRefused.*localhost:11434'
    severity: CRITICAL
    suggested_fix: "Check if Ollama is running: ollama list"
    
  - name: "CORTEX startup timeout"
    regex: '\[ERROR\].*CORTEX failed to start within \d+s'
    severity: HIGH
    suggested_fix: "Check logs/services/cortex.log for errors"
    
  - name: "Training process crashed"
    regex: 'CUDA out of memory|RuntimeError.*CUDA'
    severity: HIGH
    suggested_fix: "Reduce batch_size in training config"
    
  - name: "Port already in use"
    regex: 'Address already in use.*:(\d+)'
    severity: MEDIUM
    suggested_fix: "Kill process on port {port}: Get-Process -Id (Get-NetTCPConnection -LocalPort {port}).OwningProcess | Stop-Process"
    
  - name: "File not found"
    regex: 'FileNotFoundError|ENOENT.*no such file'
    severity: LOW
    suggested_fix: "Check if file path is correct and file exists"
```

**Валидатор:**
```python
# validators/log_validator.py
import re
import yaml

class LogValidator:
    def __init__(self, patterns_file):
        with open(patterns_file) as f:
            self.patterns = yaml.safe_load(f)['patterns']
    
    def scan_logs(self, log_lines: list[str]) -> list[Error]:
        errors = []
        for line in log_lines:
            for pattern in self.patterns:
                if re.search(pattern['regex'], line):
                    errors.append({
                        'name': pattern['name'],
                        'severity': pattern['severity'],
                        'log_line': line,
                        'suggested_fix': pattern['suggested_fix']
                    })
        return errors
```

**Критерии успеха:**
- ✅ Обнаруживает 5/5 тестовых ошибок (добавить в лог вручную)
- ✅ False positive rate <5% (не срабатывает на INFO/DEBUG)

#### Шаг 2.3: Auto-Fix Generator (20 часов)

**Задача:** Генерация кода-фиксов с помощью LLM + валидация

**Алгоритм:**
```python
# agent.py (дополнение)
class DesktopAutomationAgent:
    def generate_fix(self, error: Error) -> CodeFix:
        """
        Генерирует код-фикс для обнаруженной ошибки.
        Использует локальную модель (qwen2.5:14b) + RAG по кодовой базе.
        """
        # 1. Поиск контекста в коде
        context = self.search_codebase(error.log_line)
        
        # 2. Запрос к LLM
        prompt = f"""
        Error detected in WORLD_OLLAMA:
        
        Error: {error.name}
        Log line: {error.log_line}
        Suggested fix (high-level): {error.suggested_fix}
        
        Relevant code context:
        {context.file_path}:
        ```
        {context.code}
        ```
        
        Generate a concrete code fix. Return ONLY the exact code to replace, nothing else.
        Use the exact format from the codebase (indentation, style).
        
        Output format:
        FILE: <path>
        OLD_CODE:
        ```
        <exact old code with 3 lines context>
        ```
        NEW_CODE:
        ```
        <fixed code>
        ```
        """
        
        response = self.llm.invoke(prompt)
        fix = self.parse_fix_response(response.content)
        
        # 3. Валидация фикса
        if not self.validate_fix(fix):
            raise ValueError("Generated fix failed validation")
        
        return fix
    
    def validate_fix(self, fix: CodeFix) -> bool:
        """
        Проверяет, что fix не галлюцинация:
        1. Файл существует
        2. OLD_CODE точно присутствует в файле
        3. NEW_CODE компилируется (для Rust) или парсится (для JS/Svelte)
        """
        # Проверка 1
        if not os.path.exists(fix.file_path):
            return False
        
        # Проверка 2
        with open(fix.file_path) as f:
            content = f.read()
            if fix.old_code not in content:
                return False  # LLM галлюцинирует old code
        
        # Проверка 3 (для Rust)
        if fix.file_path.endswith('.rs'):
            temp_file = self.apply_fix_to_temp(fix)
            result = subprocess.run(['cargo', 'check', '--manifest-path', temp_file], capture_output=True)
            if result.returncode!= 0:
                return False  # Fix ломает компиляцию
        
        return True
```

**Критерии успеха:**
- ✅ Генерирует валидный Rust код (cargo check проходит)
- ✅ Галлюцинации обнаруживаются (100% валидации проходят)
- ✅ Фикс реально исправляет ошибку (повторный запуск теста → SUCCESS)

---

### ЭТАП 3: INTEGRATION (Неделя 5) — End-to-End Pipeline

#### Шаг 3.1: Test Scenarios Library (12 часов)

**Задача:** Создать 10 базовых E2E сценариев

**Сценарии:**

1. **startup_test.py** — Запуск приложения
   ```yaml
   name: Application Startup
   steps:
     - Start process: npm run tauri dev
     - Wait for window: WORLD_OLLAMA (timeout 30s)
     - Verify logs: orchestrator.log contains "Step 1: Checking Ollama"
     - Verify UI: GetScreenState returns >0 elements
   success_criteria:
     - Window visible
     - No ERROR in logs
     - Main panel loaded (element with id "main-panel" exists)
   ```

2. **cortex_query_test.py** — Запрос к CORTEX
   ```yaml
   name: CORTEX Query
   steps:
     - Click element: chat-input (by name)
     - Type text: "What is TRIZ?"
     - Press Enter
     - Wait for response (timeout 10s)
     - Verify logs: cortex.log contains "POST /query"
     - Verify UI: response container not empty
   success_criteria:
     - Response received within 10s
     - No "Failed to connect" in logs
     - UI shows answer with sources
   ```

3. **training_start_test.py** — Запуск обучения
   ```yaml
   name: Training Start
   steps:
     - Navigate to: Training Panel (click sidebar button)
     - Select profile: triz_td010v3_smoketest
     - Set epochs: 1
     - Click: Start Training
     - Wait for status: RUNNING (timeout 5s)
     - Verify logs: training_status.json contains "status":"running"
   success_criteria:
     - Status changes to RUNNING
     - training_status.json updated
     - No "Failed to start" in logs
   ```

4. **flows_execution_test.py** — Выполнение Flow
5. **settings_change_test.py** — Изменение настроек
6. **git_status_check_test.py** — Проверка Git статуса
7. **indexation_test.py** — Индексация документации
8. **mcp_shell_test.py** — MCP Shell команда
9. **window_resize_test.py** — Изменение размера окна
10. **crash_recovery_test.py** — Восстановление после краша

**Критерии успеха:**
- ✅ Все 10 сценариев проходят на чистой установке (100% pass rate)
- ✅ Каждый сценарий выполняется за <60s
- ✅ Flakiness rate <2% (98% stability)

#### Шаг 3.2: CI/CD Integration (8 часов)

**Задача:** Интеграция в GitHub Actions

**Workflow:**
```yaml
# .github/workflows/full-automation-test.yml
name: Full Automation Test Suite

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
  schedule:
    - cron: '0 3 * * *'  # Каждый день в 3:00

jobs:
  desktop-automation-test:
    runs-on: windows-latest  # Только Windows пока
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Rust
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      
      - name: Install Ollama
        run: |
          Invoke-WebRequest -Uri https://ollama.ai/download/OllamaSetup.exe -OutFile ollama.exe
          Start-Process ollama.exe /S -Wait
          ollama serve &
          ollama pull qwen2.5:14b
          ollama pull nomic-embed-text
      
      - name: Start CORTEX (LightRAG)
        run: |
          cd services/lightrag
          pip install -r requirements.txt
          python lightrag_server.py &
          Start-Sleep -Seconds 30  # Ждём загрузки
      
      - name: Build Tauri Client
        run: |
          cd client
          npm install
          npm run tauri build
      
      - name: Build Automation Server
        run: |
          cd client/src-tauri
          cargo build --release --bin automation-server
      
      - name: Run Test Suite
        run: |
          cd automation/orchestrator
          pip install -r requirements.txt
          python src/main.py --test-suite config/test_suite.yaml --mode ci
      
      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: |
            automation/orchestrator/results/*.json
            automation/orchestrator/screenshots/*.png
      
      - name: Report to GitHub
        if: failure()
        uses: actions/github-script@v7
        with:
          script: |
            const results = require('./automation/orchestrator/results/summary.json');
            github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: `[AUTO] Test Suite Failed - ${results.failed_tests.length} failures`,
              body: `Automation test suite failed:\n\n${results.details}`,
              labels: ['automation', 'bug']
            });
```

**Критерии успеха:**
- ✅ Workflow запускается на каждом PR
- ✅ Если тесты падают → создаётся GitHub issue автоматически
- ✅ Screenshots прикладываются к артефактам

#### Шаг 3.3: Hot Reload & Iterative Fix (12 часов)

**Задача:** Автоматическое исправление и перезапуск

**Алгоритм:**
```python
# orchestrator/src/main.py
def run_test_with_auto_fix(scenario_name: str, max_retries: int = 3):
    for attempt in range(max_retries):
        result = agent.execute_scenario(scenario_name)
        
        if result.status == "SUCCESS":
            return result
        
        if attempt < max_retries - 1:
            # Обнаружена ошибка → генерируем фикс
            errors = log_validator.scan_logs(result.logs)
            if not errors:
                # Ошибка не в логах → проблема с UI
                errors = ui_validator.compare_screenshots(
                    result.screenshot,
                    scenario.expected_screenshot
                )
            
            for error in errors:
                fix = agent.generate_fix(error)
                if agent.validate_fix(fix):
                    apply_fix(fix)  # replace_string_in_file
                    
                    # Hot reload
                    if fix.file_path.endswith('.rs'):
                        subprocess.run(['cargo', 'build'], cwd='client/src-tauri')
                        restart_tauri_process()
                    elif fix.file_path.endswith('.svelte'):
                        # Tauri hot-reload автоматически
                        time.sleep(2)
                    
                    break  # Пробуем только первый фикс
            else:
                # Не смогли сгенерировать фикс → escalate
                create_github_issue(error, result)
                return result
        else:
            # Последняя попытка провалилась
            create_github_issue(errors, result)
            return result
```

**Критерии успеха:**
- ✅ Искусственная ошибка (добавить typo в код) → агент исправляет за 1 попытку
- ✅ Сложная ошибка (логический баг) → агент пробует 3 раза, затем создаёт issue
- ✅ Hot reload работает → фикс применяется без полного перезапуска CI

---

### ЭТАП 4: HARDENING (Неделя 6) — Production Readiness

#### Шаг 4.1: Anti-Hallucination Checks (8 часов)

**Задача:** Добавить 5 слоёв защиты от галлюцинаций

**Слои:**

1. **Pre-action validation** (перед каждым click/type)
   ```python
   def click_element(element_id: str):
       # 1. Проверить, что элемент существует В ДАННЫЙ МОМЕНТ
       tree = mcp_client.call_tool("GetScreenState")
       if element_id not in [el['id'] for el in tree['elements']]:
           raise ElementNotFoundError(f"Element {element_id} not in current UI")
       
       # 2. Проверить, что элемент видим
       element = find_element_by_id(tree, element_id)
       if element['bounds']['width'] == 0 or element['bounds']['height'] == 0:
           raise ElementNotVisibleError(f"Element {element_id} has zero size")
       
       # 3. Выполнить клик
       mcp_client.call_tool("ClickElement", {"element_id": element_id})
       
       # 4. Post-action verification (скриншот изменился?)
       screenshot_before = take_screenshot()
       time.sleep(0.5)  # Ждём анимации
       screenshot_after = take_screenshot()
       if hash(screenshot_before) == hash(screenshot_after):
           logger.warning(f"Click on {element_id} had no visual effect")
   ```

2. **Log correlation** (каждое действие должно оставлять trace в логах)
   ```python
   def verify_action_logged(action_name: str, timeout: float = 5.0):
       start = time.time()
       while time.time() - start < timeout:
           logs = mcp_client.call_tool("GetRecentLogs", {"log_file": "orchestrator.log", "lines": 50})
           if any(action_name in line for line in logs):
               return True
           time.sleep(0.1)
       raise ActionNotLoggedError(f"Action {action_name} not found in logs after {timeout}s")
   ```

3. **Code fix validation** (см. Шаг 2.3)

4. **Screenshot hash comparison** (UI действительно изменился)

5. **Accessibility Tree diff** (новые элементы появились, старые исчезли)

**Критерии успеха:**
- ✅ Тест: агент пытается кликнуть несуществующий элемент → exception, НЕ "click successful"
- ✅ Тест: агент генерирует неправильный код → validation fails, код НЕ применяется
- ✅ 100% действий валидируются (ни одно действие без проверки)

#### Шаг 4.2: Regression Suite (8 часов)

**Задача:** Создать набор regression тестов для критических функций

**Список:**
```yaml
# config/regression_suite.yaml
regressions:
  - name: "CORTEX startup regression"
    description: "Ensure CORTEX always starts within 30s after Ollama"
    test: cortex_startup_test.py
    baseline_time: 25s
    alert_if_slower_than: 35s
    
  - name: "Training smoke test regression"
    description: "1 epoch training should complete without errors"
    test: training_smoke_test.py
    baseline_time: 120s
    alert_if_slower_than: 180s
    
  - name: "MCP Shell circuit breaker"
    description: "Circuit breaker should open after 3 failures"
    test: mcp_circuit_breaker_test.py
    expected_state: OPEN after 3 fails
    
  - name: "Git Safe Push validation"
    description: "7 blockers должны проверяться перед push"
    test: git_safe_push_test.py
    expected_blockers: 7
```

**Критерии успеха:**
- ✅ Regression suite запускается на каждом релизе (перед git tag)
- ✅ Если какой-то regression fail → релиз блокируется
- ✅ Baseline times обновляются автоматически (если новая версия стабильно быстрее)

#### Шаг 4.3: Release Validation Pipeline (12 часов)

**Задача:** Финальная валидация перед релизом

**Алгоритм:**
```python
# orchestrator/src/release_validator.py
def validate_release(version: str) -> ReleaseReport:
    """
    Выполняет полную валидацию перед релизом.
    Включает:
    1. Все 10 E2E сценариев
    2. Regression suite
    3. Performance baseline check
    4. Security audit (no hardcoded secrets)
    5. Documentation sync check
    """
    report = ReleaseReport(version=version)
    
    # 1. E2E Tests
    for scenario in load_scenarios("config/test_suite.yaml"):
        result = run_test_with_auto_fix(scenario.name, max_retries=1)
        report.add_test_result(scenario.name, result)
        if result.status!= "SUCCESS":
            report.block_release(f"E2E test {scenario.name} failed")
    
    # 2. Regression Suite
    for regression in load_regressions("config/regression_suite.yaml"):
        result = run_regression_test(regression)
        if result.is_slower_than_baseline():
            report.add_warning(f"Performance regression: {regression.name}")
        if result.status!= "SUCCESS":
            report.block_release(f"Regression {regression.name} failed")
    
    # 3. Performance Check
    startup_time = measure_startup_time()
    if startup_time > 45.0:  # seconds
        report.add_warning(f"Slow startup: {startup_time}s (baseline 30s)")
    
    # 4. Security Audit
    secrets = scan_for_hardcoded_secrets()
    if secrets:
        report.block_release(f"Found hardcoded secrets: {secrets}")
    
    # 5. Documentation Sync
    if not check_documentation_sync():
        report.add_warning("README.md or CHANGELOG.md out of sync")
    
    # Финальное решение
    if report.has_blockers():
        raise ReleaseBlockedError(report.blockers)
    
    return report
```

**Критерии успеха:**
- ✅ Релиз блокируется, если >0 E2E тестов упали
- ✅ Релиз блокируется, если найдены hardcoded secrets
- ✅ Релиз проходит за <10 минут (baseline для CI)

---

## 📊 МЕТРИКИ УСПЕХА

### Key Performance Indicators (KPIs)

| Метрика | Целевое значение | Критичность |
|---------|------------------|-------------|
| **E2E Test Coverage** | 100% критических сценариев | 🔴 P0 |
| **Test Suite Execution Time** | <10 минут (full suite) | 🟡 P1 |
| **Flakiness Rate** | <2% (98% stability) | 🔴 P0 |
| **False Positive Rate** (error detection) | <5% | 🟡 P1 |
| **Auto-Fix Success Rate** | >70% (первая попытка) | 🟢 P2 |
| **Hallucination Detection Rate** | 100% (ни один некорректный fix не применяется) | 🔴 P0 |
| **Release Validation Time** | <15 минут | 🟡 P1 |

### Acceptance Criteria

**Релиз v0.4.0 считается успешным, если:**

✅ **Autonomous Operation:**
- Агент может запустить Desktop Client самостоятельно (0 manual steps)
- Агент проходит 10/10 E2E сценариев без человеческого вмешательства
- Агент обнаруживает и исправляет минимум 5/10 искусственных ошибок

✅ **Zero Hallucinations:**
- 100% валидация кода-фиксов (cargo check/npm run build проходят)
- 100% валидация UI actions (элемент существует перед кликом)
- 0 false success reports (если тест упал → статус FAIL, не "seems working")

✅ **Production Ready:**
- GitHub Actions workflow работает на каждом PR
- Release validation pipeline блокирует релиз при наличии ошибок
- Документация синхронизирована (CHANGELOG.md обновлён автоматически)

✅ **Performance:**
- Full E2E suite: <10 минут
- Single E2E scenario: <60 секунд
- Hot reload после фикса: <30 секунд

---

## 🚧 РИСКИ И МИТИГАЦИЯ

| Риск | Вероятность | Влияние | Митигация |
|------|-------------|---------|-----------|
| **enigo не работает в GitHub Actions** | Средняя | Высокое | Использовать self-hosted runner с реальным дисплеем |
| **LLM генерирует некорректные фиксы** | Высокая | Критическое | Многослойная валидация (compile + test + human review для сложных) |
| **Accessibility Tree пуст для Canvas** | Средняя | Среднее | Fallback на screenshot + OmniParser (Phase 3) |
| **Flaky tests из-за анимаций** | Высокая | Высокое | Mandatory debounce + smart wait strategies |
| **CI timeout (10 min лимит)** | Низкая | Среднее | Параллельный запуск тестов + caching зависимостей |
| **Ollama/CORTEX не успевают стартовать** | Средняя | Высокое | Adaptive timeout (30s → 60s → 120s) + health checks |

---

## 📝 ЧЕКЛИСТ РЕАЛИЗАЦИИ

### Phase 1: Foundation (Недели 1-2)
- [ ] Шаг 1.1: Интеграция Rust crates (enigo, uiautomation, serde_json, tokio, notify)
- [ ] Шаг 1.2: MCP Server skeleton (JSON-RPC stdio handler)
- [ ] Шаг 1.3: Visualizer — Accessibility Tree dump (Windows)
- [ ] Шаг 1.4: Executor — click_element & type_text
- [ ] Шаг 1.5: Log Monitor — real-time tailing с notify

### Phase 2: Intelligence (Недели 3-4)
- [ ] Шаг 2.1: AI Orchestrator (LangChain + qwen2.5:14b)
- [ ] Шаг 2.2: Error Detection Patterns (regex YAML config)
- [ ] Шаг 2.3: Auto-Fix Generator (LLM + validation)

### Phase 3: Integration (Неделя 5)
- [ ] Шаг 3.1: Test Scenarios Library (10 E2E сценариев)
- [ ] Шаг 3.2: CI/CD Integration (GitHub Actions workflow)
- [ ] Шаг 3.3: Hot Reload & Iterative Fix (auto-apply + restart)

### Phase 4: Hardening (Неделя 6)
- [ ] Шаг 4.1: Anti-Hallucination Checks (5 слоёв защиты)
- [ ] Шаг 4.2: Regression Suite (baseline performance tracking)
- [ ] Шаг 4.3: Release Validation Pipeline (финальная проверка)

### Documentation
- [ ] Обновить README.md (добавить секцию "Automated Testing")
- [ ] Создать docs/automation/DESKTOP_AUTOMATION_SETUP.md
- [ ] Обновить .github/copilot-instructions.md (новый MCP server)
- [ ] Создать docs/automation/TROUBLESHOOTING.md

---

## 🎯 NEXT STEPS (Immediate Actions)

**Для начала реализации (следующие 3 дня):**

```powershell
# 1. Установить Rust Analyzer
code --install-extension rust-lang.rust-analyzer

# 2. Создать структуру директорий
New-Item -ItemType Directory -Path "client\src-tauri\src\automation" -Force
New-Item -ItemType Directory -Path "automation\orchestrator\src" -Force

# 3. Добавить dependencies
# Открыть client/src-tauri/Cargo.toml и добавить:
# enigo = "0.1.12"
# uiautomation = "0.5.0"
# serde_json = "1.0"
# tokio = { version = "1", features = ["full"] }
# notify = "6.1"

# 4. Создать первый тест
# Скопировать код из Шаг 1.3 в client/src-tauri/src/automation/visualizer.rs

# 5. Запустить smoke test
cargo test test_accessibility_tree_dump --manifest-path client/src-tauri/Cargo.toml
```

**GitHub Issue Template:**
```markdown
### Epic: Desktop Automation Agent (v0.4.0)

**Goal:** Полная автоматизация тестирования и релиза Desktop Client

**Phases:**
- [ ] Phase 1: Foundation (Недели 1-2)
- [ ] Phase 2: Intelligence (Недели 3-4)
- [ ] Phase 3: Integration (Неделя 5)
- [ ] Phase 4: Hardening (Неделя 6)

**Acceptance Criteria:**
- [ ] Агент запускает Desktop Client самостоятельно
- [ ] Агент проходит 10/10 E2E сценариев
- [ ] Агент исправляет минимум 5/10 искусственных ошибок
- [ ] 0 галлюцинаций (100% валидация фиксов)
- [ ] Release validation pipeline работает в CI

**Deliverables:**
- Desktop Automation MCP Server (Rust)
- AI Orchestrator (Python + LangChain)
- 10 E2E Test Scenarios
- GitHub Actions workflow
- Документация
```

---

**Автор roadmap:** AI Agent (GitHub Copilot)  
**Методология:** WORLD_OLLAMA audit-based planning + Tauri automation research  
**Дата создания:** 03.12.2025 16:05  
**Последнее обновление:** 03.12.2025 16:30 (добавлен ЭТАП 0, обновлён baseline)  
**Версия:** 1.1
