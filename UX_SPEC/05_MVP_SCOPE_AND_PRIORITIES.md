# UX-SPEC: MVP SCOPE AND PRIORITIES

**Проект:** WORLD_OLLAMA Desktop Client (Tauri)  
**Документ:** MVP Feature Scope & Priority Matrix  
**Версия:** v1.0  
**Дата создания:** 27.11.2025  
**Статус:** ✅ COMPLETE (Task D)

---

## 📋 ЦЕЛЬ ДОКУМЕНТА

Определение минимального жизнеспособного продукта (MVP) для первого релиза Tauri client, с приоритизацией функций по критичности для пользовательского опыта.

---

## 🎯 MVP DEFINITION

### Core Value Proposition

**MVP Goal:**  
Локальный desktop-клиент для диалога с AI (LLM) с доступом к базе знаний (486+ документов ТРИЗ, GPU, AI методологии) через интерфейс чат-бота.

**Success Criteria:**
1. ✅ User can ask questions in natural language
2. ✅ System retrieves relevant documents (CORTEX)
3. ✅ LLM generates answers based on retrieved knowledge
4. ✅ User can view source documents
5. ✅ System works fully offline (after initial setup)

**Target Users (MVP):**
- **Primary:** Persona 1 (Инженер ТРИЗ) — Basic usage
- **Secondary:** Persona 2 (Архитектор AI) — Advanced features post-MVP

**Timeline:**
- **MVP Release:** 10.12.2025 (13 days from 27.11.2025)
- **Post-MVP:** 15.12.2025+ (feature expansion)

---

## 📊 FEATURE PRIORITY MATRIX

Using **MoSCoW Method:**
- **Must Have:** Critical for MVP, blockers if missing
- **Should Have:** Important, but MVP ships without them
- **Could Have:** Nice-to-have, low priority
- **Won't Have (Yet):** Out of scope for MVP

---

## ✅ MUST HAVE (MVP Critical)

### 1. Basic Chat Interface

**Features:**
- Single chat session (no multi-session history in MVP)
- Text input field (no voice input)
- Send button + Enter key support
- Message display (user + assistant bubbles)
- Streaming response (typewriter effect)
- Basic error handling ("Connection lost", retry button)

**Why Must Have:**
- Core value proposition
- Without this, no product exists

**Acceptance Criteria:**
- User can type question, press Enter, see streaming response
- Response completes in <30s for typical query
- Errors show actionable message (not just crash)

**UX Reference:**
- Flow 2 (02_USER_FLOWS.md, lines 150-250)

**Effort:** 🔴 High (3-4 days)

---

### 2. CORTEX Integration (Knowledge Retrieval)

**Features:**
- Query CORTEX API (`http://localhost:8004/query`)
- Use current Plan C config (top_k=20, local mode)
- Display retrieved sources (document names only in MVP)
- Handle CORTEX errors (show "Knowledge base unavailable")

**Why Must Have:**
- Differentiator from generic chatbots
- Access to 486 docs is the core feature

**Acceptance Criteria:**
- Every assistant response includes 5-20 source document references
- User can see "Sources: doc1.txt, doc2.txt, ..." below answer
- If CORTEX down, shows error (not silent failure)

**UX Reference:**
- Flow 2 (02_USER_FLOWS.md, sources panel)
- Entity Model (03_INFORMATION_ARCHITECTURE.md, Message → CORTEXQuery → Documents)

**Effort:** 🔴 High (2-3 days, including error handling)

---

### 3. System Status Monitoring

**Features:**
- Check Ollama health (`http://localhost:11434/api/tags`)
- Check CORTEX health (`http://localhost:8004/health`)
- Show status indicators: 🟢 Running / 🔴 Down
- Manual restart buttons (calls `pwsh scripts/start_lightrag.ps1` equivalent)

**Why Must Have:**
- Self-service troubleshooting
- Reduces support burden ("why doesn't it work?")

**Acceptance Criteria:**
- System Status tab shows Ollama + CORTEX status
- If service down, user can click [Restart] and see progress
- Status updates every 30s automatically

**UX Reference:**
- Flow 5 (02_USER_FLOWS.md, System Diagnostics)

