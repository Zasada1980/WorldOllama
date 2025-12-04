#![cfg(windows)]

use std::ptr::null_mut;

// Raw Windows API bindings (inline FFI)
type HANDLE = isize;
type BOOL = i32;
type DWORD = u32;
type LPVOID = *mut std::ffi::c_void;
type LPCWSTR = *const u16;

#[repr(C)]
struct JOBOBJECT_BASIC_LIMIT_INFORMATION {
    PerProcessUserTimeLimit: i64,
    PerJobUserTimeLimit: i64,
    LimitFlags: DWORD,
    MinimumWorkingSetSize: usize,
    MaximumWorkingSetSize: usize,
    ActiveProcessLimit: DWORD,
    Affinity: usize,
    PriorityClass: DWORD,
    SchedulingClass: DWORD,
}

#[repr(C)]
struct IO_COUNTERS {
    ReadOperationCount: u64,
    WriteOperationCount: u64,
    OtherOperationCount: u64,
    ReadTransferCount: u64,
    WriteTransferCount: u64,
    OtherTransferCount: u64,
}

#[repr(C)]
struct JOBOBJECT_EXTENDED_LIMIT_INFORMATION {
    BasicLimitInformation: JOBOBJECT_BASIC_LIMIT_INFORMATION,
    IoInfo: IO_COUNTERS,
    ProcessMemoryLimit: usize,
    JobMemoryLimit: usize,
    PeakProcessMemoryUsed: usize,
    PeakJobMemoryUsed: usize,
}

const JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE: DWORD = 0x00002000;
const JobObjectExtendedLimitInformation: i32 = 9;
const FALSE: BOOL = 0;

#[link(name = "kernel32")]
extern "system" {
    fn CreateJobObjectW(lpJobAttributes: LPVOID, lpName: LPCWSTR) -> HANDLE;
    fn AssignProcessToJobObject(hJob: HANDLE, hProcess: HANDLE) -> BOOL;
    fn SetInformationJobObject(
        hJob: HANDLE,
        JobObjectInformationClass: i32,
        lpJobObjectInformation: LPVOID,
        cbJobObjectInformationLength: DWORD,
    ) -> BOOL;
    fn CloseHandle(hObject: HANDLE) -> BOOL;
    fn GetCurrentProcess() -> HANDLE;
}

/// Windows Job Object wrapper
/// 
/// Ensures all child processes (WebView2) are killed when parent exits.
/// 
/// # Example
/// ```rust
/// let job = JobObject::new()?;
/// job.assign_current_process()?;
/// // ... rest of app logic ...
/// // On drop: CloseHandle → kills all children
/// ```
pub struct JobObject {
    handle: HANDLE,
}

#[derive(Debug)]
pub struct JobObjectError(String);

impl std::fmt::Display for JobObjectError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "Job Object Error: {}", self.0)
    }
}

impl std::error::Error for JobObjectError {}

impl JobObject {
    /// Create new Job Object with KILL_ON_JOB_CLOSE flag
    pub fn new() -> Result<Self, JobObjectError> {
        unsafe {
            // Step 1: Create Job Object (unnamed)
            let handle = CreateJobObjectW(null_mut(), null_mut());
            if handle == 0 || handle == -1 {
                return Err(JobObjectError("CreateJobObjectW failed".to_string()));
            }

            // Step 2: Configure limits
            let mut info: JOBOBJECT_EXTENDED_LIMIT_INFORMATION = std::mem::zeroed();
            info.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;

            // Step 3: Apply configuration
            let result = SetInformationJobObject(
                handle,
                JobObjectExtendedLimitInformation,
                &mut info as *mut _ as LPVOID,
                std::mem::size_of::<JOBOBJECT_EXTENDED_LIMIT_INFORMATION>() as DWORD,
            );

            if result == FALSE {
                CloseHandle(handle);
                return Err(JobObjectError("SetInformationJobObject failed".to_string()));
            }

            Ok(Self { handle })
        }
    }

    /// Assign current process to Job Object
    /// 
    /// All future child processes will inherit this assignment.
    pub fn assign_current_process(&self) -> Result<(), JobObjectError> {
        unsafe {
            let result = AssignProcessToJobObject(self.handle, GetCurrentProcess());
            if result == FALSE {
                return Err(JobObjectError("AssignProcessToJobObject failed".to_string()));
            }
            Ok(())
        }
    }

    /// Get raw handle (for advanced usage)
    #[allow(dead_code)]
    pub fn handle(&self) -> HANDLE {
        self.handle
    }
}

impl Drop for JobObject {
    fn drop(&mut self) {
        unsafe {
            // CloseHandle triggers KILL_ON_JOB_CLOSE
            // All child processes (WebView2) are terminated
            CloseHandle(self.handle);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_job_object_creation() {
        let job = JobObject::new().expect("Failed to create Job Object");
        assert!(job.handle() != 0 && job.handle() != -1);
    }

    #[test]
    fn test_job_object_assignment() {
        let job = JobObject::new().expect("Failed to create Job Object");
        job.assign_current_process().expect("Failed to assign process");
        // If we reach here, assignment succeeded
    }

    #[test]
    fn test_job_object_drop() {
        {
            let _job = JobObject::new().expect("Failed to create Job Object");
            // Job dropped at end of scope
        }
        // If no crash, Drop implementation worked
    }
}
