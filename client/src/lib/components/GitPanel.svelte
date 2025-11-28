<script lang="ts">
  // WORLD_OLLAMA Desktop Client - Git Panel
  // TASK 17: Git Safety (Phase 1 - Plan Mode UI)
  // 
  // Этот компонент отображает результаты анализа Git Push Plan
  // и предоставляет интерфейс для безопасного push.
  // 
  // ТРИЗ Principle №10: Предварительное действие
  // "Показывай пользователю ЧТО будет запушено, ПЕРЕД push"

  import { invoke } from '@tauri-apps/api/tauri';
  import { onMount } from 'svelte';

  // ══════════════════════════════════════════════════════════════════════
  // ИНТЕРФЕЙСЫ (соответствуют GitPushPlan из Rust)
  // ══════════════════════════════════════════════════════════════════════

  interface GitPushPlan {
    status: 'ready' | 'blocked' | 'clean';
    remote: string;
    branch: string;
    current_branch: string;
    commits: string[];           // ["sha: message", ...]
    files_changed: string[];     // ["M src/main.rs", ...]
    blocked_reasons: string[];   // ["Unstaged changes", ...]
  }

  interface GitPushResult {
    success: boolean;
    message: string;
  }

  interface ApiResponse<T> {
    ok: boolean;
    data?: T;
    error?: {
      type: string;
      message: string;
    };
  }

  // ══════════════════════════════════════════════════════════════════════
  // STATE
  // ══════════════════════════════════════════════════════════════════════

  let plan: GitPushPlan | null = null;
  let loading = false;
  let errorMessage = '';
  let successMessage = '';  // Сообщение об успехе
  let executing = false;    // Состояние выполнения push

  // Настройки (пока hardcoded, позже из Settings)
  let remote = 'origin';
  let branch = 'main';

  // ══════════════════════════════════════════════════════════════════════
  // ФУНКЦИИ
  // ══════════════════════════════════════════════════════════════════════

  /**
   * Получить план push (вызов Tauri команды)
   */
  async function fetchPlan() {
    loading = true;
    errorMessage = '';
    plan = null;

    try {
      const response = await invoke<ApiResponse<GitPushPlan>>('plan_git_push', {
        remote,
        branch,
      });

      if (response.ok && response.data) {
        plan = response.data;
      } else if (response.error) {
        errorMessage = `${response.error.type}: ${response.error.message}`;
      }
    } catch (err) {
      errorMessage = `Failed to fetch plan: ${err}`;
    } finally {
      loading = false;
    }
  }

  /**
   * Выполнить push (TASK 17.2 - реализация)
   */
  async function executePush() {
    if (!plan || plan.status !== 'ready') {
      errorMessage = 'Cannot execute push: repository not ready';
      return;
    }

    executing = true;
    errorMessage = '';
    successMessage = '';

    try {
      const response = await invoke<ApiResponse<GitPushResult>>('execute_git_push', {
        remote,
        branch,
      });

      if (response.ok && response.data) {
        const result = response.data;

        if (result.success) {
          // Успех: показываем сообщение и обновляем план
          successMessage = result.message || 'Push completed successfully';
          
          // Автоматически обновить план (после push должен быть clean)
          setTimeout(() => {
            fetchPlan();
          }, 1000);
        } else {
          // Push вернул ошибку (из Git stderr)
          errorMessage = `Push failed: ${result.message}`;
        }
      } else if (response.error) {
        errorMessage = `${response.error.type}: ${response.error.message}`;
      }
    } catch (err) {
      errorMessage = `Failed to execute push: ${err}`;
    } finally {
      executing = false;
    }
  }

  /**
   * Обновить план (refresh)
   */
  function refreshPlan() {
    fetchPlan();
  }

  // ══════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════════════════

  onMount(() => {
    // Автоматически получить план при загрузке
    fetchPlan();
  });

  // ══════════════════════════════════════════════════════════════════════
  // COMPUTED (REACTIVE)
  // ══════════════════════════════════════════════════════════════════════

  $: statusBadgeClass = plan
    ? plan.status === 'ready'
      ? 'badge-success'
      : plan.status === 'blocked'
      ? 'badge-error'
      : 'badge-info'
    : '';

  $: statusText = plan
    ? plan.status === 'ready'
      ? 'ГОТОВ К PUSH'
      : plan.status === 'blocked'
      ? 'ЗАБЛОКИРОВАН'
      : 'НЕЧЕГО ПУШИТЬ'
    : '';

  $: canExecutePush = plan && plan.status === 'ready';
</script>

