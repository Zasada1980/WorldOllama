# 2025-11-24 — Connector Integration Task

## Background
- Goal: Stand up a sandbox-friendly connector package that talks to the LightRAG API (port 8003) via the Python SDK.
- Inputs: `inputs/connectors/python/library_client.py`, LightRAG server contract from `inputs/connectors/README.md`, repo reference PRICE_PC.
- Constraints: Work stays inside `sandbox_main`, document every step, produce report and MANUAL updates.

## Plan
1. Create dedicated workspace under `scripts/knowledge_connector/` with isolated requirements file and helper CLI.
2. Vendor the current `library_client.py` into the workspace and add CLI wrapper for health check + canned queries.
3. Document run instructions + env setup, capture example outputs into `outputs/connector/2025-11-24`.
4. Update `MANUAL.md` with connector location + runbook references.

## Open Questions
- LightRAG server availability? If offline, keep CLI dry-run friendly and document how to swap base URL.
- Need TS SDK? current priority is Python (per request) — leave TODO hook in README.
