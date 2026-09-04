#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DD_NAME="install-gradle"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

GRADLE_VERSION="${GRADLE_VERSION:-9.7.1}"
GRADLE_INSTALL_DIR="/opt/gradle"
GRADLE_HOME="${GRADLE_INSTALL_DIR}/gradle-${GRADLE_VERSION}"
GRADLE_ZIP_URL="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"

ensure_apt

gradle_version_line() {
  gradle --version 2>&1 | sed -n '/^Gradle /p' | sed -n '1p'
}

if command -v gradle >/dev/null 2>&1; then
  log "Gradle is already installed: $(gradle_version_line)"
  exit 0
fi

if ! command -v java >/dev/null 2>&1; then
  log "Java not found; installing Java before Gradle."
  bash "$SCRIPT_DIR/install-java.sh"
fi

apt_install_missing curl:curl unzip:unzip
require_command curl
require_command unzip

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

log "Installing Gradle ${GRADLE_VERSION} via official binary distribution."
curl -fsSL "$GRADLE_ZIP_URL" -o "$work_dir/gradle.zip"
run_sudo mkdir -p "$GRADLE_INSTALL_DIR"
run_sudo unzip -q "$work_dir/gradle.zip" -d "$GRADLE_INSTALL_DIR"
run_sudo ln -sf "${GRADLE_HOME}/bin/gradle" /usr/local/bin/gradle

hash -r 2>/dev/null || true
export PATH="/usr/local/bin:${PATH}"

if ! command -v gradle >/dev/null 2>&1; then
  fail "Gradle install finished but 'gradle' was not found on PATH"
fi

log "Gradle installed successfully: $(gradle_version_line)"
