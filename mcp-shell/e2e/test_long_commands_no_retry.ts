import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";

async function run() {
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: ["./dist/server.js"],
    cwd: process.cwd(),
    env: { ...process.env, WORLD_OLLAMA_ROOT: process.env.WORLD_OLLAMA_ROOT || process.cwd(), MCP_LOG_MIRROR_ROOT: "1" }
  });
  const client = new Client({ name: "e2e-client", version: "1.0.0" });
  await client.connect(transport);

  // Long command class: npm (should be classified 'long' and have 0 retries)
  const res = await client.callTool({ name: "execute_command", arguments: { command: "npm run nonexist" } });
  const payload = JSON.parse((res.content[0] as any).text);
  const retryAttempt = payload.meta.retryAttempt;
  const maxRetries = payload.meta.maxRetries;
  console.log("retryAttempt:", retryAttempt, "maxRetries:", maxRetries);
  // Expect retryAttempt==1 and maxRetries==0
  process.exit(retryAttempt === 1 && maxRetries === 0 ? 0 : 1);
}

run().catch(err => { console.error(err); process.exit(2); });
