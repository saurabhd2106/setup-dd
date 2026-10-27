#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DD_NAME="install-playwright"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

# Optional space-separated browser list for playwright install, e.g. "chromium".
# Empty means install the default set (Chromium, Firefox, WebKit).
PLAYWRIGHT_BROWSERS="${PLAYWRIGHT_BROWSERS:-}"

ensure_apt

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  log "Node.js not found; installing Node.js before Playwright."
  bash "$SCRIPT_DIR/install-node.sh"
fi

require_command node
require_command npm

playwright_browsers_present() {
  local cache_dir
  cache_dir="$(target_home)/.cache/ms-playwright"
  [[ -d "$cache_dir" ]] && [[ -n "$(ls -A "$cache_dir" 2>/dev/null || true)" ]]
}

if command -v playwright >/dev/null 2>&1 && playwright_browsers_present; then
  log "Playwright is already installed: $(playwright --version 2>&1 | sed -n '1p')"
  exit 0
fi

if ! command -v playwright >/dev/null 2>&1; then
  log "Installing @playwright/test globally via npm."
  run_sudo npm install -g @playwright/test@latest
  hash -r 2>/dev/null || true
fi

if ! command -v playwright >/dev/null 2>&1; then
  fail "npm install finished but 'playwright' was not found on PATH"
fi

log "Installing Playwright OS dependencies (requires sudo)."
# shellcheck disable=SC2086
run_sudo playwright install-deps $PLAYWRIGHT_BROWSERS

log "Installing Playwright browsers into $(target_user)'s cache."
# shellcheck disable=SC2086
run_as_target_user playwright install $PLAYWRIGHT_BROWSERS

log "Playwright installed successfully: $(playwright --version 2>&1 | sed -n '1p')"
cat <<'EOF'

Browsers are cached under ~/.cache/ms-playwright.
In a project, prefer a local dependency:

  npm init playwright@latest

Or add @playwright/test as a devDependency and run npx playwright test.
EOF
