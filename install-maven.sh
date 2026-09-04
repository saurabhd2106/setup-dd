#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DD_NAME="install-maven"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

ensure_apt

if command -v mvn >/dev/null 2>&1; then
  log "Maven is already installed: $(mvn --version 2>&1 | sed -n '1p')"
  exit 0
fi

if ! command -v java >/dev/null 2>&1; then
  log "Java not found; installing Java before Maven."
  bash "$SCRIPT_DIR/install-java.sh"
fi

apt_install maven

log "Maven installed successfully: $(mvn --version 2>&1 | sed -n '1p')"
