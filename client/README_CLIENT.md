# WORLD_OLLAMA Desktop Client

**Framework:** Tauri + Rust + Svelte + TypeScript  
**Status:** 🟡 In Development (Phase 3)  
**Version:** MVP 0.1.0  
**Target Release:** 10.12.2025

---

## 📋 OVERVIEW

Десктопное приложение для взаимодействия с WORLD_OLLAMA AI-системой через нативный интерфейс.

**Core Features (MVP):**
- 💬 **Chat Interface** — Диалог с LLM (Ollama)
- 📚 **Knowledge Base Access** — Запросы через CORTEX (LightRAG)
- 🔧 **System Status** — Мониторинг Ollama/CORTEX
- ⚙ **Settings** — Выбор модели, параметры поиска
- ❌ **Error Handling** — Понятные ошибки + retry

---

## 🏗️ ARCHITECTURE

### Technology Stack

**Frontend:**
- **Svelte** — Reactive UI framework
- **TypeScript** — Type-safe JavaScript
- **Vite** — Build tool
- **Tailwind CSS** — Utility-first CSS (minimal)

**Backend (Tauri Core):**
- **Rust** — Native backend
- **Tauri v1.x** — Desktop app framework
- **reqwest** — HTTP client (Ollama/CORTEX)
- **serde** — JSON serialization

**Services (External):**
- **Ollama** — LLM inference (`http://localhost:11434`)
- **CORTEX (LightRAG)** — Knowledge retrieval (`http://localhost:8004`)

---

## 📁 PROJECT STRUCTURE

```
client/
├── src/                      # Svelte Frontend
│   ├── lib/
│   │   ├── components/       # UI Components
│   │   │   ├── Chat.svelte
│   │   │   ├── SystemStatus.svelte
│   │   │   ├── Settings.svelte
│   │   │   └── Layout.svelte
│   │   ├── stores/           # Svelte stores (state)
│   │   └── api/              # Frontend API wrappers
│   ├── routes/               # SvelteKit routes (if used)
│   └── App.svelte            # Root component
│
├── src-tauri/                # Rust Core
│   ├── src/
│   │   ├── main.rs           # Tauri app entry
│   │   ├── commands/         # Tauri commands
│   │   │   ├── ollama.rs     # Ollama integration
│   │   │   ├── cortex.rs     # CORTEX integration
│   │   │   └── system.rs     # System status
│   │   └── lib.rs
│   ├── Cargo.toml            # Rust dependencies
│   └── tauri.conf.json       # Tauri configuration
│
├── ui_stub/                  # UI prototypes (Rust-independent)
│   ├── Chat.svelte
│   ├── SystemStatus.svelte
│   ├── Settings.svelte
│   └── README.md
│
├── design_notes.md           # Architecture decisions
├── package.json              # npm dependencies
└── README_CLIENT.md          # This file
```

---

## 🚀 GETTING STARTED

### Prerequisites

**Required:**
1. **Node.js** (v18+) — Frontend build
2. **npm** or **pnpm** — Package manager
3. **Rust toolchain** — Tauri backend
   - `rustc`, `cargo`, `rustup`
   - **Installation guide:** See `../UX_SPEC/RUST_TOOLCHAIN_PREREQ.md`

**External Services (must be running):**
- Ollama (port 11434)
- CORTEX/LightRAG (port 8004)

---

### Installation

**Step 1: Install Rust (if not already):**

See `../UX_SPEC/RUST_TOOLCHAIN_PREREQ.md` for detailed instructions.

```powershell
# Verify Rust is installed
rustc --version
cargo --version
```

---

**Step 2: Initialize Tauri project (after Rust installed):**

```powershell
cd E:\WORLD_OLLAMA
npx create-tauri-app@latest client --manager npm --template svelte-ts --yes
```

---

**Step 3: Install dependencies:**

```powershell
cd client
npm install
```

---

**Step 4: Run development server:**

```powershell
npm run tauri dev
```

**Expected result:**
- Tauri app window opens
- Svelte hot-reload active
- No Rust compilation errors

---

### Build Production App

```powershell
npm run tauri build
```

**Output:**
- Windows: `src-tauri/target/release/world-ollama.exe`
- Installer: `src-tauri/target/release/bundle/nsis/world-ollama_x.x.x_x64-setup.exe`

---

## 🎨 UI DESIGN SYSTEM

**Based on:** `../UX_SPEC/06_UI_PATTERNS_AND_COMPONENTS.md`

**Key Components:**
1. **ChatMessage** — User/Assistant bubbles
2. **SourceBadge** — Document reference pills
3. **StatusIndicator** — Service health (🟢/🟡/🔴)
4. **Button** — Primary/Secondary/Danger variants
5. **Modal** — Confirmations, errors
6. **Toast** — Success/Error notifications

**Color Palette:**
- Primary: `#1976D2` (blue)
- Success: `#4CAF50` (green)
- Error: `#F44336` (red)
- Background: `#FFFFFF` (white)
- Text: `#212121` (dark grey)

