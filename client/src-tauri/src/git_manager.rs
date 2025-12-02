// WORLD_OLLAMA Desktop Client - Git Manager Module
// TASK 17: Git Safety (Phase 1 - Plan Mode)
// 
// Этот модуль реализует "мозг" Git Push конвейера:
// - Анализирует состояние репозитория (readonly)
// - Проверяет безопасность push (unstaged changes, branch divergence)
// - НЕ выполняет push на этом этапе (только планирование)
//
// ТРИЗ Principle №10: Предварительное действие
// "Всегда планируй push, перед тем как выполнить его"

use serde::Serialize;
use std::process::Command;
use std::path::Path;

// ════════════════════════════════════════════════════════════════════════════
// СТРУКТУРЫ ДАННЫХ
// ════════════════════════════════════════════════════════════════════════════

/// План Git Push с результатами безопасности
/// 
/// Эта структура содержит полный анализ состояния репозитория
/// и детерминирует, можно ли выполнить push.
#[derive(Debug, Serialize)]
pub struct GitPushPlan {
    /// Статус готовности к push
    /// - "ready" - можно пушить (все проверки пройдены)
    /// - "blocked" - push заблокирован (есть проблемы)
    /// - "clean" - нечего пушить (нет новых коммитов)
    pub status: String,
    
    /// Имя remote (обычно "origin")
    pub remote: String,
    
    /// Целевая ветка на remote (из аргументов)
    pub branch: String,
    
    /// Текущая локальная ветка
    pub current_branch: String,
    
    /// Список исходящих коммитов (SHA + сообщение)
    /// Формат: "a1b2c3d: Add new feature"
    pub commits: Vec<String>,
    
    /// Список изменённых файлов (с git status codes)
    /// Формат: "M src/main.rs", "A new_file.txt", "D old_file.rs"
    pub files_changed: Vec<String>,
    
    /// Причины блокировки (если status="blocked")
    /// Примеры: "Unstaged changes", "Uncommitted changes", "Branch diverged"
    pub blocked_reasons: Vec<String>,
}

/// Результат выполнения Git Push
/// 
/// Эта структура возвращается после попытки выполнить push.
#[derive(Debug, Serialize)]
pub struct GitPushResult {
    /// Успешность выполнения
    pub success: bool,
    
    /// Сообщение (stdout при успехе, stderr при ошибке)
    pub message: String,
}

// ════════════════════════════════════════════════════════════════════════════
// CORE LOGIC: PLAN GIT PUSH (READ-ONLY ANALYSIS)
// ════════════════════════════════════════════════════════════════════════════

