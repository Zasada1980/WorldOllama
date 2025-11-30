<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import { listen, type UnlistenFn } from "@tauri-apps/api/event";
  import { invoke } from "@tauri-apps/api/core";

  import ChatPanel from "$lib/components/ChatPanel.svelte";
  import SystemStatusPanel from "$lib/components/SystemStatusPanel.svelte";
  import SettingsPanel from "$lib/components/SettingsPanel.svelte";
  import LibraryPanel from "$lib/components/LibraryPanel.svelte";
  import CommandSlot from "$lib/components/CommandSlot.svelte";
  import TrainingPanel from "$lib/components/TrainingPanel.svelte";
  import NotificationCenter from "$lib/components/NotificationCenter.svelte";
  import WorkflowMap from "$lib/components/WorkflowMap.svelte";
  import WelcomeTour from "$lib/components/WelcomeTour.svelte";
  import GitPanel from "$lib/components/GitPanel.svelte";
  import FlowsPanel from "$lib/components/FlowsPanel.svelte";

  // Order 34: Display Preferences integration
  import { displayPreferences } from "$lib/stores/displayPreferences";
  import { applyWindowSize, applyTheme, getBackgroundClass } from "$lib/utils/applyDisplayPreferences";

  type View =
    | "chat"
    | "status"
    | "settings"
    | "library"
    | "commands"
    | "training"
    | "workflow"
    | "git"
    | "flows";

  let activeView: View = "workflow"; // Default to workflow for v0.3.0 experience

  // ===========================================================================
  // STATE: Shared Status for Workflow Map
  // ===========================================================================

  let trainingStatus: any = { status: "idle" }; // Default
  let gitPlanStatus: string = "clean"; // Default

  let unlisten: UnlistenFn | null = null;
  let pollInterval: any = null;

  // Order 34: Display Preferences reactive state
  let bgClass = "bg-base-100";
  let unsubscribeDisplay: (() => void) | null = null;

  // PULSE v1 Listener
  async function setupListeners() {
    unlisten = await listen("training_status_update", (event: any) => {
      trainingStatus = event.payload;
    });
  }

  // Git Status Poller (Lightweight)
  async function checkGitStatus() {
    try {
      // We only check if we are on the workflow tab to save resources
      if (activeView === "workflow") {
        const res: any = await invoke("plan_git_push", {
          remote: "origin",
          branch: "main",
        });
        if (res && res.data) {
          gitPlanStatus = res.data.status;
        }
      }
    } catch (e) {
      console.error("Failed to check git status:", e);
      gitPlanStatus = "blocked";
    }
  }

  onMount(async () => {
    await setupListeners();

    // Initial Git check
    checkGitStatus();

    // Poll Git status every 10s if on workflow tab
    pollInterval = setInterval(checkGitStatus, 10000);

    // Order 34: Subscribe to display preferences changes
    unsubscribeDisplay = displayPreferences.subscribe(async (prefs) => {
      await applyWindowSize(prefs.windowSize);
      applyTheme(prefs.theme);
      bgClass = getBackgroundClass(prefs.background);
    });

    // Fix #3: Apply initial preferences on mount
    const initialPrefs = $displayPreferences;
    await applyWindowSize(initialPrefs.windowSize);
    applyTheme(initialPrefs.theme);
    bgClass = getBackgroundClass(initialPrefs.background);
    console.log('[+page] Initial display preferences applied:', initialPrefs);
  });

  onDestroy(() => {
    if (unlisten) unlisten();
    if (pollInterval) clearInterval(pollInterval);
    if (unsubscribeDisplay) unsubscribeDisplay();
  });

  // Navigation Handler from WorkflowMap
  function handleNavigate(event: CustomEvent<string>) {
    const target = event.detail as View;
    if (target) {
      activeView = target;
    }
  }

  // Tour Completion Handler
  function handleTourComplete() {
    activeView = "workflow";
  }
</script>

