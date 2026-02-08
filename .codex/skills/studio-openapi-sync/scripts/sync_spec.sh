#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

CANONICAL_SPEC="${REPO_ROOT}/docs/core/contracts/openapi/tv7-fastapi-backend/openapi.json"
LOCAL_SPEC="${REPO_ROOT}/forgotten_client/openapi/forgotten-app.json"

if [[ ! -f "${CANONICAL_SPEC}" ]]; then
  echo "Missing canonical OpenAPI spec: ${CANONICAL_SPEC}" >&2
  exit 1
fi

mkdir -p "$(dirname "${LOCAL_SPEC}")"
cp "${CANONICAL_SPEC}" "${LOCAL_SPEC}"

echo "Synced OpenAPI spec:"
echo "  from: ${CANONICAL_SPEC}"
echo "  to:   ${LOCAL_SPEC}"

if command -v shasum >/dev/null 2>&1; then
  echo "Hashes:"
  echo "  canonical: $(shasum -a 256 "${CANONICAL_SPEC}" | awk '{print $1}')"
  echo "  local:     $(shasum -a 256 "${LOCAL_SPEC}" | awk '{print $1}')"
fi
