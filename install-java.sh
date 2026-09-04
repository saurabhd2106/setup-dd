#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DD_NAME="install-java"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

JAVA_PACKAGE="${JAVA_PACKAGE:-openjdk-21-jdk}"

ensure_apt

if command -v java >/dev/null 2>&1 && command -v javac >/dev/null 2>&1; then
  log "Java is already installed: $(java -version 2>&1 | sed -n '1p')"
  exit 0
fi

apt_install "$JAVA_PACKAGE"

log "Java installed successfully: $(java -version 2>&1 | sed -n '1p')"
