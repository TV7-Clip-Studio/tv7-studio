#!/bin/sh
set -eu

studio_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
engine_dir=$(CDPATH= cd -- "$studio_dir/../tv7-engine" && pwd)

case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) target=aarch64-apple-darwin ;;
  Darwin-x86_64) target=x86_64-apple-darwin ;;
  *) echo "Studio currently packages a macOS Engine sidecar only." >&2; exit 1 ;;
esac

cargo build --release --manifest-path "$engine_dir/Cargo.toml" -p engine-service
mkdir -p "$studio_dir/src-tauri/binaries"
cp "$engine_dir/target/release/engine-service" "$studio_dir/src-tauri/binaries/engine-service-$target"
chmod 755 "$studio_dir/src-tauri/binaries/engine-service-$target"
yt_dlp_version=2026.08.19
yt_dlp_sha256=07e54b0865303c864006925913bce2604f8ee8cc6f18699bac9c309f9328a6d8
yt_dlp_binary_sha256=4f54eb67e4e96c7c3ffa49dd5deb81bc348bbb495080889b47d157d5c6d74443
yt_dlp_binary="$studio_dir/src-tauri/binaries/yt-dlp-macos"
yt_dlp_internal="$studio_dir/src-tauri/binaries/yt-dlp-internal"
if [ ! -f "$yt_dlp_binary" ] || [ ! -d "$yt_dlp_internal" ] || \
   [ "$(shasum -a 256 "$yt_dlp_binary" | cut -d ' ' -f 1)" != "$yt_dlp_binary_sha256" ]; then
  yt_dlp_temp=$(mktemp -d)
  trap 'rm -rf "$yt_dlp_temp"' EXIT HUP INT TERM
  curl --fail --location --silent --show-error --retry 3 \
    "https://github.com/yt-dlp/yt-dlp/releases/download/$yt_dlp_version/yt-dlp_macos.zip" \
    --output "$yt_dlp_temp/yt-dlp_macos.zip"
  actual_sha256=$(shasum -a 256 "$yt_dlp_temp/yt-dlp_macos.zip" | cut -d ' ' -f 1)
  if [ "$actual_sha256" != "$yt_dlp_sha256" ]; then
    echo "yt-dlp download checksum mismatch" >&2
    exit 1
  fi
  unzip -q "$yt_dlp_temp/yt-dlp_macos.zip" -d "$yt_dlp_temp/unpacked"
  chmod 755 "$yt_dlp_temp/unpacked/yt-dlp_macos"
  rm -rf "$yt_dlp_internal"
  mv "$yt_dlp_temp/unpacked/_internal" "$yt_dlp_internal"
  mv "$yt_dlp_temp/unpacked/yt-dlp_macos" "$yt_dlp_binary"
  trap - EXIT HUP INT TERM
  rm -rf "$yt_dlp_temp"
fi
ln -sfn "$yt_dlp_internal" "$studio_dir/src-tauri/binaries/_internal"
# Tauri dev runs outside the app bundle. Link the prepared directory beside
# its executable without duplicating the Python runtime.
mkdir -p "$studio_dir/src-tauri/target/debug"
ln -sfn "$studio_dir/src-tauri/binaries" "$studio_dir/src-tauri/target/debug/yt-dlp"
echo "Prepared Engine sidecar: $target"
echo "Prepared yt-dlp sidecar: $yt_dlp_version"
