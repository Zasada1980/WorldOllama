<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import { apiClient } from "$lib/api/client";
  import { notifications } from "$lib/stores/notifications";
  import { commandSlotStore } from "$lib/stores/commandSlotStore";

  // ========================================
  // State (реактивная подписка на store)
  // ========================================

  let commandText = "";
  let description: string | null = null;
  let isExecuting = false;

  // Подписка на store (Chat может менять commandText/description)
  commandSlotStore.subscribe((state) => {
    commandText = state.commandText;
    description = state.description;
  });
  let lastResult: {
    success: boolean;
    message: string;
    command_type: string;
  } | null = null;

  // Preset Templates (для быстрой вставки)
  const templates = {
    index: `INDEX KNOWLEDGE
PATH="E:\\WORLD_OLLAMA\\library\\raw_documents"
MODE="local"
PROFILE="triz_engineer"`,
    train: `TRAIN AGENT
PROFILE="triz_engineer"
DATA_PATH="E:\\WORLD_OLLAMA\\training_data"
EPOCHS="5"
MODE="llama_factory"`,
    git: `GIT PUSH
REPO_PATH="E:\\WORLD_OLLAMA"
BRANCH="main"
SUMMARY="Auto-commit from desktop client"`,
  };

  // ========================================
  // Functions
  // ========================================

  function clearCommand() {
    commandSlotStore.clear();
    lastResult = null;
  }

  function loadTemplate(templateKey: keyof typeof templates) {
    commandSlotStore.setCommand(templates[templateKey]);
    lastResult = null; // Сбрасываем результат при смене шаблона
  }

  async function executeCommand() {
    if (!commandText.trim()) {
      notifications.push({
        type: "error",
        message: "Команда пуста",
        details: "Введите команду или выберите шаблон",
      });
      return;
    }

    isExecuting = true;
    lastResult = null;

    try {
      const response = await apiClient.executeAgentCommand(commandText);

      if (response && response.success) {
        lastResult = response;
        notifications.push({
          type: "success",
          message: `Команда ${response.command_type} выполнена`,
          details: response.message,
        });
      } else {
        const errorMsg = response?.message || "Неизвестная ошибка";
        notifications.push({
          type: "error",
          message: `Ошибка выполнения команды`,
          details: errorMsg,
        });
        lastResult = {
          success: false,
          message: errorMsg,
          command_type: "UNKNOWN",
        };
      }
    } catch (error) {
      const errorMsg =
        error instanceof Error ? error.message : String(error);
      notifications.push({
        type: "error",
        message: "Ошибка подключения",
        details: errorMsg,
      });
      lastResult = {
        success: false,
        message: errorMsg,
        command_type: "ERROR",
      };
    } finally {
      isExecuting = false;
    }
  }

  // ========================================
  // Lifecycle
  // ========================================

  onMount(() => {
    console.log("[CommandSlot] Mounted");
  });

  onDestroy(() => {
    console.log("[CommandSlot] Destroyed");
  });
</script>

<!-- ========================================
     Markup
     ======================================== -->

