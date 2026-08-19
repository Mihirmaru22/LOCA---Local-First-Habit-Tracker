import path from "node:path";
import os from "node:os";
import fs from "node:fs";
import Database from "better-sqlite3";

export interface ServerConfig {
  dbPath: string;
  isFallback: boolean;
  version: string;
  serverName: string;
}

function isDatabaseAccessible(testPath: string): boolean {
  try {
    if (!fs.existsSync(testPath)) return false;
    fs.accessSync(testPath, fs.constants.R_OK);
    const testDb = new Database(testPath, { timeout: 500 });
    testDb.prepare("SELECT 1").get();
    testDb.close();
    return true;
  } catch {
    return false;
  }
}

export function resolveDatabasePath(): { dbPath: string; isFallback: boolean } {
  // 1. Explicit CLI argument --db /path/to/default.store
  const args = process.argv.slice(2);
  const dbArgIdx = args.findIndex((arg) => arg === "--db" || arg === "-d");
  if (dbArgIdx !== -1 && args[dbArgIdx + 1]) {
    const customPath = path.resolve(args[dbArgIdx + 1]);
    if (isDatabaseAccessible(customPath)) {
      return { dbPath: customPath, isFallback: false };
    }
  }

  // 2. Explicit Environment Variable
  if (process.env.LOCA_DB_PATH) {
    const envPath = path.resolve(process.env.LOCA_DB_PATH);
    if (isDatabaseAccessible(envPath)) {
      return { dbPath: envPath, isFallback: false };
    }
  }

  const homeDir = os.homedir();

  // 3. Known macOS container locations
  const candidatePaths = [
    path.join(
      homeDir,
      "Library/Group Containers/group.com.mihirmaru.loca/default.store"
    ),
    path.join(
      homeDir,
      "Library/Application Support/LOCA/default.store"
    ),
    path.join(
      homeDir,
      "Library/Application Support/default.store"
    ),
    path.join(
      homeDir,
      "Library/Containers/com.Loca-final-final.Loca-Mac/Data/Library/Application Support/default.store"
    ),
  ];

  for (const candidate of candidatePaths) {
    if (isDatabaseAccessible(candidate)) {
      return { dbPath: candidate, isFallback: false };
    }
  }

  // 4. Standalone / Development Database
  const fallbackDir = path.resolve(process.cwd(), "data");
  if (!fs.existsSync(fallbackDir)) {
    fs.mkdirSync(fallbackDir, { recursive: true });
  }
  const fallbackPath = path.join(fallbackDir, "loca-dev.store");
  return { dbPath: fallbackPath, isFallback: true };
}

export const CONFIG: ServerConfig = {
  ...resolveDatabasePath(),
  version: "1.0.0",
  serverName: "loca-mcp-server",
};
