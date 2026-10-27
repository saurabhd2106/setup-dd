#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DD_NAME="install-cypress"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

ensure_apt

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  log "Node.js not found; installing Node.js before Cypress."
  bash "$SCRIPT_DIR/install-node.sh"
fi

require_command node
require_command npm

cypress_linux_deps() {
  local codename
  local -a packages=(
    libgbm-dev
    libnotify-dev
    libnss3
    libxss1
    libxtst6
    xauth
    xvfb
  )

  codename="$(ubuntu_codename)"
  case "$codename" in
    jammy|focal)
      packages+=(libgtk-3-0 libasound2)
      ;;
    *)
      # Ubuntu 24.04+ (noble and newer) use the t64 package names.
      packages+=(libgtk-3-0t64 libasound2t64)
      ;;
  esac

  printf '%s\n' "${packages[@]}"
}

cypress_binary_cached() {
  local cache_dir
  cache_dir="$(target_home)/.cache/Cypress"
  [[ -d "$cache_dir" ]] && [[ -n "$(ls -A "$cache_dir" 2>/dev/null || true)" ]]
}

if command -v cypress >/dev/null 2>&1 && cypress_binary_cached; then
  log "Cypress is already installed: $(cypress --version 2>&1 | sed -n '1p')"
  exit 0
fi

mapfile -t deps < <(cypress_linux_deps)
log "Installing Cypress Linux prerequisites."
apt_install "${deps[@]}"

if ! command -v cypress >/dev/null 2>&1; then
  log "Installing cypress globally via npm."
  run_sudo npm install -g cypress@latest
  hash -r 2>/dev/null || true
fi

if ! command -v cypress >/dev/null 2>&1; then
  fail "npm install finished but 'cypress' was not found on PATH"
fi

if ! cypress_binary_cached; then
  log "Downloading Cypress binary into the user cache."
  run_as_target_user cypress install
fi

log "Cypress installed successfully: $(cypress --version 2>&1 | sed -n '1p')"
cat <<'EOF'

The Cypress app binary is cached under ~/.cache/Cypress.
Projects should still add Cypress as a local devDependency:

  npm install cypress --save-dev
  npx cypress open
EOF