**Effort:** 🟡 Medium (1-2 days)

---

### 4. Basic Settings (Model Selection)

**Features:**
- List available Ollama models (from `ollama list`)
- Select LLM (radio buttons: qwen2.5:14b, TD010v2, etc.)
- Settings persist (save to `config/settings.json`)
- Apply settings immediately (no app restart)

**Why Must Have:**
- Users need to switch models (performance vs quality tradeoff)
- Hardcoding one model = inflexible

**Acceptance Criteria:**
- Settings tab shows ≥2 models
- Changing model works within 30-60s (model unload + load)
- Settings survive app restart

**UX Reference:**
- Flow 6 (02_USER_FLOWS.md, Settings Configuration)

**Effort:** 🟡 Medium (1-2 days)

---

### 5. Error Handling & Recovery

**Features:**
- Graceful degradation (if CORTEX down, LLM still answers without sources)
- Retry failed queries (button: [Try Again])
- Connection error detection (timeout after 30s)
- Clear error messages ("Ollama not running" vs "Unknown error")

**Why Must Have:**
- MVP will have bugs/issues
- User must not be blocked by errors

**Acceptance Criteria:**
- All error states have actionable messages
- User can recover from errors without restarting app
- No silent failures (always show something to user)

**UX Reference:**
- Flow 2 Alt Flows (02_USER_FLOWS.md, Connection Timeout, CORTEX Error)
- Flow 5 Alt Flows (Service restart, logs)

**Effort:** 🟡 Medium (ongoing, baked into features)

---

## 🟡 SHOULD HAVE (Important, Post-MVP)

### 6. Library Browser (Document List)

**Features:**
- List all documents (486 files from `library/raw_documents/`)
- Basic search by filename (no filters in MVP)
- Click document → preview (first 500 chars)
- Click [View Full] → opens in viewer

**Why Should Have:**
- Enhances UX (explore knowledge base)
- Not critical (can access docs via Chat sources)

**Defer Reason:**
- Chat + Sources covers 80% use case
- Library is convenience, not blocker

**Post-MVP Timeline:** +3-5 days after MVP

**UX Reference:**
- Flow 3 (02_USER_FLOWS.md, Library Navigation)

**Effort:** 🟡 Medium (2-3 days)

---

### 7. Custom Document Upload

**Features:**
- Add documents via drag-drop or file picker
- Validate format (.txt, .md, .pdf), size (<10MB)
- Show indexing progress (poll `kv_store_doc_status.json`)
- Confirm completion ("2 docs added, total now 488")

**Why Should Have:**
- Power users want to add own content
- Differentiates from static knowledge base

**Defer Reason:**
- 486 docs sufficient for MVP
- Complex feature (indexing, validation, errors)

**Post-MVP Timeline:** +5-7 days after MVP

**UX Reference:**
- Flow 4 (02_USER_FLOWS.md, Custom Document Indexing)

**Effort:** 🔴 High (4-5 days, complex)

---

### 8. Chat History (Multi-Session)

**Features:**
- Save conversations to SQLite
- Sidebar: List sessions (Today/Week/Month groups)
- Click session → load messages
- [+ New Chat] button

**Why Should Have:**
- Professional feature (resume conversations)
- MVP can work with single session

**Defer Reason:**
- Single session covers initial use case
- Multi-session = database schema, UI complexity

**Post-MVP Timeline:** +2-3 days after MVP

**UX Reference:**
- Flow 1 (02_USER_FLOWS.md, Chat sidebar)
- Entity Model (03_INFORMATION_ARCHITECTURE.md, ChatSession)

**Effort:** 🟡 Medium (2-3 days)

---

### 9. Advanced Search Settings

**Features:**
- Adjust top_k slider (5-50)
- Select mode (Local/Global/Naive radio buttons)
- Toggle post-processing (deduplication, threshold)

**Why Should Have:**
- Power users want control
- MVP uses sane defaults (Plan C: top_k=20, local)

**Defer Reason:**
- Defaults work for 90% users
- Settings UI = extra complexity

**Post-MVP Timeline:** +1-2 days after MVP

**UX Reference:**
- Flow 6 (02_USER_FLOWS.md, Search tab in Settings)

