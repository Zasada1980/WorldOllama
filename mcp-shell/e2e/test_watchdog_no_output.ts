import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";

async function run() {
  const serverCommand = process.execPath; // node
  const args = ["./dist/server.js"]; // run built server
  const cwd = process.cwd();
  const env = { ...process.env, WORLD_OLLAMA_ROOT: process.env.WORLD_OLLAMA_ROOT || cwd, MCP_LOG_MIRROR_ROOT: "1" };

  const transport = new StdioClientTransport({ command: serverCommand, args, cwd, env });
  const client = new Client({ name: "e2e-client", version: "1.0.0" });
  await client.connect(transport);

  // Command that produces no output for 35s, expect no_output_timeout (policy default 30s)
  const cmd = "Start-Sleep -Seconds 35";
  const res = await client.callTool({ name: "execute_command", arguments: { command: cmd } });
  const text = (res.content[0] as any).text;
  const payload = JSON.parse(text);
  console.log("classification:", payload.meta.classification);
  console.log("stderr:", payload.stderr);
  process.exit(payload.meta.classification === "no_output_timeout" ? 0 : 1);
}

run().catch(err => { console.error(err); process.exit(2); });
