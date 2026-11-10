#!/bin/sh
set -eu

if [ -x "$HOME/.cargo/bin/rustup" ]; then
  rustup_bin="$HOME/.cargo/bin/rustup"
elif [ -x /opt/homebrew/opt/rustup/bin/rustup ]; then
  rustup_bin=/opt/homebrew/opt/rustup/bin/rustup
elif command -v rustup >/dev/null 2>&1; then
  rustup_bin=$(command -v rustup)
else
  rustup_bin=
fi

if [ -n "$rustup_bin" ]; then
  PATH="$(dirname "$rustup_bin"):$PATH"
  RUSTUP_TOOLCHAIN="${RUSTUP_TOOLCHAIN:-stable}"
  export PATH RUSTUP_TOOLCHAIN
fi

exec "$@"
