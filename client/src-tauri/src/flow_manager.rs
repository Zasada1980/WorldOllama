use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use std::io::Write;
use tauri::{AppHandle, Manager, Emitter};
use chrono::Utc;

// ==================================================================================
// FLOW MANAGER - ORDER 35 + ORDER 36 + ORDER 37 + ORDER 38 (v0.3.0)
// ==================================================================================
//
// NOTE: Flows v1 supports STATUS, GIT_PUSH, TRAIN, and INDEX commands.
//       ORDER 38: Added runtime logging for observability.
//
// ==================================================================================

// ==================================================================================
// ORDER 38 - FLOW RUNTIME LOGGING
// ==================================================================================

/// Log entry for flow execution (JSON Lines format)
#[derive(Debug, Serialize)]
struct FlowLogEntry {
    timestamp: i64,
    flow_id: String,
    run_id: String,
    step_id: Option<String>,
    cmd: Option<String>,
    status: String,  // "started" | "success" | "error"
    message: String,
    error: Option<String>,
}

/// Logger for flow execution (ORDER 38)
struct FlowLogger {
    log_path: PathBuf,
    flow_id: String,
    run_id: String,
}

impl FlowLogger {
    fn new(flow_id: &str) -> Result<Self, String> {
        let run_id = format!("{}", Utc::now().timestamp());
        let project_root = Self::get_project_root()?;
        
        let log_dir = PathBuf::from(project_root)
            .join("logs")
            .join("flows");
        
        fs::create_dir_all(&log_dir)
            .map_err(|e| format!("Failed to create log directory: {}", e))?;
        
        let timestamp = Utc::now().format("%Y%m%d_%H%M%S");
        let filename = format!("flow_{}_{}.jsonl", flow_id, timestamp);
        let log_path = log_dir.join(filename);
        
        Ok(Self {
            log_path,
            flow_id: flow_id.to_string(),
            run_id,
        })
    }
    
    fn get_project_root() -> Result<String, String> {
        std::env::var("WORLD_OLLAMA_ROOT")
            .or_else(|_| {
                std::env::current_exe()
                    .ok()
                    .and_then(|p| {
                        p.parent()
                            .and_then(|p| p.parent())
                            .and_then(|p| p.parent())
                            .and_then(|p| p.parent())
                            .and_then(|p| p.parent())
                            .map(|p| p.to_string_lossy().to_string())
                    })
                    .ok_or_else(|| "Failed to determine project root".to_string())
            })
    }
    
    fn log(&self, entry: FlowLogEntry) -> Result<(), String> {
        let json = serde_json::to_string(&entry)
            .map_err(|e| format!("Failed to serialize: {}", e))?;
        
        let mut file = fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.log_path)
            .map_err(|e| format!("Failed to open log: {}", e))?;
        
        writeln!(file, "{}", json)
            .map_err(|e| format!("Failed to write: {}", e))?;
        
