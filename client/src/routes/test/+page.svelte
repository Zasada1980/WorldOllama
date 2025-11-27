<script lang="ts">
  import { onMount } from 'svelte';
  import { invoke } from '@tauri-apps/api/core';

  type TestStatus = 'pending' | 'running' | 'success' | 'error';
  
  interface TestResult {
    status: TestStatus;
    output: string;
  }

  let tests: Record<string, TestResult> = {
    test1: { status: 'pending', output: 'Нажмите кнопку для запуска...' },
    test2: { status: 'pending', output: 'Нажмите кнопку для запуска...' },
    test3: { status: 'pending', output: 'Нажмите кнопку для запуска...' }
  };

  let successCount = 0;
  let errorCount = 0;
  let totalTime = '0s';
  let showSummary = false;
  let isRunning = false;
  let startTime = 0;

  async function test1_getSystemStatus() {
    tests.test1.status = 'running';
    tests.test1.output = 'Запрос статуса сервисов...';
    
    try {
      const response: any = await invoke('get_system_status');
      
      if (response.ok) {
        const { ollama, cortex } = response.data;
        tests.test1.output = `✅ КОМАНДА ВЫПОЛНЕНА УСПЕШНО

Ollama:
  Статус: ${ollama.status}
  Детали: ${ollama.details || 'N/A'}

CORTEX:
  Статус: ${cortex.status}
  Детали: ${cortex.details || 'N/A'}

📦 Полный ответ (JSON):
${JSON.stringify(response, null, 2)}`;
        
        tests.test1.status = 'success';
        successCount++;
      } else {
        tests.test1.output = `❌ ОШИБКА: ${response.error.message}\n\nТип: ${response.error.type}`;
        tests.test1.status = 'error';
        errorCount++;
      }
    } catch (error: any) {
      tests.test1.output = `❌ ИСКЛЮЧЕНИЕ: ${error.message || error}`;
      tests.test1.status = 'error';
      errorCount++;
    }
  }

  async function test2_sendOllamaChat() {
    tests.test2.status = 'running';
    tests.test2.output = 'Отправка запроса в Ollama...';
    
    try {
      const testPrompt = "Привет! Ответь одним предложением: что такое ТРИЗ?";
      const response: any = await invoke('send_ollama_chat', {
        prompt: testPrompt,
        model: null
      });
      
      if (response.ok) {
        tests.test2.output = `✅ КОМАНДА ВЫПОЛНЕНА УСПЕШНО

Запрос: ${testPrompt}

Модель: ${response.data.model}

Ответ Ollama:
${response.data.response}

Контекст: ${response.data.context ? 'Сохранён (' + response.data.context.length + ' токенов)' : 'N/A'}

📦 Полный ответ (JSON):
${JSON.stringify(response, null, 2)}`;
        
        tests.test2.status = 'success';
        successCount++;
      } else {
        tests.test2.output = `❌ ОШИБКА: ${response.error.message}\n\nТип: ${response.error.type}`;
        tests.test2.status = 'error';
        errorCount++;
      }
    } catch (error: any) {
      tests.test2.output = `❌ ИСКЛЮЧЕНИЕ: ${error.message || error}`;
      tests.test2.status = 'error';
      errorCount++;
    }
  }

  async function test3_sendCortexQuery() {
    tests.test3.status = 'running';
    tests.test3.output = 'Отправка RAG-запроса в CORTEX...';
    
    try {
      const testQuery = "Что такое принцип дробления в ТРИЗ?";
      const response: any = await invoke('send_cortex_query', {
        query: testQuery,
        topK: 10,
        mode: 'local'
      });
      
      if (response.ok) {
        const sources = response.data.sources || [];
        const sourcesPreview = sources.slice(0, 3).map((src: string, idx: number) => 
          `  ${idx + 1}. ${src.substring(0, 100)}...`
        ).join('\n');
        
        tests.test3.output = `✅ КОМАНДА ВЫПОЛНЕНА УСПЕШНО

Запрос: ${testQuery}

Режим: local
Top-K: 10

Ответ CORTEX:
${response.data.answer}

Источники (${sources.length} шт.):
${sourcesPreview || 'Нет источников'}

📦 Полный ответ (JSON):
${JSON.stringify(response, null, 2)}`;
        
        tests.test3.status = 'success';
        successCount++;
      } else {
        tests.test3.output = `❌ ОШИБКА: ${response.error.message}\n\nТип: ${response.error.type}`;
        tests.test3.status = 'error';
        errorCount++;
      }
    } catch (error: any) {
      tests.test3.output = `❌ ИСКЛЮЧЕНИЕ: ${error.message || error}`;
      tests.test3.status = 'error';
      errorCount++;
    }
  }

  async function runAllTests() {
    // Reset
    successCount = 0;
    errorCount = 0;
    showSummary = false;
    isRunning = true;
    startTime = Date.now();
    
    // Run tests sequentially
    await test1_getSystemStatus();
    await new Promise(r => setTimeout(r, 500));
    
    await test2_sendOllamaChat();
    await new Promise(r => setTimeout(r, 500));
    
    await test3_sendCortexQuery();
    
    // Show summary
    totalTime = ((Date.now() - startTime) / 1000).toFixed(2) + 's';
    showSummary = true;
    isRunning = false;
  }

  function getStatusClass(status: TestStatus): string {
    return status;
  }

  function getStatusText(status: TestStatus): string {
    switch (status) {
      case 'running': return 'ВЫПОЛНЯЕТСЯ...';
      case 'success': return '✅ УСПЕШНО';
      case 'error': return '❌ ОШИБКА';
      default: return 'ОЖИДАНИЕ';
    }
  }
