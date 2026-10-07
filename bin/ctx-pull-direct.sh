#!/usr/bin/env bash
# ==============================================================================
# ctx-pull-direct: Pull & Restore Knowledge directly from Vercel Cloud API
# ==============================================================================
set -euo pipefail

CONFIG_FILE="${HOME}/.config/ctx-cloud.env"
if [[ -f "${CONFIG_FILE}" ]]; then
  # shellcheck source=/dev/null
  source "${CONFIG_FILE}"
fi

ENDPOINT="${CTX_CLOUD_URL:-https://ctxknowledge.vercel.app/api/sync}"
TOKEN="${CTX_CLOUD_TOKEN:-b87ab9dd25dc2b3c0ae9ff8da880936a}"
PROJECT_ID="${1:-}"

if [[ -z "${PROJECT_ID}" ]]; then
  echo "Usage: ctx-pull-direct <project_id>"
  echo ""
  echo "Daftar project_id yang tersedia di Cloud Vercel:"
  curl -sS -H "Authorization: Bearer ${TOKEN}" "${ENDPOINT}" | jq -r '.data[].project_id' 2>/dev/null || true
  exit 1
fi

TMP_PAYLOAD="$(mktemp --suffix=.json)"
TMP_FACTS="$(mktemp --suffix=.json)"

echo "Mengambil knowledge '${PROJECT_ID}' dari ${ENDPOINT}..."
HTTP_CODE=$(curl -sS -w "%{http_code}" -o "${TMP_PAYLOAD}" \
  -H "Authorization: Bearer ${TOKEN}" \
  "${ENDPOINT}?project=${PROJECT_ID}")

if [[ "${HTTP_CODE}" != "200" ]]; then
  echo "Gagal mengambil knowledge dari Vercel (HTTP ${HTTP_CODE}):" >&2
  cat "${TMP_PAYLOAD}" >&2
  rm -f "${TMP_PAYLOAD}" "${TMP_FACTS}"
  exit 1
fi

# Ekstrak array facts agar kompatibel dengan 'lean-ctx knowledge import'
node -e '
  const fs = require("fs");
  const data = JSON.parse(fs.readFileSync(process.argv[1], "utf-8"));
  const facts = Array.isArray(data) ? data : (data.facts || [data]);
  fs.writeFileSync(process.argv[2], JSON.stringify(facts, null, 2));
' "${TMP_PAYLOAD}" "${TMP_FACTS}"

echo "Mengimpor fakta ke lean-ctx lokal..."
lean-ctx knowledge import "${TMP_FACTS}" --merge append
rm -f "${TMP_PAYLOAD}" "${TMP_FACTS}"

echo "✅ Berhasil! Knowledge '${PROJECT_ID}' sudah aktif di lean-ctx lokal kamu via Vercel Cloud."
