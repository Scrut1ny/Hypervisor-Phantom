#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && { echo "Required environment variables not set."; exit 1; }

source "./utils/formatter.sh"
source "./utils/prompter.sh"
source "./utils/packages.sh"

# EDK2/OVMF packages for each distribution
OVMF_PKGS_Arch=(
  edk2-ovmf
  edk2-shell
)

OVMF_PKGS_Debian=(
  ovmf
  qemu-efi-aarch64
  qemu-efi
)

OVMF_PKGS_openSUSE=(
  ovmf
  qemu-ovmf-x86_64
)

OVMF_PKGS_Fedora=(
  edk2-ovmf
  edk2-aarch64
)

# Standard OVMF installation paths for each distribution
get_ovmf_path() {
  case "$DISTRO" in
    Arch)
      echo "/usr/share/edk2/x64"
      ;;
    Debian)
      echo "/usr/share/OVMF"
      ;;
    openSUSE)
      echo "/usr/share/qemu"
      ;;
    Fedora)
      echo "/usr/share/edk2"
      ;;
    *)
      echo "/usr/share/ovmf"
      ;;
  esac
}

cleanup_patched_edk2() {
  fmtr::info "Cleaning up any existing patched EDK2/OVMF installations..."
  
  # Remove patched OVMF files from common locations
  local ovmf_locations=("/usr/share/edk2/x64" "/usr/share/ovmf" "/usr/share/OVMF")
  
  for location in "${ovmf_locations[@]}"; do
    if [ -d "$location" ]; then
      # Check for patched files (qcow2 format and secboot variants)
      local patched_files=()
      
      # Find qcow2 files (created by patched version)
      while IFS= read -r -d '' file; do
        patched_files+=("$file")
      done < <(find "$location" -name "*.qcow2" -type f -print0 2>/dev/null)
      
      # Find secboot files (created by patched version)
      while IFS= read -r -d '' file; do
        patched_files+=("$file")
      done < <(find "$location" -name "*secboot*" -type f -print0 2>/dev/null)
      
      if [ ${#patched_files[@]} -gt 0 ]; then
        fmtr::warn "Found patched OVMF files in $location:"
        for file in "${patched_files[@]}"; do
          fmtr::warn "  - $(basename "$file")"
        done
        
        if prmt::yes_or_no "$(fmtr::ask 'Remove patched OVMF files?')"; then
          fmtr::info "Removing patched OVMF files..."
          for file in "${patched_files[@]}"; do
            sudo rm -f "$file" 2>/dev/null || true
            fmtr::log "Removed: $file"
          done
        else
          fmtr::warn "Keeping patched OVMF files - this may cause VM boot issues!"
        fi
      fi
    fi
  done
  
  # Clean up any leftover EDK2 source directories
  if compgen -G "src/edk2-*" > /dev/null 2>&1; then
    fmtr::info "Cleaning up EDK2 source directories..."
    rm -rf src/edk2-* 2>/dev/null || true
  fi
  
  # Clean up any fake battery ACPI files
  if [ -f "$HOME/fake_battery.aml" ]; then
    fmtr::info "Cleaning up custom ACPI files..."
    rm -f "$HOME/fake_battery.aml" "$HOME/fake_battery.dsl" 2>/dev/null || true
  fi
  
  # Clean up any custom NVRAM files that might be using patched OVMF
  local nvram_dir="/var/lib/libvirt/qemu/nvram"
  if [ -d "$nvram_dir" ]; then
    local secure_vars_files=()
    while IFS= read -r -d '' file; do
      secure_vars_files+=("$file")
    done < <(find "$nvram_dir" -name "*SECURE_VARS*" -type f -print0 2>/dev/null)
    
    if [ ${#secure_vars_files[@]} -gt 0 ]; then
      fmtr::warn "Found custom secure boot NVRAM files:"
      for file in "${secure_vars_files[@]}"; do
        fmtr::warn "  - $(basename "$file")"
      done
      
      if prmt::yes_or_no "$(fmtr::ask 'Remove custom secure boot NVRAM files?')"; then
        fmtr::info "Removing custom NVRAM files..."
        for file in "${secure_vars_files[@]}"; do
          sudo rm -f "$file" 2>/dev/null || true
          fmtr::log "Removed: $file"
        done
      fi
    fi
  fi
}

install_latest_edk2() {
  fmtr::info "Installing latest EDK2/OVMF from package manager..."
  
  case "$DISTRO" in
    Arch)
      # Update package database first
      sudo pacman -Sy &>> "$LOG_FILE" || {
        fmtr::error "Failed to update package database."
        return 1
      }
      
      # Install OVMF packages
      sudo pacman -S --noconfirm "${OVMF_PKGS_Arch[@]}" &>> "$LOG_FILE" || {
        fmtr::fatal "Failed to install OVMF packages."
        exit 1
      }
      ;;
    Debian)
      # Update package database first
      sudo apt update &>> "$LOG_FILE" || {
        fmtr::error "Failed to update package database."
        return 1
      }
      
      # Install OVMF packages
      sudo apt install -y "${OVMF_PKGS_Debian[@]}" &>> "$LOG_FILE" || {
        fmtr::fatal "Failed to install OVMF packages."
        exit 1
      }
      ;;
    openSUSE)
      # Refresh repositories first
      sudo zypper refresh &>> "$LOG_FILE" || {
        fmtr::error "Failed to refresh repositories."
        return 1
      }
      
      # Install OVMF packages
      sudo zypper install -y "${OVMF_PKGS_openSUSE[@]}" &>> "$LOG_FILE" || {
        fmtr::fatal "Failed to install OVMF packages."
        exit 1
      }
      ;;
    Fedora)
      # Install EDK2/OVMF packages
      sudo dnf install -y "${OVMF_PKGS_Fedora[@]}" &>> "$LOG_FILE" || {
        fmtr::fatal "Failed to install EDK2/OVMF packages."
        exit 1
      }
      ;;
    *)
      fmtr::fatal "Unsupported distribution: $DISTRO"
      exit 1
      ;;
  esac

  fmtr::log "EDK2/OVMF latest version successfully installed via package manager."
}

