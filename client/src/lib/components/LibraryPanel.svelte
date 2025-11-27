<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import { apiClient, type AppSettings } from "$lib/api/client";
  import { notifications } from "$lib/stores/notifications";

  type IndexationState = "idle" | "running" | "error";

  interface IndexationStatus {
    state: IndexationState;
    last_run: string | null;
    last_error?: string | null;
  }

  let status: IndexationStatus = {
    state: "idle",
    last_run: null,
    last_error: null
  };
  
  let settings: AppSettings | null = null;
  let isStarting = false;
  let isLoadingStatus = false;
  let refreshInterval: ReturnType<typeof setInterval> | null = null;

  async function loadStatus() {
    isLoadingStatus = true;
    const res = await apiClient.callApi<IndexationStatus>("get_indexation_status", {}, true);
    if (res) {
      status = res;
    }
    isLoadingStatus = false;
  }

  async function loadSettings() {
    const res = await apiClient.callApi<AppSettings>("get_app_settings", {}, true);
    if (res) {
      settings = res;
    }
  }

  async function startIndexation() {
    isStarting = true;
    const res = await apiClient.callApi<{ started_at: string }>("start_indexation");
    if (res) {
      notifications.push({
        type: "info",
        message: "Индексация запущена",
        details: `Старт: ${new Date(res.started_at).toLocaleString('ru-RU')}`,
        timeoutMs: 6000
      });
      await loadStatus();
    }
    isStarting = false;
  }

  function getStateIcon(state: IndexationState): string {
    switch (state) {
      case "idle": return "⏸️";
      case "running": return "⚙️";
      case "error": return "❌";
      default: return "❓";
    }
  }

  function getStateLabel(state: IndexationState): string {
    switch (state) {
      case "idle": return "Ожидание";
      case "running": return "Выполняется";
      case "error": return "Ошибка";
      default: return "Неизвестно";
    }
  }

  function formatDate(dateStr: string | null): string {
    if (!dateStr) return "Никогда";
    try {
      return new Date(dateStr).toLocaleString('ru-RU', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
      });
    } catch {
      return dateStr;
    }
  }

  onMount(() => {
    loadStatus();
    loadSettings();
    // Авто-обновление статуса каждые 10 секунд
    refreshInterval = setInterval(loadStatus, 10000);
  });

  onDestroy(() => {
    if (refreshInterval) {
      clearInterval(refreshInterval);
    }
  });
</script>

