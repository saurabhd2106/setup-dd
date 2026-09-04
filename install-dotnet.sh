#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DD_NAME="install-dotnet"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

# Default to the LTS SDK available on Ubuntu 22.04 and 24.04 without a PPA.
# On 24.04+, override with DOTNET_SDK_PACKAGE=dotnet-sdk-10.0 if desired.
DOTNET_SDK_PACKAGE="${DOTNET_SDK_PACKAGE:-dotnet-sdk-8.0}"

ensure_apt

if command -v dotnet >/dev/null 2>&1; then
  log ".NET SDK is already installed: $(dotnet --version 2>&1 | sed -n '1p')"
  exit 0
fi

apt_install "$DOTNET_SDK_PACKAGE"

if ! command -v dotnet >/dev/null 2>&1; then
  fail ".NET SDK package installed but 'dotnet' was not found on PATH"
fi

log ".NET SDK installed successfully: $(dotnet --version 2>&1 | sed -n '1p')"
