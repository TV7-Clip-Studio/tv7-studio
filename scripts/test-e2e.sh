#!/bin/sh
set -eu
workspace=$(mktemp -d)
trap 'rm -rf "$workspace"' EXIT
export TV7_E2E_DIR="$workspace"
export TV7_ENGINE_WORK_DIR="$workspace"
export TV7_ENGINE_PORT=17070
export TV7_ENGINE_YT_DLP_BIN="$PWD/tests/e2e/yt-dlp-fixture"
export VITE_ENGINE_URL=http://127.0.0.1:17070
export VITE_BACKEND_URL=http://127.0.0.1:18000
ffmpeg -v error -f lavfi -i 'testsrc2=size=320x240:rate=30:duration=20' \
  -c:v libx264 -pix_fmt yuv420p "$workspace/local-fixture.mp4"
# Keep per-test fixture inputs separate from the Engine's managed asset catalog.
mkdir "$workspace/assets"
export TV7_ENGINE_ASSET_DIR="$workspace/assets"
npx --no-install playwright test "$@"
