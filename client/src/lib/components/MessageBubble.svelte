<script lang="ts">
  import SourcesList from './SourcesList.svelte';

  export let msg: {
    id: string;
    role: 'user' | 'assistant' | 'system';
    text: string;
    backend?: 'ollama' | 'cortex';
    sources?: Array<{ id: string; title?: string; snippet?: string }>;
    error?: boolean;
  };
</script>

<div class="message-bubble {msg.role}" class:error={msg.error}>
  <div class="message-header">
    {#if msg.role === 'user'}
      <span class="role-badge user">Вы</span>
    {:else if msg.role === 'assistant'}
      <span class="role-badge assistant">
        {msg.backend === 'cortex' ? 'CORTEX (RAG)' : 'Ollama'}
      </span>
    {:else}
      <span class="role-badge system">Система</span>
    {/if}
  </div>
  
  <div class="message-text">
    {msg.text}
  </div>

  {#if msg.sources && msg.sources.length > 0}
    <SourcesList sources={msg.sources} />
  {/if}
</div>

<style>
  .message-bubble {
    margin: 12px 0;
    padding: 12px 16px;
    border-radius: 12px;
    max-width: 80%;
    animation: fadeIn 0.3s ease-in;
  }

  @keyframes fadeIn {
    from { opacity: 0; transform: translateY(10px); }
    to { opacity: 1; transform: translateY(0); }
  }

  .message-bubble.user {
    background: #007bff;
    color: white;
    margin-left: auto;
    border-bottom-right-radius: 4px;
  }

  .message-bubble.assistant {
    background: #f1f3f5;
    color: #212529;
    margin-right: auto;
    border-bottom-left-radius: 4px;
  }

  .message-bubble.system {
    background: #fff3cd;
    color: #856404;
    margin: 12px auto;
    text-align: center;
  }

  .message-bubble.error {
    background: #f8d7da;
    color: #721c24;
    border: 1px solid #f5c6cb;
  }

  .message-header {
    font-size: 0.75rem;
    margin-bottom: 6px;
    opacity: 0.8;
  }

  .role-badge {
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .role-badge.user {
    color: rgba(255, 255, 255, 0.9);
  }

  .role-badge.assistant {
    color: #495057;
  }

  .role-badge.system {
    color: #856404;
  }

  .message-text {
    white-space: pre-wrap;
    word-wrap: break-word;
    line-height: 1.5;
  }
</style>
