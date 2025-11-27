# UX-SPEC: TAURI TECHNICAL CONSTRAINTS

**Проект:** WORLD_OLLAMA Desktop Client (Tauri)  
**Документ:** Technical Constraints & Platform Limitations  
**Версия:** v1.0  
**Дата создания:** 27.11.2025  
**Статус:** ✅ COMPLETE (Task C)

---

## 📋 ЦЕЛЬ ДОКУМЕНТА

Определение технических ограничений платформы Tauri и их влияние на UX-дизайн, чтобы обеспечить реалистичные ожидания и оптимальные решения в рамках возможностей стека.

---

## 🏗️ TECHNOLOGY STACK

### Core Platform

**Desktop Framework:**
- **Tauri v1.x** (or v2.x if migration planned)
- **Rust Core** — Backend logic, system integration, IPC
- **Svelte Frontend** — Reactive UI framework (recommended для Tauri)
- **WebView** — OS-native webview (не Chromium embed)

**Advantages:**
- ✅ Small bundle size (~5-15 MB vs Electron 100+ MB)
- ✅ Low memory footprint (~50-150 MB RAM)
- ✅ Native performance (Rust backend)
- ✅ System tray integration

**Tradeoffs:**
- ⚠️ WebView inconsistencies across OS (Windows EdgeHTML/Chromium, macOS WebKit)
- ⚠️ Limited to single main window + secondary windows (no tabs like browser)
- ⚠️ IPC overhead (frontend ↔ Rust backend communication)

---

## 🔒 LOCAL-FIRST ARCHITECTURE CONSTRAINTS

### Single-User, Single-Machine Design

**Implications:**

