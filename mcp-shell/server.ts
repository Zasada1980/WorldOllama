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

// ORDER 51.7: Load timeout policy from config
interface TimeoutPolicy {
    timeouts: {
        default_exec_timeout_sec: number;
        max_exec_timeout_sec: number;
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
    
    // Fallback to default policy
    timeoutPolicy = {
        timeouts: {
            default_exec_timeout_sec: 120,
            max_exec_timeout_sec: 900,
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

const server = new Server(
    {
        name: "mcp-shell",
        version: "1.1.0", // ORDER 51.7: Bump version for timeout support
    },
    {
        capabilities: {
            tools: {},
        },
    }
);

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
    return {
        tools: [
            {
                name: "execute_command",
                description: "Execute a PowerShell command and return the output",
                inputSchema: {
                    type: "object",
                    properties: {
                        command: {
                            type: "string",
                            description: "PowerShell command to execute",
                        },
                        cwd: {
                            type: "string",
                            description: "Working directory (optional)",
                        },
                    },
                    required: ["command"],
                },
            },
        ],
    };
});

// Execute command tool
server.setRequestHandler(CallToolRequestSchema, async (request) => {
    if (request.params.name !== "execute_command") {
        throw new Error(`Unknown tool: ${request.params.name}`);
    }

    const { command, cwd } = request.params.arguments as {
        command: string;
        cwd?: string;
    };

    // ORDER 51.7: Get timeout based on command classification
    const timeoutMs = getCommandTimeout(command);
    console.error(`[MCP] Executing command with ${timeoutMs / 1000}s timeout: ${command}`);

    return new Promise((resolve, reject) => {
        const proc = spawn("powershell", ["-Command", command], {
            cwd: cwd || process.cwd(),
            shell: true,
        });

        let stdout = "";
        let stderr = "";
        let timedOut = false;

        // Setup timeout
        const timeoutHandle = setTimeout(() => {
            timedOut = true;
            proc.kill("SIGTERM");
            
            // Force kill after 5 seconds if SIGTERM didn't work
            setTimeout(() => {
                if (!proc.killed) {
                    proc.kill("SIGKILL");
                }
            }, 5000);
            
            resolve({
                content: [
                    {
                        type: "text",
                        text: JSON.stringify({
                            exitCode: -1,
                            stdout: stdout,
                            stderr: `Command timeout after ${timeoutMs / 1000}s: ${command}`,
                        }, null, 2),
                    },
                ],
                isError: true,
            });
        }, timeoutMs);

        proc.stdout.on("data", (data) => {
            stdout += data.toString();
        });

        proc.stderr.on("data", (data) => {
            stderr += data.toString();
        });

        proc.on("close", (code) => {
            clearTimeout(timeoutHandle);
            
            if (timedOut) {
                return; // Already resolved by timeout
            }
            
            resolve({
                content: [
                    {
                        type: "text",
                        text: JSON.stringify({
                            exitCode: code,
                            stdout: stdout,
                            stderr: stderr,
                        }, null, 2),
                    },
                ],
            });
        });

        proc.on("error", (error) => {
            clearTimeout(timeoutHandle);
            
            if (timedOut) {
                return; // Already resolved by timeout
            }
            
            reject(new Error(`Failed to execute command: ${error.message}`));
        });
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
