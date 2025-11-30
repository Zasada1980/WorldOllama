<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import { apiClient } from "$lib/api/client";
  import {
    displayPreferences,
    type WindowSizePreset,
    type Theme,
    type Background,
  } from "$lib/stores/displayPreferences";
  import { applyWindowSize, applyTheme } from "$lib/utils/applyDisplayPreferences";

  // ============================================================================
  // Task 5.4: SettingsPanel - Интерфейс настроек приложения
  // ============================================================================

  interface AppSettings {
    ollama_model: string;
    max_tokens: number | null;
    cortex_top_k: number;
    cortex_mode: string;
    active_agent_profile: string;
  }

  // Состояние компонента
  let settings: AppSettings = {
    ollama_model: "qwen2.5:14b-instruct-q4_k_m",
    max_tokens: null,
    cortex_top_k: 20,
    cortex_mode: "local",
    active_agent_profile: "triz_engineer",
  };

  let isLoading = true;
  let isSaving = false;

  // Доступные модели Ollama (из тестов проекта)
  const availableModels = [
    "qwen2.5:14b-instruct-q4_k_m",
    "qwen2.5:3b-instruct",
    "triz-td010v2:latest",
    "llama3.1:8b",
    "librarian-lite",
  ];

  // Профили агента
  const agentProfiles = [
    {
      id: "triz_engineer",
      name: "🔧 ТРИЗ-инженер",
      description: "Решение изобретательских задач",
    },
    {
      id: "doc_organizer",
      name: "📚 Документалист",
      description: "Организация знаний",
    },
    {
      id: "code_assistant",
      name: "💻 Code Assistant",
      description: "Помощь в программировании",
    },
  ];

  // ============================================================================
  // Task 6.5: Загрузка настроек через apiClient
  // ============================================================================
  onMount(async () => {
    const response = await apiClient.getAppSettings();

    if (response) {
      // Мержим полученные данные с дефолтными (apiClient возвращает не все поля)
      settings = {
        ...settings,
        ...response,
      };
      console.log("✅ Настройки загружены:", settings);
    }

    isLoading = false;
  });

  // ============================================================================
  // Task 6.5: Сохранение настроек через apiClient (показывает success toast)
  // ============================================================================
  async function saveSettings() {
    isSaving = true;

    const success = await apiClient.saveAppSettings(settings);

    if (success) {
      console.log("✅ Настройки сохранены:", settings);
      // TODO: Показать toast success
    } else {
      console.error("❌ Ошибка сохранения настроек");
      // TODO: Показать toast error
    }

    isSaving = false;
  }

  // ============================================================================
  // Order 34: Display Preferences управление
  // ============================================================================
  // Используем $-синтаксис для автоподписки (Fix #1: убрана двойная подписка)
  $: displayPrefs = $displayPreferences;

  async function updateWindowSize(size: WindowSizePreset) {
    displayPreferences.update((p) => ({ ...p, windowSize: size }));
    // Fix #2: Применяем изменения сразу через Tauri API
    await applyWindowSize(size);
    console.log('[SettingsPanel] Window size applied:', size);
  }

  async function updateTheme(theme: Theme) {
    displayPreferences.update((p) => ({ ...p, theme }));
    // Fix #2: Применяем изменения сразу
    applyTheme(theme);
    console.log('[SettingsPanel] Theme applied:', theme);
  }

  function updateBackground(bg: Background) {
    displayPreferences.update((p) => ({ ...p, background: bg }));
    // Background применяется через CSS класс в +page.svelte (реактивно)
    console.log('[SettingsPanel] Background updated:', bg);
  }
</script>

