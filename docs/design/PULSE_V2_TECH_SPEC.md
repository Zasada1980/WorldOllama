# PULSE v2 — Technical Specification

Версия: draft v1  
Связанные документы:
- PULSE_V2_REQUIREMENTS.md
- PULSE_V2_IA_UX.md
- PULSE_V2_MIGRATION_PLAN.md

Цель этого документа — описать **технический протокол PULSE v2**:
- какие сущности и события существуют на уровне протокола;
- как они передаются от Python → Rust → UI;
- как из них собирается snapshot (в духе PULSE v1);
- какие есть ограничения по частоте/надёжности/совместимости.

---

## 1. Архитектурный контур

### 1.1. Участники

1. **Python Training Process**
   - запускает фактическое обучение (run_training);
   - генерирует события PULSE v2 (status/progress/metrics/error);
   - отвечает за базовую агрегацию и частоту событий на своём уровне.

2. **Rust Backend (Tauri)**
   - принимает события от Python:
     - через файловый мост,
     - или через IPC/pipe (подробно ниже);
   - отвечает за:
     - поддерживает in-memory модель текущих `TrainingRun` / `TrainingSnapshot`,
     - при необходимости логирует события (JSONL) для истории,
     - транслирует события в UI (Tauri events / invoke-ответы).

3. **UI (Svelte / Tauri Frontend)**
   - подписывается на события от Rust (event-канал);
   - поддерживает состояние:
     - `TrainingState` (current + recent runs);
     - интеграцию с Flows (для TRAIN шагов);
   - отображает состояние и метрики согласно PULSE_V2_IA_UX.md.

---

## 2. Формат событий PULSE v2

### 2.1. Общий формат TrainingEvent

Базовый формат события на "проволоке" (между Python и Rust):

```json
{
  "event_type": "status_changed | progress | metric | error | completed | cancelled",
  "training_id": "train_2025_11_29_001",
  "flow_run_id": "flow_abc123",     // optional
  "flow_step_id": "step_03",        // optional
  "timestamp": 1732800000,
  "payload": { /* тип-специфичные поля */ }
}
```

Обязательные поля:

- `event_type` — тип события (строка из ограниченного набора);
- `training_id` — уникальный ID запуска обучения;
- `timestamp` — Unix timestamp (int, секунды или миллисекунды — фиксируется в реализации);
- `payload` — объект, структура которого зависит от типа события.

Дополнительные поля:

- `flow_run_id` — если обучение запущено как часть FlowRun;
- `flow_step_id` — ID шага внутри flow.

### 2.2. Типы событий и payload

#### 2.2.1. `status_changed`

Используется для смены статуса обучения (см. IA/UX документ):

```json
{
  "event_type": "status_changed",
  "training_id": "train_2025_11_29_001",
  "timestamp": 1732800000,
  "payload": {
    "status": "preparing | running | cooling_down | done | error | cancelled",
    "message": "Preparing datasets and model…"
  }
}
```

Требования:

- статус `done`, `error`, `cancelled` считаются терминальными для данного `training_id`;
- Rust/UI должны игнорировать любые последующие `progress`/`metric` события, пришедшие после терминального статуса.

#### 2.2.2. `progress`

Модель прогресса по epoch/steps, без жёсткого требования наличия `steps`:

```json
{
  "event_type": "progress",
  "training_id": "train_2025_11_29_001",
  "timestamp": 1732800100,
  "payload": {
    "epoch": 3,
    "total_epochs": 10,
    "step": 120,          // optional
    "total_steps": 800    // optional
  }
}
```

Требования:

- `epoch` и `total_epochs` — основные поля;
- `step` и `total_steps` опциональны;
- на основе этих данных UI может вычислять процент.

#### 2.2.3. `metric`

Событие с метриками; допускается несколько типов в одном payload:

```json
{
  "event_type": "metric",
  "training_id": "train_2025_11_29_001",
  "timestamp": 1732800110,
  "payload": {
    "loss": 0.342,
    "time_per_epoch": 12.5,
    "samples_per_second": 153.0
  }
}
```

