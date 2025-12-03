#!/usr/bin/env -S node --loader tsx
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import * as path from "path";

function sleep(ms: number) { return new Promise(r => setTimeout(r, ms)); }

async function run() {
  const cwd = process.cwd();
  const nodeBin = process.execPath;
  const serverJs = path.join(cwd, 'dist', 'server.js');
  const client = new Client({ name: 'mcp-stress', version: '0.1.0' });
  const transport = new StdioClientTransport({
    command: nodeBin,
    args: [ serverJs ],
    cwd,
    env: { ...process.env, WORLD_OLLAMA_ROOT: cwd }
  } as any);
  await client.connect(transport);

  const concurrency = 10;
  const start = Date.now();

  const tasks = Array.from({ length: concurrency }, (_, i) => client.callTool({
    name: 'execute_command',
    arguments: { command: i % 2 === 0 ? 'Get-Date' : 'Get-Process | Select-Object -First 1' }
  }).then(res => JSON.parse(res.content[0].text as string)));

  const results = await Promise.allSettled(tasks);
  const duration = Date.now() - start;

  const successes = results.filter(r => r.status === 'fulfilled' && (r as any).value.exitCode === 0).length;
  const failures  = results.length - successes;

  console.log(`Concurrency: ${concurrency}, duration=${duration}ms, success=${successes}, failures=${failures}`);
  if (failures > 0) {
    console.log('❌ Some tasks failed');
    process.exitCode = 1;
  } else {
    console.log('✅ All parallel tasks succeeded');
  }
}

run().catch(e => { console.error(e); process.exit(1); });
