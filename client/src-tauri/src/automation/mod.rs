// Desktop Automation Module
// ЭТАП 1 - Basic Implementation (FULL_AUTOMATION_ROADMAP.md)
//
// Инструмент для агента VS Code консоли:
// - Минимальные команды для тестирования UI
// - Простые функции без сложной логики

use log::{info, warn};
use serde::{Deserialize, Serialize};

pub mod visualizer;
pub mod executor;
pub mod monitor;

#[cfg(test)]
mod tests;

#[derive(Debug, Serialize, Deserialize)]
pub struct ScreenState {
    pub timestamp: String,
    pub screens_available: usize,
    pub active_monitors: Vec<String>,
}

/// Initialize automation subsystem
pub fn init() -> Result<(), Box<dyn std::error::Error>> {
    info!("Desktop Automation module initialized (ЭТАП 1)");
    
    // Проверка доступности crates
    let screens = screenshots::Screen::all()?;
    info!("Detected {} screen(s)", screens.len());
    
    Ok(())
}

/// ЭТАП 1: Простая команда для агента - получить состояние экрана
pub fn get_screen_state() -> Result<ScreenState, Box<dyn std::error::Error>> {
    let screens = screenshots::Screen::all()?;
    let timestamp = chrono::Utc::now().to_rfc3339();
    
    let active_monitors: Vec<String> = screens.iter()
        .enumerate()
        .map(|(i, s)| format!("Monitor {} ({}x{})", i, s.display_info.width, s.display_info.height))
        .collect();
    
    Ok(ScreenState {
        timestamp,
        screens_available: screens.len(),
        active_monitors,
    })
}

/// ЭТАП 1: Простая команда для агента - сделать скриншот
pub fn capture_screenshot(monitor_index: usize) -> Result<Vec<u8>, Box<dyn std::error::Error>> {
    use image::ImageEncoder;
    use std::io::Cursor;
    
    let screens = screenshots::Screen::all()?;
    
    if monitor_index >= screens.len() {
        return Err(format!("Monitor {} not found (available: {})", monitor_index, screens.len()).into());
    }
    
    let screen = &screens[monitor_index];
    let image = screen.capture()?;
    
    // Конвертируем в PNG bytes
    let mut buffer = Cursor::new(Vec::new());
    let encoder = image::codecs::png::PngEncoder::new(&mut buffer);
    encoder.write_image(
        image.as_raw(),
        image.width(),
        image.height(),
        image::ColorType::Rgba8,
    )?;
    
    Ok(buffer.into_inner())
}

/// ЭТАП 1: Placeholder для mouse/keyboard (будет реализовано в executor.rs)
pub fn simulate_input(_action: &str) -> Result<(), Box<dyn std::error::Error>> {
    warn!("simulate_input not fully implemented - use executor module");
    Err("Not implemented".into())
}
