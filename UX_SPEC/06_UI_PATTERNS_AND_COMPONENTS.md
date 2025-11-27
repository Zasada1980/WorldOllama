# UX-SPEC: UI PATTERNS AND COMPONENTS

**Проект:** WORLD_OLLAMA Desktop Client (Tauri)  
**Документ:** UI Design System & Component Library  
**Версия:** v1.0  
**Дата создания:** 27.11.2025  
**Статус:** ✅ COMPLETE (Task E)

---

## 📋 ЦЕЛЬ ДОКУМЕНТА

Определение визуального языка, UI-паттернов и переиспользуемых компонентов для обеспечения консистентного и профессионального пользовательского интерфейса.

---

## 🎨 DESIGN PRINCIPLES

### 1. Local-First Transparency

**Principle:**  
Пользователь всегда видит реальное состояние системы (нет фальшивых индикаторов прогресса).

**Implementation:**
- ✅ Show real service status (🟢/🔴), not "probably working"
- ✅ Display actual indexing progress (45/486 docs), not generic spinner
- ✅ Expose errors clearly ("CORTEX connection refused"), not "Something went wrong"

**Anti-Patterns:**
- ❌ Phantom spinners (loading forever with no timeout)
- ❌ "Almost done..." without actual percentage
- ❌ Silent failures (query fails, user sees nothing)

---

### 2. Chat-First Hierarchy

**Principle:**  
Chat interface is the primary focus; other sections support it.

**Implementation:**
- Chat tab = default on launch
- Chat input = always visible (no scroll to find)
- Sources panel = accessible but non-intrusive (collapsible)

**Visual Hierarchy:**
```
Primary:   Chat input, Assistant responses
Secondary: Sources, System status
Tertiary:  Settings, Advanced options
```

---

### 3. Minimal Cognitive Load

**Principle:**  
Reduce visual noise; show only what's necessary for current task.

**Implementation:**
- One primary action per screen (e.g., Chat: "Send", Settings: "Save")
- Hide advanced features by default (toggle "Show Advanced")
- Use progressive disclosure (Settings tabs: General visible, Advanced hidden)

**Example:**
- Basic user sees: [General] [Models] [Search] tabs
- Advanced user sees: + [Advanced] tab (after toggle)

---

### 4. Consistent Visual Language

**Principle:**  
Same patterns for same actions across all screens.

**Implementation:**
- All service cards use same status indicator (🟢/🟡/🔴)
- All modals have [Cancel] [Confirm] buttons in same positions
- All loading states use skeleton UI (not random spinners)

---

## 🏗️ LAYOUT PATTERNS

### Pattern 1: Main Application Layout

**Structure:**
```
┌────────────────────────────────────────────┐
│ WORLD_OLLAMA                    [Min][×]   │ ← Window Title Bar
├────────────────────────────────────────────┤
│ [💬 Chat] [📚 Library] [🔧 System] [⚙]    │ ← Primary Tabs
├────────────────────────────────────────────┤
│                                            │
│            CONTENT AREA                    │
│         (varies by active tab)             │
│                                            │
│                                            │
└────────────────────────────────────────────┘
```

**Specs:**
- **Window:** Min 1024x768, default 1280x900, no max (resizable)
- **Title Bar:** OS-native (Tauri default)
- **Tabs:** Height 48px, always visible, no scroll
- **Content:** Fills remaining space, scrollable if needed

**Tauri Config:**
```json
{
  "tauri": {
    "windows": [{
      "title": "WORLD_OLLAMA",
      "width": 1280,
      "height": 900,
      "minWidth": 1024,
      "minHeight": 768
    }]
  }
}
```

---

### Pattern 2: Chat Layout (3-Column)

**Structure:**
```
┌──────┬────────────────────────┬──────────┐
│      │                        │          │
│ SIDE │   CHAT THREAD          │ SOURCES  │
│ BAR  │                        │ (toggle) │
│      │                        │          │
│ 240px│   flexible             │ 320px    │
└──────┴────────────────────────┴──────────┘
```

**Sidebar (Left):**
- Width: 240px fixed
- Content: Conversation history (deferred to Post-MVP)
- MVP: Hide sidebar (Chat thread takes full width)

**Chat Thread (Center):**
- Width: Flexible (fills space)
- Scrollable: Yes (auto-scroll to bottom on new message)
- Padding: 24px horizontal

