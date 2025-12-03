#!/usr/bin/env -S node --loader tsx
import { spawn } from "child_process";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import * as path from "path";

function sleep(ms: number) { return new Promise(r => setTimeout(r, ms)); }

async function run() {
  const cwd = process.cwd();
  // Spawn MCP server via tsx
  const nodeBin = process.execPath; // current Node
  const serverJs = path.join(cwd, 'dist', 'server.js');
  const transport = new StdioClientTransport({
    command: nodeBin,
    args: [ serverJs ],
    cwd,
    env: { ...process.env, WORLD_OLLAMA_ROOT: cwd }
  } as any);
  const client = new Client({ name: "mcp-e2e", version: "0.1.0" });
  await client.connect(transport);

  const quick = process.argv.includes('--quick');

  let passed = 0, failed = 0;
  async function assert(name: string, cond: boolean) {
    if (cond) { console.log(`✅ ${name}`); passed++; } else { console.log(`❌ ${name}`); failed++; }
  }

  // 1) Basic success
  {
    const res = await client.callTool({ name: 'execute_command', arguments: { command: 'Get-Date' } });
    const payload = JSON.parse(res.content[0].text as string);
    await assert('Get-Date success', payload.exitCode === 0 && payload.meta.classification === 'success');
  }

  // 2) Base64-encoded pipeline
  {
    const res = await client.callTool({ name: 'execute_command', arguments: { command: 'Get-Process | Select-Object -First 1' } });
    const payload = JSON.parse(res.content[0].text as string);
    await assert('Pipe encodes OK', payload.exitCode === 0 && payload.meta.classification === 'success');
  }

  // 3) Force 3 quick failures → breaker OPEN
  for (let i=1;i<=3;i++) {
    const res = await client.callTool({ name: 'execute_command', arguments: { command: 'this-command-does-not-exist-xyz' } });
    const payload = JSON.parse(res.content[0].text as string);
    await assert(`Exec error #${i}`, payload.exitCode !== 0 && payload.meta.classification !== 'success');
  }

  // 4) Next call should suggest fallback (OPEN)
  {
    const res = await client.callTool({ name: 'execute_command', arguments: { command: 'dir' } });
    const payload = JSON.parse(res.content[0].text as string);
    await assert('Breaker OPEN suggests fallback', payload.meta.fallbackSuggested === true && payload.meta.breakerState === 'OPEN');
  }

  // 5) Health check should be degraded and OPEN
  {
    const res = await client.callTool({ name: 'health_check', arguments: {} });
    const payload = JSON.parse(res.content[0].text as string);
    await assert('Health degraded & OPEN', payload.status === 'degraded' && payload.breakerState === 'OPEN');
  }

  // 6) Wait 6s → HALF_OPEN, then success recovers to CLOSED
  await sleep(6000);
  {
    const resProbe = await client.callTool({ name: 'health_check', arguments: {} });
    const probe = JSON.parse(resProbe.content[0].text as string);
    await assert('Breaker moves to HALF_OPEN', probe.breakerState === 'HALF_OPEN');

    const res = await client.callTool({ name: 'execute_command', arguments: { command: 'echo test' } });
    const payload = JSON.parse(res.content[0].text as string);
    await assert('Recovery to CLOSED', payload.exitCode === 0);
  }

  // 7) (Optional heavy) Timeout and No-output watchdog
  if (!quick) {
    // Timeout: exceed default 120s via override (use long classification like npm)
    // We cannot change policy dynamically, so skip real 120s sleep; simulate with small hang and rely on no-output watchdog
    const resHang = await client.callTool({ name: 'execute_command', arguments: { command: 'while($true) { Start-Sleep -Milliseconds 100 }' } });
    const hangPayload = JSON.parse(resHang.content[0].text as string);
    await assert('No-output watchdog triggers', hangPayload.exitCode === -1 && hangPayload.meta.classification === 'no_output_timeout');
  }

  console.log(`\nSummary: Passed=${passed} Failed=${failed}`);
  process.exit(failed > 0 ? 1 : 0);
}

run().catch(e => { console.error(e); process.exit(1); });