Требования:

- все поля в `payload` опциональны;
- отсутствие метрик не ломает протокол;
- за конкретный набор метрик отвечает реализация (Python).

#### 2.2.4. `error`

Отдельное событие об ошибке:

```json
{
  "event_type": "error",
  "training_id": "train_2025_11_29_001",
  "timestamp": 1732800120,
  "payload": {
    "error_code": "CUDA_OOM",
    "message": "Out of memory on device 0",
    "is_retryable": false,
    "details": {
      "trace_id": "abc123",
      "extra": "…"
    }
  }
}
```

Требования:

- при генерации события `error`:
  - допустимо (и желательно) также генерировать `status_changed` → `error`;
  - Rust/UI должны отражать ошибки в статусе и History.

#### 2.2.5. `completed`

Финальное событие об успешном завершении:

```json
{
  "event_type": "completed",
  "training_id": "train_2025_11_29_001",
  "timestamp": 1732800200,
  "payload": {
    "epochs_completed": 10,
    "final_loss": 0.289,
    "duration_seconds": 600.0
  }
}
```

Требования:

- как минимум:
  - `epochs_completed`,
  - `final_loss` (если есть),
  - `duration_seconds` (опционально, можно вычислить на Rust, если есть started/finished timestamps).
- может сопровождаться `status_changed` → `done`.

#### 2.2.6. `cancelled` (опционально)

Если поддерживается остановка обучения:

```json
{
  "event_type": "cancelled",
  "training_id": "train_2025_11_29_001",
  "timestamp": 1732800150,
  "payload": {
    "reason": "user_request"
  }
}
```

---

## 3. Каналы доставки событий Python → Rust → UI

### 3.1. Python → Rust

PULSE v2 допускает несколько вариантов для реализации, но базовый ориентир:

**Вариант A (File-based JSONL канал):**

- Python пишет события в файл (или несколько файлов) в формате JSON Lines:
  - `logs/training/training_{training_id}.jsonl`
  - каждый `.jsonl` — все события конкретного `training_id`;
- Rust:
  - следит за новыми событиями (tail / периодическое чтение с сохранением offset),
  - обновляет in-memory модель,
  - при необходимости ретранслирует события вверх.

Плюсы:
- простая диагностика — логи читаемы человеком;
- хорошо стыкуется с уже существующим logs/flows.

Минусы:
- требуется аккуратность с IO / локациями.

**Вариант B (Pipe/IPC, оставляем как возможность):**

- Python пишет в stdout/pipe JSONL события;
- Rust слушает pipe и пишет в in-memory модель + при желании в файлы.

> Конкретный выбор и детали реализации закрепляются уже в имплементационном ORDER (например ORDER 42), а не в этом документе. Здесь важно, чтобы формат событий был унифицирован.

### 3.2. Rust → UI

Рекомендуемый способ: **Tauri events** + при необходимости `invoke` для initial snapshot.

1. Для каждого нового события Rust:
   - обновляет internal state (TrainingState);
   - эмитит Tauri event:
     - `training_event` (raw event),
     - или сразу агрегированный `training_snapshot_updated` (на уровне snapshot).

2. При открытии TrainingPanel:
   - UI может вызвать `get_training_snapshot(training_id)` через `invoke`:
     - получает последнее состояние (snapshot);
     - подписывается на обновления через Tauri events.

---

## 4. Snapshot-модель (PULSE v1 совместимость)

### 4.1. TrainingSnapshot структура

В Rust/TS модель snapshot может выглядеть логически так:

```json
{
  "training_id": "train_2025_11_29_001",
  "status": "running",
  "epoch": 3,
  "total_epochs": 10,
  "loss": 0.342,
  "message": "epoch 3/10, step 150/800",
  "timestamp": 1732800115
}
```

Это по сути тот же формат, что PULSE v1, но:

- Здесь `training_id` становится обязательным.
- `message` может собираться из последнего status/metric события.

**Правило построения snapshot:**

