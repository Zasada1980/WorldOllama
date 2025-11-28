// WORLD_OLLAMA Desktop Client - Tauri Core
// Task 2: Core Bridge (Ollama + CORTEX Integration)
// Task 5: Settings + Agent Profiles
// Task 7: Library & Indexation Management
// Task 8: Command Slot + Training UI
// Task 12: Training System (UI + Backend)
// Task 17: Git Safety (Plan Mode)

mod config;
mod commands;
mod settings;
mod command_parser;
mod training_manager;  // NEW: TASK 12.1
mod git_manager;       // NEW: TASK 17 - Git Push Safety

use commands::{
    get_system_status, 
    send_ollama_chat, 
    send_cortex_query, 
    get_app_settings, 
    save_app_settings,
    start_indexation,
    get_indexation_status,
    execute_agent_command,
    // NEW: TASK 12.1 Training commands
    get_training_status,
    clear_training_status,
    list_training_profiles,
    list_datasets_roots,
    // NEW: TASK 16.1 Path Agnosticism
    get_project_root,
    // NEW: TASK 17 Git Safety
    plan_git_push,
    execute_git_push,
};

use tauri::Manager;  // TASK 16.3: Required for path() method

// Сохраняем старую команду для совместимости
#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .setup(|app| {
            // PULSE v1: Singleton poller (ОРДЕР №16.3-UI)
            // Запускаем polling loop ОДИН РАЗ при старте приложения
            let app_handle = app.handle();
            
            // Получаем путь к training_status.json
            let status_path = app_handle
                .path()
                .app_data_dir()
                .expect("Failed to get app data dir")
                .join("training_status.json");
            
            // Запускаем polling в background
            let app_handle_clone = app_handle.clone();
            tauri::async_runtime::spawn(async move {
                log::info!("[PULSE] Starting singleton training status poller");
                if let Err(e) = training_manager::poll_training_status(app_handle_clone, status_path).await {
                    log::error!("[PULSE] Polling error: {}", e);
                }
            });
            
            Ok(())
        })
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
            // NEW: TASK 12.1 Training commands
            get_training_status,
            clear_training_status,
            list_training_profiles,
            list_datasets_roots,
            // NEW: TASK 16.1 Path Agnosticism
            get_project_root,
            // NEW: TASK 17 Git Safety
            plan_git_push,
            execute_git_push,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
