# UX-SPEC: INFORMATION ARCHITECTURE

**Проект:** WORLD_OLLAMA Desktop Client (Tauri)  
**Документ:** Information Architecture & Navigation  
**Версия:** v1.0 (Skeleton)  
**Дата создания:** 27.11.2025  
**Статус:** 🟡 DRAFT (Skeleton ready, content pending)

---

## 📋 ЦЕЛЬ ДОКУМЕНТА

Определение структуры информации, навигации и организации контента в Tauri desktop client для обеспечения интуитивного пользовательского опыта.

---

## 🏗️ ОБЩАЯ СТРУКТУРА ПРИЛОЖЕНИЯ

### Основные разделы (Primary Navigation)

```
┌─────────────────────────────────────────────────────┐
│  WORLD_OLLAMA                            [Min][Max][X] │
├─────────────────────────────────────────────────────┤
│ [💬 Chat] [📚 Library] [🔧 System] [⚙ Settings]    │
├─────────────────────────────────────────────────────┤
│                                                     │
│              CONTENT AREA                           │
│                                                     │
│                                                     │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**4 основных раздела:**

1. **💬 Chat** — Главный интерфейс для вопросов и ответов
2. **📚 Library (Knowledge Base)** — Просмотр и управление документами
3. **🔧 System Status** — Мониторинг состояния сервисов
4. **⚙ Settings** — Настройки системы и параметров поиска

### Navigation Patterns

**Primary Navigation:**
- **Location:** Top horizontal tabs (как в VS Code)
- **Always visible:** Да
- **Keyboard shortcuts:** 
  - Ctrl+1 → Chat
  - Ctrl+2 → Library
  - Ctrl+3 → System
  - Ctrl+4 → Settings

**Secondary Navigation:**
- **Location:** Sidebar (collapsible) внутри каждого раздела
- **Context-dependent:** Меняется в зависимости от активного раздела

---

## 💬 РАЗДЕЛ 1: CHAT

### Назначение

Главный интерфейс для взаимодействия с AI: задавать вопросы, получать ответы, управлять диалогами.

### Структура контента

```
┌─────────────────────────────────────────────┐
│ 💬 Chat                                     │
├──────────┬──────────────────────────────────┤
│          │                                  │
│ SIDEBAR  │        CHAT AREA                 │
│          │                                  │
│ History: │  [Conversation thread]           │
│  - Today │                                  │
│  - Week  │  User: Question...               │
│  - Month │  Assistant: Answer...            │
│          │                                  │
│ [+ New]  │  [Input field]     [Send]        │
│          │                                  │
└──────────┴──────────────────────────────────┘
```

**Sidebar (Left - Collapsible):**
- **Conversation History:**
  - Группировка по времени (Today, Yesterday, Last 7 days, Last 30 days)
  - Каждый диалог: заголовок (первый вопрос) + timestamp
  - Кнопка "[+ New Conversation]"
  - Кнопка "[🗑 Clear All]" (с подтверждением)

**Chat Area (Center):**
- **Conversation Thread:**
  - Чередование User → Assistant сообщений
  - Каждое сообщение Assistant:
    - Текст ответа (markdown formatted)
    - Кнопки: [Copy] [Export] [View Sources] [⚠ Not Relevant]
  - Streaming text support (если возможно)

**Input Area (Bottom):**
- Поле ввода (multiline, растягивается до 5 строк)
- Кнопка "Send" (→) или Enter
- Shift+Enter = новая строка
- Placeholder: "Ask about TRIZ principles, AI architectures, or engineering solutions..."

### Metadata для каждого ответа

**Visible:**
- Timestamp (HH:MM)
- Source count ("Based on 3 documents")

**Hidden (expandable):**
- Latency (6.7s)
- Search mode (Local)
- Top documents used (clickable → opens in Library)

### User Actions

- Создать новый диалог
- Открыть существующий диалог
- Удалить диалог
- Экспортировать диалог (.txt, .md, .pdf?)
- Копировать ответ
- Отметить ответ как нерелевантный (feedback)
- Посмотреть источники (transition to Library с фильтром)

---

## 📚 РАЗДЕЛ 2: LIBRARY (KNOWLEDGE BASE)

### Назначение

Просмотр доступных документов, поиск по базе знаний, чтение полных документов, управление индексом.

### Структура контента

```
┌─────────────────────────────────────────────┐
│ 📚 Library                                  │
├──────────┬──────────────────────────────────┤
│          │                                  │
│ FILTERS  │    DOCUMENT LIST / VIEWER        │
│          │                                  │
│ Category:│  [Search box: Filter by name]   │
│  □ TRIZ  │                                  │
│  □ GPU   │  [Doc 1] Floor_01_TRIZ...       │
│  □ AI    │  [Doc 2] Floor_31_GPU...        │
│  □ Other │  [Doc 3] Floor_24_Posrednik...  │
│          │                                  │
│ Sort by: │  Total: 486 documents            │
│  ⚪ Name  │                                  │
│  ⚪ Date  │                                  │
│          │                                  │
└──────────┴──────────────────────────────────┘
```

**Sidebar (Left - Filters):**
- **Category filter:**
  - ☑ TRIZ Principles (40 принципов)
  - ☑ GPU Optimization (RTX 5060 Ti, MSI Afterburner)
  - ☑ Multi-Agent Systems (WORLD_OLLAMA architecture)
  - ☑ LightRAG & RAG (GraphRAG, retrieval)
  - ☑ Other
- **Sort options:**
  - ⚪ Alphabetical (A-Z)
  - ⚪ Date added (newest first)
  - ⚪ Size (largest first)
- **Statistics:**
  - Total documents: 486
  - Total size: 7.69 MB
  - Last indexed: 27.11.2025

**Document List (Center):**
- **List view (default):**
  - Document name (truncated, tooltip on hover)
  - Category badge (TRIZ, GPU, AI, etc.)
  - Size (KB)
  - Click → opens Document Viewer

**Document Viewer (Center - when document selected):**
- Full document text (markdown rendered)
- Breadcrumb: Library > TRIZ Principles > Floor_01_Drobienie...
- Actions:
  - [Copy All]
  - [Export as .txt]
  - [Ask AI about this document]
- Sidebar (right): Table of Contents (if document has headings)

### Advanced Features (Persona 2)

**Add Custom Document:**
- Button: "[+ Add Document]"
- Upload .txt, .md, .pdf (converts to text)
- Indexing progress bar (~2-5 min for large docs)
- Confirmation: "Document indexed successfully"

**Re-index Knowledge Base:**
- Button: "[🔄 Re-index All]" (Settings → Library)
- Progress: X/486 documents processed
- Warning: "This will take ~15-30 minutes"

### User Actions

- Browse documents by category
- Search by document name
- Open & read full document
- Copy document content
- Ask AI question about specific document
- (Advanced) Add custom document to index
- (Advanced) Re-index knowledge base

---

## 🔧 РАЗДЕЛ 3: SYSTEM STATUS

### Назначение

Мониторинг здоровья сервисов, проверка производительности, доступ к логам (для Persona 2).

### Структура контента

```
┌─────────────────────────────────────────────┐
│ 🔧 System Status                            │
├─────────────────────────────────────────────┤
│                                             │
│  Services Health:                           │
│  🟢 Ollama          Running (port 11434)    │
│  🟢 CORTEX          Ready   (port 8004)     │
│  ⚠️ Neuro-Terminal  Optional(port 8501)     │
│                                             │
│  Models Loaded:                             │
│  ✅ qwen2.5:14b-instruct-q4_k_m             │
│  ✅ nomic-embed-text:latest                 │
│                                             │
│  Knowledge Base:                            │
│  📊 486 documents indexed                   │
│  💾 Cache size: 357.85 KB                   │
│  🕒 Last update: 27.11.2025 14:20           │
│                                             │
│  Performance (Last 10 queries):             │
│  ⏱ Avg Latency: 6.7s                        │
│  📈 P@5: 0.184, R@10: 0.268                 │
│  🎯 Success rate: 50/50 (100%)              │
│                                             │
│  GPU Status (if available):                 │
│  🖥 RTX 5060 Ti 16GB                        │
│  💾 VRAM used: 8.2 GB / 16 GB               │
│  🌡 Temperature: 68°C                       │
│                                             │
│  [Restart Services] [View Logs]             │
│                                             │
└─────────────────────────────────────────────┘
```

### Components

**Service Status Cards:**
- Each service (Ollama, CORTEX, Neuro) = separate card
- Status indicators: 🟢 Running, 🟡 Starting, 🔴 Down
- Port number visible
- Action buttons: [Restart] [Stop]

**Models Section:**
- List of loaded models (checkmarks)
- Missing models highlighted with ⚠️ + [Download] button

**Knowledge Base Stats:**
- Document count
- Cache size (from kv_store_doc_status.json)
- Last indexing date
- Button: [Re-index] (opens confirmation dialog)

**Performance Metrics:**
- Real-time or recent stats
- Latency chart (last 10-20 queries)
- Success rate percentage
- Optional: Export metrics to CSV

**GPU Monitoring (Advanced):**
- VRAM usage bar chart
- Temperature gauge
- Model currently loaded in VRAM

### User Actions

- Check system health at a glance
- Restart individual services
- View detailed logs (opens log viewer)
- Export diagnostics report (.txt with all metrics)
- (Advanced) Adjust service startup parameters

---

## ⚙ РАЗДЕЛ 4: SETTINGS

### Назначение

Настройка параметров системы, моделей, поиска, UI preferences.

### Структура контента

```
┌─────────────────────────────────────────────┐
│ ⚙ Settings                                  │
├──────────┬──────────────────────────────────┤
│          │                                  │
│ TABS:    │     SETTINGS CONTENT             │
│          │                                  │
│ General  │  [Settings for active tab]       │
│ Search   │                                  │
│ Models   │                                  │
│ Library  │                                  │
│ Advanced │                                  │
│          │                                  │
│          │  [Save] [Reset to Defaults]      │
│          │                                  │
└──────────┴──────────────────────────────────┘
```

### Tab 1: General

**UI Preferences:**
- Theme: ⚪ Light  ⚪ Dark  ⚪ Auto (system)
- Language: English (future: русский)
- Font size: Small | Medium | Large
- Startup behavior:
  - ☑ Launch on system startup
  - ☑ Auto-start services
  - ☑ Minimize to tray

**Data & Privacy:**
- Chat history retention: 7 days | 30 days | Forever
- Telemetry: ☐ Send anonymous usage stats (default: OFF)
- Data location: `E:\WORLD_OLLAMA\data\` [Change...]

### Tab 2: Search Settings

**Search Mode:**
- ⚪ Local (fast, local context)
- ⚪ Global (slow, full graph traversal)
- ⚪ Hybrid (adaptive, unstable) ⚠️
- ⚪ Naive (simple text search)

**Retrieval Parameters:**
- top_k: [20] (10-50 range slider)
- Temperature (LLM): [0.1] (0.0-1.0 slider)

**POST-PROCESSING:**
- ☑ Enable deduplication
- ☑ Filter short sentences (<30 chars)
- Max sentences in answer: [8] (5-15 range)

**Experimental (Advanced Users):**
- ☐ Enable rerank (⚠️ FROZEN until 10.12.2025)

### Tab 3: Models

**LLM Model:**
- Dropdown: qwen2.5:14b-instruct-q4_k_m (active)
  - llama3.2:3b
  - mistral:7b
  - [+ Pull New Model...]

**Embedding Model:**
- Dropdown: nomic-embed-text:latest (active)
  - all-minilm:l6-v2
  - [+ Pull New Model...]

**Model Management:**
- [List All Models] → shows Ollama models
- [Remove Unused Models]
- [Download Models...] → Ollama pull dialog

### Tab 4: Library

**Indexing Settings:**
- Auto-index new documents: ☑ Enabled
- Watch folder: `E:\WORLD_OLLAMA\library\raw_documents\` [Change...]
- Re-index interval: Never | Daily | Weekly

**Document Management:**
- [Add Custom Document...]
- [Re-index All Documents] (⚠️ 15-30 min)
- [Clear Index Cache] (⚠️ destructive)

### Tab 5: Advanced

**Developer Options:**
- ☐ Show debug logs in UI
- ☐ Enable API access (localhost:8004)
- API Key: `sesa-secure-core-v1` [🔄 Regenerate]

**Service Configuration:**
- Ollama URL: `http://127.0.0.1:11434` [Edit...]
- CORTEX URL: `http://127.0.0.1:8004` [Edit...]
- Timeout (seconds): [90]

