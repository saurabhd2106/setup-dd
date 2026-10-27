#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DD_NAME="install-playwright-mcp"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

ensure_apt

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  log "Node.js not found; installing Node.js before Playwright MCP."
  bash "$SCRIPT_DIR/install-node.sh"
fi

require_command node
require_command npm

playwright_browsers_present() {
  local cache_dir
  cache_dir="$(target_home)/.cache/ms-playwright"
  [[ -d "$cache_dir" ]] && [[ -n "$(ls -A "$cache_dir" 2>/dev/null || true)" ]]
}

if ! command -v playwright >/dev/null 2>&1 || ! playwright_browsers_present; then
  log "Playwright CLI or browsers missing; running install-playwright.sh first."
  bash "$SCRIPT_DIR/install-playwright.sh"
fi

playwright_mcp_installed() {
  npm list -g --depth=0 @playwright/mcp >/dev/null 2>&1
}

if playwright_mcp_installed; then
  log "Playwright MCP is already installed: $(npm list -g --depth=0 @playwright/mcp 2>/dev/null | sed -n '/@playwright\/mcp@/p' | sed -n '1p')"
  exit 0
fi

log "Installing @playwright/mcp globally via npm."
run_sudo npm install -g @playwright/mcp@latest
hash -r 2>/dev/null || true

if ! playwright_mcp_installed; then
  fail "npm install finished but @playwright/mcp was not found in the global npm packages"
fi

log "Playwright MCP installed successfully: $(npm list -g --depth=0 @playwright/mcp 2>/dev/null | sed -n '/@playwright\/mcp@/p' | sed -n '1p')"
cat <<'EOF'

Add the Playwright MCP server to your MCP client config:

{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}

With Claude Code:

  claude mcp add playwright npx @playwright/mcp@latest

EOF
