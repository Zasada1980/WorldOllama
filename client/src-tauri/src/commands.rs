use serde::{Deserialize, Serialize};
use reqwest::Client;
use std::time::Duration;
use std::process::Command;
use std::fs;
use std::path::PathBuf;
use tauri::{AppHandle, Emitter};
use crate::flow_manager;  // ORDER 38

use crate::config::AppConfig;
use crate::settings::{load_settings, save_settings, AppSettings};

// ============================================================================
// Task 2.5: Unified Response Structure
// ============================================================================

#[derive(Serialize, Deserialize)]
pub struct ApiResponse<T> {
    pub ok: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub data: Option<T>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<ApiError>,
}

#[derive(Serialize, Deserialize)]
pub struct ApiError {
    #[serde(rename = "type")]
    pub error_type: String,
    pub message: String,
}

impl<T> ApiResponse<T> {
    pub fn success(data: T) -> Self {
        Self {
            ok: true,
            data: Some(data),
            error: None,
        }
    }

    pub fn error(error_type: &str, message: String) -> Self {
        Self {
            ok: false,
            data: None,
            error: Some(ApiError {
                error_type: error_type.to_string(),
                message,
            }),
        }
    }
}

// ============================================================================
// TASK 16.1: Path Agnosticism - Single Source of Truth
// ============================================================================

/// Returns the absolute path to the project root directory.
/// Uses environment variable WORLD_OLLAMA_ROOT if set,
/// otherwise calculates from executable location.
#[tauri::command]
pub fn get_project_root(_app_handle: tauri::AppHandle) -> Result<String, String> {
    // Method 1: Environment variable (for testing/deployment flexibility)
    if let Ok(root) = std::env::var("WORLD_OLLAMA_ROOT") {
        return Ok(root);
    }
    
    // Method 2: Current Exe (Production/Dev)
    // exe -> src-tauri -> client -> WORLD_OLLAMA (in dev)
    // or exe -> tauri_fresh -> WORLD_OLLAMA (in prod structure)
    if let Ok(exe_path) = std::env::current_exe() {
        if let Some(parent) = exe_path.parent() {
            if let Some(project_root) = parent.parent() {
                return Ok(project_root.to_string_lossy().to_string());
            }
        }
    }
    
    // Method 3: Current Dir (Last resort)
    Ok(std::env::current_dir()
        .map(|p| p.to_string_lossy().to_string())
        .unwrap_or_else(|_| ".".to_string()))
}

// ============================================================================
// Task 2.2: get_system_status
// ============================================================================

#[derive(Serialize, Deserialize)]
pub struct ServiceStatus {
    pub status: String, // "up" | "down"
    #[serde(skip_serializing_if = "Option::is_none")]
    pub details: Option<String>,
}

#[derive(Serialize, Deserialize)]
pub struct SystemStatus {
    pub ollama: ServiceStatus,
    pub cortex: ServiceStatus,
}

#[tauri::command]
pub async fn get_system_status() -> ApiResponse<SystemStatus> {
    let config = AppConfig::default();
    let client = Client::builder()
        .timeout(Duration::from_secs(3))
        .build()
        .unwrap();

    // Проверка Ollama
    let ollama_status = match client
        .get(format!("{}/api/tags", config.ollama_base_url))
        .send()
        .await
    {
        Ok(res) if res.status().is_success() => ServiceStatus {
            status: "up".to_string(),
            details: Some("Ollama доступен".to_string()),
        },
        Ok(res) => ServiceStatus {
            status: "down".to_string(),
            details: Some(format!("HTTP {}", res.status())),
        },
        Err(e) => ServiceStatus {
            status: "down".to_string(),
            details: Some(format!("Ошибка подключения: {}", e)),
        },
    };

    // Проверка CORTEX
    let cortex_status = match client
        .get(format!("{}/health", config.cortex_base_url))
        .header("X-API-KEY", &config.cortex_api_key)
        .send()
        .await
    {
        Ok(res) if res.status().is_success() => ServiceStatus {
            status: "up".to_string(),
            details: Some("CORTEX доступен".to_string()),
        },
        Ok(res) => ServiceStatus {
            status: "down".to_string(),
            details: Some(format!("HTTP {}", res.status())),
        },
        Err(e) => ServiceStatus {
            status: "down".to_string(),
            details: Some(format!("Ошибка подключения: {}", e)),
        },
    };

    ApiResponse::success(SystemStatus {
        ollama: ollama_status,
        cortex: cortex_status,
    })
}

