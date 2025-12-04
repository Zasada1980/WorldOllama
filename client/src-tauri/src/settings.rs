use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppSettings {
    pub ollama_model: String,
    pub max_tokens: Option<u32>,
    pub cortex_top_k: u32,
    pub cortex_mode: String,
    pub active_agent_profile: String,
}

impl Default for AppSettings {
    fn default() -> Self {
        Self {
            ollama_model: "mistral-small".to_string(),
            max_tokens: None,
            cortex_top_k: 20,
            cortex_mode: "local".to_string(),
            active_agent_profile: "triz_engineer".to_string(),
        }
    }
}

/// Получить путь к файлу настроек в AppData директории
pub fn get_settings_path() -> Result<PathBuf, String> {
    // Для Windows: %APPDATA%\tauri_fresh\settings.json
    // Для Linux: ~/.config/tauri_fresh/settings.json
    // Для macOS: ~/Library/Application Support/tauri_fresh/settings.json
    
    let app_data_dir = dirs::data_dir()
        .ok_or_else(|| "Не удалось определить директорию AppData".to_string())?;
    
    let app_dir = app_data_dir.join("tauri_fresh");
    
    // Создать директорию если её нет
    if !app_dir.exists() {
        fs::create_dir_all(&app_dir)
            .map_err(|e| format!("Не удалось создать директорию настроек: {}", e))?;
    }
    
    Ok(app_dir.join("settings.json"))
}

/// Загрузить настройки из файла (или вернуть Default если файла нет)
pub fn load_settings() -> AppSettings {
    match get_settings_path() {
        Ok(path) => {
            if path.exists() {
                match fs::read_to_string(&path) {
                    Ok(content) => {
                        match serde_json::from_str::<AppSettings>(&content) {
                            Ok(settings) => settings,
                            Err(e) => {
                                eprintln!("Ошибка парсинга настроек: {}. Используем дефолт.", e);
                                AppSettings::default()
                            }
                        }
                    }
                    Err(e) => {
                        eprintln!("Ошибка чтения файла настроек: {}. Используем дефолт.", e);
                        AppSettings::default()
                    }
                }
            } else {
                // Файла нет — создаём с дефолтными значениями
                let default_settings = AppSettings::default();
                let _ = save_settings(&default_settings); // Игнорируем ошибку при создании
                default_settings
            }
        }
        Err(e) => {
            eprintln!("Ошибка получения пути настроек: {}. Используем дефолт.", e);
            AppSettings::default()
        }
    }
}

/// Сохранить настройки в файл
pub fn save_settings(settings: &AppSettings) -> Result<(), String> {
    let path = get_settings_path()?;
    
    let json_content = serde_json::to_string_pretty(settings)
        .map_err(|e| format!("Ошибка сериализации настроек: {}", e))?;
    
    fs::write(&path, json_content)
        .map_err(|e| format!("Ошибка записи настроек в файл: {}", e))?;
    
    Ok(())
}
