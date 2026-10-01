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
echo "Prepared Engine sidecar: $target"
