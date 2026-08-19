import crypto from "node:crypto";
import { dbAdapter } from "./adapter.js";

export interface HabitRecord {
  id: string;
  name: string;
  metricType: "binary" | "quantitative";
  targetValue: number;
  unitLabel: string;
  emoji: string;
  dimension: string | null;
  currentStreak: number;
  bestStreak: number;
  todayCompleted: boolean;
  todayLoggedValue: number;
}

export interface HabitLogRecord {
  id: string;
  habitId: string;
  timestamp: string;
  value: number;
  note: string | null;
}

export class HabitsRepository {
  /** Lists all active habits with live streak calculation */
  public listHabits(options: { activeOnly?: boolean } = {}): HabitRecord[] {
    const { activeOnly = true } = options;
    const sql = `
      SELECT 
        ZID as id,
        ZNAME as name,
        ZMETRICTYPE as metricType,
        COALESCE(ZTARGETVALUE, 1.0) as targetValue,
        COALESCE(ZUNITLABEL, 'check') as unitLabel,
        COALESCE(ZEMOJI, '⚡️') as emoji,
        ZDIMENSION as dimension,
        ZARCHIVEDAT as archivedAt
      FROM ZHABITBOARD
      WHERE ${activeOnly ? "ZARCHIVEDAT IS NULL" : "1=1"}
      ORDER BY Z_PK ASC
    `;

    const rows = dbAdapter.queryAll<any>(sql);
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayCoreData = dbAdapter.dateToCoreData(todayStart);

    return rows.map((row) => {
      const habitId = dbAdapter.formatUUID(row.id);

      // Query today's logs for this habit
      const todayLogs = dbAdapter.queryAll<{ value: number }>(
        `SELECT ZVALUE as value FROM ZLOGENTRY 
         WHERE ZBOARDID = ? AND ZTIMESTAMP >= ? AND ZARCHIVEDAT IS NULL`,
        [habitId, todayCoreData]
      );

      const todayLoggedValue = todayLogs.reduce((acc, log) => acc + (log.value ?? 1.0), 0);
      const isQuantitative = row.metricType === 1;
      const targetValue = Number(row.targetValue) || 1.0;
      const todayCompleted = todayLoggedValue >= targetValue;

      // Compute streak metrics
      const streakMetrics = this.computeStreak(habitId, targetValue);

      return {
        id: habitId,
        name: row.name || "Untitled Habit",
        metricType: isQuantitative ? "quantitative" : "binary",
        targetValue,
        unitLabel: row.unitLabel || "check",
        emoji: row.emoji || "⚡️",
        dimension: row.dimension || null,
        currentStreak: streakMetrics.currentStreak,
        bestStreak: streakMetrics.bestStreak,
        todayCompleted,
        todayLoggedValue,
      };
    });
  }

  /** Logs a check-in or quantitative entry */
  public logHabit(params: {
    habitId: string;
    value?: number;
    note?: string;
    date?: string | Date;
  }): { success: boolean; logId: string; newStreak: number } {
    const { habitId, value = 1.0, note = null, date } = params;
    const logId = crypto.randomUUID();
    const timestamp = dbAdapter.dateToCoreData(date ? new Date(date) : new Date());

    dbAdapter.execute(
      `INSERT INTO ZLOGENTRY (ZID, ZBOARDID, ZTIMESTAMP, ZVALUE, ZNOTE)
       VALUES (?, ?, ?, ?, ?)`,
      [logId, habitId, timestamp, value, note]
    );

    const habit = dbAdapter.queryOne<{ targetValue: number }>(
      `SELECT COALESCE(ZTARGETVALUE, 1.0) as targetValue FROM ZHABITBOARD WHERE ZID = ?`,
      [habitId]
    );

    const streak = this.computeStreak(habitId, habit?.targetValue ?? 1.0);
    return { success: true, logId, newStreak: streak.currentStreak };
  }