**Effort:** 🟢 Low (1-2 days)

---

## 🔵 COULD HAVE (Nice-to-Have, Low Priority)

### 10. Logs Viewer

**Features:**
- View CORTEX logs (`services/lightrag/logs/cortex.log`)
- Tail last 50 lines
- Export logs to file
- Filter by level (INFO, ERROR)

**Why Could Have:**
- Useful for debugging
- Advanced users (Persona 2) would use

**Defer Reason:**
- System Status covers basic diagnostics
- Logs = niche feature

**Post-MVP Timeline:** +1 day (if time allows)

**UX Reference:**
- Flow 5 Alt Flow 7 (02_USER_FLOWS.md, View Logs)

**Effort:** 🟢 Low (1 day)

---

### 11. Performance Metrics Dashboard

**Features:**
- Chart: Latency trend (last 10 queries)
- Display: P@5, R@10 (from CORTEX)
- VRAM usage graph (from `nvidia-smi`)

**Why Could Have:**
- Power users (Persona 2) like data
- Not critical for basic usage

**Defer Reason:**
- System Status shows basic health
- Metrics = advanced feature

**Post-MVP Timeline:** +2-3 days (if requested)

**UX Reference:**
- Flow 5 (02_USER_FLOWS.md, Metrics tab)

**Effort:** 🟡 Medium (2 days)

---

### 12. Keyboard Shortcuts

**Features:**
- Ctrl+1/2/3/4: Switch tabs (Chat/Library/System/Settings)
- Ctrl+N: New chat
- Ctrl+F: Focus search (in Library)
- Esc: Close modals

**Why Could Have:**
- Power users love shortcuts
- Not critical for MVP

**Defer Reason:**
- Mouse navigation works fine
- Shortcuts = polish, not core

**Post-MVP Timeline:** +1 day (easy to add)

**UX Reference:**
- 03_INFORMATION_ARCHITECTURE.md (Navigation Patterns)

**Effort:** 🟢 Low (0.5 day)

---

### 13. Theme Support (Dark/Light Mode)

**Features:**
- Toggle in Settings: Light/Dark/Auto (system)
- Persist preference
- Apply theme to all UI

**Why Could Have:**
- Nice UX touch
- Many users prefer dark mode

**Defer Reason:**
- Default theme (light or dark) sufficient for MVP
- Theming = CSS complexity

**Post-MVP Timeline:** +1-2 days

**Effort:** 🟡 Medium (1-2 days)

---

## ❌ WON'T HAVE (Out of Scope for MVP)

### 14. Multi-User Support
**Reason:** Local-First architecture = single-user design

### 15. Cloud Sync
**Reason:** Privacy-first, no cloud integration

### 16. Voice Input/Output
**Reason:** Complex, not core value proposition

### 17. Plugin System
**Reason:** Over-engineering for MVP

### 18. Mobile App
**Reason:** Desktop-only scope

### 19. Collaboration Features
**Reason:** Single-user system

### 20. Export to Word/PDF
**Reason:** Chat history export = plain text sufficient

---

## 📋 MVP FEATURE CHECKLIST

### Core Features (Must Have) — 5 items

- [ ] **Chat Interface** (input, send, display, streaming)
- [ ] **CORTEX Integration** (retrieve docs, show sources)
- [ ] **System Status** (service health, restart buttons)
- [ ] **Basic Settings** (model selection, persist)
- [ ] **Error Handling** (retry, clear messages)

**Total Effort:** ~10-12 days (realistic for 13-day deadline)

### Post-MVP (Should Have) — 4 items

- [ ] **Library Browser** (list, search, preview)
- [ ] **Custom Document Upload** (add, validate, index)
- [ ] **Chat History** (multi-session, sidebar)
- [ ] **Advanced Search Settings** (top_k, mode)

**Total Effort:** ~10-13 days (starts after MVP)

### Future Enhancements (Could Have) — 4 items

- [ ] **Logs Viewer**
- [ ] **Metrics Dashboard**
- [ ] **Keyboard Shortcuts**
- [ ] **Theme Support**

**Total Effort:** ~5-7 days (based on user feedback)

