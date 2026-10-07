#!/usr/bin/env bash
# ==============================================================================
# Seamless Auto-Sync antara Local Lean-CTX dan Turso Cloud
# ==============================================================================
set -euo pipefail

CTX_DIR="/home/bms-del053/My-Self/ctx-cloud"
ACTION="${1:-push}"

case "${ACTION}" in
  push)
    # Upload semua knowledge lokal yang ada ke Turso
    pnpm --dir "${CTX_DIR}" exec tsx -e '
      require("dotenv").config({ path: "/home/bms-del053/My-Self/ctx-cloud/.env" });
      const fs = require("fs");
      const path = require("path");
      const crypto = require("crypto");
      const { createClient } = require("@libsql/client");

      async function sync() {
        const client = createClient({
          url: process.env.TURSO_DATABASE_URL,
          authToken: process.env.TURSO_AUTH_TOKEN
        });

        const base = "/home/bms-del053/.local/share/lean-ctx/knowledge";
        if (!fs.existsSync(base)) return;
        const dirs = fs.readdirSync(base);

        for (const d of dirs) {
          const f = path.join(base, d, "knowledge.json");
          if (fs.existsSync(f)) {
            const raw = fs.readFileSync(f, "utf-8");
            const json = JSON.parse(raw);
            const root = json.project_root || d;
            const slug = path.basename(root) || d;
            const projectId = `lean-ctx-${slug}-${d.slice(0, 6)}`;
            const hash = crypto.createHash("sha256").update(raw).digest("hex");

            await client.execute({
              sql: `INSERT INTO project_knowledge (project_id, project_hash, payload, updated_at)
                    VALUES (?, ?, ?, CURRENT_TIMESTAMP)
                    ON CONFLICT(project_id) DO UPDATE SET
                      project_hash = excluded.project_hash,
                      payload = excluded.payload,
                      updated_at = CURRENT_TIMESTAMP`,
              args: [projectId, hash, raw]
            });
          }
        }
        console.log("✅ Auto-push ke Turso selesai.");
      }
      sync().catch(console.error);
    '
    ;;

  pull)
    # Pull dan pulihkan semua knowledge dari Turso ke lokal ~/.local/share/lean-ctx/
    pnpm --dir "${CTX_DIR}" exec tsx -e '
      require("dotenv").config({ path: "/home/bms-del053/My-Self/ctx-cloud/.env" });
      const fs = require("fs");
      const path = require("path");
      const { createClient } = require("@libsql/client");

      async function restore() {
        const client = createClient({
          url: process.env.TURSO_DATABASE_URL,
          authToken: process.env.TURSO_AUTH_TOKEN
        });

        const res = await client.execute("SELECT project_id, payload FROM project_knowledge WHERE project_id LIKE \x27lean-ctx-%\x27");
        const base = "/home/bms-del053/.local/share/lean-ctx/knowledge";

        for (const row of res.rows) {
          try {
            const json = JSON.parse(row.payload);
            const parts = row.project_id.split("-");
            const hashPrefix = parts[parts.length - 1];

            // Cocokkan ke direktori yang sesuai
            const targetDirs = fs.readdirSync(base).filter(d => d.startsWith(hashPrefix));
            for (const td of targetDirs) {
              const targetFile = path.join(base, td, "knowledge.json");
              fs.writeFileSync(targetFile, JSON.stringify(json, null, 2));
              console.log("Restored knowledge to:", td);
            }
          } catch(e) {}
        }
        console.log("✅ Auto-pull dari Turso selesai.");
      }
      restore().catch(console.error);
    '
    ;;
esac
