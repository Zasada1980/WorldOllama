<script lang="ts">
  import { onMount } from 'svelte';
  import { apiClient, type AppSettings } from '$lib/api/client';
  import { commandSlotStore } from '$lib/stores/commandSlotStore';
  import { notifications } from '$lib/stores/notifications';
  import MessageBubble from './MessageBubble.svelte';

  // Task 3.2: Модель данных
  type Role = 'user' | 'assistant' | 'system';
  type Backend = 'ollama' | 'cortex';

  interface ChatMessage {
    id: string;
    role: Role;
    text: string;
    backend?: Backend;
    sources?: Array<{ id: string; title?: string; snippet?: string }>;
    error?: boolean;
  }

  interface OllamaResponse {
    response: string;
    model: string;
  }

  interface CortexResponse {
    answer: string;
    sources?: string[];
    metadata?: any;
  }

  // State
  let messages: ChatMessage[] = [];
  let inputText = '';
  let backend: Backend = 'ollama';
  let isSending = false;
  let messagesContainer: HTMLDivElement;
  let appSettings: AppSettings | null = null;

  // Task 6.4: Загрузка настроек через apiClient
  onMount(async () => {
    const settings = await apiClient.getAppSettings();
    if (settings) {
      appSettings = settings;
      console.log('✅ Настройки загружены в ChatPanel:', appSettings);
    }
  });

  // Task 3.3: Функция отправки сообщения
  async function sendMessage() {
    if (!inputText.trim() || isSending) return;

    const userText = inputText.trim();
    inputText = '';
    isSending = true;

    // Добавляем сообщение пользователя
    const userMessage: ChatMessage = {
      id: crypto.randomUUID(),
      role: 'user',
      text: userText,
      backend,
    };
    messages = [...messages, userMessage];
    scrollToBottom();

    try {
      if (backend === 'ollama') {
        // Task 6.4: Запрос к Ollama через apiClient
        const response = await apiClient.callApi<OllamaResponse>('send_ollama_chat', {
          prompt: userText,
          model: appSettings?.ollama_model || null,
        });

        if (response) {
          const assistantMessage: ChatMessage = {
            id: crypto.randomUUID(),
            role: 'assistant',
            text: response.response,
            backend: 'ollama',
          };
          messages = [...messages, assistantMessage];
        } else {
          // Ошибка от Ollama (уже показали уведомление в apiClient)
          const errorMessage: ChatMessage = {
            id: crypto.randomUUID(),
            role: 'system',
            text: `❌ Не удалось получить ответ от Ollama. Проверьте System Status.`,
            error: true,
          };
          messages = [...messages, errorMessage];
        }
      } else {
        // Task 6.4: Запрос к CORTEX через apiClient
        const response = await apiClient.callApi<CortexResponse>('send_cortex_query', {
          query: userText,
          topK: appSettings?.cortex_top_k || null,
          mode: appSettings?.cortex_mode || null,
        });

        if (response) {
          // Парсим источники
          const sources = response.sources?.map((src: string, idx: number) => ({
            id: src,
            title: `Источник ${idx + 1}`,
            snippet: src.substring(0, 100) + '...',
          }));

          const assistantMessage: ChatMessage = {
            id: crypto.randomUUID(),
            role: 'assistant',
            text: response.answer,
            backend: 'cortex',
            sources,
          };
          messages = [...messages, assistantMessage];
        } else {
          // Ошибка от CORTEX (уже показали уведомление)
          const errorMessage: ChatMessage = {
            id: crypto.randomUUID(),
            role: 'system',
            text: `❌ Не удалось получить ответ от CORTEX. Проверьте System Status.`,
            error: true,
          };
          messages = [...messages, errorMessage];
        }
      }
    } catch (error) {
      // Это не должно случиться (apiClient уже ловит всё), но на всякий случай
      const errorMessage: ChatMessage = {
        id: crypto.randomUUID(),
        role: 'system',
        text: `❌ Критическая ошибка: ${error}`,
        error: true,
      };
      messages = [...messages, errorMessage];
    } finally {
      isSending = false;
      scrollToBottom();
    }
  }

  function scrollToBottom() {
    setTimeout(() => {
      if (messagesContainer) {
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
      }
    }, 100);
  }

  // Task 8.5: Генерация команды из последнего сообщения пользователя
  function generateCommandFromLastUserMessage() {
    // Находим последнее сообщение пользователя
    const lastUserMessage = [...messages].reverse().find((m) => m.role === 'user');
    
    if (!lastUserMessage) {
      notifications.push({
        type: 'warning',
        message: 'Нет сообщений для анализа',
        details: 'Напишите хотя бы одно сообщение в чат',
        timeoutMs: 4000,
      });
      return;
    }

    const text = lastUserMessage.text.toLowerCase();
    const profile = appSettings?.active_agent_profile ?? 'triz_engineer';
    const cortexMode = appSettings?.cortex_mode ?? 'local';

    // Простой keyword-based mapping (MVP)
    
    // Вариант 1: INDEX KNOWLEDGE
    if (
      text.match(/индекс|index|папк|folder|директ|library|библиотек/i)
    ) {
      // Пытаемся извлечь путь из сообщения (простой regex)
      const pathMatch = text.match(/[a-z]:\\[^\s"]+|\/[^\s"]+/i);
      const path = pathMatch ? pathMatch[0] : 'E:\\WORLD_OLLAMA\\library\\raw_documents';

      const cmd = [
        'INDEX KNOWLEDGE',
        `PATH="${path}"`,
        `MODE="${cortexMode}"`,
        `PROFILE="${profile}"`,
      ].join('\n');

      commandSlotStore.setCommand(
        cmd,
        `Индексация папки ${path} под профилем ${profile}`
      );

      notifications.push({
        type: 'info',
        message: 'Команда INDEX сгенерирована',
        details: 'Проверьте вкладку 🔧 Commands',
        timeoutMs: 4000,
      });
      return;
    }

    // Вариант 2: TRAIN AGENT
    if (text.match(/обучи|обучить|train|fine-tune|дообуч|тренир/i)) {
      const cmd = [
        'TRAIN AGENT',
        `PROFILE="${profile}"`,
        `DATA_PATH="E:\\WORLD_OLLAMA\\training_data"`,
        'EPOCHS="5"',
        'MODE="llama_factory"',
      ].join('\n');

      commandSlotStore.setCommand(
        cmd,
        `Дообучение профиля ${profile} (MVP-заглушка)`
      );

      notifications.push({
        type: 'info',
        message: 'Команда TRAIN сгенерирована',
        details: 'Проверьте вкладку 🔧 Commands (пока заглушка)',
        timeoutMs: 4000,
      });
      return;
    }

    // Вариант 3: GIT (пока не реализуем, пользователь использует шаблон)
    // if (text.match(/git|коммит|commit|push/i)) { ... }

    // Не распознана
    notifications.push({
      type: 'warning',
      message: 'Не удалось распознать команду',
      details: 'Поддерживаются ключевые слова: индекс, обучить, train',
      timeoutMs: 5000,
    });
  }

  function handleKeyPress(event: KeyboardEvent) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      sendMessage();
    }
  }
