import { sqliteTable, text } from "drizzle-orm/sqlite-core";
import { sql } from "drizzle-orm";

export const projectKnowledge = sqliteTable("project_knowledge", {
  projectId: text("project_id").primaryKey(),
  projectHash: text("project_hash"),
  payload: text("payload").notNull(),
  updatedAt: text("updated_at").default(sql`CURRENT_TIMESTAMP`),
});

export type ProjectKnowledgeRow = typeof projectKnowledge.$inferSelect;
export type InsertProjectKnowledgeRow = typeof projectKnowledge.$inferInsert;