        Ok(())
    }
    
    fn log_flow_start(&self) -> Result<(), String> {
        self.log(FlowLogEntry {
            timestamp: Utc::now().timestamp(),
            flow_id: self.flow_id.clone(),
            run_id: self.run_id.clone(),
            step_id: None,
            cmd: None,
            status: "started".to_string(),
            message: format!("Flow '{}' started", self.flow_id),
            error: None,
        })
    }
    
    fn log_step_start(&self, step_id: &str, cmd: &str) -> Result<(), String> {
        self.log(FlowLogEntry {
            timestamp: Utc::now().timestamp(),
            flow_id: self.flow_id.clone(),
            run_id: self.run_id.clone(),
            step_id: Some(step_id.to_string()),
            cmd: Some(cmd.to_string()),
            status: "started".to_string(),
            message: format!("Step {} ({}) started", step_id, cmd),
            error: None,
        })
    }
    
    fn log_step_success(&self, step_id: &str, cmd: &str, result_msg: &str) -> Result<(), String> {
        self.log(FlowLogEntry {
            timestamp: Utc::now().timestamp(),
            flow_id: self.flow_id.clone(),
            run_id: self.run_id.clone(),
            step_id: Some(step_id.to_string()),
            cmd: Some(cmd.to_string()),
            status: "success".to_string(),
            message: result_msg.to_string(),
            error: None,
        })
    }
    
    fn log_step_error(&self, step_id: &str, cmd: &str, error_msg: &str) -> Result<(), String> {
        self.log(FlowLogEntry {
            timestamp: Utc::now().timestamp(),
            flow_id: self.flow_id.clone(),
            run_id: self.run_id.clone(),
            step_id: Some(step_id.to_string()),
            cmd: Some(cmd.to_string()),
            status: "error".to_string(),
            message: format!("Step {} ({}) failed", step_id, cmd),
            error: Some(error_msg.to_string()),
        })
    }
    
    fn log_flow_complete(&self, success: bool, message: &str) -> Result<(), String> {
        self.log(FlowLogEntry {
            timestamp: Utc::now().timestamp(),
            flow_id: self.flow_id.clone(),
            run_id: self.run_id.clone(),
           step_id: None,
            cmd: None,
            status: if success { "success" } else { "error" }.to_string(),
            message: message.to_string(),
            error: if success { None } else { Some(message.to_string()) },
        })
    }
}

// ==================================================================================
// ORDER 38 КОМАНДА 2 - FLOW HISTORY
// ==================================================================================

/// Summary of a flow execution for history display
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FlowRunSummary {
    pub flow_id: String,
    pub run_id: String,
    pub started_at: i64,
    pub finished_at: Option<i64>,
    pub status: String,  // "success" | "error" | "running"
    pub total_steps: usize,
    pub failed_step: Option<String>,
}

