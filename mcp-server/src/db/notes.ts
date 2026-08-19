import crypto from "node:crypto";
import { dbAdapter } from "./adapter.js";

export interface NoteRecord {
  id: string;
  title: string;
  bodyText: string;
  snippet: string;
  tags: string[];
  isPinned: boolean;
  isFavorite: boolean;
  isLocked: boolean;
  folderId: string | null;
  hasChecklist: boolean;
  hasTable: boolean;
  checklistItems: Array<{ text: string; isChecked: boolean }>;
  tableData: any | null;
  createdAt: string;
  updatedAt: string;
}

export class NotesRepository {
  /** Searches notes with full-text search, tags, or folder filter */
  public searchNotes(options: {
    query?: string;
    tag?: string;
    folderId?: string;
    isFavorite?: boolean;
    isPinned?: boolean;
    limit?: number;
  } = {}): NoteRecord[] {
    const { query, tag, folderId, isFavorite, isPinned, limit = 50 } = options;

    let whereClauses: string[] = ["(ZDELETEDAT IS NULL AND ZISARCHIVED = 0)"];
    const params: any[] = [];

    if (query) {
      whereClauses.push("(ZTITLE LIKE ? OR ZBODYTEXT LIKE ?)");
      params.push(`%${query}%`, `%${query}%`);
    }

    if (tag) {
      whereClauses.push("ZTAGS LIKE ?");
      params.push(`%${tag}%`);
    }

    if (folderId) {
      whereClauses.push("ZFOLDERID = ?");
      params.push(folderId);
    }

    if (isFavorite !== undefined) {
      whereClauses.push("ZISFAVORITE = ?");
      params.push(isFavorite ? 1 : 0);
    }

    if (isPinned !== undefined) {
      whereClauses.push("ZISPINNED = ?");
      params.push(isPinned ? 1 : 0);
    }

    const sql = `
      SELECT 
        ZID as id,
        ZTITLE as title,
        ZBODYTEXT as bodyText,
        ZTAGS as tagsJSON,
        COALESCE(ZISPINNED, 0) as isPinned,
        COALESCE(ZISFAVORITE, 0) as isFavorite,
        COALESCE(ZISLOCKED, 0) as isLocked,
        ZFOLDERID as folderId,
        COALESCE(ZHASCHECKLIST, 0) as hasChecklist,
        COALESCE(ZHASTABLE, 0) as hasTable,
        ZCHECKLISTITEMSJSON as checklistJSON,
        ZTABLEDATAJSON as tableJSON,
        ZCREATEDAT as createdAt,
        ZUPDATEDAT as updatedAt
      FROM ZBRAINSTORMNOTE
      WHERE ${whereClauses.join(" AND ")}
      ORDER BY ZISPINNED DESC, ZUPDATEDAT DESC, ZCREATEDAT DESC
      LIMIT ?
    `;
    params.push(limit);

    const rows = dbAdapter.queryAll<any>(sql, params);

    return rows.map((row) => this.mapNoteRow(row));
  }

  /** Gets a single note by ID with full text and structured payload */
  public getNote(id: string): NoteRecord | null {
    const row = dbAdapter.queryOne<any>(
      `SELECT 
        ZID as id,
        ZTITLE as title,
        ZBODYTEXT as bodyText,
        ZTAGS as tagsJSON,
        COALESCE(ZISPINNED, 0) as isPinned,
        COALESCE(ZISFAVORITE, 0) as isFavorite,
        COALESCE(ZISLOCKED, 0) as isLocked,
        ZFOLDERID as folderId,
        COALESCE(ZHASCHECKLIST, 0) as hasChecklist,
        COALESCE(ZHASTABLE, 0) as hasTable,
        ZCHECKLISTITEMSJSON as checklistJSON,
        ZTABLEDATAJSON as tableJSON,
        ZCREATEDAT as createdAt,
        ZUPDATEDAT as updatedAt
      FROM ZBRAINSTORMNOTE
      WHERE ZID = ? AND ZDELETEDAT IS NULL`,
      [id]
    );

    return row ? this.mapNoteRow(row) : null;
  }

