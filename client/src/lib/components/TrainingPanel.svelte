<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import { listen, type UnlistenFn } from "@tauri-apps/api/event";
  import { apiClient } from "$lib/api/client";
  import { notifications } from "$lib/stores/notifications";

  // ============================================================================

  type TrainingState = "idle" | "running" | "done" | "error";

  interface TrainingStatus {
    // PULSE v1 Protocol (FROZEN - 6 fields only)
    status: TrainingState; // "idle" | "running" | "done" | "error"
    epoch: number; // 0.0, 2.5, 3.0
    total_epochs: number; // 3.0
    loss: number; // 0.0, 0.342, 0.127
    message: string; // "epoch 2/3, step 150/800"
    timestamp: number; // Unix timestamp (seconds)
  }

  interface TrainingContext {
    // Client-side persistence (localStorage) - NOT in PULSE JSON
    profile: string;
    dataset: string;
  }

  interface TrainingProfile {
    id: string;
    name: string;
    description: string;
    base_model: string;
    recommended_epochs: number;
  }

  interface DatasetRoot {
    path: string;
    name: string;
    file_count?: number | null;
  }

  // ============================================================================
  // STATE
  // ============================================================================

  let status: TrainingStatus | null = null;
  let context: TrainingContext | null = null; // From localStorage
  let profiles: TrainingProfile[] = [];
  let datasets: DatasetRoot[] = [];

  let isLoading = false;
  let isStarting = false;
  let errorMessage: string | null = null;
  let timeSinceUpdate: number = 0;

  let eventUnlisten: UnlistenFn | null = null;
  let intervalId: ReturnType<typeof setInterval> | null = null;

  // ============================================================================
  // PULSE v1: Event Listening (ОРДЕР №16.3-UI КОМАНДА 2)
  // ============================================================================

  async function setupPulseListener() {
    eventUnlisten = await listen<TrainingStatus>(
      "training_status_update",
      (event) => {
        status = event.payload;
        timeSinceUpdate = 0;
        console.log("[TrainingPanel] PULSE update:", status);
      },
    );
  }

  // ============================================================================
  // Context Persistence (localStorage - ОРДЕР №16.3-UI КОМАНДА 2)
  // ============================================================================

  function loadContext() {
    const stored = localStorage.getItem("active_training_context");
    if (stored) {
      try {
        context = JSON.parse(stored);
      } catch (e) {
        console.warn("Failed to parse training context from localStorage:", e);
      }
    }
  }

  function saveContext(profileName: string, datasetName: string) {
    context = { profile: profileName, dataset: datasetName };
    localStorage.setItem("active_training_context", JSON.stringify(context));
  }

  // ============================================================================
  // API CALLS (Legacy - для начального статуса)
  // ============================================================================

  async function refreshStatus() {
    if (isLoading) return;
    isLoading = true;
    errorMessage = null;

    const res = await apiClient.getTrainingStatus();

    if (!res) {
      errorMessage = "Не удалось получить статус обучения";
      status = null;
    } else {
      // Convert old API format to PULSE v1 if needed
      status = {
        status: (res as any).status || (res as any).state || "idle",
        epoch: (res as any).epoch || (res as any).current_epoch || 0,
        total_epochs: (res as any).total_epochs || 0,
        loss: (res as any).loss || 0,
        message: (res as any).message || "No training in progress",
        timestamp: (res as any).timestamp || Math.floor(Date.now() / 1000),
      };
      timeSinceUpdate = 0;
    }

    isLoading = false;
  }

  async function loadProfiles() {
    const res = await apiClient.listTrainingProfiles();
    if (res) {
      profiles = res;
    }
  }

  async function loadDatasets() {
    const res = await apiClient.listDatasetsRoots();
    if (res) {
      datasets = res;
    }
  }

  async function handleClearStatus() {
    if (!confirm("Очистить статус обучения? Это сбросит все текущие данные.")) {
      return;
    }

    const res = await apiClient.clearTrainingStatus();

    if (res !== null) {
      notifications.push({
        type: "success",
        message: "Статус обучения очищен",
        timeoutMs: 4000,
      });
      await refreshStatus();
    }
  }

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  onMount(async () => {
    loadContext(); // PULSE v1: Load profile/dataset from localStorage
    await setupPulseListener(); // PULSE v1: Subscribe to training_status_update events
    refreshStatus(); // Initial status fetch
    loadProfiles();
    loadDatasets();

    intervalId = setInterval(() => {
      if (status && status.timestamp > 0) {
        timeSinceUpdate = Math.floor(Date.now() / 1000) - status.timestamp;
      }
    }, 1000); // Update "X seconds ago" display
  });

  onDestroy(() => {
    if (intervalId) clearInterval(intervalId);
    if (eventUnlisten) eventUnlisten(); // PULSE v1: Cleanup event listener
  });

  // ============================================================================
  // START TRAINING (DSL → execute_agent_command)
  // ============================================================================

  let selectedProfileId: string = "";
  let selectedDatasetPath: string = "";
  let epochs: number = 3;

  $: if (!selectedProfileId && profiles.length > 0) {
    selectedProfileId = profiles[0].id;
  }

  $: if (!selectedDatasetPath && datasets.length > 0) {
    selectedDatasetPath = datasets[0].path;
  }

  async function startTraining() {
    if (isStarting) return;

    if (!selectedProfileId || !selectedDatasetPath) {
      notifications.push({
        type: "error",
        message: "Не выбран профиль или датасет",
        timeoutMs: 4000,
      });
      return;
    }

    if (epochs < 1 || epochs > 5) {
      notifications.push({
        type: "error",
        message: "EPOCHS должен быть в диапазоне 1–5",
        timeoutMs: 4000,
      });
      return;
    }

    // PULSE v1: Save training context to localStorage (ОРДЕР №16.3-UI КОМАНДА 2)
    const profileObj = profiles.find((p) => p.id === selectedProfileId);
    const datasetObj = datasets.find((d) => d.path === selectedDatasetPath);
    if (profileObj && datasetObj) {
      saveContext(
        profileObj.name || selectedProfileId,
        datasetObj.name || selectedDatasetPath,
      );
    }

    const lines = [
      "TRAIN AGENT",
      `PROFILE="${selectedProfileId}"`,
      `DATA_PATH="${selectedDatasetPath}"`,
      `EPOCHS="${epochs}"`,
      'MODE="llama_factory"',
    ];

    const command_text = lines.join("\n");

    isStarting = true;
    try {
      const res = await apiClient.executeAgentCommand(command_text);

      if (res && res.success) {
        notifications.push({
          type: "success",
          message: "Обучение запущено",
          details: res.message,
          timeoutMs: 6000,
        });
        await refreshStatus();
      } else {
        const msg = res?.message ?? "Неизвестная ошибка при запуске обучения";
        notifications.push({
          type: "error",
          message: "Ошибка запуска обучения",
          details: msg,
          timeoutMs: 6000,
        });
      }
    } finally {
      isStarting = false;
    }
  }

  // ============================================================================
  // COMPUTED
  // ============================================================================

  // PULSE v1: State labels and emojis
  $: stateLabel = status
    ? {
        idle: "IDLE",
        running: "ВЫПОЛНЯЕТСЯ",
        done: "ЗАВЕРШЕНО",
        error: "ОШИБКА",
      }[status.status]
    : "НЕИЗВЕСТНО";

  $: stateEmoji = status
    ? {
        idle: "💤",
        running: "🔄",
        done: "✅",
        error: "❌",
      }[status.status]
    : "❓";

  // PULSE v1: Progress calculation (ОРДЕР №16.3-UI КОМАНДА 2)
  // NaN Protection: Math.min + zero-division guard
  $: progressPercent =
    status && status.total_epochs > 0
      ? Math.min(100, Math.round((status.epoch / status.total_epochs) * 100))
      : 0;
