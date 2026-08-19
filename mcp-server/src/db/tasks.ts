import crypto from "node:crypto";
import { dbAdapter } from "./adapter.js";

export interface TaskRecord {
  id: string;
  title: string;
  notes: string | null;
  priority: number; // 0 = default, 1 = P1, 2 = P2, 3 = P3, 4 = P4
  priorityLabel: string;
  dueDate: string | null;
  isCompleted: boolean;
  completedAt: string | null;
  createdAt: string;
}

export class TasksRepository {
  /** Lists tasks filtered by priority, bucket, completion */
  public listTasks(options: {
    priority?: number;
    bucket?: "Today" | "Upcoming" | "Anytime";
    completed?: boolean;
  } = {}): TaskRecord[] {
    const { priority, bucket, completed } = options;

    let whereClauses: string[] = ["ZARCHIVEDAT IS NULL"];
    const params: any[] = [];

    if (priority !== undefined) {
      whereClauses.push("ZPRIORITY = ?");
      params.push(priority);
    }

    if (completed !== undefined) {
      if (completed) {
        whereClauses.push("ZCOMPLETEDAT IS NOT NULL");
      } else {
        whereClauses.push("ZCOMPLETEDAT IS NULL");
      }
    }

    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999);

    const todayStartCD = dbAdapter.dateToCoreData(todayStart);
    const todayEndCD = dbAdapter.dateToCoreData(todayEnd);

    if (bucket === "Today") {
      whereClauses.push("((ZDUEDATE >= ? AND ZDUEDATE <= ?) OR (ZDUEDATE IS NULL AND ZPRIORITY = 1))");
      params.push(todayStartCD, todayEndCD);
    } else if (bucket === "Upcoming") {
      whereClauses.push("(ZDUEDATE > ?)");
      params.push(todayEndCD);
    } else if (bucket === "Anytime") {
      whereClauses.push("(ZDUEDATE IS NULL)");
    }

    const sql = `
      SELECT 
        ZID as id,
        ZTITLE as title,
        ZNOTES as notes,
        COALESCE(ZPRIORITY, 0) as priority,
        ZDUEDATE as dueDate,
        ZCOMPLETEDAT as completedAt,
        ZCREATEDAT as createdAt
      FROM ZTODOITEM
      WHERE ${whereClauses.join(" AND ")}
      ORDER BY ZPRIORITY ASC, ZDUEDATE ASC, ZCREATEDAT DESC
    `;

    const rows = dbAdapter.queryAll<any>(sql, params);

    return rows.map((row) => {
      const p = Number(row.priority) || 0;
      const priorityLabel = p === 1 ? "P1 High" : p === 2 ? "P2 Med" : p === 3 ? "P3 Standard" : p === 4 ? "P4 Backlog" : "Standard";
      const isDone = row.completedAt !== null;

      return {
        id: dbAdapter.formatUUID(row.id),
        title: row.title || "Untitled Task",
        notes: row.notes || null,
        priority: p,
        priorityLabel,
        dueDate: dbAdapter.formatISO(dbAdapter.coreDataToDate(row.dueDate)),
        isCompleted: isDone,
        completedAt: dbAdapter.formatISO(dbAdapter.coreDataToDate(row.completedAt)),
        createdAt: dbAdapter.formatISO(dbAdapter.coreDataToDate(row.createdAt)) || new Date().toISOString(),
      };
    });
  }

  /** Creates a new task */
  public createTask(params: {
    title: string;
    priority?: number;
    notes?: string;
    dueDate?: string | Date;
  }): TaskRecord {
    const id = crypto.randomUUID();
    const nowCD = dbAdapter.dateToCoreData(new Date());
    const dueDateCD = params.dueDate ? dbAdapter.dateToCoreData(params.dueDate) : null;
    const priority = params.priority ?? 0;

    dbAdapter.execute(
      `INSERT INTO ZTODOITEM (
        ZID, ZTITLE, ZNOTES, ZPRIORITY, ZDUEDATE, ZCREATEDAT
      ) VALUES (?, ?, ?, ?, ?, ?)`,
      [
        id,
        params.title,
        params.notes ?? null,
        priority,
        dueDateCD,
        nowCD,
      ]
    );

    return this.getTask(id)!;
  }

  /** Gets a single task by ID */
  public getTask(id: string): TaskRecord | null {
    const row = dbAdapter.queryOne<any>(
      `SELECT 
        ZID as id,
        ZTITLE as title,
        ZNOTES as notes,
        COALESCE(ZPRIORITY, 0) as priority,
        ZDUEDATE as dueDate,
        ZCOMPLETEDAT as completedAt,
        ZCREATEDAT as createdAt
      FROM ZTODOITEM WHERE ZID = ?`,
      [id]
    );

    if (!row) return null;
    const p = Number(row.priority) || 0;
    const priorityLabel = p === 1 ? "P1 High" : p === 2 ? "P2 Med" : p === 3 ? "P3 Standard" : p === 4 ? "P4 Backlog" : "Standard";

    return {
      id: dbAdapter.formatUUID(row.id),
      title: row.title || "Untitled Task",
      notes: row.notes || null,
      priority: p,
      priorityLabel,
      dueDate: dbAdapter.formatISO(dbAdapter.coreDataToDate(row.dueDate)),
      isCompleted: row.completedAt !== null,
      completedAt: dbAdapter.formatISO(dbAdapter.coreDataToDate(row.completedAt)),
      createdAt: dbAdapter.formatISO(dbAdapter.coreDataToDate(row.createdAt)) || new Date().toISOString(),
    };
  }

  /** Toggles or sets task completion */
  public completeTask(id: string, completed: boolean = true): { success: boolean; isCompleted: boolean } {
    const completedAtCD = completed ? dbAdapter.dateToCoreData(new Date()) : null;
    dbAdapter.execute(
      `UPDATE ZTODOITEM SET ZCOMPLETEDAT = ? WHERE ZID = ?`,
      [completedAtCD, id]
    );
    return { success: true, isCompleted: completed };
  }

  /** Schedules a task to a specific due date */
  public scheduleDueDate(id: string, dueDate: string | Date): { success: boolean } {
    const dueDateCD = dbAdapter.dateToCoreData(dueDate);
    dbAdapter.execute(
      `UPDATE ZTODOITEM SET ZDUEDATE = ? WHERE ZID = ?`,
      [dueDateCD, id]
    );
    return { success: true };
  }
}

export const tasksRepo = new TasksRepository();
