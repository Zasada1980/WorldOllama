// training_manager.rs
// Training state management for WORLD_OLLAMA Desktop Client
// Версия: 0.2.0 (TASK 12.1)

use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;
use tauri::{AppHandle, Manager, Emitter};  // TASK 12.1: Add Manager trait for path() method + Emitter for emit()


// ========================================
// ORDER 36: TRAIN PUBLIC API STRUCTURES
// ========================================

/// Configuration for training job execution
/// Used by both Tauri commands and flow_manager
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TrainingConfig {
    /// Training profile name (e.g., "triz_td010v3_full", "default")
    pub profile: String,
    
    /// Optional dataset path (defaults to PROJECT_ROOT/library/raw_documents)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub dataset: Option<String>,
    
    /// Number of epochs (1-5, default: 1)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub epochs: Option<u32>,
    
    /// Training mode ("full", "quick", "standard", etc.)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub mode: Option<String>,
    
    /// Dry-run mode (reserved for future use, currently ignored)
    #[serde(default)]
    pub dry_run: bool,
}

impl Default for TrainingConfig {
    fn default() -> Self {
        Self {
            profile: "default".to_string(),
            dataset: None,
            epochs: Some(1),
            mode: Some("standard".to_string()),
            dry_run: false,
        }
    }
}

/// Result of training job launch attempt
#[derive(Debug, Serialize, Deserialize)]
pub struct TrainingResult {
    /// Success indicator
    pub success: bool,
    
    /// Human-readable message (profile, epochs, job_id, or error)
    pub message: String,
    
    /// Optional job ID for successful launches
    #[serde(skip_serializing_if = "Option::is_none")]
    pub job_id: Option<String>,
}


// ========================================
// СТРУКТУРЫ ДАННЫХ
// ========================================

/// PULSE v1 Protocol: Training Status (ОРДЕР №16.2-FINAL)
/// Каноническая схема - СТРОГО 6 полей, NO EXTENSIONS
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct TrainingStatus {
    /// Статус: "idle" | "running" | "done" | "error" | "stale" (internal)
    pub status: String,
    
    /// Текущая эпоха (может быть дробной, например 2.5)
    pub epoch: f64,
    
    /// Всего эпох в обучении
    pub total_epochs: f64,
    
    /// Текущий/последний loss
    pub loss: f64,
    
    /// Человеко-читаемое сообщение для UI
    pub message: String,
    
    /// Unix timestamp (секунды) - для stale check
    pub timestamp: i64,
}

impl TrainingStatus {
    /// Вычисляет прогресс для UI (0..100)
    pub fn calculate_progress(&self) -> f64 {
        if self.total_epochs > 0.0 {
            ((self.epoch / self.total_epochs) * 100.0).clamp(0.0, 100.0)
        } else {
            0.0
        }
    }
    
    /// Проверяет является ли статус "протухшим" (>60 сек без обновлений)
    pub fn is_stale(&self) -> bool {
        if self.status != "running" {
            return false; // Только running может стать stale
        }
        
        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs() as i64;
        
        let diff = now - self.timestamp;
        diff > 60 // >60 секунд без обновлений
    }
    
    /// Создаёт stale-версию статуса (при зависшем процессе)
    pub fn as_stale(&self) -> Self {
        Self {
            status: "error".to_string(), // Stale трактуется как error
            epoch: self.epoch,
            total_epochs: self.total_epochs,
            loss: self.loss,
            message: "Process unresponsive (stale pulse)".to_string(),
            timestamp: self.timestamp,
        }
    }
    
    /// Безопасное чтение из файла (НЕ падает при битом JSON)
    /// ВАЖНО: При missing file возвращает None (caller интерпретирует как idle)
    pub fn from_file(path: &PathBuf) -> Option<Self> {
        match fs::read_to_string(path) {
            Ok(content) => {
                match serde_json::from_str::<TrainingStatus>(&content) {
                    Ok(status) => {
                        // Stale check ТОЛЬКО для running (ОРДЕР №16.3-UI)
                        if status.is_stale() {
                            log::warn!("Training status is stale (>60s without updates)");
                            Some(status.as_stale())
                        } else {
                            Some(status)
                        }
                    }
                    Err(e) => {
                        log::warn!("Failed to parse training_status.json: {}", e);
                        None
                    }
                }
            }
            Err(_) => {
                // Файл не существует → возвращаем None (не паникуем)
                None
            }
        }
    }
}

