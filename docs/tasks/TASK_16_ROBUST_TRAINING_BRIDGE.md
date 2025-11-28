# 📋 TASK 16: ROBUST TRAINING BRIDGE (Надёжный Мост Обучения)

**Версия:** 2.0 (REFACTORED by SESA3002a)  
**Дата:** 28 ноября 2025 г.  
**Статус:** 🟡 PLANNED (v0.2.0)  
**Приоритет:** 🔴 **CRITICAL** (блокирует v0.2.0 release)

---

## 🎯 ЦЕЛЬ (ИКР — Идеальный Конечный Результат)

Создать **отказоустойчивый** и **переносимый** конвейер запуска обучения моделей, который:

1. ✅ Работает на **любом диске** (C:, D:, E:, F:) без модификации кода
2. ✅ Гарантирует **надёжную передачу статуса** (без хрупкого Regex парсинга)
3. ✅ Обеспечивает **бесшовную UX** (запуск → автопереход к мониторингу)

**ТРИЗ Принципы применены:**
- **№35 (Изменение параметров):** Система адаптируется к среде (динамические пути)
- **№26 (Копирование/Упрощение):** Простой и надёжный протокол "Pulse" вместо сложного парсера
- **№10 (Предварительное действие):** Решаем проблему путей ДО построения сложного UI
- **№5 (Объединение):** Команда запуска автоматически переключает UI на панель мониторинга

---

## 🚨 SESA3002a AUDIT FINDINGS

### Критические противоречия в исходной спецификации (v1.0):

#### 1. **Противоречие Фундамента (Hardcoded Paths)**

**Факт:**
```powershell
# scripts/start_agent_training.ps1:15
$PROJECT_ROOT = "E:\WORLD_OLLAMA"  # ❌ ЖЁСТКО ЗАКОДИРОВАНО

# src-tauri/src/commands.rs:47
let project_root = PathBuf::from("E:\\WORLD_OLLAMA");  # ❌ HARDCODE
```

**Проблема:**
- Система работает **только на компьютере автора** (диск E:)
- При установке на C:, D:, F: → **КРИТИЧЕСКИЙ СБОЙ**
- Блокирует распространение v0.1.0/v0.2.0

**ТРИЗ-анализ (Принцип №1 — Дробление):**
> "Строить сложную надстройку (Training UI) на фундаменте, который не подлежит масштабированию (Hardcoded Paths), нарушает Принцип Секционирования. Если пользователь установит систему на диск D:\, 'Идеальный' Training Loop не сработает."

---

#### 2. **Противоречие Связности (Regex Fragility)**

**Факт:**
- Исходный план: парсить stdout LLaMA Factory через Regex в реальном времени
- LLaMA Factory базируется на `transformers`, формат логов **не гарантирован стабильным**

**Проблема:**
```python
# Пример хрупкого парсинга (из исходного плана v1.0)
if line.match(r"Epoch (\d+)/(\d+)"):  # ❌ СЛОМАЕТСЯ при обновлении LLaMA Factory
    epoch = int(match.group(1))
```

**Риск:**
- Любое обновление библиотеки → парсер ломается
- Добавление одного пробела в формат логов → UI показывает "Unknown status"

**ТРИЗ-анализ (Принцип №26 — Копирование/Упрощение):**
> "Вместо сложного и хрупкого средства (Regex парсер чужих логов), используем простое и надёжное (JSON status file с контролируемым форматом)."

---

#### 3. **Противоречие Интерфейса (UX Disconnect)**

**Факт:**
- Команда `TRAIN AGENT` запускается в `Commands Panel`
- Мониторинг прогресса — в `Training Panel` (другая вкладка)

**Проблема:**
- Пользователь вынужден **разрывать контекст**: запустить → переключить вкладку → искать свой training run
- Нарушение **Принципа №5 (Объединение)**: функции запуска и контроля должны быть связаны

