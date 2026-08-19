import crypto from "node:crypto";
import { dbAdapter } from "./adapter.js";

export interface ProjectRecord {
  id: string;
  title: string;
  description: string | null;
  colorHex: string;
  iconName: string;
  isFavorite: boolean;
  totalTasks: number;
  completedTasks: number;
  progressPercent: number;
  createdAt: string;
}

export class ProjectsRepository {
  public listProjects(options: { activeOnly?: boolean } = {}): ProjectRecord[] {
    const { activeOnly = true } = options;
    const sql = `
      SELECT 
        ZID as id,
        ZTITLE as title,
        ZPROJECTDESCRIPTION as description,
        COALESCE(ZCOLORHEX, '#6366F1') as colorHex,
        COALESCE(ZICONNAME, 'folder') as iconName,
        COALESCE(ZISFAVORITE, 0) as isFavorite,
        ZCREATEDAT as createdAt
      FROM ZWORKPROJECT
      WHERE ${activeOnly ? "ZISARCHIVED = 0" : "1=1"}
      ORDER BY ZISFAVORITE DESC, ZORDERINDEX ASC, ZCREATEDAT DESC
    `;

    const rows = dbAdapter.queryAll<any>(sql);

    return rows.map((row) => {
      const pId = dbAdapter.formatUUID(row.id);
      const tasks = dbAdapter.queryAll<{ completedAt: number | null }>(
        `SELECT ZCOMPLETEDAT as completedAt FROM ZTODOITEM WHERE ZPROJECTID = ? AND ZARCHIVEDAT IS NULL`,
        [pId]
      );

      const totalTasks = tasks.length;
      const completedTasks = tasks.filter((t) => t.completedAt !== null).length;
      const progressPercent = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;

      return {
        id: pId,
        title: row.title || "Untitled Project",
        description: row.description || null,
        colorHex: row.colorHex,
        iconName: row.iconName,
        isFavorite: row.isFavorite === 1,
        totalTasks,
        completedTasks,
        progressPercent,
        createdAt: dbAdapter.formatISO(dbAdapter.coreDataToDate(row.createdAt)) || new Date().toISOString(),
      };
    });
  }

  public createProject(params: {
    title: string;
    description?: string;
    colorHex?: string;
    iconName?: string;
    isFavorite?: boolean;
    initialTasks?: string[];
  }): ProjectRecord {
    const id = crypto.randomUUID();
    const nowCD = dbAdapter.dateToCoreData(new Date());

    dbAdapter.execute(
      `INSERT INTO ZWORKPROJECT (
        ZID, ZTITLE, ZPROJECTDESCRIPTION, ZCOLORHEX, ZICONNAME, ZISFAVORITE, ZCREATEDAT
      ) VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        id,
        params.title,
        params.description ?? null,
        params.colorHex ?? "#6366F1",
        params.iconName ?? "folder",
        params.isFavorite ? 1 : 0,
        nowCD,
      ]
    );

    if (params.initialTasks && params.initialTasks.length > 0) {
      for (const taskTitle of params.initialTasks) {
        const taskId = crypto.randomUUID();
        dbAdapter.execute(
          `INSERT INTO ZTODOITEM (ZID, ZTITLE, ZPROJECTID, ZCREATEDAT) VALUES (?, ?, ?, ?)`,
          [taskId, taskTitle, id, nowCD]
        );
      }
    }

    const projects = this.listProjects({ activeOnly: false });
    return projects.find((p) => p.id === id)!;
  }
}

export const projectsRepo = new ProjectsRepository();
