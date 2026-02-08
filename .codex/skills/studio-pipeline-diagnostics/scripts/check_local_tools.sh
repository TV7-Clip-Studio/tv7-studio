#!/usr/bin/env bash
set -euo pipefail

missing=0

check_tool() {
  local tool="$1"
  local version_cmd="$2"

  if command -v "${tool}" >/dev/null 2>&1; then
    local path
    path="$(command -v "${tool}")"
    echo "[OK] ${tool}: ${path}"
    # shellcheck disable=SC2086
    eval "${version_cmd}" 2>/dev/null | head -n 1 | sed "s/^/      version: /"
  else
    echo "[MISSING] ${tool}"
    missing=1
  fi
}

check_tool "ffmpeg" "ffmpeg -version"
check_tool "yt-dlp" "yt-dlp --version"

if [[ "${missing}" -ne 0 ]]; then
  echo "One or more required tools are missing." >&2
  exit 1
fi

echo "All required local media tools are available."
