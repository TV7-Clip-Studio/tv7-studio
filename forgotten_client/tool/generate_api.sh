#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/.."
OPENAPI_DIR="${REPO_ROOT}/openapi"
SPEC="${OPENAPI_DIR}/forgotten-app.yaml"
CONFIG="${OPENAPI_DIR}/config.yaml"
OUTPUT_DIR="${REPO_ROOT}/lib/api/generated"

if [[ ! -f "${SPEC}" ]]; then
  echo "Missing OpenAPI spec at ${SPEC}."
  echo "Download the latest forgotten-app OpenAPI file and save it there (e.g., curl -o ${SPEC} <SPEC_URL>)."
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"

openapi-generator-cli generate \
  -g dart-dio \
  -i "${SPEC}" \
  -o "${OUTPUT_DIR}" \
  -c "${CONFIG}" \
  --skip-validate-spec

echo "API client generated into ${OUTPUT_DIR}"
