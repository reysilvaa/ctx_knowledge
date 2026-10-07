import { KnowledgeRepository } from "./repository.js";
import { KnowledgePayload, SyncRecord } from "./types.js";

export class KnowledgeService {
  constructor(private repo: KnowledgeRepository = new KnowledgeRepository()) {}

  async pull(projectId: string): Promise<KnowledgePayload | null> {
    if (!projectId || typeof projectId !== "string") {
      throw new Error("Invalid project ID");
    }
    const record = await this.repo.getKnowledge(projectId);
    return record ? record.payload : null;
  }

  async push(
    projectId: string,
    payload: KnowledgePayload
  ): Promise<void> {
    if (!projectId || typeof projectId !== "string") {
      throw new Error("Invalid project ID");
    }

    if (!payload || !Array.isArray(payload.facts)) {
      throw new Error("Invalid knowledge payload: 'facts' array is required");
    }

    const projectHash = payload.project_hash || "";
    await this.repo.saveKnowledge(projectId, projectHash, payload);
  }

  async list(): Promise<{ project_id: string; project_hash: string; updated_at: string }[]> {
    return this.repo.listProjects();
  }
}