<section class="command-slot">
  <!-- Header -->
  <div class="header">
    <h2>🔧 Командный Слот</h2>
    <p class="subtitle">Формальный DSL для управления агентом</p>
  </div>

  <!-- Templates Quick Access -->
  <div class="templates">
    <span class="label">Шаблоны:</span>
    <button class="template-btn" on:click={() => loadTemplate("index")}>
      📚 INDEX
    </button>
    <button class="template-btn" on:click={() => loadTemplate("train")}>
      🧠 TRAIN
    </button>
    <button class="template-btn" on:click={() => loadTemplate("git")}>
      🌿 GIT
    </button>
  </div>

  <!-- Command Editor -->
  <div class="editor-block card">
    <label for="command-text">Команда (DSL формат):</label>
    <textarea
      id="command-text"
      bind:value={commandText}
      placeholder={`INDEX KNOWLEDGE\nPATH="..."\nMODE="local"`}
      rows="10"
    />

    <label for="description">Описание (человеко-читаемое):</label>
    <input
      id="description"
      type="text"
      bind:value={description}
      placeholder="Краткое описание задачи"
    />
  </div>

  <!-- Action Buttons -->
  <div class="actions">
    <button class="btn btn-secondary" on:click={clearCommand}>
      🗑️ Очистить
    </button>
    <button
      class="btn btn-primary"
      on:click={executeCommand}
      disabled={isExecuting || !commandText.trim()}
    >
      {#if isExecuting}
        ⏳ Выполняется...
      {:else}
        ▶️ Запустить команду
      {/if}
    </button>
  </div>

  <!-- Last Result Display -->
  {#if lastResult}
    <div class="result-block card" class:success={lastResult.success} class:error={!lastResult.success}>
      <div class="result-header">
        <span class="type-badge">{lastResult.command_type}</span>
        <span class="status-icon">
          {#if lastResult.success}
            ✅
          {:else}
            ❌
          {/if}
        </span>
      </div>
      <pre class="result-message">{lastResult.message}</pre>
    </div>
  {/if}

  <!-- Help Block -->
  <details class="help-block card">
    <summary>❓ Справка по DSL</summary>
    <div class="help-content">
      <h3>INDEX KNOWLEDGE</h3>
      <code>
        INDEX KNOWLEDGE<br />
        PATH="&lt;путь к папке&gt;"<br />
        MODE="local|global|hybrid|naive"<br />
        PROFILE="&lt;имя профиля&gt;"
      </code>

      <h3>TRAIN AGENT (STUB)</h3>
      <code>
        TRAIN AGENT<br />
        PROFILE="&lt;имя профиля&gt;"<br />
        DATA_PATH="&lt;путь к данным&gt;"<br />
        EPOCHS="&lt;число&gt;"<br />
        MODE="llama_factory"
      </code>

      <h3>GIT PUSH (STUB)</h3>
      <code>
        GIT PUSH<br />
        REPO_PATH="E:\\WORLD_OLLAMA"<br />
        BRANCH="main"<br />
        SUMMARY="&lt;описание&gt;"
      </code>

      <p class="note">
        ⚠️ <strong>Важно:</strong> Все значения должны быть в двойных кавычках.
        TRAIN и GIT — заглушки (безопасность).
      </p>
    </div>
  </details>
</section>

<!-- ========================================
     Styles
     ======================================== -->

<style>
  .command-slot {
    padding: 1.5rem;
    max-width: 900px;
    margin: 0 auto;
  }

  .header {
    margin-bottom: 1.5rem;
  }

  .header h2 {
    margin: 0 0 0.5rem 0;
    color: var(--color-text);
    font-size: 1.8rem;
  }

  .subtitle {
    margin: 0;
    color: var(--color-text-dim);
    font-size: 0.95rem;
  }

  /* Templates Quick Access */
  .templates {
    display: flex;
    gap: 0.75rem;
    align-items: center;
    margin-bottom: 1.5rem;
  }

  .templates .label {
    font-weight: 600;
    color: var(--color-text-dim);
  }

  .template-btn {
    padding: 0.4rem 0.8rem;
    background: var(--color-bg-secondary);
    border: 1px solid var(--color-border);
    border-radius: 6px;
    cursor: pointer;
    font-size: 0.9rem;
    transition: all 0.2s;
  }

  .template-btn:hover {
    background: var(--color-primary);
    color: white;
    border-color: var(--color-primary);
  }

  /* Editor Block */
  .editor-block {
    margin-bottom: 1.5rem;
  }

  .editor-block label {
    display: block;
    font-weight: 600;
    margin-bottom: 0.5rem;
    color: var(--color-text);
  }

  .editor-block textarea {
    width: 100%;
    padding: 0.75rem;
    background: var(--color-bg);
    border: 2px solid var(--color-border);
    border-radius: 8px;
    font-family: "Consolas", "Monaco", monospace;
    font-size: 0.95rem;
    color: var(--color-text);
    resize: vertical;
    margin-bottom: 1rem;
  }

  .editor-block textarea:focus {
    outline: none;
    border-color: var(--color-primary);
  }

  .editor-block input {
    width: 100%;
    padding: 0.6rem;
    background: var(--color-bg);
    border: 2px solid var(--color-border);
    border-radius: 6px;
    font-size: 0.95rem;
    color: var(--color-text);
  }

  .editor-block input:focus {
    outline: none;
    border-color: var(--color-primary);
  }

  /* Actions */
  .actions {
    display: flex;
    gap: 1rem;
    margin-bottom: 1.5rem;
  }

  .btn {
    flex: 1;
    padding: 0.75rem 1.5rem;
    border: none;
    border-radius: 8px;
    font-size: 1rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
  }

  .btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .btn-primary {
    background: var(--color-primary);
    color: white;
  }

  .btn-primary:hover:not(:disabled) {
    background: var(--color-primary-dark);
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(0, 123, 255, 0.3);
  }

  .btn-secondary {
    background: var(--color-bg-secondary);
    color: var(--color-text);
    border: 1px solid var(--color-border);
  }

  .btn-secondary:hover {
    background: var(--color-bg-hover);
  }

  /* Result Block */
  .result-block {
    margin-bottom: 1.5rem;
    padding: 1.5rem;
    border-left: 4px solid transparent;
  }

  .result-block.success {
    border-left-color: #28a745;
    background: rgba(40, 167, 69, 0.1);
  }

  .result-block.error {
    border-left-color: #dc3545;
    background: rgba(220, 53, 69, 0.1);
  }

  .result-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1rem;
  }

  .type-badge {
    display: inline-block;
    padding: 0.3rem 0.7rem;
    background: var(--color-bg-secondary);
    border-radius: 4px;
    font-family: "Consolas", monospace;
    font-size: 0.85rem;
    font-weight: 600;
    color: var(--color-text);
  }

  .status-icon {
    font-size: 1.5rem;
  }

  .result-message {
    margin: 0;
    padding: 1rem;
    background: var(--color-bg);
    border-radius: 6px;
    font-family: "Consolas", monospace;
    font-size: 0.9rem;
    white-space: pre-wrap;
    word-wrap: break-word;
    color: var(--color-text);
  }

  /* Help Block */
  .help-block {
    cursor: pointer;
  }

  .help-block summary {
    font-weight: 600;
    color: var(--color-text);
    padding: 1rem;
    user-select: none;
  }

  .help-content {
    padding: 1rem;
    border-top: 1px solid var(--color-border);
  }

  .help-content h3 {
    margin: 1.5rem 0 0.5rem 0;
    color: var(--color-primary);
    font-size: 1.1rem;
  }

  .help-content h3:first-child {
    margin-top: 0;
  }

  .help-content code {
    display: block;
    padding: 0.75rem;
    background: var(--color-bg);
    border-radius: 6px;
    font-family: "Consolas", monospace;
    font-size: 0.9rem;
    color: var(--color-text);
    margin-bottom: 1rem;
  }

  .help-content .note {
    margin-top: 1rem;
    padding: 0.75rem;
    background: rgba(255, 193, 7, 0.1);
    border-left: 3px solid #ffc107;
    border-radius: 4px;
    font-size: 0.9rem;
  }

  /* Responsive */
  @media (max-width: 768px) {
    .command-slot {
      padding: 1rem;
    }

    .actions {
      flex-direction: column;
    }

    .btn {
      width: 100%;
    }

    .templates {
      flex-wrap: wrap;
    }
  }
</style>
