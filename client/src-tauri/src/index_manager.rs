/// ORDER 37: INDEX Command Public API
///
/// Single entry point for all indexing operations.
/// Used by both Tauri commands and flow_manager.
///
/// Design mirrors training_manager.rs (ORDER 36) for consistency.

use tauri::AppHandle;
use std::process::Command;
use chrono::Utc;

#[derive(Debug, Clone)]
pub struct IndexConfig {
    pub profile: Option<String>,    // Future: profile-specific indexing
    pub data_root: Option<String>,  // Override default dataset path
    pub mode: Option<String>,       // "full" | "incremental" (future)
}

#[derive(Debug, serde::Serialize)]
pub struct IndexResult {
    pub success: bool,
    pub message: String,
    pub job_id: Option<String>,
}

/// Launch indexing job with given configuration (ORDER 37)
///
/// This is the canonical entry point for indexing execution.
/// Used by both Tauri commands and flow_manager.
///
/// # Returns
/// * `Ok(IndexResult)` - indexing launched or validation failed
/// * `Err(String)` - internal error (status read failed, etc.)
pub async fn run_indexing(
    _app_handle: &AppHandle,
    config: IndexConfig,
) -> Result<IndexResult, String> {
    // Validation 1: Get project root (path-agnostic - ORDER 16)
    let project_root = std::env::var("WORLD_OLLAMA_ROOT")
        .unwrap_or_else(|_| {
            // Fallback: executable is at PROJECT_ROOT/client/src-tauri/target/debug/app.exe
            // We need to go up: debug → target → src-tauri → client → PROJECT_ROOT
            std::env::current_exe()
                .ok()
                .and_then(|p| {
                    p.parent()  // debug
                        .and_then(|p| p.parent())  // target
                        .and_then(|p| p.parent())  // src-tauri
                        .and_then(|p| p.parent())  // client
                        .and_then(|p| p.parent())  // PROJECT_ROOT
                        .map(|p| p.to_string_lossy().to_string())
                })
                .unwrap_or_else(|| ".".to_string())
        });

    // Validation 2: Check PowerShell script exists
    let script_path = format!("{}/scripts/ingest_watcher.ps1", project_root);
    
    if !std::path::Path::new(&script_path).exists() {
        return Ok(IndexResult {
            success: false,
            message: format!("Indexing script not found: {}", script_path),
            job_id: None,
        });
    }

    // Validation 3: Validate dataset path
    let dataset = config.data_root
        .unwrap_or_else(|| format!("{}/library/raw_documents", project_root));

    if !std::path::Path::new(&dataset).exists() {
        return Ok(IndexResult {
            success: false,
            message: format!("Dataset path not found: {}", dataset),
            job_id: None,
        });
    }

    // Generate Job ID
    let job_id = format!("index-{}", Utc::now().format("%Y%m%d-%H%M%S"));

    // Launch PowerShell indexing script (v0.3.0 - wraps existing implementation)
    // Future (v0.3.1+): Direct Python call for better control
    let result = Command::new("powershell")
        .args(&[
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-File", &script_path,
            "-DetailedOutput"
        ])
        .spawn();

    match result {
        Ok(_child) => Ok(IndexResult {
            success: true,
            message: format!("Indexing started: dataset={}, job_id={}", dataset, job_id),
            job_id: Some(job_id),
        }),
        Err(e) => Ok(IndexResult {
            success: false,
            message: format!("Failed to start indexing: {}", e),
            job_id: None,
        }),
    }
}
