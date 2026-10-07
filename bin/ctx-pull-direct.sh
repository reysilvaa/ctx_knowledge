#!/usr/bin/env bash
# ==============================================================================
# ctx-pull-direct: Pull & Restore Knowledge from Turso directly into local lean-ctx
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="/home/bms-del053/My-Self/ctx-cloud"
PROJECT_ID="${1:-}"

if [[ -z "${PROJECT_ID}" ]]; then
  echo "Usage: ctx-pull-direct <project_id>"
  echo ""
  echo "Contoh project_id yang tersedia:"
  node -e '
    require("dotenv").config({ path: "/home/bms-del053/My-Self/ctx-cloud/.env" });
    const { createClient } = require("@libsql/client");
    const client = createClient({
      url: process.env.TURSO_DATABASE_URL,
      authToken: process.env.TURSO_AUTH_TOKEN
    });
    client.execute("SELECT project_id FROM project_knowledge ORDER BY project_id ASC")
      .then(r => r.rows.forEach(x => console.log("  - " + x.project_id)));
  '
  exit 1
fi

TMP_FILE="$(mktemp --suffix=.json)"

node -e '
  require("dotenv").config({ path: "/home/bms-del053/My-Self/ctx-cloud/.env" });
  const fs = require("fs");
  const { createClient } = require("@libsql/client");
  const client = createClient({
    url: process.env.TURSO_DATABASE_URL,
    authToken: process.env.TURSO_AUTH_TOKEN
  });
  const id = process.argv[1];
  const out = process.argv[2];
  client.execute({
    sql: "SELECT payload FROM project_knowledge WHERE project_id = ?",
    args: [id]
  }).then(r => {
    if (r.rows.length === 0) {
      console.error("Project not found in Turso:", id);
      process.exit(1);
    }
    const payload = JSON.parse(r.rows[0].payload);
    fs.writeFileSync(out, JSON.stringify(payload, null, 2));
    console.log("Downloaded payload for " + id);
  });
' "${PROJECT_ID}" "${TMP_FILE}"

echo "Mengimpor ke lean-ctx lokal..."
lean-ctx knowledge import "${TMP_FILE}" --merge append
rm -f "${TMP_FILE}"

echo "✅ Berhasil! Knowledge '${PROJECT_ID}' sudah aktif di lean-ctx lokal kamu."
