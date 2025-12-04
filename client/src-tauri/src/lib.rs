// WORLD_OLLAMA Desktop Client - Tauri Core
// Task 2: Core Bridge (Ollama + CORTEX Integration)
// Task 5: Settings + Agent Profiles
// Task 7: Library & Indexation Management
// Task 8: Command Slot + Training UI
// Task 12: Training System (UI + Backend)
// Task 17: Git Safety (Plan Mode)
// ORDER 35-38: Flow Automation + Observability

// ===== CORE MODULES (НЕ ТРОГАТЬ) =====
mod config;
mod commands;
mod settings;
mod command_parser;
mod training_manager;  // NEW: TASK 12.1
mod git_manager;       // NEW: TASK 17 - Git Push Safety
mod flow_manager;      // NEW: TASK 24 - Agent Automation
mod index_manager;     // NEW: ORDER 37 - INDEX Rust Wrapper
mod utils;             // NEW: ORDER 37-FIX - Path utilities
mod automation;        // NEW: ЭТАП 1 - Desktop Automation
mod automation_commands; // NEW: ЭТАП 2 - Automation Tauri Commands

// Windows-specific modules (ORDER 43 - Crash Fix)
#[cfg(windows)]
mod windows_job;       // Job Objects for zombie process cleanup
// ===== /CORE MODULES =====

// ===== TAURI IMPORTS (НЕ ТРОГАТЬ) =====
use tauri::Manager;  // TASK 16.3: Required for path() method
use std::sync::{Arc, Mutex};
// ===== /TAURI IMPORTS =====

// ===== TAURI COMMANDS EXPORT (РАЗРЕШЕНО МИНИМАЛЬНО РЕДАКТИРОВАТЬ) =====
use crate::commands::{
    // <AI_EDIT_REGION:COMMANDS_LIST>
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
    start_training_job, // NEW: ORDER 42.2
    // NEW: TASK 16.1 Path Agnosticism
    get_project_root,
    // NEW: TASK 17 Git Safety
    plan_git_push,
    execute_git_push,
    // NEW: ORDER 38 Flow History
    get_flow_history,
    // </AI_EDIT_REGION:COMMANDS_LIST>
};

// NEW: ЭТАП 2 - Desktop Automation Commands
use crate::automation_commands::{
    automation_get_screen_state,
    automation_capture_screenshot,
    automation_click,
    automation_type_text,
    automation_get_windows,
};
// ===== /TAURI COMMANDS EXPORT =====

// NEW: Flow Commands (inline - require state)
use flow_manager::{Flow, FlowStatus};

#[tauri::command]
fn list_flows(state: tauri::State<Arc<Mutex<flow_manager::FlowManager>>>) -> Vec<Flow> {
    state.lock().unwrap().load_flows()
}

#[tauri::command]
fn run_flow(flow_id: String, state: tauri::State<Arc<Mutex<flow_manager::FlowManager>>>) -> Result<(), String> {
    state.lock().unwrap().execute_flow(flow_id)
}

#[tauri::command]
fn get_flow_status(state: tauri::State<Arc<Mutex<flow_manager::FlowManager>>>) -> FlowStatus {
    state.lock().unwrap().get_status()
}

// Сохраняем старую команду для совместимости
#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    // ORDER 43: Windows Job Objects for zombie process cleanup
    // CRITICAL: _job_guard MUST stay in scope for entire app lifetime
    #[cfg(windows)]
    let _job_guard = match windows_job::JobObject::new() {
        Ok(job) => {
            if let Err(e) = job.assign_current_process() {
                eprintln!("[WARN] Failed to assign Job Object: {}", e);
                eprintln!("[WARN] Zombie process cleanup may not work. Fallback to PowerShell cleanup.");
                None
            } else {
                println!("[INFO] Job Object assigned. Zombie cleanup enabled.");
                Some(job) // Keep alive until run() exits
            }
        }
        Err(e) => {
            eprintln!("[WARN] Failed to create Job Object: {}", e);
            eprintln!("[WARN] Falling back to PowerShell cleanup only.");
            None
        }
    };

    let _app_result = tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .setup(|app| {
            let app_handle = app.handle();

            // Initialize FlowManager (ORDER 35)
            let flow_manager = flow_manager::FlowManager::new(app_handle.clone());
            app.manage(Arc::new(Mutex::new(flow_manager)));

            // PULSE v1: Singleton poller (ОРДЕР №16.3-UI)
            // Запускаем polling loop ОДИН РАЗ при старте приложения
            
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
            // <AI_EDIT_REGION:HANDLER_LIST>
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
            start_training_job, // NEW: ORDER 42.2
            // NEW: TASK 16.1 Path Agnosticism
            get_project_root,
            // NEW: TASK 17 Git Safety
            plan_git_push,
            execute_git_push,
            // NEW: TASK 24 / ORDER 35-38 Flow Commands
            list_flows,
            run_flow,
            get_flow_status,
            get_flow_history,
            // NEW: ЭТАП 2 Desktop Automation Commands
            automation_get_screen_state,
            automation_capture_screenshot,
            automation_click,
            automation_type_text,
            automation_get_windows,
            // </AI_EDIT_REGION:HANDLER_LIST>
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
    
    // Job Object cleanup happens here when _job_guard goes out of scope
    // This triggers JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE → all children killed
    #[cfg(windows)]
    drop(_job_guard);
}
