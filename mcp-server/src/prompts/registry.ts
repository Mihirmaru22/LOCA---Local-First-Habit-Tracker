import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

export function registerPrompts(server: McpServer): void {
  // 1. Morning Planning Workflow
  server.prompt(
    "morning_planning",
    "Guides the AI to audit today's habit streaks, analyze P1–P4 backlog tasks, and generate an hour-by-hour scheduled timeline for peak productivity.",
    {},
    () => {
      return {
        messages: [
          {
            role: "user",
            content: {
              type: "text",
              text: `Act as my Sovereign Chief of Staff and Day Architect. Please execute the following sequence:
1. Call 'get_daily_briefing' to fetch my current habits, today's tasks, and focus stats.
2. Call 'list_tasks' with bucket="Today" and bucket="Upcoming" to review the pending task pipeline.
3. Call 'list_habits' to inspect which streaks are active or at risk.
4. Synthesize this data into a streamlined, high-density Morning Action Plan:
   - 🔥 Priority 1 Non-Negotiable: The single most vital outcome for today.
   - ⚡️ Habit Stack: When and how to execute today's habit check-ins.
   - ⏰ Hour-by-Hour Timeline: A realistic schedule with dedicated 90-minute Deep Work blocks.
   - 🛡 Obstacle Pre-Mortem: One anticipated friction point and its countermeasure.
Format your response in sleek, structured Markdown.`,
            },
          },
        ],
      };
    }
  );

  // 2. Evening Reflection Workflow
  server.prompt(
    "evening_reflection",
    "Audits today's completed tasks, reviews habit check-ins, calculates deep work hours, and crafts an evening stoic journal prompt.",
    {},
    () => {
      return {
        messages: [
          {
            role: "user",
            content: {
              type: "text",
              text: `Act as my Evening Reflection Coach. Please execute the following sequence:
1. Call 'get_daily_briefing' to inspect what was accomplished today.
2. Call 'get_focus_stats' for the past 1 day to audit today's deep work sprint volume.
3. Call 'list_habits' to see if any habit check-ins remain unlogged for today.
4. Output an Evening Shutdown Review:
   - 🏆 Today's Wins & Completed Outcomes
   - 📈 Deep Work Hours & Productivity Velocity
   - ⚡️ Habit Audit (prompt me if any habits need check-in)
   - 📖 Stoic Journaling Prompt for overnight subconscious processing.`,
            },
          },
        ],
      };
    }
  );

  // 3. Note Synthesizer & Project Extractor
  server.prompt(
    "note_synthesizer",
    "Extracts actionable tasks, phased milestones, and key decisions from a raw brainstorm note.",
    {
      noteId: z.string().describe("UUID of the brainstorm note to analyze"),
    },
    ({ noteId }) => {
      return {
        messages: [
          {
            role: "user",
            content: {
              type: "text",
              text: `Please analyze the note with ID '${noteId}':
1. Call 'get_note' with noteId="${noteId}".
2. Extract all raw ideas, decisions, and implicit action items from the note text.
3. Structure the output into:
   - 🎯 Executive Summary (2-3 sentences)
   - 🏗 Milestone Deliverables (Phased tree)
   - 📋 Actionable Todo Items (with recommended P1-P4 priorities)
4. Ask if I would like you to automatically create a new Work Project or tasks using 'create_project' or 'create_task'.`,
            },
          },
        ],
      };
    }
  );

  // 4. Weekly Executive Review
  server.prompt(
    "weekly_review",
    "Synthesizes 7-day habit consistency, deep work focus sprint hours, milestone progress, and 10-year life blueprint alignment.",
    {},
    () => {
      return {
        messages: [
          {
            role: "user",
            content: {
              type: "text",
              text: `Act as an Executive Performance Auditor. Please perform a 7-Day Weekly Review:
1. Call 'list_habits' to check 7-day streak health and consistency scores.
2. Call 'get_focus_stats' with days=7 to analyze deep work volume and acoustic categories.
3. Call 'list_projects' to audit milestone completion percentages.
4. Call 'get_life_blueprint' to evaluate alignment with long-term 10-year horizons.
5. Provide a high-density Executive Report:
   - 📊 Weekly Discipline Scorecard (Habit consistency %)
   - 🧠 Deep Work Audit (Total hours vs 15-hour weekly target)
   - 🚀 Project Velocity (Tasks completed & milestones hit)
   - 🗺 Life Blueprint Alignment (Are this week's actions serving my 10-year vision?)
   - 🎯 Top 3 High-Leverage Strategic Bets for Next Week.`,
            },
          },
        ],
      };
    }
  );
}
