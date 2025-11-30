<script lang="ts">
    import { createEventDispatcher } from "svelte";

    const dispatch = createEventDispatcher();

    type NodeStatus =
        | "idle"
        | "active"
        | "error"
        | "ready"
        | "blocked"
        | "clean";

    interface WorkflowNode {
        id: string;
        label: string;
        description: string;
        status: NodeStatus;
        targetPanel: string | null;
        icon: string;
    }

    // Props for external status injection
    export let trainingStatus: string = "idle"; // from PULSE
    export let gitStatus: string = "clean"; // from Git Plan

    // Reactive nodes based on props
    $: nodes = [
        {
            id: "docs",
            label: "Documents",
            description: "Raw text files",
            status: "idle",
            targetPanel: "library",
            icon: "📄",
        },
        {
            id: "index",
            label: "Indexation",
            description: "LightRAG Process",
            status: "idle",
            targetPanel: "flows", // Indexing is triggered via flows/commands
            icon: "⚙️",
        },
        {
            id: "knowledge",
            label: "Knowledge Base",
            description: "Graph & Vectors",
            status: "ready", // Assume ready for MVP
            targetPanel: "chat",
            icon: "🧠",
        },
        {
            id: "train",
            label: "Training",
            description: "Fine-tuning Agent",
            status: mapTrainingStatus(trainingStatus),
            targetPanel: "training",
            icon: "🎓",
        },
        {
            id: "models",
            label: "Models",
            description: "Ollama / Adapters",
            status: "ready",
            targetPanel: "settings",
            icon: "🤖",
        },
        {
            id: "git",
            label: "Git Repo",
            description: "Version Control",
            status: mapGitStatus(gitStatus),
            targetPanel: "git",
            icon: "📦",
        },
    ] as WorkflowNode[];

    function mapTrainingStatus(status: string): NodeStatus {
        if (status === "running") return "active";
        if (status === "error") return "error";
        if (status === "done") return "ready";
        return "idle";
    }

    function mapGitStatus(status: string): NodeStatus {
        if (status === "ready") return "ready";
        if (status === "blocked") return "blocked";
        return "clean";
    }

    function handleNodeClick(node: WorkflowNode) {
        if (node.targetPanel) {
            dispatch("navigate", node.targetPanel);
        }
    }
</script>

<div class="w-full max-w-[1400px] mx-auto px-4 py-8">
    <div
        class="flex flex-wrap md:flex-nowrap gap-4 items-stretch overflow-x-auto pb-2"
    >
        {#each nodes as node, i}
            <!-- Node Card -->
            <button
                class="flex flex-col items-center p-4 rounded-xl border-2 transition-all
                       min-w-[180px] sm:min-w-[200px] md:min-w-[220px]
                       flex-1 md:flex-none md:w-48
                       relative group
          {node.status === 'active'
                    ? 'border-blue-500 bg-blue-900/20 shadow-blue-500/20 shadow-lg'
                    : node.status === 'error' || node.status === 'blocked'
                      ? 'border-red-500 bg-red-900/20'
                      : node.status === 'ready'
                        ? 'border-green-500 bg-green-900/20'
                        : 'border-gray-700 bg-gray-800 hover:border-gray-500'}"
                on:click={() => handleNodeClick(node)}
            >
                <div class="text-3xl mb-2">{node.icon}</div>
                <div class="font-bold text-white mb-1">{node.label}</div>
                <div class="text-xs text-gray-400 text-center">
                    {node.description}
                </div>

                <!-- Status Indicator -->
                <div
                    class="mt-3 px-2 py-0.5 rounded-full text-[10px] uppercase font-bold tracking-wider
          {node.status === 'active'
                        ? 'bg-blue-500 text-white animate-pulse'
                        : node.status === 'error' || node.status === 'blocked'
                          ? 'bg-red-500 text-white'
                          : node.status === 'ready'
                            ? 'bg-green-500 text-white'
                            : 'bg-gray-700 text-gray-400'}"
                >
                    {node.status}
                </div>
            </button>

            <!-- Arrow (except last) -->
            {#if i < nodes.length - 1}
                <div
                    class="hidden md:flex flex-1 items-center justify-center min-w-[20px] max-w-[60px]"
                >
                    <div class="w-full h-0.5 bg-gray-700 relative">
                        <div
                            class="absolute right-0 top-1/2 -translate-y-1/2 w-2 h-2 border-t-2 border-r-2 border-gray-700 rotate-45"
                        ></div>
                    </div>
                </div>
            {/if}
        {/each}
    </div>
</div>
