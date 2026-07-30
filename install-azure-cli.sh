#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DD_NAME="install-azure-cli"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

ensure_apt

if command -v az >/dev/null 2>&1; then
  log "Azure CLI is already installed: $(az version --query '"azure-cli"' -o tsv 2>/dev/null || az --version | sed -n '1p')"
  exit 0
fi

install_gpg_key \
  "https://packages.microsoft.com/keys/microsoft.asc" \
  "/etc/apt/keyrings/microsoft.gpg"

write_apt_source \
  "deb [arch=$(dpkg_arch) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(ubuntu_codename) main" \
  "/etc/apt/sources.list.d/azure-cli.list"

apt_install azure-cli

log "Azure CLI installed successfully: $(az version --query '"azure-cli"' -o tsv 2>/dev/null || az --version | sed -n '1p')"
