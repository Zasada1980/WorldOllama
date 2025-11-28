#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
    CallToolRequestSchema,
    ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { spawn } from "child_process";

const server = new Server(
    {
        name: "mcp-shell",
        version: "1.0.0",
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

    return new Promise((resolve, reject) => {
        const proc = spawn("powershell", ["-Command", command], {
            cwd: cwd || process.cwd(),
            shell: true,
        });

        let stdout = "";
        let stderr = "";

        proc.stdout.on("data", (data) => {
            stdout += data.toString();
        });

        proc.stderr.on("data", (data) => {
            stderr += data.toString();
        });

        proc.on("close", (code) => {
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