// ==================================================================================
// FLOW DATA STRUCTURES
// ==================================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Flow {
    pub id: String,
    pub name: String,
    pub description: String,
    pub steps: Vec<FlowStep>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FlowStep {
    pub id: String,
    pub cmd: String,
    pub args: serde_json::Value,
    pub on_failure: FailurePolicy,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum FailurePolicy {
    Abort,
    Continue,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FlowStatus {
    pub is_running: bool,
    pub current_flow_id: Option<String>,
    pub current_step_index: Option<usize>,
    pub total_steps: Option<usize>,
    pub last_error: Option<String>,
    pub logs: Vec<String>,
}

impl Default for FlowStatus {
    fn default() -> Self {
        Self {
            is_running: false,
            current_flow_id: None,
            current_step_index: None,
            total_steps: None,
            last_error: None,
            logs: Vec::new(),
        }
    }
}

// ==================================================================================
// FLOW MANAGER
// ==================================================================================

pub struct FlowManager {
    storage_path: PathBuf,
    status: Arc<Mutex<FlowStatus>>,
    app_handle: AppHandle,
}

impl FlowManager {
    pub fn new(app_handle: AppHandle) -> Self {
        let project_root = std::env::var("WORLD_OLLAMA_ROOT")
            .unwrap_or_else(|_| std::env::current_exe()
                .ok()
                .and_then(|p| p.parent().and_then(|p| p.parent()).map(|p| p.to_string_lossy().to_string()))
                .unwrap_or_else(|| ".".to_string()));
        let storage_path = PathBuf::from(&project_root).join("automation").join("flows");
        
        if !storage_path.exists() {
            let _ = fs::create_dir_all(&storage_path);
            Self::create_default_flows(&storage_path);
        }

        Self { 
            storage_path,
            status: Arc::new(Mutex::new(FlowStatus::default())),
            app_handle,
        }
    }

    fn create_default_flows(path: &PathBuf) {
        let smoke_test = Flow {
            id: "smoke_test".to_string(),
            name: "Smoke Test Cycle".to_string(),
            description: "Quick check: Status + Dry-run Git Push".to_string(),
            steps: vec![
                FlowStep {
                    id: "step_1".to_string(),
                    cmd: "STATUS".to_string(),
                    args: serde_json::json!({}),
                    on_failure: FailurePolicy::Abort,
                },
                FlowStep {
                    id: "step_2".to_string(),
                    cmd: "GIT_PUSH".to_string(),
                    args: serde_json::json!({ "remote": "origin", "branch": "main", "dry_run": true }),
                    on_failure: FailurePolicy::Continue,
                },
            ],
        };

        if let Ok(json) = serde_json::to_string_pretty(&smoke_test) {
            let _ = fs::write(path.join("smoke_test.json"), json);
        }
    }

    pub fn load_flows(&self) -> Vec<Flow> {
        let mut flows = Vec::new();
        if let Ok(entries) = fs::read_dir(&self.storage_path) {
            for entry in entries.flatten() {
                if entry.path().extension().map_or(false, |ext| ext == "json") {
                    if let Ok(content) = fs::read_to_string(entry.path()) {
                        if let Ok(flow) = serde_json::from_str::<Flow>(&content) {
                            flows.push(flow);
                        }
                    }
                }
            }
        }
        flows
    }

    pub fn execute_flow(&self, flow_id: String) -> Result<(), String> {
        let flows = self.load_flows();
        let flow = flows.into_iter().find(|f| f.id == flow_id)
            .ok_or_else(|| format!("Flow not found: {}", flow_id))?;

        let status = self.status.clone();
        let app = self.app_handle.clone();

        {
            let mut s = status.lock().unwrap();
            if s.is_running {
                return Err("A flow is already running".to_string());
            }
            s.is_running = true;
            s.current_flow_id = Some(flow_id.clone());
            s.current_step_index = Some(0);
            s.total_steps = Some(flow.steps.len());
            s.last_error = None;
            s.logs.clear();
            s.logs.push(format!("Starting flow: {}", flow.name));
        }

        let _ = app.emit("flow_status_update", self.get_status());

        tauri::async_runtime::spawn(async move {
            Self::run_flow_logic(flow, status.clone(), app.clone()).await;
        });

        Ok(())
    }

    async fn run_flow_logic(flow: Flow, status: Arc<Mutex<FlowStatus>>, app: AppHandle) {
        // ORDER 38: Initialize logger
        let logger = match FlowLogger::new(&flow.id) {
            Ok(l) => Some(l),
            Err(e) => {
                eprintln!("Failed to create logger: {}", e);
                None  // Continue without logging
            }
        };

        // LOG: Flow start
        if let Some(ref log) = logger {
            let _ = log.log_flow_start();
        }

        for (idx, step) in flow.steps.iter().enumerate() {
            {
                let mut s = status.lock().unwrap();
                s.current_step_index = Some(idx);
                s.logs.push(format!("Step {}/{}: {} ({})", idx + 1, flow.steps.len(), step.cmd, step.id));
            }
            let _ = app.emit("flow_status_update", Self::get_status_internal(&status));

            // LOG: Step start
            if let Some(ref log) = logger {
                let _ = log.log_step_start(&step.id, &step.cmd);
            }

            let result = Self::execute_step(step, &app).await;

            if let Err(e) = result {
                // LOG: Step error
                if let Some(ref log) = logger {
                    let _ = log.log_step_error(&step.id, &step.cmd, &e);
                }

                {
                    let mut s = status.lock().unwrap();
                    s.last_error = Some(e.clone());
                    s.logs.push(format!("❌ Error in step {}: {}", step.id, e));
                }
                let _ = app.emit("flow_status_update", Self::get_status_internal(&status));

                if step.on_failure == FailurePolicy::Abort {
                    {
                        let mut s = status.lock().unwrap();
                        s.is_running = false;
                        s.logs.push("⛔ Flow aborted due to error".to_string());
                    }
                    let _ = app.emit("flow_status_update", Self::get_status_internal(&status));
                    
                    // LOG: Flow failed
                    if let Some(ref log) = logger {
                        let _ = log.log_flow_complete(false, &format!("Flow aborted at step {}", step.id));
                    }
                    return;
                }
            } else {
                // LOG: Step success
                if let Some(ref log) = logger {
                    if let Ok(ref msg) = result {
                        let _ = log.log_step_success(&step.id, &step.cmd, msg);
                    }
                }

                {
                    let mut s = status.lock().unwrap();
                    s.logs.push(format!("✅ Step {} completed", step.id));
                }
            }
        }

        {
            let mut s = status.lock().unwrap();
            s.is_running = false;
            s.current_step_index = None;
            s.logs.push("🎉 Flow completed successfully".to_string());
        }
        let _ = app.emit("flow_status_update", Self::get_status_internal(&status));

        // LOG: Flow complete
        if let Some(ref log) = logger {
            let _ = log.log_flow_complete(true, &format!("Flow completed: {} steps", flow.steps.len()));
        }
    }

    async fn execute_step(step: &FlowStep, app: &AppHandle) -> Result<String, String> {
        match step.cmd.as_str() {
            "STATUS" => Self::cmd_status(step, app).await,
            "TRAIN" => Self::cmd_train(step, app).await,
            "GIT_PUSH" => Self::cmd_git_push(step, app).await,
            "INDEX" => Self::cmd_index(step, app).await,
            _ => Err(format!("Unknown command: {}. Supported: STATUS, TRAIN, GIT_PUSH, INDEX", step.cmd))
        }
    }
    
    async fn cmd_status(_step: &FlowStep, app: &AppHandle) -> Result<String, String> {
        let app_name = app.package_info().name.clone();
        Ok(format!("System status: OK ({})", app_name))
    }

    async fn cmd_train(step: &FlowStep, app: &AppHandle) -> Result<String, String> {
        use crate::training_manager::{run_training, TrainingConfig};
        
        let profile = step.args.get("profile")
            .and_then(|v| v.as_str())
            .ok_or("TRAIN step requires 'profile' field")?
            .to_string();
        
        let dataset = step.args.get("dataset")
            .and_then(|v| v.as_str())
            .map(|s| s.to_string());
        
        let epochs = step.args.get("epochs")
            .and_then(|v| v.as_u64())
            .map(|n| n as u32);
        
        let mode = step.args.get("mode")
            .and_then(|v| v.as_str())
            .map(|s| s.to_string());
        
        let config = TrainingConfig {
            profile: profile.clone(),
            dataset,
            epochs,
            mode,
            dry_run: false,
        };
        
        match run_training(app, config).await {
            Ok(result) => {
                if result.success {
                    Ok(format!("Training started: {}", result.message))
                } else {
                    Err(format!("Training failed: {}", result.message))
                }
            },
            Err(e) => Err(format!("Training internal error: {}", e)),
        }
    }

    async fn cmd_git_push(step: &FlowStep, app: &AppHandle) -> Result<String, String> {
        use crate::git_manager::{plan_git_push, execute_git_push};
        
        let remote = step.args.get("remote")
            .and_then(|v| v.as_str())
            .unwrap_or("origin");
        
        let branch = step.args.get("branch")
            .and_then(|v| v.as_str())
            .unwrap_or("main");
        
        let dry_run = step.args.get("dry_run")
            .and_then(|v| v.as_bool())
            .unwrap_or(false);
        
        let repo_root = std::env::var("WORLD_OLLAMA_ROOT")
            .unwrap_or_else(|_| {
                std::env::current_exe()
                    .ok()
                    .and_then(|p| {
                        p.parent()
                            .and_then(|p| p.parent())
                            .and_then(|p| p.parent())
                            .and_then(|p| p.parent())
                            .and_then(|p| p.parent())
                            .map(|p| p.to_string_lossy().to_string())
                    })
                    .unwrap_or_else(|| ".".to_string())
            });
        
        let plan = plan_git_push(&repo_root, remote, branch)
            .map_err(|e| format!("Git plan failed: {}", e))?;
        
        if plan.status != "ready" {
            let reasons = if plan.blocked_reasons.is_empty() {
                vec!["Unknown reason".to_string()]
            } else {
                plan.blocked_reasons
            };
            return Err(format!("Git push blocked: {}", reasons.join(", ")));
        }
        
        if dry_run {
            return Ok(format!("Git plan: {} commits ready (dry-run, no actual push)", plan.commits.len()));
        }
        
        execute_git_push(&repo_root, remote, branch)
            .map_err(|e| format!("Git push failed: {}", e))?;
        
        Ok(format!("Git push successful: {} commits to {}/{}", plan.commits.len(), remote, branch))
    }

    async fn cmd_index(step: &FlowStep, app: &AppHandle) -> Result<String, String> {
        use crate::index_manager::{IndexConfig, run_indexing};

        let profile = step.args.get("profile")
            .and_then(|v| v.as_str())
            .map(|s| s.to_string());

        let mode = step.args.get("mode")
            .and_then(|v| v.as_str())
            .unwrap_or("full");

        let config = IndexConfig {
            profile,
            data_root: None,
            mode: Some(mode.to_string()),
        };

        let result = run_indexing(app, config).await
            .map_err(|e| format!("Indexing internal error: {}", e))?;

        if result.success {
            Ok(format!("Indexing completed: {}", result.message))
        } else {
            Err(format!("Indexing failed: {}", result.message))
        }
    }

    pub fn get_status(&self) -> FlowStatus {
        Self::get_status_internal(&self.status)
    }

    fn get_status_internal(status: &Arc<Mutex<FlowStatus>>) -> FlowStatus {
        status.lock().unwrap().clone()
    }

    /// Get flow execution history (ORDER 38 КОМАНДА 2)
    pub fn get_flow_history(limit: usize) -> Result<Vec<FlowRunSummary>, String> {
        let project_root = FlowLogger::get_project_root()?;
        let logs_dir = PathBuf::from(project_root).join("logs").join("flows");

        if !logs_dir.exists() {
            return Ok(Vec::new());
        }

        let mut runs: Vec<FlowRunSummary> = Vec::new();

        if let Ok(entries) = fs::read_dir(&logs_dir) {
            for entry in entries.flatten() {
                let path = entry.path();
                if path.extension().and_then(|s| s.to_str()) == Some("jsonl") {
                    if let Ok(summary) = Self::parse_flow_log(&path) {
                        runs.push(summary);
                    }
                }
            }
        }

        // Sort by started_at desc, take limit
        runs.sort_by(|a, b| b.started_at.cmp(&a.started_at));
        runs.truncate(limit);

        Ok(runs)
    }

    fn parse_flow_log(path: &PathBuf) -> Result<FlowRunSummary, String> {
        let content = fs::read_to_string(path)
            .map_err(|e| format!("Failed to read log: {}", e))?;

        let lines: Vec<FlowLogEntry> = content.lines()
            .filter_map(|line| serde_json::from_str(line).ok())
            .collect();

        if lines.is_empty() {
            return Err("Empty log file".to_string());
        }

        let first = &lines[0];
        let last = lines.last().unwrap();

        let finished_at = if last.step_id.is_none() && (last.status == "success" || last.status == "error") {
            Some(last.timestamp)
        } else {
            None
        };

        let step_events: Vec<_> = lines.iter()
            .filter(|e| e.step_id.is_some())
            .collect();
        let total_steps = step_events.len() / 2;  // start + success/error per step

        let failed_step = lines.iter()
            .find(|e| e.status == "error" && e.step_id.is_some())
            .and_then(|e| e.step_id.clone());

        let status = if finished_at.is_some() {
            last.status.clone()
        } else {
            "running".to_string()
        };

        Ok(FlowRunSummary {
            flow_id: first.flow_id.clone(),
            run_id: first.run_id.clone(),
            started_at: first.timestamp,
            finished_at,
            status,
            total_steps,
            failed_step,
        })
    }
}
