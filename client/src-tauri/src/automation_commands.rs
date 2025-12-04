// Automation Commands для Tauri - ЭТАП 1
// Простые команды для агента консоли VS Code

use crate::automation;
use serde::{Deserialize, Serialize};
use tauri::command;

#[derive(Debug, Serialize, Deserialize)]
pub struct ApiResponse<T> {
    pub success: bool,
    pub data: Option<T>,
    pub error: Option<String>,
}

/// ЭТАП 1: Команда для агента - получить состояние экранов
#[command]
pub async fn automation_get_screen_state() -> Result<ApiResponse<automation::ScreenState>, String> {
    match automation::get_screen_state() {
        Ok(state) => Ok(ApiResponse {
            success: true,
            data: Some(state),
            error: None,
        }),
        Err(e) => Ok(ApiResponse {
            success: false,
            data: None,
            error: Some(e.to_string()),
        }),
    }
}

/// ЭТАП 1: Команда для агента - сделать скриншот
#[command]
pub async fn automation_capture_screenshot(monitor_index: usize) -> Result<ApiResponse<Vec<u8>>, String> {
    match automation::capture_screenshot(monitor_index) {
        Ok(png_bytes) => Ok(ApiResponse {
            success: true,
            data: Some(png_bytes),
            error: None,
        }),
        Err(e) => Ok(ApiResponse {
            success: false,
            data: None,
            error: Some(e.to_string()),
        }),
    }
}

/// ЭТАП 1: Команда для агента - клик мышью
#[command]
pub async fn automation_click(x: i32, y: i32) -> Result<ApiResponse<String>, String> {
    match automation::executor::click_at(x, y) {
        Ok(_) => Ok(ApiResponse {
            success: true,
            data: Some(format!("Clicked at ({}, {})", x, y)),
            error: None,
        }),
        Err(e) => Ok(ApiResponse {
            success: false,
            data: None,
            error: Some(e.to_string()),
        }),
    }
}

/// ЭТАП 1: Команда для агента - ввести текст
#[command]
pub async fn automation_type_text(text: String) -> Result<ApiResponse<String>, String> {
    match automation::executor::type_text(&text) {
        Ok(_) => Ok(ApiResponse {
            success: true,
            data: Some(format!("Typed: {}", text)),
            error: None,
        }),
        Err(e) => Ok(ApiResponse {
            success: false,
            data: None,
            error: Some(e.to_string()),
        }),
    }
}

/// ЭТАП 1: Команда для агента - получить активные окна
#[command]
pub async fn automation_get_windows() -> Result<ApiResponse<Vec<automation::visualizer::WindowInfo>>, String> {
    match automation::visualizer::get_active_windows() {
        Ok(windows) => Ok(ApiResponse {
            success: true,
            data: Some(windows),
            error: None,
        }),
        Err(e) => Ok(ApiResponse {
            success: false,
            data: None,
            error: Some(e.to_string()),
        }),
    }
}