**Typography:**
- Font: Inter (Google Fonts)
- Body: 14px
- Headings: 16-24px

---

## 🔌 API INTEGRATION

### Tauri Commands (Rust → Frontend)

**System Status:**
```typescript
import { invoke } from '@tauri-apps/api/tauri';

const status = await invoke('get_system_status');
// Returns: { ollama: "up", cortex: "up" }
```

**Send Chat Message:**
```typescript
const response = await invoke('send_ollama_chat', {
  message: "Explain TRIZ Principle 1",
  model: "qwen2.5:14b"
});
```

**Query CORTEX:**
```typescript
const results = await invoke('send_cortex_query', {
  query: "TRIZ drobienie principle",
  topK: 20,
  mode: "local"
});
// Returns: { answer: "...", sources: [...] }
```

---

### External Services

**Ollama API:**
- Base URL: `http://localhost:11434`
- Endpoint: `/api/generate` (streaming)
- Docs: https://github.com/ollama/ollama/blob/main/docs/api.md

**CORTEX API:**
- Base URL: `http://localhost:8004`
- Endpoint: `/query` (POST)
- Auth: `X-API-KEY: sesa-secure-core-v1`
- Body: `{ query: string, mode: "local"|"global"|"naive", top_k: number }`

---

## 📊 CURRENT STATUS

### Phase 3 Progress

**Completed:**
- ✅ UX_SPEC documentation (Phase 2)
- ✅ `client/` directory structure created
- ✅ Rust prerequisite documented

**Blocked (awaiting Rust installation):**
- ⏳ Tauri project initialization
- ⏳ Rust Core development
- ⏳ Svelte UI integration

**In Progress:**
- 🔄 UI stub components (Rust-independent)

---

### Timeline

- **Start:** 27.11.2025
- **Target MVP:** 08.12.2025 (internal)
- **Deadline:** 10.12.2025 (Director review)
- **Status:** 🟡 On Track (13 days remaining)

---

## 📝 DEVELOPMENT WORKFLOW

### Daily Tasks

**1. Check Services:**
```powershell
# Verify Ollama running
curl http://localhost:11434/api/tags

# Verify CORTEX running
curl http://localhost:8004/health
```

**2. Start Development:**
```powershell
cd E:\WORLD_OLLAMA\client
npm run tauri dev
```

**3. Hot Reload:**
- Edit `.svelte` files → Auto-reload in app
- Edit `.rs` files → Auto-recompile Rust Core

**4. Test Build:**
```powershell
npm run tauri build
```

---

### Git Workflow

**Branching:**
- `main` — Stable releases
- `phase-3-tauri-mvp` — Active development
- Feature branches: `feature/chat-ui`, `feature/cortex-integration`

**Commits:**
- Use conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`
- Example: `feat(chat): add streaming response support`

---

## 🐛 TROUBLESHOOTING

### Common Issues

**1. Rust not found:**
- **Error:** `rustc: The term 'rustc' is not recognized`
- **Solution:** Install Rust via `rustup` (see `RUST_TOOLCHAIN_PREREQ.md`)

**2. Tauri dev fails to compile:**
- **Error:** `error: could not compile 'tauri-app'`
- **Solution:** Check Rust version (`rustc --version`), update if needed

**3. CORTEX connection refused:**
- **Error:** `Connection refused on localhost:8004`
- **Solution:** Start CORTEX: `pwsh E:\WORLD_OLLAMA\scripts\START_ALL.ps1`

**4. Ollama model not found:**
- **Error:** `model 'qwen2.5:14b' not found`
- **Solution:** Pull model: `ollama pull qwen2.5:14b`

---

## 🔗 RELATED DOCUMENTATION

**Project Docs:**
- `../UX_SPEC/02_USER_FLOWS.md` — User scenarios
- `../UX_SPEC/03_INFORMATION_ARCHITECTURE.md` — Navigation structure
- `../UX_SPEC/04_TAURI_TECH_CONSTRAINTS.md` — Platform limitations
- `../UX_SPEC/05_MVP_SCOPE_AND_PRIORITIES.md` — Feature priorities
- `../UX_SPEC/06_UI_PATTERNS_AND_COMPONENTS.md` — Design system
- `../UX_SPEC/RUST_TOOLCHAIN_PREREQ.md` — Rust installation guide

**Technical Specs:**
- `../TECHNICAL_REPORT_VERIFIED.md` — System architecture
- `../PROJECT_MAP.md` — Project structure overview
- `../STATE_SNAPSHOT_v3.1.md` — Current system state

---

## 📞 SUPPORT

**Issues:**
- Check `RUST_TOOLCHAIN_PREREQ.md` for Rust problems
- Review `04_TAURI_TECH_CONSTRAINTS.md` for platform limitations
- See Phase 3 tasks in Director reports

**Contact:**
- Project Director: See `PHASE_2_DIRECTOR_REPORT.md`

---

**Last Updated:** 27.11.2025  
**Status:** 🟡 Development (awaiting Rust installation)  
**Next Milestone:** Task 3 — Tauri initialization
