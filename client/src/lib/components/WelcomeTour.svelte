<script lang="ts">
    import { onMount, createEventDispatcher } from "svelte";
    import { fade, fly } from "svelte/transition";
    import WorkflowMap from "./WorkflowMap.svelte"; // Import for visualization

    const dispatch = createEventDispatcher();

    let isOpen = false;
    let currentStep = 0;
    const TOTAL_STEPS = 5; // Increased to 5

    onMount(() => {
        const tourCompleted = localStorage.getItem("tour_completed");
        if (!tourCompleted) {
            isOpen = true;
        }
    });

    function nextStep() {
        if (currentStep < TOTAL_STEPS - 1) {
            currentStep++;
        } else {
            finishTour();
        }
    }

    function finishTour() {
        localStorage.setItem("tour_completed", "true");
        isOpen = false;
        dispatch("complete"); // Notify parent to switch to workflow
    }

    function skipTour() {
        finishTour();
    }
</script>

{#if isOpen}
    <div
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm"
        transition:fade
    >
        <div
            class="w-[800px] bg-gray-900 border border-gray-700 rounded-xl shadow-2xl overflow-hidden"
            in:fly={{ y: 20, duration: 300 }}
        >
            <!-- Header -->
            <div
                class="px-8 py-6 border-b border-gray-800 flex justify-between items-center"
            >
                <h2 class="text-2xl font-bold text-white">
                    {#if currentStep === 0}Welcome to WORLD_OLLAMA{/if}
                    {#if currentStep === 1}System Check{/if}
                    {#if currentStep === 2}Key Features{/if}
                    {#if currentStep === 3}How it Works{/if}
                    {#if currentStep === 4}Ready to Start{/if}
                </h2>
                <div class="flex gap-1">
                    {#each Array(TOTAL_STEPS) as _, i}
                        <div
                            class="w-2 h-2 rounded-full {i === currentStep
                                ? 'bg-blue-500'
                                : 'bg-gray-700'}"
                        ></div>
                    {/each}
                </div>
            </div>

            <!-- Content -->
            <div class="p-8 min-h-[400px] flex flex-col justify-center">
                {#if currentStep === 0}
                    <div class="text-center space-y-4">
                        <div class="text-6xl">🌍</div>
                        <h3 class="text-xl text-blue-400">
                            Local-First AI Knowledge Workstation
                        </h3>
                        <p class="text-gray-400">
                            Complete control over your AI models, data, and
                            training.<br />
                            No cloud dependencies. No data leaks.
                        </p>
                    </div>
                {/if}

                {#if currentStep === 1}
                    <div class="space-y-4">
                        <div
                            class="flex items-center justify-between p-4 bg-gray-800 rounded-lg"
                        >
                            <span class="text-gray-300">Tauri Backend</span>
                            <span class="text-green-400 font-mono"
                                >Connected</span
                            >
                        </div>
                        <div
                            class="flex items-center justify-between p-4 bg-gray-800 rounded-lg"
                        >
                            <span class="text-gray-300">Ollama Service</span>
                            <span class="text-yellow-400 font-mono"
                                >Checking...</span
                            >
                        </div>
                        <div
                            class="flex items-center justify-between p-4 bg-gray-800 rounded-lg"
                        >
                            <span class="text-gray-300">CORTEX RAG</span>
                            <span class="text-gray-500 font-mono">Pending</span>
                        </div>
                    </div>
                {/if}

                {#if currentStep === 2}
                    <div class="grid grid-cols-2 gap-4">
                        <div
                            class="p-4 bg-gray-800 rounded-lg border border-gray-700"
                        >
                            <div class="text-2xl mb-2">🧠</div>
                            <h4 class="font-bold text-white">Train Agents</h4>
                            <p class="text-sm text-gray-400">
                                Fine-tune models on your own data using LLaMA
                                Factory.
                            </p>
                        </div>
                        <div
                            class="p-4 bg-gray-800 rounded-lg border border-gray-700"
                        >
                            <div class="text-2xl mb-2">🛡️</div>
                            <h4 class="font-bold text-white">Safe Git</h4>
                            <p class="text-sm text-gray-400">
                                Two-phase push workflow to prevent mistakes.
                            </p>
                        </div>
                    </div>
                {/if}

                {#if currentStep === 3}
                    <div class="space-y-4">
                        <p class="text-gray-300 text-center">
                            Data flows from your documents to the Git
                            repository. <br />
                            Click on nodes in the Workflow tab to access specific
                            tools.
                        </p>
                        <!-- Embedded Read-only Workflow Map -->
                        <div
                            class="scale-75 origin-center border border-gray-700 rounded-xl bg-gray-900/50 p-4 pointer-events-none opacity-80"
                        >
                            <WorkflowMap
                                trainingStatus="idle"
                                gitStatus="clean"
                            />
                        </div>
                    </div>
                {/if}

                {#if currentStep === 4}
                    <div class="text-center space-y-6">
                        <div class="text-6xl">🚀</div>
                        <p class="text-xl text-white">You are all set!</p>
                        <p class="text-gray-400">
                            We'll take you to the <b>Workflow Tab</b> now.
                        </p>
                    </div>
                {/if}
            </div>

            <!-- Footer -->
            <div
                class="px-8 py-6 bg-gray-800/50 flex justify-between items-center"
            >
                <button
                    class="text-gray-500 hover:text-white transition-colors"
                    on:click={skipTour}
                >
                    Skip Tour
                </button>
                <button
                    class="px-6 py-2 bg-blue-600 hover:bg-blue-500 text-white rounded-lg font-medium transition-colors"
                    on:click={nextStep}
                >
                    {currentStep === TOTAL_STEPS - 1
                        ? "Open Workflow Map"
                        : "Next"}
                </button>
            </div>
        </div>
    </div>
{/if}
