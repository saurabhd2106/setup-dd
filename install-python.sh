#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DD_NAME="install-python"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

ensure_apt

if command -v python3 >/dev/null 2>&1 && command -v pip3 >/dev/null 2>&1; then
  log "Python is already installed: $(python3 --version 2>&1), $(pip3 --version 2>&1 | sed -n '1p')"
else
  apt_install python3 python3-pip python3-venv
  log "Python installed successfully: $(python3 --version 2>&1), $(pip3 --version 2>&1 | sed -n '1p')"
fi

# Ensure venv support even if python3/pip were already present.
if ! is_package_installed python3-venv; then
  apt_install python3-venv
fi

if command -v pipx >/dev/null 2>&1; then
  log "pipx is already installed: $(pipx --version 2>&1 | sed -n '1p')"
else
  apt_install pipx
  log "pipx installed successfully: $(pipx --version 2>&1 | sed -n '1p')"
fi

log "Ensuring pipx PATH for $(target_user)."
run_as_target_user pipx ensurepath
ensure_profile_path "$(target_home)/.local/bin" "setup-dd install-python"

export PATH="$(target_home)/.local/bin:${PATH}"

if run_as_target_user bash -lc 'command -v poetry >/dev/null 2>&1'; then
  log "Poetry is already installed: $(run_as_target_user bash -lc 'poetry --version' 2>&1 | sed -n '1p')"
else
  log "Installing Poetry via pipx."
  run_as_target_user pipx install poetry
  log "Poetry installed successfully: $(run_as_target_user bash -lc 'poetry --version' 2>&1 | sed -n '1p')"
fi

if command -v uv >/dev/null 2>&1; then
  log "uv is already installed: $(uv --version 2>&1 | sed -n '1p')"
else
  apt_install_missing curl:curl
  require_command curl
  log "Installing uv system-wide into /usr/local/bin."
  curl -LsSf https://astral.sh/uv/install.sh | run_sudo env UV_UNMANAGED_INSTALL=/usr/local/bin sh
  hash -r 2>/dev/null || true
  export PATH="/usr/local/bin:${PATH}"
  if ! command -v uv >/dev/null 2>&1; then
    fail "uv install finished but 'uv' was not found on PATH"
  fi
  log "uv installed successfully: $(uv --version 2>&1 | sed -n '1p')"
fi
