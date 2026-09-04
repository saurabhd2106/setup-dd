#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DD_NAME="install-php"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

COMPOSER_INSTALLER_URL="${COMPOSER_INSTALLER_URL:-https://getcomposer.org/installer}"

ensure_apt

if command -v php >/dev/null 2>&1; then
  log "PHP is already installed: $(php --version 2>&1 | sed -n '1p')"
else
  apt_install php-cli php-mbstring php-xml php-curl php-zip unzip
  log "PHP installed successfully: $(php --version 2>&1 | sed -n '1p')"
fi

missing_php_pkgs=()
for pkg in php-mbstring php-xml php-curl php-zip unzip; do
  if ! is_package_installed "$pkg"; then
    missing_php_pkgs+=("$pkg")
  fi
done
if [[ "${#missing_php_pkgs[@]}" -gt 0 ]]; then
  apt_install "${missing_php_pkgs[@]}"
fi

require_command php

if command -v composer >/dev/null 2>&1; then
  log "Composer is already installed: $(composer --version 2>&1 | sed -n '1p')"
  exit 0
fi

apt_install_missing curl:curl
require_command curl

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

log "Installing Composer into /usr/local/bin."
curl -fsSL "$COMPOSER_INSTALLER_URL" -o "$work_dir/composer-setup.php"
run_sudo php "$work_dir/composer-setup.php" --install-dir=/usr/local/bin --filename=composer

hash -r 2>/dev/null || true
export PATH="/usr/local/bin:${PATH}"

if ! command -v composer >/dev/null 2>&1; then
  fail "Composer install finished but 'composer' was not found on PATH"
fi

log "Composer installed successfully: $(composer --version 2>&1 | sed -n '1p')"
