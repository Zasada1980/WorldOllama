<script lang="ts">
  import { writable } from 'svelte/store';
  
  // ===========================
  // SETTINGS COMPONENT (UI STUB)
  // ===========================
  // Purpose: Configure LLM model, CORTEX parameters, app preferences
  // Status: Skeleton (awaiting Tauri Core implementation)
  // Based on: ../UX_SPEC/06_UI_PATTERNS_AND_COMPONENTS.md
  
  // ----- Types -----
  interface Settings {
    llmModel: string;
    topK: number;
    searchMode: 'local' | 'global' | 'naive' | 'hybrid';
  }
  
  // ----- State -----
  let availableModels = [
    'qwen2.5:14b-instruct-q4_k_m',
    'qwen2.5:7b',
    'llama3:8b',
    'mistral:7b'
  ];
  
  let settings = writable<Settings>({
    llmModel: 'qwen2.5:14b-instruct-q4_k_m',
    topK: 20,
    searchMode: 'local'
  });
  
  let isSaving = false;
  let saveSuccess = false;
  
  // ----- Mock Actions (to be replaced with Tauri commands) -----
  async function loadSettings() {
    // TODO: Replace with Tauri command
    // const loadedSettings = await invoke('load_settings');
    // settings.set(loadedSettings);
    
    // Mock: Settings already initialized above
  }
  
  async function saveSettings() {
    isSaving = true;
    saveSuccess = false;
    
    // TODO: Replace with Tauri command
    // await invoke('save_settings', { settings: $settings });
    
    // Mock save
    setTimeout(() => {
      isSaving = false;
      saveSuccess = true;
      
      // Hide success message after 3s
      setTimeout(() => {
        saveSuccess = false;
      }, 3000);
    }, 500);
  }
  
  async function fetchAvailableModels() {
    // TODO: Replace with Tauri command
    // const models = await invoke('get_available_models');
    // availableModels = models;
    
    // Mock: Already initialized above
  }
  
  function resetToDefaults() {
    settings.set({
      llmModel: 'qwen2.5:14b-instruct-q4_k_m',
      topK: 20,
      searchMode: 'local'
    });
  }
  
  // ----- Helpers -----
  function getSearchModeDescription(mode: string): string {
    switch (mode) {
      case 'local':
        return 'Search within local context (fast, focused)';
      case 'global':
        return 'Search entire knowledge graph (slow, comprehensive)';
      case 'naive':
        return 'Simple text search (fastest, least accurate)';
      case 'hybrid':
        return 'Adaptive mode selection (recommended)';
      default:
        return '';
    }
  }
</script>

<!-- ===========================
     STYLES
     =========================== -->