impl Default for TrainingStatus {
    fn default() -> Self {
        Self {
            status: "idle".to_string(),
            epoch: 0.0,
            total_epochs: 0.0,
            loss: 0.0,
            message: "No training in progress".to_string(),
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs() as i64,
        }
    }
}

/// Профиль обучения
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TrainingProfile {
    /// ID профиля (например, "default")
    pub id: String,
    
    /// Отображаемое имя
    pub name: String,
    
    /// Описание профиля
    pub description: String,
    
    /// Базовая модель (например, "qwen2.5:14b")
    pub base_model: String,
    
    /// Рекомендуемое количество эпох
    pub recommended_epochs: u32,
}

/// Корневая директория датасета
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DatasetRoot {
    /// Путь к директории
    pub path: String,
    
    /// Отображаемое имя
    pub name: String,
    
    /// Количество файлов (если удалось посчитать)
    pub file_count: Option<usize>,
}

// ========================================
// УТИЛИТЫ
// ========================================

/// Получить путь к файлу статуса обучения
fn get_status_file_path(app_handle: &AppHandle) -> Result<PathBuf, String> {
    let app_data_dir = app_handle
        .path()
        .app_data_dir()
        .map_err(|e| format!("Failed to get app data dir: {}", e))?;
    
    // Создать директорию если не существует
    fs::create_dir_all(&app_data_dir)
        .map_err(|e| format!("Failed to create app data dir: {}", e))?;
    
    Ok(app_data_dir.join("training_status.json"))
}

/// Получить текущее время в ISO8601
fn get_current_timestamp() -> String {
    chrono::Local::now().to_rfc3339()
}

// ========================================
// ПУБЛИЧНЫЕ ФУНКЦИИ (PULSE v1 PROTOCOL)
// ========================================

/// Получить текущий статус обучения (PULSE v1)
/// Использует безопасное чтение с stale-check
pub fn get_training_status(app_handle: &AppHandle) -> Result<TrainingStatus, String> {
    let status_path = get_status_file_path(app_handle)?;
    
    // Безопасное чтение через TrainingStatus::from_file
    match TrainingStatus::from_file(&status_path) {
        Some(status) => Ok(status),
        None => Ok(TrainingStatus::default()), // Файл не существует → idle
    }
}

/// Launch agent training job with given configuration (ORDER 36)
///
/// This is the canonical entry point for training execution.
/// Used by both Tauri commands and flow_manager.
///
/// # Returns
/// * `Ok(TrainingResult)` - training launched or validation failed
/// * `Err(String)` - internal error (status read failed)
pub async fn run_training(
    app_handle: &AppHandle,
    config: TrainingConfig,
) -> Result<TrainingResult, String> {
    use std::process::Command;
    use chrono::Utc;
    
    // Validation 1: Epochs range
    let epochs = config.epochs.unwrap_or(1);
    if epochs < 1 || epochs > 5 {
        return Ok(TrainingResult {
            success: false,
            message: "EPOCHS must be in range 1-5".to_string(),
            job_id: None,
        });
    }
    
    // Validation 2: Profile whitelist
    let valid_profiles = [
        "triz_engineer", "triz_researcher",
        "triz_td010v3_full", "triz_td010v3_smoketest",
        "default"
    ];
    if !valid_profiles.contains(&config.profile.as_str()) {
        return Ok(TrainingResult {
            success: false,
            message: format!("Invalid profile: {}. Valid: {:?}", 
                           config.profile, valid_profiles),
            job_id: None,
        });
    }
    
    // Validation 3: Dataset path (ORDER 37-FIX)
    let project_root = crate::utils::get_project_root();
    
    let data_path = config.dataset.unwrap_or_else(|| {
        project_root.join("library").join("raw_documents")
            .to_string_lossy().to_string()
    });
    
    if !std::path::Path::new(&data_path).exists() {
        return Ok(TrainingResult {
            success: false,
            message: format!("Dataset path not found: {}", data_path),
            job_id: None,
        });
   }
    
    // Validation 4: Check if already running
    let current_status = get_training_status(app_handle)?;
    
    if current_status.status == "running" || current_status.status == "queued" {
        return Ok(TrainingResult {
            success: false,
            message: format!("Training already in progress (status: {})", 
                           current_status.status),
            job_id: None,
        });
    }
    
    // Generate Job ID
    let job_id = format!("train-{}", Utc::now().format("%Y%m%d-%H%M%S"));
    
    // Launch PowerShell training script
    let script_path = project_root.join("scripts").join("start_agent_training.ps1");
    
    if !script_path.exists() {
        return Ok(TrainingResult {
            success: false,
            message: format!("Training script not found: {}", script_path.display()),
            job_id: None,
        });
    }
    
    let mode = config.mode.unwrap_or_else(|| "standard".to_string());
    
    let result = Command::new("powershell")
        .args(&["-NoProfile", "-ExecutionPolicy", "Bypass",
                "-File", &script_path.to_string_lossy(),
                "-Profile", &config.profile,
                "-DataPath", &data_path,
                "-Epochs", &epochs.to_string(),
                "-Mode", &mode])
        .spawn();
    
    match result {
        Ok(_child) => Ok(TrainingResult {
            success: true,
            message: format!("Training started: profile={}, epochs={}, job_id={}", 
                           config.profile, epochs, job_id),
            job_id: Some(job_id),
        }),
        Err(e) => Ok(TrainingResult {
            success: false,
            message: format!("Failed to start training: {}", e),
            job_id: None,
        }),
    }
}