// ============================================================================
// Task 2.3: send_ollama_chat
// ============================================================================

#[derive(Serialize, Deserialize)]
pub struct OllamaRequest {
    pub model: String,
    pub prompt: String,
    pub stream: bool,
}

#[derive(Serialize, Deserialize)]
pub struct OllamaResponse {
    pub response: String,
    pub model: String,
}

#[tauri::command]
pub async fn send_ollama_chat(
    prompt: String,
    model: Option<String>,
) -> ApiResponse<OllamaResponse> {
    let config = AppConfig::default();
    let settings = load_settings();
    let client = Client::builder()
        .timeout(Duration::from_secs(60))
        .build()
        .unwrap();

    // Приоритет: параметр из UI -> настройки -> дефолт
    let model = model.unwrap_or(settings.ollama_model);

    let request_body = OllamaRequest {
        model: model.clone(),
        prompt,
        stream: false,
    };

    match client
        .post(format!("{}/api/generate", config.ollama_base_url))
        .json(&request_body)
        .send()
        .await
    {
        Ok(res) if res.status().is_success() => {
            match res.json::<serde_json::Value>().await {
                Ok(json) => {
                    let response_text = json["response"]
                        .as_str()
                        .unwrap_or("(пустой ответ)")
                        .to_string();
                    
                    ApiResponse::success(OllamaResponse {
                        response: response_text,
                        model,
                    })
                }
                Err(e) => ApiResponse::error(
                    "bad_response",
                    format!("Не удалось распарсить JSON от Ollama: {}", e),
                ),
            }
        }
        Ok(res) => ApiResponse::error(
            "service_unavailable",
            format!("Ollama вернул ошибку: HTTP {}", res.status()),
        ),
        Err(e) => {
            if e.is_timeout() {
                ApiResponse::error(
                    "network_timeout",
                    "Превышено время ожидания ответа от Ollama (60s)".to_string(),
                )
            } else {
                ApiResponse::error(
                    "network_error",
                    format!("Ошибка подключения к Ollama: {}", e),
                )
            }
        }
    }
}

// ============================================================================
// Task 2.4: send_cortex_query
// ============================================================================

#[derive(Serialize, Deserialize)]
pub struct CortexRequest {
    pub query: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub top_k: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub mode: Option<String>,
}

#[derive(Serialize, Deserialize)]
pub struct CortexResponse {
    pub answer: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub sources: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub metadata: Option<serde_json::Value>,
}

#[tauri::command]
pub async fn send_cortex_query(
    query: String,
    top_k: Option<u32>,
    mode: Option<String>,
) -> ApiResponse<CortexResponse> {
    let config = AppConfig::default();
    let settings = load_settings();
    
    // Приоритет: параметры из UI -> настройки
    let effective_top_k = top_k.unwrap_or(settings.cortex_top_k);
    let effective_mode = mode.unwrap_or(settings.cortex_mode);
    let client = Client::builder()
        .timeout(Duration::from_secs(90))
        .build()
        .unwrap();

    let request_body = CortexRequest {
        query,
        top_k: Some(effective_top_k),
        mode: Some(effective_mode),
    };

    match client
        .post(format!("{}/query", config.cortex_base_url))
        .header("X-API-KEY", &config.cortex_api_key)
        .header("Content-Type", "application/json")
        .json(&request_body)
        .send()
        .await
    {
        Ok(res) if res.status().is_success() => {
            match res.json::<serde_json::Value>().await {
                Ok(json) => {
                    let answer = json["answer"]
                        .as_str()
                        .or_else(|| json["response"].as_str())
                        .unwrap_or("(пустой ответ от CORTEX)")
                        .to_string();

                    let sources = json["sources"]
                        .as_array()
                        .map(|arr| {
                            arr.iter()
                                .filter_map(|v| v.as_str().map(|s| s.to_string()))
                                .collect()
                        });

                    ApiResponse::success(CortexResponse {
                        answer,
                        sources,
                        metadata: Some(json),
                    })
                }
                Err(e) => ApiResponse::error(
                    "bad_response",
                    format!("Не удалось распарсить JSON от CORTEX: {}", e),
                ),
            }
        }
        Ok(res) => ApiResponse::error(
            "service_unavailable",
            format!("CORTEX вернул ошибку: HTTP {}", res.status()),
        ),
        Err(e) => {
            if e.is_timeout() {
                ApiResponse::error(
                    "network_timeout",
                    "Превышено время ожидания ответа от CORTEX (90s)".to_string(),
                )
            } else {
                ApiResponse::error(
                    "network_error",
                    format!("Ошибка подключения к CORTEX: {}", e),
                )
            }
        }
    }
}