**Logs & Diagnostics:**
- [Open Log Folder]
- [Export Diagnostics Report]
- [Reset All Settings] (⚠️ destructive)

### User Actions

- Change UI theme/language
- Adjust search parameters
- Switch LLM/embedding models
- Configure auto-indexing
- (Advanced) Enable API access
- (Advanced) View/export logs

---

## 🔀 NAVIGATION FLOWS BETWEEN SECTIONS

### Primary Transitions

**Chat → Library:**
- Click "View Sources" in answer → opens Library with filter for those documents

**Chat → System:**
- Error message "CORTEX unavailable" → link to System Status

**Library → Chat:**
- Click "Ask AI about this document" → opens Chat with pre-filled question

**System → Settings:**
- Click "Restart Services" → redirects to Settings > Advanced if fails

**Settings → System:**
- After changing model → "View in System Status" to confirm loaded

### Global Actions (Available Everywhere)

- **Keyboard Shortcuts:**
  - Ctrl+N → New conversation (Chat)
  - Ctrl+F → Focus search (Library/Chat)
  - Ctrl+, → Open Settings
  - F5 → Refresh current view
  - Ctrl+Q → Quit application

- **Top-right Menu (☰):**
  - About WORLD_OLLAMA
  - Documentation (opens browser: GitHub README)
  - Report Issue (opens GitHub Issues)
  - Check for Updates
  - Quit

