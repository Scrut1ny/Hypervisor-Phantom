#!/usr/bin/env bash

# Usage: install_req_pkgs <component_name>
install_req_pkgs() {
  [[ -z "$1" ]] && { fmtr::error "Component name not specified!"; exit 1; }
  local component="$1"

  fmtr::log "Checking for missing $component packages..."

  # Determine package manager commands
  case "$DISTRO" in
    Arch)
      PKG_MANAGER="pacman"
      INSTALL_CMD="sudo pacman -S --noconfirm"
      CHECK_CMD="pacman -Q"
      ;;
    Debian)
      PKG_MANAGER="apt"
      INSTALL_CMD="sudo apt -y install"
      CHECK_CMD="dpkg -l"
      ;;
    openSUSE)
      PKG_MANAGER="zypper"
      INSTALL_CMD="sudo zypper install -y"
      CHECK_CMD="rpm -q"
      ;;
    Fedora)
      PKG_MANAGER="dnf"
      INSTALL_CMD="sudo dnf -yq install"
      CHECK_CMD="rpm -q"
      ;;
    *)
      fmtr::error "Unsupported distribution: $DISTRO."
      exit 1
      ;;
  esac

  # Load required packages from caller's distro-specific array
  local pkg_var="REQUIRED_PKGS_${DISTRO}"
  if [[ ! -v "$pkg_var" ]]; then
    fmtr::error "$component packages undefined for $DISTRO."
    exit 1
  fi
  declare -n REQUIRED_PKGS_REF="$pkg_var"
  local REQUIRED_PKGS=("${REQUIRED_PKGS_REF[@]}")

  # Check for missing packages
  local MISSING_PKGS=()
  for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! $CHECK_CMD "$pkg" &>/dev/null; then
      MISSING_PKGS+=("$pkg")
    fi
  done

  if [[ ${#MISSING_PKGS[@]} -eq 0 ]]; then
    fmtr::log "All $component packages are already installed."
    return 0
  fi

  # Handle installation
  fmtr::warn "Missing $component packages: ${MISSING_PKGS[*]}"
  if prmt::yes_or_no "$(fmtr::ask "Install missing $component packages?")"; then
    if ! $INSTALL_CMD "${MISSING_PKGS[@]}" &>> "$LOG_FILE"; then
      fmtr::error "Failed to install $component packages"
      exit 1
    fi
    fmtr::log "Installed: ${MISSING_PKGS[*]}"
  else
    fmtr::log "Exiting due to missing $component packages."
    exit 1
  fi
}
