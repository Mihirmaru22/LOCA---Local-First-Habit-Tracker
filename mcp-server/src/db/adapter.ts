import Database from "better-sqlite3";
import crypto from "node:crypto";
import fs from "node:fs";
import { CONFIG } from "../config.js";

// Core Data epoch offset in seconds (Jan 1, 2001 00:00:00 GMT vs Jan 1, 1970 00:00:00 GMT)
export const COREDATA_EPOCH_OFFSET = 978307200;

export class DatabaseAdapter {
  private db: Database.Database;

  constructor(dbPath: string = CONFIG.dbPath) {
    // Open SQLite database in WAL mode for safe concurrent reading while app is active
    this.db = new Database(dbPath, { timeout: 5000 });
    this.db.pragma("journal_mode = WAL");
    this.db.pragma("foreign_keys = ON");

    // Initialize tables if running in fallback/standalone mode or empty database
    this.ensureSchema();
  }

  // MARK: - Date & Timestamp Converters

  /** Converts a CoreData float timestamp to JavaScript Date */
  public coreDataToDate(timestamp: number | null | undefined): Date | null {
    if (timestamp === null || timestamp === undefined || isNaN(timestamp)) {
      return null;
    }
    return new Date((timestamp + COREDATA_EPOCH_OFFSET) * 1000);
  }

  /** Converts a JavaScript Date or ISO string to CoreData float timestamp */
  public dateToCoreData(date: Date | string | number | null | undefined): number {
    const d = date ? new Date(date) : new Date();
    return d.getTime() / 1000 - COREDATA_EPOCH_OFFSET;
  }

  /** Formats a Date into clean ISO string */
  public formatISO(date: Date | null | undefined): string | null {
    return date ? date.toISOString() : null;
  }

  // MARK: - UUID Converters

  /** Normalizes UUID strings or 16-byte buffer blobs into standard 8-4-4-4-12 string */
  public formatUUID(raw: any): string {
    if (!raw) return crypto.randomUUID();
    if (typeof raw === "string") return raw;
    if (Buffer.isBuffer(raw) && raw.length === 16) {
      const hex = raw.toString("hex");
      return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
    }
    return String(raw);
  }

  /** Parses JSON payloads safely */
  public parseJSON<T>(raw: string | null | undefined, fallback: T): T {
    if (!raw || typeof raw !== "string") return fallback;
    try {
      return JSON.parse(raw);
    } catch {
      return fallback;
    }
  }

  // MARK: - Query Wrappers

  public queryAll<T = any>(sql: string, params: any[] = []): T[] {
    const stmt = this.db.prepare(sql);
    return stmt.all(...params) as T[];
  }

  public queryOne<T = any>(sql: string, params: any[] = []): T | null {
    const stmt = this.db.prepare(sql);
    return (stmt.get(...params) as T) || null;
  }

  public execute(sql: string, params: any[] = []): Database.RunResult {
    const stmt = this.db.prepare(sql);
    return stmt.run(...params);
  }

  public transaction<T>(fn: () => T): T {
    return this.db.transaction(fn)();
  }

  public hasTable(tableName: string): boolean {
    const row = this.queryOne<{ count: number }>(
      "SELECT count(*) as count FROM sqlite_master WHERE type='table' AND (name = ? OR name = ?)",
      [tableName, `Z${tableName.toUpperCase()}`]
    );
    return (row?.count ?? 0) > 0;
  }

  public close(): void {
    this.db.close();
  }

  // MARK: - Schema Initialization (For Standalone Dev / Fallback Mode)