---

## 📊 INFORMATION HIERARCHY

### Priority Levels (по важности для Persona 1)

**Level 1 (Critical - Always Visible):**
- Chat input field
- Send button
- System status indicator (🟢/🟡/🔴)

**Level 2 (Important - One Click Away):**
- Conversation history
- Document list (Library)
- Settings (common options)

**Level 3 (Advanced - Two Clicks):**
- Logs & diagnostics
- Model management
- Advanced settings

### Complexity Management

**For Persona 1 (Basic User):**
- Hide advanced features by default
- Simple, clean interface
- Minimal configuration needed

**For Persona 2 (Advanced User):**
- "Show Advanced Options" toggle in Settings
- Full access to logs, metrics, API
- Developer-friendly configuration

---

## 🔀 NAVIGATION HIERARCHY (3 LEVELS)

### Level 1: Layout Navigation (Primary Tabs)

**Location:** Top horizontal tab bar, always visible  
**Scope:** Global, high-level sections  
**Example:**
```
[💬 Chat*] [📚 Library] [🔧 System] [⚙ Settings]
```

**Rules:**
- Only 1 tab active at a time
- Switching tabs changes entire content area
- State preserved when switching (e.g., chat scroll position, Library filters)
- Keyboard shortcuts: Ctrl+1/2/3/4