<section class="library-panel">
  <div class="header">
    <h1 class="title">📚 Library & Indexation</h1>
    <p class="subtitle">Управление базой знаний и индексацией документов</p>
  </div>

  <!-- Блок индексации -->
  <div class="card indexation-block">
    <div class="card-header">
      <h2 class="card-title">⚙️ Индексация новых файлов</h2>
    </div>
    <div class="card-content">
      <p class="hint">
        Индексация обновляет базу знаний CORTEX, добавляя новые файлы из директории <code>library/raw_documents</code>.
      </p>

      <div class="status-display">
        <div class="status-row">
          <span class="label">Текущее состояние:</span>
          <span class="status-badge" class:running={status.state === "running"} class:error={status.state === "error"}>
            {getStateIcon(status.state)} {getStateLabel(status.state)}
          </span>
        </div>

        {#if status.last_run}
          <div class="status-row">
            <span class="label">Последний запуск:</span>
            <span class="value">{formatDate(status.last_run)}</span>
          </div>
        {/if}
      </div>

      {#if status.last_error}
        <div class="error-box">
          <strong>❌ Последняя ошибка индексации:</strong>
          <p>{status.last_error}</p>
        </div>
      {/if}

      <button
        class="btn btn-primary"
        on:click={startIndexation}
        disabled={isStarting || status.state === "running"}
      >
        {#if status.state === "running"}
          ⚙️ Индексация уже идёт…
        {:else if isStarting}
          🔄 Запуск…
        {:else}
          ▶️ Запустить индексацию
        {/if}
      </button>
    </div>
  </div>

  <!-- Блок документов (заглушка) -->
  <div class="card docs-block">
    <div class="card-header">
      <h2 class="card-title">📄 Документы в библиотеке</h2>
    </div>
    <div class="card-content">
      <p class="hint">
        На этом этапе — заглушка. В следующих версиях тут появится список
        документов, фильтры, управление файлами и статистика индексации.
      </p>
      <div class="placeholder">
        <div class="placeholder-icon">📚</div>
        <p class="placeholder-text">Список документов будет доступен в следующей версии</p>
      </div>
    </div>
  </div>

  <!-- Task 7.3: Agent Profile Integration -->
  <div class="card profile-block">
    <div class="card-header">
      <h2 class="card-title">🤖 Активный профиль агента</h2>
    </div>
    <div class="card-content">
      {#if settings}
        <div class="profile-display">
          <div class="profile-icon">🎯</div>
          <div class="profile-info">
            <span class="profile-name">{settings.active_agent_profile}</span>
            <p class="profile-hint">
              Активный профиль определяет, как агент использует индексированные данные.
              В будущих версиях здесь будет возможность тонкой настройки профилей
              и их обучения на основе библиотеки знаний.
            </p>
          </div>
        </div>
      {:else}
        <p class="hint">Загрузка настроек профиля...</p>
      {/if}
    </div>
  </div>
</section>

<style>
  .library-panel {
    padding: 1.5rem;
    max-width: 900px;
    margin: 0 auto;
  }

  .header {
    margin-bottom: 2rem;
  }

  .title {
    font-size: 2rem;
    font-weight: 700;
    color: #1f2937;
    margin-bottom: 0.5rem;
  }

  .subtitle {
    font-size: 1rem;
    color: #6b7280;
  }

  .card {
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 0.5rem;
    margin-bottom: 1.5rem;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  }

  .card-header {
    padding: 1rem 1.5rem;
    border-bottom: 1px solid #e5e7eb;
  }

  .card-title {
    font-size: 1.25rem;
    font-weight: 600;
    color: #374151;
    margin: 0;
  }

  .card-content {
    padding: 1.5rem;
  }

  .hint {
    font-size: 0.875rem;
    color: #6b7280;
    margin-bottom: 1.5rem;
    line-height: 1.5;
  }

  .hint code {
    background: #f3f4f6;
    padding: 0.125rem 0.375rem;
    border-radius: 0.25rem;
    font-family: monospace;
    font-size: 0.875rem;
  }

  .status-display {
    background: #f9fafb;
    border: 1px solid #e5e7eb;
    border-radius: 0.375rem;
    padding: 1rem;
    margin-bottom: 1.5rem;
  }

  .status-row {
    display: flex;
    align-items: center;
    margin-bottom: 0.75rem;
  }

  .status-row:last-child {
    margin-bottom: 0;
  }

  .label {
    font-weight: 500;
    color: #374151;
    margin-right: 0.75rem;
    min-width: 150px;
  }

  .value {
    color: #6b7280;
    font-family: monospace;
    font-size: 0.875rem;
  }

  .status-badge {
    display: inline-flex;
    align-items: center;
    padding: 0.25rem 0.75rem;
    border-radius: 0.375rem;
    font-size: 0.875rem;
    font-weight: 500;
    background: #e5e7eb;
    color: #374151;
  }

  .status-badge.running {
    background: #dbeafe;
    color: #1e40af;
  }

  .status-badge.error {
    background: #fee2e2;
    color: #991b1b;
  }

  .error-box {
    background: #fef2f2;
    border: 1px solid #fecaca;
    border-radius: 0.375rem;
    padding: 1rem;
    margin-bottom: 1.5rem;
  }

  .error-box strong {
    display: block;
    margin-bottom: 0.5rem;
    color: #991b1b;
  }

  .error-box p {
    color: #dc2626;
    margin: 0;
    font-size: 0.875rem;
  }

  .btn {
    padding: 0.625rem 1.25rem;
    border-radius: 0.375rem;
    font-weight: 500;
    font-size: 0.875rem;
    border: none;
    cursor: pointer;
    transition: all 0.2s;
  }

  .btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .btn-primary {
    background: #3b82f6;
    color: white;
  }

  .btn-primary:not(:disabled):hover {
    background: #2563eb;
  }

  .placeholder {
    text-align: center;
    padding: 3rem 1rem;
  }

  .placeholder-icon {
    font-size: 4rem;
    margin-bottom: 1rem;
    opacity: 0.3;
  }

  .placeholder-text {
    color: #9ca3af;
    font-size: 0.875rem;
  }

  /* Task 7.3: Agent Profile Styles */
  .profile-display {
    display: flex;
    align-items: flex-start;
    gap: 1rem;
    background: #f0f9ff;
    border: 1px solid #bae6fd;
    border-radius: 0.5rem;
    padding: 1.5rem;
  }

  .profile-icon {
    font-size: 2.5rem;
    flex-shrink: 0;
  }

  .profile-info {
    flex: 1;
  }

  .profile-name {
    display: block;
    font-size: 1.125rem;
    font-weight: 600;
    color: #0c4a6e;
    margin-bottom: 0.5rem;
  }

  .profile-hint {
    color: #0369a1;
    font-size: 0.875rem;
    line-height: 1.5;
    margin: 0;
  }
</style>
