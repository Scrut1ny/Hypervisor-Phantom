#!/usr/bin/env bash

source "./utils.sh"

uninstall_qemu() {
  fmtr::warn "This will remove QEMU from /usr/local/bin and delete the source directory."
  if ! prmt::yes_or_no "$(fmtr::ask 'Are you sure you want to proceed?')"; then
    fmtr::info "Aborted."
    return
  fi

  fmtr::log "Removing QEMU binaries..."
  sudo rm -f /usr/local/bin/qemu-*
  sudo rm -f /usr/local/bin/ivshmem-*
  sudo rm -f /usr/local/bin/virtiofsd
  
  fmtr::log "Removing QEMU source directory..."
  rm -rf src/qemu-*
  
  fmtr::log "Removing logs..."
  rm -rf logs/*
  
  fmtr::info "Uninstall complete."
}

main() {
  fmtr::box_text "Uninstall / Cleanup"
  uninstall_qemu
  
  echo ""
  prmt::quick_prompt "$(fmtr::info 'Press any key to return to menu...')"
}

main
