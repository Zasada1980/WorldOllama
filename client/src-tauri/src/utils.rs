/// Utility functions for project-wide path resolution
/// 
/// ORDER 37-FIX: Robust project root detection to replace
/// fragile current_exe() + 5-parent traversal approach

use std::path::{Path, PathBuf};

/// Get project root directory with robust fallback strategy
/// 
/// Priority order:
/// 1. WORLD_OLLAMA_ROOT environment variable (explicit override)
/// 2. Walk up from executable looking for project markers
/// 3. Current working directory (last resort)
/// 
/// # Returns
/// PathBuf to project root (guaranteed to return something)
/// 
/// # Examples
/// ```
/// use tauri_fresh::utils::get_project_root;
/// 
/// let root = get_project_root();
/// let scripts = root.join("scripts");
/// ```
pub fn get_project_root() -> PathBuf {
    // Priority 1: Explicit environment variable
    if let Ok(root) = std::env::var("WORLD_OLLAMA_ROOT") {
        let path = PathBuf::from(&root);
        if path.exists() {
            log::info!("[PATH] Using WORLD_OLLAMA_ROOT: {}", root);
            return path;
        } else {
            log::warn!("[PATH] WORLD_OLLAMA_ROOT set but path doesn't exist: {}", root);
        }
    }
    
    // Priority 2: Walk up from executable location
    if let Ok(exe) = std::env::current_exe() {
        let mut current = exe.as_path();
        
        // Walk up maximum 10 levels to find project root
        for level in 0..10 {
            if let Some(parent) = current.parent() {
                if is_project_root(parent) {
                    log::info!(
                        "[PATH] Found project root {} levels up from exe: {}",
                        level + 1,
                        parent.display()
                    );
                    return parent.to_path_buf();
                }
                current = parent;
            } else {
                break;
            }
        }
        
        log::warn!("[PATH] No project markers found walking up from exe");
    }
    
    // Priority 3: Current working directory
    let cwd = std::env::current_dir().unwrap_or_else(|_| {
        log::error!("[PATH] Could not get CWD, falling back to '.'");
        PathBuf::from(".")
    });
    
    log::info!("[PATH] Using current working directory: {}", cwd.display());
    cwd
}

/// Check if a directory is the project root by looking for marker files
/// 
/// Markers checked (in order of priority):
/// 1. WORLD_OLLAMA_LAUNCH.ps1 (highly specific to this project)
/// 2. client/src-tauri directory (Tauri project structure)
/// 3. README.md + services directory (project structure)
fn is_project_root(path: &Path) -> bool {
    // Marker 1: Launch script (most specific)
    if path.join("WORLD_OLLAMA_LAUNCH.ps1").exists() {
        return true;
    }
    
    // Marker 2: Tauri project structure
    if path.join("client").join("src-tauri").exists() {
        return true;
    }
    
    // Marker 3: General project structure
    if path.join("README.md").exists() && path.join("services").exists() {
        return true;
    }
    
    false
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_get_project_root_with_env() {
        // Set env var to a known path
        std::env::set_var("WORLD_OLLAMA_ROOT", "E:/WORLD_OLLAMA");
        
        let root = get_project_root();
        let root_str = root.to_string_lossy();
        
        // Should use the env var
        assert!(
            root_str.contains("WORLD_OLLAMA"),
            "Expected project root to contain WORLD_OLLAMA, got: {}",
            root_str
        );
        
        // Clean up
        std::env::remove_var("WORLD_OLLAMA_ROOT");
    }

    #[test]
    fn test_is_project_root_with_launch_script() {
        let project_root = PathBuf::from("E:/WORLD_OLLAMA");
        
        // This test assumes we're actually in the project
        // Skip if the path doesn't exist (e.g., CI environment)
        if project_root.exists() {
            assert!(
                is_project_root(&project_root),
                "Project root should be detected via markers"
            );
        }
    }

    #[test]
    fn test_is_project_root_negative() {
        let temp_dir = std::env::temp_dir();
        
        // Temp directory should NOT be detected as project root
        assert!(
            !is_project_root(&temp_dir),
            "Temp directory should not be project root"
        );
    }
}