// ============================================================================
// Task 5.2.2: Settings Management Commands
// ============================================================================

#[tauri::command]
pub async fn get_app_settings() -> ApiResponse<AppSettings> {
    let settings = load_settings();
    ApiResponse::success(settings)
}

#[tauri::command]
pub async fn save_app_settings(settings: AppSettings) -> ApiResponse<AppSettings> {
    match save_settings(&settings) {
        Ok(_) => ApiResponse::success(settings),
        Err(e) => ApiResponse::error("settings_save_error", e),
    }
}

// ============================================================================
// Task 7.1: Indexation Management Commands
// ============================================================================

use chrono::{DateTime, Utc};

#[derive(Serialize, Deserialize)]
pub struct IndexationStartInfo {
    pub started_at: String,
    pub status: String, // "started"
}

#[derive(Serialize, Deserialize, Clone)]
pub struct IndexationStatus {
    pub state: String, // "idle" | "running" | "error"
    pub last_run: Option<String>,
    pub last_error: Option<String>,
}

impl Default for IndexationStatus {
    fn default() -> Self {
        Self {
            state: "idle".to_string(),
            last_run: None,
            last_error: None,
        }
    }
}

fn get_status_file_path() -> PathBuf {
    let app_data = std::env::var("APPDATA").unwrap_or_else(|_| ".".to_string());
    PathBuf::from(app_data)
        .join("tauri_fresh")
        .join("indexation_status.json")
}

fn ensure_status_dir() -> Result<(), String> {
    let status_path = get_status_file_path();
    if let Some(parent) = status_path.parent() {
        fs::create_dir_all(parent)
            .map_err(|e| format!("Failed to create status directory: {}", e))?;
    }
    Ok(())
}

fn load_indexation_status() -> IndexationStatus {
    let status_path = get_status_file_path();
    
    if !status_path.exists() {
        return IndexationStatus::default();
    }
    
    match fs::read_to_string(&status_path) {
        Ok(content) => {
            serde_json::from_str(&content).unwrap_or_default()
        }
        Err(_) => IndexationStatus::default(),
    }
}

fn save_indexation_status(status: &IndexationStatus) -> Result<(), String> {
    ensure_status_dir()?;
    
    let status_path = get_status_file_path();
    let json = serde_json::to_string_pretty(status)
        .map_err(|e| format!("Failed to serialize status: {}", e))?;
    
    fs::write(&status_path, json)
        .map_err(|e| format!("Failed to write status file: {}", e))?;
    
    Ok(())
}