**Transitions:**
- Between tabs: Instant content swap (no animation)
- State loading: Show skeleton/spinner if data not cached

---

### Level 2: Content Navigation (Section-Specific)

**Location:** Within content area, context-dependent  
**Scope:** Sub-areas of active tab  
**Examples:**

**Chat (Level 2):**
- Sidebar: Conversation history (Today/Week/Month groups)
- Main: Thread messages + input field
- Right panel (collapsible): Sources panel

**Library (Level 2):**
- Sidebar: Filters (TRIZ/GPU/AI/Custom categories)
- Main: Document list (scrollable, searchable)
- Right panel: Document preview/viewer

**System (Level 2):**
- Main: Service cards (Ollama/CORTEX/Neuro)
- Tabs within System: [Services] [Metrics] [Logs]

**Settings (Level 2):**
- Tabs: [General] [Models] [Search] [Advanced]
- Main: Settings form for active tab

**Rules:**
- Level 2 navigation visible when relevant (e.g., Settings tabs only in Settings section)
- Can have multiple Level 2 elements visible simultaneously (sidebar + main + panel)
- State persists within Level 1 tab (e.g., selected Settings tab remembered)

---

### Level 3: Modal/Overlay Navigation (Contextual Actions)

**Location:** Overlays on top of content area  
**Scope:** Temporary, task-focused interactions  
**Triggers:** User actions (buttons, errors, confirmations)

