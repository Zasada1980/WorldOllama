#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { CallToolRequestSchema, ListToolsRequestSchema, } from "@modelcontextprotocol/sdk/types.js";
import { spawn } from "child_process";
import { getErrorInfo, classifyByStderr } from "./error_catalog.js";
import * as fs from "fs";
import * as path from "path";
let timeoutPolicy = null;
function loadTimeoutPolicy() {
    if (timeoutPolicy)
        return timeoutPolicy;
    try {
        // GLOBAL MCP: Load config from server's own directory (independent of any project)
        const serverDir = path.dirname(process.argv[1] || __dirname);
        const policyPath = path.join(serverDir, "config", "terminal_timeout_policy.json");
        if (fs.existsSync(policyPath)) {
            const content = fs.readFileSync(policyPath, "utf-8");
            timeoutPolicy = JSON.parse(content);
            console.error(`[MCP] Loaded timeout policy from: ${policyPath}`);
            return timeoutPolicy;
        }
    }
    catch (error) {
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
function encodeCommandToBase64(rawCommand) {
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
function requiresEncoding(command) {
    // Characters that commonly cause Exit Code 255 in PowerShell
    const dangerousChars = /[|{}$"'`]/;
    return dangerousChars.test(command);
}
function getCommandTimeout(command) {
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
const mcpState = {
    breaker: "CLOSED",
    consecutiveFailures: 0,
    lastFailureTs: 0,
    nextProbeTs: 0,
};
const FAILURE_THRESHOLD = 3; // 3 подряд ошибки → OPEN
function getBaseBackoffMs() {
    const policy = loadTimeoutPolicy();
    return policy.breaker?.base_backoff_ms ?? 5000;
}
function getJitterMs() {
    const policy = loadTimeoutPolicy();
    return policy.breaker?.jitter_ms ?? 500;
}
function writeMcpLog(line) {
    try {
        const cwdRoot = process.cwd();
        const projectRoot = process.env.WORLD_OLLAMA_ROOT || cwdRoot;
        const entry = `[${new Date().toISOString()}] ${line}\n`;
        // Primary log under current working root
        const primaryDir = path.join(cwdRoot, "logs", "mcp");
        if (!fs.existsSync(primaryDir))
            fs.mkdirSync(primaryDir, { recursive: true });
        fs.appendFileSync(path.join(primaryDir, "mcp-events.log"), entry, { encoding: "utf-8" });
        // Optional mirroring to project root logs when running from subfolder (e.g., mcp-shell)
        const enableMirror = (process.env.MCP_LOG_MIRROR_ROOT || "1") === "1"; // default on per PHASE 2.3
        if (enableMirror && path.resolve(projectRoot) !== path.resolve(cwdRoot)) {
            const mirrorDir = path.join(projectRoot, "logs", "mcp");
            if (!fs.existsSync(mirrorDir))
                fs.mkdirSync(mirrorDir, { recursive: true });
            fs.appendFileSync(path.join(mirrorDir, "mcp-events.log"), entry, { encoding: "utf-8" });
        }
    }
    catch (e) {
        console.error(`[MCP] Log write failed: ${e}`);
    }
}
function recordFailure(classification) {
    mcpState.consecutiveFailures++;
    mcpState.lastFailureTs = Date.now();
    writeMcpLog(`FAIL classification=${classification} count=${mcpState.consecutiveFailures}`);
    if (mcpState.consecutiveFailures >= FAILURE_THRESHOLD && mcpState.breaker === "CLOSED") {
        mcpState.breaker = "OPEN";
        const jitter = Math.floor(Math.random() * getJitterMs());
        mcpState.nextProbeTs = Date.now() + getBaseBackoffMs() + jitter;
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
function isIdempotent(cmd) {
    const readOnlyPatterns = /^(dir|ls|cat|type|echo|get-content|test-path|git status|nvidia-smi|pwd|which)/i;
    return readOnlyPatterns.test(cmd.trim());
}
function getRetryConfig(cmd) {
    const policy = loadTimeoutPolicy();
    const cmdLower = cmd.toLowerCase();
    // Fast commands: 2 retries, 1s base backoff
    for (const p of policy.command_classification.fast.patterns) {
        if (cmdLower.includes(p.toLowerCase()))
            return { maxRetries: 2, baseBackoffMs: 1000 };
    }
    // Medium commands: 1 retry, 5s backoff
    for (const p of policy.command_classification.medium.patterns) {
        if (cmdLower.includes(p.toLowerCase()))
            return { maxRetries: 1, baseBackoffMs: 5000 };
    }
    // Long/unknown: 0 retries (immediate fallback)
    return { maxRetries: 0, baseBackoffMs: 0 };
}
const server = new Server({
    name: "mcp-shell",
    version: "1.3.1", // Phase 2.3: UX error mapping, retry/watchdog finalized
}, { capabilities: { tools: {} } });
// === P5: Concurrency Limiter (max 5 concurrent execute_command) ===
const MAX_CONCURRENT = 5;
let activeCount = 0;
const pendingQueue = [];
function acquireSlot() {
    return new Promise(resolve => {
        const tryAcquire = () => {
            if (activeCount < MAX_CONCURRENT) {
                activeCount++;
                resolve();
            }
            else {
                pendingQueue.push(tryAcquire);
            }
        };
        tryAcquire();
    });
}
function releaseSlot() {
    activeCount = Math.max(0, activeCount - 1);
    const next = pendingQueue.shift();
    if (next)
        setImmediate(next);
}
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
                                consecutiveFailures: mcpState.consecutiveFailures,
                                errorCode: "MCP_BREAKER_OPEN",
                                userMessage: "Сервис MCP временно недоступен. Переключаюсь на Terminal fallback."
                            }
                        }, null, 2)
                    }
                ],
                isError: true
            };
        }
    }
    const { command, cwd, useEncodedCommand } = request.params.arguments;
    // ORDER 51.7: Get timeout based on command classification
    const timeoutMs = getCommandTimeout(command);
    // Phase 1 v0.4.0: Determine if Base64 encoding is needed
    const needsEncoding = useEncodedCommand ?? requiresEncoding(command);
    let powershellArgs;
    if (needsEncoding) {
        const encodedCommand = encodeCommandToBase64(command);
        powershellArgs = ["-NoProfile", "-NonInteractive", "-EncodedCommand", encodedCommand];
        console.error(`[MCP] Using Base64 encoding (detected special chars)`);
    }
    else {
        powershellArgs = ["-Command", command];
    }
    console.error(`[MCP] Executing command with ${timeoutMs / 1000}s timeout: ${command}`);
    // P4: Retry wrapper
    const retryConfig = getRetryConfig(command);
    const canRetry = isIdempotent(command) && retryConfig.maxRetries > 0;
    let attemptNumber = 0;
    const executeWithRetry = async () => {
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
                    setTimeout(() => { if (!proc.killed)
                        proc.kill("SIGKILL"); }, policy.timeouts.hard_kill_timeout_sec * 1000);
                }
            }, 1000);
            // Main exec timeout
            const timeoutHandle = setTimeout(() => {
                clearInterval(noOutputInterval);
                timedOut = true;
                writeMcpLog(`EXEC_TIMEOUT cmd=${command.substring(0, 50)} timeout=${timeoutMs}ms`);
                proc.kill("SIGTERM");
                // P3: Use soft/hard kill from policy
                setTimeout(() => { if (!proc.killed)
                    proc.kill("SIGKILL"); }, policy.timeouts.hard_kill_timeout_sec * 1000);
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
                    const classification = noOutputKilled ? "no_output_timeout" : "timeout_exec";
                    const err = getErrorInfo(classification);
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
                                        classification,
                                        durationMs: Date.now() - startTs,
                                        retryAttempt: attemptNumber,
                                        maxRetries: retryConfig.maxRetries,
                                        errorCode: err.code,
                                        userMessage: err.userMessage
                                    }
                                }, null, 2)
                            }],
                        isError: true
                    });
                    return;
                }
                // Normal close
                let classificationNorm = code === 0 ? "success" : (stderr ? "exec_error" : "unknown_error");
                if (code !== 0 && stderr) {
                    const refined = classifyByStderr(stderr);
                    if (refined)
                        classificationNorm = refined;
                }
                if (code === 0) {
                    recordSuccess();
                    // Log HALF_OPEN probe recovery
                    if (mcpState.breaker === "HALF_OPEN") {
                        writeMcpLog(`PROBE_RESULT state=HALF_OPEN outcome=success`);
                    }
                    writeMcpLog(`SUCCESS durationMs=${Date.now() - startTs} breakerState=${mcpState.breaker}`);
                }
                else {
                    // P4: Retry for exec_error if idempotent
                    if (canRetry && attemptNumber < retryConfig.maxRetries + 1) {
                        const backoffMs = retryConfig.baseBackoffMs * Math.pow(2, attemptNumber - 1);
                        writeMcpLog(`RETRY_ERROR attempt=${attemptNumber}/${retryConfig.maxRetries + 1} exitCode=${code}`);
                        setTimeout(() => {
                            executeWithRetry().then(resolve).catch(reject);
                        }, backoffMs);
                        return;
                    }
                    // Log HALF_OPEN probe failure
                    if (mcpState.breaker === "HALF_OPEN") {
                        writeMcpLog(`PROBE_RESULT state=HALF_OPEN outcome=failure`);
                        // return to OPEN with nextProbe scheduled
                        mcpState.breaker = "OPEN";
                        const jitter = Math.floor(Math.random() * getJitterMs());
                        mcpState.nextProbeTs = Date.now() + getBaseBackoffMs() + jitter;
                    }
                    recordFailure(typeof classificationNorm === "string" ? classificationNorm : "unknown_error");
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
                                    classification: classificationNorm,
                                    consecutiveFailures: mcpState.consecutiveFailures,
                                    fallbackSuggested: mcpState.breaker === "OPEN",
                                    durationMs: Date.now() - startTs,
                                    retryAttempt: attemptNumber,
                                    maxRetries: retryConfig.maxRetries,
                                    ...(code === 0 ? {} : (() => { const err = getErrorInfo(classificationNorm); return { errorCode: err.code, userMessage: err.userMessage }; })())
                                }
                            }, null, 2)
                        }],
                    isError: code !== 0
                });
                releaseSlot();
            });
            proc.on("error", error => {
                clearTimeout(timeoutHandle);
                clearInterval(noOutputInterval);
                if (timedOut || noOutputKilled)
                    return;
                recordFailure("spawn_error");
                reject(new Error(`Failed to execute command: ${error.message}`));
                releaseSlot();
            });
        });
    };
    return acquireSlot().then(() => executeWithRetry()).catch(err => {
        releaseSlot();
        throw err;
    });
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
