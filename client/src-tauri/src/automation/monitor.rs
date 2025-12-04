// File System Monitor (ЭТАП 1) - Простой watcher для логов
// Использует notify для отслеживания изменений

use log::{info, warn};
use notify::{RecommendedWatcher, RecursiveMode, Watcher, Event};
use std::path::Path;
use std::sync::mpsc::{channel, Receiver};

/// ЭТАП 1: Простая команда - запустить watcher для logs/
pub fn start_log_watcher(path: &str) -> Result<(RecommendedWatcher, Receiver<notify::Result<Event>>), Box<dyn std::error::Error>> {
    info!("Starting file system watcher for: {}", path);
    
    let (tx, rx) = channel();
    
    let mut watcher = RecommendedWatcher::new(
        move |res| {
            if let Err(e) = tx.send(res) {
                warn!("Watcher send error: {}", e);
            }
        },
        notify::Config::default(),
    )?;
    
    watcher.watch(Path::new(path), RecursiveMode::Recursive)?;
    
    info!("Watcher started successfully");
    Ok((watcher, rx))
}

/// ЭТАП 1: Placeholder для расширенного мониторинга (ЭТАП 2)
pub fn start_watcher(_path: &str) -> Result<(), Box<dyn std::error::Error>> {
    warn!("start_watcher deprecated - use start_log_watcher instead");
    Err("Use start_log_watcher".into())
}
