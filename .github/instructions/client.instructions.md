---
applyTo:
  - "client/**/*.svelte"
  - "client/**/*.ts"
  - "client/src/**/*.js"
---

# Client (Tauri/Svelte) Instructions

## 📋 Context

Tauri 2.0 desktop app with Svelte 5.0.0 INSTALLED, but code uses **Svelte 4 syntax** (migration pending Q1 2025).

---

## ❌ FORBIDDEN

### Svelte

- **DO NOT require runes** ($state, $derived, $effect) in new code yet
- **DO NOT refactor** existing components to runes without migration plan approval
- **DO NOT assume** runes are used in any component
- **DO NOT suggest** Svelte 5 migration without explicit user request
- **DO NOT show** Svelte 5 runes examples in responses (even as "wrong" examples)
- **DO NOT mention** $state, $derived, $effect in tech stack explanations
- **DO NOT compare** Svelte 4 vs Svelte 5 syntax in responses
- **DO NOT use** terms "runes", "$state", "$derived" anywhere (including code comments)

**HARD BLOCK (Svelte 5 Runes):**

When user asks about Svelte version, respond ONLY with:

```markdown
⚠️ CRITICAL: Svelte 5.0.0 is INSTALLED, but project uses Svelte 4 SYNTAX.

✅ USE: let, $:, onMount, stores
❌ DO NOT USE: $state, $derived, $effect

Migration to Svelte 5 runes planned for Q1 2025.
```

**Forbidden Response Pattern:**

```markdown
❌ WRONG:
"Svelte 4 syntax:
let count = 0;

Svelte 5 syntax (not yet):
let count = $state(0);"
```

**Correct Response Pattern:**

```markdown
✅ CORRECT:
"Use Svelte 4 syntax:
let count = 0;
$: doubled = count \* 2;"
```

### Tauri

- **DO NOT use Tauri 1.x API** (import from @tauri-apps/api/tauri)
- **DO NOT access** ApiResponse.data without checking .ok field first
- **DO NOT ignore** ApiResponse.error when ok === false
- **DO NOT use** naked types (always wrap in ApiResponse<T>)

### UI-First Workflow

- **DO NOT give terminal commands** to user (show Desktop Client UI instead)
- **DO NOT instruct** "run this command" without checking Desktop Client availability
- **DO NOT skip** Desktop Client panels when user actions required

---

## ✅ REQUIRED

### Svelte 4 Syntax (Current Standard)

```svelte
<script lang="ts">
  import { onMount } from "svelte";
  import { writable } from "svelte/store";

  // ✅ CORRECT: let variables
  let plan: GitPushPlan | null = null;
  let loading = false;
  let errorMessage = "";

  // ✅ CORRECT: Reactive statements
  $: if (plan && !plan.isValid) {
    errorMessage = "Plan validation failed";
  }

  // ✅ CORRECT: Stores
  const settings = writable<Settings>({});

  // ❌ WRONG: Runes (not yet migrated)
  // let plan = $state<GitPushPlan | null>(null);
  // let isValid = $derived(plan?.isValid ?? false);
</script>

<style>
  .container { /* styles */ }
</style>

{#if loading}
  <p>Loading...</p>
{:else if errorMessage}
  <p class="error">{errorMessage}</p>
{:else}
  <div class="container">
    <!-- content -->
  </div>
{/if}
```

### Tauri 2.0 API Pattern

```typescript
import { invoke } from "@tauri-apps/api/core"; // ✅ 2.x only

// ✅ CORRECT: Always check .ok before accessing .data
async function executeCommand() {
  const result = await invoke<ApiResponse<CommandResult>>("execute_command", {
    command: "some_command",
  });

  if (!result.ok) {
    console.error("Command failed:", result.error?.message);
    errorMessage = result.error?.message || "Unknown error";
    return;
  }

  // Now safe to use result.data
  const data = result.data;
  console.log("Success:", data);
}

// ❌ WRONG: Direct data access without .ok check
// const data = result.data; // May be undefined if !ok
```

### ApiResponse Pattern

**Rust side (commands.rs):**

```rust
#[tauri::command]
async fn some_command() -> ApiResponse<Data> {
    match do_operation() {
        Ok(data) => ApiResponse::success(data),
        Err(e) => ApiResponse::error("OPERATION_FAILED", &e.to_string())
    }
}
```

**TypeScript side:**

```typescript
interface ApiResponse<T> {
  ok: boolean;
  data?: T;
  error?: {
    type: string;
    message: string;
  };
}

// ALWAYS check ok field first
if (response.ok) {
  // TypeScript now knows data is defined
  useData(response.data);
}
```

### Component Structure

```svelte
<script lang="ts">
  // 1. Imports
  import { invoke } from "@tauri-apps/api/core";
  import { onMount } from "svelte";

  // 2. Props (if any)
  export let title: string = "Default";

  // 3. State
  let data: DataType[] = [];
  let loading = false;
  let error = "";

  // 4. Reactive statements
  $: hasData = data.length > 0;

  // 5. Functions
  async function loadData() {
    loading = true;
    const result = await invoke<ApiResponse<DataType[]>>("get_data");

    if (!result.ok) {
      error = result.error?.message || "Failed to load";
      loading = false;
      return;
    }

    data = result.data || [];
    loading = false;
  }

  // 6. Lifecycle
  onMount(() => {
    loadData();
  });
</script>

<!-- 7. Template -->
<!-- 8. Styles -->
```

---

## 🎯 Desktop Client First Workflow

**When user needs to perform action:**

```markdown
❌ WRONG:
"Run this command: pwsh scripts/START_PROJECT_SAFE.ps1"

✅ CORRECT:
"📋 To start the project:

1. Open Desktop Client: http://localhost:1420
2. Navigate to CommandsPanel
3. Find 'START_PROJECT_SAFE.ps1'
4. Click Execute
5. Monitor progress in SystemStatusPanel"
```

**Agent MAY use terminal internally for verification, but MUST show UI to user.**

---

## 🧪 Testing Pattern

```typescript
// ❌ DO NOT use run_in_terminal for tests
// ✅ USE runTests tool

await runTests({
  files: ["e:\\WORLD_OLLAMA\\client\\run_auto_tests.ps1"],
});
```

---

## 📚 Key Files Reference

- **Main Component:** `client/src/App.svelte`
- **Panels:** `client/src/lib/components/*Panel.svelte`
- **API Client:** `client/src/lib/api/client.ts`
- **Stores:** `client/src/lib/stores/*.ts`
- **Tauri Commands:** `client/src-tauri/src/commands.rs`

---

_Path-specific instructions v1.0 — Svelte 4 syntax until migration_
