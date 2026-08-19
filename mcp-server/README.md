# ⚡️ LOCA / Pluto Model Context Protocol (MCP) Server

Connect your local-first **LOCA / Pluto** personal operating system directly to any AI client (**Claude Desktop, Cursor, Antigravity IDE, Windsurf, Cline, Open-WebUI**).

---

## 🏛 Architecture

- **Protocol**: Model Context Protocol (MCP) 2026 Specification
- **Transport**: Standard Input/Output (`stdio`) JSON-RPC 2.0
- **Database Engine**: Direct read/write SQLite integration with SwiftData / CoreData reference epoch offsets
- **Privacy & Sovereignty**: 100% offline and local on your Mac. No cloud dependencies or telemetry.

---

## 🚀 Quickstart

### 1. Build the Server
```bash
cd mcp-server
npm install
npm run build
```

### 2. Connect to AI Clients

#### A. Claude Desktop
Add this to `~/Library/Application Support/Claude/claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "loca": {
      "command": "node",
      "args": [
        "/Users/mihirmaru/Downloads/LOCA---Local-First-Habit-Tracker/mcp-server/build/index.js"
      ]
    }
  }
}
```

#### B. Cursor
Go to **Cursor Settings → MCP → Add New MCP Server**:
- **Name**: `loca`
- **Type**: `command`
- **Command**: `node /Users/mihirmaru/Downloads/LOCA---Local-First-Habit-Tracker/mcp-server/build/index.js`

#### C. Visual MCP Inspector (Testing & Debugging)
```bash
npm run inspector
```

---

## 🛠 Available Tools (16 Tools)

### ☀️ Day Architecture & HUD
- `get_daily_briefing`: Real-time morning summary across habits, scheduled tasks, and focus stats.

### ⚡️ Today: Habits & Streaks
- `list_habits`: List all habits with streaks, daily targets, and today's status.
- `log_habit`: Check-in or log quantitative values for a habit.
- `create_habit`: Create a new custom habit board.

### 🎯 Today: Tasks & Day Planner
- `list_tasks`: Filter tasks by priority (P1–P4), due date bucket (Today, Upcoming, Anytime), or project.
- `create_task`: Create a new prioritized task with start time and duration.
- `complete_task`: Mark a task as completed or active.
- `schedule_timeblock`: Place a task on the Day Planner timeline.

### 📝 Studio: Notes & Knowledge Base
- `search_notes`: Full-text search and tag filtering (`#architecture`, etc.).
- `get_note`: Get full note content, checklists, and structured tables.
- `create_note`: Create a formatted markdown note.
- `update_note`: Append text, edit titles, or update tags.

### 🚀 Studio: Projects & Milestones
- `list_projects`: View all work projects with progress percentage.
- `create_project`: Create a work project with milestone tasks.

### 🧠 Focus Room
- `get_focus_stats`: Query deep work focus minutes and completed goals.
- `log_focus_session`: Record a completed focus sprint.

### 🗺 Life: Satellite Atlas & Blueprint
- `list_treks`: Query mountain summits, coordinates, and elevation telemetry.
- `log_summit`: Record a conquered summit in the Atlas.
- `get_life_blueprint`: Retrieve the 10-Year Horizon and Core Manifesto.
- `add_blueprint_goal`: Add an ambitious milestone to the 10-Year Horizon.

---

## 📦 Dynamic Resources (`loca://`)

- `loca://daily-briefing`: Live Markdown summary of today's schedule and habits.
- `loca://habits`: JSON feed of active habits and streaks.
- `loca://tasks/today`: JSON list of today's priority tasks.
- `loca://notes/recent`: 10 most recent notes with snippets.
- `loca://blueprint`: 10-Year Life Horizon and core principles.

---

## 🧠 AI Workflows & Prompts

- `morning_planning`: Optimizes today's agenda and habit stack into an hour-by-hour timeline.
- `evening_reflection`: Audits completed tasks, calculates deep work hours, and crafts an evening journal prompt.
- `note_synthesizer`: Extracts actionable projects and tasks from raw brainstorming notes.
- `weekly_review`: Synthesizes 7-day habit consistency, deep work volume, and project velocity.