// Task 9.1: Внутренняя функция для запуска индексации с параметрами
fn start_indexation_internal(
    _path: Option<String>,
    _mode: Option<String>,
    _profile: Option<String>,
) -> ApiResponse<IndexationStartInfo> {
    // Проверяем текущий статус
    let current_status = load_indexation_status();
    if current_status.state == "running" {
        return ApiResponse::error(
            "already_running",
            "Индексация уже выполняется".to_string(),
        );
    }
    
    // TASK 16.1: Динамический путь к скрипту индексации
    // Note: Эта функция вызывается из Tauri command, но app_handle недоступен
    // Используем относительный путь от exe или environment variable
    let project_root = std::env::var("WORLD_OLLAMA_ROOT")
        .unwrap_or_else(|_| std::env::current_exe()
            .ok()
            .and_then(|p| p.parent().and_then(|p| p.parent()).map(|p| p.to_string_lossy().to_string()))
            .unwrap_or_else(|| ".".to_string()));
    
    let script_path = format!("{}\\scripts\\ingest_watcher.ps1", project_root);
    
    if !std::path::Path::new(&script_path).exists() {
        let mut error_status = current_status;
        error_status.state = "error".to_string();
        error_status.last_error = Some(format!("Скрипт индексации не найден: {}", script_path));
        let _ = save_indexation_status(&error_status);
        
        return ApiResponse::error(
            "script_not_found",
            format!("Скрипт индексации не найден: {}", script_path),
        );
    }
    
    // Формируем аргументы для скрипта
    let args = vec![
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", &script_path,
        "-DetailedOutput"
    ];
    
    // TODO: В будущем передавать path/mode/profile в скрипт
    // Пока скрипт использует дефолтные пути из конфига
    // После обновления скрипта можно добавить:
    // if let Some(p) = path { args.extend(&["-Path", &p]); }
    // if let Some(m) = mode { args.extend(&["-Mode", &m]); }
    // if let Some(pr) = profile { args.extend(&["-Profile", &pr]); }
    
    // Запускаем PowerShell скрипт в фоне
    let result = Command::new("powershell")
        .args(&args)
        .spawn();
    
    match result {
        Ok(_child) => {
            let now: DateTime<Utc> = Utc::now();
            let timestamp = now.to_rfc3339();
            
            // Обновляем статус
            let new_status = IndexationStatus {
                state: "running".to_string(),
                last_run: Some(timestamp.clone()),
                last_error: None,
            };
            
            if let Err(e) = save_indexation_status(&new_status) {
                return ApiResponse::error("status_save_failed", e);
            }
            
            ApiResponse::success(IndexationStartInfo {
                started_at: timestamp,
                status: "started".to_string(),
            })
        }
        Err(e) => {
            let mut error_status = current_status;
            error_status.state = "error".to_string();
            error_status.last_error = Some(format!("Не удалось запустить скрипт: {}", e));
            let _ = save_indexation_status(&error_status);
            
            ApiResponse::error(
                "start_failed",
                format!("Не удалось запустить индексацию: {}", e),
            )
        }
    }
}

#[tauri::command]
pub async fn start_indexation() -> ApiResponse<IndexationStartInfo> {
    // Используем внутреннюю функцию с дефолтными параметрами
    start_indexation_internal(None, None, None)
}

#[tauri::command]
pub async fn get_indexation_status() -> ApiResponse<IndexationStatus> {
    let status = load_indexation_status();
    ApiResponse::success(status)
}

// ============================================================================
// Task 8.2: Agent Command Execution
// ============================================================================

use crate::command_parser::{parse_command, validate_index_knowledge, validate_train_agent, validate_git_push, CommandKind};

#[derive(Serialize, Deserialize)]
pub struct ExecutionResult {
    pub success: bool,
    pub message: String,
    pub command_type: String,
}

// ============================================================================
// Task 9.2: Training Job Launcher (Real Integration)
// ============================================================================
// NOTE: TrainingStatus moved to training_manager.rs in TASK 12.1
// NOTE: All training status management now uses training_manager functions
// PULSE v1 (ОРДЕР №16.3-UI): Python writes status, Rust reads only

// REMOVED: set_training_queued, set_training_error (PULSE v1 enforcement)
// Use: training_manager::{get_training_status, clear_training_status, get_status_file_path}

#[derive(Serialize, Deserialize)]
#[allow(dead_code)] // TODO: Will be used in future UI updates for training progress
pub struct TrainingStartInfo {
    pub job_id: String,
    pub started_at: String,
    pub profile: String,
}

