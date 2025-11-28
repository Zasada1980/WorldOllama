<script lang="ts">
  import ChatPanel from '$lib/components/ChatPanel.svelte';
  import SystemStatusPanel from '$lib/components/SystemStatusPanel.svelte';
  import SettingsPanel from '$lib/components/SettingsPanel.svelte';
  import LibraryPanel from '$lib/components/LibraryPanel.svelte';
  import CommandSlot from '$lib/components/CommandSlot.svelte';
  import TrainingPanel from '$lib/components/TrainingPanel.svelte';  // TASK 12.2
  import NotificationCenter from '$lib/components/NotificationCenter.svelte';

  type View = 'chat' | 'status' | 'settings' | 'library' | 'commands' | 'training';
  let activeView: View = 'chat';
</script>

<nav class="main-nav">
  <button 
    class:selected={activeView === 'chat'} 
    on:click={() => activeView = 'chat'}
  >
    💬 Chat
  </button>
  <button 
    class:selected={activeView === 'status'} 
    on:click={() => activeView = 'status'}
  >
    📡 System Status
  </button>
  <button 
    class:selected={activeView === 'library'} 
    on:click={() => activeView = 'library'}
  >
    📚 Library
  </button>
  <button 
    class:selected={activeView === 'commands'} 
    on:click={() => activeView = 'commands'}
  >
    🔧 Commands
  </button>
  <button 
    class:selected={activeView === 'training'} 
    on:click={() => activeView = 'training'}
  >
    🧪 Training
  </button>
  <button 
    class:selected={activeView === 'settings'} 
    on:click={() => activeView = 'settings'}
  >
    ⚙️ Settings
  </button>
</nav>

<main>
  {#if activeView === 'chat'}
    <ChatPanel />
  {:else if activeView === 'status'}
    <SystemStatusPanel />
  {:else if activeView === 'library'}
    <LibraryPanel />
  {:else if activeView === 'commands'}
    <CommandSlot />
  {:else if activeView === 'training'}
    <TrainingPanel />
  {:else if activeView === 'settings'}
    <SettingsPanel />
  {/if}
</main>

<!-- Task 6.2: NotificationCenter overlay -->
<NotificationCenter />

<style>
  :global(body) {
    margin: 0;
    padding: 0;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 
                 'Helvetica Neue', Arial, sans-serif;
    font-size: 14px;
    background: #1a1a1a;
    color: #e0e0e0;
  }

  :global(*) {
    box-sizing: border-box;
  }

  .main-nav {
    display: flex;
    gap: 0;
    background: #2a2a2a;
    border-bottom: 2px solid #333;
    padding: 0;
  }

  .main-nav button {
    flex: 1;
    padding: 16px 24px;
    background: transparent;
    color: #888;
    border: none;
    border-bottom: 3px solid transparent;
    cursor: pointer;
    font-size: 1em;
    font-weight: 600;
    transition: all 0.2s;
  }

  .main-nav button:hover {
    background: #333;
    color: #fff;
  }

  .main-nav button.selected {
    color: #4CAF50;
    background: #1a1a1a;
    border-bottom-color: #4CAF50;
  }

  main {
    min-height: calc(100vh - 60px);
  }
</style>
