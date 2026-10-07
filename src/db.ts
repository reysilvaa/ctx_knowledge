import { createClient, Client } from "@libsql/client";
import { drizzle, LibSQLDatabase } from "drizzle-orm/libsql";
import * as schema from "./schema.js";

let clientInstance: Client | null = null;
let dbInstance: LibSQLDatabase<typeof schema> | null = null;

export function getClient(): Client {
  if (clientInstance) return clientInstance;

  const url = process.env.TURSO_DATABASE_URL;
  const authToken = process.env.TURSO_AUTH_TOKEN;

  if (!url) {
    throw new Error("Missing TURSO_DATABASE_URL environment variable");
  }

  clientInstance = createClient({
    url,
    authToken,
  });

  return clientInstance;
}

export function getDb(): LibSQLDatabase<typeof schema> {
  if (dbInstance) return dbInstance;
  const client = getClient();
  dbInstance = drizzle(client, { schema });
  return dbInstance;
}

export async function initDb(): Promise<void> {
  const client = getClient();
  await client.execute(`
    CREATE TABLE IF NOT EXISTS project_knowledge (
      project_id TEXT PRIMARY KEY,
      project_hash TEXT,
      payload TEXT NOT NULL,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `);
}
