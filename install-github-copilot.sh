#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DD_NAME="install-github-copilot"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

COPILOT_INSTALL_URL="${COPILOT_INSTALL_URL:-https://gh.io/copilot-install}"
# Optional: latest (default), prerelease, or an exact version such as v0.0.369
COPILOT_VERSION="${COPILOT_VERSION:-}"

ensure_apt

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  fail "run this installer as a regular user (not root). GitHub Copilot CLI installs under ~/.local"
fi

export PATH="${HOME}/.local/bin:${PATH}"

if command -v copilot >/dev/null 2>&1; then
  log "GitHub Copilot CLI is already installed: $(copilot --version 2>&1 | sed -n '1p')"
  exit 0
fi

apt_install_missing curl:curl
require_command curl

log "Installing GitHub Copilot CLI via official installer."
if [[ -n "$COPILOT_VERSION" ]]; then
  curl -fsSL "$COPILOT_INSTALL_URL" | VERSION="$COPILOT_VERSION" bash
else
  curl -fsSL "$COPILOT_INSTALL_URL" | bash
fi

hash -r 2>/dev/null || true
export PATH="${HOME}/.local/bin:${PATH}"
ensure_profile_path "${HOME}/.local/bin" "setup-dd install-github-copilot"

if ! command -v copilot >/dev/null 2>&1; then
  fail "GitHub Copilot CLI install finished but 'copilot' was not found on PATH. Open a new shell or run: export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

log "GitHub Copilot CLI installed successfully: $(copilot --version 2>&1 | sed -n '1p')"
cat <<'EOF'

Authenticate with your GitHub account (requires an active Copilot subscription):

  copilot
  # or: copilot login

EOF
