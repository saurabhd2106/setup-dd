#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DD_NAME="install-claude-code"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

CLAUDE_CODE_INSTALL_URL="${CLAUDE_CODE_INSTALL_URL:-https://claude.ai/install.sh}"
# Optional: stable, latest, or an exact version such as 2.1.89
CLAUDE_CODE_CHANNEL="${CLAUDE_CODE_CHANNEL:-}"

ensure_apt

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  fail "run this installer as a regular user (not root). Claude Code installs under ~/.local"
fi

export PATH="${HOME}/.local/bin:${PATH}"

if command -v claude >/dev/null 2>&1; then
  log "Claude Code is already installed: $(claude --version 2>&1 | sed -n '1p')"
  exit 0
fi

apt_install_missing curl:curl
require_command curl

log "Installing Claude Code via Anthropic's native installer."
if [[ -n "$CLAUDE_CODE_CHANNEL" ]]; then
  curl -fsSL "$CLAUDE_CODE_INSTALL_URL" | bash -s -- "$CLAUDE_CODE_CHANNEL"
else
  curl -fsSL "$CLAUDE_CODE_INSTALL_URL" | bash
fi

hash -r 2>/dev/null || true
export PATH="${HOME}/.local/bin:${PATH}"

ensure_local_bin_path() {
  local line='export PATH="$HOME/.local/bin:$PATH"'
  local profile

  case ":${PATH}:" in
    *:"${HOME}/.local/bin":*) ;;
    *) export PATH="${HOME}/.local/bin:${PATH}" ;;
  esac

  for profile in "${HOME}/.bashrc" "${HOME}/.profile"; do
    if [[ -f "$profile" ]] && grep -Fq '.local/bin' "$profile" 2>/dev/null; then
      return 0
    fi
  done

  if [[ -f "${HOME}/.bashrc" ]]; then
    profile="${HOME}/.bashrc"
  else
    profile="${HOME}/.profile"
    touch "$profile"
  fi

  log "Adding ~/.local/bin to PATH in $profile"
  {
    printf '\n# Added by setup-dd install-claude-code\n'
    printf '%s\n' "$line"
  } >>"$profile"
}

ensure_local_bin_path

if ! command -v claude >/dev/null 2>&1; then
  fail "Claude Code install finished but 'claude' was not found on PATH. Open a new shell or run: export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

log "Claude Code installed successfully: $(claude --version 2>&1 | sed -n '1p')"
cat <<'EOF'

Authenticate with your Anthropic account (Pro/Max/Team/Enterprise or Console API billing):

  claude

EOF
