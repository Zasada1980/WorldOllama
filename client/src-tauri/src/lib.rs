// WORLD_OLLAMA Desktop Client - Tauri Core
// Task 2: Core Bridge (Ollama + CORTEX Integration)
// Task 5: Settings + Agent Profiles
// Task 7: Library & Indexation Management
// Task 8: Command Slot + Training UI

mod config;
mod commands;
mod settings;
mod command_parser;

use commands::{
    get_system_status, 
    send_ollama_chat, 
    send_cortex_query, 
    get_app_settings, 
    save_app_settings,
    start_indexation,
    get_indexation_status,
    execute_agent_command,
};

// Сохраняем старую команду для совместимости
#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![
            greet,
            get_system_status,
            send_ollama_chat,
            send_cortex_query,
            get_app_settings,
            save_app_settings,
            start_indexation,
            get_indexation_status,
            execute_agent_command,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