---

## 🎨 UI SCOPE FOR MVP

### Screens (Must Have)

1. **Chat Tab** (Main interface)
   - Message list (scrollable)
   - Input field + Send button
   - Sources list (below each assistant message)
   - Loading state (spinner + "Thinking...")
   - Error state (red message + Retry)

2. **System Status Tab** (Diagnostics)
   - Ollama status card (🟢/🔴 + Restart)
   - CORTEX status card (🟢/🔴 + Restart)
   - Auto-refresh every 30s

3. **Settings Tab** (Basic)
   - Models section (radio buttons)
   - Save button
   - Confirmation toast ("Settings saved ✅")

### Screens (Deferred to Post-MVP)

- Library tab (Should Have)
- Logs tab (Could Have)
- Metrics tab (Could Have)
- Advanced settings (Should Have)

---

## 🚀 ROLLOUT STRATEGY

### Phase 1: MVP (10.12.2025) — 13 days

**Week 1 (27.11 - 03.12):**
- Day 1-2: Tauri project setup, basic UI skeleton
- Day 3-4: Chat interface (input, display, Ollama integration)
- Day 5-6: CORTEX integration (query, show sources)
- Day 7: System Status (health checks)

**Week 2 (04.12 - 10.12):**
- Day 8: Settings (model selection)
- Day 9: Error handling (all flows)
- Day 10-11: Testing, bug fixes
- Day 12: Polish, performance optimization
- Day 13: MVP Release 🎉

**Deliverables:**
- Working Tauri app (.exe for Windows)
- Basic Chat + CORTEX + System Status
- 5 Must Have features complete

---

### Phase 2: Post-MVP Expansion (11.12 - 20.12)

**Week 3 (11.12 - 17.12):**
- Library Browser (3 days)
- Chat History (2 days)
- Advanced Settings (2 days)

**Week 4 (18.12 - 20.12):**
- Custom Document Upload (3 days)

**Deliverables:**
- v1.1 Release with 4 Should Have features

---

### Phase 3: Polish & Enhancements (21.12+)

**Future:**
- Logs Viewer (if requested)
- Metrics Dashboard (if requested)
- Keyboard Shortcuts (easy win)
- Theme Support (if users ask)

**Deliverables:**
- v1.2+ incremental releases

---

## 📊 SUCCESS METRICS

### MVP Success (by 10.12.2025)

**Technical:**
- ✅ App starts in <5s
- ✅ Query response in <30s (CORTEX + LLM)
- ✅ No critical bugs (app doesn't crash)
- ✅ Services auto-start 90% of the time

**User Experience:**
- ✅ User can ask question and get answer (Flow 2 works)
- ✅ User can see sources (transparency)
- ✅ User can check system status (self-service)
- ✅ User can switch models (flexibility)

**Business:**
- ✅ Working demo for Director review
- ✅ Foundation for Phase 3 (Tauri MVP → full app)

---

### Post-MVP Success (by 20.12.2025)

**Technical:**
- ✅ Library Browser works (browse 486 docs)
- ✅ Chat History persists (multi-session)
- ✅ Custom docs can be added

**User Experience:**
- ✅ User can explore knowledge base (not just query)
- ✅ User can add own documents (extensibility)
- ✅ User can resume conversations (professional feature)

---

## 📝 СЛЕДУЮЩИЕ ШАГИ

### Статус документа

**Завершено (Task D):**
- ✅ MVP scope defined (5 Must Have features)
- ✅ Post-MVP roadmap (4 Should Have, 4 Could Have)
- ✅ Priority matrix (MoSCoW method)
- ✅ Rollout strategy (3 phases)
- ✅ Success metrics defined

**Для Phase 2 (следующие задачи):**
1. **Task E:** Create 06_UI_PATTERNS_AND_COMPONENTS.md (layouts, components, style)

**Для Implementation:**
- Use this doc to guide development priorities
- Defer non-MVP features (resist scope creep!)
- Track progress against checklist

---

**Статус:** ✅ COMPLETE (MVP + Post-MVP scopes defined)  
**Обновлено:** 27.11.2025 (Task D завершён)  
**Автор:** UX Team (CODEC executor)
