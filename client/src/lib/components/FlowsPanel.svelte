<script lang="ts">
    import { onMount, onDestroy } from "svelte";
    import { invoke } from "@tauri-apps/api/core";
    import { listen, type UnlistenFn } from "@tauri-apps/api/event";

    interface Flow {
        id: string;
        name: string;
        description: string;
        steps: any[];
    }

    interface FlowStatus {
        is_running: boolean;
        current_flow_id: string | null;
        current_step_index: number | null;
        total_steps: number | null;
        last_error: string | null;
        logs: string[];
    }

    // ORDER 38 КОМАНДА 2: Flow history
    interface FlowRunSummary {
        flow_id: string;
        run_id: string;
        started_at: number;
        finished_at: number | null;
        status: string;
        total_steps: number;
        failed_step: string | null;
    }

    let flows: Flow[] = [];
    let status: FlowStatus = {
        is_running: false,
        current_flow_id: null,
        current_step_index: null,
        total_steps: null,
        last_error: null,
        logs: [],
    };

    let unlisten: UnlistenFn | null = null;
    let isLoading = true; // ORDER 22 КОМАНДА 4: Loading state
    let loadError: string | null = null; // ORDER 22 КОМАНДА 4: Error state
    let history: FlowRunSummary[] = []; // ORDER 38 КОМАНДА 2: Flow history
    let historyLoading = false;

    async function loadFlows() {
        isLoading = true;
        loadError = null;
        try {
            flows = await invoke("list_flows");
            isLoading = false;
        } catch (e) {
            console.error("Failed to load flows:", e);
            loadError = `Failed to load flows: ${e}`;
            isLoading = false;
        }
    }

    async function runFlow(id: string) {
        try {
            await invoke("run_flow", { flowId: id });
        } catch (e) {
            console.error("Failed to run flow:", e);
            status.logs = [...status.logs, `❌ Failed to start flow: ${e}`];
        }
    }

    // ORDER 38 КОМАНДА 2: Load flow history
    async function loadHistory() {
        historyLoading = true;
        try {
            const response: any = await invoke("get_flow_history", {
                limit: 10,
            });
            if (response.ok && response.data) {
                history = response.data;
            }
        } catch (e) {
            console.error("Failed to load history:", e);
        } finally {
            historyLoading = false;
        }
    }

    function formatDuration(started: number, finished: number | null): string {
        if (!finished) return "Running...";
        const duration = finished - started;
        return duration < 60
            ? `${duration}s`
            : `${Math.floor(duration / 60)}m ${duration % 60}s`;
    }

    onMount(async () => {
        await loadFlows();
        await loadHistory(); // ORDER 38 КОМАНДА 2

        // Initial status check
        status = await invoke("get_flow_status");

        // Listen for updates
        unlisten = await listen("flow_status_update", (event: any) => {
            status = event.payload;
            // Reload history after flow completes
            if (!event.payload.is_running) {
                loadHistory();
            }
        });
    });

    onDestroy(() => {
        if (unlisten) unlisten();
    });
</script>

<div class="h-full flex flex-col p-6 text-gray-200">
    <div class="mb-6">
        <h2 class="text-2xl font-bold text-white mb-2">Agent Automation</h2>
        <p class="text-gray-400">
            Execute multi-step workflows to automate your agent lifecycle.
        </p>
    </div>

    <!-- ORDER 22 КОМАНДА 4: Help Banner -->
    <div class="bg-blue-900/20 border border-blue-700 rounded-lg p-4 mb-6">
        <p class="text-sm text-blue-200">
            <strong>ℹ️ Flows Automation:</strong> Execute pre-defined workflows (JSON
            files).
        </p>
        <p class="text-xs text-blue-300 mt-2">
            📁 Files: <code class="bg-blue-900/40 px-1 rounded"
                >automation/flows/*.json</code
            >
            | ✅ Supported: STATUS, TRAIN, GIT_PUSH | ⏸️ INDEX → v0.3.1 (ORDER 37)
        </p>
    </div>

    <!-- ORDER 22 КОМАНДА 4: Loading State -->
    {#if isLoading}
        <div class="text-center py-12 text-gray-400">
            <div
                class="animate-spin inline-block w-8 h-8 border-4 border-blue-500 border-t-transparent rounded-full mb-4"
            ></div>
            <p>Loading flows...</p>
        </div>

        <!-- ORDER 22 КОМАНДА 4: Error State -->
    {:else if loadError}
        <div class="bg-red-900/20 border border-red-700 rounded-lg p-6">
            <p class="text-red-300 font-bold">❌ Error Loading Flows</p>
            <p class="text-red-400 text-sm mt-2">{loadError}</p>
            <button
                class="mt-4 px-4 py-2 bg-red-700 hover:bg-red-600 text-white rounded-lg"
                on:click={loadFlows}
            >
                Retry
            </button>
        </div>

        <!-- ORDER 22 КОМАНДА 4: Empty State -->
    {:else if flows.length === 0}
        <div class="text-center py-12 text-gray-400">
            <p class="text-lg font-bold mb-2">📦 No flows found</p>
            <p class="text-sm">
                Add JSON files to <code class="bg-gray-800 px-2 py-1 rounded"
                    >automation/flows/</code
                > to use automation
            </p>
        </div>

        <!-- Flow Cards -->
    {:else}
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            {#each flows as flow}
                <div
                    class="bg-gray-800 border border-gray-700 rounded-xl p-6 hover:border-blue-500 transition-colors"
                >
                    <div class="flex justify-between items-start mb-4">
                        <div>
                            <h3 class="text-lg font-bold text-white">
                                {flow.name}
                            </h3>
                            <p class="text-sm text-gray-400 mt-1">
                                {flow.description}
                            </p>
                        </div>
                        <span
                            class="px-2 py-1 bg-gray-700 rounded text-xs text-gray-300"
                        >
                            {flow.steps.length} steps
                        </span>
                    </div>
                </div>
            {/each}
        </div>
    {/if}

    {#if status.logs.length > 0}
        <div
            class="mt-8 flex-1 min-h-0 flex flex-col bg-gray-900 rounded-lg border border-gray-700 overflow-hidden"
        >
            <div class="px-4 py-2 border-b border-gray-800 bg-gray-800/50">
                <h4
                    class="text-sm font-bold text-gray-400 uppercase tracking-wider"
                >
                    Execution Log
                </h4>
            </div>
            <div class="flex-1 overflow-y-auto p-4 font-mono text-sm space-y-1">
                {#each status.logs as log}
                    <div
                        class:text-red-400={log.includes("❌") ||
                            log.includes("⛔")}
                        class:text-green-400={log.includes("✅") ||
                            log.includes("🎉")}
                        class:text-blue-400={log.includes("Starting") ||
                            log.includes("Step")}
                        class="text-gray-300"
                    >
                        {log}
                    </div>
                {/each}
                {#if status.is_running}
                    <div class="animate-pulse text-gray-500">_</div>
                {/if}
            </div>
        </div>
    {/if}
</div>
