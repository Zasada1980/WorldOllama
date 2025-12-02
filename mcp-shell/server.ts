#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
    CallToolRequestSchema,
    ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { spawn } from "child_process";
import * as fs from "fs";
import * as path from "path";

// ORDER 51.7 + PHASE 2.2: Load timeout policy from config (full parameters)
interface TimeoutPolicy {
    timeouts: {
        default_exec_timeout_sec: number;
        max_exec_timeout_sec: number;
        no_output_timeout_sec: number;        // P3: watchdog для зависших процессов
        soft_kill_timeout_sec: number;        // P3: grace period для SIGTERM
        hard_kill_timeout_sec: number;        // P3: force kill delay
        global_agent_timeout_sec: number;     // Reserved для будущего use
    };
    long_running_overrides: Record<string, number>;
    command_classification: {
        fast: { max_timeout_sec: number; patterns: string[] };
        medium: { max_timeout_sec: number; patterns: string[] };
        long: { max_timeout_sec: number; patterns: string[] };
    };
}

let timeoutPolicy: TimeoutPolicy | null = null;

function loadTimeoutPolicy(): TimeoutPolicy {
    if (timeoutPolicy) return timeoutPolicy;
    
    try {
        // Try to load from project root
        const projectRoot = process.env.WORLD_OLLAMA_ROOT || process.cwd();
        const policyPath = path.join(projectRoot, "config", "terminal_timeout_policy.json");
        
        if (fs.existsSync(policyPath)) {
            const content = fs.readFileSync(policyPath, "utf-8");
            timeoutPolicy = JSON.parse(content);
            console.error(`[MCP] Loaded timeout policy from: ${policyPath}`);
            return timeoutPolicy!;
        }
    } catch (error) {
        console.error(`[MCP] Failed to load timeout policy: ${error}`);
    }
    
    // Fallback to default policy (Phase 2.2: full params)
    timeoutPolicy = {
        timeouts: {
            default_exec_timeout_sec: 120,
            max_exec_timeout_sec: 900,
            no_output_timeout_sec: 30,
            soft_kill_timeout_sec: 10,
            hard_kill_timeout_sec: 5,
            global_agent_timeout_sec: 90,
        },
        long_running_overrides: {},
        command_classification: {
            fast: { max_timeout_sec: 60, patterns: ["dir", "ls", "cat", "echo"] },
            medium: { max_timeout_sec: 120, patterns: ["pwsh", "node", "python"] },
            long: { max_timeout_sec: 900, patterns: ["npm", "cargo", "docker"] },
        },
    };
    console.error("[MCP] Using default timeout policy");
    return timeoutPolicy;
}

/**
 * Encodes PowerShell command to Base64 to prevent Exit Code 255 from special characters.
 * Solves issues with |, {}, $, " in commands.
 * 
 * @param rawCommand - Original PowerShell command
 * @returns Base64-encoded command string ready for -EncodedCommand parameter
 */
function encodeCommandToBase64(rawCommand: string): string {
    // PowerShell requires UTF-16LE encoding for -EncodedCommand
    const buffer = Buffer.from(rawCommand, 'utf16le');
    return buffer.toString('base64');
}

/**
 * Checks if command contains special characters that require Base64 encoding.
 * 
 * @param command - Command to check
 * @returns true if command needs encoding
 */