/// Запускает фоновое обучение агента с заданными параметрами
#[tauri::command]
pub async fn start_training_job(
    app_handle: tauri::AppHandle,  // NEW: TASK 12.1 - need app_handle for status
    profile: String,
    data_path: String,
    epochs: u32,
    mode: String,
) -> ApiResponse<ExecutionResult> {
    // ======== VALIDATION 1: DATA_PATH exists ========
    if !std::path::Path::new(&data_path).exists() {
        return ApiResponse::error(
            "validation_error",
            format!("❌ DATA_PATH не существует:\n{}", data_path),
        );
    }

    // ======== VALIDATION 2: PROFILE whitelist ========
    // TASK 15.2.4: Added triz_td010v3_full for LLaMA Factory TRIZ training
    let valid_profiles = [
        "triz_engineer", 
        "triz_researcher", 
        "triz_td010v3_full",       // 15.2.4: Full TRIZ dataset (3448 examples)
        "triz_td010v3_smoketest",  // 15.2.5: Smoke-test profile (100 examples, 50 steps)
        "default"
    ];
    if !valid_profiles.contains(&profile.as_str()) {
        return ApiResponse::error(
            "validation_error",
            format!(
                "❌ Недопустимый PROFILE: {}\nДопустимые значения: {:?}",
                profile, valid_profiles
            ),
        );
    }

    // ======== VALIDATION 3: EPOCHS range ========
    if epochs < 1 || epochs > 5 {
        return ApiResponse::error(
            "validation_error",
            "❌ EPOCHS должен быть в диапазоне 1-5".to_string(),
        );
    }

    // ======== VALIDATION 4: Check if training already running ========
    let current_status = match crate::training_manager::get_training_status(&app_handle) {
        Ok(status) => status,
        Err(_) => {
            // If can't read status, assume idle (safe default)
            return ApiResponse::error(
                "status_read_failed",
                "❌ Не удалось прочитать текущий статус обучения".to_string(),
            );
        }
    };

    if current_status.status == "running" || current_status.status == "queued" {
        return ApiResponse::error(
            "already_running",
            format!(
                "⚠️ Обучение уже выполняется!\n\nТекущий профиль: {}\nСтатус: {}",
                "(profile removed in PULSE v1)",
                current_status.status
            ),
        );
    }

    // ======== Generate Job ID ========
    use chrono::Utc;
    let now = Utc::now();
    let job_id = format!("train-{}", now.format("%Y%m%d-%H%M%S"));

    // ======== PULSE v1: Python pulse_wrapper пишет статус, Rust только читает ========
    // NOTE: Статус "queued" теперь устанавливается внутри start_agent_training.ps1
    // через вызов pulse_wrapper.write_idle_status() или write_running_status()

    // ======== Launch PowerShell training script (TASK 16.1: Dynamic path) ========
    let project_root = crate::utils::get_project_root();
    let script_path = project_root.join("scripts").join("start_agent_training.ps1");
    let script_path_str = script_path.to_string_lossy().to_string();
    // Check if script exists
    if !std::path::Path::new(&script_path).exists() {
        // PULSE v1: НЕ пишем error статус из Rust (Python пишет)
        return ApiResponse::error(
            "script_not_found",
            format!("❌ Скрипт обучения не найден:\n{}", &script_path_str),
        );
    }

    let result = Command::new("powershell")
        .args(&[
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            &script_path_str,
            "-Profile",
            &profile,
            "-DataPath",
            &data_path,
            "-Epochs",
            &epochs.to_string(),
            "-Mode",
            &mode,
        ])
        .spawn();

    match result {
        Ok(_child) => {
            // Success: training launched in background
            ApiResponse::success(ExecutionResult {
                success: true,
                message: format!(
                    "✅ Обучение профиля **{}** запущено!\n\n\
                    📋 Параметры:\n\
                    • DATA_PATH: {}\n\
                    • EPOCHS: {}\n\
                    • MODE: {}\n\n\
                    🆔 Job ID: {}\n\n\
                    ⚠️ Обучение выполняется в фоне. Статус отслеживается в `training_status.json`.\n\n\
                    💡 Для мониторинга используйте команду `STATUS: TRAINING` или вкладку 🧠 Training.",
                    profile, data_path, epochs, mode, job_id
                ),
                command_type: "TRAIN_AGENT".to_string(),
            })
        }
        Err(e) => {
            // PULSE v1: НЕ пишем error статус из Rust (Python пишет)
            ApiResponse::error(
                "start_failed",
                format!("❌ Не удалось запустить обучение:\n{}", e),
            )
        }
    }
}