**Types:**

**Modals (blocking):**
- Add Custom Documents (drag-drop UI)
- Confirm Service Restart
- Error Details (with logs)
- Model Download Progress

**Panels (non-blocking):**
- Sources panel in Chat (slides in from right)
- Document full viewer in Library (expands within content)

**Toasts (transient):**
- "Settings Saved ✅"
- "CORTEX connection failed ❌"
- "Model downloaded successfully 🎉"

**Rules:**
- Modals: Esc to close, click outside to dismiss (with confirmation if data entered)
- Panels: Can interact with main content simultaneously (e.g., read sources while viewing chat)
- Toasts: Auto-dismiss after 3-5s, click to dismiss immediately

**Navigation within Level 3:**
- Modals: Can have internal tabs (e.g., Add Documents: [Upload] [History] [Settings])
- Panels: Can scroll independently of main content

---

## 🗂️ ENTITY RELATIONSHIP MODEL

Diagram showing how data entities connect and flow through the system.

### Core Entities

```
┌─────────────┐
│    USER     │ (Single-user system, implicit)
└──────┬──────┘
       │
       │ 1:N (creates)
       ↓
┌─────────────┐
│ CHAT        │
│ SESSION     │ (Conversation thread)
├─────────────┤
│ - id: UUID  │
│ - title     │
│ - created   │
│ - updated   │
└──────┬──────┘
       │
       │ 1:N (contains)
       ↓
┌─────────────┐
│  MESSAGE    │ (User or Assistant turn)
├─────────────┤
│ - id: UUID  │
│ - role      │ (user | assistant)
│ - content   │
│ - timestamp │
│ - queryId   │ (optional, if assistant)
└──────┬──────┘
       │
       │ 1:1 (if assistant message)
       ↓
┌─────────────┐
│ CORTEX      │
│ QUERY       │ (RAG retrieval event)
├─────────────┤
│ - id: UUID  │
│ - query     │
│ - mode      │ (local | global | naive)
│ - top_k     │
│ - latency   │
└──────┬──────┘
       │
       │ 1:N (retrieved)
       ↓
┌─────────────┐
│ RETRIEVED   │
│ DOCUMENT    │ (Source reference)
├─────────────┤
│ - docId     │ (FK to DOCUMENT)
│ - score     │
│ - snippet   │
└──────┬──────┘
       │
       │ N:1 (references)
       ↓
┌─────────────┐
│  DOCUMENT   │ (Knowledge base item)
├─────────────┤
│ - id: UUID  │
│ - filename  │
│ - category  │ (TRIZ | GPU | AI | Custom)
│ - size      │
│ - indexed   │ (timestamp)
│ - content   │ (full text)
└─────────────┘
```

### Relationships Explained

**USER → CHAT SESSION (1:N):**
- User creates multiple conversations over time
- Example: "2 sessions today", "15 sessions this week"

**CHAT SESSION → MESSAGE (1:N):**
- Each session contains alternating user/assistant messages
- Example: Session "ТРИЗ для медицины" has 10 messages (5 user, 5 assistant)

**MESSAGE → CORTEX QUERY (1:1 or 1:0):**
- Only assistant messages have associated queries
- User messages don't trigger queries (just stored as-is)
- Example: Assistant message #3 → Query #3 (local, top_k=20, 6.7s)

**CORTEX QUERY → RETRIEVED DOCUMENT (1:N):**
- Each query retrieves up to top_k documents
- Example: Query #3 → 5 docs (scores: 0.92, 0.87, 0.81, 0.75, 0.68)

**RETRIEVED DOCUMENT → DOCUMENT (N:1):**
- Same document can be retrieved in multiple queries
- Example: "1.triz_droblenie_v_inzhenerii_i_ii.txt" retrieved in 12 different queries

### Data Flow (Typical Query)

