import test from "node:test";
import assert from "node:assert/strict";
import { authenticate } from "../src/auth.js";
import { KnowledgeService } from "../src/service.js";

// Mock Repository
class MockRepository {
  public store = new Map<string, any>();

  async getKnowledge(id: string) {
    const data = this.store.get(id);
    return data ? { project_id: id, project_hash: "hash", payload: data, updated_at: "now" } : null;
  }

  async saveKnowledge(id: string, hash: string, payload: any) {
    this.store.set(id, payload);
  }

  async listProjects() {
    return Array.from(this.store.keys()).map((k) => ({
      project_id: k,
      project_hash: "hash",
      updated_at: "now",
    }));
  }
}

test("Authentication middleware", () => {
  process.env.CTX_SECRET_KEY = "test-secret-123";
  assert.equal(authenticate(undefined), false);
  assert.equal(authenticate("Bearer wrong"), false);
  assert.equal(authenticate("Bearer test-secret-123"), true);
});

test("KnowledgeService push and pull", async () => {
  const repo = new MockRepository();
  const service = new KnowledgeService(repo as any);

  const testPayload = {
    project_root: "/home/bms/test",
    project_hash: "12345",
    facts: [{ category: "db", key: "port", value: "5432" }],
  };

  await service.push("my-project", testPayload);
  const pulled = await service.pull("my-project");

  assert.deepEqual(pulled, testPayload);

  const list = await service.list();
  assert.equal(list.length, 1);
  assert.equal(list[0].project_id, "my-project");
});
