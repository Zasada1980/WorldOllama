const { invoke } = require('@tauri-apps/api/core');

async function testScreenState() {
    try {
        console.log('Calling automation_get_screen_state...');
        const result = await invoke('automation_get_screen_state');
        
        if (result.success) {
            console.log('✅ Success:', JSON.stringify(result.data, null, 2));
            console.log(`  Detected ${result.data.screens_available} screen(s)`);
            return 0;
        } else {
            console.error('❌ Error:', result.error);
            return 1;
        }
    } catch (error) {
        console.error('❌ Exception:', error);
        return 1;
    }
}

testScreenState().then(code => process.exit(code));