<style>
  .settings-container {
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
  }
  
  h1 {
    font-size: 24px;
    font-weight: 600;
    margin: 0 0 24px 0;
  }
  
  .settings-section {
    background: white;
    border: 1px solid #e0e0e0;
    border-radius: 12px;
    padding: 24px;
    margin-bottom: 20px;
  }
  
  .section-title {
    font-size: 18px;
    font-weight: 600;
    margin: 0 0 16px 0;
    color: #1976D2;
  }
  
  .form-group {
    margin-bottom: 20px;
  }
  
  label {
    display: block;
    font-weight: 500;
    margin-bottom: 8px;
    color: #424242;
  }
  
  .label-description {
    font-size: 14px;
    color: #757575;
    font-weight: 400;
    margin-top: 4px;
  }
  
  select, input[type="range"] {
    width: 100%;
    padding: 10px;
    border: 1px solid #e0e0e0;
    border-radius: 6px;
    font-size: 14px;
    font-family: inherit;
  }
  
  select:focus {
    outline: none;
    border-color: #1976D2;
  }
  
  .slider-container {
    display: flex;
    align-items: center;
    gap: 16px;
  }
  
  input[type="range"] {
    flex: 1;
  }
  
  .slider-value {
    min-width: 60px;
    text-align: center;
    font-weight: 600;
    color: #1976D2;
    font-size: 16px;
  }
  
  .radio-group {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }
  
  .radio-option {
    display: flex;
    align-items: flex-start;
    gap: 8px;
  }
  
  .radio-option input {
    margin-top: 4px;
  }
  
  .radio-label {
    flex: 1;
  }
  
  .radio-title {
    font-weight: 500;
    margin-bottom: 4px;
  }
  
  .radio-description {
    font-size: 14px;
    color: #757575;
  }
  
  .actions {
    display: flex;
    gap: 12px;
    margin-top: 24px;
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
  
  .btn-secondary {
    background: #757575;
    color: white;
  }
  
  .btn-secondary:hover {
    background: #616161;
  }
  
  .success-message {
    background: #E8F5E9;
    border-left: 4px solid #4CAF50;
    color: #2E7D32;
    padding: 12px 16px;
    border-radius: 4px;
    margin-top: 16px;
    animation: fadeIn 0.3s;
  }
  
  @keyframes fadeIn {
    from { opacity: 0; transform: translateY(-10px); }
    to { opacity: 1; transform: translateY(0); }
  }
  
  .info-box {
    background: #FFF3E0;
    border-left: 4px solid #FF9800;
    padding: 16px;
    border-radius: 4px;
    margin-top: 16px;
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
<div class="settings-container">
  <h1>⚙ Settings</h1>
  
  <!-- LLM Configuration Section -->
  <div class="settings-section">
    <h2 class="section-title">🤖 LLM Configuration</h2>
    
    <div class="form-group">
      <label for="llm-model">
        Model Selection
        <span class="label-description">Choose the language model for chat</span>
      </label>
      
      <select id="llm-model" bind:value={$settings.llmModel}>
        {#each availableModels as model}
          <option value={model}>{model}</option>
        {/each}
      </select>
    </div>
  </div>
  
  <!-- CORTEX Configuration Section -->
  <div class="settings-section">
    <h2 class="section-title">📚 CORTEX (Knowledge Base) Configuration</h2>
    
    <div class="form-group">
      <label for="top-k">
        Search Depth (top_k)
        <span class="label-description">Number of source documents to retrieve</span>
      </label>
      
      <div class="slider-container">
        <input 
          type="range" 
          id="top-k"
          bind:value={$settings.topK}
          min="5"
          max="50"
          step="5"
        />
        <span class="slider-value">{$settings.topK}</span>
      </div>
      
      <div class="info-box">
        <p><strong>Recommendation:</strong> 20 sources balances quality and speed (Plan C baseline)</p>
        <p>• Low (5-10): Fast, but may miss relevant info</p>
        <p>• Medium (15-25): Balanced</p>
        <p>• High (30-50): Comprehensive, slower</p>
      </div>
    </div>
    
    <div class="form-group">
      <label>
        Search Mode
        <span class="label-description">How CORTEX searches the knowledge graph</span>
      </label>
      
      <div class="radio-group">
        <div class="radio-option">
          <input 
            type="radio" 
            id="mode-naive" 
            value="naive"
            bind:group={$settings.searchMode}
          />
          <label for="mode-naive" class="radio-label">
            <div class="radio-title">Naive</div>
            <div class="radio-description">{getSearchModeDescription('naive')}</div>
          </label>
        </div>
        
        <div class="radio-option">
          <input 
            type="radio" 
            id="mode-local" 
            value="local"
            bind:group={$settings.searchMode}
          />
          <label for="mode-local" class="radio-label">
            <div class="radio-title">Local (Recommended)</div>
            <div class="radio-description">{getSearchModeDescription('local')}</div>
          </label>
        </div>
        
        <div class="radio-option">
          <input 
            type="radio" 
            id="mode-global" 
            value="global"
            bind:group={$settings.searchMode}
          />
          <label for="mode-global" class="radio-label">
            <div class="radio-title">Global</div>
            <div class="radio-description">{getSearchModeDescription('global')}</div>
          </label>
        </div>
        
        <div class="radio-option">
          <input 
            type="radio" 
            id="mode-hybrid" 
            value="hybrid"
            bind:group={$settings.searchMode}
          />
          <label for="mode-hybrid" class="radio-label">
            <div class="radio-title">Hybrid</div>
            <div class="radio-description">{getSearchModeDescription('hybrid')}</div>
          </label>
        </div>
      </div>
    </div>
  </div>
  
  <!-- Actions -->
  <div class="actions">
    <button 
      class="btn-primary"
      on:click={saveSettings}
      disabled={isSaving}
    >
      {isSaving ? '⏳ Saving...' : '💾 Save Settings'}
    </button>
    
    <button 
      class="btn-secondary"
      on:click={resetToDefaults}
    >
      🔄 Reset to Defaults
    </button>
  </div>
  
  <!-- Success Message -->
  {#if saveSuccess}
    <div class="success-message">
      ✅ Settings saved successfully!
    </div>
  {/if}
</div>

<!-- ===========================
     TODO: Tauri Integration
     =========================== 
     
     1. Replace `loadSettings()` with:
     
     import { invoke } from '@tauri-apps/api/tauri';
     
     async function loadSettings() {
       try {
         const loadedSettings = await invoke('load_settings');
         settings.set(loadedSettings);
       } catch (error) {
         console.error('Failed to load settings:', error);
         // Use defaults
       }
     }
     
     2. Replace `saveSettings()` with:
     
     async function saveSettings() {
       isSaving = true;
       saveSuccess = false;
       
       try {
         await invoke('save_settings', { 
           settings: $settings 
         });
         
         saveSuccess = true;
         setTimeout(() => saveSuccess = false, 3000);
         
       } catch (error) {
         console.error('Failed to save settings:', error);
         // TODO: Show error toast
         
       } finally {
         isSaving = false;
       }
     }
     
     3. Replace `fetchAvailableModels()` with:
     
     async function fetchAvailableModels() {
       try {
         const models = await invoke('get_available_models');
         availableModels = models;
       } catch (error) {
         console.error('Failed to fetch models:', error);
         // Use mock defaults
       }
     }
     
     =========================== -->