/// Анализирует состояние Git репозитория и возвращает план push
/// 
/// **ВАЖНО:** Эта функция НИЧЕГО НЕ МЕНЯЕТ в репозитории.
/// Она только читает состояние через `git` команды.
/// 
/// # Проверки (в порядке выполнения)
/// 
/// 1. **Check Root**: Убеждаемся что находимся в Git репо
/// 2. **Check Status**: `git status --porcelain` → unstaged/uncommitted changes
/// 3. **Check Branch**: `git branch --show-current` → совпадает ли с target
/// 4. **Check Remote**: `git remote get-url {remote}` → валиден ли remote
/// 5. **Check Outgoing**: `git log {remote}/{branch}..HEAD` → есть ли коммиты для push
/// 
/// # Arguments
/// 
/// * `repo_root` - Путь к корню проекта (полученный из get_project_root)
/// * `remote` - Имя remote (обычно "origin")
/// * `branch` - Целевая ветка для push (обычно "main")
/// 
/// # Returns
/// 
/// * `Ok(GitPushPlan)` - План с результатами анализа
/// * `Err(String)` - Ошибка выполнения git команды (критическая проблема)
/// 
/// # Example
/// 
/// ```rust,ignore
/// # use tauri_fresh::git_manager::plan_git_push;
/// let plan = plan_git_push("/path/to/project", "origin", "main");
/// 
/// if let Ok(plan) = plan {
///     match plan.status.as_str() {
///         "ready" => println!("Ready to push {} commits", plan.commits.len()),
///         "blocked" => println!("Blocked: {:?}", plan.blocked_reasons),
///         "clean" => println!("Nothing to push"),
///         _ => {}
///     }
/// }
/// ```
pub fn plan_git_push(
    repo_root: &str,
    remote: &str,
    branch: &str,
) -> Result<GitPushPlan, String> {
    let repo_path = Path::new(repo_root);
    
    // Инициализируем структуру с дефолтными значениями
    let mut plan = GitPushPlan {
        status: String::from("blocked"),  // По умолчанию blocked до проверок
        remote: remote.to_string(),
        branch: branch.to_string(),
        current_branch: String::new(),
        commits: Vec::new(),
        files_changed: Vec::new(),
        blocked_reasons: Vec::new(),
    };
    
    // ────────────────────────────────────────────────────────────────────────
    // CHECK 1: Проверка что мы в Git репозитории
    // ────────────────────────────────────────────────────────────────────────
    let git_dir = repo_path.join(".git");
    if !git_dir.exists() {
        plan.blocked_reasons.push(format!(
            "Not a Git repository (no .git directory at {})",
            repo_root
        ));
        return Ok(plan);
    }
    
    // ────────────────────────────────────────────────────────────────────────
    // CHECK 2: git status --porcelain (unstaged/uncommitted changes)
    // ────────────────────────────────────────────────────────────────────────
    let status_output = Command::new("git")
        .arg("status")
        .arg("--porcelain")
        .current_dir(repo_path)
        .output()
        .map_err(|e| format!("Failed to execute git status: {}", e))?;
    
    if !status_output.status.success() {
        return Err(format!(
            "git status failed: {}",
            String::from_utf8_lossy(&status_output.stderr)
        ));
    }
    
    let status_text = String::from_utf8_lossy(&status_output.stdout);
    
    // Парсим файлы из git status --porcelain
    for line in status_text.lines() {
        if !line.is_empty() {
            plan.files_changed.push(line.to_string());
        }
    }
    
    // Если есть изменения → blocked
    if !plan.files_changed.is_empty() {
        // Проверяем есть ли unstaged (индекс 1 в porcelain формате)
        let has_unstaged = plan.files_changed.iter().any(|f| {
            f.len() >= 2 && &f[1..2] != " "
        });
        
        // Проверяем есть ли uncommitted (индекс 0 в porcelain формате)
        let has_uncommitted = plan.files_changed.iter().any(|f| {
            f.len() >= 2 && &f[0..1] != " " && &f[0..2] != "??"
        });
        
        if has_unstaged {
            plan.blocked_reasons.push(String::from(
                "Unstaged changes detected (use git add)"
            ));
        }
        
        if has_uncommitted {
            plan.blocked_reasons.push(String::from(
                "Uncommitted changes detected (use git commit)"
            ));
        }
        
        // Untracked файлы (не блокируют push, но показываем)
        let has_untracked = plan.files_changed.iter().any(|f| f.starts_with("??"));
        if has_untracked && !has_unstaged && !has_uncommitted {
            // Untracked файлы не блокируют push (они не войдут в коммит)
            // Но мы их показываем для информации
        } else if has_unstaged || has_uncommitted {
            // Блокируем push если есть unstaged/uncommitted
            return Ok(plan);
        }
    }
    
    // ────────────────────────────────────────────────────────────────────────
    // CHECK 3: git branch --show-current (текущая ветка)
    // ────────────────────────────────────────────────────────────────────────
    let branch_output = Command::new("git")
        .arg("branch")
        .arg("--show-current")
        .current_dir(repo_path)
        .output()
        .map_err(|e| format!("Failed to execute git branch: {}", e))?;
    
    if !branch_output.status.success() {
        return Err(format!(
            "git branch failed: {}",
            String::from_utf8_lossy(&branch_output.stderr)
        ));
    }
    
    plan.current_branch = String::from_utf8_lossy(&branch_output.stdout)
        .trim()
        .to_string();
    
    // Проверяем соответствие веток
    if plan.current_branch != branch {
        plan.blocked_reasons.push(format!(
            "Current branch '{}' does not match target branch '{}'",
            plan.current_branch, branch
        ));
        return Ok(plan);
    }
    
    // ────────────────────────────────────────────────────────────────────────
    // CHECK 4: git remote get-url {remote} (проверка remote)
    // ────────────────────────────────────────────────────────────────────────
    let remote_output = Command::new("git")
        .arg("remote")
        .arg("get-url")
        .arg(remote)
        .current_dir(repo_path)
        .output()
        .map_err(|e| format!("Failed to execute git remote: {}", e))?;
    
    if !remote_output.status.success() {
        plan.blocked_reasons.push(format!(
            "Remote '{}' not found (use git remote add)",
            remote
        ));
        return Ok(plan);
    }
    
    // ────────────────────────────────────────────────────────────────────────
    // CHECK 5: git log {remote}/{branch}..HEAD --oneline (исходящие коммиты)
    // ────────────────────────────────────────────────────────────────────────
    let log_output = Command::new("git")
        .arg("log")
        .arg(format!("{}/{}..HEAD", remote, branch))
        .arg("--oneline")
        .arg("--no-decorate")
        .current_dir(repo_path)
        .output()
        .map_err(|e| format!("Failed to execute git log: {}", e))?;
    
    // Если git log вернул ошибку → возможно branch не существует на remote
    if !log_output.status.success() {
        let stderr = String::from_utf8_lossy(&log_output.stderr);
        
        // Проверяем специфическую ошибку "unknown revision"
        if stderr.contains("unknown revision") || stderr.contains("does not have any commits") {
            plan.blocked_reasons.push(format!(
                "Branch '{}/{}' does not exist on remote (use git push -u)",
                remote, branch
            ));
            return Ok(plan);
        }
        
        return Err(format!("git log failed: {}", stderr));
    }
    
    let log_text = String::from_utf8_lossy(&log_output.stdout);
    
    // Парсим коммиты (формат: "sha message")
    for line in log_text.lines() {
        if !line.is_empty() {
            plan.commits.push(line.to_string());
        }
    }
    
    // ────────────────────────────────────────────────────────────────────────
    // CHECK 6: git log HEAD..{remote}/{branch} --oneline (remote ahead check)
    // ────────────────────────────────────────────────────────────────────────
    let remote_ahead_output = Command::new("git")
        .arg("log")
        .arg(format!("HEAD..{}/{}", remote, branch))
        .arg("--oneline")
        .arg("--no-decorate")
        .current_dir(repo_path)
        .output()
        .map_err(|e| format!("Failed to execute git log (remote ahead): {}", e))?;
    
    // Если команда успешна, проверяем есть ли коммиты на remote
    if remote_ahead_output.status.success() {
        let remote_ahead_text = String::from_utf8_lossy(&remote_ahead_output.stdout);
        
        // Если вывод не пустой → remote ушёл вперёд
        if !remote_ahead_text.trim().is_empty() {
            plan.blocked_reasons.push(format!(
                "Remote is ahead (pull required before push)"
            ));
        }
    } else {
        // Если команда упала, проверяем ошибку "ambiguous argument" (нет upstream)
        let stderr = String::from_utf8_lossy(&remote_ahead_output.stderr);
        
        if stderr.contains("ambiguous argument") || stderr.contains("unknown revision") {
            plan.blocked_reasons.push(format!(
                "No upstream branch configured (use git push -u {remote} {branch})",
                remote = remote,
                branch = branch
            ));
        }
    }
    
    // ────────────────────────────────────────────────────────────────────────
    // ФИНАЛЬНОЕ РЕШЕНИЕ (с учётом приоритета блокировки)
    // ────────────────────────────────────────────────────────────────────────
    
    // ПРИОРИТЕТ 1: Блокировки (даже если есть коммиты)
    if !plan.blocked_reasons.is_empty() {
        plan.status = String::from("blocked");
    } else if plan.commits.is_empty() {
        // ПРИОРИТЕТ 2: Нет коммитов → нечего пушить
        plan.status = String::from("clean");
    } else {
        // ПРИОРИТЕТ 3: Есть коммиты и нет блокировок → готовы к push
        plan.status = String::from("ready");
    }
    
    Ok(plan)
}