**UX анти-паттерн:**
```
User action:
1. Открывает Commands Panel
2. Вводит "TRAIN AGENT profile=triz-expert"
3. Жмёт Execute
4. ❓ Где смотреть результат? → должен сам догадаться переключить на Training Panel
5. ❓ Какой именно training run его? → должен искать по имени профиля
```

---

## ✅ ОБНОВЛЁННАЯ СПЕЦИФИКАЦИЯ (v2.0 — SESA3002a Refactor)

### Подзадачи (3 mandatory, 0 optional)

---

### 🔴 TASK 16.1: Path Agnosticism (ПРИОРИТЕТ #1)

**Цель:** Полностью устранить зависимость от буквы диска и жёстких путей.

**Затронутые компоненты:**

#### Rust Backend (src-tauri/src/commands.rs)

**Было (HARDCODE):**
```rust
let project_root = PathBuf::from("E:\\WORLD_OLLAMA");
let training_script = project_root.join("scripts\\start_agent_training.ps1");
```

**Стало (DYNAMIC):**
```rust
use tauri::Manager;

#[tauri::command]
fn get_project_root(app_handle: AppHandle) -> Result<String, String> {
    let resource_path = app_handle.path_resolver()
        .resource_dir()
        .ok_or("Failed to resolve resource directory")?;
    Ok(resource_path.to_string_lossy().to_string())
}

#[tauri::command]
async fn execute_train_command(
    app_handle: AppHandle,
    params: TrainParams
) -> Result<TrainResult> {
    // ✅ Dynamic root detection
    let project_root = PathBuf::from(get_project_root(app_handle.clone())?);
    let training_script = project_root.join("scripts/start_agent_training.ps1");
    
    // Validate existence
    if !training_script.exists() {
        return Err(format!("Training script not found: {:?}", training_script));
    }
    
    // Pass project root to PowerShell script
    let output = Command::new("pwsh")
        .arg("-File")
        .arg(training_script)
        .arg("-ProjectRoot")
        .arg(&project_root)
        .arg("-ProfileId")
        .arg(&params.profile_id)
        .spawn()?;
    
    Ok(TrainResult { status: "started", pid: output.id() })
}
```

---

#### PowerShell Scripts (scripts/start_agent_training.ps1)

**Было (HARDCODE):**
```powershell
# Line 15 (OLD)
$PROJECT_ROOT = "E:\WORLD_OLLAMA"
$LLAMA_FACTORY = "$PROJECT_ROOT\services\llama_factory"
```

**Стало (PARAMETERIZED):**
```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectRoot,  # ✅ Passed from Rust backend
    
    [Parameter(Mandatory=$true)]
    [string]$ProfileId
)

# Validate project root
if (-not (Test-Path $ProjectRoot)) {
    Write-Error "Project root does not exist: $ProjectRoot"
    exit 1
}

# Derive paths dynamically
$LLAMA_FACTORY = Join-Path $ProjectRoot "services\llama_factory"
$VENV_PYTHON = Join-Path $LLAMA_FACTORY "venv\Scripts\python.exe"
$STATUS_FILE = Join-Path $ProjectRoot "training_status.json"

# Initialize Pulse Protocol status
@{
    status = "starting"
    profile_id = $ProfileId
    epoch = 0
    total_epochs = 0
    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
} | ConvertTo-Json | Set-Content $STATUS_FILE
```

---

#### Other Scripts (START_ALL.ps1, STOP_ALL.ps1, etc.)

**Рефакторинг аналогично:**
```powershell
# scripts/START_ALL.ps1
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$CORTEX_PATH = Join-Path $ProjectRoot "services\lightrag"
$VENV_ACTIVATE = Join-Path $CORTEX_PATH "venv\Scripts\Activate.ps1"
```

**Критерии успеха:**
- [ ] Grep search по всему проекту не находит "E:\\WORLD_OLLAMA" (кроме документации)
- [ ] Система запускается на C:, D:, F: без модификации кода
- [ ] Portable exe работает в произвольной директории

**Оценка времени:** 1-2 дня (рефакторинг + тестирование на разных дисках)

---

