#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DD_NAME="install-databricks-cli"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

DATABRICKS_INSTALL_URL="${DATABRICKS_INSTALL_URL:-https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh}"

ensure_apt

if command -v databricks >/dev/null 2>&1; then
  log "Databricks CLI is already installed: $(databricks -v 2>&1 | sed -n '1p')"
  exit 0
fi

# Only touch apt when dependencies are missing. A broken third-party apt
# source (for example Azure CLI on unsupported Ubuntu suites) should not
# block Databricks when curl/unzip are already present.
apt_install_missing curl:curl unzip:unzip
require_command curl
require_command unzip

log "Installing Databricks CLI via official setup script."
curl -fsSL "$DATABRICKS_INSTALL_URL" | run_sudo sh

# Official installer may place the binary in /usr/local/bin.
hash -r 2>/dev/null || true
export PATH="/usr/local/bin:${PATH}"

if ! command -v databricks >/dev/null 2>&1; then
  fail "Databricks CLI install finished but 'databricks' was not found on PATH"
fi

log "Databricks CLI installed successfully: $(databricks -v 2>&1 | sed -n '1p')"