verify_edk2_installation() {
  fmtr::info "Verifying EDK2/OVMF installation..."
  
  local ovmf_path=$(get_ovmf_path)
  local found_files=()
  
  # Look for OVMF files in distribution-specific locations
  case "$DISTRO" in
    Arch)
      if [ -f "/usr/share/edk2/x64/OVMF_CODE.4m.fd" ]; then
        found_files+=("/usr/share/edk2/x64/OVMF_CODE.4m.fd")
      fi
      if [ -f "/usr/share/edk2/x64/OVMF_VARS.4m.fd" ]; then
        found_files+=("/usr/share/edk2/x64/OVMF_VARS.4m.fd")
      fi
      if [ -f "/usr/share/edk2/x64/OVMF.4m.fd" ]; then
        found_files+=("/usr/share/edk2/x64/OVMF.4m.fd")
      fi
      ;;
    Debian)
      if [ -f "/usr/share/OVMF/OVMF_CODE.fd" ]; then
        found_files+=("/usr/share/OVMF/OVMF_CODE.fd")
      fi
      if [ -f "/usr/share/OVMF/OVMF_VARS.fd" ]; then
        found_files+=("/usr/share/OVMF/OVMF_VARS.fd")
      fi
      # Also check for .secboot variants
      if [ -f "/usr/share/OVMF/OVMF_CODE_4M.fd" ]; then
        found_files+=("/usr/share/OVMF/OVMF_CODE_4M.fd")
      fi
      ;;
    openSUSE)
      if [ -f "/usr/share/qemu/ovmf-x86_64-code.bin" ]; then
        found_files+=("/usr/share/qemu/ovmf-x86_64-code.bin")
      fi
      if [ -f "/usr/share/qemu/ovmf-x86_64-vars.bin" ]; then
        found_files+=("/usr/share/qemu/ovmf-x86_64-vars.bin")
      fi
      ;;
    Fedora)
      if [ -f "/usr/share/edk2/ovmf/OVMF_CODE.fd" ]; then
        found_files+=("/usr/share/edk2/ovmf/OVMF_CODE.fd")
      fi
      if [ -f "/usr/share/edk2/ovmf/OVMF_VARS.fd" ]; then
        found_files+=("/usr/share/edk2/ovmf/OVMF_VARS.fd")
      fi
      ;;
  esac

  if [ ${#found_files[@]} -gt 0 ]; then
    fmtr::log "Installation verified successfully!"
    fmtr::log "Found OVMF files:"
    for file in "${found_files[@]}"; do
      if [ -f "$file" ]; then
        local file_size=$(stat -c%s "$file" 2>/dev/null)
        fmtr::log "  - $file (${file_size} bytes)"
      fi
    done
    fmtr::log "OVMF installation path: $ovmf_path"
    
    # Check for additional useful files
    local shell_files=()
    case "$DISTRO" in
      Arch)
        if [ -f "/usr/share/edk2-shell/x64/Shell.efi" ]; then
          shell_files+=("/usr/share/edk2-shell/x64/Shell.efi")
        fi
        if [ -f "/usr/share/edk2-shell/x64/Shell_Full.efi" ]; then
          shell_files+=("/usr/share/edk2-shell/x64/Shell_Full.efi")
        fi
        ;;
      Fedora)
        if [ -f "/usr/share/edk2/ovmf/Shell.efi" ]; then
          shell_files+=("/usr/share/edk2/ovmf/Shell.efi")
        fi
        ;;
    esac
    
    if [ ${#shell_files[@]} -gt 0 ]; then
      fmtr::log "Additional EFI files found:"
      for file in "${shell_files[@]}"; do
        fmtr::log "  - $file"
      done
    fi
    
    # Important note about VM configuration
    fmtr::info "NOTE: Existing VMs may need configuration updates to use the new OVMF files."
    fmtr::info "Check your VM loader paths if you experience boot issues."
    
  else
    fmtr::error "Installation verification failed! No OVMF files found."
    fmtr::error "Expected location: $ovmf_path"
    return 1
  fi
}

main() {
  fmtr::info "Starting latest EDK2/OVMF installation from package manager..."
  
  # Clean up any existing patched installations
  cleanup_patched_edk2
  
  # Install latest EDK2/OVMF via package manager
  install_latest_edk2
  
  # Verify installation
  verify_edk2_installation
  
  fmtr::log "Latest EDK2/OVMF installation completed successfully!"
  fmtr::info "EDK2/OVMF installed via native package manager"
}

main 