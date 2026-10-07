#!/usr/bin/env bash
# ==============================================================================
# Seamless Auto-Sync antara Local Lean-CTX dan Vercel Cloud API
# ==============================================================================
set -euo pipefail

CONFIG_FILE="${HOME}/.config/ctx-cloud.env"
if [[ -f "${CONFIG_FILE}" ]]; then
  # shellcheck source=/dev/null
  source "${CONFIG_FILE}"
fi

export ENDPOINT="${CTX_CLOUD_URL:-https://ctxknowledge.vercel.app/api/sync}"
export TOKEN="${CTX_CLOUD_TOKEN:-b87ab9dd25dc2b3c0ae9ff8da880936a}"
ACTION="${1:-push}"

case "${ACTION}" in
  push)
    # Upload semua knowledge lokal yang ada ke Vercel API
    node -e '
      const fs = require("fs");
      const path = require("path");

      const endpoint = process.env.ENDPOINT;
      const token = process.env.TOKEN;
      const base = "/home/bms-del053/.local/share/lean-ctx/knowledge";
      if (!fs.existsSync(base)) process.exit(0);
      const dirs = fs.readdirSync(base);

      async function pushAll() {
        for (const d of dirs) {
          const f = path.join(base, d, "knowledge.json");
          if (fs.existsSync(f)) {
            try {
              const raw = fs.readFileSync(f, "utf-8");
              const json = JSON.parse(raw);
              const root = json.project_root || d;
              const slug = path.basename(root) || d;
              const projectId = `lean-ctx-${slug}-${d.slice(0, 6)}`;

              const res = await fetch(`${endpoint}?project=${projectId}`, {
                method: "POST",
                headers: {
                  "Authorization": `Bearer ${token}`,
                  "Content-Type": "application/json"
                },
                body: raw
              });
              if (res.ok) {
                console.log(`✅ Synced to Vercel: ${projectId}`);
              } else {
                console.warn(`⚠️ Failed ${projectId}: HTTP ${res.status}`);
              }
            } catch (err) {
              console.error(`❌ Error ${d}:`, err.message);
            }
          }
        }
      }
      pushAll().then(() => console.log("🎉 Auto-push ke Vercel Cloud selesai."));
    '
    ;;

  pull)
    # Pull dan pulihkan knowledge dari Vercel Cloud API ke ~/.local/share/lean-ctx/
    node -e '
      const fs = require("fs");
      const path = require("path");

      const endpoint = process.env.ENDPOINT;
      const token = process.env.TOKEN;
      const base = "/home/bms-del053/.local/share/lean-ctx/knowledge";
      if (!fs.existsSync(base)) fs.mkdirSync(base, { recursive: true });

      async function pullAll() {
        const res = await fetch(endpoint, {
          headers: { "Authorization": `Bearer ${token}` }
        });
        const json = await res.json();
        if (!json.success || !Array.isArray(json.data)) {
          console.error("Gagal mengambil daftar proyek dari Vercel:", json);
          return;
        }

        for (const item of json.data) {
          if (!item.project_id.startsWith("lean-ctx-")) continue;
          try {
            const parts = item.project_id.split("-");
            const hashPrefix = parts[parts.length - 1];

            const itemRes = await fetch(`${endpoint}?project=${item.project_id}`, {
              headers: { "Authorization": `Bearer ${token}` }
            });
            if (!itemRes.ok) continue;
            const payload = await itemRes.json();

            const targetDirs = fs.readdirSync(base).filter(d => d.startsWith(hashPrefix));
            for (const td of targetDirs) {
              const targetFile = path.join(base, td, "knowledge.json");
              fs.writeFileSync(targetFile, JSON.stringify(payload, null, 2));
              console.log(`✅ Restored to local: ${td}`);
            }
          } catch(e) {}
        }
      }
      pullAll().then(() => console.log("🎉 Auto-pull dari Vercel Cloud selesai."));
    '
    ;;
esac
