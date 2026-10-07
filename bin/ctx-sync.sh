#!/usr/bin/env bash
# ==============================================================================
# ctx-sync: Push or Pull Lean-CTX knowledge to self-hosted cloud on Vercel
# ==============================================================================
set -euo pipefail

CONFIG_FILE="${HOME}/.config/ctx-cloud.env"
if [[ -f "${CONFIG_FILE}" ]]; then
  # shellcheck source=/dev/null
  source "${CONFIG_FILE}"
fi

ENDPOINT="${CTX_CLOUD_URL:-https://ctxknowledge.vercel.app/api/sync}"
TOKEN="${CTX_CLOUD_TOKEN:-b87ab9dd25dc2b3c0ae9ff8da880936a}"

if [[ -z "${TOKEN}" ]]; then
  echo "Error: CTX_CLOUD_TOKEN is not set. Export it or create ${CONFIG_FILE}" >&2
  exit 1
fi

ACTION="${1:-push}"
PROJECT_NAME="$(basename "${PWD}")"

case "${ACTION}" in
  push)
    echo "Exporting local lean-ctx knowledge for '${PROJECT_NAME}'..."
    TMP_EXPORT="$(mktemp)"
    lean-ctx knowledge export --format json > "${TMP_EXPORT}"

    echo "Pushing to ${ENDPOINT}?project=${PROJECT_NAME}..."
    curl -sS -X POST "${ENDPOINT}?project=${PROJECT_NAME}" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "Content-Type: application/json" \
      --data-binary "@${TMP_EXPORT}"
    rm -f "${TMP_EXPORT}"
    echo ""
    echo "Sync push completed."
    ;;

  pull)
    echo "Pulling knowledge for '${PROJECT_NAME}' from ${ENDPOINT}..."
    TMP_PULL="$(mktemp)"
    HTTP_CODE=$(curl -sS -w "%{http_code}" -o "${TMP_PULL}" \
      -H "Authorization: Bearer ${TOKEN}" \
      "${ENDPOINT}?project=${PROJECT_NAME}")

    if [[ "${HTTP_CODE}" != "200" ]]; then
      echo "Failed to pull knowledge (HTTP ${HTTP_CODE}):" >&2
      cat "${TMP_PULL}" >&2
      rm -f "${TMP_PULL}"
      exit 1
    fi

    echo "Importing into local lean-ctx..."
    lean-ctx knowledge import "${TMP_PULL}" --merge append
    rm -f "${TMP_PULL}"
    echo "Sync pull completed."
    ;;

  list)
    echo "Fetching registered cloud projects..."
    curl -sS -H "Authorization: Bearer ${TOKEN}" "${ENDPOINT}" | jq . || cat
    echo ""
    ;;

  *)
    echo "Usage: $0 [push|pull|list]"
    exit 1
    ;;
esac