```
1. USER types question in Chat
   ↓
2. MESSAGE created (role=user, content="...")
   ↓
3. CORTEX QUERY triggered (query="...", mode=local, top_k=20)
   ↓
4. CORTEX searches knowledge base
   ↓
5. RETRIEVED DOCUMENTS created (5 results with scores)
   ↓
6. LLM generates response using retrieved docs
   ↓
7. MESSAGE created (role=assistant, content=response, queryId=...)
   ↓
8. UI displays assistant message + sources panel (RETRIEVED DOCUMENTS)
```

### State Management Implications

**For UX Design:**
- **Chat History:** Load from MESSAGE table, grouped by CHAT SESSION
- **Sources Panel:** Display RETRIEVED DOCUMENTS for selected assistant message
- **Library Count:** Count DOCUMENT entities, group by category
- **System Metrics:** Aggregate CORTEX QUERY latency, calculate avg/p95

**For Local-First:**
- All entities stored locally (SQLite)
- No sync, no cloud backup (single-user, single-machine)
- Documents physically stored in `E:\WORLD_OLLAMA\library\raw_documents\`

---

## 🎭 SUBSCREEN/STATE DETAILS FOR EACH SECTION

Detailed breakdown of states and subscreens within each primary navigation tab.

---

### 💬 CHAT — States & Subscreens

**Subscreen Hierarchy:**
```
Chat (Level 1)
├── Sidebar: Conversation History (Level 2)
│   ├── Empty State (no sessions)
│   ├── Grouped List (Today/Week/Month)
│   └── Selected Session (highlighted)
├── Main: Thread Area (Level 2)
│   ├── Empty State (new session)
│   ├── Waiting State (user sent, before response)
│   ├── Streaming State (response generating)
│   ├── Complete State (full conversation)
│   └── Error State (query failed)
└── Right Panel: Sources (Level 2, collapsible)
    ├── Collapsed (show button "View Sources")
    ├── Expanded (5 source badges)
    └── Source Detail (click badge → full document)
```

**State Transitions:**

**Empty → Waiting:**
- Trigger: User sends first message
- UI: Input disabled, spinner in chat, "Assistant is thinking..."

**Waiting → Streaming:**
- Trigger: LLM starts generating response
- UI: Text appears word-by-word (streaming), spinner removed

**Streaming → Complete:**
- Trigger: LLM finishes, response fully displayed
- UI: Sources panel badge appears ("+5 sources"), input re-enabled

**Complete → Error:**
- Trigger: CORTEX timeout, LLM failure, connection lost
- UI: Red error message, retry button, logs link

**Error → Waiting:**
- Trigger: User clicks [Retry]
- UI: Same as initial Waiting state

**State Persistence:**
- Scroll position: Saved when switching tabs, restored on return
- Input draft: Saved to localStorage, restored on reopen
- Selected session: Highlighted in sidebar

---

### 📚 LIBRARY — States & Subscreens

**Subscreen Hierarchy:**
```
Library (Level 1)
├── Sidebar: Filters + Stats (Level 2)
│   ├── Category Checkboxes (TRIZ/GPU/AI/Custom)
│   ├── Stats (486 docs, 12 MB total)
│   └── Search Input (real-time filter)
├── Main: Document List (Level 2)
│   ├── Loading State (skeleton list)
│   ├── Filtered List (scrollable, 20 visible)
│   ├── Empty State (no results)
│   └── Selected Document (highlighted row)
└── Right Panel: Document Viewer (Level 2, expandable)
    ├── Preview Mode (metadata + first 500 chars)
    ├── Full View Mode (markdown rendered, scrollable)
    └── Chat Transition Button (+ Use in Chat)
