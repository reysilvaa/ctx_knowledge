import { eq, desc } from "drizzle-orm";
import { getDb, initDb } from "./db.js";
import { projectKnowledge } from "./schema.js";
import { KnowledgePayload, SyncRecord } from "./types.js";

export class KnowledgeRepository {
  private static initialized = false;

  private async ensureTable(): Promise<void> {
    if (!KnowledgeRepository.initialized) {
      await initDb();
      KnowledgeRepository.initialized = true;
    }
  }

  async getKnowledge(projectId: string): Promise<SyncRecord | null> {
    await this.ensureTable();
    const db = getDb();
    const rows = await db
      .select()
      .from(projectKnowledge)
      .where(eq(projectKnowledge.projectId, projectId))
      .limit(1);

    if (rows.length === 0) {
      return null;
    }

    const row = rows[0];
    return {
      project_id: row.projectId,
      project_hash: row.projectHash || "",
      payload: JSON.parse(row.payload) as KnowledgePayload,
      updated_at: row.updatedAt || "",
    };
  }

  async saveKnowledge(
    projectId: string,
    projectHash: string,
    payload: KnowledgePayload
  ): Promise<void> {
    await this.ensureTable();
    const db = getDb();

    await db
      .insert(projectKnowledge)
      .values({
        projectId,
        projectHash,
        payload: JSON.stringify(payload),
      })
      .onConflictDoUpdate({
        target: projectKnowledge.projectId,
        set: {
          projectHash,
          payload: JSON.stringify(payload),
        },
      });
  }

  async listProjects(): Promise<{ project_id: string; project_hash: string; updated_at: string }[]> {
    await this.ensureTable();
    const db = getDb();
    const rows = await db
      .select({
        projectId: projectKnowledge.projectId,
        projectHash: projectKnowledge.projectHash,
        updatedAt: projectKnowledge.updatedAt,
      })
      .from(projectKnowledge)
      .orderBy(desc(projectKnowledge.updatedAt));

    return rows.map((row) => ({
      project_id: row.projectId,
      project_hash: row.projectHash || "",
      updated_at: row.updatedAt || "",
    }));
  }
}
