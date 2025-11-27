<script lang="ts">
  import { writable } from 'svelte/store';
  
  // ===========================
  // CHAT COMPONENT (UI STUB)
  // ===========================
  // Purpose: Main chat interface with LLM + CORTEX integration
  // Status: Skeleton (awaiting Tauri Core implementation)
  // Based on: ../UX_SPEC/06_UI_PATTERNS_AND_COMPONENTS.md
  
  // ----- Types -----
  interface Message {
    id: number;
    role: 'user' | 'assistant';
    content: string;
    sources?: string[];
    timestamp: number;
  }
  
  // ----- State -----
  let messages = writable<Message[]>([
    // Mock data for UI testing
    {
      id: 1,
      role: 'user',
      content: 'Explain TRIZ Principle 1 (Drobienie)',
      timestamp: Date.now() - 60000
    },
    {
      id: 2,
      role: 'assistant',
      content: 'TRIZ Principle 1 (Drobienie / Segmentation) involves dividing an object into independent parts...',
      sources: ['Floor_01_TRIZ_Drobienie.txt', 'Floor_03_Principles.txt'],
      timestamp: Date.now() - 30000
    }
  ]);
  
  let userInput = '';
  let useCortex = false;
  let isLoading = false;
  
  // ----- Mock Actions (to be replaced with Tauri commands) -----
  async function sendMessage() {
    if (!userInput.trim()) return;
    
    isLoading = true;
    
    // Add user message
    const userMsg: Message = {
      id: Date.now(),
      role: 'user',
      content: userInput,
      timestamp: Date.now()
    };
    
    messages.update(m => [...m, userMsg]);
    userInput = '';
    
    // TODO: Replace with Tauri command
    // const response = await invoke('send_ollama_chat', { message: userMsg.content });
    
    // Mock assistant response
    setTimeout(() => {
      const assistantMsg: Message = {
        id: Date.now(),
        role: 'assistant',
        content: 'This is a mock response. Replace with Tauri Core integration.',
        sources: useCortex ? ['Mock_Source_1.txt', 'Mock_Source_2.txt'] : undefined,
        timestamp: Date.now()
      };
      
      messages.update(m => [...m, assistantMsg]);
      isLoading = false;
    }, 1500);
  }
  
  function handleKeyPress(event: KeyboardEvent) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      sendMessage();
    }
  }
</script>

<!-- ===========================
     STYLES (Minimal Tailwind-like)
     =========================== -->
<style>
  .chat-container {
    display: flex;
    flex-direction: column;
    height: 100vh;
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
  }
  
  .messages {
    flex: 1;
    overflow-y: auto;
    padding: 20px;
    border: 1px solid #e0e0e0;
    border-radius: 8px;
    background: #fafafa;
    margin-bottom: 20px;
  }
  
  .message {
    margin-bottom: 16px;
    padding: 12px 16px;
    border-radius: 8px;
    max-width: 80%;
  }
  
  .message.user {
    background: #1976D2;
    color: white;
    margin-left: auto;
  }
  
  .message.assistant {
    background: white;
    border: 1px solid #e0e0e0;
  }
  
  .message-content {
    margin: 0;
    line-height: 1.5;
  }
  
  .sources {
    margin-top: 12px;
    padding-top: 12px;
    border-top: 1px solid #e0e0e0;
  }
  
  .source-badge {
    display: inline-block;
    background: #E3F2FD;
    color: #1976D2;
    padding: 4px 8px;
    border-radius: 4px;
    font-size: 12px;
    margin-right: 8px;
    margin-bottom: 4px;
  }
  
  .input-area {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }
  
  .checkbox-container {
    display: flex;
    align-items: center;
    gap: 8px;
  }
  
  textarea {
    width: 100%;
    padding: 12px;
    border: 1px solid #e0e0e0;
    border-radius: 8px;
    font-size: 14px;
    font-family: inherit;
    resize: vertical;
    min-height: 80px;
  }
  
  textarea:focus {
    outline: none;
    border-color: #1976D2;
  }
  
  .button-row {
    display: flex;
    gap: 12px;
    align-items: center;
  }
  
  button {
    padding: 10px 20px;
    border: none;
    border-radius: 6px;
    font-weight: 500;
    cursor: pointer;
    transition: background 0.2s;
  }
  
  .btn-primary {
    background: #1976D2;
    color: white;
  }
  
  .btn-primary:hover:not(:disabled) {
    background: #1565C0;
  }
  
  .btn-primary:disabled {
    background: #BBDEFB;
    cursor: not-allowed;
  }
  
  .loading-indicator {
    color: #757575;
    font-size: 14px;
  }
</style>

<!-- ===========================
     TEMPLATE
     =========================== -->
<div class="chat-container">
  <!-- Message List -->
  <div class="messages">
    {#each $messages as message}
      <div class="message {message.role}">
        <p class="message-content">{message.content}</p>
        
        {#if message.sources && message.sources.length > 0}
          <div class="sources">
            <strong>📚 Sources:</strong><br>
            {#each message.sources as source}
              <span class="source-badge">{source}</span>
            {/each}
          </div>
        {/if}
      </div>
    {/each}
    
    {#if isLoading}
      <div class="message assistant">
        <p class="loading-indicator">🤔 Thinking...</p>
      </div>
    {/if}
  </div>
  
  <!-- Input Area -->
  <div class="input-area">
    <div class="checkbox-container">
      <input 
        type="checkbox" 
        id="use-cortex" 
        bind:checked={useCortex}
      />
      <label for="use-cortex">
        📚 <strong>With Knowledge Base</strong> (CORTEX)
      </label>
    </div>
    
    <textarea
      bind:value={userInput}
      on:keypress={handleKeyPress}
      placeholder="Ask anything... (Shift+Enter for new line, Enter to send)"
      disabled={isLoading}
    />
    
    <div class="button-row">
      <button 
        class="btn-primary"
        on:click={sendMessage}
        disabled={isLoading || !userInput.trim()}
      >
        {isLoading ? '⏳ Sending...' : '📤 Send'}
      </button>
      
      <span style="color: #757575; font-size: 14px;">
        {useCortex ? 'Mode: LLM + RAG' : 'Mode: LLM Only'}
      </span>
    </div>
  </div>
</div>

<!-- ===========================
     TODO: Tauri Integration
     =========================== 
     
     Replace mock `sendMessage()` with:
     
     import { invoke } from '@tauri-apps/api/tauri';
     
     async function sendMessage() {
       try {
         // Send to Ollama
         const ollamaResponse = await invoke('send_ollama_chat', {
           message: userInput,
           model: 'qwen2.5:14b'
         });
         
         let sources = undefined;
         
         // If CORTEX enabled, retrieve sources
         if (useCortex) {
           const cortexResponse = await invoke('send_cortex_query', {
             query: userInput,
             topK: 20,
             mode: 'local'
           });
           sources = cortexResponse.sources;
         }
         
         // Add assistant message
         const assistantMsg: Message = {
           id: Date.now(),
           role: 'assistant',
           content: ollamaResponse.response,
           sources: sources,
           timestamp: Date.now()
         };
         
         messages.update(m => [...m, assistantMsg]);
         
       } catch (error) {
         console.error('Error sending message:', error);
         // TODO: Show toast notification
       }
     }
     
     =========================== -->