/// Polling loop с дедупликацией и heartbeat (ОРДЕР №16.2-REFINED)
/// Вызывается при старте обучения, emit только при изменениях
pub async fn poll_training_status(
    app_handle: AppHandle,
    status_path: PathBuf,
) -> Result<(), String> {
    use tokio::time::{sleep, Duration, Instant};
    
    let mut last_known_status: Option<TrainingStatus> = None;
    let mut last_emit_time = Instant::now();
    const HEARTBEAT_INTERVAL: u64 = 10; // Heartbeat каждые 10 секунд
    
    loop {
        sleep(Duration::from_secs(2)).await;
        
        match TrainingStatus::from_file(&status_path) {
            Some(status) => {
                let should_emit = match &last_known_status {
                    Some(last) => {
                        // Emit если данные изменились ИЛИ прошло >10 сек (heartbeat)
                        *last != status || last_emit_time.elapsed().as_secs() > HEARTBEAT_INTERVAL
                    }
                    None => true, // Первое чтение → всегда emit
                };
                
                if should_emit {
                    // Emit события в UI
                    if let Err(e) = app_handle.emit("training_status_update", &status) {
                        log::error!("Failed to emit training_status_update: {}", e);
                    } else {
                        log::debug!("Emitted training status: {} (epoch {}/{})", 
                                   status.status, status.epoch, status.total_epochs);
                    }
                    
                    last_emit_time = Instant::now();
                }
                
                // Обновляем cached status
                last_known_status = Some(status.clone());
                
                // Если done/error → выход из цикла
                if status.status == "done" || status.status == "error" {
                    log::info!("Training finished with status: {}", status.status);
                    break;
                }
            }
            None => {
                // Файл не существует или битый JSON → используем cached
                if let Some(ref _cached) = last_known_status {
                    log::warn!("training_status.json unreadable, using cached status");
                } else {
                    log::debug!("training_status.json not yet created");
                }
            }
        }
    }
    
    Ok(())
}

// ВАЖНО (PULSE v1 Protocol):
// Rust НЕ ПИШЕТ в training_status.json напрямую!
// Запись выполняется ТОЛЬКО через Python pulse_wrapper.py (атомарно)
// Rust только ЧИТАЕТ и EMIT событий в UI

/// Очистить статус обучения (удалить файл, UI получит idle через polling)
pub fn clear_training_status(app_handle: &AppHandle) -> Result<(), String> {
    let status_path = get_status_file_path(app_handle)?;
    
    if status_path.exists() {
        fs::remove_file(&status_path)
            .map_err(|e| format!("Failed to remove status file: {}", e))?;
        
        // Emit idle status в UI
        let idle_status = TrainingStatus::default();
        if let Err(e) = app_handle.emit("training_status_update", &idle_status) {
            log::error!("Failed to emit idle status: {}", e);
        }
    }
    
    Ok(())
}