  /** Creates a new habit */
  public createHabit(params: {
    name: string;
    metricType?: "binary" | "quantitative";
    targetValue?: number;
    unitLabel?: string;
    emoji?: string;
    dimension?: string;
  }): { id: string; name: string } {
    const id = crypto.randomUUID();
    const isQuantitative = params.metricType === "quantitative";
    const metricTypeInt = isQuantitative ? 1 : 0;
    const targetValue = isQuantitative ? (params.targetValue ?? 1.0) : 1.0;
    const unitLabel = params.unitLabel ?? (isQuantitative ? "units" : "check");
    const emoji = params.emoji ?? "⚡️";
    const dimension = params.dimension ?? null;

    dbAdapter.execute(
      `INSERT INTO ZHABITBOARD (ZID, ZNAME, ZMETRICTYPE, ZTARGETVALUE, ZUNITLABEL, ZEMOJI, ZDIMENSION)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [id, params.name, metricTypeInt, targetValue, unitLabel, emoji, dimension]
    );

    return { id, name: params.name };
  }

  /** Computes current & best consecutive day streak */
  private computeStreak(habitId: string, targetValue: number): { currentStreak: number; bestStreak: number } {
    const logs = dbAdapter.queryAll<{ timestamp: number; value: number }>(
      `SELECT ZTIMESTAMP as timestamp, ZVALUE as value FROM ZLOGENTRY 
       WHERE ZBOARDID = ? AND ZARCHIVEDAT IS NULL
       ORDER BY ZTIMESTAMP DESC`,
      [habitId]
    );

    if (logs.length === 0) {
      return { currentStreak: 0, bestStreak: 0 };
    }

    // Group values by date string YYYY-MM-DD
    const dayTotals = new Map<string, number>();
    for (const log of logs) {
      const date = dbAdapter.coreDataToDate(log.timestamp);
      if (date) {
        const key = date.toISOString().split("T")[0];
        dayTotals.set(key, (dayTotals.get(key) ?? 0) + (log.value || 1.0));
      }
    }

    // Check consecutive days starting from today or yesterday
    const now = new Date();
    const todayStr = now.toISOString().split("T")[0];
    const yesterday = new Date(now.getTime() - 86400000);
    const yesterdayStr = yesterday.toISOString().split("T")[0];

    let currentStreak = 0;
    let checkDate = new Date(now);

    // If today is not completed yet, check if streak is alive from yesterday
    const todayDone = (dayTotals.get(todayStr) ?? 0) >= targetValue;
    if (!todayDone) {
      const yesterdayDone = (dayTotals.get(yesterdayStr) ?? 0) >= targetValue;
      if (!yesterdayDone) {
        return { currentStreak: 0, bestStreak: this.calculateBestStreak(dayTotals, targetValue) };
      }
      checkDate = yesterday;
    }

    while (true) {
      const dateStr = checkDate.toISOString().split("T")[0];
      const val = dayTotals.get(dateStr) ?? 0;
      if (val >= targetValue) {
        currentStreak++;
        checkDate = new Date(checkDate.getTime() - 86400000);
      } else {
        break;
      }
    }

    const bestStreak = Math.max(currentStreak, this.calculateBestStreak(dayTotals, targetValue));
    return { currentStreak, bestStreak };
  }

  private calculateBestStreak(dayTotals: Map<string, number>, targetValue: number): number {
    const dates = Array.from(dayTotals.keys()).sort();
    let max = 0;
    let current = 0;
    let prevDate: Date | null = null;

    for (const dStr of dates) {
      const d = new Date(dStr);
      const val = dayTotals.get(dStr) ?? 0;
      if (val >= targetValue) {
        if (prevDate && d.getTime() - prevDate.getTime() === 86400000) {
          current++;
        } else {
          current = 1;
        }
        max = Math.max(max, current);
        prevDate = d;
      }
    }
    return max;
  }
}

export const habitsRepo = new HabitsRepository();
