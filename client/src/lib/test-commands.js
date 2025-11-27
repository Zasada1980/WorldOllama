// WORLD_OLLAMA Desktop Client - Test Script для Console
// Использование: откройте DevTools в Tauri окне, вставьте в консоль

// @ts-ignore
const { invoke } = window.__TAURI__.core;

// ============================================================================
// Тест 1: Проверка статуса сервисов
// ============================================================================
async function testSystemStatus() {
    console.log('🔍 Проверка статуса Ollama и CORTEX...');
    try {
        const result = await invoke('get_system_status');
        console.log('✅ get_system_status:', result);
        
        if (result.ok) {
            console.log('  Ollama:', result.data.ollama.status, '-', result.data.ollama.details);
            console.log('  CORTEX:', result.data.cortex.status, '-', result.data.cortex.details);
        } else {
            console.error('❌ Ошибка:', result.error);
        }
    } catch (error) {
        console.error('❌ Исключение при вызове get_system_status:', error);
    }
}

// ============================================================================
// Тест 2: Запрос к Ollama
// ============================================================================
async function testOllamaChat() {
    console.log('🤖 Отправка запроса в Ollama...');
    try {
        const result = await invoke('send_ollama_chat', {
            prompt: 'Привет! Ответь одним предложением.',
            model: null, // используем default модель
        });
        console.log('✅ send_ollama_chat:', result);
        
        if (result.ok) {
            console.log('  Модель:', result.data.model);
            console.log('  Ответ:', result.data.response);
        } else {
            console.error('❌ Ошибка:', result.error);
        }
    } catch (error) {
        console.error('❌ Исключение при вызове send_ollama_chat:', error);
    }
}

// ============================================================================
// Тест 3: Запрос к CORTEX
// ============================================================================
async function testCortexQuery() {
    console.log('🧠 Отправка запроса в CORTEX...');
    try {
        const result = await invoke('send_cortex_query', {
            query: 'Что такое ТРИЗ?',
            topK: 5,
            mode: 'local',
        });
        console.log('✅ send_cortex_query:', result);
        
        if (result.ok) {
            console.log('  Ответ:', result.data.answer);
            console.log('  Источники:', result.data.sources);
        } else {
            console.error('❌ Ошибка:', result.error);
        }
    } catch (error) {
        console.error('❌ Исключение при вызове send_cortex_query:', error);
    }
}

// ============================================================================
// Запуск всех тестов последовательно
// ============================================================================
async function runAllTests() {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🚀 WORLD_OLLAMA - Тестирование Core Bridge (Task 2.6)');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    await testSystemStatus();
    console.log('\n');
    
    await testOllamaChat();
    console.log('\n');
    
    await testCortexQuery();
    
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('✅ Все тесты завершены');
}

// Экспорт для глобального доступа
window.WORLD_OLLAMA_TESTS = {
    testSystemStatus,
    testOllamaChat,
    testCortexQuery,
    runAllTests,
};

console.log('📋 Доступные команды:');
console.log('  - WORLD_OLLAMA_TESTS.testSystemStatus()');
console.log('  - WORLD_OLLAMA_TESTS.testOllamaChat()');
console.log('  - WORLD_OLLAMA_TESTS.testCortexQuery()');
console.log('  - WORLD_OLLAMA_TESTS.runAllTests()');
console.log('\n💡 Запустите WORLD_OLLAMA_TESTS.runAllTests() для полного теста');
