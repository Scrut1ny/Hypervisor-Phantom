#!/usr/bin/env bash

detect_distro() {
  local distro_id=""
  
  if [ -f /etc/os-release ]; then
    distro_id=$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '"')
    case "$distro_id" in
      # Arch-based
      arch|manjaro|endeavouros|arcolinux|garuda|artix)
        DISTRO="Arch"
        ;;
        
      # openSUSE
      opensuse-tumbleweed|opensuse-slowroll|opensuse-leap|sles)
        DISTRO="openSUSE"
        ;;

      # Debian-based
      debian|ubuntu|linuxmint|kali|pureos|pop|elementary|zorin|mx|parrot|deepin|peppermint|trisquel|bodhi|linuxlite|neon)
        DISTRO="Debian"
        ;;
        
      # RHEL/Fedora-based
      fedora|centos|rhel|rocky|alma|oracle)
        DISTRO="Fedora"
        ;;
    esac
  fi

  # Fallback if DISTRO wasn't set by case statement
  if [ -z "$DISTRO" ]; then
    if command -v pacman &>/dev/null; then
      DISTRO="Arch"
    elif command -v apt &>/dev/null; then
      DISTRO="Debian"
    elif command -v zypper &>/dev/null; then
      DISTRO="openSUSE"
    elif command -v dnf &>/dev/null; then
      DISTRO="Fedora"
    else
      if [ -n "$distro_id" ]; then
        DISTRO="Unknown ($distro_id)"
      else
        DISTRO="Unknown"
      fi
    fi
  fi

  export DISTRO
  readonly DISTRO
}

cpu_vendor_id() {
  VENDOR_ID=$(LANG=en_US.UTF-8 lscpu 2>/dev/null | awk -F': +' '/Vendor ID/ {print $2}' | xargs)

  if [ -z "$VENDOR_ID" ]; then
    # Fallback method
    VENDOR_ID=$(awk -F': +' '/vendor_id/ {print $2; exit}' /proc/cpuinfo | xargs)
  fi

  : "${VENDOR_ID:=Unknown}"

  export VENDOR_ID
  readonly VENDOR_ID
}

print_system_info() {

    local show_output=0
    local output=""

    # CPU Virtualization (Intel VT-x/AMD-V) - Required for KVM (hardware-assisted virtualization)
    if grep -qE 'vmx|svm' /proc/cpuinfo; then
        output+="\n  [✅] VT-x/AMD-V (Virtualization): Supported"
    else
        output+="\n  [❌] VT-x/AMD-V (Virtualization): Not supported"
        show_output=1
    fi

    # IOMMU (VT-d/AMD-Vi) - Required for PCIe/GPU Passthrough
    if grep -qE "iommu=on" /proc/cmdline; then
        output+="\n  [✅] VT-d/AMD-Vi (IOMMU): Enabled"
    else
        output+="\n  [❌] VT-d/AMD-Vi (IOMMU): Not enabled"
        show_output=1
    fi

    # KVM module check
    if lsmod | grep -q kvm; then
        output+="\n  [✅] KVM Kernel Module: Loaded"
    else
        output+="\n  [❌] KVM Kernel Module: Not loaded"
        show_output=1
    fi

    # Final output logic
    if [ "$show_output" -eq 1 ]; then
        echo -e "$output"
        echo -e "\n  ──────────────────────────────\n"
    else
        echo ""
    fi

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
    "Auto Libvirt XML Setup"
  )
  readonly options

  while true; do
    clear
    fmtr::box_text " >> Hypervisor Phantom << " && print_system_info

    for (( i=1; i < ${#options[@]}; i++ )); do
      fmtr::format_text '  ' "[${i}]" " ${options[${i}]}" "$TEXT_BRIGHT_YELLOW"
    done
    fmtr::format_text '\n  ' "[0]" " ${options[0]}\n" "$TEXT_BRIGHT_RED"

    local choice="$(prmt::quick_prompt '  Enter your choice [0-7]: ')" && clear
    case $choice in
      1) fmtr::box_text "${options[1]}"; "./modules/virtualization.sh" ;;
      2) fmtr::box_text "${options[2]}"; "./modules/spoof_qemu_patch.sh" ;;
      3) fmtr::box_text "${options[3]}"; "./modules/spoof_edk2_patch.sh" ;;
      4) fmtr::box_text "${options[4]}"; "./modules/gpu_passthrough.sh" ;;
      5) fmtr::box_text "${options[5]}"; "./modules/patch_kernel.sh" ;;
      6) fmtr::box_text "${options[6]}"; "./modules/looking_glass.sh" ;;
      7) fmtr::box_text "${options[7]}"; "./modules/auto_xml.sh" ;;
      0)
        if prmt::yes_or_no "$(fmtr::ask 'Do you want to clear the logs directory?')"; then
          rm "${LOG_PATH}"/*.log
        fi
        exit 0
        ;;
      *) fmtr::error "Invalid option, please try again." ;;
    esac
    prmt::quick_prompt "$(fmtr::info 'Press any key to continue...')"
  done
}

main() {
  if ! source "./utils/debugger.sh"; then
    echo "Log file at ${LOG_FILE} couldn't be generated. Check permissions!"
    exit 1
  fi

  if ! declare -f fmtr::format_text &>/dev/null && ! source "./utils/formatter.sh"; then
    echo "Library 'formatter.sh' couldn't be loaded!"
    exit 1
  fi

  if ! source "./utils/prompter.sh"; then
    echo "Library 'prompter.sh' couldn't be loaded!"
    exit 1
  fi

  detect_distro
  cpu_vendor_id
  main_menu
}

main