### 🟠 TASK 16.2: Протокол "Pulse" (Замена Regex Парсера)

**Цель:** Надёжная передача статуса обучения без хрупкого парсинга stdout.

**Идея (Принцип №26 — Упрощение):**
Вместо попыток распарсить каждую строку вывода LLaMA Factory (формат может измениться), используем **контролируемый протокол обмена состоянием**:

1. PowerShell скрипт создаёт JSON status file (`training_status.json`)
2. Python wrapper (обёртка вокруг LLaMA Factory) обновляет этот файл при критических событиях
3. Tauri backend читает файл каждые 2 секунды
4. UI отображает последний статус

---

#### Структура Pulse Protocol

**Файл:** `E:\WORLD_OLLAMA\training_status.json` (но путь динамический!)

**Формат:**
```json
{
  "status": "running",         // starting | running | error | completed
  "profile_id": "triz-expert", // ID профиля агента
  "epoch": 3,                  // Текущая эпоха
  "total_epochs": 10,          // Всего эпох
  "last_loss": 0.8591,         // Последний loss (опционально)
  "error_message": null,       // Текст ошибки если status=error
  "timestamp": "2025-11-28 23:45:12"
}
```

**События (Pulse Signals):**

| Event | status | Description |
|-------|--------|-------------|
| `__PULSE_START__` | starting | Training process launched |
| `__PULSE_EPOCH_END__` | running | Epoch completed (increment epoch counter) |
| `__PULSE_ERROR__` | error | Critical error occurred |
| `__PULSE_DONE__` | completed | Training finished successfully |

---

#### Python Wrapper (services/llama_factory/pulse_wrapper.py)

**НОВЫЙ ФАЙЛ:**
```python
import json
import subprocess
import sys
from pathlib import Path

def update_pulse(status_file: Path, **kwargs):
    """Update training_status.json with new pulse data"""
    try:
        with open(status_file, 'r') as f:
            data = json.load(f)
        data.update(kwargs)
        data['timestamp'] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(status_file, 'w') as f:
            json.dump(data, f, indent=2)
    except Exception as e:
        print(f"PULSE ERROR: {e}", file=sys.stderr)

def main():
    project_root = Path(sys.argv[1])
    profile_id = sys.argv[2]
    status_file = project_root / "training_status.json"
    
    # PULSE: Start
    update_pulse(status_file, status="starting")
    
    try:
        # Launch actual LLaMA Factory training
        result = subprocess.run([
            "python", "-m", "llamafactory.cli.train",
            "--config", f"configs/{profile_id}.yaml"
        ], capture_output=True, text=True, check=True)
        
        # Parse only critical info (epochs) from stdout
        for line in result.stdout.split('\n'):
            if "Epoch" in line:  # Simplified check
                # PULSE: Epoch done
                update_pulse(status_file, status="running", epoch=epoch)
        
        # PULSE: Done
        update_pulse(status_file, status="completed")
        
    except subprocess.CalledProcessError as e:
        # PULSE: Error
        update_pulse(status_file, status="error", error_message=str(e))
        sys.exit(1)

if __name__ == "__main__":
    main()
```

**Интеграция в start_agent_training.ps1:**
```powershell
# Launch Python wrapper instead of direct LLaMA Factory call
& $VENV_PYTHON "$LLAMA_FACTORY\pulse_wrapper.py" $ProjectRoot $ProfileId
```

---

#### Rust Backend Monitoring

