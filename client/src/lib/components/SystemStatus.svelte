<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  
  // ===========================
  // SYSTEM STATUS COMPONENT (UI STUB)
  // ===========================
  // Purpose: Monitor Ollama + CORTEX service health
  // Status: Skeleton (awaiting Tauri Core implementation)
  // Based on: ../UX_SPEC/06_UI_PATTERNS_AND_COMPONENTS.md
  
  // ----- Types -----
  interface ServiceStatus {
    name: string;
    url: string;
    status: 'up' | 'down' | 'unknown';
    lastChecked?: number;
  }
  
  // ----- State -----
  let ollamaStatus: ServiceStatus = {
    name: 'Ollama',
    url: 'http://localhost:11434',
    status: 'unknown'
  };
  
  let cortexStatus: ServiceStatus = {
    name: 'CORTEX (LightRAG)',
    url: 'http://localhost:8004',
    status: 'unknown'
  };
  
  let isChecking = false;
  let autoRefreshInterval: number | null = null;
  
  // ----- Mock Actions (to be replaced with Tauri commands) -----
  async function checkSystemStatus() {
    isChecking = true;
    
    // TODO: Replace with Tauri command
    // const status = await invoke('get_system_status');
    
    // Mock status check
    setTimeout(() => {
      // Simulate random status for demo
      ollamaStatus = {
        ...ollamaStatus,
        status: Math.random() > 0.2 ? 'up' : 'down',
        lastChecked: Date.now()
      };
      
      cortexStatus = {
        ...cortexStatus,
        status: Math.random() > 0.2 ? 'up' : 'down',
        lastChecked: Date.now()
      };
      
      isChecking = false;
    }, 1000);
  }
  
  function toggleAutoRefresh() {
    if (autoRefreshInterval) {
      clearInterval(autoRefreshInterval);
      autoRefreshInterval = null;
    } else {
      autoRefreshInterval = setInterval(checkSystemStatus, 10000); // Every 10s
    }
  }
  
  // ----- Lifecycle -----
  onMount(() => {
    checkSystemStatus(); // Initial check
  });
  
  onDestroy(() => {
    if (autoRefreshInterval) {
      clearInterval(autoRefreshInterval);
    }
  });
  
  // ----- Helpers -----
  function getStatusColor(status: string): string {
    switch (status) {
      case 'up': return '#4CAF50';
      case 'down': return '#F44336';
      default: return '#757575';
    }
  }
  
  function getStatusEmoji(status: string): string {
    switch (status) {
      case 'up': return '🟢';
      case 'down': return '🔴';
      default: return '⚪';
    }
  }
  
  function formatLastChecked(timestamp?: number): string {
    if (!timestamp) return 'Never';
    
    const seconds = Math.floor((Date.now() - timestamp) / 1000);
    if (seconds < 60) return `${seconds}s ago`;
    
    const minutes = Math.floor(seconds / 60);
    return `${minutes}m ago`;
  }
</script>

<!-- ===========================
     STYLES
     =========================== -->
