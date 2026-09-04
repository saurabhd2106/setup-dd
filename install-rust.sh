#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DD_NAME="install-rust"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

RUSTUP_URL="${RUSTUP_URL:-https://sh.rustup.rs}"
CARGO_BIN="$(target_home)/.cargo/bin"

ensure_apt

export PATH="${CARGO_BIN}:${PATH}"

if command -v rustc >/dev/null 2>&1 && command -v cargo >/dev/null 2>&1; then
  log "Rust is already installed: $(rustc --version 2>&1 | sed -n '1p'), $(cargo --version 2>&1 | sed -n '1p')"
  ensure_profile_path "$CARGO_BIN" "setup-dd install-rust"
  exit 0
fi

apt_install_missing curl:curl build-essential:cc
require_command curl

log "Installing Rust via rustup for $(target_user)."
curl -fsSL "$RUSTUP_URL" | run_as_target_user sh -s -- -y --default-toolchain stable

hash -r 2>/dev/null || true
export PATH="${CARGO_BIN}:${PATH}"
ensure_profile_path "$CARGO_BIN" "setup-dd install-rust"

if ! run_as_target_user bash -lc "export PATH=\"${CARGO_BIN}:\$PATH\"; command -v rustc >/dev/null 2>&1"; then
  fail "Rust install finished but 'rustc' was not found on PATH"
fi
if ! run_as_target_user bash -lc "export PATH=\"${CARGO_BIN}:\$PATH\"; command -v cargo >/dev/null 2>&1"; then
  fail "Rust install finished but 'cargo' was not found on PATH"
fi

log "Rust installed successfully: $(run_as_target_user bash -lc "export PATH=\"${CARGO_BIN}:\$PATH\"; rustc --version" 2>&1 | sed -n '1p'), $(run_as_target_user bash -lc "export PATH=\"${CARGO_BIN}:\$PATH\"; cargo --version" 2>&1 | sed -n '1p')"