**Sources Panel (Right):**
- Width: 320px when expanded
- Collapsible: Yes (button: "View Sources →")
- Default: Collapsed (MVP)

**Responsive:**
- <1024px width: Hide sidebar, collapse sources (Chat only)

---

### Pattern 3: Library Layout (2-Column + Preview)

**Structure:**
```
┌────────┬────────────┬─────────────────┐
│ FILTER │   LIST     │    PREVIEW      │
│ (side) │            │   (expandable)  │
│ 200px  │   400px    │    flexible     │
└────────┴────────────┴─────────────────┘
```

**Filters Sidebar:**
- Width: 200px
- Content: Category checkboxes, search input, stats

**Document List:**
- Width: 400px fixed
- Scrollable: Virtual scroll (render 20 visible items)
- Item height: 64px (filename + metadata)

**Preview Panel:**
- Width: Flexible
- Modes: Preview (collapsed), Full View (expanded)
- Expandable: Click [View Full] → takes 60% width

---

### Pattern 4: Settings Layout (Tabbed)

**Structure:**
```
┌─────────────────────────────────────┐
│ [General] [Models] [Search] [Adv*]  │ ← Sub-tabs
├─────────────────────────────────────┤
│                                     │
│    SETTINGS FORM                    │
│    (varies by active tab)           │
│                                     │
│  [Reset Defaults]    [Save]         │ ← Actions
└─────────────────────────────────────┘
```

**Tabs:**
- Height: 40px
- Horizontal scroll if >4 tabs (unlikely)

**Form Area:**
- Padding: 24px
- Max width: 600px (centered for readability)
- Scrollable: Yes

**Actions:**
- Bottom-right: [Save Settings] (primary)
- Bottom-left: [Reset to Defaults] (secondary, warning)

---

## 🧩 CORE COMPONENTS

### Component 1: ChatMessage

**Purpose:** Display user or assistant message in chat thread

**Variants:**

**User Message:**
```
┌────────────────────────────────────┐
│ You                     14:32      │ ← Metadata
│ How to apply TRIZ principle 1?    │ ← Content
└────────────────────────────────────┘
```

**Assistant Message:**
```
┌────────────────────────────────────┐
│ Assistant               14:32      │
│ TRIZ Principle 1 "Drobienie"      │
│ (Segmentation) involves...         │
│                                    │
│ Sources: 1.triz_droblenie.txt +4   │ ← Sources badge
└────────────────────────────────────┘
```

**Props:**
```typescript
interface ChatMessageProps {
  role: "user" | "assistant";
  content: string;
  timestamp: Date;
  sources?: SourceDocument[];  // Only for assistant
  isStreaming?: boolean;       // Typewriter effect
}
```