/// Получить список доступных профилей обучения
pub fn list_training_profiles() -> Vec<TrainingProfile> {
    vec![
        TrainingProfile {
            id: "default".to_string(),
            name: "Default LoRA".to_string(),
            description: "Базовое обучение с LoRA адаптером (rank=8, alpha=16)".to_string(),
            base_model: "qwen2.5:14b-instruct-q4_k_m".to_string(),
            recommended_epochs: 3,
        },
        TrainingProfile {
            id: "triz_engineer".to_string(),  // ← Fixed: underscore instead of dash
            name: "TRIZ Engineer".to_string(),
            description: "Специализация на ТРИЗ инженерных задачах (rank=16, alpha=32)".to_string(),
            base_model: "qwen2.5:14b-instruct-q4_k_m".to_string(),
            recommended_epochs: 5,
        },
        TrainingProfile {
            id: "triz_researcher".to_string(),  // ← Fixed: underscore instead of dash
            name: "TRIZ Researcher".to_string(),
            description: "Специализация на ТРИЗ исследованиях (rank=16, alpha=32)".to_string(),
            base_model: "qwen2.5:14b-instruct-q4_k_m".to_string(),
            recommended_epochs: 5,
        },
        TrainingProfile {
            id: "lightweight".to_string(),
            name: "Lightweight (Fast)".to_string(),
            description: "Быстрое обучение с минимальными параметрами (rank=4)".to_string(),
            base_model: "qwen2.5:7b-instruct-q4_k_m".to_string(),
            recommended_epochs: 2,
        },
    ]
}

/// Получить список корневых директорий датасетов
pub fn list_datasets_roots() -> Vec<DatasetRoot> {
    let mut roots = Vec::new();
    
    // ORDER 37-FIX: Use robust project root resolution
    let project_root = crate::utils::get_project_root();
    
    // Главная библиотека WORLD_OLLAMA
    let main_library = project_root.join("library").join("raw_documents");
    let main_library_str = main_library.to_string_lossy().to_string();
    if let Ok(metadata) = fs::metadata(&main_library) {
        if metadata.is_dir() {
            let file_count = fs::read_dir(&main_library)
                .ok()
                .map(|entries| entries.filter_map(Result::ok).count());
            
            roots.push(DatasetRoot {
                path: main_library_str,
                name: "Main Library (TRIZ)".to_string(),
                file_count,
            });
        }
    }
    
    // Cleaned documents
    let cleaned_docs = project_root.join("library").join("cleaned_documents");
    let cleaned_docs_str = cleaned_docs.to_string_lossy().to_string();
    if let Ok(metadata) = fs::metadata(&cleaned_docs) {
        if metadata.is_dir() {
            let file_count = fs::read_dir(&cleaned_docs)
                .ok()
                .map(|entries| entries.filter_map(Result::ok).count());
            
            roots.push(DatasetRoot {
                path: cleaned_docs_str,
                name: "Cleaned Documents".to_string(),
                file_count,
            });
        }
    }
    
    roots
}

// ========================================
// DEPRECATED: Эти функции УДАЛЕНЫ в PULSE v1
// ========================================
// Причина: В PULSE v1 Rust НЕ ПИШЕТ в training_status.json.
// Python (pulse_wrapper.py) — единственный writer через atomic write.
// Rust ТОЛЬКО ЧИТАЕТ (poll_training_status) и emit событий.
//
// Старые функции использовали несуществующие поля:
// - status.state (переименован в status.status)
// - status.profile (удален из PULSE v1)
// - status.dataset_path (удален)
// - status.current_epoch (переименован в status.epoch)
// - status.progress (удален, UI вычисляет из epoch/total_epochs)
// - status.log_path (удален)
// - status.updated_at (заменен на status.timestamp)
//
// ЕСЛИ старый код вызывает эти функции → компиляция УПАДЁТ (по дизайну).
// Нужно переписать на вызовы Python:
//   pulse_wrapper.write_running_status(...)
//   pulse_wrapper.write_done_status(...)
//   pulse_wrapper.write_error_status(...)
//
// Удалено 5 функций:
// - update_training_progress()
// - set_training_queued()
// - set_training_running()
// - set_training_done()
// - set_training_error()

// ========================================
// ТЕСТЫ
// ========================================

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_default_training_status() {
        let status = TrainingStatus::default();
        assert_eq!(status.status, "idle");
        // Поля profile и progress удалены в PULSE v1
    }
    
    #[test]
    fn test_list_training_profiles() {
        let profiles = list_training_profiles();
        assert!(!profiles.is_empty());
        assert!(profiles.iter().any(|p| p.id == "default"));
    }
    
    #[test]
    fn test_training_status_serialization() {
        let status = TrainingStatus {
            status: "running".to_string(),
            epoch: 2.0,
            total_epochs: 4.0,
            loss: 0.5,
            message: "Epoch 2/4".to_string(),
            timestamp: 1234567890,
        };
        
        let json = serde_json::to_string(&status).unwrap();
        let deserialized: TrainingStatus = serde_json::from_str(&json).unwrap();
        
        assert_eq!(deserialized.status, "running");
        assert_eq!(deserialized.epoch, 2.0);
    }
}
