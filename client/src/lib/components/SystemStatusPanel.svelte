<script lang="ts">
  import { apiClient } from '$lib/api/client';
  import { onMount, onDestroy } from 'svelte';

  type ServiceStatus = 'unknown' | 'checking' | 'up' | 'down';

  interface ServiceInfo {
    status: ServiceStatus;
    details?: string;
  }

  let ollama: ServiceInfo = { status: 'unknown' };
  let cortex: ServiceInfo = { status: 'unknown' };
  let lastCheck: string | null = null;
  let isChecking = false;
  let intervalId: number | null = null;

  async function refreshStatus() {
    isChecking = true;

    ollama = { status: 'checking' };
    cortex = { status: 'checking' };

    // Task 6.5: Используем apiClient (silent = true, без уведомлений)
    const res = await apiClient.getSystemStatus();

    if (!res) {
      // Если apiClient вернул null, значит ошибка (уже показали уведомление)
      ollama = { status: 'down', details: 'Нет ответа' };
      cortex = { status: 'down', details: 'Нет ответа' };
    } else {
      ollama = {
        status: res.ollama.available ? 'up' : 'down',
        details: res.ollama.available 
          ? `Модели: ${res.ollama.models.join(', ')}` 
          : 'Недоступен'
      };
      cortex = {
        status: res.cortex.available ? 'up' : 'down',
        details: res.cortex.available ? 'Работает' : 'Недоступен'
      };
      lastCheck = new Date().toLocaleTimeString();
    }

    isChecking = false;
  }

  onMount(() => {
    refreshStatus();
    intervalId = window.setInterval(refreshStatus, 15000); // каждые 15 сек
  });

  onDestroy(() => {
    if (intervalId !== null) clearInterval(intervalId);
  });
</script>

<style>
  .container {
    max-width: 1000px;
    margin: 0 auto;
    padding: 30px 20px;
  }

  h1 {
    color: #4CAF50;
    margin-bottom: 10px;
    font-size: 2em;
  }

  .subtitle {
    color: #888;
    margin-bottom: 30px;
    font-size: 0.95em;
  }

  .status-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 20px;
    margin-bottom: 30px;
  }

  .status-card {
    background: #2a2a2a;
    border-radius: 12px;
    padding: 25px;
    border-left: 4px solid #2196F3;
    transition: transform 0.2s, box-shadow 0.2s;
  }

  .status-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0,0,0,0.3);
  }

  .status-card h2 {
    color: #2196F3;
    margin-bottom: 15px;
    font-size: 1.4em;
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .badge {
    display: inline-block;
    padding: 8px 16px;
    border-radius: 20px;
    font-weight: bold;
    font-size: 0.95em;
    margin-bottom: 10px;
  }

  .badge-up {
    background: #4CAF50;
    color: white;
  }

  .badge-down {
    background: #f44336;
    color: white;
  }

  .badge-checking {
    background: #FF9800;
    color: #000;
    animation: pulse 1.5s infinite;
  }

  .badge-unknown {
    background: #666;
    color: white;
  }

  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.6; }
  }

  .details {
    color: #aaa;
    font-size: 0.9em;
    margin-top: 10px;
    padding: 10px;
    background: #1a1a1a;
    border-radius: 6px;
    border-left: 3px solid #555;
  }

  .status-controls {
    display: flex;
    align-items: center;
    gap: 20px;
    margin-bottom: 30px;
    padding: 20px;
    background: #2a2a2a;
    border-radius: 8px;
  }

  button {
    background: #4CAF50;
    color: white;
    border: none;
    padding: 12px 24px;
    border-radius: 6px;
    cursor: pointer;
    font-size: 1em;
    font-weight: bold;
    transition: background 0.2s;
  }

  button:hover:not(:disabled) {
    background: #45a049;
  }

  button:disabled {
    background: #555;
    cursor: not-allowed;
    opacity: 0.7;
  }

  .last-check {
    color: #888;
    font-size: 0.9em;
  }

  .error-box {
    background: #f443364d;
    border: 2px solid #f44336;
    border-radius: 8px;
    padding: 15px 20px;
    margin-bottom: 20px;
    color: #ffcccc;
    font-weight: 500;
  }

  .help {
    background: #2a2a2a;
    border-radius: 8px;
    padding: 25px;
    border-left: 4px solid #FF9800;
  }

  .help h3 {
    color: #FF9800;
    margin-bottom: 15px;
    font-size: 1.2em;
  }

  .help ul {
    list-style: none;
    padding: 0;
    margin: 0;
  }

  .help li {
    padding: 10px 0;
    border-bottom: 1px solid #333;
    color: #ccc;
    line-height: 1.6;
  }

  .help li:last-child {
    border-bottom: none;
  }

  .help strong {
    color: #fff;
  }

  .help code {
    background: #1a1a1a;
    padding: 2px 8px;
    border-radius: 4px;
    font-family: 'Consolas', monospace;
    color: #4CAF50;
  }

  .auto-refresh-notice {
    display: flex;
    align-items: center;
    gap: 8px;
    color: #888;
    font-size: 0.85em;
    padding: 8px 12px;
    background: #1a1a1a;
    border-radius: 6px;
    margin-left: auto;
  }

  .version-info {
    text-align: center;
    margin-top: 30px;
    padding: 15px;
    border-top: 1px solid #333;
  }

  .version-badge {
    display: inline-block;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 8px 16px;
    border-radius: 20px;
    font-size: 0.85em;
    font-weight: bold;
    letter-spacing: 0.5px;
  }

  .auto-refresh-notice .dot {
    width: 8px;
    height: 8px;
    background: #4CAF50;
    border-radius: 50%;
    animation: blink 2s infinite;
  }

  @keyframes blink {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.3; }
  }