**src-tauri/src/commands.rs:**
```rust
use std::time::Duration;
use tokio::time::sleep;

#[derive(serde::Deserialize, Clone)]
struct TrainingStatus {
    status: String,
    profile_id: String,
    epoch: u32,
    total_epochs: u32,
    last_loss: Option<f64>,
    error_message: Option<String>,
    timestamp: String,
}

#[tauri::command]
async fn monitor_training_status(
    app_handle: AppHandle,
    profile_id: String
) -> Result<(), String> {
    let project_root = PathBuf::from(get_project_root(app_handle.clone())?);
    let status_file = project_root.join("training_status.json");
    
    loop {
        sleep(Duration::from_secs(2)).await;
        
        if !status_file.exists() {
            continue;  // Wait for file to be created
        }
        
        let content = std::fs::read_to_string(&status_file)
            .map_err(|e| format!("Failed to read status file: {}", e))?;
        
        let status: TrainingStatus = serde_json::from_str(&content)
            .map_err(|e| format!("Failed to parse status JSON: {}", e))?;
        
        // Emit event to frontend
        app_handle.emit_all("training_status_update", status.clone())?;
        
        // Stop monitoring if completed or errored
        if status.status == "completed" || status.status == "error" {
            break;
        }
    }
    
    Ok(())
}
```

**Критерии успеха:**
- [ ] Pulse Protocol работает без зависимости от формата логов LLaMA Factory
- [ ] UI обновляется каждые 2 секунды (плавный прогресс)
- [ ] Обработка ошибок (status=error) отображается в UI
- [ ] После обновления LLaMA Factory протокол продолжает работать

**Оценка времени:** 2-3 дня (Python wrapper + Rust monitoring + UI integration)

---

### 🟢 TASK 16.3: UX Bridge (Автопереключение DSL → Panel)

**Цель:** Бесшовный переход от запуска к мониторингу (Принцип №10 — Предварительное действие).

**Проблема (текущая UX):**
```
User: Вводит TRAIN AGENT profile=triz-expert в Commands Panel
System: Executes command
User: ❓ Что дальше? Где смотреть результат?
User: Вручную переключает на Training Panel
User: ❓ Какой training run мой? Ищет по profile_id...
```

**Решение (улучшенная UX):**
```
User: Вводит TRAIN AGENT profile=triz-expert в Commands Panel
System: Executes command
System: ✅ Автоматически переключает UI на Training Panel
System: ✅ Передаёт profile_id для фильтрации
User: Сразу видит свой training run в мониторинге
```

---

#### Реализация (Svelte Frontend)

**components/CommandsPanel.svelte:**
```svelte
<script lang="ts">
import { invoke } from '@tauri-apps/api/tauri';
import { listen } from '@tauri-apps/api/event';

async function executeCommand(cmd: string) {
    const parsed = parseCommandDSL(cmd);
    
    if (parsed.type === 'TRAIN') {
        // Execute training
        const result = await invoke('execute_train_command', {
            params: { profile_id: parsed.profile_id }
        });
        
        // ✅ Auto-switch to Training Panel
        window.dispatchEvent(new CustomEvent('switch-tab', {
            detail: { tab: 'training', profile_id: parsed.profile_id }
        }));
        
        // ✅ Start monitoring
        await invoke('monitor_training_status', {
            profile_id: parsed.profile_id
        });
    }
}
</script>
```

**App.svelte (Tab Manager):**
```svelte
<script lang="ts">
import { onMount } from 'svelte';

let activeTab = 'chat';
let highlightedProfileId = null;

onMount(() => {
    window.addEventListener('switch-tab', (e: CustomEvent) => {
        activeTab = e.detail.tab;
        highlightedProfileId = e.detail.profile_id;
    });
});
</script>

{#if activeTab === 'training'}
    <TrainingPanel highlightedProfile={highlightedProfileId} />
{/if}
```

**components/TrainingPanel.svelte:**
```svelte
<script lang="ts">
import { listen } from '@tauri-apps/api/event';

export let highlightedProfile: string | null = null;

let trainingRuns: TrainingStatus[] = [];

listen('training_status_update', (event) => {
    const status = event.payload;
    
    // Update or add training run
    const index = trainingRuns.findIndex(r => r.profile_id === status.profile_id);
    if (index >= 0) {
        trainingRuns[index] = status;
    } else {
        trainingRuns.push(status);
    }
    
    // Auto-scroll to highlighted profile
    if (status.profile_id === highlightedProfile) {
        document.getElementById(`run-${status.profile_id}`)?.scrollIntoView();
    }
});
</script>

{#each trainingRuns as run}
    <div id="run-{run.profile_id}" class:highlighted={run.profile_id === highlightedProfile}>
        <h3>{run.profile_id}</h3>
        <p>Status: {run.status}</p>
        <progress value={run.epoch} max={run.total_epochs}></progress>
    </div>
{/each}
```

