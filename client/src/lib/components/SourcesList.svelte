<script lang="ts">
  export let sources: Array<{
    id: string;
    title?: string;
    snippet?: string;
  }>;

  let expanded = false;
</script>

<div class="sources-container">
  <button 
    class="sources-toggle" 
    on:click={() => expanded = !expanded}
  >
    <span class="icon">{expanded ? '▼' : '▶'}</span>
    Источники ({sources.length})
  </button>

  {#if expanded}
    <div class="sources-list">
      {#each sources as source, i}
        <div class="source-item">
          <div class="source-number">{i + 1}</div>
          <div class="source-content">
            {#if source.title}
              <div class="source-title">{source.title}</div>
            {/if}
            {#if source.snippet}
              <div class="source-snippet">{source.snippet}</div>
            {/if}
            <div class="source-id">{source.id}</div>
          </div>
        </div>
      {/each}
    </div>
  {/if}
</div>

<style>
  .sources-container {
    margin-top: 12px;
    padding-top: 12px;
    border-top: 1px solid rgba(0, 0, 0, 0.1);
  }

  .sources-toggle {
    background: none;
    border: none;
    color: #007bff;
    cursor: pointer;
    font-size: 0.85rem;
    font-weight: 600;
    padding: 4px 8px;
    display: flex;
    align-items: center;
    gap: 6px;
    transition: color 0.2s;
  }

  .sources-toggle:hover {
    color: #0056b3;
  }

  .icon {
    font-size: 0.7rem;
  }

  .sources-list {
    margin-top: 8px;
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .source-item {
    display: flex;
    gap: 10px;
    padding: 8px;
    background: rgba(0, 0, 0, 0.03);
    border-radius: 6px;
    font-size: 0.85rem;
  }

  .source-number {
    flex-shrink: 0;
    width: 24px;
    height: 24px;
    background: #007bff;
    color: white;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 600;
    font-size: 0.75rem;
  }

  .source-content {
    flex: 1;
    min-width: 0;
  }

  .source-title {
    font-weight: 600;
    color: #212529;
    margin-bottom: 4px;
  }

  .source-snippet {
    color: #495057;
    line-height: 1.4;
    margin-bottom: 4px;
  }

  .source-id {
    color: #6c757d;
    font-size: 0.75rem;
    font-family: 'Courier New', monospace;
  }
</style>
