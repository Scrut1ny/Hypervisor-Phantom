#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && { echo "Required environment variables not set."; exit 1; }

source "./utils/formatter.sh"
source "./utils/prompter.sh"
source "./utils/packages.sh"

# QEMU packages for each distribution
QEMU_PKGS_Arch=(
  qemu-full
  qemu-desktop
  qemu-system-x86
  qemu-img
)

QEMU_PKGS_Debian=(
  qemu-system
  qemu-system-x86
  qemu-utils
  qemu-block-extra
  spice-client-gtk
  libusb-1.0-0
)

QEMU_PKGS_openSUSE=(
  qemu
  qemu-x86
  qemu-tools
  qemu-ui-gtk
  qemu-ui-spice-core
  qemu-hw-usb-redirect
)

QEMU_PKGS_Fedora=(
  qemu-system-x86
  qemu-img
  qemu-ui-gtk
  qemu-device-usb-redirect
  spice-gtk3
)

cleanup_patched_qemu() {
  fmtr::info "Cleaning up any existing patched QEMU installations..."
  
  # Remove manually compiled QEMU from /usr/local
  if [ -f "/usr/local/bin/qemu-system-x86_64" ]; then
    fmtr::warn "Found patched QEMU installation in /usr/local/"
    if prmt::yes_or_no "$(fmtr::ask 'Remove patched QEMU installation?')"; then
      fmtr::info "Removing patched QEMU binaries..."
      sudo rm -f /usr/local/bin/qemu-* 2>/dev/null || true
      
      fmtr::info "Removing patched QEMU libraries and data..."
      sudo rm -rf /usr/local/libexec/qemu-* 2>/dev/null || true
      sudo rm -rf /usr/local/share/qemu/ 2>/dev/null || true
      sudo rm -rf /usr/local/share/doc/qemu/ 2>/dev/null || true
      
      fmtr::info "Removing patched QEMU man pages..."
      sudo rm -f /usr/local/man/man*/qemu* 2>/dev/null || true
      sudo rm -f /usr/local/man/man*/*qemu* 2>/dev/null || true
      
      fmtr::info "Removing patched QEMU includes and icons..."
      sudo rm -f /usr/local/include/qemu-* 2>/dev/null || true
      sudo rm -f /usr/local/share/applications/qemu.desktop 2>/dev/null || true
      sudo rm -rf /usr/local/share/icons/hicolor/*/apps/qemu.* 2>/dev/null || true
      
      fmtr::info "Removing patched QEMU locales..."
      sudo rm -f /usr/local/share/locale/*/LC_MESSAGES/qemu.mo 2>/dev/null || true
      
      fmtr::log "Patched QEMU installation removed."
    else
      fmtr::warn "Keeping patched QEMU - this may cause conflicts!"
    fi
  fi
  
  # Clean up any leftover source directories
  if compgen -G "src/qemu-*" > /dev/null 2>&1; then
    fmtr::info "Cleaning up QEMU source directories..."
    rm -rf src/qemu-* 2>/dev/null || true
  fi
  
  # Clean up any leftover source files
  if compgen -G "src/qemu-*.tar.*" > /dev/null 2>&1; then
    fmtr::info "Cleaning up QEMU source archives..."
    rm -f src/qemu-*.tar.* src/qemu-*.sig 2>/dev/null || true
  fi
}

install_latest_qemu() {
  fmtr::info "Installing latest QEMU from package manager..."
  
  case "$DISTRO" in
    Arch)
      # Update package database first
      sudo pacman -Sy &>> "$LOG_FILE" || {
        fmtr::error "Failed to update package database."
        return 1
      }
      
      # Install QEMU packages
      sudo pacman -S --noconfirm "${QEMU_PKGS_Arch[@]}" &>> "$LOG_FILE" || {
        fmtr::fatal "Failed to install QEMU packages."
        exit 1
      }
      ;;
    Debian)
      # Update package database first
      sudo apt update &>> "$LOG_FILE" || {
        fmtr::error "Failed to update package database."
        return 1
      }
      
      # Install QEMU packages
      sudo apt install -y "${QEMU_PKGS_Debian[@]}" &>> "$LOG_FILE" || {
        fmtr::fatal "Failed to install QEMU packages."
        exit 1
      }
      ;;
    openSUSE)
      # Refresh repositories first
      sudo zypper refresh &>> "$LOG_FILE" || {
        fmtr::error "Failed to refresh repositories."
        return 1
      }
      
      # Install QEMU packages
      sudo zypper install -y "${QEMU_PKGS_openSUSE[@]}" &>> "$LOG_FILE" || {
        fmtr::fatal "Failed to install QEMU packages."
        exit 1
      }
      ;;
    Fedora)
      # Install QEMU packages
      sudo dnf install -y "${QEMU_PKGS_Fedora[@]}" &>> "$LOG_FILE" || {
        fmtr::fatal "Failed to install QEMU packages."
        exit 1
      }
      ;;
    *)
      fmtr::fatal "Unsupported distribution: $DISTRO"
      exit 1
      ;;
  esac

  fmtr::log "QEMU latest version successfully installed via package manager."
}

verify_qemu_installation() {
  fmtr::info "Verifying QEMU installation..."
  
  # Check for qemu-system-x86_64 in common locations
  local qemu_binary=""
  if command -v qemu-system-x86_64 &>/dev/null; then
    qemu_binary=$(command -v qemu-system-x86_64)
  elif [ -x "/usr/bin/qemu-system-x86_64" ]; then
    qemu_binary="/usr/bin/qemu-system-x86_64"
  elif [ -x "/usr/local/bin/qemu-system-x86_64" ]; then
    qemu_binary="/usr/local/bin/qemu-system-x86_64"
  fi

  if [ -n "$qemu_binary" ] && [ -x "$qemu_binary" ]; then
    local version=$("$qemu_binary" --version 2>/dev/null | head -n1)
    fmtr::log "Installation verified successfully!"
    fmtr::log "QEMU binary: $qemu_binary"
    fmtr::log "Version: $version"
    
    # Check for KVM support
    if [ -r /dev/kvm ]; then
      fmtr::log "KVM support: Available"
    else
      fmtr::warn "KVM support: Not available (check permissions or virtualization settings)"
    fi
    
    # Warn if still using patched version
    if [[ "$qemu_binary" == "/usr/local/bin/qemu-system-x86_64" ]]; then
      fmtr::warn "Still using patched QEMU version from /usr/local/bin/"
      fmtr::warn "Consider removing it to use the package manager version"
    fi
  else
    fmtr::error "Installation verification failed! QEMU binary not found."
    return 1
  fi
}

main() {
  fmtr::info "Starting latest QEMU installation from package manager..."
  
  # Clean up any existing patched installations
  cleanup_patched_qemu
  
  # Install latest QEMU via package manager
  install_latest_qemu
  
  # Verify installation
  verify_qemu_installation
  
  fmtr::log "Latest QEMU installation completed successfully!"
  fmtr::info "QEMU installed via native package manager"
}

main 