```

**State Transitions:**

**Loading → Filtered List:**
- Trigger: Documents loaded from filesystem
- UI: Skeleton disappears, list populated, stats updated

**Filtered List → Empty State:**
- Trigger: Filter/search returns 0 results
- UI: "No documents found. Try different filters." + [Clear Filters]

**Empty State → Filtered List:**
- Trigger: User clears filters
- UI: Full list re-appears

**Selected Document → Preview Mode:**
- Trigger: User clicks document row
- UI: Right panel slides in, preview shown

**Preview Mode → Full View Mode:**
- Trigger: User clicks [View Full Document]
- UI: Right panel expands to ~60% width, markdown rendered

**Full View Mode → Chat (cross-tab):**
- Trigger: User clicks [+ Use in Chat] button
- UI: Switches to Chat tab, input pre-filled: "Explain [document name]", document attached

**State Persistence:**
- Active filters: Saved when switching tabs
- Search query: Cleared on tab switch (intentional, avoid confusion)
- Scroll position: Saved for list, not for viewer (resets)

---

### 🔧 SYSTEM STATUS — States & Subscreens

**Subscreen Hierarchy:**
```
System (Level 1)
├── Main: Service Cards (Level 2)
│   ├── All Green (healthy)
│   ├── Partial Degradation (1-2 services down)
│   └── Critical (all services down)
├── Tabs: [Services*] [Metrics] [Logs] (Level 2)
│   ├── Services Tab (default)
│   │   ├── Ollama Card (🟢/🟡/🔴 + actions)
│   │   ├── CORTEX Card (🟢/🟡/🔴 + actions)
│   │   └── Neuro Card (optional service)
│   ├── Metrics Tab
│   │   ├── Loading (fetching last 10 queries)
│   │   ├── Charts (latency trend, P@5/R@10)
│   │   └── Empty (no queries yet)
│   └── Logs Tab
│       ├── Service Selector (Ollama | CORTEX | Neuro)
│       ├── Log Viewer (last 50 lines, scrollable)
│       └── Actions ([Export] [Clear] [Refresh])
└── Modal: Service Details (Level 3)
    ├── Triggered by: Click [View Details] on service card
    ├── Content: Full config, version, uptime, logs
    └── Actions: [Close] [Export Diagnostics]
```

**State Transitions:**

**All Green → Partial Degradation:**
- Trigger: Health check detects service down
- UI: Status indicator changes 🟢 → 🔴, notification toast

**Partial Degradation → All Green:**
- Trigger: Service restart successful
- UI: Status indicator changes 🔴 → 🟢, success toast

**Healthy → Critical:**
- Trigger: Ollama + CORTEX both down
- UI: Red alert banner, "System not operational. Restart required."

**State Persistence:**
- Last health check: Updated every 30s (background polling)
- Log view scroll: Not persisted (resets on tab switch)

---

### ⚙ SETTINGS — States & Subscreens

**Subscreen Hierarchy:**
```
Settings (Level 1)
├── Tabs: [General] [Models*] [Search] [Advanced] (Level 2)
│   ├── General Tab
│   │   ├── UI Preferences (theme, language)
│   │   └── Auto-start settings
│   ├── Models Tab (default)
│   │   ├── LLM Selection (radio buttons)
│   │   ├── Embedding Model (auto-selected)
│   │   └── [+ Add Custom Model] button
│   ├── Search Tab
│   │   ├── Top-K Slider (5-50)
│   │   ├── Mode Radio (Local*/Global/Naive)
│   │   └── Post-processing toggles
│   └── Advanced Tab
│       ├── Server Configs (host:port)
│       ├── Logging Level (dropdown)
│       └── [Open Log Directory] button
└── Modals (Level 3)
    ├── Add Custom Model (input: model name, pulls from Ollama)
    ├── Model Download Progress (progress bar, ETA, cancel)
    ├── Reset Confirmation ("This will restore all defaults")
    └── Invalid Input Error ("top_k must be 5-50")
