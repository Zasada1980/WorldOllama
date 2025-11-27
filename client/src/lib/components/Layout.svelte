<script lang="ts">
  // ===========================
  // LAYOUT COMPONENT (UI STUB)
  // ===========================
  // Purpose: Main application layout with tab navigation
  // Status: Skeleton (awaiting Tauri Core implementation)
  // Based on: ../UX_SPEC/03_INFORMATION_ARCHITECTURE.md
  
  // ----- State -----
  let currentTab: 'chat' | 'system' | 'settings' = 'chat';
  
  // Mock system status (to be replaced with real status from Tauri)
  let systemStatus: 'healthy' | 'degraded' | 'down' = 'healthy';
</script>

<!-- ===========================
     STYLES
     =========================== -->
<style>
  .app-layout {
    display: flex;
    flex-direction: column;
    height: 100vh;
    background: #f5f5f5;
  }
  
  /* Header */
  header {
    background: white;
    border-bottom: 2px solid #e0e0e0;
    padding: 16px 24px;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  
  h1 {
    font-size: 20px;
    font-weight: 600;
    margin: 0;
    color: #1976D2;
  }
  
  .status-indicator {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 14px;
    font-weight: 500;
  }
  
  .status-dot {
    width: 10px;
    height: 10px;
    border-radius: 50%;
  }
  
  .status-dot.healthy {
    background: #4CAF50;
  }
  
  .status-dot.degraded {
    background: #FF9800;
  }
  
  .status-dot.down {
    background: #F44336;
  }
  
  /* Tab Navigation */
  nav {
    background: white;
    border-bottom: 1px solid #e0e0e0;
    display: flex;
    padding: 0 24px;
  }
  
  .tab-button {
    background: none;
    border: none;
    padding: 16px 24px;
    font-size: 14px;
    font-weight: 500;
    color: #757575;
    cursor: pointer;
    border-bottom: 2px solid transparent;
    transition: all 0.2s;
  }
  
  .tab-button:hover {
    color: #1976D2;
    background: #f5f5f5;
  }
  
  .tab-button.active {
    color: #1976D2;
    border-bottom-color: #1976D2;
  }
  
  /* Main Content */
  main {
    flex: 1;
    overflow-y: auto;
    padding: 0;
  }
  
  .tab-content {
    height: 100%;
  }
</style>

<!-- ===========================
     TEMPLATE
     =========================== -->
<div class="app-layout">
  <!-- Header -->
  <header>
    <h1>🧠 WORLD_OLLAMA</h1>
    
    <div class="status-indicator">
      <span class="status-dot {systemStatus}"></span>
      <span>
        {#if systemStatus === 'healthy'}
          System Healthy
        {:else if systemStatus === 'degraded'}
          System Degraded
        {:else}
          System Down
        {/if}
      </span>
    </div>
  </header>
  
  <!-- Tab Navigation -->
  <nav>
    <button 
      class="tab-button {currentTab === 'chat' ? 'active' : ''}"
      on:click={() => currentTab = 'chat'}
    >
      💬 Chat
    </button>
    
    <button 
      class="tab-button {currentTab === 'system' ? 'active' : ''}"
      on:click={() => currentTab = 'system'}
    >
      📊 System Status
    </button>
    
    <button 
      class="tab-button {currentTab === 'settings' ? 'active' : ''}"
      on:click={() => currentTab = 'settings'}
    >
      ⚙ Settings
    </button>
  </nav>
  
  <!-- Main Content -->
  <main>
    <div class="tab-content">
      <!-- Dynamic content slot -->
      <!-- In real implementation, this will load components dynamically -->
      
      {#if currentTab === 'chat'}
        <div style="padding: 20px; text-align: center; color: #757575;">
          <h2>💬 Chat Component</h2>
          <p>Chat.svelte will be loaded here after Tauri initialization</p>
        </div>
      {:else if currentTab === 'system'}
        <div style="padding: 20px; text-align: center; color: #757575;">
          <h2>📊 System Status Component</h2>
          <p>SystemStatus.svelte will be loaded here after Tauri initialization</p>
        </div>
      {:else if currentTab === 'settings'}
        <div style="padding: 20px; text-align: center; color: #757575;">
          <h2>⚙ Settings Component</h2>
          <p>Settings.svelte will be loaded here after Tauri initialization</p>
        </div>
      {/if}
    </div>
  </main>
</div>

<!-- ===========================
     TODO: After Tauri Init
     =========================== 
     
     Replace placeholders with real component imports:
     
     <script lang="ts">
       import Chat from './Chat.svelte';
       import SystemStatus from './SystemStatus.svelte';
       import Settings from './Settings.svelte';
       
       // Import system status from store
       import { systemStatus } from '../stores/system';
     </script>
     
     <main>
       {#if currentTab === 'chat'}
         <Chat />
       {:else if currentTab === 'system'}
         <SystemStatus />
       {:else if currentTab === 'settings'}
         <Settings />
       {/if}
     </main>
     
     =========================== -->
