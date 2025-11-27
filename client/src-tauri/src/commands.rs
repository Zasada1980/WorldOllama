use serde::{Deserialize, Serialize};
use reqwest::Client;
use std::time::Duration;

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
use std::fs;
use std::path::PathBuf;
use std::process::Command;

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
    
    // Путь к скрипту индексации
    let script_path = r"E:\WORLD_OLLAMA\scripts\ingest_watcher.ps1";
    
    if !std::path::Path::new(script_path).exists() {
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
        "-File", script_path,
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

fn get_training_status_path() -> PathBuf {
    let app_data = std::env::var("APPDATA").unwrap_or_else(|_| ".".to_string());
    PathBuf::from(app_data)
        .join("tauri_fresh")
        .join("training_status.json")
}

#[derive(Serialize, Deserialize, Clone)]
pub struct TrainingStatus {
    pub state: String, // "idle" | "running" | "completed" | "error"
    pub profile: Option<String>,
    pub data_path: Option<String>,
    pub epochs: Option<u32>,
    pub started_at: Option<String>,
    pub last_error: Option<String>,
}

impl Default for TrainingStatus {
    fn default() -> Self {
        Self {
            state: "idle".to_string(),
            profile: None,
            data_path: None,
            epochs: None,
            started_at: None,
            last_error: None,
        }
    }
}

fn save_training_status(status: &TrainingStatus) -> Result<(), String> {
    ensure_status_dir()?;
    
    let status_path = get_training_status_path();
    let json = serde_json::to_string_pretty(status)
        .map_err(|e| format!("Failed to serialize training status: {}", e))?;
    
    fs::write(&status_path, json)
        .map_err(|e| format!("Failed to write training status file: {}", e))?;
    
    Ok(())
}

// ============================================================================
// Task 9.2: Training Job Launcher (Real Integration)
// ============================================================================

#[derive(Serialize, Deserialize)]
#[allow(dead_code)] // TODO: Will be used in future UI updates for training progress
pub struct TrainingStartInfo {
    pub job_id: String,
    pub started_at: String,
    pub profile: String,
}

/// Запускает фоновое обучение агента с заданными параметрами
fn start_training_job(
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
    let valid_profiles = ["triz_engineer", "triz_researcher", "default"];
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
    let current_status = match get_training_status_path() {
        path if path.exists() => {
            match fs::read_to_string(&path) {
                Ok(json) => serde_json::from_str::<TrainingStatus>(&json).unwrap_or_default(),
                Err(_) => TrainingStatus::default(),
            }
        }
        _ => TrainingStatus::default(),
    };

    if current_status.state == "running" || current_status.state == "queued" {
        return ApiResponse::error(
            "already_running",
            format!(
                "⚠️ Обучение уже выполняется!\n\nТекущий профиль: {}\nСтатус: {}",
                current_status.profile.unwrap_or_else(|| "unknown".to_string()),
                current_status.state
            ),
        );
    }

    // ======== Generate Job ID ========
    let now = Utc::now();
    let job_id = format!("train-{}", now.format("%Y%m%d-%H%M%S"));

    // ======== Update status to "queued" BEFORE launching ========
    let queued_status = TrainingStatus {
        state: "queued".to_string(),
        profile: Some(profile.clone()),
        data_path: Some(data_path.clone()),
        epochs: Some(epochs),
        started_at: Some(now.to_rfc3339()),
        last_error: None,
    };

    if let Err(e) = save_training_status(&queued_status) {
        return ApiResponse::error(
            "status_save_failed",
            format!("❌ Не удалось сохранить статус обучения: {}", e),
        );
    }

    // ======== Launch PowerShell training script ========
    let script_path = r"E:\WORLD_OLLAMA\scripts\start_agent_training.ps1";

    // Check if script exists
    if !std::path::Path::new(script_path).exists() {
        let mut error_status = queued_status.clone();
        error_status.state = "error".to_string();
        error_status.last_error = Some(format!("Скрипт не найден: {}", script_path));
        let _ = save_training_status(&error_status);

        return ApiResponse::error(
            "script_not_found",
            format!("❌ Скрипт обучения не найден:\n{}", script_path),
        );
    }

    let result = Command::new("powershell")
        .args(&[
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            script_path,
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
                    💡 Для мониторинга используйте команду `STATUS: TRAINING` или вкладку 🔧 Commands.",
                    profile, data_path, epochs, mode, job_id
                ),
                command_type: "TRAIN_AGENT".to_string(),
            })
        }
        Err(e) => {
            // Error: update status to "error"
            let mut error_status = queued_status;
            error_status.state = "error".to_string();
            error_status.last_error = Some(format!("Не удалось запустить скрипт: {}", e));
            let _ = save_training_status(&error_status);

            ApiResponse::error(
                "start_failed",
                format!("❌ Не удалось запустить обучение:\n{}", e),
            )
        }
    }
}

#[tauri::command]
pub async fn execute_agent_command(command_text: String) -> ApiResponse<ExecutionResult> {
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

            // ✅ REAL ACTION (Task 9.2): Запуск фонового обучения
            start_training_job(profile, data_path, epochs, mode)
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

            // ======== SECURITY CHECK: Whitelist paths ========
            let allowed_paths = vec!["E:\\WORLD_OLLAMA", "E:/WORLD_OLLAMA"];
            if !allowed_paths.iter().any(|p| repo_path.starts_with(p)) {
                return ApiResponse::error(
                    "security_error",
                    format!(
                        "❌ REPO_PATH должен начинаться с E:\\WORLD_OLLAMA (безопасность)\n\nПолучено: {}",
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