**Styling:**
- **User:** Right-aligned, blue background (#E3F2FD), grey text
- **Assistant:** Left-aligned, white background, black text
- **Padding:** 16px
- **Border-radius:** 8px
- **Font:** Inter 14px (body), 12px (metadata)

**States:**
- Default (static text)
- Streaming (cursor animation, word-by-word append)
- Error (red border, error icon)

---

### Component 2: SourceBadge

**Purpose:** Show reference to source document (clickable pill)

**Structure:**
```
┌─────────────────────────┐
│ 📄 1.triz_droblenie.txt │  ← Pill badge
└─────────────────────────┘
```

**Collapsed View (when >5 sources):**
```
Sources: 📄 doc1.txt, 📄 doc2.txt, 📄 doc3.txt +7 more
```

**Props:**
```typescript
interface SourceBadgeProps {
  filename: string;
  score?: number;        // Optional relevance score
  onClick: () => void;   // Open document viewer
}
```

**Styling:**
- Background: Light grey (#F5F5F5)
- Border: 1px solid #E0E0E0
- Padding: 4px 12px
- Border-radius: 16px (pill shape)
- Font: Inter 12px
- Icon: 📄 emoji (simple, no custom icon)

**Interaction:**
- Hover: Background → #E8E8E8
- Click: Open document in Library → Full View mode

---

### Component 3: StatusIndicator

**Purpose:** Show service health status

**Variants:**

**🟢 Healthy:**
```
🟢 Ollama          Running
   Port: 11434
```

**🟡 Warning:**
```
🟡 CORTEX          Slow
   Indexing in progress (45/486)
```

**🔴 Down:**
```
🔴 CORTEX          Connection Refused
   Last seen: 2 minutes ago
   [Restart] [View Logs]
```

**Props:**
```typescript
interface StatusIndicatorProps {
  serviceName: string;
  status: "healthy" | "warning" | "down";
  details?: string;      // Subtext (port, error)
  actions?: Action[];    // Buttons (Restart, Logs)
}
```

**Styling:**
- Card: White background, 1px border (#E0E0E0), 8px radius
- Padding: 16px
- Icon: 🟢/🟡/🔴 (24px, left-aligned)
- Font: Inter 16px (service name), 14px (details)

**States:**
- Default (static)
- Updating (pulse animation on icon)

---

### Component 4: Button

**Purpose:** Primary and secondary actions

**Variants:**

**Primary (Call-to-Action):**
```
┌──────────────┐
│ Save Settings│  ← Blue, bold
└──────────────┘
```

**Secondary (Less Important):**
```
┌──────────┐
│ Cancel   │  ← Grey, outlined
└──────────┘
```

**Danger (Destructive Action):**
```
┌──────────┐
│ Delete   │  ← Red background
└──────────┘
```

**Props:**
```typescript
interface ButtonProps {
  variant: "primary" | "secondary" | "danger";
  disabled?: boolean;
  loading?: boolean;    // Show spinner
  onClick: () => void;
  children: React.ReactNode;
}
```

**Styling (Primary):**
- Background: #1976D2 (blue)
- Color: White
- Padding: 10px 24px
- Border-radius: 4px
- Font: Inter 14px, medium weight
- Hover: Background → #1565C0

**Styling (Secondary):**
- Background: Transparent
- Border: 1px solid #BDBDBD
- Color: #424242
- Hover: Background → #F5F5F5

**Styling (Danger):**
- Background: #D32F2F (red)
- Color: White
- Hover: Background → #C62828

**States:**
- Default
- Hover
- Active (pressed)
- Disabled (opacity 0.5, no hover)
- Loading (spinner inside button, disabled)

---

### Component 5: Modal

**Purpose:** Blocking overlay for confirmations, forms, errors

**Structure:**
```
┌─────────────────────────────────────┐
│ ⚠️ Confirm Service Restart          │ ← Header
├─────────────────────────────────────┤
│ Restarting CORTEX will interrupt    │ ← Body
│ any ongoing queries. Continue?      │
│                                     │
│                  [Cancel] [Restart] │ ← Actions
└─────────────────────────────────────┘
```

**Props:**
```typescript
interface ModalProps {
  title: string;
  icon?: string;         // Emoji (⚠️, ✅, ❌)
  children: React.ReactNode;
  actions: ModalAction[];
  onClose: () => void;
}

interface ModalAction {
  label: string;
  variant: "primary" | "secondary" | "danger";
  onClick: () => void;
}
```

**Styling:**
- Overlay: Black 50% opacity
- Modal: White, 600px max-width, centered
- Padding: 24px
- Border-radius: 8px
- Shadow: 0 4px 20px rgba(0,0,0,0.15)

**Behavior:**
- Click outside → Close (if no unsaved data)
- Esc key → Close
- Focus trap (Tab cycles through modal elements)

---

### Component 6: Toast (Notification)

**Purpose:** Transient feedback (success, error, info)

**Variants:**

**Success:**
```
┌──────────────────────────┐
│ ✅ Settings saved        │
└──────────────────────────┘
```

**Error:**
```
┌──────────────────────────────┐
│ ❌ CORTEX connection failed  │
└──────────────────────────────┘
```

**Info:**
```
┌──────────────────────────────┐
│ ℹ️ Indexing 45/486 documents │
└──────────────────────────────┘
```

**Props:**
```typescript
interface ToastProps {
  type: "success" | "error" | "info";
  message: string;
  duration?: number;  // Auto-dismiss (default 3000ms)
}
```

**Styling:**
- Position: Bottom-right, 16px from edges
- Background: 
  - Success: #4CAF50
  - Error: #F44336
  - Info: #2196F3
- Color: White
- Padding: 12px 16px
- Border-radius: 4px
- Font: Inter 14px

**Behavior:**
- Slide in from bottom (200ms animation)
- Auto-dismiss after 3s (or custom duration)
- Click to dismiss immediately
- Stack multiple toasts (max 3 visible)

---

### Component 7: Skeleton Loader

**Purpose:** Placeholder for loading content (better than spinners)

**Example (Chat Message):**
```
┌────────────────────────────────────┐
│ ████████         ░░░░              │ ← Shimmer effect
│ ████████████████                   │
│ ██████████████████████             │
└────────────────────────────────────┘
```

**Example (Document List):**
```
┌────────────────────┐
│ ████████    ░░░░   │
│ ████████    ░░░░   │
│ ████████    ░░░░   │
└────────────────────┘
```

**Props:**
```typescript
interface SkeletonProps {
  type: "text" | "card" | "list-item";
  count?: number;  // Repeat N times
}
```

**Styling:**
- Background: Linear gradient (grey → white → grey)
- Animation: Shimmer effect (move gradient left-to-right, 1.5s loop)
- Border-radius: Match actual content

**Usage:**
- Show while loading chat history (skeleton message x5)
- Show while loading document list (skeleton item x10)

---

### Component 8: ProgressBar

**Purpose:** Show determinate progress (file upload, indexing)

**Structure:**
```
Indexing Documents...
████████████░░░░░░░░░░  45/486 (9%)
```

**Props:**
```typescript
interface ProgressBarProps {
  current: number;
  total: number;
  label?: string;      // "Indexing Documents..."
  showPercentage?: boolean;
}
```

**Styling:**
- Height: 8px
- Background: #E0E0E0 (track)
- Foreground: #1976D2 (filled)
- Border-radius: 4px
- Text: Inter 14px, above bar

**Animation:**
- Smooth transition (300ms ease) when `current` updates

---

## 🎨 VISUAL STYLE GUIDE

### Color Palette

**Primary Colors:**
- **Primary Blue:** #1976D2 (buttons, links, active states)
- **Secondary Grey:** #757575 (secondary text, icons)

**Status Colors:**
- **Success Green:** #4CAF50 (✅)
- **Warning Yellow:** #FFC107 (⚠️)
- **Error Red:** #F44336 (❌)
- **Info Blue:** #2196F3 (ℹ️)

**Neutral Colors:**
- **Background:** #FFFFFF (main)
- **Surface:** #F5F5F5 (cards, panels)
- **Border:** #E0E0E0 (dividers)
- **Text Primary:** #212121
- **Text Secondary:** #757575

**Chat Message Colors:**
- **User Message BG:** #E3F2FD (light blue)
- **Assistant Message BG:** #FFFFFF (white)

---

### Typography

**Font Family:**
- **Primary:** Inter (Google Fonts)
- **Monospace:** Roboto Mono (for code, logs)

**Font Sizes:**
```css
/* Headings */
h1: 24px / 1.4 (page titles)
h2: 20px / 1.4 (section headers)
h3: 16px / 1.4 (subsections)

/* Body */
body: 14px / 1.6 (main text)
small: 12px / 1.5 (metadata, timestamps)

/* UI Elements */
button: 14px / 1 (medium weight)
input: 14px / 1.4
badge: 12px / 1
```

**Font Weights:**
- Regular: 400 (body text)
- Medium: 500 (buttons, labels)
- Bold: 700 (headings, emphasis)

---

### Spacing System

**Base Unit:** 8px

**Spacing Scale:**
```css
xs:  4px   (tight spacing)
sm:  8px   (default gap)
md:  16px  (section padding)
lg:  24px  (card padding)
xl:  32px  (page margins)
xxl: 48px  (major sections)
```

**Usage:**
- Component padding: `md` (16px)
- Card margin: `lg` (24px)
- Page margins: `xl` (32px)

---

### Shadows & Elevation

**Elevation Levels:**

**Level 0 (Flat):**
- Usage: Text, icons
- Shadow: None

**Level 1 (Subtle):**
- Usage: Cards, panels
- Shadow: `0 1px 3px rgba(0,0,0,0.12)`

**Level 2 (Raised):**
- Usage: Modals, dropdowns
- Shadow: `0 4px 20px rgba(0,0,0,0.15)`

**Level 3 (Floating):**
- Usage: Tooltips, context menus
- Shadow: `0 8px 32px rgba(0,0,0,0.2)`

---

### Border Radius

**Rounding Scale:**
```css
none: 0px     (sharp edges, dividers)
sm:   4px     (buttons, inputs)
md:   8px     (cards, messages)
lg:   16px    (pills, badges)
full: 9999px  (circles, rounded pills)
```

**Usage:**
- Buttons: `sm` (4px)
- Chat messages: `md` (8px)
- Source badges: `lg` (16px, pill)

---

### Icons

**Strategy:** Use emoji for simplicity (no icon library)

**Common Icons:**
- 💬 Chat
- 📚 Library
- 🔧 System
- ⚙ Settings
- 🟢 Healthy
- 🟡 Warning
- 🔴 Down
- ✅ Success
- ❌ Error
- ⚠️ Warning
- ℹ️ Info
- 📄 Document

**Fallback:** If emoji not suitable, use SVG (e.g., send arrow ↑)

---

## 🔄 INTERACTION PATTERNS

### Hover States

**All Interactive Elements:**
- Background lightens/darkens slightly
- Cursor: pointer
- Transition: 150ms ease

**Example (Button):**
```css
button:hover {
  background: darken(primary, 10%);
  transition: background 150ms ease;
}
```

---

### Loading States

**Pattern:** Replace content with skeleton, not spinner

**Example (Loading Chat):**
```
Before:
  [Spinner]

After (Better):
  ┌─────────────────┐
  │ ████████  ░░░░  │  ← Skeleton message
  │ ████████████    │
  └─────────────────┘
```

**Exception:** Use spinner only for indeterminate tasks (e.g., "Connecting to CORTEX...")

---

### Error States

**Pattern:** Show error inline, with recovery action

**Example (CORTEX Down):**
```
❌ Failed to connect to CORTEX
   Connection refused on localhost:8004

   [Retry]  [View Logs]
```

**Guidelines:**
- Red color (#F44336)
- Error icon (❌)
- Actionable message (not just "Error")
- Recovery button (Retry, Restart, etc.)

---

### Empty States

**Pattern:** Show helpful message + next action

**Example (No Chat History):**
```
💬 No conversations yet

   Ask your first question to get started!

   [Start Chat]
```

**Guidelines:**
- Friendly icon/emoji
- 2-3 lines max
- Call-to-action button

---

## 📱 RESPONSIVE BEHAVIOR

### Breakpoints

```css
/* Desktop (primary target) */
xl: 1280px+  (default)

/* Laptop */
lg: 1024px - 1279px  (hide sidebar)

/* Tablet (not primary, but functional) */
md: 768px - 1023px   (single column)
```

**Primary Target:** 1280x900 (desktop)  
**Minimum Supported:** 1024x768

---

### Adaptive Layouts

**At <1280px:**
- Hide Chat sidebar (deferred to Post-MVP anyway)
- Collapse Sources panel by default

**At <1024px:**
- Library: Stack filters above list (no sidebar)
- Settings: Full-width form (no max-width)

**At <768px:**
- Not optimized (desktop-first app)
- Basic functionality works (scrollable)

---

## 🌓 DARK MODE (DEFERRED)

**Status:** Could Have (Post-MVP)

**If Implemented:**
- Background: #121212
- Surface: #1E1E1E
- Text: #E0E0E0
- Primary: #64B5F6 (lighter blue)

**Toggle:** Settings → General → Theme (Light/Dark/Auto)

---

## 📝 СЛЕДУЮЩИЕ ШАГИ

### Статус документа

**Завершено (Task E):**
- ✅ Design principles (4 core principles)
- ✅ Layout patterns (4 layouts: Main, Chat, Library, Settings)
- ✅ Core components (8 components with specs)
- ✅ Visual style guide (colors, typography, spacing)
- ✅ Interaction patterns (hover, loading, error, empty states)

**Для Implementation:**
1. Create Svelte component library based on this spec
2. Build Storybook/component showcase (optional)
3. Test components in isolation before integration

**Для Phase 3 (Tauri MVP Development):**
- Use this doc as reference for all UI decisions
- Maintain consistency across all screens
- Add new components as needed (follow same patterns)

---

**Статус:** ✅ COMPLETE (Design System fully defined)  
**Обновлено:** 27.11.2025 (Task E завершён)  
**Автор:** UX Team (CODEC executor)