  /** Creates a new note */
  public createNote(params: {
    title: string;
    bodyText: string;
    tags?: string[];
    folderId?: string;
    isPinned?: boolean;
    isFavorite?: boolean;
  }): NoteRecord {
    const id = crypto.randomUUID();
    const nowCD = dbAdapter.dateToCoreData(new Date());
    const tagsJSON = JSON.stringify(params.tags ?? []);
    const isPinned = params.isPinned ? 1 : 0;
    const isFavorite = params.isFavorite ? 1 : 0;

    dbAdapter.execute(
      `INSERT INTO ZBRAINSTORMNOTE (
        ZID, ZTITLE, ZBODYTEXT, ZTAGS, ZFOLDERID, ZISPINNED, ZISFAVORITE, ZCREATEDAT, ZUPDATEDAT
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [id, params.title, params.bodyText, tagsJSON, params.folderId ?? null, isPinned, isFavorite, nowCD, nowCD]
    );

    return this.getNote(id)!;
  }

  /** Updates an existing note */
  public updateNote(params: {
    id: string;
    title?: string;
    bodyText?: string;
    appendText?: string;
    tags?: string[];
    isPinned?: boolean;
    isFavorite?: boolean;
  }): NoteRecord | null {
    const existing = this.getNote(params.id);
    if (!existing) return null;

    let finalBody = params.bodyText ?? existing.bodyText;
    if (params.appendText) {
      finalBody = `${finalBody}\n\n${params.appendText}`;
    }

    const finalTitle = params.title ?? existing.title;
    const finalTags = params.tags ? JSON.stringify(params.tags) : JSON.stringify(existing.tags);
    const isPinned = params.isPinned !== undefined ? (params.isPinned ? 1 : 0) : (existing.isPinned ? 1 : 0);
    const isFavorite = params.isFavorite !== undefined ? (params.isFavorite ? 1 : 0) : (existing.isFavorite ? 1 : 0);
    const nowCD = dbAdapter.dateToCoreData(new Date());

    dbAdapter.execute(
      `UPDATE ZBRAINSTORMNOTE 
       SET ZTITLE = ?, ZBODYTEXT = ?, ZTAGS = ?, ZISPINNED = ?, ZISFAVORITE = ?, ZUPDATEDAT = ?
       WHERE ZID = ?`,
      [finalTitle, finalBody, finalTags, isPinned, isFavorite, nowCD, params.id]
    );

    return this.getNote(params.id);
  }

  private mapNoteRow(row: any): NoteRecord {
    const body = row.bodyText || "";
    const cleanSnippet = body
      .replace(/[#*`_~[\]]/g, "")
      .split("\n")
      .map((l: string) => l.trim())
      .filter((l: string) => l.length > 0)
      .slice(0, 3)
      .join(" ");

    const tags: string[] = dbAdapter.parseJSON(row.tagsJSON, []);
    const checklistItems = dbAdapter.parseJSON<Array<{ text: string; isChecked: boolean }>>(row.checklistJSON, []);
    const tableData = dbAdapter.parseJSON<any>(row.tableJSON, null);

    return {
      id: dbAdapter.formatUUID(row.id),
      title: row.title || "Untitled Note",
      bodyText: body,
      snippet: cleanSnippet.slice(0, 180),
      tags,
      isPinned: row.isPinned === 1,
      isFavorite: row.isFavorite === 1,
      isLocked: row.isLocked === 1,
      folderId: row.folderId ? dbAdapter.formatUUID(row.folderId) : null,
      hasChecklist: row.hasChecklist === 1,
      hasTable: row.hasTable === 1,
      checklistItems,
      tableData,
      createdAt: dbAdapter.formatISO(dbAdapter.coreDataToDate(row.createdAt)) || new Date().toISOString(),
      updatedAt: dbAdapter.formatISO(dbAdapter.coreDataToDate(row.updatedAt)) || new Date().toISOString(),
    };
  }
}

export const notesRepo = new NotesRepository();