```

**State Transitions:**

**Viewing → Editing:**
- Trigger: User changes any setting value
- UI: [Save Settings] button highlights, unsaved indicator (*)

**Editing → Saving:**
- Trigger: User clicks [Save Settings]
- UI: Brief loading, then success toast "✅ Settings Saved"

**Editing → Validation Error:**
- Trigger: User enters invalid value (e.g., top_k=200)
- UI: Red error message under field, [Save] button disabled

**Viewing → Downloading Model (async):**
- Trigger: User selects model not available locally
- UI: Modal opens, progress bar, can switch tabs while downloading

**State Persistence:**
- Unsaved changes: Warn on tab switch ("Unsaved changes. Save or discard?")
- Active settings tab: Saved when switching primary tabs

---

## 🧭 BASIC VS ADVANCED USER PATTERNS

Differentiation strategy for Persona 1 (Basic) vs Persona 2 (Advanced).

### Default Experience (Persona 1 - Basic User)

**Visible by Default:**
- ✅ Chat (simple input, clear responses)
- ✅ Library (browse, search by name)
- ✅ System Status (service health indicators only)
- ✅ Settings → General, Models (common options)

**Hidden by Default:**
- ❌ Advanced Settings tab (only [General] [Models] [Search] visible)
- ❌ Logs tab in System Status
- ❌ Detailed metrics (P@5, R@10, latency breakdown)
- ❌ Manual CORTEX query parameters

**Simplified Language:**
- "Chat" instead of "LLM Dialog Interface"
- "Search Quality" instead of "Precision @ 5"
- "Add Documents" instead of "Index Custom Knowledge Base"

**Error Handling:**
- Simple messages: "Connection lost. Try restarting."
- Auto-suggest actions: [Restart CORTEX] button instead of instructions

---

### Advanced Experience (Persona 2 - Power User)

**Unlocked by:**
- Toggle in Settings → General: `☑ Show Advanced Options`
- OR: Keyboard shortcut `Ctrl+Shift+A` (toggle advanced mode)

**Additional Features Shown:**
- ✅ Settings → Advanced tab (server configs, logging)
- ✅ System Status → Logs tab (full logs, export)
- ✅ System Status → Metrics tab (latency chart, P@5/R@10)
- ✅ Chat → Query Inspector (hover assistant message → see CORTEX params used)
- ✅ Library → Indexing Status (progress, errors, re-index button)

**Detailed Language:**
- "LLM Model: qwen2.5:14b-instruct-q4_k_m"
- "Precision@5: 0.184 | Recall@10: 0.268"
- "CORTEX Query (local mode, top_k=20, 6.7s latency)"

**Error Handling:**
- Technical details: "Connection refused (ECONNREFUSED) on localhost:8004"
- Full stack traces available in Logs tab
- Manual actions: [Open Terminal], [View Config File]

---

### Visual Indicator

**In header (when advanced mode active):**
```
┌──────────────────────────────────────────┐
│ WORLD_OLLAMA          [🔧 Advanced] ⚙ ☰│
└──────────────────────────────────────────┘
```

**In Settings:**
```
⚙ Settings > General

☑ Show Advanced Options
   Unlock technical features, logs, and detailed metrics
   (Recommended for developers and power users)
```

---

## 📝 СЛЕДУЮЩИЕ ШАГИ

### Статус документа

**Завершено (Task B):**
- ✅ Navigation Hierarchy (3 levels: Layout → Content → Modals)
- ✅ Entity Relationship Model (User → ChatSession → Message → CORTEXQuery → Documents)
- ✅ Subscreen/State Details (Chat, Library, System, Settings — all states mapped)
- ✅ Basic vs Advanced User Patterns (Persona 1 vs Persona 2 differentiation)

**Для Phase 2 (следующие задачи):**
1. **Task C:** Create 04_TAURI_TECH_CONSTRAINTS.md (platform, local-first, performance)
2. **Task D:** Create 05_MVP_SCOPE_AND_PRIORITIES.md (Must/Should/Could)
3. **Task E:** Create 06_UI_PATTERNS_AND_COMPONENTS.md (layouts, components, style)

**Для finalization (после Phase 2):**
- Create detailed wireframes для каждого раздела (Figma/Excalidraw)
- Define navigation animations (transitions, fade-in/out)
- Accessibility considerations (keyboard navigation, screen reader)
- Responsive design (window resize behavior, min/max sizes)

### Зависимости

- **01_PERSONAS_AND_CONTEXT.md** — используется для определения сложности UI
- **02_USER_FLOWS.md** — flows реализуются через эту IA
- **04_TAURI_TECH_CONSTRAINTS.md** (next) — технические ограничения для IA design
- **05_MVP_SCOPE_AND_PRIORITIES.md** (next) — приоритизация features для IA

---

**Статус:** ✅ COMPLETE (Structure + Navigation + States + Entity Model + User Patterns)  
**Обновлено:** 27.11.2025 (Task B завершён)  
**Автор:** UX Team (CODEC executor)
