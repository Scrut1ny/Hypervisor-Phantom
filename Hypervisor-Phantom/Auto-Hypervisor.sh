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

get_cpu_info() {
  CPU_COUNT=$(nproc --all 2>/dev/null || echo "Unknown")
  VENDOR_ID=$(LANG=en_US.UTF-8 lscpu | grep 'Vendor ID:' | awk '{print $3}' 2>/dev/null | xargs || echo "Unknown")
  export CPU_COUNT VENDOR_ID
  readonly CPU_COUNT VENDOR_ID
}

get_virtualization_status() {
  VIRT_STATUS=$(LANG=en_US.UTF-8 lscpu | grep 'Virtualization:' | awk '{print $2}' 2>/dev/null | xargs || echo "Unknown")
  VIRT_STATUS=${VIRT_STATUS:-"Not enabled"}
  export VIRT_STATUS
  readonly VIRT_STATUS
}

get_memory_info() {
  if [ -f /proc/meminfo ]; then
    TOTAL_RAM_GB=$(awk '/MemTotal/ {print $2 / 1024 / 1024}' /proc/meminfo)
    AVAILABLE_RAM_GB=$(awk '/MemAvailable/ {print $2 / 1024 / 1024}' /proc/meminfo)
    TOTAL_RAM_GB=$(printf "%.2f" "$TOTAL_RAM_GB")
    AVAILABLE_RAM_GB=$(printf "%.2f" "$AVAILABLE_RAM_GB")
  else
    TOTAL_RAM_GB="Unknown"
    AVAILABLE_RAM_GB="Unknown"
  fi
  export TOTAL_RAM_GB AVAILABLE_RAM_GB
  readonly TOTAL_RAM_GB AVAILABLE_RAM_GB
}

get_gpu_info() {
  GPU_NAMES=$(lspci | grep -iE 'vga|3d' | sed -E 's/.*\[(.*)\].*/\1/')
  if [ -n "$GPU_NAMES" ]; then
    GPU_NAMES=$(echo "$GPU_NAMES" | awk '{printf "├─ %s\n", $0}' | sed '$ s/├─ /└─ /')
  else
    GPU_NAMES="None detected"
  fi
  export GPU_NAMES
  readonly GPU_NAMES
}

print_system_info() {
  fmtr::format_text '  ' "\n  • System Information" '' "$BOLD"
  fmtr::format_text '    ├─ Distro: ' "$DISTRO" '' "$TEXT_BRIGHT_GREEN"

  local cpu_info="$VENDOR_ID • $CPU_COUNT Cores • $VIRT_STATUS"
  local virt_status_color="$TEXT_BRIGHT_GREEN"
  if [[ "$VIRT_STATUS" == "Not enabled" ]]; then
    virt_status_color="$TEXT_BRIGHT_RED"
  fi
  fmtr::format_text '    ├─ CPU: ' "$cpu_info" '' "$virt_status_color"

  echo "    ├─ GPU(s):"
  while IFS= read -r gpu_line; do
    gpu_name_colored=$(echo "$gpu_line" | sed -E 's/(├─ |└─ )//')
    fmtr::format_text "    │  ${gpu_line:0:3}" "$gpu_name_colored" '' "$TEXT_BRIGHT_GREEN"
  done <<< "$GPU_NAMES"

  fmtr::format_text '    └─ RAM: ' "$TOTAL_RAM_GB GB (Available: $AVAILABLE_RAM_GB GB)" '' "$TEXT_BRIGHT_GREEN"
  echo -e "\n  ────────────────────────────────\n"
}

main_menu() {
  local options=(
    "Exit"
    "VFIO Configuration"
    "Virt Software Setup"
    "QEMU (Patched) Setup"
    "EDK2/OVMF (Patched) Setup"
    "Linux Kernel (Patched) Setup"
    "Looking Glass Setup"
  )
  readonly options

  while true; do
    clear
    fmtr::box_text "Hypervisor Phantom" && print_system_info

    for (( i=1; i < ${#options[@]}; i++ )); do
      fmtr::format_text '  ' "[${i}]" " ${options[${i}]}" "$TEXT_BRIGHT_YELLOW"
    done
    fmtr::format_text '\n  ' "[0]" " ${options[0]}\n" "$TEXT_BRIGHT_RED"

    local choice="$(prmt::quick_prompt '  Enter your choice [0-6]: ')" && clear
    case $choice in
      1) fmtr::box_text "${options[1]}"; "./functions/configure_vfio.sh" ;;
      2) fmtr::box_text "${options[2]}"; "./functions/install_virt_software.sh" ;;
      3) fmtr::box_text "${options[3]}"; "./functions/spoof_qemu_patch.sh" ;;
      4) fmtr::box_text "${options[4]}"; "./functions/spoof_ovmf_patch.sh" ;;
      5) fmtr::box_text "${options[5]}"; "./functions/patch_kernel.sh" ;;
      6) fmtr::box_text "${options[6]}"; "./functions/looking_glass.sh" ;;
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
  get_cpu_info
  get_virtualization_status
  get_memory_info
  get_gpu_info
  main_menu
}

main