  private ensureSchema(): void {
    // Check if SwiftData tables exist; if not, create clean schemas matching RippleSchemaV1
    const tablesSql = `
      CREATE TABLE IF NOT EXISTS ZHABITBOARD (
        Z_PK INTEGER PRIMARY KEY AUTOINCREMENT,
        Z_ENT INTEGER DEFAULT 1,
        Z_OPT INTEGER DEFAULT 1,
        ZID VARCHAR(64) UNIQUE,
        ZNAME VARCHAR(255),
        ZMETRICTYPE INTEGER DEFAULT 0,
        ZTARGETVALUE FLOAT,
        ZUNITLABEL VARCHAR(64),
        ZCOLORINDEX INTEGER DEFAULT 0,
        ZUSECOLORBACKGROUND INTEGER DEFAULT 0,
        ZEMOJI VARCHAR(32),
        ZDIMENSION VARCHAR(64),
        ZHABITKINDRAW INTEGER DEFAULT 0,
        ZARCHIVEDAT FLOAT
      );

      CREATE TABLE IF NOT EXISTS ZLOGENTRY (
        Z_PK INTEGER PRIMARY KEY AUTOINCREMENT,
        Z_ENT INTEGER DEFAULT 2,
        Z_OPT INTEGER DEFAULT 1,
        ZID VARCHAR(64) UNIQUE,
        ZBOARDID VARCHAR(64),
        ZTIMESTAMP FLOAT,
        ZVALUE FLOAT DEFAULT 1.0,
        ZNOTE TEXT,
        ZARCHIVEDAT FLOAT
      );

      CREATE TABLE IF NOT EXISTS ZTODOITEM (
        Z_PK INTEGER PRIMARY KEY AUTOINCREMENT,
        Z_ENT INTEGER DEFAULT 3,
        Z_OPT INTEGER DEFAULT 1,
        ZID VARCHAR(64) UNIQUE,
        ZTITLE VARCHAR(255),
        ZNOTES TEXT,
        ZPRIORITY INTEGER DEFAULT 0,
        ZCATEGORY VARCHAR(64),
        ZDUEDATE FLOAT,
        ZSTARTTIME FLOAT,
        ZDURATIONMINUTES INTEGER DEFAULT 0,
        ZICONNAME VARCHAR(64),
        ZPROJECTID VARCHAR(64),
        ZSECTIONID VARCHAR(64),
        ZPARENTID VARCHAR(64),
        ZCREATEDAT FLOAT,
        ZCOMPLETEDAT FLOAT,
        ZARCHIVEDAT FLOAT
      );

      CREATE TABLE IF NOT EXISTS ZBRAINSTORMNOTE (
        Z_PK INTEGER PRIMARY KEY AUTOINCREMENT,
        Z_ENT INTEGER DEFAULT 4,
        Z_OPT INTEGER DEFAULT 1,
        ZID VARCHAR(64) UNIQUE,
        ZTITLE VARCHAR(255),
        ZBODYTEXT TEXT,
        ZISPINNED INTEGER DEFAULT 0,
        ZISFAVORITE INTEGER DEFAULT 0,
        ZISLOCKED INTEGER DEFAULT 0,
        ZISARCHIVED INTEGER DEFAULT 0,
        ZDELETEDAT FLOAT,
        ZFOLDERID VARCHAR(64),
        ZTAGS TEXT,
        ZHASCHECKLIST INTEGER DEFAULT 0,
        ZHASATTACHMENTS INTEGER DEFAULT 0,
        ZHASTABLE INTEGER DEFAULT 0,
        ZTABLEDATAJSON TEXT,
        ZCHECKLISTITEMSJSON TEXT,
        ZATTACHMENTSJSON TEXT,
        ZCREATEDAT FLOAT,
        ZUPDATEDAT FLOAT
      );

      CREATE TABLE IF NOT EXISTS ZBRAINSTORMFOLDER (
        Z_PK INTEGER PRIMARY KEY AUTOINCREMENT,
        Z_ENT INTEGER DEFAULT 5,
        Z_OPT INTEGER DEFAULT 1,
        ZID VARCHAR(64) UNIQUE,
        ZNAME VARCHAR(255),
        ZICONNAME VARCHAR(64),
        ZCOLORHEX VARCHAR(32),
        ZPARENTFOLDERID VARCHAR(64),
        ZORDERINDEX INTEGER DEFAULT 0,
        ZCREATEDAT FLOAT
      );

      CREATE TABLE IF NOT EXISTS ZWORKPROJECT (
        Z_PK INTEGER PRIMARY KEY AUTOINCREMENT,
        Z_ENT INTEGER DEFAULT 6,
        Z_OPT INTEGER DEFAULT 1,
        ZID VARCHAR(64) UNIQUE,
        ZTITLE VARCHAR(255),
        ZPROJECTDESCRIPTION TEXT,
        ZCOLORHEX VARCHAR(32),
        ZICONNAME VARCHAR(64),
        ZISFAVORITE INTEGER DEFAULT 0,
        ZISARCHIVED INTEGER DEFAULT 0,
        ZORDERINDEX INTEGER DEFAULT 0,
        ZCREATEDAT FLOAT
      );

      CREATE TABLE IF NOT EXISTS ZFOCUSSESSION (
        Z_PK INTEGER PRIMARY KEY AUTOINCREMENT,
        Z_ENT INTEGER DEFAULT 7,
        Z_OPT INTEGER DEFAULT 1,
        ZID VARCHAR(64) UNIQUE,
        ZSESSIONTAG VARCHAR(64),
        ZBACKGROUNDCATEGORY VARCHAR(64),
        ZDURATIONSECONDS INTEGER DEFAULT 0,
        ZSTARTTIME FLOAT,
        ZENDTIME FLOAT
      );

      CREATE TABLE IF NOT EXISTS ZFOCUSGOAL (
        Z_PK INTEGER PRIMARY KEY AUTOINCREMENT,
        Z_ENT INTEGER DEFAULT 8,
        Z_OPT INTEGER DEFAULT 1,
        ZID VARCHAR(64) UNIQUE,
        ZSESSIONID VARCHAR(64),
        ZTITLE VARCHAR(255),
        ZISCOMPLETED INTEGER DEFAULT 0,
        ZCREATEDAT FLOAT,
        ZSESSIONDATE FLOAT
      );

      CREATE TABLE IF NOT EXISTS ZTREKRECORD (
        Z_PK INTEGER PRIMARY KEY AUTOINCREMENT,
        Z_ENT INTEGER DEFAULT 9,
        Z_OPT INTEGER DEFAULT 1,
        ZID VARCHAR(64) UNIQUE,
        ZNAME VARCHAR(255),
        ZREGION VARCHAR(128),
        ZCOUNTRY VARCHAR(128),
        ZLATITUDE FLOAT DEFAULT 0.0,
        ZLONGITUDE FLOAT DEFAULT 0.0,
        ZELEVATIONMETERS FLOAT DEFAULT 0.0,
        ZTRAILDISTANCEKM FLOAT,
        ZELEVATIONGAINMETERS FLOAT,
        ZSTATUSRAW INTEGER DEFAULT 0,
        ZDIFFICULTYRAW INTEGER DEFAULT 1,
        ZRATING INTEGER DEFAULT 5,
        ZPERSONALNOTES TEXT,
        ZDATECONQUERED FLOAT,
        ZCREATEDAT FLOAT,
        ZARCHIVEDAT FLOAT
      );

      CREATE TABLE IF NOT EXISTS ZLIFEBLUEPRINT (
        Z_PK INTEGER PRIMARY KEY AUTOINCREMENT,
        Z_ENT INTEGER DEFAULT 10,
        Z_OPT INTEGER DEFAULT 1,
        ZID VARCHAR(64) UNIQUE,
        ZCATEGORY VARCHAR(64),
        ZTITLE VARCHAR(255),
        ZTARGETYEAR INTEGER,
        ZISACHIEVED INTEGER DEFAULT 0,
        ZMANIFESTONOTES TEXT,
        ZCREATEDAT FLOAT
      );
    `;

    this.db.exec(tablesSql);

    // If standalone fallback database is fresh, seed starter records
    if (CONFIG.isFallback) {
      const count = this.queryOne<{ count: number }>("SELECT count(*) as count FROM ZHABITBOARD");
      if (count?.count === 0) {
        this.seedInitialDevData();
      }
    }
  }