<div class="git-panel">
  <!-- ════════════════════════════════════════════════════════════════ -->
  <!-- HEADER -->
  <!-- ════════════════════════════════════════════════════════════════ -->
  <div class="panel-header">
    <h2>Git Push Safety</h2>
    <button
      class="btn btn-sm btn-ghost"
      on:click={refreshPlan}
      disabled={loading}
    >
      {loading ? '⟳ Загрузка...' : '🔄 Обновить'}
    </button>
  </div>

  <!-- ════════════════════════════════════════════════════════════════ -->
  <!-- ERROR MESSAGE -->
  <!-- ════════════════════════════════════════════════════════════════ -->
  {#if errorMessage}
    <div class="alert alert-error">
      <span>❌ {errorMessage}</span>
    </div>
  {/if}

  <!-- ════════════════════════════════════════════════════════════════ -->
  <!-- SUCCESS MESSAGE -->
  <!-- ════════════════════════════════════════════════════════════════ -->
  {#if successMessage}
    <div class="alert alert-success">
      <span>✅ {successMessage}</span>
    </div>
  {/if}

  <!-- ════════════════════════════════════════════════════════════════ -->
  <!-- LOADING STATE -->
  <!-- ════════════════════════════════════════════════════════════════ -->
  {#if loading}
    <div class="loading-container">
      <span class="loading loading-spinner loading-lg"></span>
      <p>Анализ репозитория...</p>
    </div>
  {/if}

  <!-- ════════════════════════════════════════════════════════════════ -->
  <!-- PLAN DISPLAY (when loaded) -->
  <!-- ════════════════════════════════════════════════════════════════ -->
  {#if plan && !loading}
    <div class="plan-content">
      <!-- STATUS BADGE -->
      <div class="status-section">
        <span class="badge {statusBadgeClass} badge-lg">
          {statusText}
        </span>
      </div>

      <!-- REPOSITORY INFO -->
      <div class="info-section">
        <div class="info-row">
          <span class="label">Remote:</span>
          <span class="value">{plan.remote}</span>
        </div>
        <div class="info-row">
          <span class="label">Ветка:</span>
          <span class="value">{plan.current_branch} → {plan.branch}</span>
        </div>
      </div>

      <!-- COMMITS TO PUSH -->
      {#if plan.commits.length > 0}
        <div class="commits-section">
          <h3>Коммиты для push ({plan.commits.length})</h3>
          <ul class="commits-list">
            {#each plan.commits as commit}
              <li>{commit}</li>
            {/each}
          </ul>
        </div>
      {/if}

      <!-- CHANGED FILES -->
      {#if plan.files_changed.length > 0}
        <div class="files-section">
          <h3>Изменённые файлы ({plan.files_changed.length})</h3>
          <ul class="files-list">
            {#each plan.files_changed as file}
              <li>{file}</li>
            {/each}
          </ul>
        </div>
      {/if}

      <!-- BLOCKED REASONS -->
      {#if plan.blocked_reasons.length > 0}
        <div class="blocked-section">
          <h3>⚠️ Причины блокировки</h3>
          <ul class="blocked-list">
            {#each plan.blocked_reasons as reason}
              <li class="blocked-item">{reason}</li>
            {/each}
          </ul>
        </div>
      {/if}

      <!-- ACTION BUTTONS -->
      <div class="actions-section">
        <button
          class="btn btn-primary btn-lg"
          on:click={executePush}
          disabled={!canExecutePush || executing}
        >
          {#if executing}
            <span class="loading loading-spinner loading-sm"></span>
            Выполняется push...
          {:else if canExecutePush}
            🚀 Выполнить Push
          {:else}
            🔒 Push заблокирован
          {/if}
        </button>

        {#if plan.status === 'clean'}
          <p class="clean-message">
            ✅ Все изменения уже запушены. Нечего отправлять.
          </p>
        {/if}
      </div>
    </div>
  {/if}
</div>

<style>
  .git-panel {
    padding: 1rem;
    max-width: 800px;
    margin: 0 auto;
  }

  .panel-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1rem;
  }

  .panel-header h2 {
    font-size: 1.5rem;
    font-weight: bold;
  }

  .loading-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 2rem;
  }

  .loading-container p {
    margin-top: 1rem;
    color: #666;
  }

  .plan-content {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .status-section {
    display: flex;
    justify-content: center;
    padding: 1rem 0;
  }

  .info-section {
    background-color: #f5f5f5;
    padding: 1rem;
    border-radius: 8px;
  }

  .info-row {
    display: flex;
    justify-content: space-between;
    padding: 0.5rem 0;
    border-bottom: 1px solid #e0e0e0;
  }

  .info-row:last-child {
    border-bottom: none;
  }

  .info-row .label {
    font-weight: bold;
    color: #555;
  }

  .info-row .value {
    font-family: 'Courier New', monospace;
    color: #333;
  }

  .commits-section,
  .files-section,
  .blocked-section {
    background-color: #fff;
    border: 1px solid #ddd;
    border-radius: 8px;
    padding: 1rem;
  }

  .commits-section h3,
  .files-section h3,
  .blocked-section h3 {
    font-size: 1.1rem;
    font-weight: bold;
    margin-bottom: 0.5rem;
  }

  .commits-list,
  .files-list,
  .blocked-list {
    list-style: none;
    padding: 0;
    margin: 0;
  }

  .commits-list li,
  .files-list li {
    font-family: 'Courier New', monospace;
    font-size: 0.9rem;
    padding: 0.3rem 0;
    border-bottom: 1px solid #f0f0f0;
  }

  .commits-list li:last-child,
  .files-list li:last-child {
    border-bottom: none;
  }

  .blocked-list .blocked-item {
    background-color: #ffe6e6;
    color: #c00;
    padding: 0.5rem;
    margin-bottom: 0.5rem;
    border-radius: 4px;
    border-left: 4px solid #c00;
  }

  .actions-section {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
    padding-top: 1rem;
  }

  .clean-message {
    color: #28a745;
    font-weight: bold;
    text-align: center;
  }

  .badge-success {
    background-color: #28a745;
    color: white;
  }

  .badge-error {
    background-color: #dc3545;
    color: white;
  }

  .badge-info {
    background-color: #17a2b8;
    color: white;
  }

  .alert {
    padding: 1rem;
    border-radius: 8px;
    margin-bottom: 1rem;
  }

  .alert-error {
    background-color: #f8d7da;
    color: #721c24;
    border: 1px solid #f5c6cb;
  }

  .alert-success {
    background-color: #d4edda;
    color: #155724;
    border: 1px solid #c3e6cb;
  }
</style>
