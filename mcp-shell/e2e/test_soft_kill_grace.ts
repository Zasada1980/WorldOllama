import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";

async function run() {
  const transport = new StdioClientTransport({ command: process.execPath, args: ["./dist/server.js"], cwd: process.cwd(), env: { ...process.env } });
  const client = new Client({ name: "e2e-client", version: "1.0.0" });
  await client.connect(transport);

  // Command exceeds main timeout to trigger soft/hard kill path; use a very long sleep
  const res = await client.callTool({ name: "execute_command", arguments: { command: "Start-Sleep -Seconds 200" } });
  const payload = JSON.parse((res.content[0] as any).text);
  console.log("stderr:", payload.stderr);
  console.log("classification:", payload.meta.classification);
  // We cannot directly assert SIGTERM grace, but classification should be timeout_exec
  process.exit(payload.meta.classification === "timeout_exec" ? 0 : 1);
}

run().catch(err => { console.error(err); process.exit(2); });