  private seedInitialDevData(): void {
    const now = this.dateToCoreData(new Date());

    // 1. Starter Habits
    this.execute(`
      INSERT INTO ZHABITBOARD (ZID, ZNAME, ZMETRICTYPE, ZTARGETVALUE, ZUNITLABEL, ZCOLORINDEX, ZEMOJI, ZDIMENSION, ZHABITKINDRAW)
      VALUES 
        (?, 'Morning Deep Work', 1, 90, 'mins', 0, '⚡️', 'focus', 0),
        (?, 'Hydration & Water', 1, 3.0, 'liters', 2, '💧', 'energy', 0),
        (?, 'Evening Reflection', 0, 1.0, 'check', 4, '📖', 'mood', 0);
    `, [crypto.randomUUID(), crypto.randomUUID(), crypto.randomUUID()]);

    // 2. Starter Tasks
    this.execute(`
      INSERT INTO ZTODOITEM (ZID, ZTITLE, ZPRIORITY, ZCATEGORY, ZDURATIONMINUTES, ZCREATEDAT)
      VALUES
        (?, 'Finalize LOCA MCP Server Architecture', 1, 'Engineering', 45, ?),
        (?, 'Review Q3 Milestone Deliverables', 2, 'Strategy', 30, ?),
        (?, 'Sync Mountain Trek Logs to Satellite Atlas', 3, 'Life', 20, ?);
    `, [crypto.randomUUID(), now, crypto.randomUUID(), now, crypto.randomUUID(), now]);

    // 3. Starter BrainStorm Note
    this.execute(`
      INSERT INTO ZBRAINSTORMNOTE (ZID, ZTITLE, ZBODYTEXT, ZTAGS, ZISPINNED, ZCREATEDAT, ZUPDATEDAT)
      VALUES
        (?, 'Loca System Architecture & Sovereignty', '# Loca & Pluto System Architecture\n\n- Local-first SwiftData storage\n- 120 FPS native AppKit canvas\n- Zero-cloud offline sovereignty\n- Model Context Protocol (MCP) AI bridge', '["#architecture", "#sovereignty"]', 1, ?, ?);
    `, [crypto.randomUUID(), now, now]);

    // 4. Starter Trek Record
    this.execute(`
      INSERT INTO ZTREKRECORD (ZID, ZNAME, ZREGION, ZCOUNTRY, ZLATITUDE, ZLONGITUDE, ZELEVATIONMETERS, ZSTATUSRAW, ZCREATEDAT)
      VALUES
        (?, 'Mount Rainier Summit', 'Washington', 'United States', 46.8523, -121.7603, 4392.0, 1, ?);
    `, [crypto.randomUUID(), now]);

    // 5. Starter Blueprint Goals
    this.execute(`
      INSERT INTO ZLIFEBLUEPRINT (ZID, ZCATEGORY, ZTITLE, ZTARGETYEAR, ZMANIFESTONOTES, ZCREATEDAT)
      VALUES
        (?, 'Mastery', 'Build the fastest, most sovereign local-first personal OS', 2027, 'Zero compromise on speed, aesthetics, or privacy.', ?),
        (?, 'Adventure', 'Conquer 10 iconic mountain summits across 4 continents', 2030, 'Track all GPS elevation contours and passport stamps in Atlas.', ?);
    `, [crypto.randomUUID(), now, crypto.randomUUID(), now]);
  }
}

export const dbAdapter = new DatabaseAdapter();
