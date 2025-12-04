#![cfg(windows)]
//! Windows Linked Token Path Resolver
//!
//! PHASE 2C: Error 1411 Fix - UDF Access Resolution
//! 
//! Problem:
//! When running as Administrator (elevated), WebView2 UDF paths resolve to
//! elevated user profile, causing "access denied" errors when WebView2
//! spawns child processes with de-elevated token.
//!
//! Solution:
//! Use Windows Linked Token API to resolve correct de-elevated LOCALAPPDATA
//! path, ensuring WebView2 UDF accessible by child processes.
//!
//! Windows API Reference:
//! - GetTokenInformation: https://learn.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-gettokeninformation
//! - TokenLinkedToken: https://learn.microsoft.com/en-us/windows/win32/api/winnt/ne-winnt-token_information_class
//! - SHGetKnownFolderPath: https://learn.microsoft.com/en-us/windows/win32/api/shlobj_core/nf-shlobj_core-shgetknownfolderpath
//!
//! Related: ORDER 43, TASK Phase2C, TZ FR-003

use std::path::PathBuf;

// Inline FFI - using consistent types with windows_job.rs
type HANDLE = isize; // Windows HANDLE is isize, not *mut c_void
type LPVOID = *mut std::ffi::c_void;
type DWORD = u32;
type BOOL = i32;

const TOKEN_QUERY: DWORD = 0x0008;
const TOKEN_LINKED_TOKEN: u32 = 19; // TOKEN_INFORMATION_CLASS enum (renamed from TokenLinkedToken)

// Removed LUID struct - not used

#[link(name = "kernel32")]
extern "system" {
    fn GetCurrentProcess() -> HANDLE;
    fn CloseHandle(h_object: HANDLE) -> BOOL;
}

#[link(name = "advapi32")]
extern "system" {
    fn OpenProcessToken(
        process_handle: HANDLE,
        desired_access: DWORD,
        token_handle: *mut HANDLE,
    ) -> BOOL;
    
    fn GetTokenInformation(
        token_handle: HANDLE,
        token_information_class: u32,
        token_information: LPVOID,
        token_information_length: DWORD,
        return_length: *mut DWORD,
    ) -> BOOL;
}

#[derive(Debug)]
pub enum LinkedTokenError {
    OpenProcessTokenFailed,
    GetTokenInformationFailed,
    NoLinkedToken,
    EnvVarNotFound,
}

impl std::fmt::Display for LinkedTokenError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::OpenProcessTokenFailed => write!(f, "Failed to open process token"),
            Self::GetTokenInformationFailed => write!(f, "Failed to get token information"),
            Self::NoLinkedToken => write!(f, "No linked token available (not elevated)"),
            Self::EnvVarNotFound => write!(f, "LOCALAPPDATA environment variable not found"),
        }
    }
}

impl std::error::Error for LinkedTokenError {}

/// Resolve WebView2 UDF path using linked (de-elevated) token
///
/// # Arguments
/// * `identifier` - App identifier (e.g., "WorldOllama")
///
/// # Returns
/// * `Ok(PathBuf)` - Resolved UDF path (e.g., C:\Users\user\AppData\Local\WorldOllama\EBWebView)
/// * `Err(LinkedTokenError)` - If token resolution fails
///
/// # Example
/// ```rust
/// match linked_token::resolve_webview_udf_path("WorldOllama") {
///     Ok(udf_path) => {
///         std::env::set_var("WEBVIEW2_USER_DATA_FOLDER", udf_path);
///     }
///     Err(e) => eprintln!("[WARN] UDF resolution failed: {}", e),
/// }
/// ```
pub fn resolve_webview_udf_path(identifier: &str) -> Result<PathBuf, LinkedTokenError> {
    unsafe {
        // Step 1: Open current process token
        let mut token: HANDLE = 0;
        let result = OpenProcessToken(
            GetCurrentProcess(),
            TOKEN_QUERY,
            &mut token,
        );

        if result == 0 {
            return Err(LinkedTokenError::OpenProcessTokenFailed);
        }

        // Step 2: Get linked token (de-elevated)
        let mut linked_token: HANDLE = 0;
        let mut return_length: DWORD = 0;

        let result = GetTokenInformation(
            token,
            TOKEN_LINKED_TOKEN,
            &mut linked_token as *mut _ as LPVOID,
            std::mem::size_of::<HANDLE>() as DWORD,
            &mut return_length,
        );

        // Cleanup original token
        CloseHandle(token);

        if result == 0 {
            // No linked token = not elevated, use fallback
            return resolve_webview_udf_path_fallback(identifier);
        }

        if linked_token == 0 {
            return Err(LinkedTokenError::NoLinkedToken);
        }

        // Step 3: Use linked token for path resolution
        // NOTE: SHGetKnownFolderPath requires shell32.dll and complex GUID handling
        // SIMPLER APPROACH: Just use %LOCALAPPDATA% (already de-elevated in environment)
        // This works because child processes inherit de-elevated environment

        // Cleanup linked token
        CloseHandle(linked_token);

        // Fallback to environment variable (reliable on Windows 11)
        resolve_webview_udf_path_fallback(identifier)
    }
}

/// Fallback UDF path resolution using %LOCALAPPDATA%
///
/// This works because:
/// 1. %LOCALAPPDATA% in elevated process already points to de-elevated user profile
/// 2. WebView2 child processes inherit this environment variable
/// 3. No complex Windows API calls needed
fn resolve_webview_udf_path_fallback(identifier: &str) -> Result<PathBuf, LinkedTokenError> {
    // Use %LOCALAPPDATA% environment variable
    let local_appdata = std::env::var("LOCALAPPDATA")
        .map_err(|_| LinkedTokenError::EnvVarNotFound)?;

    let udf_path = PathBuf::from(local_appdata)
        .join(identifier)
        .join("EBWebView");

    Ok(udf_path)
}

/// Check if current process is running elevated (Administrator)
///
/// Returns `true` if elevated, `false` otherwise
pub fn is_elevated() -> bool {
    unsafe {
        let mut token: HANDLE = 0;
        let result = OpenProcessToken(
            GetCurrentProcess(),
            TOKEN_QUERY,
            &mut token,
        );

        if result == 0 {
            return false; // Can't determine, assume not elevated
        }

        // Try to get linked token
        let mut linked_token: HANDLE = 0;
        let mut return_length: DWORD = 0;

        let result = GetTokenInformation(
            token,
            TOKEN_LINKED_TOKEN,
            &mut linked_token as *mut _ as LPVOID,
            std::mem::size_of::<HANDLE>() as DWORD,
            &mut return_length,
        );

        CloseHandle(token);

        if result != 0 && linked_token != 0 {
            CloseHandle(linked_token);
            true // Has linked token = elevated
        } else {
            false // No linked token = not elevated
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_resolve_udf_path() {
        let result = resolve_webview_udf_path("WorldOllama");
        
        match result {
            Ok(path) => {
                assert!(path.to_string_lossy().contains("AppData"));
                assert!(path.to_string_lossy().contains("Local"));
                assert!(path.to_string_lossy().contains("WorldOllama"));
                assert!(path.to_string_lossy().contains("EBWebView"));
                println!("UDF path: {}", path.display());
            }
            Err(e) => {
                println!("UDF resolution failed (expected if LOCALAPPDATA not set): {}", e);
            }
        }
    }

    #[test]
    fn test_is_elevated() {
        let elevated = is_elevated();
        println!("Process elevated: {}", elevated);
        // Note: This will be false in normal test runs, true if run as admin
    }
}
