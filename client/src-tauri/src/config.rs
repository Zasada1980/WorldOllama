use std::env;

/// Конфигурация для подключения к Ollama и CORTEX
pub struct AppConfig {
    pub ollama_base_url: String,
    pub cortex_base_url: String,
    pub cortex_api_key: String,
}

impl AppConfig {
    pub fn from_env() -> Self {
        Self {
            ollama_base_url: env::var("OLLAMA_BASE_URL")
                .unwrap_or_else(|_| "http://127.0.0.1:11434".to_string()),
            cortex_base_url: env::var("CORTEX_BASE_URL")
                .unwrap_or_else(|_| "http://127.0.0.1:8004".to_string()),
            cortex_api_key: env::var("CORTEX_API_KEY")
                .unwrap_or_else(|_| "sesa-secure-core-v1".to_string()), // TODO: убрать hardcode в production
        }
    }
}

impl Default for AppConfig {
    fn default() -> Self {
        Self::from_env()
    }
}