<div class="settings-panel">
  <h1>⚙️ Настройки</h1>

  {#if isLoading}
    <div class="loading">
      <div class="spinner"></div>
      <p>Загрузка настроек...</p>
    </div>
  {:else}
    <div class="settings-content">
      <!-- ================================================================== -->
      <!-- Секция 1: Модель LLM (Ollama) -->
      <!-- ================================================================== -->
      <section class="settings-section">
        <h2>🤖 Модель LLM (Ollama)</h2>
        <div class="setting-item">
          <label for="ollama-model">Выберите модель:</label>
          <select id="ollama-model" bind:value={settings.ollama_model}>
            {#each availableModels as model}
              <option value={model}>{model}</option>
            {/each}
          </select>
          <p class="hint">
            Модель для генерации ответов через Ollama. Более крупные модели
            (14b) точнее, но медленнее.
          </p>
        </div>

        <div class="setting-item">
          <label for="max-tokens">Max Tokens (опционально):</label>
          <input
            id="max-tokens"
            type="number"
            min="100"
            max="4096"
            bind:value={settings.max_tokens}
            placeholder="Не ограничено"
          />
          <p class="hint">
            Максимальная длина ответа в токенах (оставьте пустым для
            автоматического выбора).
          </p>
        </div>
      </section>

      <!-- ================================================================== -->
      <!-- Секция 2: CORTEX (RAG) -->
      <!-- ================================================================== -->
      <section class="settings-section">
        <h2>🧠 CORTEX (RAG Knowledge Base)</h2>
        <div class="setting-item">
          <label for="cortex-top-k">Top-K документов:</label>
          <input
            id="cortex-top-k"
            type="number"
            min="5"
            max="50"
            bind:value={settings.cortex_top_k}
          />
          <p class="hint">
            Количество документов для поиска (5-50). Больше = точнее, но
            медленнее.
          </p>
        </div>

        <div class="setting-item">
          <label for="cortex-mode">Режим поиска:</label>
          <select id="cortex-mode" bind:value={settings.cortex_mode}>
            <option value="local">Local (локальный контекст)</option>
            <option value="hybrid">Hybrid (гибридный поиск)</option>
          </select>
          <p class="hint">
            Local — быстрый поиск по локальному контексту.<br />
            Hybrid — адаптивный поиск с комбинированием стратегий.
          </p>
        </div>
      </section>

      <!-- ================================================================== -->
      <!-- Секция 3: Профили агента -->
      <!-- ================================================================== -->
      <section class="settings-section">
        <h2>👤 Профиль агента</h2>
        <div class="profiles-grid">
          {#each agentProfiles as profile}
            <button
              class="profile-card"
              class:active={settings.active_agent_profile === profile.id}
              on:click={() => (settings.active_agent_profile = profile.id)}
            >
              <div class="profile-name">{profile.name}</div>
              <div class="profile-description">{profile.description}</div>
              {#if settings.active_agent_profile === profile.id}
                <div class="profile-badge">✓ Активен</div>
              {/if}
            </button>
          {/each}
        </div>
        <p class="hint">
          Профиль влияет на стиль ответов и приоритеты поиска в базе знаний.
        </p>
      </section>

      <!-- ================================================================== -->
      <!-- Секция 4: Отображение / Display -->
      <!-- ================================================================== -->
      <section class="settings-section">
        <h2>🖥️ Отображение</h2>
        
        <!-- Размер окна -->
        <div class="setting-item">
          <div class="label-text">Размер окна:</div>
          <div class="button-group">
            <button
              class="size-button"
              class:active={displayPrefs.windowSize === 'small'}
              on:click={() => updateWindowSize('small')}
            >
              Малое<br /><span class="size-hint">1024×720</span>
            </button>
            <button
              class="size-button"
              class:active={displayPrefs.windowSize === 'medium'}
              on:click={() => updateWindowSize('medium')}
            >
              Стандарт<br /><span class="size-hint">1280×800</span>
            </button>
            <button
              class="size-button"
              class:active={displayPrefs.windowSize === 'large'}
              on:click={() => updateWindowSize('large')}
            >
              Большое<br /><span class="size-hint">1600×900</span>
            </button>
            <button
              class="size-button"
              class:active={displayPrefs.windowSize === 'fullscreen'}
              on:click={() => updateWindowSize('fullscreen')}
            >
              Полный экран
            </button>
          </div>
          <p class="hint">Изменения применяются сразу. Будет использовано при следующем запуске.</p>
        </div>

        <!-- Тема -->
        <div class="setting-item">
          <label for="theme-select">Тема:</label>
          <select id="theme-select" bind:value={displayPrefs.theme} on:change={(e) => updateTheme((e.currentTarget as HTMLSelectElement).value as Theme)}>
            <option value="system">🔄 Системная</option>
            <option value="light">☀️ Светлая</option>
            <option value="dark">🌙 Тёмная</option>
          </select>
          <p class="hint">Системная тема соответствует настройкам вашей ОС.</p>
        </div>

        <!-- Фон -->
        <div class="setting-item">
          <label for="background-select">Фон:</label>
          <select id="background-select" bind:value={displayPrefs.background} on:change={(e) => updateBackground((e.currentTarget as HTMLSelectElement).value as Background)}>
            <option value="default">По умолчанию</option>
            <option value="solid">Сплошной</option>
            <option value="grid">Сетка</option>
            <option value="gradient">Градиент</option>
          </select>
          <p class="hint">Визуальное оформление фона приложения.</p>
        </div>
      </section>

      <!-- ================================================================== -->
      <!-- Кнопка сохранения и сообщения -->
      <!-- ================================================================== -->
      <div class="actions">
        <button class="save-button" on:click={saveSettings} disabled={isSaving}>
          {isSaving ? "Сохранение..." : "💾 Сохранить настройки"}
        </button>
      </div>
    </div>
  {/if}
</div>

<style>
  .settings-panel {
    padding: 2rem;
    max-width: 900px;
    margin: 0 auto;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen,
      Ubuntu, sans-serif;
  }

  h1 {
    font-size: 2rem;
    margin-bottom: 2rem;
    color: #2c3e50;
  }

  .loading {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 300px;
    gap: 1rem;
  }

  .spinner {
    width: 50px;
    height: 50px;
    border: 4px solid #e0e0e0;
    border-top: 4px solid #3498db;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    0% {
      transform: rotate(0deg);
    }
    100% {
      transform: rotate(360deg);
    }
  }

  .settings-content {
    display: flex;
    flex-direction: column;
    gap: 2rem;
  }

  .settings-section {
    background: #f8f9fa;
    border-radius: 8px;
    padding: 1.5rem;
    border-left: 4px solid #3498db;
  }

  .settings-section h2 {
    font-size: 1.5rem;
    margin-bottom: 1.5rem;
    color: #2c3e50;
  }

  .setting-item {
    margin-bottom: 1.5rem;
  }

  .setting-item:last-child {
    margin-bottom: 0;
  }

  label {
    display: block;
    font-weight: 600;
    margin-bottom: 0.5rem;
    color: #34495e;
  }

  .label-text {
    display: block;
    font-weight: 600;
    margin-bottom: 0.5rem;
    color: #34495e;
  }

  select,
  input[type="number"] {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 1rem;
    transition: border-color 0.2s;
  }

  select:focus,
  input[type="number"]:focus {
    outline: none;
    border-color: #3498db;
    box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.1);
  }

  .hint {
    margin-top: 0.5rem;
    font-size: 0.875rem;
    color: #7f8c8d;
    line-height: 1.4;
  }

  .profiles-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 1rem;
    margin-bottom: 1rem;
  }

  .profile-card {
    background: white;
    border: 2px solid #e0e0e0;
    border-radius: 8px;
    padding: 1.5rem;
    cursor: pointer;
    transition: all 0.2s;
    text-align: left;
    position: relative;
  }

  .profile-card:hover {
    border-color: #3498db;
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  }

  .profile-card.active {
    border-color: #27ae60;
    background: #f0fdf4;
  }

  .profile-name {
    font-size: 1.125rem;
    font-weight: 600;
    margin-bottom: 0.5rem;
    color: #2c3e50;
  }

  .profile-description {
    font-size: 0.875rem;
    color: #7f8c8d;
    line-height: 1.4;
  }

  .profile-badge {
    position: absolute;
    top: 0.5rem;
    right: 0.5rem;
    background: #27ae60;
    color: white;
    padding: 0.25rem 0.75rem;
    border-radius: 12px;
    font-size: 0.75rem;
    font-weight: 600;
  }

  .button-group {
    display: flex;
    gap: 0.75rem;
    flex-wrap: wrap;
  }

  .size-button {
    flex: 1;
    min-width: 120px;
    padding: 1rem;
    background: white;
    border: 2px solid #e0e0e0;
    border-radius: 6px;
    cursor: pointer;
    transition: all 0.2s;
    font-size: 0.875rem;
    font-weight: 500;
    text-align: center;
  }

  .size-button:hover {
    border-color: #3498db;
    transform: translateY(-2px);
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  }

  .size-button.active {
    border-color: #27ae60;
    background: #f0fdf4;
    font-weight: 600;
  }

  .size-hint {
    display: block;
    font-size: 0.75rem;
    color: #7f8c8d;
    margin-top: 0.25rem;
  }

  .actions {
    margin-top: 2rem;
    display: flex;
    justify-content: center;
  }

  .save-button {
    background: #3498db;
    color: white;
    border: none;
    border-radius: 6px;
    padding: 1rem 2rem;
    font-size: 1.125rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
  }

  .save-button:hover:not(:disabled) {
    background: #2980b9;
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(52, 152, 219, 0.3);
  }

  .save-button:disabled {
    background: #95a5a6;
    cursor: not-allowed;
    opacity: 0.7;
  }

  .message {
    margin-top: 1rem;
    padding: 1rem;
    border-radius: 6px;
    font-weight: 500;
    text-align: center;
  }

  .message.success {
    background: #d4edda;
    color: #155724;
    border: 1px solid #c3e6cb;
  }

  .message.error {
    background: #f8d7da;
    color: #721c24;
    border: 1px solid #f5c6cb;
  }
</style>
