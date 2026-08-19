import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { habitsRepo } from "../db/habits.js";
import { tasksRepo } from "../db/tasks.js";
import { notesRepo } from "../db/notes.js";
import { lifeRepo } from "../db/life.js";
import { focusRepo } from "../db/focus.js";

export function registerResources(server: McpServer): void {
  // 1. Daily Briefing Resource
  server.resource(
    "daily-briefing",
    "loca://daily-briefing",
    {
      description: "Live real-time summary of today's habits, scheduled tasks, and focus time",
      mimeType: "text/markdown",
    },
    async (uri) => {
      const habits = habitsRepo.listHabits({ activeOnly: true });
      const completedHabits = habits.filter((h) => h.todayCompleted);
      const tasksToday = tasksRepo.listTasks({ bucket: "Today", completed: false });
      const focusStats = focusRepo.getFocusStats(1);

      const dateStr = new Date().toLocaleDateString("en-US", {
        weekday: "long",
        year: "numeric",
        month: "long",
        day: "numeric",
      });

      let md = `# ☀️ Daily Briefing — ${dateStr}\n\n`;
      md += `### ⚡️ Habits (${completedHabits.length}/${habits.length})\n`;
      for (const h of habits) {
        md += `- ${h.todayCompleted ? "✅" : "⏳"} **${h.emoji} ${h.name}** (Streak: ${h.currentStreak}d)\n`;
      }

      md += `\n### 🎯 Today's Scheduled Tasks (${tasksToday.length})\n`;
      for (const t of tasksToday) {
        const time = t.dueDate ? ` [Due: ${new Date(t.dueDate).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}]` : "";
        md += `- [ ] [${t.priorityLabel}] ${t.title}${time}\n`;
      }

      md += `\n### 🧠 Deep Work Today\n- ${focusStats.totalMinutes} minutes logged\n`;

      return {
        contents: [
          {
            uri: uri.href,
            mimeType: "text/markdown",
            text: md,
          },
        ],
      };
    }
  );

  // 2. Habits JSON Resource
  server.resource(
    "habits-live",
    "loca://habits",
    {
      description: "Live habit boards and streak tracking data",
      mimeType: "application/json",
    },
    async (uri) => {
      const habits = habitsRepo.listHabits({ activeOnly: true });
      return {
        contents: [
          {
            uri: uri.href,
            mimeType: "application/json",
            text: JSON.stringify(habits, null, 2),
          },
        ],
      };
    }
  );

  // 3. Tasks Today Resource
  server.resource(
    "tasks-today",
    "loca://tasks/today",
    {
      description: "All tasks scheduled or due today grouped by priority",
      mimeType: "application/json",
    },
    async (uri) => {
      const tasks = tasksRepo.listTasks({ bucket: "Today" });
      return {
        contents: [
          {
            uri: uri.href,
            mimeType: "application/json",
            text: JSON.stringify(tasks, null, 2),
          },
        ],
      };
    }
  );

  // 4. Recent Notes Resource
  server.resource(
    "notes-recent",
    "loca://notes/recent",
    {
      description: "10 most recently updated brainstorm notes with text snippets and tags",
      mimeType: "application/json",
    },
    async (uri) => {
      const notes = notesRepo.searchNotes({ limit: 10 });
      return {
        contents: [
          {
            uri: uri.href,
            mimeType: "application/json",
            text: JSON.stringify(notes, null, 2),
          },
        ],
      };
    }
  );

  // 5. 10-Year Life Blueprint Resource
  server.resource(
    "life-blueprint",
    "loca://blueprint",
    {
      description: "10-Year Life Horizon roadmap, core personal manifesto, and master bucket list",
      mimeType: "text/markdown",
    },
    async (uri) => {
      const bp = lifeRepo.getLifeBlueprint();
      let md = `# 🗺️ 10-Year Life Horizon Blueprint\n\n`;

      for (const [category, goals] of Object.entries(bp.categories)) {
        md += `## 🌟 ${category} (${goals.length} Goals)\n`;
        if (goals.length === 0) {
          md += `_No goals defined yet._\n\n`;
          continue;
        }
        for (const g of goals) {
          const check = g.isAchieved ? "✅" : "⭕️";
          const yr = g.targetYear ? ` [Target: ${g.targetYear}]` : "";
          const note = g.manifestoNotes ? ` — _${g.manifestoNotes}_` : "";
          md += `- ${check} **${g.title}**${yr}${note}\n`;
        }
        md += `\n`;
      }

      return {
        contents: [
          {
            uri: uri.href,
            mimeType: "text/markdown",
            text: md,
          },
        ],
      };
    }
  );
}
