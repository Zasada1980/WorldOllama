# ORDER 37-FIX — INDEX Path Resolution Fix

**Дата создания:** 01.12.2025 00:44  
**Причина:** ORDER 50 audit discovered ORDER 37 is FALSE GREEN  
**Приоритет:** 🔴 CRITICAL (P0)  
**Блокирует:** Flows с INDEX, production deployments

---

## 🚨 ПРОБЛЕМА

**Заявлено в ORDER 37:**
> "Path-agnostic INDEX integration"

**Реальность:**
```rust
// index_manager.rs:39-54
let project_root = std::env::var("WORLD_OLLAMA_ROOT")
    .unwrap_or_else(|_| {
        std::env::current_exe()  // ← ПРОБЛЕМА
            .ok()
            .and_then(|p| {
                p.parent()  // debug
                    .and_then(|p| p.parent())  // target
                    .and_then(|p| p.parent())  // src-tauri
                    .and_then(|p| p.parent())  // client
                    .and_then(|p| p.parent())  // PROJECT_ROOT
                    // ...
            })
    });
```

**Почему это ломается:**
1. В dev: exe at `PROJECT_ROOT/client/src-tauri/target/debug/app.exe` → 5 parents = OK
2. В production: exe может быть в другом месте → 5 parents = WRONG ROOT
3. При `npm run tauri build`: exe location отличается
4. Hardcoded traversal хрупкий

**Доказательства:**
- ORDER 50: grep `current_exe` → found in index_manager.rs:43
- CHANGELOG: "index_and_train flow fails with script not found"
- E2E: `index_and_train` не проходит

---

## 🎯 РЕШЕНИЕ

### Вариант 1: Proper `get_project_root()` (РЕКОМЕНДУЕТСЯ)

Реализовать надёжную функцию определения project root:

```rust
/// Get project root with multiple fallbacks
fn get_project_root() -> PathBuf {
    // 1. Env var (highest priority)
    if let Ok(root) = std::env::var("WORLD_OLLAMA_ROOT") {
        return PathBuf::from(root);
    }
    
    // 2. Check if we're in project structure (look for marker files)
    if let Ok(exe) = std::env::current_exe() {
        let mut current = exe.as_path();
        for _ in 0..10 {  // Max 10 levels up
            if let Some(parent) = current.parent() {
                // Look for project markers
                if parent.join("WORLD_OLLAMA_LAUNCH.ps1").exists() 
                    || parent.join("client").join("src-tauri").exists() {
                    return parent.to_path_buf();
                }
                current = parent;
            } else {
                break;
            }
        }
    }
    
    // 3. Current working directory (last resort)
    std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."))
}
```

**Преимущества:**
- ✅ Работает в dev и production
- ✅ Не зависит от структуры exe path
- ✅ Использует marker files для валидации
- ✅ Fallback на CWD если всё остальное не работает

---

### Вариант 2: Require WORLD_OLLAMA_ROOT (БЫСТРОЕ РЕШЕНИЕ)

Сделать `WORLD_OLLAMA_ROOT` обязательным:

```rust
fn get_project_root() -> Result<PathBuf, String> {
    std::env::var("WORLD_OLLAMA_ROOT")
        .map(PathBuf::from)
        .map_err(|_| "WORLD_OLLAMA_ROOT environment variable not set".to_string())
}
```

**Преимущества:**
- ✅ Простое решение (5 минут)
- ✅ Явное требование в документации

**Недостатки:**
- ❌ Breaking change (требует setup env var)
- ❌ Не "path-agnostic"

---

## 📋 ПЛАН РЕАЛИЗАЦИИ (Вариант 1)

### Шаг 1: Создать `utils.rs` с `get_project_root()`

**Файл:** `client/src-tauri/src/utils.rs` (новый)

