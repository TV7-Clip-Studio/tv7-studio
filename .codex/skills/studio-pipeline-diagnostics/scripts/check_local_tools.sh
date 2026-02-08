#!/usr/bin/env bash
set -euo pipefail

missing=0

check_tool() {
  local tool="$1"

  if command -v "${tool}" >/dev/null 2>&1; then
    local path
    path="$(command -v "${tool}")"
    echo "[OK] ${tool}: ${path}"
    case "${tool}" in
      ffmpeg)
        ffmpeg -version 2>/dev/null | head -n 1 | sed "s/^/      version: /"
        ;;
      yt-dlp)
        yt-dlp --version 2>/dev/null | head -n 1 | sed "s/^/      version: /"
        ;;
      *)
        echo "      version: unknown"
        ;;
    esac
  else
    echo "[MISSING] ${tool}"
    missing=1
  fi
}

check_tool "ffmpeg"
check_tool "yt-dlp"

if [[ "${missing}" -ne 0 ]]; then
  echo "One or more required tools are missing." >&2
  exit 1
fi

echo "All required local media tools are available."
