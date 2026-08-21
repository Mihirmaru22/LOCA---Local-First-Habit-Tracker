# 🪐 PLUTO for macOS — Local-First Habit Tracker & Life Operating System

> **"Does it let me *see* my life, or does it just *show me data* about my life?"**  
> — *The Central Question, PLUTO Engineering Manifesto*

[![Platform: macOS](https://img.shields.io/badge/Platform-macOS%2014.0%2B%20(Sonoma%20%2F%20Sequoia)-000000?style=for-the-badge&logo=apple&logoColor=white)](https://apple.com/macos)
[![Swift: 6.0](https://img.shields.io/badge/Swift-6.0%20Strict%20Concurrency-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![Storage: SwiftData](https://img.shields.io/badge/Storage-Local--First%20SwiftData%20%2B%20SQLite-4A90E2?style=for-the-badge)](https://developer.apple.com/xcode/swiftdata/)
[![MCP: Enabled](https://img.shields.io/badge/AI%20Protocol-Model%20Context%20Protocol%20(MCP)-8A2BE2?style=for-the-badge)](https://modelcontextprotocol.io)

**PLUTO** is a sovereign, local-first personal operating system for macOS engineered to unify daily time execution, task inventories, keystone habits, rich-text note synthesis, deep focus sessions, and long-term life horizons into a single fluid, Apple-native desktop canvas.

> [!NOTE]
> **Mobile Status Notice:** The iOS and Android platform targets are currently **on hold**. Engineering and product development are 100% focused on perfecting the flagship **macOS** experience.

---

## 🏛 The 3-Domain Desktop Architecture

PLUTO organizes all intentional living and productivity into 3 primary desktop domains, seamlessly navigated via a native macOS `NavigationSplitView` with Liquid Glass interactive controls:

```
                      ┌────────────────────────────────────────────────────────┐
                      │                 🪐 PLUTO FOR macOS                     │
                      └──────────────┬─────────────────┬───────────────────────┘
                                     │                 │
                ┌────────────────────┘                 └────────────────────┐
                ▼                                                           ▼
    ┌─────────────────────────┐                                 ┌─────────────────────────┐
    │       1. TODAY          │                                 │       2. STUDIO         │
    │  Living Day Execution   │                                 │ Knowledge & Synthesis  │
    ├─────────────────────────┤                                 ├─────────────────────────┤
    │ • Plan: Day Timeline    │                                 │ • Notes: BrainStorm     │
    │ • List: GTD Tasks       │                                 │ • Journal: Apple Canvas │
    │ • Time: Focus Studio    │                                 │ • Projects: PM Briefs   │
    └─────────────────────────┘                                 └─────────────────────────┘
                                             │
                                             ▼
                                ┌─────────────────────────┐
                                │        3. LIFE          │
                                │   Horizons & Atlases    │
                                ├─────────────────────────┤
                                │ • Mountain Trek Atlas   │
                                │ • GeoJSON Travel Atlas  │
                                │ • Bucket List / Badges  │
                                └─────────────────────────┘
```

---

## ⚔️ Dual-Tier Workspace Architecture: Hero Mode & Architect Mode

PLUTO provides two distinct workspace environments tailored to cognitive flow and depth:

| Workspace | Mode Name | Layout | Capabilities & Focus |
|---|---|---|---|
| **⚔️ Tier 1** | **Hero Mode** | **2-Column Focus Engine** | **Left Column**: Tri-Diurnal Horizontal Timeline (Morning 🌅, Afternoon ☀️, Evening 🌙) + Rule of 3 Active Mission Objectives.<br>**Right Column**: Circadian Energy Battery dial, Keystone Habit consistency list & flame streaks, Weekly Momentum trends, Ambient Focus Soundscape player (Rain, Drone, White Noise, Campfire), Daily Reflection check-in. |
| **👑 Tier 2** | **Architect Mode** | **3-Column Sovereign OS** | Full 3-column `NavigationSplitView` with proportional Day Planner timeline, BrainStorm canvas, Projects management, Mountain Trek Atlas, GeoJSON Travel Atlas, Life Audit matrix, and local Model Context Protocol (MCP) AI agent integration. |

> **Mode Switch Shortcut**: Press **`⌘ + ⇧ + P`** from anywhere in the app to toggle between **Hero Mode** and **Architect Mode**.

---

## ☀️ 1. TODAY: The Living Day Execution Engine

The `Today` workspace (`⌘1`) governs immediate diurnal execution through three specialized sub-modes:

### ⏱ Plan Mode (Proportional Day Planner Timeline)
* **Visual Time Blocking**: Chronological vertical timeline mapping scheduled tasks, meetings, and routines with proportional block heights and duration bubbles.
* **Smart Adaptive Start**: Dynamically anchors the viewport to the current hour or earliest scheduled item with intelligent morning/evening lookaheads.
* **Unscheduled Backlog Tray**: Slide-out tray holding unscheduled tasks due today for drag-to-time-block assignment.
* **Natural Language Scheduler**: Fast-entry input field that infers start times and durations directly from human input (e.g., `"Deep work 2pm for 90m"`).

### 📋 List Mode (High-Velocity GTD Task Inventory)
* **Flat Continuous Inventory**: Fast, friction-free task management with 0–3 priority dot scales and custom category badges.
* **Subtasks & Progress Rings**: Nested child tasks (`TodoItem.parentID`) with real-time radial completion meters.
* **Document Detail Panel**: Calm document side-panel replacing bulky form controls with grouped cards, date/time chips, and recurrence selectors.
* **MacBlockEditor (Rich Notion-Style Blocks)**: Slash-command enabled block editor embedded into task notes supporting Paragraphs, Headings (`H1`/`H2`/`H3`), Bullet lists, Numbered lists, Checklists with strikethrough, Quotes, and Dividers.

### 🎧 Time Mode (Focus Room & Spatial Audio Studio)
* **Pomodoro Focus Engine**: Interactive round-based focus sprint timer with configurable intervals, phase switches, and countdowns.
* **Multi-Stem Spatial Audio Engine**: Procedural binaural soundscapes (5-Pole Rain & Thunder Matrix, Forest Birds, Deep Space White Noise, Polyphonic Chords) with logarithmic volume mixers.
* **Curated Wallpaper Canvas**: Zero-latency local disk/RAM cached focus backgrounds with StudyStream aesthetics, inspiring quotes, and session duration tracking.

---

## ✨ 2. STUDIO: Sovereign Knowledge & Synthesis

The `Studio` workspace (`⌘2`) unites document drafting, daily reflection, and project management:

### 📝 Notes (BrainStorm — Apple Notes Surface)
* **3-Column Split View**: Nested folder tree hierarchy, tag browser, and instant-search notes list.
* **True Native Rich Text**: Full AppKit `NSTextView` integration supporting Bold, Italic, Underline, Strikethrough, Headings, Interactive Checklists, and Tables.
* **Attachments & Quick Look**: Drag-and-drop file attachments with native macOS Quick Look previews (`Space`), In-Note Find (`⌘F`), and Link insertion (`⌘K`).
* **Sovereign Storage**: RTF data persisted directly into SwiftData/SQLite without external sync dependencies.

### 📖 Journal (Apple Journal Canvas)
* **Daylight Flow Routines**: Morning & evening keystone rituals with completion tracking.
* **Sleep Tracker**: Wake/bedtime log, duration analytics, and overnight sleep debt estimation.
* **Rich Reflection Canvas**: Floating capsule toolbar with live audio recording drawer, typography popovers, photo picker, location tagging, and mood clarity ratings.
* **Analyse Dashboard**: 30-day consistency indices, monthly heatmaps, and correlation matrices.

### 💼 Projects (Command Center)
* **Project Briefs**: Sovereign markdown/rich text briefs with phase segmentation.
* **Phased Task Breakdown**: Sectional grouping (`WorkSection`) with milestone progress bars and task delegation.

---

## 🏔️ 3. LIFE: Horizons & Adventure Atlases

The `Life` workspace (`⌘3`) provides high-altitude perspective across long-term goals and physical explorations:

### 🗺 Mountain Atlas (Trek & Expedition Canvas)
* **GPX Trail Engine**: Native parser and interactive elevation profile chart for mountaineering routes.
* **Interactive Mapbox / MapKit Canvas**: Trail rendering with Indian mountain range and state boundary GeoJSON data.
* **Expedition Passports**: High-res PDF document generation for completed expeditions, summit photo galleries, and mountaineer rank progression (`Bronze` ➔ `Silver` ➔ `Gold` ➔ `Summit Master`).
* **Apple Watch Sync**: HealthKit and workout sync bridge for altitude, heart rate, and distance stats.

### 🌏 Travel Atlas & Sovereign Bucket List
* **State & District Boundary Visualizer**: Interactive travel atlas tracking visited regions across India and worldwide.
* **Multi-Horizon Bucket List**: Multi-year life goals categorized by horizon, benchmark metrics, and trophy cabinet achievements (`🏆 Achieved` / `⏳ In Progress`).

---

## ⚡️ Model Context Protocol (MCP) Server

PLUTO ships with a built-in **Model Context Protocol (MCP)** server (`mcp-server/`), allowing local AI agents (**Claude Desktop, Cursor, Antigravity IDE, Windsurf**) to read and write to your local Pluto operating system:

```bash
# Build the MCP server
cd mcp-server
npm install
npm run build
```

### Connect to Claude Desktop
Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "pluto": {
      "command": "node",
      "args": [
        "/absolute/path/to/Plut0-main/mcp-server/build/index.js"
      ]
    }
  }
}
```

### Supported MCP Tool Capabilities (16 Tools)
- **`get_daily_briefing`**: Summarizes today's scheduled blocks, open tasks, habits, and focus metrics.
- **`manage_habits`**: Check-in, fetch streak heatmaps, and retrieve consistency stats.
- **`manage_tasks`**: Create, time-block, reschedule, and complete tasks on the day planner.
- **`query_journal`**: Search journal notes, sleep logs, and reflections.
- **`brainstorm_notes`**: Create and search rich-text notes and folders in BrainStorm.

---

## 🛰 Private Alpha Telemetry & Live Web Dossier

For private alpha testing, Pluto includes an invisible background telemetry pipeline that streams tester interactions to a real-time Creator Web Dossier:

* **Live Web Dashboard**: [https://mihirmaru22.github.io/Plut0/](https://mihirmaru22.github.io/Plut0/)
* **Direct PostgREST Supabase Ingestion**: Outbound HTTPS sync to `/rest/v1/alpha_testers`, `/rest/v1/alpha_events`, `/rest/v1/alpha_state_snapshots`, and `/rest/v1/alpha_crashes`.
* **Zero-Observer Footprint**: Asynchronous execution via `Task.detached` with zero UI lag and no tester popups.
* **Bounded Local Disk Queue**: 5,000-event / 25 MB FIFO disk limit with offline exponential backoff.

---

## 📁 Repository Structure

```
Plut0-main/
├── ios/
│   ├── Loca_Mac/                 # Native macOS 14+ Application Target (Pluto for Mac)
│   │   ├── Window/               # MacRootView, MacSidebarView, Onboarding & Guides
│   │   ├── Today/ & Todo/        # Day Planner, GTD List, MacBlockEditor, Projects
│   │   ├── Studio/               # Unified Studio Workspace (Notes, Journal, Projects)
│   │   ├── BrainStorm/           # Apple Notes Canvas, NSTextView, Folders, Tags
│   │   ├── Journal/              # Apple Journal, Sleep Track, Daylight Routines
│   │   ├── Time/ & FocusRoom/    # Pomodoro Timer, Spatial Audio DSP, Wallpapers
│   │   ├── Life/                 # Mountain Atlas, GPX Engine, Travel Atlas, Passport PDF
│   │   ├── Habits/               # Heatmaps, Progress Bars, Quantitative Habit Loggers
│   │   ├── Audit/                # Milestone Horizons & Strategic Life Audits
│   │   ├── Platform/             # Spotlight, Hotkeys, Telemetry, Diagnostics, Notifications
│   │   ├── Settings/             # Mission Control, Chrono-Tunnel, Museum Gallery
│   │   └── Menus/                # LOCACommands (macOS Menu Bar & Shortcuts)
│   ├── LOCA/                     # Shared Core Models & SwiftData Schemas
│   │   ├── Core/Models/          # HabitBoard, TodoItem, JournalNote, SleepEntry, BrainStorm
│   │   └── Core/DesignSystem/    # DS Spacing, Typography, Color, and Motion Tokens
│   └── LOCA.xcodeproj           # Xcode Project Configuration
├── mcp-server/                   # Model Context Protocol (MCP) Server for Local AI Integration
├── supabase/                     # Schema SQL and Alpha Ingest Edge Functions
├── dashboard/ & docs/            # Creator Analytics Web Dossier (GitHub Pages)
└── create_dmg.sh                 # Production macOS DMG Packaging Script
```

---

## 💻 Building & Running Pluto for Mac

### System Requirements
* **macOS 14.0+** (Sonoma / Sequoia)
* **Xcode 16.0+** (with Swift 6 compiler toolchain)
* **Apple Silicon (M1–M4) or Intel Mac**

### Build in Xcode
1. Clone or open the project folder in Xcode:
   ```bash
   open ios/LOCA.xcodeproj
   ```
2. Select the **`Loca_Mac`** target and destination **`My Mac`**.
3. Press **`⌘ + R`** to compile and launch **Pluto**.

### Build a Standalone `.dmg` Installer
Run the bundled release script to package a signed distribution DMG:
```bash
./create_dmg.sh
```

---

## ⌨️ Essential Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| **`⌘ + 1`** | Navigate to **Today** (Plan / List / Time) |
| **`⌘ + 2`** | Navigate to **Studio** (Notes / Journal / Projects) |
| **`⌘ + 3`** | Navigate to **Life** (Mountain Atlas / Travel / Bucket List) |
| **`⌘ + 4`** | Navigate to **Settings & Mission Control** |
| **`⌘ + N`** | Quick Add new Task / Note / Habit |
| **`⌘ + F`** | Search across active workspace / In-Note Find |
| **`⌘ + K`** | Insert Link in Rich Text Editor |
| **`⌥ + Space`**| Open System-Wide **Pluto Quick Action HUD** |
| **`Space`** | Quick Look preview for selected document or attachment |

---

## 🏛️ Engineering Invariants

* **Local-First Ground Truth**: SwiftData backed by SQLite is the single authoritative source of truth. All features function 100% offline.
* **Strict Concurrency**: Fully compliant with Swift 6 strict concurrency (`@MainActor`, `Sendable`, nonisolated DSP contexts).
* **Zero Unique Attributes for CloudKit**: Avoids `@Attribute(.unique)` to allow conflict-free peer synchronization.
* **Soft Delete Architecture**: Entity deletion sets `archivedAt = Date()` or `deletedAt = Date()`, ensuring zero data loss and historical referential integrity.
* **Append-Only Completions**: Task completions mutate timestamp records (`completedAt = Date()` / `completedAt = nil`) without destructive row deletes.

---

## 📄 License

Copyright © 2024–2026 Mihir Maru. All rights reserved.
