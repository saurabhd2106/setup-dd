#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DD_NAME="install-go"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

GO_VERSION="${GO_VERSION:-1.27.1}"
GO_INSTALL_DIR="/usr/local/go"

go_arch() {
  case "$(dpkg_arch)" in
    amd64) printf 'amd64\n' ;;
    arm64) printf 'arm64\n' ;;
    *) fail "unsupported architecture for Go install: $(dpkg_arch) (need amd64 or arm64)" ;;
  esac
}

ensure_apt

if command -v go >/dev/null 2>&1; then
  log "Go is already installed: $(go version 2>&1 | sed -n '1p')"
  exit 0
fi

apt_install_missing curl:curl tar:tar
require_command curl
require_command tar

arch="$(go_arch)"
tarball="go${GO_VERSION}.linux-${arch}.tar.gz"
url="https://go.dev/dl/${tarball}"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

log "Installing Go ${GO_VERSION} via official tarball (${arch})."
curl -fsSL "$url" -o "$work_dir/$tarball"
run_sudo rm -rf "$GO_INSTALL_DIR"
run_sudo tar -C /usr/local -xzf "$work_dir/$tarball"
run_sudo ln -sf "${GO_INSTALL_DIR}/bin/go" /usr/local/bin/go
run_sudo ln -sf "${GO_INSTALL_DIR}/bin/gofmt" /usr/local/bin/gofmt

hash -r 2>/dev/null || true
export PATH="/usr/local/bin:${PATH}"

if ! command -v go >/dev/null 2>&1; then
  fail "Go install finished but 'go' was not found on PATH"
fi

log "Go installed successfully: $(go version 2>&1 | sed -n '1p')"