#[tauri::command]
pub async fn execute_agent_command(
    app_handle: tauri::AppHandle,  // TASK 12.1: Need for training status management
    command_text: String
) -> ApiResponse<ExecutionResult> {
    // Шаг 1: Парсинг команды
    let parsed = match parse_command(&command_text) {
        Ok(cmd) => cmd,
        Err(e) => {
            return ApiResponse::error(
                "parse_error",
                format!("Ошибка парсинга команды: {}", e),
            );
        }
    };

    // Шаг 2: Валидация и выполнение в зависимости от типа
    match parsed.kind {
        CommandKind::IndexKnowledge => {
            // Валидация
            if let Err(e) = validate_index_knowledge(&parsed) {
                return ApiResponse::error(
                    "validation_error",
                    format!("Ошибка валидации INDEX KNOWLEDGE: {}", e),
                );
            }

            // Получаем аргументы
            let path = parsed.args.get("PATH").cloned();
            let mode = parsed.args.get("MODE").cloned();
            let profile = parsed.args.get("PROFILE").cloned();

            // Task 9.1: РЕАЛЬНЫЙ ЗАПУСК ИНДЕКСАЦИИ
            let indexation_result = start_indexation_internal(path.clone(), mode.clone(), profile.clone());

            match indexation_result {
                ApiResponse { ok: true, data: Some(info), .. } => {
                    let path_display = path.unwrap_or_else(|| "default".to_string());
                    let mode_display = mode.unwrap_or_else(|| "local".to_string());
                    let profile_display = profile.unwrap_or_else(|| "default".to_string());

                    ApiResponse::success(ExecutionResult {
                        success: true,
                        message: format!(
                            "✅ Индексация запущена!\n\nПараметры:\nPATH: {}\nMODE: {}\nPROFILE: {}\n\nВремя старта: {}\n\nСтатус можно отслеживать на вкладке 📚 Library.",
                            path_display, mode_display, profile_display, info.started_at
                        ),
                        command_type: "INDEX_KNOWLEDGE".to_string(),
                    })
                }
                ApiResponse { error: Some(err), .. } => {
                    ApiResponse::error(
                        "indexation_failed",
                        format!("Ошибка запуска индексации: {} - {}", err.error_type, err.message),
                    )
                }
                _ => {
                    ApiResponse::error(
                        "unexpected_error",
                        "Неожиданный ответ от start_indexation_internal".to_string(),
                    )
                }
            }
        }

        CommandKind::TrainAgent => {
            // Валидация команды
            if let Err(e) = validate_train_agent(&parsed) {
                return ApiResponse::error(
                    "validation_error",
                    format!("Ошибка валидации TRAIN AGENT: {}", e),
                );
            }

            // Извлечение аргументов (обязательные уже проверены в validate_train_agent)
            let profile = parsed.args.get("PROFILE").cloned().unwrap();
            let data_path = parsed.args.get("DATA_PATH").cloned().unwrap();
            let epochs = parsed.args.get("EPOCHS")
                .and_then(|s| s.parse::<u32>().ok())
                .unwrap_or(3);
            let mode = parsed.args.get("MODE").cloned().unwrap_or_else(|| "llama_factory".to_string());

            // ✅ REAL ACTION (Task 12.1): Запуск фонового обучения через новый backend
            start_training_job(app_handle.clone(), profile, data_path, epochs, mode).await
        }

        CommandKind::GitPush => {
            // Валидация команды
            if let Err(e) = validate_git_push(&parsed) {
                return ApiResponse::error(
                    "validation_error",
                    format!("Ошибка валидации GIT PUSH: {}", e),
                );
            }

            // Извлечение аргументов
            let repo_path = parsed.args.get("REPO_PATH").cloned().unwrap();
            let branch = parsed.args.get("BRANCH").cloned().unwrap_or_else(|| "main".to_string());
            let summary = parsed.args.get("SUMMARY").cloned().unwrap_or_else(|| "Auto-commit".to_string());

            // ======== SECURITY CHECK: Whitelist paths (TASK 16.1: Dynamic) ========
            let project_root = std::env::var("WORLD_OLLAMA_ROOT")
                .unwrap_or_else(|_| std::env::current_exe()
                    .ok()
                    .and_then(|p| p.parent().and_then(|p| p.parent()).map(|p| p.to_string_lossy().to_string()))
                    .unwrap_or_else(|| ".".to_string()));
            
            let allowed_paths = vec![project_root.clone(), project_root.replace("\\", "/")];
            if !allowed_paths.iter().any(|p| repo_path.starts_with(p)) {
                return ApiResponse::error(
                    "security_error",
                    format!(
                        "❌ REPO_PATH должен находиться внутри проекта (безопасность)\n\nРазрешённый корень: {}\nПолучено: {}",
                        allowed_paths.first().unwrap_or(&"unknown".to_string()),
                        repo_path
                    ),
                );
            }

            // ======== DRY-RUN: Execute git status --porcelain ========
            let result = Command::new("git")
                .args(&["status", "--porcelain"])
                .current_dir(&repo_path)
                .output();

            match result {
                Ok(output) => {
                    if !output.status.success() {
                        let stderr = String::from_utf8_lossy(&output.stderr);
                        return ApiResponse::error(
                            "git_error",
                            format!("❌ Не удалось выполнить git status:\n{}", stderr),
                        );
                    }

                    // Parse git status output
                    let status_output = String::from_utf8_lossy(&output.stdout);
                    let changed_files: Vec<&str> = status_output
                        .lines()
                        .filter(|line| !line.trim().is_empty())
                        .collect();

                    if changed_files.is_empty() {
                        // No changes detected
                        return ApiResponse::success(ExecutionResult {
                            success: true,
                            message: format!(
                                "✅ Git dry-run выполнен.\n\n\
                                 📁 Репозиторий: {}\n\
                                 🌿 Ветка: {}\n\n\
                                 ℹ️ **Нет изменённых файлов.**\n\n\
                                 ⚠️ Реальный push не производится (безопасный режим).",
                                repo_path, branch
                            ),
                            command_type: "GIT_PUSH".to_string(),
                        });
                    }

                    // Changes detected
                    let files_display = changed_files
                        .iter()
                        .take(20) // Limit to first 20 files
                        .map(|f| format!("  {}", f))
                        .collect::<Vec<_>>()
                        .join("\n");

                    let truncation_note = if changed_files.len() > 20 {
                        format!("\n\n... и ещё {} файлов", changed_files.len() - 20)
                    } else {
                        String::new()
                    };

                    ApiResponse::success(ExecutionResult {
                        success: true,
                        message: format!(
                            "✅ Git dry-run выполнен.\n\n\
                             📁 Изменённые файлы ({}):\n{}{}\n\n\
                             📋 Параметры:\n\
                             • РЕПОЗИТОРИЙ: {}\n\
                             • ВЕТКА: {}\n\
                             • СООБЩЕНИЕ: {}\n\n\
                             ⚠️ Реальный push не производится (безопасный режим).\n\n\
                             💡 Для реального коммита используйте `git` в терминале.",
                            changed_files.len(),
                            files_display,
                            truncation_note,
                            repo_path,
                            branch,
                            summary
                        ),
                        command_type: "GIT_PUSH".to_string(),
                    })
                }
                Err(e) => {
                    ApiResponse::error(
                        "git_error",
                        format!("❌ Ошибка выполнения git:\n{}", e),
                    )
                }
            }
        }
    }
}

