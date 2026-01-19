#!/usr/bin/env bash

detect_distro() {
  local id

  # Try reading /etc/os-release first
  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    id=${ID,,}
  else
    id=""
  fi

  # Map known distro IDs to canonical names
  case "$id" in
    arch|manjaro|endeavouros|arcolinux|garuda|artix) DISTRO="Arch" ;;
    opensuse-*|sles) DISTRO="openSUSE" ;;
    debian|ubuntu|linuxmint|kali|pureos|pop|elementary|zorin|mx|parrot|deepin|peppermint|trisquel|bodhi|linuxlite|neon) DISTRO="Debian" ;;
    fedora|centos|rhel|rocky|alma|oracle) DISTRO="Fedora" ;;
    *)
      # Fallback: detect by package manager
      if command -v pacman >/dev/null 2>&1; then
        DISTRO="Arch"
      elif command -v apt >/dev/null 2>&1; then
        DISTRO="Debian"
      elif command -v zypper >/dev/null 2>&1; then
        DISTRO="openSUSE"
      elif command -v dnf >/dev/null 2>&1; then
        DISTRO="Fedora"
      else
        DISTRO=${id:+Unknown ($id)}
        : "${DISTRO:=Unknown}"
      fi
      ;;
  esac

  export DISTRO
  readonly DISTRO
}

cpu_detect() {
  local vendor
  vendor=$(awk -F': +' '/^vendor_id/ {print $2; exit}' /proc/cpuinfo)

  [[ -n $vendor ]] || fmtr::fatal "Unable to determine CPU vendor from /proc/cpuinfo"

  case "$vendor" in
    *AuthenticAMD*)
      CPU_VENDOR_ID="AuthenticAMD"
      CPU_VIRTUALIZATION="svm"
      CPU_MANUFACTURER="amd"
      ;;
    *GenuineIntel*)
      CPU_VENDOR_ID="GenuineIntel"
      CPU_VIRTUALIZATION="vmx"
      CPU_MANUFACTURER="intel"
      ;;
    *)
      fmtr::fatal "Unsupported CPU vendor: $vendor"
      ;;
  esac

  export CPU_VENDOR_ID CPU_VIRTUALIZATION CPU_MANUFACTURER
  readonly CPU_VENDOR_ID CPU_VIRTUALIZATION CPU_MANUFACTURER
}

main_menu() {
  local options=(
    "Exit"
    "Virtualization Setup"
    "QEMU (Patched) Setup"
    "EDK2 (Patched) Setup"
    "GPU Passthrough Setup"
    "Kernel (Patched) Setup"
    "Looking Glass Setup"
    "Deploy Auto/Unattended XML"
  )
  readonly options

  while :; do
    clear
    fmtr::box_text " >> Hypervisor Phantom << "; echo ""

    for ((i=1; i<${#options[@]}; i++)); do
      printf '  %b[%d]%b %s\n' "$TEXT_BRIGHT_YELLOW" "$i" "$RESET" "${options[i]}"
    done
    printf '\n  %b[%d]%b %s\n\n' "$TEXT_BRIGHT_RED" 0 "$RESET" "${options[0]}"

    local choice
    choice="$(prmt::quick_prompt '  Enter your choice [0-7]: ')" || continue
    clear

    case $choice in
      1) fmtr::box_text "${options[1]}"; ./modules/virtualization.sh ;;
      2) fmtr::box_text "${options[2]}"; ./modules/patch_qemu.sh ;;
      3) fmtr::box_text "${options[3]}"; ./modules/patch_ovmf.sh ;;
      4) fmtr::box_text "${options[4]}"; ./modules/vfio.sh ;;
      5) fmtr::box_text "${options[5]}"; ./modules/patch_kernel.sh ;;
      6) fmtr::box_text "${options[6]}"; ./modules/looking_glass.sh ;;
      7) fmtr::box_text "${options[7]}"; ./modules/auto_xml.sh ;;
      0)
        prmt::yes_or_no "$(fmtr::ask 'Do you want to clear the logs directory?')" &&
          rm -f -- "${LOG_PATH}"/*.log
        exit 0
        ;;
      *) fmtr::error "Invalid option, please try again." ;;
    esac

    prmt::quick_prompt "$(fmtr::info 'Press any key to continue...')"
  done
}

main() {
  source ./utils.sh || { echo "Failed to load utilities module!"; exit 1; }
  detect_distro
  cpu_detect
  main_menu
}

main