**Критерии успеха:**
- [ ] После выполнения `TRAIN AGENT` UI автоматически переключается на Training Panel
- [ ] Соответствующий training run подсвечивается/скроллится в видимую область
- [ ] Пользователь сразу видит прогресс без manual navigation

**Оценка времени:** 1 день (event system + UI navigation)

---

## 📊 ИТОГОВАЯ ОЦЕНКА

| Подзадача | Приоритет | Время | Блокер |
|-----------|-----------|-------|--------|
| **16.1 Path Agnosticism** | 🔴 CRITICAL | 1-2 дня | Блокирует v0.2.0 release |
| **16.2 Pulse Protocol** | 🟠 HIGH | 2-3 дня | Зависит от 16.1 |
| **16.3 UX Bridge** | 🟢 MEDIUM | 1 день | Зависит от 16.2 |
| **ИТОГО** | — | **4-6 дней** | — |

**Общий прогресс:** 0% (все подзадачи planned)

---

## 🗑️ ВЫНЕСЕНО В BACKLOG (v0.3.0+)

Следующие элементы исключены из TASK 16 как избыточные для MVP (v0.2.0):

### Детальный Regex Парсинг Логов
**Причина отказа:**
- Высокая хрупкость (формат логов LLaMA Factory не гарантирован)
- Сложность поддержки (требует обновления парсера при каждом апдейте библиотеки)
- Pulse Protocol достаточен для MVP (status + epoch — это 80% нужной информации)

**Применённый принцип ТРИЗ:** №26 (Копирование/Упрощение)

---

### VRAM Real-time Monitoring
**Причина отказа:**
- Сложная интеграция (`nvidia-smi` парсинг, polling каждые 500ms)
- Не является критической функцией для **запуска** обучения
- Достаточно статического VRAM pre-check перед стартом

**Применённый принцип ТРИЗ:** Принцип необходимости и достаточности

**Альтернатива (v0.3.0):**
```rust
// Simple pre-check before training
#[tauri::command]
fn check_vram_availability() -> Result<VramStatus> {
    let output = Command::new("nvidia-smi")
        .arg("--query-gpu=memory.free")
        .arg("--format=csv,noheader,nounits")
        .output()?;
    
    let free_mb: u32 = String::from_utf8(output.stdout)?.trim().parse()?;
    
    Ok(VramStatus {
        free_mb,
        sufficient: free_mb > 6000  // 6GB minimum for Qwen2.5-3B
    })
}
```

---

### Toast Notifications
**Причина отказа:**
- Косметическая функция (не влияет на функциональность)
- Статус в Training Panel достаточен для информирования пользователя
- Может раздражать при длительном обучении (10+ эпох)

**Применённый принцип ТРИЗ:** Не перегружать систему второстепенными функциями

---

### ETA Расчёт (Estimated Time Remaining)
**Причина отказа:**
- Требует накопления статистики скорости обучения (минимум 2-3 эпохи)
- В первых эпохах даёт большую погрешность (irritates user: "ETA 2h" → "ETA 5h" → "ETA 3h")
- Скорость обучения нестабильна (зависит от batch размера, системной нагрузки)

**Применённый принцип ТРИЗ:** Не давать пользователю информацию, в которой система не уверена

**Альтернатива (v0.3.0):**
```rust
// Simple epoch-based ETA (после 3+ эпох)
if status.epoch >= 3 {
    let avg_epoch_time = total_time / status.epoch;
    let remaining_epochs = status.total_epochs - status.epoch;
    let eta_seconds = avg_epoch_time * remaining_epochs;
    
    // Display only if variance < 20%
    if epoch_time_variance < 0.2 {
        display_eta(eta_seconds);
    }
}
```

---