function requiresEncoding(command: string): boolean {
    // Characters that commonly cause Exit Code 255 in PowerShell
    const dangerousChars = /[|{}$"'`]/;
    return dangerousChars.test(command);
}

function getCommandTimeout(command: string): number {
    const policy = loadTimeoutPolicy();
    
    // Check long_running_overrides first (normalize spaces to underscores for matching)
    const normalizedCmd = command.toLowerCase().replace(/\s+/g, "_");
    for (const [pattern, timeout] of Object.entries(policy.long_running_overrides)) {
        if (normalizedCmd.includes(pattern.toLowerCase())) {
            return timeout * 1000; // Convert to milliseconds
        }
    }
    
    // Check command classification
    const cmdLower = command.toLowerCase();
    
    for (const pattern of policy.command_classification.fast.patterns) {
        if (cmdLower.includes(pattern.toLowerCase())) {
            return policy.command_classification.fast.max_timeout_sec * 1000;
        }
    }
    
    for (const pattern of policy.command_classification.medium.patterns) {
        if (cmdLower.includes(pattern.toLowerCase())) {
            return policy.command_classification.medium.max_timeout_sec * 1000;
        }
    }
    
    for (const pattern of policy.command_classification.long.patterns) {
        if (cmdLower.includes(pattern.toLowerCase())) {
            return policy.command_classification.long.max_timeout_sec * 1000;
        }
    }
    
    // Default timeout
    return policy.timeouts.default_exec_timeout_sec * 1000;
}

// === PHASE 2.1: Circuit Breaker + Health Check (P2/P7) ===
type BreakerState = "CLOSED" | "OPEN" | "HALF_OPEN";
interface McpState {
    breaker: BreakerState;
    consecutiveFailures: number;
    lastFailureTs: number;
    nextProbeTs: number;
}
const mcpState: McpState = {
    breaker: "CLOSED",
    consecutiveFailures: 0,
    lastFailureTs: 0,
    nextProbeTs: 0,
};
const FAILURE_THRESHOLD = 3; // 3 подряд ошибки → OPEN
const BASE_BACKOFF_MS = 5000; // начальный backoff для HALF_OPEN

function writeMcpLog(line: string) {
    try {
        const root = process.env.WORLD_OLLAMA_ROOT || process.cwd();
        const logDir = path.join(root, "logs", "mcp");
        if (!fs.existsSync(logDir)) fs.mkdirSync(logDir, { recursive: true });
        const entry = `[${new Date().toISOString()}] ${line}\n`;
        fs.appendFileSync(path.join(logDir, "mcp-events.log"), entry, { encoding: "utf-8" });
    } catch (e) {
        console.error(`[MCP] Log write failed: ${e}`);
    }
}

function recordFailure(classification: string) {
    mcpState.consecutiveFailures++;
    mcpState.lastFailureTs = Date.now();
    writeMcpLog(`FAIL classification=${classification} count=${mcpState.consecutiveFailures}`);
    if (mcpState.consecutiveFailures >= FAILURE_THRESHOLD && mcpState.breaker === "CLOSED") {
        mcpState.breaker = "OPEN";
        mcpState.nextProbeTs = Date.now() + BASE_BACKOFF_MS;
        writeMcpLog(`STATE_CHANGE CLOSED→OPEN threshold=${FAILURE_THRESHOLD}`);
    }
}

function recordSuccess() {
    if (mcpState.breaker !== "CLOSED") {
        writeMcpLog(`BREAKER_RECOVERY prior=${mcpState.breaker}`);
    }
    mcpState.breaker = "CLOSED";
    mcpState.consecutiveFailures = 0;
}

function considerHalfOpen() {
    if (mcpState.breaker === "OPEN" && Date.now() >= mcpState.nextProbeTs) {
        mcpState.breaker = "HALF_OPEN";
        writeMcpLog(`STATE_CHANGE OPEN→HALF_OPEN probeAttempt`);
    }
}

// === P4: Retry Logic ===
function isIdempotent(cmd: string): boolean {
    const readOnlyPatterns = /^(dir|ls|cat|type|echo|get-content|test-path|git status|nvidia-smi|pwd|which)/i;
    return readOnlyPatterns.test(cmd.trim());
}

function getRetryConfig(cmd: string): { maxRetries: number; baseBackoffMs: number } {
    const policy = loadTimeoutPolicy();
    const cmdLower = cmd.toLowerCase();
    // Fast commands: 2 retries, 1s base backoff
    for (const p of policy.command_classification.fast.patterns) {
        if (cmdLower.includes(p.toLowerCase())) return { maxRetries: 2, baseBackoffMs: 1000 };
    }
    // Medium commands: 1 retry, 5s backoff
    for (const p of policy.command_classification.medium.patterns) {
        if (cmdLower.includes(p.toLowerCase())) return { maxRetries: 1, baseBackoffMs: 5000 };
    }
    // Long/unknown: 0 retries (immediate fallback)
    return { maxRetries: 0, baseBackoffMs: 0 };
}

const server = new Server(
  {
    name: "mcp-shell",
    version: "1.3.0", // Phase 2.1: Added health_check + circuit breaker
  },
  { capabilities: { tools: {} } }
);

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
    return {
        tools: [
            {
                name: "execute_command",
                description: "Execute a PowerShell command. Adds meta: breakerState, fallbackSuggested.",
                inputSchema: {
                    type: "object",
                    properties: {
                        command: { type: "string", description: "PowerShell command to execute" },
                        cwd: { type: "string", description: "Working directory (optional)" },
                        useEncodedCommand: { type: "boolean", description: "Force Base64 encoding override." }
                    },
                    required: ["command"],
                },
            },
            {
                name: "health_check",
                description: "Lightweight probe returning breaker state and readiness.",
                inputSchema: { type: "object", properties: {}, required: [] },
            }
        ],
    };
});

