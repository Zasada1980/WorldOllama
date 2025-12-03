# WORLD_OLLAMA Project Map

**Generated:** 2025-11-26 (VERIFIED)  
**Root:** `E:\WORLD_OLLAMA`  
**Status:** ✅ Physically verified structure

---

## 📁 Directory Structure (REAL, не гипотеза)

```
E:\WORLD_OLLAMA\
├── .github/
│   └── copilot-instructions.md       # AI Copilot configuration
│
├── agents/                            # Multi-Agent structure (config only)
│   ├── qwen2-main/
│   │   ├── configs/
│   │   │   └── Modelfile_qwen2_main  # Ollama Modelfile
│   │   └── scripts/
│   │       └── install_qwen_model.ps1
│   └── helper-lite/
│       ├── configs/
│       └── scripts/
│
├── backups/
│   ├── archived_reports/              # Устаревшие отчёты
│   ├── daily/
│   ├── weekly/
│   └── manual/
│
├── production/                        # ✅ Production модели
│   └── TD010v2_triz_full/            # eval_loss 0.8591 (CERTIFIED)
│       ├── adapter_model.safetensors # 35.27 MB
│       └── all_results.json
│
├── archive/                           # ✅ Архив моделей и скриптов
│   ├── TD010v2_triz_extended/        # Legacy (eval_loss 0.9358)
│   ├── Qwen2-7B_checkpoint/          # R&D potential (539 MB)
│   └── scripts/                      # NEW: 03.12.2025 (archived 14 scripts)
│       ├── td009/                    # TD-009 iteration (3 files)
│       ├── td010_iterations/         # TD-010 development (9 files)
│       ├── legacy/                   # Obsolete utilities (2 files)
│       └── README_ARCHIVE.md         # Архивация история
│
├── saves/                             # Training checkpoints
│
├── docs/
│   └── SECURE_ENCLAVE_REPORT.md
│
├── library/                           # ✅ 179 files, 7.69 MB
│   ├── raw_documents/                # ТРИЗ + AI методологии (.txt)
│   ├── cleaned_documents/
│   └── backups/
│
├── llamaboard_cache/                  # LLaMA Board cache
│
├── logs/
│   ├── agents/
│   ├── ingestion/
│   └── services/
│
├── models/
│   ├── qwen2-triz-merged/            # Fine-tuned LoRA adapters (legacy)
│   └── triz-td010v2-merged/          # ✅ Merged HF model (2960 MB)
│       ├── model-00001-of-00002.safetensors  # 1884 MB
│       ├── model-00002-of-00002.safetensors  # 1061 MB
│       └── Modelfile                         # Ollama config
│
├── scripts/                           # ✅ 28 PowerShell scripts (cleaned 03.12.2025)
│   ├── Orchestration (3):
│   │   ├── START_ALL.ps1             # Start all services
│   │   ├── STOP_ALL.ps1              # Stop all services
│   │   └── CHECK_STATUS.ps1          # Health monitoring
│   ├── Auto-indexation (5):         # NEW: 03.12.2025 (Consensus.app Research)
│   │   ├── UPDATE_PROJECT_INDEX.ps1  # Core reindexing logic
│   │   ├── WATCH_FILE_CHANGES.ps1    # Real-time FileSystemWatcher
│   │   ├── INSTALL_GIT_HOOK.ps1      # Git hook installer
│   │   ├── post-commit.hook          # Git post-commit hook
│   │   └── CREATE_SCHEDULED_TASK.ps1 # Daily scheduled task (03:00)
│   ├── Training (2):
│   │   ├── start_agent_training.ps1  # Universal training launcher
│   │   └── BUILD_RELEASE.ps1         # Tauri release build
│   ├── Infrastructure (5):
│   │   ├── ingest_watcher.ps1        # RAG auto-indexation
│   │   ├── generate_map.ps1          # PROJECT_MAP generator
│   │   ├── generate_project_index_v51.ps1
│   │   ├── CLEANUP_VSCODE_TOOLS.ps1  # VS Code cleanup (71→51 ext)
│   │   └── cleanup_project.ps1       # Project maintenance
│   ├── Testing (6):
│   │   ├── analyze_mcp_metrics.ps1   # MCP metrics
│   │   ├── collect_mcp_metrics.ps1   # MCP dashboard
│   │   ├── test_compilation.ps1      # CI/CD validation
│   │   ├── test_compilation_detailed.ps1
│   │   └── tests/                    # E2E test suite
│   │       ├── TEST_AGENT_INTEGRATION.ps1
│   │       ├── TEST_SYSTEM_INTEGRITY.ps1
│   │       └── TEST_UPDATE_SIMULATION.ps1
│   └── Utilities (7):
│       ├── analyze_workspace.ps1
│       ├── validate_sandbox.ps1
│       ├── docker_build.ps1
│       ├── sync_to_cloud.ps1
│       ├── start_lightrag.ps1        # Standalone CORTEX
│       ├── start_neuro_terminal.ps1  # Standalone UI
│       └── start_training_ui.ps1     # LLaMA Board
│
├── services/                          # ✅ Microservices
│   ├── connectors/
│   │   └── synapse/                  # CORTEX API client
│   │       ├── knowledge_client.py   # Main connector
│   │       └── requirements.txt
│   ├── fastapi-gateways/
│   ├── lightrag/                     # CORTEX (port 8004)
│   │   ├── data/                     # ✅ 1 file (340 KB)
│   │   ├── lightrag_server.py        # 697 lines
│   │   ├── venv/
│   │   └── requirements.txt          # 8 dependencies
│   ├── llama_factory/                # Fine-tuning platform
│   │   ├── data/
│   │   │   └── triz_synthesis_v1.jsonl  # ✅ 300 lines, 480 KB
│   │   ├── triz_safe_config.yaml
│   │   ├── venv/
│   │   └── requirements.txt          # 30+ dependencies
│   └── neuro_terminal/               # UI (port 8501) - MAIN
│       ├── app.py                    # 210 lines
│       ├── .venv/                    # NOTE: .venv not venv!
│       └── requirements.txt          # 3 dependencies
│
├── USER/                              # ✅ 5 PowerShell scripts
│   ├── CHECK_STATUS.ps1
│   ├── START_ALL.ps1
│   ├── START_ALL_TEST.ps1
│   ├── STOP_ALL.ps1
│   ├── TEST_E2E.ps1
│   └── README.md
│
├── workbench/
│   └── sandbox_main/                 # Experimental workspace
│       ├── scripts/                  # ✅ 13 scripts/utilities
│       │   ├── data_forge.py         # Dataset generation
│       │   ├── force_inference_test.py
│       │   ├── ci/
│       │   └── knowledge_connector/
│       ├── inputs/                   # Legacy data (archived)
│       ├── outputs/
│       └── tmp/
│
├── NEURAL_LINK_ACTIVATION.md
├── PROJECT_MAP.md                     # ← YOU ARE HERE
├── README.md                          # ✅ Main documentation
├── STATE_SNAPSHOT_v3.1.md             # System snapshot
└── TECHNICAL_REPORT_VERIFIED.md       # ✅ Verified technical report
│   ├── qwen2-main/
│   │   ├── scripts/
│   │   ├── configs/
│   ├── helper-lite/
│   │   ├── scripts/
│   │   ├── configs/
├── RAEDME
```

---

## 🛡️ Filtering Rules

**Ignored Folders:**
- `.git`
- `venv`
- `.venv`
- `node_modules`
- `__pycache__`
- `lightrag_cache`
- `.vscode`
- `tmp`
- `temp`
- `.pytest_cache`
- `.mypy_cache`
- `dist`
- `build`
- `eggs`
- `.eggs`
- `htmlcov`
- `downloads`
- `uploads`
- `cache`
- `assets`
- `static`
- `media`
- `site-packages`
- `blobs`
- `manifests`

**Ignored Files:**
- `.DS_Store`
- `Thumbs.db`
- `desktop.ini`
- `*.pyc`
- `*.pyo`
- `*.pyd`
- `*.so`
- `*.dll`
- `*.dylib`
- `*.log`

---

**Generated by:** Living Map Generator (TD-005)  
**Script:** `generate_map.ps1`  
**Version:** 1.0 (SESA3002a Protocol)
