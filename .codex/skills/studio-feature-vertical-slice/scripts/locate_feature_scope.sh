#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <feature-keyword>" >&2
  exit 1
fi

feature="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

echo "Feature keyword: ${feature}"
echo

echo "Candidate directories:"
find "${REPO_ROOT}/forgotten_client/lib/features" -type d -name "*${feature}*" 2>/dev/null | sort || true
find "${REPO_ROOT}/forgotten_client/lib/data" -type d -name "*${feature}*" 2>/dev/null | sort || true
find "${REPO_ROOT}/forgotten_client/test" -type d -name "*${feature}*" 2>/dev/null | sort || true

echo
echo "Candidate files:"
find "${REPO_ROOT}/forgotten_client/lib" -type f -name "*${feature}*" \
  ! -path "*/lib/api/generated/*" \
  ! -path "*/.dart_tool/*" \
  ! -path "*/build/*" 2>/dev/null | sort || true
find "${REPO_ROOT}/forgotten_client/test" -type f -name "*${feature}*" \
  ! -path "*/.dart_tool/*" \
  ! -path "*/build/*" 2>/dev/null | sort || true