// ════════════════════════════════════════════════════════════════════════════
// EXECUTION: EXECUTE GIT PUSH (WRITE OPERATION)
// ════════════════════════════════════════════════════════════════════════════

/// Выполняет Git Push после re-validation состояния репозитория
/// 
/// **ВАЖНО:** Эта функция ИЗМЕНЯЕТ remote репозиторий.
/// Перед выполнением она повторно проверяет состояние через plan_git_push.
/// 
/// # Safety Re-Validation
/// 
/// 1. Вызывает `plan_git_push()` повторно
/// 2. Если status != "ready" → возвращает ошибку "Safety check failed"
/// 3. Только если status == "ready" → выполняет push
/// 
/// # Arguments
/// 
/// * `repo_root` - Путь к корню проекта
/// * `remote` - Имя remote (обычно "origin")
/// * `branch` - Целевая ветка для push
/// 
/// # Returns
/// 
/// * `Ok(GitPushResult)` - Результат выполнения (success + message)
/// * `Err(String)` - Критическая ошибка (git не найден, repo_root невалиден)
/// 
/// # Example
/// 
/// ```rust,ignore
/// # use tauri_fresh::git_manager::execute_git_push;
/// let result = execute_git_push("/path/to/project", "origin", "main");
/// 
/// if let Ok(result) = result {
///     if result.success {
///         println!("Push successful: {}", result.message);
///     } else {
///         eprintln!("Push failed: {}", result.message);
///     }
/// }
/// ```
pub fn execute_git_push(
    repo_root: &str,
    remote: &str,
    branch: &str,
) -> Result<GitPushResult, String> {
    // ────────────────────────────────────────────────────────────────────────
    // SAFETY RE-VALIDATION (ТРИЗ Principle №10)
    // ────────────────────────────────────────────────────────────────────────
    let plan = plan_git_push(repo_root, remote, branch)?;
    
    // Если статус НЕ "ready" → блокируем выполнение
    if plan.status != "ready" {
        return Ok(GitPushResult {
            success: false,
            message: format!(
                "Safety check failed: Repository state is '{}'. Blocked reasons: {}",
                plan.status,
                plan.blocked_reasons.join(", ")
            ),
        });
    }
    
    // ────────────────────────────────────────────────────────────────────────
    // EXECUTION: git push {remote} {branch}
    // ────────────────────────────────────────────────────────────────────────
    let repo_path = Path::new(repo_root);
    
    let push_output = Command::new("git")
        .arg("push")
        .arg(remote)
        .arg(branch)
        .current_dir(repo_path)
        .output()
        .map_err(|e| format!("Failed to execute git push: {}", e))?;
    
    // ────────────────────────────────────────────────────────────────────────
    // RESULT PROCESSING
    // ────────────────────────────────────────────────────────────────────────
    if push_output.status.success() {
        // Успех: берём stdout (обычно содержит "To github.com:...")
        let stdout = String::from_utf8_lossy(&push_output.stdout).to_string();
        let stderr = String::from_utf8_lossy(&push_output.stderr).to_string();
        
        // Git push часто пишет в stderr даже при успехе (прогресс-бары)
        // Комбинируем оба потока
        let combined = if !stderr.is_empty() {
            format!("{}{}", stderr, stdout)
        } else {
            stdout
        };
        
        Ok(GitPushResult {
            success: true,
            message: if combined.is_empty() {
                String::from("Push completed successfully")
            } else {
                combined
            },
        })
    } else {
        // Ошибка: берём stderr
        let stderr = String::from_utf8_lossy(&push_output.stderr).to_string();
        
        Ok(GitPushResult {
            success: false,
            message: if stderr.is_empty() {
                String::from("Push failed (unknown error)")
            } else {
                stderr
            },
        })
    }
}

// ════════════════════════════════════════════════════════════════════════════
// TESTS (будут добавлены в TASK 17.2)
// ════════════════════════════════════════════════════════════════════════════

#[cfg(test)]
mod tests {
    use super::*;
    
    // TODO: Добавить тесты для:
    // - plan_git_push с clean repo (status="clean")
    // - plan_git_push с uncommitted changes (status="blocked")
    // - plan_git_push с commits ready (status="ready")
    // - plan_git_push с неправильным remote (status="blocked")
}
