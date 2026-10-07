import type { IncomingMessage, ServerResponse } from "node:http";
import { authenticate } from "../src/auth.js";
import { KnowledgeService } from "../src/service.js";

const service = new KnowledgeService();

export default async function handler(req: IncomingMessage & { query?: Record<string, string>; body?: unknown }, res: ServerResponse): Promise<void> {
  const sendJson = (status: number, data: unknown) => {
    res.statusCode = status;
    res.setHeader("Content-Type", "application/json");
    res.end(JSON.stringify(data));
  };

  try {
    if (!authenticate(req.headers.authorization)) {
      sendJson(401, { success: false, error: "Unauthorized: Invalid or missing token" });
      return;
    }

    const url = new URL(req.url || "/", `http://${req.headers.host || "localhost"}`);
    const method = req.method?.toUpperCase();

    // GET: Pull knowledge or list projects
    if (method === "GET") {
      const projectId = url.searchParams.get("project");
      if (!projectId) {
        const list = await service.list();
        sendJson(200, { success: true, data: list });
        return;
      }

      const payload = await service.pull(projectId);
      if (!payload) {
        sendJson(404, { success: false, error: `Project '${projectId}' not found in cloud knowledge base` });
        return;
      }

      sendJson(200, payload);
      return;
    }

    // POST: Push knowledge
    if (method === "POST") {
      let bodyData: any = req.body;
      if (!bodyData) {
        const buffers: Buffer[] = [];
        for await (const chunk of req) {
          buffers.push(typeof chunk === "string" ? Buffer.from(chunk) : chunk);
        }
        const raw = Buffer.concat(buffers).toString("utf-8");
        bodyData = raw ? JSON.parse(raw) : {};
      }

      const projectId = url.searchParams.get("project") || bodyData.project_id || (bodyData.project_root ? bodyData.project_root.split("/").pop() : null);

      if (!projectId) {
        sendJson(400, { success: false, error: "Project identifier required (?project=... or project_id in body)" });
        return;
      }

      await service.push(projectId, bodyData);
      sendJson(200, { success: true, message: `Knowledge for '${projectId}' successfully synced` });
      return;
    }

    sendJson(405, { success: false, error: `Method ${method} not allowed` });
  } catch (err: any) {
    sendJson(500, { success: false, error: err.message || "Internal server error" });
  }
}