</script>

<div class="training-panel">
  <!-- ========================================
       HEADER: Status Badge + Controls
       ======================================== -->
  <header class="training-header">
    <div class="title-row">
      <h2>
        {stateEmoji} Training Status
      </h2>
      <span class={`badge badge-${status?.status ?? "unknown"}`}>
        {stateLabel}
      </span>
    </div>

    <div class="controls-row">
      <button on:click={refreshStatus} disabled={isLoading}>
        {#if isLoading}
          ⏳ Обновление...
        {:else}
          🔄 Обновить
        {/if}
      </button>

      <button
        class="danger"
        on:click={handleClearStatus}
        disabled={isLoading || status?.status === "running"}
      >
        🗑️ Очистить статус
      </button>

      {#if status && status.timestamp > 0}
        <span class="last-updated">
          Обновлено: {timeSinceUpdate}s назад
        </span>
      {/if}
    </div>

    {#if errorMessage}
      <div class="error-box">
        ❌ {errorMessage}
      </div>
    {/if}
  </header>

  <!-- ========================================
       DETAILS: Current Training Info
       ======================================== -->
  <section class="training-details">
    <h3>📋 Детали обучения</h3>

    {#if status}
      <div class="details-grid">
        <!-- PULSE v1: Context from localStorage -->
        <div class="detail-item">
          <div class="label">Профиль (localStorage)</div>
          <div class="value">{context?.profile ?? "—"}</div>
        </div>

        <div class="detail-item">
          <div class="label">Датасет (localStorage)</div>
          <div class="value mono">{context?.dataset ?? "—"}</div>
        </div>

        <!-- PULSE v1: Live metrics -->
        <div class="detail-item">
          <div class="label">Эпохи (PULSE)</div>
          <div class="value">
            {status.epoch.toFixed(1)} / {status.total_epochs.toFixed(1)}
          </div>
        </div>

        <div class="detail-item">
          <div class="label">Loss (PULSE)</div>
          <div class="value">{status.loss.toFixed(4)}</div>
        </div>

        <div class="detail-item">
          <div class="label">Timestamp (PULSE)</div>
          <div class="value mono">
            {new Date(status.timestamp * 1000).toLocaleString("ru-RU")}
          </div>
        </div>

        <div class="detail-item">
          <div class="label">Сообщение (PULSE)</div>
          <div class="value">{status.message}</div>
        </div>
      </div>

      <!-- Progress Bar (PULSE v1) -->
      {#if status.status === "running" && status.total_epochs > 0}
        <div class="progress-section">
          <div class="progress-label">
            <span>Прогресс обучения</span>
            <span>{progressPercent}%</span>
          </div>
          <div class="progress-bar">
            <div class="progress-fill" style="width: {progressPercent}%">
              {progressPercent > 10 ? `${progressPercent}%` : ""}
            </div>
          </div>
        </div>
      {/if}
    {:else}
      <p class="placeholder">
        Данные о текущем обучении отсутствуют. Запустите обучение через вкладку <code
          >🔧 Commands</code
        >.
      </p>
    {/if}
  </section>

  <!-- ========================================
       START TRAINING: Inline Form
       ======================================== -->
  <section class="start-training">
    <h3>🚀 Запуск обучения из панели</h3>

    <div class="start-grid">
      <div class="form-control">
        <label for="profile-select">Профиль</label>
        <select id="profile-select" bind:value={selectedProfileId}>
          {#each profiles as profile}
            <option value={profile.id}>{profile.name}</option>
          {/each}
        </select>
      </div>

      <div class="form-control">
        <label for="dataset-select">Датасет</label>
        <select id="dataset-select" bind:value={selectedDatasetPath}>
          {#each datasets as dataset}
            <option value={dataset.path}>{dataset.name}</option>
          {/each}
        </select>
      </div>

      <div class="form-control">
        <label for="epochs-input">Эпохи (1–5)</label>
        <input
          id="epochs-input"
          type="number"
          min="1"
          max="5"
          bind:value={epochs}
        />
      </div>
    </div>

    <div class="start-actions">
      <button
        on:click={startTraining}
        disabled={isStarting || status?.status === "running"}
      >
        {#if isStarting}
          ⏳ Запуск...
        {:else}
          ▶️ Запустить обучение
        {/if}
      </button>
      <span class="hint"
        >Команда уходит как DSL через execute_agent_command.</span
      >
    </div>
  </section>

  <!-- ========================================
       LOG: Messages from Training
       ======================================== -->
  <section class="training-log">
    <h3>📝 Лог обучения</h3>

    {#if status && status.message}
      <pre class="log-block">{status.message}</pre>
    {:else}
      <p class="placeholder">Пока нет сообщений от процесса обучения.</p>
    {/if}
  </section>

  <!-- ========================================
       INFO: Available Profiles
       ======================================== -->
  <section class="info-section">
    <h3>🎯 Доступные профили обучения</h3>

    {#if profiles.length > 0}
      <div class="profile-grid">
        {#each profiles as profile}
          <div class="profile-card">
            <h4>{profile.name}</h4>
            <p>{profile.description}</p>
            <p class="meta">
              Модель: <code>{profile.base_model}</code><br />
              Рекомендуемые эпохи: <code>{profile.recommended_epochs}</code>
            </p>
          </div>
        {/each}
      </div>
    {:else}
      <p class="placeholder">Загрузка профилей...</p>
    {/if}
  </section>

  <!-- ========================================
       INFO: Available Datasets
       ======================================== -->
  <section class="info-section">
    <h3>📁 Доступные датасеты</h3>

    {#if datasets.length > 0}
      <ul class="dataset-list">
        {#each datasets as dataset}
          <li class="dataset-item">
            <div>
              <div class="name">📂 {dataset.name}</div>
              <div class="path">{dataset.path}</div>
            </div>
            {#if dataset.file_count !== null}
              <div class="count">{dataset.file_count} файлов</div>
            {/if}
          </li>
        {/each}
      </ul>
    {:else}
      <p class="placeholder">Загрузка датасетов...</p>
    {/if}
  </section>

  <!-- ========================================
       HELP: How to Start Training
       ======================================== -->
  <section class="training-help">
    <h3>💡 Как запустить обучение</h3>
    <ol>
      <li>Откройте вкладку <code>🔧 Commands</code>.</li>
      <li>
        Введите команду в формате DSL:
        <pre
          style="margin: 10px 0; padding: 10px; background: rgba(0,0,0,0.3); border-radius: 4px; color: #4CAF50;">TRAIN AGENT
PROFILE: triz_engineer
DATA_PATH: E:\WORLD_OLLAMA\library\raw_documents
EPOCHS: 3
MODE: llama_factory</pre>
      </li>
      <li>Нажмите <b>Запустить команду</b>.</li>
      <li>Вернитесь на вкладку <code>🧪 Training</code> для мониторинга.</li>
      <li>Статус будет автоматически обновляться каждые 5 секунд.</li>
    </ol>
  </section>
</div>

<style>
  .training-panel {
    max-width: 1200px;
    margin: 0 auto;
    padding: 30px 20px;
  }

  /* ========================================
     HEADER
     ======================================== */

  .training-header {
    background: linear-gradient(135deg, #1e1e1e 0%, #2a2a2a 100%);
    border: 1px solid #333;
    border-radius: 12px;
    padding: 25px;
    margin-bottom: 25px;
  }

  .title-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
  }

  h2 {
    color: #4caf50;
    margin: 0;
    font-size: 1.8em;
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .badge {
    display: inline-block;
    padding: 6px 14px;
    border-radius: 20px;
    font-size: 0.85em;
    font-weight: bold;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .badge-idle {
    background: #555;
    color: #ddd;
  }

  .badge-queued {
    background: #ff9800;
    color: #000;
  }

  .badge-running {
    background: linear-gradient(90deg, #2196f3, #00bcd4);
    color: white;
    animation: pulse 2s ease-in-out infinite;
  }

  @keyframes pulse {
    0%,
    100% {
      opacity: 1;
    }
    50% {
      opacity: 0.7;
    }
  }

  .badge-done {
    background: #4caf50;
    color: white;
  }

  .badge-error {
    background: #f44336;
    color: white;
  }

  .badge-unknown {
    background: #666;
    color: #ccc;
  }

  .controls-row {
    display: flex;
    gap: 15px;
    align-items: center;
    flex-wrap: wrap;
  }

  button {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border: none;
    padding: 10px 18px;
    border-radius: 8px;
    cursor: pointer;
    font-size: 0.95em;
    font-weight: 600;
    transition: all 0.2s;
  }

  button:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
  }

  button:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  button.danger {
    background: linear-gradient(135deg, #f44336 0%, #e91e63 100%);
  }

  button.danger:hover:not(:disabled) {
    box-shadow: 0 4px 12px rgba(244, 67, 54, 0.4);
  }

  .toggle {
    display: flex;
    align-items: center;
    gap: 8px;
    color: #aaa;
    font-size: 0.9em;
    cursor: pointer;
  }

  .toggle input[type="checkbox"] {
    cursor: pointer;
  }

  .last-updated {
    color: #888;
    font-size: 0.85em;
    margin-left: auto;
  }

  .error-box {
    background: #3d1f1f;
    border: 1px solid #f44336;
    border-radius: 8px;
    padding: 12px;
    margin-top: 15px;
    color: #ff9999;
    font-size: 0.9em;
  }

  /* ========================================
     DETAILS SECTION
     ======================================== */

  .training-details {
    background: #1e1e1e;
    border: 1px solid #333;
    border-radius: 12px;
    padding: 25px;
    margin-bottom: 25px;
  }

  .training-details h3 {
    color: #4caf50;
    margin: 0 0 20px 0;
    font-size: 1.3em;
  }

  .details-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 20px;
  }

  .detail-item {
    background: #252525;
    padding: 15px;
    border-radius: 8px;
    border-left: 3px solid #667eea;
  }

  .label {
    color: #888;
    font-size: 0.85em;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin-bottom: 8px;
  }

  .value {
    color: #fff;
    font-size: 1.1em;
    font-weight: 500;
    word-break: break-word;
  }

  .value.mono {
    font-family: "Courier New", monospace;
    font-size: 0.95em;
    color: #4caf50;
  }

  .placeholder {
    color: #666;
    font-style: italic;
    text-align: center;
    padding: 20px;
  }

  /* ========================================
     PROGRESS BAR
     ======================================== */

  .progress-section {
    margin-top: 20px;
  }

  .progress-label {
    display: flex;
    justify-content: space-between;
    margin-bottom: 8px;
    color: #aaa;
    font-size: 0.9em;
  }

  .progress-bar {
    width: 100%;
    height: 24px;
    background: #252525;
    border-radius: 12px;
    overflow: hidden;
    position: relative;
  }

  .progress-fill {
    height: 100%;
    background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
    transition: width 0.3s ease;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-size: 0.85em;
    font-weight: bold;
  }

  /* ========================================
     LOG SECTION
     ======================================== */

  .training-log {
    background: #1e1e1e;
    border: 1px solid #333;
    border-radius: 12px;
    padding: 25px;
    margin-bottom: 25px;
    max-height: 400px; /* Limit height */
    overflow-y: auto; /* Enable scroll */
  }

  .training-log h3 {
    color: #4caf50;
    margin: 0 0 15px 0;
    font-size: 1.3em;
  }

  .log-block {
    background: #0d0d0d;
    border: 1px solid #444;
    border-radius: 8px;
    padding: 15px;
    color: #4caf50;
    font-family: "Courier New", monospace;
    font-size: 0.9em;
    white-space: pre-wrap;
    word-wrap: break-word;
    max-height: 300px;
    overflow-y: auto;
  }

  .log-block::-webkit-scrollbar {
    width: 8px;
  }

  .log-block::-webkit-scrollbar-track {
    background: #1a1a1a;
    border-radius: 4px;
  }

  .log-block::-webkit-scrollbar-thumb {
    background: #667eea;
    border-radius: 4px;
  }

  /* ========================================
     INFO SECTIONS
     ======================================== */

  .info-section {
    background: #1e1e1e;
    border: 1px solid #333;
    border-radius: 12px;
    padding: 25px;
    margin-bottom: 25px;
  }

  .info-section h3 {
    color: #4caf50;
    margin: 0 0 15px 0;
    font-size: 1.2em;
  }

  .profile-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 15px;
    margin-bottom: 20px;
  }

  .profile-card {
    background: #252525;
    border: 1px solid #333;
    border-radius: 8px;
    padding: 15px;
    transition: all 0.2s;
  }

  .profile-card:hover {
    border-color: #667eea;
    transform: translateY(-2px);
  }

  .profile-card h4 {
    color: #667eea;
    margin: 0 0 8px 0;
    font-size: 1.1em;
  }

  .profile-card p {
    color: #aaa;
    font-size: 0.9em;
    margin: 5px 0;
  }

  .profile-card .meta {
    color: #666;
    font-size: 0.85em;
    margin-top: 10px;
  }

  .dataset-list {
    list-style: none;
    padding: 0;
    margin: 0;
  }

  .dataset-item {
    background: #252525;
    border: 1px solid #333;
    border-radius: 8px;
    padding: 12px 15px;
    margin-bottom: 10px;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .dataset-item .name {
    color: #fff;
    font-weight: 500;
  }

  .dataset-item .path {
    color: #4caf50;
    font-family: "Courier New", monospace;
    font-size: 0.85em;
  }

  .dataset-item .count {
    color: #888;
    font-size: 0.85em;
  }

  /* ========================================
     HELP SECTION
     ======================================== */

  .training-help {
    background: linear-gradient(135deg, #1e3a5f 0%, #2a1f3a 100%);
    border: 1px solid #667eea;
    border-radius: 12px;
    padding: 25px;
  }

  .training-help h3 {
    color: #4caf50;
    margin: 0 0 15px 0;
    font-size: 1.2em;
  }

  .training-help ol {
    color: #ccc;
    line-height: 1.8;
    padding-left: 25px;
  }

  .training-help li {
    margin-bottom: 8px;
  }

  .training-help code {
    background: rgba(102, 126, 234, 0.2);
    color: #667eea;
    padding: 2px 6px;
    border-radius: 4px;
    font-family: "Courier New", monospace;
    font-size: 0.9em;
  }

  .training-help b {
    color: #fff;
  }

  /* ========================================
     START FORM
     ======================================== */

  .start-training {
    background: #1e1e1e;
    border: 1px solid #333;
    border-radius: 12px;
    padding: 25px;
    margin-bottom: 25px;
  }

  .start-training h3 {
    color: #4caf50;
    margin: 0 0 15px 0;
    font-size: 1.2em;
  }

  .start-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    gap: 16px;
    margin-bottom: 16px;
  }

  .form-control {
    display: flex;
    flex-direction: column;
    gap: 6px;
  }

  .form-control label {
    color: #ccc;
    font-size: 0.9em;
  }

  .form-control select,
  .form-control input[type="number"] {
    background: #252525;
    border: 1px solid #444;
    border-radius: 6px;
    color: #fff;
    padding: 8px 10px;
    font-size: 0.95em;
  }

  .start-actions {
    display: flex;
    justify-content: flex-start;
    align-items: center;
    gap: 12px;
  }

  .hint {
    color: #777;
    font-size: 0.85em;
  }
</style>
