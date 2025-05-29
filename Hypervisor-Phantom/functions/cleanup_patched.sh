#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && { echo "Required environment variables not set."; exit 1; }

source "./utils/formatter.sh"
source "./utils/prompter.sh"

cleanup_all_patched() {
  fmtr::box_text "Complete Patched Installation Cleanup"
  
  fmtr::info "This script will remove ALL patched QEMU and EDK2 installations."
  fmtr::warn "This includes manually compiled versions and custom files."
  fmtr::warn "Make sure you have backups if you need any custom configurations."
  
  if ! prmt::yes_or_no "$(fmtr::ask 'Continue with complete cleanup?')"; then
    fmtr::info "Cleanup cancelled."
    exit 0
  fi
}

cleanup_patched_qemu() {
  fmtr::info "=== Cleaning up patched QEMU installations ==="
  
  # Remove manually compiled QEMU from /usr/local
  if [ -f "/usr/local/bin/qemu-system-x86_64" ]; then
    fmtr::warn "Found patched QEMU installation in /usr/local/"
    
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
    fmtr::log "No patched QEMU installation found in /usr/local/"
  fi
  
  # Clean up QEMU source directories
  if compgen -G "src/qemu-*" > /dev/null 2>&1; then
    fmtr::info "Cleaning up QEMU source directories..."
    rm -rf src/qemu-* 2>/dev/null || true
    fmtr::log "QEMU source directories removed."
  fi
  
  # Clean up QEMU source files
  if compgen -G "src/qemu-*.tar.*" > /dev/null 2>&1; then
    fmtr::info "Cleaning up QEMU source archives..."
    rm -f src/qemu-*.tar.* src/qemu-*.sig 2>/dev/null || true
    fmtr::log "QEMU source archives removed."
  fi
}

cleanup_patched_edk2() {
  fmtr::info "=== Cleaning up patched EDK2/OVMF installations ==="
  
  # Remove patched OVMF files from common locations
  local ovmf_locations=("/usr/share/edk2/x64" "/usr/share/ovmf" "/usr/share/OVMF")
  local total_removed=0
  
  for location in "${ovmf_locations[@]}"; do
    if [ -d "$location" ]; then
      # Find and remove qcow2 files (created by patched version)
      local qcow2_files=()
      while IFS= read -r -d '' file; do
        qcow2_files+=("$file")
      done < <(find "$location" -name "*.qcow2" -type f -print0 2>/dev/null)
      
      if [ ${#qcow2_files[@]} -gt 0 ]; then
        fmtr::info "Removing qcow2 OVMF files from $location..."
        for file in "${qcow2_files[@]}"; do
          sudo rm -f "$file" 2>/dev/null || true
          fmtr::log "Removed: $(basename "$file")"
          ((total_removed++))
        done
      fi
      
      # Find and remove secboot files (created by patched version)
      local secboot_files=()
      while IFS= read -r -d '' file; do
        secboot_files+=("$file")
      done < <(find "$location" -name "*secboot*" -type f -print0 2>/dev/null)
      
      if [ ${#secboot_files[@]} -gt 0 ]; then
        fmtr::info "Removing secure boot OVMF files from $location..."
        for file in "${secboot_files[@]}"; do
          sudo rm -f "$file" 2>/dev/null || true
          fmtr::log "Removed: $(basename "$file")"
          ((total_removed++))
        done
      fi
    fi
  done
  
  if [ $total_removed -eq 0 ]; then
    fmtr::log "No patched OVMF files found."
  else
    fmtr::log "Removed $total_removed patched OVMF files."
  fi
  
  # Clean up EDK2 source directories
  if compgen -G "src/edk2-*" > /dev/null 2>&1; then
    fmtr::info "Cleaning up EDK2 source directories..."
    rm -rf src/edk2-* 2>/dev/null || true
    fmtr::log "EDK2 source directories removed."
  fi
  
  # Clean up fake battery ACPI files
  local acpi_files=("$HOME/fake_battery.aml" "$HOME/fake_battery.dsl")
  local acpi_removed=0
  for file in "${acpi_files[@]}"; do
    if [ -f "$file" ]; then
      rm -f "$file" 2>/dev/null || true
      fmtr::log "Removed: $(basename "$file")"
      ((acpi_removed++))
    fi
  done
  
  if [ $acpi_removed -gt 0 ]; then
    fmtr::log "Removed $acpi_removed custom ACPI files."
  fi
  
  # Clean up custom NVRAM files
  local nvram_dir="/var/lib/libvirt/qemu/nvram"
  if [ -d "$nvram_dir" ]; then
    local secure_vars_files=()
    while IFS= read -r -d '' file; do
      secure_vars_files+=("$file")
    done < <(find "$nvram_dir" -name "*SECURE_VARS*" -type f -print0 2>/dev/null)
    
    if [ ${#secure_vars_files[@]} -gt 0 ]; then
      fmtr::warn "Found ${#secure_vars_files[@]} custom secure boot NVRAM files:"
      for file in "${secure_vars_files[@]}"; do
        fmtr::warn "  - $(basename "$file")"
      done
      
      if prmt::yes_or_no "$(fmtr::ask 'Remove custom secure boot NVRAM files?')"; then
        fmtr::info "Removing custom NVRAM files..."
        for file in "${secure_vars_files[@]}"; do
          sudo rm -f "$file" 2>/dev/null || true
          fmtr::log "Removed: $(basename "$file")"
        done
      else
        fmtr::warn "Keeping custom NVRAM files - may cause VM issues with new OVMF."
      fi
    fi
  fi
}

cleanup_source_directory() {
  fmtr::info "=== Cleaning up source directory ==="
  
  if [ -d "src" ]; then
    local src_contents=$(ls -A src/ 2>/dev/null | wc -l)
    if [ "$src_contents" -eq 0 ]; then
      fmtr::info "Removing empty source directory..."
      rmdir src/ 2>/dev/null || true
      fmtr::log "Empty source directory removed."
    else
      fmtr::info "Source directory contains other files, keeping it."
    fi
  fi
}

show_cleanup_summary() {
  fmtr::info "=== Cleanup Summary ==="
  
  # Check what's left
  local qemu_local_exists=false
  local ovmf_patched_exists=false
  
  if [ -f "/usr/local/bin/qemu-system-x86_64" ]; then
    qemu_local_exists=true
  fi
  
  for location in "/usr/share/edk2/x64" "/usr/share/ovmf" "/usr/share/OVMF"; do
    if [ -d "$location" ]; then
      if find "$location" -name "*.qcow2" -o -name "*secboot*" | grep -q .; then
        ovmf_patched_exists=true
        break
      fi
    fi
  done
  
  if [ "$qemu_local_exists" = false ] && [ "$ovmf_patched_exists" = false ]; then
    fmtr::log "✅ All patched installations have been successfully removed!"
    fmtr::info "You can now safely install unpatched versions using options 4 & 5."
  else
    fmtr::warn "⚠️  Some patched files may still remain:"
    [ "$qemu_local_exists" = true ] && fmtr::warn "  - QEMU files in /usr/local/"
    [ "$ovmf_patched_exists" = true ] && fmtr::warn "  - Patched OVMF files found"
    fmtr::info "You may need to manually remove remaining files."
  fi
}

main() {
  cleanup_all_patched
  cleanup_patched_qemu
  cleanup_patched_edk2
  cleanup_source_directory
  show_cleanup_summary
  
  fmtr::log "Cleanup process completed!"
}

main 