</script>

<style>
  :global(body) {
    background: #1a1a1a;
    color: #e0e0e0;
    font-family: 'Consolas', 'Courier New', monospace;
  }

  .container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
  }

  h1 {
    color: #4CAF50;
    margin-bottom: 20px;
    border-bottom: 2px solid #4CAF50;
    padding-bottom: 10px;
  }

  .subtitle {
    margin-bottom: 20px;
    color: #888;
  }

  button {
    background: #4CAF50;
    color: white;
    border: none;
    padding: 12px 24px;
    border-radius: 4px;
    cursor: pointer;
    font-size: 1em;
    font-weight: bold;
    margin-bottom: 20px;
  }

  button:hover { background: #45a049; }
  button:disabled { 
    background: #555; 
    cursor: not-allowed; 
  }

  .test-section {
    background: #2a2a2a;
    border-radius: 8px;
    padding: 20px;
    margin-bottom: 20px;
    border-left: 4px solid #2196F3;
  }

  .test-section h2 {
    color: #2196F3;
    margin-bottom: 15px;
    font-size: 1.2em;
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .status {
    display: inline-block;
    padding: 4px 12px;
    border-radius: 4px;
    font-weight: bold;
    font-size: 0.9em;
  }

  .status.pending { background: #FF9800; color: #000; }
  .status.running { 
    background: #2196F3; 
    color: #fff; 
    animation: pulse 1s infinite; 
  }
  .status.success { background: #4CAF50; color: #fff; }
  .status.error { background: #f44336; color: #fff; }

  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.6; }
  }

  .output {
    background: #1a1a1a;
    padding: 15px;
    border-radius: 4px;
    margin-top: 10px;
    border: 1px solid #333;
    max-height: 400px;
    overflow-y: auto;
  }

  .output pre {
    white-space: pre-wrap;
    word-wrap: break-word;
    color: #a0a0a0;
    font-size: 0.9em;
    margin: 0;
  }

  .summary {
    background: #2a2a2a;
    padding: 20px;
    border-radius: 8px;
    margin-top: 20px;
    border: 2px solid #4CAF50;
  }

  .summary h2 { color: #4CAF50; margin-bottom: 15px; }

  .summary-item {
    display: flex;
    justify-content: space-between;
    padding: 8px 0;
    border-bottom: 1px solid #333;
  }

  .summary-item:last-child { border-bottom: none; }

  .success-text { color: #4CAF50; }
  .error-text { color: #f44336; }
</style>

<div class="container">
  <h1>🧪 CORE BRIDGE AUTO-TEST</h1>
  <p class="subtitle">
    Автоматическая проверка всех Tauri команд без ручного ввода
  </p>

  <button on:click={runAllTests} disabled={isRunning}>
    ▶️ ЗАПУСТИТЬ ВСЕ ТЕСТЫ
  </button>

  <!-- Test 1: System Status -->
  <div class="test-section">
    <h2>
      TEST 1: get_system_status
      <span class="status {getStatusClass(tests.test1.status)}">
        {getStatusText(tests.test1.status)}
      </span>
    </h2>
    <div class="output">
      <pre>{tests.test1.output}</pre>
    </div>
  </div>

  <!-- Test 2: Ollama Chat -->
  <div class="test-section">
    <h2>
      TEST 2: send_ollama_chat
      <span class="status {getStatusClass(tests.test2.status)}">
        {getStatusText(tests.test2.status)}
      </span>
    </h2>
    <div class="output">
      <pre>{tests.test2.output}</pre>
    </div>
  </div>

  <!-- Test 3: CORTEX Query -->
  <div class="test-section">
    <h2>
      TEST 3: send_cortex_query
      <span class="status {getStatusClass(tests.test3.status)}">
        {getStatusText(tests.test3.status)}
      </span>
    </h2>
    <div class="output">
      <pre>{tests.test3.output}</pre>
    </div>
  </div>

  <!-- Summary -->
  {#if showSummary}
    <div class="summary">
      <h2>📊 ИТОГОВЫЙ ОТЧЁТ</h2>
      <div class="summary-item">
        <span>Всего тестов:</span>
        <span>3</span>
      </div>
      <div class="summary-item">
        <span class="success-text">✅ Успешно:</span>
        <span class="success-text">{successCount}</span>
      </div>
      <div class="summary-item">
        <span class="error-text">❌ Провалено:</span>
        <span class="error-text">{errorCount}</span>
      </div>
      <div class="summary-item">
        <span>Время выполнения:</span>
        <span>{totalTime}</span>
      </div>
    </div>
  {/if}
</div>