</style>

<div class="container">
  <h1>📡 System Status</h1>
  <p class="subtitle">
    Мониторинг состояния сервисов AI-системы
  </p>

  <section class="status-grid">
    <!-- Ollama Status Card -->
    <div class="status-card">
      <h2>🤖 Ollama</h2>
      {#if ollama.status === 'up'}
        <span class="badge badge-up">🟢 Работает</span>
      {:else if ollama.status === 'down'}
        <span class="badge badge-down">🔴 Не работает</span>
      {:else if ollama.status === 'checking'}
        <span class="badge badge-checking">🟡 Проверка...</span>
      {:else}
        <span class="badge badge-unknown">⚪ Неизвестно</span>
      {/if}
      
      {#if ollama.details}
        <p class="details">{ollama.details}</p>
      {/if}
    </div>

    <!-- CORTEX Status Card -->
    <div class="status-card">
      <h2>🧠 CORTEX</h2>
      {#if cortex.status === 'up'}
        <span class="badge badge-up">🟢 Работает</span>
      {:else if cortex.status === 'down'}
        <span class="badge badge-down">🔴 Не работает</span>
      {:else if cortex.status === 'checking'}
        <span class="badge badge-checking">🟡 Проверка...</span>
      {:else}
        <span class="badge badge-unknown">⚪ Неизвестно</span>
      {/if}
      
      {#if cortex.details}
        <p class="details">{cortex.details}</p>
      {/if}
    </div>
  </section>

  <div class="status-controls">
    <button on:click={refreshStatus} disabled={isChecking}>
      {#if isChecking}
        🔄 Проверка...
      {:else}
        🔄 Обновить статус
      {/if}
    </button>

    {#if lastCheck}
      <span class="last-check">Последняя проверка: {lastCheck}</span>
    {/if}

    <div class="auto-refresh-notice">
      <span class="dot"></span>
      <span>Автообновление каждые 15 сек</span>
    </div>
  </div>

  <section class="help">
    <h3>💡 Если что-то не работает</h3>
    <ul>
      <li>
        <strong>Ollama 🔴</strong> — проверь, запущен ли Ollama и загружена ли нужная модель (<code>qwen2.5:14b</code>).
        <br>Команда проверки: <code>ollama list</code>
      </li>
      <li>
        <strong>CORTEX 🔴</strong> — проверь запуск скриптов <code>START_ALL.ps1</code> и статус CORTEX.
        <br>Команда проверки: <code>pwsh scripts\CHECK_STATUS.ps1</code>
      </li>
      <li>
        <strong>Оба сервиса 🔴</strong> — перезапусти систему оркестрации:
        <br><code>pwsh scripts\STOP_ALL.ps1</code> → <code>pwsh scripts\START_ALL.ps1</code>
      </li>
      <li>
        Если проблемы сохраняются — проверь логи сервисов в <code>services/lightrag/logs/cortex.log</code>
      </li>
    </ul>
  </section>

  <footer class="version-info">
    <span class="version-badge">WORLD_OLLAMA v0.1.0 (Developer Preview)</span>
  </footer>
</div>