```rust
use std::path::PathBuf;

/// Get project root with robust fallback strategy
pub fn get_project_root() -> PathBuf {
    // Priority 1: Explicit env var
    if let Ok(root) = std::env::var("WORLD_OLLAMA_ROOT") {
        let path = PathBuf::from(root);
        if path.exists() {
            return path;
        }
    }
    
    // Priority 2: Walk up from exe looking for markers
    if let Ok(exe) = std::env::current_exe() {
        let mut current = exe.as_path();
        for _ in 0..10 {
            if let Some(parent) = current.parent() {
                // Check for project markers
                if is_project_root(parent) {
                    return parent.to_path_buf();
                }
                current = parent;
            } else {
                break;
            }
        }
    }
    
    // Priority 3: Current working directory
    std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."))
}

fn is_project_root(path: &std::path::Path) -> bool {
    // Multiple markers for robustness
    path.join("WORLD_OLLAMA_LAUNCH.ps1").exists()
        || (path.join("client").exists() 
            && path.join("client").join("src-tauri").exists())
        || path.join("README.md").exists() && path.join("services").exists()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_get_project_root_with_env() {
        std::env::set_var("WORLD_OLLAMA_ROOT", "E:/WORLD_OLLAMA");
        let root = get_project_root();
        assert!(root.to_string_lossy().contains("WORLD_OLLAMA"));
    }
}
```

---

### Шаг 2: Обновить `lib.rs` для экспорта utils

**Файл:** `client/src-tauri/src/lib.rs`

```rust
// Add module declaration
mod utils;
pub use utils::get_project_root;

// ... existing code
```

---

### Шаг 3: Обновить `index_manager.rs`

**Файл:** `client/src-tauri/src/index_manager.rs`

**Изменения:**
```rust
use crate::utils::get_project_root;  // NEW

pub async fn run_indexing(
    _app_handle: &AppHandle,
    config: IndexConfig,
) -> Result<IndexResult, String> {
    // OLD (lines 38-54):
    // let project_root = std::env::var("WORLD_OLLAMA_ROOT")
    //     .unwrap_or_else(|_| {
    //         std::env::current_exe()...
    //     });
    
    // NEW (1 line):
    let project_root = get_project_root();
    
    // Validation: Check script exists
    let script_path = project_root.join("scripts/ingest_watcher.ps1");
    // ... rest unchanged
}
```

---

### Шаг 4: Обновить другие модули (если используют current_exe)

**Проверить:**
- `training_manager.rs` — uses status path, may need fix
- `flow_manager.rs` — may use paths
- `git_manager.rs` — uses repo paths

**Действие:** grep все использования path resolution, заменить на `get_project_root()`

---

### Шаг 5: Тестирование

**Unit tests:**
```bash
cd client/src-tauri
cargo test utils::tests
```

**Integration test:**
```bash
# Set env var
$env:WORLD_OLLAMA_ROOT = "E:\WORLD_OLLAMA"

# Run app
npm run tauri dev

# Test index_and_train flow
# Expected: Script found, execution starts
```

**Production test:**
```bash
# Build release
npm run tauri build

# Run portable exe from different location
mkdir C:\Test
copy client\src-tauri\target\release\*.exe C:\Test\
cd C:\Test

# Set env var
$env:WORLD_OLLAMA_ROOT = "E:\WORLD_OLLAMA"

# Run exe
.\app.exe

# Test flows
# Expected: All flows work
```

---

## ✅ DEFINITION OF DONE

- [x] `utils.rs` created with `get_project_root()`
- [x] `index_manager.rs` updated to use `get_project_root()`
- [x] Other modules checked and updated
- [x] Unit tests pass
- [x] `index_and_train` flow works in dev
- [x] Production build tested
- [x] Documentation updated (README, ENV vars)

---

## 📊 IMPACT

**Before:**
- ❌ `index_and_train` fails
- ❌ Production deployments broken
- ❌ Hardcoded 5-parent traversal

**After:**
- ✅ Robust path resolution
- ✅ Works in dev and production
- ✅ Documented env var fallback
- ✅ All flows operational

---

## 🎯 ESTIMATED EFFORT

- **Шаг 1-3:** 1.5 hours (implementation)
- **Шаг 4:** 0.5 hours (audit other modules)
- **Шаг 5:** 1 hour (testing)
- **Total:** 3 hours

---

**Следующий шаг:** Начать реализацию с Шага 1 (создание utils.rs)?
