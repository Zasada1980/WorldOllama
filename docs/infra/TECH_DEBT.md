# TECH DEBT — Non‑Critical Items (PHASE 2.x)
Date: 2025-12-02
Owner: GitHub Copilot

## Scope
Non‑critical improvements deferred to later iterations. Do not block releases.

## Backlog (Priority: LOW/MEDIUM)

Status update (2025-12-02):
- P5 Concurrency Limiter — COMPLETED: Max 5 concurrent with queue; stress test 10 parallel succeeded.
- Log Aggregation to Project Root — COMPLETED: Mirroring enabled via `MCP_LOG_MIRROR_ROOT` (default on) and `WORLD_OLLAMA_ROOT`.
- P8 Error Catalog Expansion — PARTIAL: Centralized module `mcp-shell/error_catalog.ts` created with base mappings.
- Metrics Analyzer — UPDATED: Fallback to `mcp-shell/logs/mcp` when root log missing.
 - P9 Metrics Dashboard — PARTIAL: Added `scripts/collect_mcp_metrics.ps1` exporting JSON/CSV summaries.
 - Health Probe Tuning — COMPLETED: Breaker `base_backoff_ms` and `jitter_ms` configurable via policy with jitter applied.
 - P10 Extended E2E — PARTIAL: Added watchdog test `npm run e2e:watchdog` to verify `no_output_timeout` classification.
 - Error Catalog Expansion — COMPLETED: Added mappings for file not found, access denied, path issues and stderr-based refinement.
 - HALF_OPEN Probe Outcomes — COMPLETED: Log outcomes success/failure and reschedule OPEN with backoff on failure.
 - Extended E2E — COMPLETED: Added tests `npm run e2e:softkill` and `npm run e2e:long`.
 - Metrics Summary — COMPLETED: Added `logs/mcp/metrics/README.md` for summary artifacts.

- P5 Concurrency Limiter (MEDIUM)
  - Implement max concurrent MCP executions (e.g., 5) with queueing. ✅ Done
  - Add simple rate limiter per tool (`execute_command`). ⏳ Optional (future)
  - Success criteria: 10+ parallel requests complete without starvation or race. ✅ Met

- P9 Metrics Dashboard (MEDIUM)
  - Convert `scripts/analyze_mcp_metrics.ps1` into periodic collector with CSV/JSON output.
    ✅ Implemented `scripts/collect_mcp_metrics.ps1` for one-shot JSON/CSV export.
  - Add p95/p99, error rate, breaker OPEN time, retry histogram.
  - Optional: small HTML/Markdown summary under `logs/mcp/metrics/`.

- P10 Extended E2E (MEDIUM)
  - Full watchdog scenario without `--quick`: verify `no_output_timeout` classification. ✅ Implemented `e2e/test_watchdog_no_output.ts`.
  - Add test for soft_kill timeout observance (SIGTERM grace)
  - Add test for long commands (npm/cargo) ensuring no retry.

- P8 Error Catalog Expansion (LOW)
  - Expand `errorCode`/`userMessage` mapping: file not found, access denied, path issues. ✅ Done
  - Centralize mapping in a small module for reuse. ✅ Done (`mcp-shell/error_catalog.ts`)

- Log Aggregation to Project Root (LOW)
  - Ensure logs always mirror to `E:/WORLD_OLLAMA/logs/mcp/mcp-events.log` regardless of CWD. ✅ Done
  - Option: env flag `MCP_LOG_MIRROR_ROOT=1` to enable copy/append. ✅ Implemented (default on)

- Health Probe Tuning (LOW)
  - Make `BASE_BACKOFF_MS` configurable from policy, add jitter. ✅ Done (`server.ts`).
  - Record probe outcomes for OPEN→HALF_OPEN transitions. ✅ Done (PROBE_RESULT logs)

- Encoding Edge Cases (LOW)
  - Add tests for very long commands, mixed CRLF/LF, complex Unicode (RTL, ZWJ), null bytes safeguards.

- Documentation & Examples (LOW)
  - Short README for `mcp-shell/e2e/` on how to run tests locally. ✅ Done
  - Add examples of interpreting `meta` and logs for troubleshooting. ✅ Included in README

## Consensus Research Follow-ups (LOW)

- WorkspaceFolder vs Env Resolution
  - Avoid `${workspaceFolder}` in MCP command args; prefer relative paths and `env` injection.
  - Standardize root resolution in servers: `WORLD_OLLAMA_ROOT || process.cwd()`.
  - Document path rules in `.github/copilot-instructions.md` and ensure tests cover CWD changes.

- SDK‑Managed Spawning
  - Prefer `StdioClientTransport({ command, args, cwd, env })` for portability on Windows.
  - Avoid shell expansion reliance; pass variables via `env` explicitly.
  - Add sample snippet and guidance under `docs/infra/SETTINGS_UPGRADE_TZ_MAP.md`.

## Notes
- These items improve robustness and observability but are not release blockers.
- Group work by pillar to batch changes efficiently.