// ============================================================================
// TASK 12.1: Training Management Commands
// ============================================================================

use crate::training_manager::{
    get_training_status as get_status_internal,
    clear_training_status as clear_status_internal,
    list_training_profiles as list_profiles_internal,
    list_datasets_roots as list_datasets_internal,
    TrainingStatus,
    TrainingProfile,
    DatasetRoot,
};

/// Получить текущий статус обучения
#[tauri::command]
pub async fn get_training_status(
    app_handle: tauri::AppHandle,
) -> ApiResponse<TrainingStatus> {
    match get_status_internal(&app_handle) {
        Ok(status) => ApiResponse::success(status),
        Err(e) => ApiResponse::error("status_error", format!("Failed to get training status: {}", e)),
    }
}

/// Очистить статус обучения (сбросить в idle)
#[tauri::command]
pub async fn clear_training_status(
    app_handle: tauri::AppHandle,
) -> ApiResponse<()> {
    match clear_status_internal(&app_handle) {
        Ok(_) => ApiResponse::success(()),
        Err(e) => ApiResponse::error("clear_error", format!("Failed to clear training status: {}", e)),
    }
}

/// Получить список доступных профилей обучения
#[tauri::command]
pub async fn list_training_profiles() -> ApiResponse<Vec<TrainingProfile>> {
    let profiles = list_profiles_internal();
    ApiResponse::success(profiles)
}

