#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DD_NAME="install-aws-cli"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

ensure_apt

if command -v aws >/dev/null 2>&1; then
  log "AWS CLI is already installed: $(aws --version 2>&1 | sed -n '1p')"
  exit 0
fi

case "$(dpkg_arch)" in
  amd64)
    AWS_CLI_ARCH="x86_64"
    ;;
  arm64)
    AWS_CLI_ARCH="aarch64"
    ;;
  *)
    fail "AWS CLI installer is available for amd64 and arm64 only. Detected: $(dpkg_arch)"
    ;;
esac

AWS_CLI_ZIP_URL="https://awscli.amazonaws.com/awscli-exe-linux-${AWS_CLI_ARCH}.zip"

# Only touch apt when dependencies are missing. A broken third-party apt
# source (for example Azure CLI on unsupported Ubuntu suites) should not
# block AWS CLI when curl/unzip are already present.
apt_install_missing curl:curl unzip:unzip
require_command curl
require_command unzip

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

log "Installing AWS CLI v2 via official bundled installer (${AWS_CLI_ARCH})."
curl -fsSL "$AWS_CLI_ZIP_URL" -o "$work_dir/awscliv2.zip"
unzip -q "$work_dir/awscliv2.zip" -d "$work_dir"
run_sudo "$work_dir/aws/install"

# Official installer places the binary in /usr/local/bin.
hash -r 2>/dev/null || true
export PATH="/usr/local/bin:${PATH}"

if ! command -v aws >/dev/null 2>&1; then
  fail "AWS CLI install finished but 'aws' was not found on PATH"
fi

log "AWS CLI installed successfully: $(aws --version 2>&1 | sed -n '1p')"
