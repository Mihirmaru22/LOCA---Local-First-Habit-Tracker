import { habitsRepo } from "../src/db/habits.js";
import { tasksRepo } from "../src/db/tasks.js";
import { notesRepo } from "../src/db/notes.js";
import { projectsRepo } from "../src/db/projects.js";
import { focusRepo } from "../src/db/focus.js";
import { lifeRepo } from "../src/db/life.js";

async function runTests() {
  console.log("=========================================");
  console.log("🧪 RUNNING LOCA MCP SERVER TEST SUITE");
  console.log("=========================================\n");

  // 1. Test Habits
  console.log("▶ Testing Habits Repository...");
  const habits = habitsRepo.listHabits();
  console.log(`  Found ${habits.length} habits:`, habits.map((h) => h.name));
  if (habits.length > 0) {
    const logRes = habitsRepo.logHabit({ habitId: habits[0].id, value: 1.0, note: "Automated test check-in" });
    console.log(`  Logged habit check-in: Success=${logRes.success}, Streak=${logRes.newStreak}`);
  }

  // 2. Test Tasks
  console.log("\n▶ Testing Tasks Repository...");
  const tasks = tasksRepo.listTasks();
  console.log(`  Found ${tasks.length} tasks.`);
  const newTask = tasksRepo.createTask({
    title: "Test Task via MCP",
    priority: 1,
    category: "Engineering",
    durationMinutes: 45,
  });
  console.log(`  Created task: '${newTask.title}' [${newTask.priorityLabel}] (ID: ${newTask.id})`);

  const compRes = tasksRepo.completeTask(newTask.id, true);
  console.log(`  Completed task: Success=${compRes.success}, isCompleted=${compRes.isCompleted}`);

  // 3. Test Notes
  console.log("\n▶ Testing Notes Repository...");
  const notes = notesRepo.searchNotes({ limit: 5 });
  console.log(`  Found ${notes.length} notes.`);
  const newNote = notesRepo.createNote({
    title: "MCP Integration Architecture",
    bodyText: "# MCP Architecture\n\n- Local-first\n- TypeScript v2 SDK\n- Zero cloud",
    tags: ["#mcp", "#architecture"],
    isPinned: true,
  });
  console.log(`  Created note: '${newNote.title}' (ID: ${newNote.id})`);

  // 4. Test Projects
  console.log("\n▶ Testing Projects Repository...");
  const projects = projectsRepo.listProjects();
  console.log(`  Found ${projects.length} projects.`);

  // 5. Test Focus
  console.log("\n▶ Testing Focus Repository...");
  const focusStats = focusRepo.getFocusStats(7);
  console.log(`  Focus stats: ${focusStats.totalMinutes} minutes across ${focusStats.totalSessions} sessions.`);

  // 6. Test Life Atlas & Blueprint
  console.log("\n▶ Testing Life & Blueprint Repository...");
  const treks = lifeRepo.listTreks();
  console.log(`  Found ${treks.length} treks/summits in Atlas.`);
  const blueprint = lifeRepo.getLifeBlueprint();
  console.log(`  Blueprint contains ${blueprint.totalGoals} goals across ${Object.keys(blueprint.categories).length} categories.`);

  console.log("\n=========================================");
  console.log("✅ ALL LOCA MCP SERVER TESTS PASSED!");
  console.log("=========================================");
}

runTests().catch((err) => {
  console.error("❌ Test failed:", err);
  process.exit(1);
});
