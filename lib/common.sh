#!/usr/bin/env bash

if [[ "${SETUP_DD_COMMON_LOADED:-false}" == "true" ]]; then
  return 0
fi
SETUP_DD_COMMON_LOADED=true

SETUP_DD_NAME="${SETUP_DD_NAME:-setup-dd}"
APT_UPDATED="${APT_UPDATED:-false}"

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  SUDO=()
else
  SUDO=(sudo)
fi

log() {
  printf '[%s] %s\n' "$SETUP_DD_NAME" "$1"
}

warn() {
  printf '[%s] Warning: %s\n' "$SETUP_DD_NAME" "$1" >&2
}

fail() {
  printf '[%s] Error: %s\n' "$SETUP_DD_NAME" "$1" >&2
  exit 1
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "required command not found: $1"
  fi
}

run_sudo() {
  "${SUDO[@]}" "$@"
}

ensure_linux() {
  if [[ "$(uname -s)" != "Linux" ]]; then
    fail "this script is intended for Linux. Detected: $(uname -s)"
  fi
}

ensure_ubuntu() {
  ensure_linux

  if [[ ! -r /etc/os-release ]]; then
    fail "cannot read /etc/os-release to detect the Linux distribution"
  fi

  # shellcheck disable=SC1091
  . /etc/os-release

  if [[ "${ID:-}" != "ubuntu" ]]; then
    fail "this setup is intended for Ubuntu. Detected: ${PRETTY_NAME:-unknown}"
  fi
}

ensure_apt() {
  ensure_ubuntu
  require_command apt-get
  require_command dpkg
  require_command dpkg-query

  if [[ "${#SUDO[@]}" -gt 0 ]]; then
    require_command sudo
  fi
}

apt_suite_exists() {
  local repo_url="$1"
  local suite="$2"

  if ! command -v curl >/dev/null 2>&1; then
    return 1
  fi

  curl -fsI --connect-timeout 5 --max-time 15 "${repo_url%/}/dists/${suite}/Release" >/dev/null 2>&1
}

resolve_apt_suite() {
  local repo_url="$1"
  shift
  local suite

  for suite in "$@"; do
    [[ -n "$suite" ]] || continue
    if apt_suite_exists "$repo_url" "$suite"; then
      printf '%s\n' "$suite"
      return 0
    fi
  done

  return 1
}

azure_cli_apt_suite() {
  local preferred fallback
  preferred="$(ubuntu_codename)"

  if fallback="$(resolve_apt_suite "https://packages.microsoft.com/repos/azure-cli" "$preferred" noble jammy focal)"; then
    printf '%s\n' "$fallback"
    return 0
  fi

  case "$preferred" in
    noble|jammy|focal)
      printf '%s\n' "$preferred"
      return 0
      ;;
    resolute|questing|plucky)
      # Microsoft has not published suites for these Ubuntu releases yet.
      printf 'noble\n'
      return 0
      ;;
  esac

  return 1
}

repair_azure_cli_apt_source() {
  local source_path="/etc/apt/sources.list.d/azure-cli.list"
  local keyring_path="/etc/apt/keyrings/microsoft.gpg"
  local preferred suite source_line

  [[ -e "$source_path" ]] || return 0

  preferred="$(ubuntu_codename)"
  if ! suite="$(azure_cli_apt_suite)"; then
    warn "Azure CLI apt suite is unavailable; disabling $source_path so apt update can continue."
    run_sudo mv -f "$source_path" "${source_path}.disabled"
    APT_UPDATED=false
    return 0
  fi

  if [[ "$suite" != "$preferred" ]]; then
    warn "Ubuntu '$preferred' has no Azure CLI apt suite yet; using '$suite' instead."
  fi

  if [[ ! -s "$keyring_path" ]]; then
    warn "Azure CLI apt keyring missing at $keyring_path; disabling $source_path so apt update can continue."
    run_sudo mv -f "$source_path" "${source_path}.disabled"
    APT_UPDATED=false
    return 0
  fi

  source_line="deb [arch=$(dpkg_arch) signed-by=${keyring_path}] https://packages.microsoft.com/repos/azure-cli/ ${suite} main"
  if [[ -r "$source_path" ]] && grep -Fxq "$source_line" "$source_path"; then
    return 0
  fi

  write_apt_source "$source_line" "$source_path"
}

apt_update_once() {
  ensure_apt

  if [[ "$APT_UPDATED" == "true" ]]; then
    return 0
  fi

  repair_azure_cli_apt_source

  log "Updating apt package indexes."
  run_sudo apt-get update
  APT_UPDATED=true
}

apt_install() {
  ensure_apt

  if [[ "$#" -eq 0 ]]; then
    return 0
  fi

  apt_update_once
  log "Installing packages: $*"
  run_sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}

# Install apt packages only when the matching command is missing.
# Usage: apt_install_missing curl:curl unzip:unzip
apt_install_missing() {
  local spec package command_name
  local -a missing=()

  for spec in "$@"; do
    package="${spec%%:*}"
    command_name="${spec#*:}"
    if [[ "$command_name" == "$spec" ]]; then
      command_name="$package"
    fi
    if ! command -v "$command_name" >/dev/null 2>&1; then
      missing+=("$package")
    fi
  done

  if [[ "${#missing[@]}" -eq 0 ]]; then
    return 0
  fi

  apt_install "${missing[@]}"
}

ensure_apt_prereqs() {
  apt_install ca-certificates curl gnupg
}

is_package_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

dpkg_arch() {
  dpkg --print-architecture
}

ubuntu_codename() {
  # shellcheck disable=SC1091
  . /etc/os-release

  if [[ -n "${VERSION_CODENAME:-}" ]]; then
    printf '%s\n' "$VERSION_CODENAME"
    return 0
  fi

  require_command lsb_release
  lsb_release -cs
}

install_gpg_key() {
  local key_url="$1"
  local keyring_path="$2"

  ensure_apt_prereqs

  if [[ -s "$keyring_path" ]]; then
    log "GPG key already exists: $keyring_path"
    return 0
  fi

  local tmp_file
  tmp_file="$(mktemp)"

  log "Installing GPG key: $keyring_path"
  curl -fsSL "$key_url" | gpg --dearmor >"$tmp_file"
  run_sudo install -d -m 0755 "$(dirname "$keyring_path")"
  run_sudo install -m 0644 "$tmp_file" "$keyring_path"
  rm -f "$tmp_file"
}

write_apt_source() {
  local source_line="$1"
  local source_path="$2"
  local tmp_file

  if [[ -r "$source_path" ]] && grep -Fxq "$source_line" "$source_path"; then
    log "Apt source already configured: $source_path"
    return 0
  fi

  tmp_file="$(mktemp)"
  printf '%s\n' "$source_line" >"$tmp_file"

  log "Configuring apt source: $source_path"
  run_sudo install -d -m 0755 "$(dirname "$source_path")"
  run_sudo install -m 0644 "$tmp_file" "$source_path"
  rm -f "$tmp_file"

  APT_UPDATED=false
}

target_user() {
  printf '%s\n' "${SETUP_DD_USER:-${SUDO_USER:-${USER}}}"
}

print_command_version() {
  local command_name="$1"
  shift

  if command -v "$command_name" >/dev/null 2>&1; then
    "$command_name" "$@" 2>&1 | sed -n '1p'
  else
    printf '%s not found\n' "$command_name"
  fi
}
