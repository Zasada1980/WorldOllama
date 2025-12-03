# MCP Shell E2E Tests

## Scripts
- `npm run e2e:stress` — 10 parallel tool calls, validates concurrency limiter stability.
- `npm run e2e:failures` — breaker OPEN sequence and recovery; Base64 pipeline sanity.
- `npm run e2e:watchdog` — verifies `no_output_timeout` classification via a no-output command.

## Environment
- Set `WORLD_OLLAMA_ROOT` to project root (e.g., `e:\WORLD_OLLAMA`).
- `MCP_LOG_MIRROR_ROOT=1` to mirror logs to root (default on in server).

## Quick Start
```powershell
Set-Location 'e:\WORLD_OLLAMA\mcp-shell'
$env:WORLD_OLLAMA_ROOT='e:\WORLD_OLLAMA'
$env:MCP_LOG_MIRROR_ROOT='1'
npm run e2e:stress
npm run e2e:failures
npm run e2e:watchdog
```

## Interpreting Results
- Check `logs/mcp/mcp-events.log` or `mcp-shell/logs/mcp/mcp-events.log`.
- Use `scripts/analyze_mcp_metrics.ps1` for quick stats.
- Use `scripts/collect_mcp_metrics.ps1` to emit JSON/CSV summaries under `logs/mcp/metrics/`.