## ✅ КРИТЕРИИ ПРИЁМКИ (Definition of Done)

### TASK 16.1 (Path Agnosticism)
- [ ] `grep -r "E:\\WORLD_OLLAMA"` не находит hardcode (кроме docs)
- [ ] Система запускается на C:, D:, F: без errors
- [ ] Portable exe работает в произвольной директории (C:\Users\...\Downloads\WorldOllama)
- [ ] Все PowerShell скрипты принимают `-ProjectRoot` параметр
- [ ] Rust backend использует `get_project_root()` вместо hardcode

### TASK 16.2 (Pulse Protocol)
- [ ] `training_status.json` создаётся корректно при запуске обучения
- [ ] Статус обновляется каждые 2 секунды в UI
- [ ] Pulse Protocol работает после обновления LLaMA Factory (независимость от формата логов)
- [ ] Обработка ошибок: `status=error` → UI показывает error message
- [ ] Завершение обучения: `status=completed` → мониторинг останавливается

### TASK 16.3 (UX Bridge)
- [ ] После `TRAIN AGENT` команды UI автоматически переключается на Training Panel
- [ ] Соответствующий training run подсвечивается (highlight animation)
- [ ] Auto-scroll к active training run
- [ ] Если несколько training runs — выделяется последний запущенный

### Integration Tests
- [ ] End-to-end test: Commands Panel → Execute TRAIN → Auto-switch → Monitor → Complete
- [ ] Test на разных дисках (C:, D:, E:, F:)
- [ ] Test с ошибкой обучения (error handling)
- [ ] Test с manual tab switch (не ломает функциональность)

---

## 🎓 ТЕХНИЧЕСКИЕ ТРЕБОВАНИЯ

### Rust (Tauri Backend)
- Tauri >= 2.0
- `serde_json` для парсинга `training_status.json`
- `tokio` для async monitoring loop

### PowerShell
- PowerShell Core >= 7.0 (кроссплатформенность)
- Поддержка `-File` и `-Command` режимов

### Python
- Python >= 3.10
- LLaMA Factory (версия как в проекте)
- `pathlib` для кроссплатформенных путей

### Frontend (Svelte)
- Tauri API (`@tauri-apps/api`)
- Event system для tab switching
- CSS animations для highlight эффектов

---

## 📝 ПРИМЕЧАНИЯ

### Почему не используем WebSocket для Pulse Protocol?

**Рассмотрено и отклонено:**
- WebSocket требует запуск отдельного сервера (complexity)
- JSON file polling проще и надёжнее для MVP
- Latency 2 секунды допустима для training monitoring

**Возможное улучшение (v0.3.0):**
Если потребуется real-time monitoring (<500ms latency), можно добавить WebSocket канал.

---

### Обратная совместимость

**TASK 16 v2.0 (refactored) НЕ ЛОМАЕТ v0.1.0:**
- Commands Panel DSL остаётся тем же (`TRAIN AGENT profile=...`)
- Training Panel UI адаптируется к новому протоколу
- Старые логи (если есть) игнорируются, используется только Pulse

---

## 🔗 СВЯЗАННЫЕ ЗАДАЧИ

- **TASK 15:** Training Backend (MVP safe mode) — ✅ ЗАВЕРШЕНО
- **TASK 12:** Training Panel UI — ✅ ЗАВЕРШЕНО (требует обновление для Pulse Protocol)
- **TECHNICAL_DEBT_REPORT.md:** Hardcoded Paths (#1.0) — 🔴 CRITICAL
- **Phase 1.1:** RAG Quality Tuning — ⏳ PLANNED (параллельно с TASK 16)

---

**Дата создания:** 28 ноября 2025 г. 23:50  
**Автор спецификации:** SESA3002a (ТРИЗ Аэрокосмический Архитектор)  
**Версия:** 2.0 (REFACTORED)  
**Статус:** ✅ APPROVED для реализации

**Следующий шаг:** Начать TASK 16.1 (Path Agnosticism) — estimated start: 29.11.2025
