/// ORDER 37: INDEX Command Public API
///
/// Single entry point for all indexing operations.
/// Used by both Tauri commands and flow_manager.
///
/// Design mirrors training_manager.rs (ORDER 36) for consistency.

use tauri::AppHandle;
use std::process::Command;
use std::path::PathBuf;  // ORDER 37-FIX
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
    // Validation 1: Get project root (ORDER 37-FIX - robust path resolution)
    let project_root = crate::utils::get_project_root();



    // Validation 2: Check PowerShell script exists
    let script_path = project_root.join("scripts").join("ingest_watcher.ps1");
    
    if !script_path.exists() {
        return Ok(IndexResult {
            success: false,
            message: format!("Indexing script not found: {}", script_path.display()),
            job_id: None,
        });
    }

    // Validation 3: Validate dataset path
    let dataset = config.data_root
        .map(PathBuf::from)
        .unwrap_or_else(|| project_root.join("library").join("raw_documents"));

    if !dataset.exists() {
        return Ok(IndexResult {
            success: false,
            message: format!("Dataset path not found: {}", dataset.display()),
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
            "-File", &script_path.to_string_lossy(),
            "-DetailedOutput"
        ])
        .spawn();

    match result {
        Ok(_child) => Ok(IndexResult {
            success: true,
            message: format!("Indexing started: dataset={}, job_id={}", dataset.display(), job_id),
            job_id: Some(job_id),
        }),
        Err(e) => Ok(IndexResult {
            success: false,
            message: format!("Failed to start indexing: {}", e),
            job_id: None,
        }),
    }
}
