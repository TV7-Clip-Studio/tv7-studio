#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/.."
OPENAPI_DIR="${REPO_ROOT}/openapi"
SPEC="${OPENAPI_DIR}/forgotten-app.json"
CONFIG="${OPENAPI_DIR}/config.yaml"
OUTPUT_DIR="${REPO_ROOT}/lib/api/generated"

if [[ ! -f "${SPEC}" ]]; then
  echo "Missing OpenAPI spec at ${SPEC}."
  echo "Download the latest forgotten-app OpenAPI file and save it there (e.g., curl -o ${SPEC} <SPEC_URL>)."
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"

openapi-generator generate \
  -g dart-dio \
  -i "${SPEC}" \
  -o "${OUTPUT_DIR}" \
  -c "${CONFIG}" \
  --skip-validate-spec

echo "API client generated into ${OUTPUT_DIR}"

# Fix dependencies to avoid build errors
cat > "${OUTPUT_DIR}/pubspec.yaml" <<EOF
name: forgotten_client_api
version: 0.0.1
description: API client for forgotten-app backend (generated).
homepage: homepage

environment:
  sdk: ^3.4.0

dependencies:
  dio: '^5.7.0'
  copy_with_extension: '^5.0.0'
  json_annotation: '^4.8.0'

dev_dependencies:
  build_runner: any
  copy_with_extension_gen: ^5.0.0
  json_serializable: '6.8.0'
  test: '^1.16.0'
EOF

echo "Restored safe dependencies in pubspec.yaml"

# Run build_runner
cd "${OUTPUT_DIR}"
flutter pub get
dart run build_runner build --delete-conflicting-outputs

echo "Regenerated code with build_runner"

# Patch files to enforce language version 3.4 (resolves mismatch with generated code)
find lib/src -name "*.dart" -exec sed -i '' '1s/^/\/\/ @dart=3.4\n/' {} +

echo "Patched generated files with // @dart=3.4"