/// Получить список корневых директорий датасетов
#[tauri::command]
pub async fn list_datasets_roots() -> ApiResponse<Vec<DatasetRoot>> {
    let roots = list_datasets_internal();
    ApiResponse::success(roots)
}

// ============================================================================
// TASK 17: Git Safety Commands
// ============================================================================

use crate::git_manager::{
    plan_git_push as plan_push_internal, 
    execute_git_push as execute_push_internal,
    GitPushPlan,
    GitPushResult,
};

/// Планирование Git Push (readonly анализ)
/// 
/// Эта команда НЕ выполняет push, только анализирует состояние репозитория
/// и возвращает план с результатами безопасности.
/// 
/// # Arguments
/// 
/// * `remote` - Имя remote (обычно "origin")
/// * `branch` - Целевая ветка для push (обычно "main")
/// 
/// # Returns
/// 
/// * `GitPushPlan` - Структура с результатами анализа:
///   - `status`: "ready" | "blocked" | "clean"
///   - `commits`: Список исходящих коммитов
///   - `files_changed`: Список изменённых файлов
///   - `blocked_reasons`: Причины блокировки (если есть)
#[tauri::command]
pub async fn plan_git_push(
    app_handle: tauri::AppHandle,
    remote: String,
    branch: String,
) -> ApiResponse<GitPushPlan> {
    // Получаем project root через существующую функцию
    let repo_root = match get_project_root(app_handle) {
        Ok(root) => root,
        Err(e) => return ApiResponse::error(
            "path_error",
            format!("Failed to get project root: {}", e)
        ),
    };
    
    // Вызываем plan_git_push из git_manager
    match plan_push_internal(&repo_root, &remote, &branch) {
        Ok(plan) => ApiResponse::success(plan),
        Err(e) => ApiResponse::error(
            "git_error",
            format!("Git command failed: {}", e)
        ),
    }
}

/// Выполнение Git Push (write операция с re-validation)
/// 
/// Эта команда ВЫПОЛНЯЕТ push после повторной проверки состояния репозитория.
/// 
/// # Safety
/// 
/// Перед выполнением повторно вызывает plan_git_push().
/// Если статус != "ready" → возвращает ошибку без выполнения push.
/// 
/// # Arguments
/// 
/// * `remote` - Имя remote (обычно "origin")
/// * `branch` - Целевая ветка для push (обычно "main")
/// 
/// # Returns
/// 
/// * `GitPushResult` - Результат выполнения:
///   - `success`: true/false
///   - `message`: stdout при успехе, stderr при ошибке
#[tauri::command]
pub async fn execute_git_push(
    app_handle: tauri::AppHandle,
    remote: String,
    branch: String,
) -> ApiResponse<GitPushResult> {
    // Получаем project root через существующую функцию
    let repo_root = match get_project_root(app_handle) {
        Ok(root) => root,
        Err(e) => return ApiResponse::error(
            "path_error",
            format!("Failed to get project root: {}", e)
        ),
    };
    
    // Вызываем execute_git_push из git_manager (с re-validation внутри)
    match execute_push_internal(&repo_root, &remote, &branch) {
        Ok(result) => ApiResponse::success(result),
        Err(e) => ApiResponse::error(
            "git_error",
            format!("Git command failed: {}", e)
        ),
    }
}
/// ORDER 38 КОМАНДА 2
#[tauri::command]
pub fn get_flow_history(limit: Option<usize>) -> ApiResponse<Vec<flow_manager::FlowRunSummary>> {
    let limit = limit.unwrap_or(10);
    match flow_manager::FlowManager::get_flow_history(limit) {
        Ok(history) => ApiResponse::success(history),
        Err(e) => ApiResponse::error("history_error", e),
    }
}