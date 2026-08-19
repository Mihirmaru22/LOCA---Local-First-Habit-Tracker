import crypto from "node:crypto";
import { dbAdapter } from "./adapter.js";

export interface FocusStatsRecord {
  totalMinutes: number;
  totalSessions: number;
  completedGoalsCount: number;
  categoryBreakdown: Record<string, number>;
  recentSessions: Array<{
    id: string;
    sessionTag: string;
    category: string;
    durationMinutes: number;
    startTime: string;
  }>;
}

export class FocusRepository {
  public getFocusStats(days: number = 7): FocusStatsRecord {
    const sinceDate = new Date();
    sinceDate.setDate(sinceDate.getDate() - days);
    const sinceCD = dbAdapter.dateToCoreData(sinceDate);

    const sessions = dbAdapter.queryAll<any>(
      `SELECT 
        ZID as id,
        COALESCE(ZSESSIONTAG, 'Focus') as sessionTag,
        COALESCE(ZBACKGROUNDCATEGORY, 'City') as category,
        COALESCE(ZDURATIONSECONDS, 0) as durationSeconds,
        ZSTARTTIME as startTime
       FROM ZFOCUSSESSION
       WHERE ZSTARTTIME >= ?
       ORDER BY ZSTARTTIME DESC`,
      [sinceCD]
    );

    let totalSeconds = 0;
    const categoryBreakdown: Record<string, number> = {};

    const recentSessions = sessions.map((s) => {
      const durSec = Number(s.durationSeconds) || 0;
      totalSeconds += durSec;
      const cat = s.category || "General";
      categoryBreakdown[cat] = (categoryBreakdown[cat] ?? 0) + Math.round(durSec / 60);

      return {
        id: dbAdapter.formatUUID(s.id),
        sessionTag: s.sessionTag,
        category: cat,
        durationMinutes: Math.round(durSec / 60),
        startTime: dbAdapter.formatISO(dbAdapter.coreDataToDate(s.startTime)) || new Date().toISOString(),
      };
    });

    const goals = dbAdapter.queryAll<{ count: number }>(
      `SELECT count(*) as count FROM ZFOCUSGOAL WHERE ZISCOMPLETED = 1 AND ZCREATEDAT >= ?`,
      [sinceCD]
    );

    return {
      totalMinutes: Math.round(totalSeconds / 60),
      totalSessions: sessions.length,
      completedGoalsCount: goals[0]?.count ?? 0,
      categoryBreakdown,
      recentSessions: recentSessions.slice(0, 10),
    };
  }

  public logFocusSession(params: {
    durationSeconds: number;
    sessionTag?: string;
    category?: string;
    goals?: string[];
  }): { id: string; durationMinutes: number } {
    const id = crypto.randomUUID();
    const nowCD = dbAdapter.dateToCoreData(new Date());

    dbAdapter.execute(
      `INSERT INTO ZFOCUSSESSION (
        ZID, ZSESSIONTAG, ZBACKGROUNDCATEGORY, ZDURATIONSECONDS, ZSTARTTIME
      ) VALUES (?, ?, ?, ?, ?)`,
      [id, params.sessionTag ?? "Deep Work", params.category ?? "Study", params.durationSeconds, nowCD]
    );

    if (params.goals && params.goals.length > 0) {
      for (const goalTitle of params.goals) {
        const goalId = crypto.randomUUID();
        dbAdapter.execute(
          `INSERT INTO ZFOCUSGOAL (ZID, ZSESSIONID, ZTITLE, ZISCOMPLETED, ZCREATEDAT)
           VALUES (?, ?, ?, 1, ?)`,
          [goalId, id, goalTitle, nowCD]
        );
      }
    }

    return { id, durationMinutes: Math.round(params.durationSeconds / 60) };
  }
}

export const focusRepo = new FocusRepository();
