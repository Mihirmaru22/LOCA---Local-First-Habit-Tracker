import crypto from "node:crypto";
import { dbAdapter } from "./adapter.js";

export interface TrekRecordItem {
  id: string;
  name: string;
  region: string;
  country: string;
  latitude: number;
  longitude: number;
  elevationMeters: number;
  trailDistanceKm: number | null;
  elevationGainMeters: number | null;
  status: "wishlist" | "conquered" | "inProgress";
  rating: number;
  personalNotes: string | null;
  dateConquered: string | null;
}

export interface LifeBlueprintItem {
  id: string;
  category: "Adventure" | "Mastery" | "Freedom" | "Principles";
  title: string;
  targetYear: number | null;
  isAchieved: boolean;
  manifestoNotes: string | null;
}

export class LifeRepository {
  public listTreks(options: { status?: "wishlist" | "conquered" | "inProgress" } = {}): TrekRecordItem[] {
    const statusMap = { wishlist: 0, conquered: 1, inProgress: 2 };
    let whereClause = "ZARCHIVEDAT IS NULL";
    const params: any[] = [];

    if (options.status !== undefined) {
      whereClause += " AND ZSTATUSRAW = ?";
      params.push(statusMap[options.status]);
    }

    const sql = `
      SELECT 
        ZID as id,
        ZNAME as name,
        COALESCE(ZREGION, '') as region,
        COALESCE(ZCOUNTRY, '') as country,
        COALESCE(ZLATITUDE, 0.0) as latitude,
        COALESCE(ZLONGITUDE, 0.0) as longitude,
        COALESCE(ZELEVATIONMETERS, 0.0) as elevationMeters,
        ZTRAILDISTANCEKM as trailDistanceKm,
        ZELEVATIONGAINMETERS as elevationGainMeters,
        COALESCE(ZSTATUSRAW, 1) as statusRaw,
        COALESCE(ZRATING, 5) as rating,
        ZPERSONALNOTES as personalNotes,
        ZDATECONQUERED as dateConquered
      FROM ZTREKRECORD
      WHERE ${whereClause}
      ORDER BY ZELEVATIONMETERS DESC
    `;

    const rows = dbAdapter.queryAll<any>(sql, params);

    return rows.map((row) => {
      const sRaw = Number(row.statusRaw);
      const status: "wishlist" | "conquered" | "inProgress" =
        sRaw === 0 ? "wishlist" : sRaw === 2 ? "inProgress" : "conquered";

      return {
        id: dbAdapter.formatUUID(row.id),
        name: row.name || "Unnamed Peak",
        region: row.region,
        country: row.country,
        latitude: Number(row.latitude) || 0.0,
        longitude: Number(row.longitude) || 0.0,
        elevationMeters: Number(row.elevationMeters) || 0.0,
        trailDistanceKm: row.trailDistanceKm ? Number(row.trailDistanceKm) : null,
        elevationGainMeters: row.elevationGainMeters ? Number(row.elevationGainMeters) : null,
        status,
        rating: Number(row.rating) || 5,
        personalNotes: row.personalNotes || null,
        dateConquered: dbAdapter.formatISO(dbAdapter.coreDataToDate(row.dateConquered)),
      };
    });
  }

  public logSummit(params: {
    name: string;
    region?: string;
    country?: string;
    latitude: number;
    longitude: number;
    elevationMeters: number;
    personalNotes?: string;
    rating?: number;
  }): TrekRecordItem {
    const id = crypto.randomUUID();
    const nowCD = dbAdapter.dateToCoreData(new Date());

    dbAdapter.execute(
      `INSERT INTO ZTREKRECORD (
        ZID, ZNAME, ZREGION, ZCOUNTRY, ZLATITUDE, ZLONGITUDE, ZELEVATIONMETERS, ZSTATUSRAW, ZRATING, ZPERSONALNOTES, ZDATECONQUERED, ZCREATEDAT
      ) VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?, ?)`,
      [
        id,
        params.name,
        params.region ?? "",
        params.country ?? "",
        params.latitude,
        params.longitude,
        params.elevationMeters,
        params.rating ?? 5,
        params.personalNotes ?? null,
        nowCD,
        nowCD,
      ]
    );

    const treks = this.listTreks();
    return treks.find((t) => t.id === id)!;
  }

  public getLifeBlueprint(): {
    categories: Record<string, LifeBlueprintItem[]>;
    totalGoals: number;
    achievedCount: number;
  } {
    const rows = dbAdapter.queryAll<any>(
      `SELECT 
        ZID as id,
        COALESCE(ZCATEGORY, 'Mastery') as category,
        ZTITLE as title,
        ZTARGETYEAR as targetYear,
        COALESCE(ZISACHIEVED, 0) as isAchieved,
        ZMANIFESTONOTES as manifestoNotes
       FROM ZLIFEBLUEPRINT
       ORDER BY ZTARGETYEAR ASC, Z_PK ASC`
    );

    const categories: Record<string, LifeBlueprintItem[]> = {
      Mastery: [],
      Adventure: [],
      Freedom: [],
      Principles: [],
    };

    let achievedCount = 0;

    for (const r of rows) {
      const cat = r.category as "Adventure" | "Mastery" | "Freedom" | "Principles";
      const isAchieved = r.isAchieved === 1;
      if (isAchieved) achievedCount++;

      const item: LifeBlueprintItem = {
        id: dbAdapter.formatUUID(r.id),
        category: cat,
        title: r.title || "Untitled Goal",
        targetYear: r.targetYear ? Number(r.targetYear) : null,
        isAchieved,
        manifestoNotes: r.manifestoNotes || null,
      };

      if (!categories[cat]) categories[cat] = [];
      categories[cat].push(item);
    }

    return {
      categories,
      totalGoals: rows.length,
      achievedCount,
    };
  }

  public addBlueprintGoal(params: {
    category: "Adventure" | "Mastery" | "Freedom" | "Principles";
    title: string;
    targetYear?: number;
    manifestoNotes?: string;
  }): LifeBlueprintItem {
    const id = crypto.randomUUID();
    const nowCD = dbAdapter.dateToCoreData(new Date());

    dbAdapter.execute(
      `INSERT INTO ZLIFEBLUEPRINT (ZID, ZCATEGORY, ZTITLE, ZTARGETYEAR, ZMANIFESTONOTES, ZCREATEDAT)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [id, params.category, params.title, params.targetYear ?? null, params.manifestoNotes ?? null, nowCD]
    );

    return {
      id,
      category: params.category,
      title: params.title,
      targetYear: params.targetYear ?? null,
      isAchieved: false,
      manifestoNotes: params.manifestoNotes ?? null,
    };
  }
}

export const lifeRepo = new LifeRepository();