**Data Storage:**
- **Chat History:** SQLite database (`E:\WORLD_OLLAMA\data\chat_history.db`)
- **Settings:** JSON config file (`E:\WORLD_OLLAMA\config\settings.json`)
- **Documents:** Filesystem (`E:\WORLD_OLLAMA\library\raw_documents\`)
- **CORTEX Index:** LightRAG data (`E:\WORLD_OLLAMA\services\lightrag\data\`)

**No Cloud Sync:**
- ❌ No multi-device sync
- ❌ No cloud backup
- ❌ No collaborative features
- ✅ Full data ownership (GDPR-friendly)
- ✅ Works offline (after initial setup)

**UX Impact:**
- **Settings:** Must include manual export/import for backup
- **Chat History:** Warn user on uninstall (data will be lost unless exported)
- **Documents:** Provide "Export Library" feature for migration

---

### Dependency on Local Services

**Required External Services:**

1. **Ollama** (port 11434)
   - Must be running for LLM queries
   - Must have models pulled (`qwen2.5:14b`, `nomic-embed-text`)

2. **CORTEX (LightRAG)** (port 8004)
   - Must be running for knowledge retrieval
   - Must have indexed documents

**UX Constraints:**

**Auto-Start Strategy:**
- **Option A (Recommended):** Tauri app starts services on launch
  - Pros: Seamless UX, no manual steps
  - Cons: Complex startup logic, error-prone
- **Option B (Safer):** User manually starts services
  - Pros: Simple, predictable
  - Cons: Extra friction, "why doesn't it just work?"

**Chosen Approach (per Director):** **Option A with fallback**
- App attempts auto-start (using `scripts/start_lightrag.ps1` equivalent)
- If fails: Show System Status with clear error + manual start button
- Onboarding: First-time wizard checks dependencies

**Error Handling Must:**
- Detect Ollama not installed → Provide download link
- Detect models missing → Provide `ollama pull` button
- Detect CORTEX indexing → Show progress, ETA

---

## ⚡ PERFORMANCE CONSTRAINTS

### GPU/VRAM Limitations

**Hardware Context:**
- **Target GPU:** RTX 5060 Ti 16GB (developer machine)
- **Model VRAM Usage:**
  - LLM (qwen2.5:14b): ~6.2 GB
  - Embedding (nomic-embed-text): ~1.8 GB
  - Total: ~8 GB baseline
- **Remaining VRAM:** ~8 GB (for other processes)

**UX Impact:**

**VRAM Monitoring:**
- Show VRAM usage in System Status (optional, Advanced mode)
- Warn if VRAM >90% ("Close other GPU apps for better performance")

**Model Switching:**
- Switching models requires unload → load (30-60s)
- Show progress: "Unloading qwen2.5... Loading TD010v2..."
- Disable Chat input during switch

**Concurrent Operations:**
- CORTEX indexing uses GPU → Slower if Chat active simultaneously
- Solution: Show warning "Indexing in progress. Queries may be slower."

---

### CPU/RAM Limitations

**Expected Workload:**
- **Idle:** ~200 MB RAM (Tauri app + Rust backend)
- **Active Chat:** ~500 MB RAM (Svelte UI + message history)
- **Indexing:** +2-5 GB RAM (CORTEX processing large documents)

**UX Impact:**

**Memory Management:**
- Limit Chat history in memory (load last 50 messages, lazy-load older)
- Pagination in Library (render 20 docs at a time, virtual scroll)
- Lazy-load document viewer (don't load all 486 docs upfront)

**Background Tasks:**
- Indexing: Low priority, pausable if user starts Chat
- Model download: Show progress, cancelable

---

### IPC (Inter-Process Communication) Overhead

**Tauri IPC Pattern:**
```
Svelte Frontend → invoke("get_chat_history") → Rust Backend → SQLite
                                              ↓
Svelte Frontend ← JSON response ← Rust Backend
```

**Latency:**
- Simple call (get settings): ~1-5 ms
- Database query (load 50 messages): ~10-50 ms
- File read (large document): ~100-500 ms

**UX Impact:**

**Optimize IPC Calls:**
- ❌ Bad: Call `get_message(id)` 50 times in loop (50x IPC overhead)
- ✅ Good: Call `get_messages([ids])` once (1x IPC)

**Cache in Frontend:**
- Chat messages: Cache in Svelte store, only fetch new on session change
- Settings: Load once on startup, update only on save
- Document list: Cache list, refresh only on manual action

**Loading States:**
- Show skeleton UI for >100ms operations
- Example: Library loading documents → Show 10 skeleton rows

---

## 🖼️ UI/UX TECHNICAL CONSTRAINTS

### Window Management

**Tauri Window Capabilities:**
- **Main Window:** Always exists, can minimize/maximize/close
- **Secondary Windows:** Can spawn (e.g., detached document viewer)
- **System Tray:** Icon + menu (can hide main window to tray)

**Limitations:**
- ❌ No browser-style tabs (each window = separate OS window)
- ❌ No split-view within single window (must use CSS flexbox)
- ⚠️ Secondary windows = separate WebView instances (performance cost)

**UX Decisions:**

**Primary Navigation:**
- Use in-app tabs (Chat/Library/System/Settings) via CSS, not OS windows
- Reason: Faster, consistent, no window management overhead

**Split-View (Future):**
- If needed: CSS Grid layout (Chat + Library side-by-side)
- Not OS-level split (Tauri limitation)

**Detached Views (Optional):**
- Allow "Open in New Window" for document viewer
- Use case: Multi-monitor setup, read doc while chatting
- Trade-off: +50-100 MB RAM per window

---

### WebView Rendering Constraints

**OS-Specific WebViews:**
- **Windows:** EdgeHTML (Win10) or Chromium Edge (Win11)
- **macOS:** WebKit (Safari engine)
- **Linux:** WebKitGTK

**Cross-Platform Consistency Issues:**

**CSS:**
- Some CSS features may not work on older Windows 10 (EdgeHTML)
- Solution: Use PostCSS autoprefixer, test on all targets

**JavaScript:**
- ES2020+ features safe (Tauri bundles polyfills)
- Avoid bleeding-edge APIs (check caniuse.com)

**Fonts:**
- System fonts differ (Segoe UI on Windows, SF Pro on macOS)
- Solution: Use web fonts (Google Fonts) for consistency

**UX Impact:**
- Test UI on all target platforms
- Use progressive enhancement (basic UI works everywhere, animations optional)

---

### Animation/Transition Performance

**WebView Performance:**
- **60 FPS animations:** Possible for simple CSS transitions
- **Complex animations:** May drop to 30 FPS on older hardware
- **GPU acceleration:** Limited (WebView != native game engine)

**UX Guidelines:**

**Safe Animations:**
- ✅ Fade-in/out (opacity transitions)
- ✅ Slide-in panels (transform: translateX)
- ✅ Button hover effects (color, scale)

**Avoid:**
- ❌ Heavy blur effects (performance killer)
- ❌ 3D transforms (overkill for desktop app)
- ❌ Particle effects (use sparingly)

**Loading Indicators:**
- Use CSS spinners, not animated GIFs (lighter)
- Skeleton UI preferred over spinners (perceived performance)

---

## 🔌 SERVICE INTEGRATION CONSTRAINTS

### CORTEX (LightRAG) Integration

**Communication:**
- **Protocol:** HTTP REST API (FastAPI)
- **Endpoint:** `http://localhost:8004/query`
- **Latency:** 6-10s per query (normal)
- **Timeout:** 30s (if no response → error)

**UX Impact:**

**Real-Time Feedback:**
- Show "Searching knowledge base..." during CORTEX query
- Show progress if possible (not supported by current API)
- Fallback: Generic "This may take up to 10 seconds"

**Error Handling:**
- Connection refused → "CORTEX not running. Start in System Status."
- Timeout → "Query took too long. Try simpler question or check System."
- 500 error → "CORTEX error. View logs in System Status."

**Query Cancellation:**
- **Problem:** CORTEX doesn't support cancel (API limitation)
- **Workaround:** Allow UI cancel (discard response when arrives)
- **UX:** Show "Canceling..." → "Query canceled (response discarded)"

---

### Ollama Integration

**Communication:**
- **Protocol:** HTTP REST API
- **Endpoint:** `http://localhost:11434/api/generate` (streaming)
- **Latency:** 500ms - 30s (depends on response length)

**Streaming Support:**
- ✅ Ollama supports token-by-token streaming
- ✅ Tauri can handle SSE (Server-Sent Events) or chunked responses

**UX Impact:**

**Streaming Chat:**
- Show tokens as they arrive (typewriter effect)
- Update UI incrementally (not wait for full response)

**Model Loading:**
- First query after model switch: +30s (model loads into VRAM)
- Show: "Loading model into memory... (~30s)"

**Model List:**
- Fetch via `ollama list` API
- Cache result (models don't change often)
- Refresh button for manual update

---

## 📦 BUILD & DEPLOYMENT CONSTRAINTS

### Bundle Size

**Target Size:**
- **Tauri App:** ~10-20 MB (app binary + frontend assets)
- **Dependencies:** Ollama (~500 MB), Models (~8 GB)

**UX Impact:**

**Installation:**
- App itself: Fast download (~10 MB)
- Dependencies: Separate installers (Ollama, model pulls)
- First-time setup: ~30-60 min (model downloads)

**Onboarding:**
- Wizard: "Download Ollama" → "Pull models" → "Start CORTEX" → "Ready"
- Progress tracking for each step

---

### Update Strategy

**Tauri Auto-Update:**
- Supported (built-in updater)
- Checks GitHub Releases or custom server

**UX Impact:**

**Update Notifications:**
- Show in Settings: "New version available (v1.2.0). [Download]"
- Auto-download in background (optional)
- Restart app to apply

**Versioning:**
- App version: Semver (e.g., v1.0.3)
- Show in About dialog: "WORLD_OLLAMA v1.0.3 (Tauri 1.5.4)"

---

## 🔐 SECURITY CONSTRAINTS

### Local-First Security

**No Authentication:**
- Single-user app → No login required
- Assumption: Physical access = authorized user

**Data Protection:**
- SQLite database: Unencrypted (acceptable for local-only)
- Settings file: Plaintext JSON (no secrets stored)

**UX Impact:**
- No login screen (instant launch)
- Warn on uninstall: "Chat history will be deleted"

---

### External API Calls

**Allowed:**
- Ollama API (localhost:11434) — Local service
- CORTEX API (localhost:8004) — Local service

**Blocked:**
- ❌ No cloud LLM APIs (OpenAI, Anthropic) — Local-First principle
- ❌ No telemetry/analytics — Privacy-first

**UX Impact:**
- Full offline capability (after setup)
- No privacy concerns (no data leaves machine)

---

## 🎨 DESIGN SYSTEM CONSTRAINTS

### Framework: Svelte + CSS

**Styling Approach:**
- **Option A:** CSS-in-JS (Svelte `<style>` blocks)
- **Option B:** Utility CSS (Tailwind)
- **Chosen:** Hybrid (Svelte components + minimal Tailwind for layout)

**Component Library:**
- **Option A:** Build custom (full control, learning curve)
- **Option B:** Use library (e.g., Carbon, SvelteUI)
- **Chosen:** Custom (tight constraints, lightweight)

**UX Impact:**
- Consistent design system (colors, spacing, typography)
- Defined in `06_UI_PATTERNS_AND_COMPONENTS.md` (Task E)

---

### Accessibility Constraints

**Keyboard Navigation:**
- ✅ All features accessible via keyboard
- Tab order: Top tabs → Sidebar → Main content → Panels

**Screen Reader:**
- ⚠️ WebView screen reader support varies (better on macOS)
- Use semantic HTML (`<button>`, `<nav>`, ARIA labels)

**UX Impact:**
- Test with screen reader (NVDA on Windows, VoiceOver on macOS)
- Provide keyboard shortcuts cheat sheet in Help

---

## 📊 PERFORMANCE TARGETS

### Startup Time

**Target:** <5 seconds (app launch → UI visible)

**Breakdown:**
- Tauri init: ~500ms
- Load settings: ~100ms
- Check services: ~1s (parallel health checks)
- Render UI: ~500ms
- **Total:** ~2-3s (well under target)

**If Services Starting:**
- CORTEX start: +10-15s
- Ollama already running (system service)
- Show: "Starting CORTEX... 80%" during startup

---

### Query Response Time

**Target (User Perception):**
- **Instant:** <100ms (typing, navigation)
- **Fast:** <1s (load chat history, settings)
- **Acceptable:** <10s (CORTEX query + LLM response)
- **Slow but OK:** <30s (indexing, model download)

**UX Rules:**
- <100ms: No loading indicator needed
- 100ms-1s: Skeleton UI or spinner
- >1s: Progress bar + time estimate
- >10s: Allow cancel, show "still working..."

---

### Memory Usage

**Target:** <500 MB RAM (app + UI, idle)

**Breakdown:**
- Tauri runtime: ~50 MB
- Rust backend: ~50 MB
- Svelte UI: ~100 MB
- Chat history (50 messages): ~50 MB
- Document cache (20 docs): ~100 MB
- **Total:** ~350 MB (within budget)

**If Exceeded:**
- Clear old chat messages from memory (keep in DB)
- Unload documents not in view

---

## 🚧 KNOWN LIMITATIONS & WORKAROUNDS

### Limitation 1: No Hybrid Search Mode

**Problem:** CORTEX doesn't support hybrid mode (Director confirmed)

**Workaround:**
- Settings: Remove "Hybrid" option, show only Local/Global/Naive
- Documentation: Explain why (API limitation)

**UX Impact:**
- User must manually choose mode
- Recommendation: Default to "Local" (fastest, good enough)

---

### Limitation 2: No Query Cancellation in CORTEX

**Problem:** CORTEX API doesn't support abort

**Workaround:**
- Frontend: Allow "Cancel" button (discard response when arrives)
- Backend: Add timeout (30s), return error if exceeded

**UX Impact:**
- Clicking [Cancel] doesn't stop CORTEX processing (still runs on server)
- But user freed to start new query

---

### Limitation 3: Long Indexing Time (No Progress API)

**Problem:** CORTEX indexing doesn't report progress percentage

**Workaround:**
- Poll `data/kv_store_doc_status.json` file (shows N/total processed)
- Calculate: `(N / total) * 100%`
- Update UI every 2-5s

**UX Impact:**
- Show: "Indexing... 45/486 documents (9%)"
- Not perfect (some docs process slower), but better than nothing

---

### Limitation 4: WebView Font Rendering Differences

**Problem:** Windows EdgeHTML vs macOS WebKit render fonts differently

**Workaround:**
- Use web fonts (Google Fonts: Inter, Roboto Mono)
- Test on both platforms
- Accept minor differences (not critical)

**UX Impact:**
- UI looks 95% same across platforms (good enough)

---

## 📝 СЛЕДУЮЩИЕ ШАГИ

### Статус документа

**Завершено (Task C):**
- ✅ Technology stack defined (Tauri + Rust + Svelte)
- ✅ Local-First constraints documented
- ✅ Performance limitations mapped
- ✅ Service integration constraints
- ✅ Known limitations + workarounds

**Для Phase 2 (следующие задачи):**
1. **Task D:** Create 05_MVP_SCOPE_AND_PRIORITIES.md (Must/Should/Could features)
2. **Task E:** Create 06_UI_PATTERNS_AND_COMPONENTS.md (layouts, components, style)

**Для Implementation:**
- Use constraints from this doc when designing features
- Test performance targets during development
- Document any new limitations discovered

---

**Статус:** ✅ COMPLETE (All technical constraints documented)  
**Обновлено:** 27.11.2025 (Task C завершён)  
**Автор:** UX Team (CODEC executor)
