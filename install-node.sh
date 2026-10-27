#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DD_NAME="install-node"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

NODE_MAJOR_VERSION="${NODE_MAJOR_VERSION:-24}"
NODE_APT_REPO="https://deb.nodesource.com/node_${NODE_MAJOR_VERSION}.x"
NODE_KEYRING_PATH="/usr/share/keyrings/nodesource.gpg"
NODE_SOURCE_PATH="/etc/apt/sources.list.d/nodesource.list"

ensure_apt

if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
  log "Node.js is already installed: $(node --version 2>&1), npm $(npm --version 2>&1)"
else
  install_gpg_key \
    "https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key" \
    "$NODE_KEYRING_PATH"

  write_apt_source \
    "deb [arch=$(dpkg_arch) signed-by=${NODE_KEYRING_PATH}] ${NODE_APT_REPO} nodistro main" \
    "$NODE_SOURCE_PATH"

  apt_install nodejs
  log "Node.js installed successfully: $(node --version 2>&1), npm $(npm --version 2>&1)"
fi

require_command node
require_command npm

if ! command -v corepack >/dev/null 2>&1; then
  fail "corepack not found; Node.js install should provide it"
fi

log "Enabling Corepack (yarn / pnpm shims)."
run_sudo corepack enable

log "Preparing yarn@stable and pnpm@latest via Corepack."
run_sudo corepack prepare yarn@stable --activate
run_sudo corepack prepare pnpm@latest --activate

hash -r 2>/dev/null || true

if ! command -v yarn >/dev/null 2>&1; then
  fail "Corepack enable finished but 'yarn' was not found on PATH"
fi
if ! command -v pnpm >/dev/null 2>&1; then
  fail "Corepack enable finished but 'pnpm' was not found on PATH"
fi

log "Node package managers ready: yarn $(yarn --version 2>&1), pnpm $(pnpm --version 2>&1)"