- `status` — из последнего `status_changed`/терминальных событий (`completed`, `error`, `cancelled`);
- `epoch`, `total_epochs` — из последнего `progress` события;
- `loss` — из последнего `metric` события, где указан `loss`;
- `message` — либо из последнего `status_changed`, либо синтезируется:
  - например: `"epoch 3/10, loss 0.342"`;
- `timestamp` — timestamp последнего учтённого события (max по времени).

### 4.2. Маппинг v2 → v1

PULSE v1 JSON, который уже используется (например, `training_status.json`):

```json
{
  "status": "idle | running | done | error",
  "epoch": 0.0,
  "total_epochs": 3.0,
  "loss": 0.0,
  "message": "Starting training...",
  "timestamp": 1732800000
}
```

Может быть получен из snapshot, оставив только эти 6 полей.

Таким образом:

- PULSE v2 → snapshot → PULSE v1 JSON (умный "адаптер");
- существующий код, ожидающий PULSE v1, может работать с адаптером, пока постепенно не мигрируем.

---

## 5. In-memory модель на стороне Rust

### 5.1. TrainingState (high-level схема)

В Rust (концептуально):

- `HashMap<String, TrainingSnapshot>` — мапа `training_id → snapshot`;
- `Vec<TrainingRunSummary>` — список недавних запусков для UI;
- отдельные структуры для логирования/истории при необходимости.

### 5.2. Обработка входящих событий

Алгоритм (в терминах Rust-логики):

1. Получить/распарсить `TrainingEvent` из JSON.
2. Найти/создать контекст для `training_id`.
3. В зависимости от `event_type`:
   - обновить snapshot-поля;
   - обновить информацию о завершении (done/error/cancelled);
   - при необходимости записать событие в лог-файл (JSONL).
4. Эмитить:
   - raw event (опционально),
   - или только обновлённый snapshot (рекомендуется для основного UI).

---

## 6. Ограничения по частоте событий и производительности

### 6.1. Частота генерации на Python-стороне

Рекомендации:

- События `progress`/`metric`:
  - не чаще 2–5 раз в секунду для UX;
  - при необходимости Python может делать агрегацию (например, отправлять только каждый N-й шаг).

- События `status_changed`, `error`, `completed`:
  - должны отправляться сразу при смене состояния.

### 6.2. Дебаунс на Rust → UI

Даже если Python присылает события чаще, Rust:

- может эмитить snapshot для UI не чаще X раз в N миллисекунд (например, раз в 200–500ms);
- может объединять несколько событий в один snapshot:
  - если пришли `progress` и `metric` почти одновременно.

---

## 7. Ошибки, устойчивость и edge cases

### 7.1. Некорректные события

Rust должен корректно обрабатывать:

- битый JSON (пропускать, логировать, не падать);
- неизвестный `event_type`:
  - логировать как warning;
  - игнорировать для snapshot.

### 7.2. Out-of-order и дубликаты

Правила:

- при обработке событий использовать `timestamp`:
  - если событие "старее", чем уже применённый snapshot, можно его игнорировать (или только логировать);
- дубликаты:
  - если событие полностью идентично уже применённому (по `training_id` + `timestamp` + `event_type` + `payload`), можно просто пропускать.

### 7.3. Потеря связи с Python

Если Python-процесс упал или перестал присылать события:

- Rust может:
  - через таймаут пометить `training_id` как "stale";
  - отправить UI специальное состояние/событие:
    - либо `status_changed` → `error` с кодом типа `TRAINING_LOST`,
    - либо специальное поле в snapshot ("состояние неизвестно").

---

## 8. Out of Scope для первой реализации

Для первой итерации PULSE v2 **НЕ являются обязательными**:

- двунаправленная связь (UI → PULSE events);
- сложные distributed сценарии (несколько Python-процессов на разные машины);
- встроенные алерты/нотификации (почта/мессенджеры);
- реализация глобального "центрального" event store.

Эти темы могут быть отдельными ORDER'ами (например, PULSE v3+), не блокируют базовый PULSE v2.

---