</script>

<div class="chat-panel">
  <!-- Task 3.5: Переключатель Ollama/CORTEX -->
  <div class="chat-header">
    <h2>WORLD_OLLAMA Chat</h2>
    <div class="backend-toggle">
      <button
        class="toggle-btn"
        class:selected={backend === 'ollama'}
        on:click={() => (backend = 'ollama')}
        disabled={isSending}
      >
        🤖 Ollama
      </button>
      <button
        class="toggle-btn"
        class:selected={backend === 'cortex'}
        on:click={() => (backend = 'cortex')}
        disabled={isSending}
      >
        🧠 CORTEX (RAG)
      </button>
    </div>
  </div>

  <!-- Task 3.4: Отображение истории чата -->
  <div class="messages-container" bind:this={messagesContainer}>
    {#if messages.length === 0}
      <div class="empty-state">
        <div class="empty-icon">💬</div>
        <p>Начните диалог с {backend === 'ollama' ? 'Ollama' : 'CORTEX'}</p>
        <p class="hint">
          {backend === 'ollama' 
            ? 'Прямое общение с языковой моделью' 
            : 'Запросы с поиском по базе знаний ТРИЗ'}
        </p>
      </div>
    {:else}
      {#each messages as msg (msg.id)}
        <MessageBubble {msg} />
      {/each}
    {/if}
  </div>

  <!-- Task 3.6: Форма ввода -->
  <form class="chat-input" on:submit|preventDefault={sendMessage}>
    <textarea
      bind:value={inputText}
      placeholder="Введите вопрос... (Enter — отправить, Shift+Enter — новая строка)"
      rows="3"
      disabled={isSending}
      on:keydown={handleKeyPress}
    ></textarea>
    <div class="input-actions">
      <button 
        type="button"
        class="command-gen-btn"
        on:click={generateCommandFromLastUserMessage}
        disabled={messages.length === 0}
        title="Сгенерировать команду из последнего сообщения"
      >
        🔧 Команда
      </button>
      <button 
        type="submit" 
        class="send-btn"
        disabled={isSending || !inputText.trim()}
      >
        {#if isSending}
          <span class="spinner"></span>
          Отправка...
        {:else}
          ➤ Отправить
        {/if}
      </button>
    </div>
  </form>
</div>

<style>
  .chat-panel {
    display: flex;
    flex-direction: column;
    height: 100vh;
    background: #ffffff;
  }

  .chat-header {
    padding: 16px 20px;
    border-bottom: 1px solid #e9ecef;
    display: flex;
    justify-content: space-between;
    align-items: center;
    background: #f8f9fa;
  }

  .chat-header h2 {
    margin: 0;
    font-size: 1.25rem;
    color: #212529;
  }

  .backend-toggle {
    display: flex;
    gap: 8px;
  }

  .toggle-btn {
    padding: 8px 16px;
    border: 2px solid #dee2e6;
    background: white;
    color: #495057;
    border-radius: 8px;
    cursor: pointer;
    font-weight: 600;
    font-size: 0.9rem;
    transition: all 0.2s;
  }

  .toggle-btn:hover:not(:disabled) {
    border-color: #007bff;
    color: #007bff;
  }

  .toggle-btn.selected {
    background: #007bff;
    border-color: #007bff;
    color: white;
  }

  .toggle-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .messages-container {
    flex: 1;
    overflow-y: auto;
    padding: 20px;
    display: flex;
    flex-direction: column;
  }

  .empty-state {
    margin: auto;
    text-align: center;
    color: #6c757d;
  }

  .empty-icon {
    font-size: 4rem;
    margin-bottom: 16px;
  }

  .empty-state p {
    margin: 8px 0;
  }

  .hint {
    font-size: 0.9rem;
    color: #adb5bd;
  }

  .chat-input {
    padding: 16px 20px;
    border-top: 1px solid #e9ecef;
    background: #f8f9fa;
    display: flex;
    gap: 12px;
  }

  textarea {
    flex: 1;
    padding: 12px;
    border: 2px solid #dee2e6;
    border-radius: 8px;
    font-family: inherit;
    font-size: 0.95rem;
    resize: none;
    transition: border-color 0.2s;
  }

  textarea:focus {
    outline: none;
    border-color: #007bff;
  }

  textarea:disabled {
    background: #e9ecef;
    cursor: not-allowed;
  }

  .input-actions {
    display: flex;
    gap: 10px;
    margin-top: 10px;
  }

  .command-gen-btn {
    flex: 0 0 auto;
    padding: 10px 18px;
    background: #28a745;
    color: white;
    border: none;
    border-radius: 8px;
    cursor: pointer;
    font-weight: 600;
    font-size: 0.9rem;
    transition: all 0.2s;
  }

  .command-gen-btn:hover:not(:disabled) {
    background: #218838;
    transform: translateY(-1px);
  }

  .command-gen-btn:disabled {
    background: #6c757d;
    cursor: not-allowed;
    opacity: 0.5;
  }

  .send-btn {
    flex: 1;
    padding: 12px 24px;
    background: #007bff;
    color: white;
    border: none;
    border-radius: 8px;
    cursor: pointer;
    font-weight: 600;
    font-size: 0.95rem;
    transition: background 0.2s;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
  }

  .send-btn:hover:not(:disabled) {
    background: #0056b3;
  }

  .send-btn:disabled {
    background: #6c757d;
    cursor: not-allowed;
  }

  .spinner {
    width: 14px;
    height: 14px;
    border: 2px solid rgba(255, 255, 255, 0.3);
    border-top-color: white;
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }
</style>