<style>
  .status-container {
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
  }
  
  .header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 24px;
  }
  
  h1 {
    font-size: 24px;
    font-weight: 600;
    margin: 0;
  }
  
  .status-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 20px;
    margin-bottom: 24px;
  }
  
  .status-card {
    background: white;
    border: 2px solid;
    border-radius: 12px;
    padding: 20px;
    transition: transform 0.2s;
  }
  
  .status-card:hover {
    transform: translateY(-2px);
  }
  
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;
  }
  
  .service-name {
    font-size: 18px;
    font-weight: 600;
    margin: 0;
  }
  
  .status-badge {
    font-size: 24px;
  }
  
  .service-url {
    color: #757575;
    font-size: 14px;
    margin: 8px 0;
    font-family: monospace;
  }
  
  .last-checked {
    color: #9E9E9E;
    font-size: 12px;
  }
  
  .actions {
    display: flex;
    gap: 12px;
    flex-wrap: wrap;
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
  
  .btn-secondary {
    background: #757575;
    color: white;
  }
  
  .btn-secondary:hover {
    background: #616161;
  }
  
  .btn-secondary.active {
    background: #4CAF50;
  }
  
  button:disabled {
    background: #BDBDBD;
    cursor: not-allowed;
  }
  
  .info-box {
    background: #E3F2FD;
    border-left: 4px solid #1976D2;
    padding: 16px;
    border-radius: 4px;
    margin-top: 24px;
  }
  
  .info-box h3 {
    margin: 0 0 8px 0;
    font-size: 16px;
  }
  
  .info-box p {
    margin: 4px 0;
    font-size: 14px;
    color: #424242;
  }
</style>

<!-- ===========================
     TEMPLATE
     =========================== -->
<div class="status-container">
  <!-- Header -->
  <div class="header">
    <h1>📊 System Status</h1>
    <span style="color: #757575; font-size: 14px;">
      {isChecking ? '🔄 Checking...' : '✅ Ready'}
    </span>
  </div>
  
  <!-- Status Cards -->
  <div class="status-grid">
    <!-- Ollama Card -->
    <div 
      class="status-card" 
      style="border-color: {getStatusColor(ollamaStatus.status)}"
    >
      <div class="card-header">
        <h2 class="service-name">{ollamaStatus.name}</h2>
        <span class="status-badge">{getStatusEmoji(ollamaStatus.status)}</span>
      </div>
      
      <p class="service-url">{ollamaStatus.url}</p>
      
      <p class="last-checked">
        Last checked: {formatLastChecked(ollamaStatus.lastChecked)}
      </p>
    </div>
    
    <!-- CORTEX Card -->
    <div 
      class="status-card" 
      style="border-color: {getStatusColor(cortexStatus.status)}"
    >
      <div class="card-header">
        <h2 class="service-name">{cortexStatus.name}</h2>
        <span class="status-badge">{getStatusEmoji(cortexStatus.status)}</span>
      </div>
      
      <p class="service-url">{cortexStatus.url}</p>
      
      <p class="last-checked">
        Last checked: {formatLastChecked(cortexStatus.lastChecked)}
      </p>
    </div>
  </div>
  
  <!-- Actions -->
  <div class="actions">
    <button 
      class="btn-primary"
      on:click={checkSystemStatus}
      disabled={isChecking}
    >
      {isChecking ? '⏳ Checking...' : '🔄 Refresh Status'}
    </button>
    
    <button 
      class="btn-secondary {autoRefreshInterval ? 'active' : ''}"
      on:click={toggleAutoRefresh}
    >
      {autoRefreshInterval ? '⏸ Stop Auto-Refresh' : '▶ Auto-Refresh (10s)'}
    </button>
    
    <button 
      class="btn-secondary"
      disabled={true}
    >
      🔧 Restart Services (Coming Soon)
    </button>
  </div>
  
  <!-- Info Box -->
  <div class="info-box">
    <h3>ℹ️ Status Guide</h3>
    <p><strong>🟢 Up:</strong> Service responding normally</p>
    <p><strong>🔴 Down:</strong> Service not responding (check if running)</p>
    <p><strong>⚪ Unknown:</strong> Status not checked yet</p>
    <br>
    <p><strong>Troubleshooting:</strong> If services are down, run <code>pwsh E:\WORLD_OLLAMA\scripts\START_ALL.ps1</code></p>
  </div>
</div>

<!-- ===========================
     TODO: Tauri Integration
     =========================== 
     
     Replace mock `checkSystemStatus()` with:
     
     import { invoke } from '@tauri-apps/api/tauri';
     
     async function checkSystemStatus() {
       isChecking = true;
       
       try {
         const status = await invoke('get_system_status');
         
         ollamaStatus = {
           ...ollamaStatus,
           status: status.ollama as 'up' | 'down',
           lastChecked: Date.now()
         };
         
         cortexStatus = {
           ...cortexStatus,
           status: status.cortex as 'up' | 'down',
           lastChecked: Date.now()
         };
         
       } catch (error) {
         console.error('Failed to check system status:', error);
         // Set all to 'down' on error
         ollamaStatus.status = 'down';
         cortexStatus.status = 'down';
         
       } finally {
         isChecking = false;
       }
     }
     
     =========================== -->