<nav class="main-nav">
  <button
    class:selected={activeView === "workflow"}
    on:click={() => (activeView = "workflow")}
  >
    🗺️ Workflow
  </button>
  <button
    class:selected={activeView === "chat"}
    on:click={() => (activeView = "chat")}
  >
    💬 Chat
  </button>
  <button
    class:selected={activeView === "status"}
    on:click={() => (activeView = "status")}
  >
    📡 Status
  </button>
  <button
    class:selected={activeView === "library"}
    on:click={() => (activeView = "library")}
  >
    📚 Library
  </button>
  <button
    class:selected={activeView === "training"}
    on:click={() => (activeView = "training")}
  >
    🧪 Training
  </button>
  <button
    class:selected={activeView === "git"}
    on:click={() => (activeView = "git")}
  >
    🛡️ Git
  </button>
  <button
    class:selected={activeView === "flows"}
    on:click={() => (activeView = "flows")}
  >
    ⚡ Flows
  </button>
  <button
    class:selected={activeView === "settings"}
    on:click={() => (activeView = "settings")}
  >
    ⚙️ Settings
  </button>
</nav>

<main class="app-container {bgClass}">
  {#if activeView === "workflow"}
    <WorkflowMap
      trainingStatus={trainingStatus?.status || "idle"}
      gitStatus={gitPlanStatus}
      on:navigate={handleNavigate}
    />
  {:else if activeView === "chat"}
    <ChatPanel />
  {:else if activeView === "status"}
    <SystemStatusPanel />
  {:else if activeView === "library"}
    <LibraryPanel />
  {:else if activeView === "commands"}
    <CommandSlot />
  {:else if activeView === "training"}
    <TrainingPanel />
  {:else if activeView === "git"}
    <GitPanel />
  {:else if activeView === "flows"}
    <FlowsPanel />
  {:else if activeView === "settings"}
    <SettingsPanel />
  {/if}
</main>

<!-- Global Components -->
<NotificationCenter />
<WelcomeTour on:complete={handleTourComplete} />

<style>
  :global(body) {
    margin: 0;
    padding: 0;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
      "Helvetica Neue", Arial, sans-serif;
    font-size: 14px;
    background: #1a1a1a;
    color: #e0e0e0;
  }

  :global(*) {
    box-sizing: border-box;
  }

  /* Order 34: Background pattern styles */
  .app-container {
    min-height: 100vh;
    transition: background 0.3s ease;
  }

  :global(.bg-grid-pattern) {
    background-color: #1a1a1a;
    background-image: 
      linear-gradient(rgba(255, 255, 255, 0.05) 1px, transparent 1px),
      linear-gradient(90deg, rgba(255, 255, 255, 0.05) 1px, transparent 1px);
    background-size: 50px 50px;
  }

  :global(.bg-gradient-to-br) {
    background: linear-gradient(to bottom right, #0f172a, #1e293b, #0f172a);
  }

  :global(.bg-neutral-900) {
    background-color: #171717;
  }

  :global(.bg-base-100) {
    background-color: #1a1a1a;
  }

  .main-nav {
    display: flex;
    gap: 0;
    background: #2a2a2a;
    border-bottom: 2px solid #333;
    padding: 0;
    overflow-x: auto; /* Allow scrolling if too many tabs */
  }

  .main-nav button {
    flex: 1;
    min-width: 100px;
    padding: 16px 12px;
    background: transparent;
    color: #888;
    border: none;
    border-bottom: 3px solid transparent;
    cursor: pointer;
    font-size: 0.95em;
    font-weight: 600;
    transition: all 0.2s;
    white-space: nowrap;
  }

  .main-nav button:hover {
    background: #333;
    color: #fff;
  }

  .main-nav button.selected {
    color: #4caf50;
    background: #1a1a1a;
    border-bottom-color: #4caf50;
  }

  main {
    min-height: calc(100vh - 60px);
    overflow-y: auto;
  }
</style>