// Execute command tool
server.setRequestHandler(CallToolRequestSchema, async (request) => {
    // health_check tool
    if (request.params.name === "health_check") {
        considerHalfOpen();
        const payload = {
            status: mcpState.breaker === "OPEN" ? "degraded" : "ok",
            breakerState: mcpState.breaker,
            consecutiveFailures: mcpState.consecutiveFailures,
            nextProbeTs: mcpState.nextProbeTs,
            ts: Date.now()
        };
        return {
            content: [{ type: "text", text: JSON.stringify(payload, null, 2) }]
        };
    }

    if (request.params.name !== "execute_command") {
        throw new Error(`Unknown tool: ${request.params.name}`);
    }

    // Breaker OPEN: immediate fallback suggestion
    if (mcpState.breaker === "OPEN") {
        considerHalfOpen();
        if (mcpState.breaker === "OPEN") {
            return {
                content: [
                    {
                        type: "text",
                        text: JSON.stringify({
                            exitCode: null,
                            stdout: "",
                            stderr: "Circuit breaker OPEN - suggest terminal fallback.",
                            meta: {
                                breakerState: mcpState.breaker,
                                fallbackSuggested: true,
                                consecutiveFailures: mcpState.consecutiveFailures
                            }
                        }, null, 2)
                    }
                ],
                isError: true
            };
        }
    }

    const { command, cwd, useEncodedCommand } = request.params.arguments as {
        command: string;
        cwd?: string;
        useEncodedCommand?: boolean;
    };

    // ORDER 51.7: Get timeout based on command classification
    const timeoutMs = getCommandTimeout(command);
    
    // Phase 1 v0.4.0: Determine if Base64 encoding is needed
    const needsEncoding = useEncodedCommand ?? requiresEncoding(command);
    
    let powershellArgs: string[];
    if (needsEncoding) {
        const encodedCommand = encodeCommandToBase64(command);
        powershellArgs = ["-NoProfile", "-NonInteractive", "-EncodedCommand", encodedCommand];
        console.error(`[MCP] Using Base64 encoding (detected special chars)`);
    } else {
        powershellArgs = ["-Command", command];
    }
    
    console.error(`[MCP] Executing command with ${timeoutMs / 1000}s timeout: ${command}`);

    // P4: Retry wrapper
    const retryConfig = getRetryConfig(command);
    const canRetry = isIdempotent(command) && retryConfig.maxRetries > 0;
    let attemptNumber = 0;

    const executeWithRetry = async (): Promise<any> => {
        attemptNumber++;
        return new Promise((resolve, reject) => {
            const proc = spawn("powershell", powershellArgs, {
                cwd: cwd || process.cwd(),
                shell: true,
            });

            let stdout = "";
            let stderr = "";
            let timedOut = false;
            let noOutputKilled = false;
            const startTs = Date.now();
            const policy = loadTimeoutPolicy();
            let lastOutputTs = Date.now();

            // P3: No-output watchdog
            const noOutputInterval = setInterval(() => {
                const sinceLastOutput = Date.now() - lastOutputTs;
                if (sinceLastOutput > policy.timeouts.no_output_timeout_sec * 1000) {
                    noOutputKilled = true;
                    clearInterval(noOutputInterval);
                    writeMcpLog(`NO_OUTPUT_TIMEOUT cmd=${command.substring(0, 50)} sinceLastMs=${sinceLastOutput}`);
                    proc.kill("SIGTERM");
                    setTimeout(() => { if (!proc.killed) proc.kill("SIGKILL"); }, policy.timeouts.hard_kill_timeout_sec * 1000);
                }
            }, 1000);

            // Main exec timeout
            const timeoutHandle = setTimeout(() => {
                clearInterval(noOutputInterval);
                timedOut = true;
                writeMcpLog(`EXEC_TIMEOUT cmd=${command.substring(0, 50)} timeout=${timeoutMs}ms`);
                proc.kill("SIGTERM");
                // P3: Use soft/hard kill from policy
                setTimeout(() => { if (!proc.killed) proc.kill("SIGKILL"); }, policy.timeouts.hard_kill_timeout_sec * 1000);
            }, timeoutMs);

            proc.stdout.on("data", d => {
                stdout += d.toString();
                lastOutputTs = Date.now();
            });
            proc.stderr.on("data", d => {
                stderr += d.toString();
                lastOutputTs = Date.now();
            });

            proc.on("close", code => {
                clearTimeout(timeoutHandle);
                clearInterval(noOutputInterval);
                if (timedOut || noOutputKilled) {
                    // P4: Retry logic for timeout
                    if (canRetry && attemptNumber < retryConfig.maxRetries + 1) {
                        const backoffMs = retryConfig.baseBackoffMs * Math.pow(2, attemptNumber - 1);
                        writeMcpLog(`RETRY attempt=${attemptNumber}/${retryConfig.maxRetries + 1} backoffMs=${backoffMs}`);
                        setTimeout(() => {
                            executeWithRetry().then(resolve).catch(reject);
                        }, backoffMs);
                        return;
                    }
                    recordFailure(noOutputKilled ? "no_output_timeout" : "timeout_exec");
                    resolve({
                        content: [{
                            type: "text",
                            text: JSON.stringify({
                                exitCode: -1,
                                stdout,
                                stderr: noOutputKilled
                                    ? `No output for ${policy.timeouts.no_output_timeout_sec}s (process hung)`
                                    : `Command timeout after ${timeoutMs / 1000}s`,
                                meta: {
                                    breakerState: mcpState.breaker,
                                    classification: noOutputKilled ? "no_output_timeout" : "timeout_exec",
                                    durationMs: Date.now() - startTs,
                                    retryAttempt: attemptNumber,
                                    maxRetries: retryConfig.maxRetries
                                }
                            }, null, 2)
                        }],
                        isError: true
                    });
                    return;
                }
                // Normal close
                const classification = code === 0 ? "success" : (stderr ? "exec_error" : "unknown_error");
                if (code === 0) {
                    recordSuccess();
                } else {
                    // P4: Retry for exec_error if idempotent
                    if (canRetry && attemptNumber < retryConfig.maxRetries + 1) {
                        const backoffMs = retryConfig.baseBackoffMs * Math.pow(2, attemptNumber - 1);
                        writeMcpLog(`RETRY_ERROR attempt=${attemptNumber}/${retryConfig.maxRetries + 1} exitCode=${code}`);
                        setTimeout(() => {
                            executeWithRetry().then(resolve).catch(reject);
                        }, backoffMs);
                        return;
                    }
                    recordFailure(classification);
                }
                resolve({
                    content: [{
                        type: "text",
                        text: JSON.stringify({
                            exitCode: code,
                            stdout,
                            stderr,
                            meta: {
                                breakerState: mcpState.breaker,
                                classification,
                                consecutiveFailures: mcpState.consecutiveFailures,
                                fallbackSuggested: mcpState.breaker === "OPEN",
                                durationMs: Date.now() - startTs,
                                retryAttempt: attemptNumber,
                                maxRetries: retryConfig.maxRetries
                            }
                        }, null, 2)
                    }],
                    isError: code !== 0
                });
            });

            proc.on("error", error => {
                clearTimeout(timeoutHandle);
                clearInterval(noOutputInterval);
                if (timedOut || noOutputKilled) return;
                recordFailure("spawn_error");
                reject(new Error(`Failed to execute command: ${error.message}`));
            });
        });
    };

    return executeWithRetry();
});

// Start server
async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error("MCP Shell Server running on stdio");
}

main().catch((error) => {
    console.error("Server error:", error);
    process.exit(1);
});
