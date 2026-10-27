#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DD_NAME="install-dotnet"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

# Prefer the newest SDK available from Ubuntu apt without a PPA.
# Ubuntu 24.04+ typically has dotnet-sdk-10.0; 22.04 commonly has 8.0.
# Override explicitly with DOTNET_SDK_PACKAGE=dotnet-sdk-8.0 (or another package).
resolve_dotnet_sdk_package() {
  if [[ -n "${DOTNET_SDK_PACKAGE:-}" ]]; then
    printf '%s\n' "$DOTNET_SDK_PACKAGE"
    return 0
  fi

  apt_update_once
  local candidate
  for candidate in dotnet-sdk-10.0 dotnet-sdk-9.0 dotnet-sdk-8.0; do
    if apt-cache show "$candidate" >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  printf 'dotnet-sdk-8.0\n'
}

ensure_apt

if command -v dotnet >/dev/null 2>&1; then
  log ".NET SDK is already installed: $(dotnet --version 2>&1 | sed -n '1p')"
  exit 0
fi

DOTNET_SDK_PACKAGE="$(resolve_dotnet_sdk_package)"
log "Using .NET SDK package: $DOTNET_SDK_PACKAGE"
apt_install "$DOTNET_SDK_PACKAGE"

if ! command -v dotnet >/dev/null 2>&1; then
  fail ".NET SDK package installed but 'dotnet' was not found on PATH"
fi

log ".NET SDK installed successfully: $(dotnet --version 2>&1 | sed -n '1p')"
