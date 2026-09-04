#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DD_NAME="install-ruby"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

ensure_apt

if command -v ruby >/dev/null 2>&1 && command -v gem >/dev/null 2>&1; then
  log "Ruby is already installed: $(ruby --version 2>&1 | sed -n '1p')"
else
  apt_install ruby-full build-essential
  log "Ruby installed successfully: $(ruby --version 2>&1 | sed -n '1p')"
fi

require_command ruby
require_command gem

if command -v bundler >/dev/null 2>&1; then
  log "Bundler is already installed: $(bundler --version 2>&1 | sed -n '1p')"
else
  log "Installing Bundler via gem into /usr/local/bin."
  run_sudo gem install bundler --no-document --bindir /usr/local/bin
  hash -r 2>/dev/null || true
  export PATH="/usr/local/bin:${PATH}"
  if ! command -v bundler >/dev/null 2>&1; then
    fail "Bundler install finished but 'bundler' was not found on PATH"
  fi
  log "Bundler installed successfully: $(bundler --version 2>&1 | sed -n '1p')"
fi
