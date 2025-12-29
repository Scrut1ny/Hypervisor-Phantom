#!/usr/bin/env bash

detect_distro() {
  local id=""
  [[ -r /etc/os-release ]] && id=$(. /etc/os-release; printf %s "$ID")

  case "$id" in
    arch|manjaro|endeavouros|arcolinux|garuda|artix) DISTRO=Arch ;;
    opensuse-tumbleweed|opensuse-slowroll|opensuse-leap|sles) DISTRO=openSUSE ;;
    debian|ubuntu|linuxmint|kali|pureos|pop|elementary|zorin|mx|parrot|deepin|peppermint|trisquel|bodhi|linuxlite|neon) DISTRO=Debian ;;
    fedora|centos|rhel|rocky|alma|oracle) DISTRO=Fedora ;;
    *)
      if   command -v pacman &>/dev/null; then DISTRO=Arch
      elif command -v apt    &>/dev/null; then DISTRO=Debian
      elif command -v zypper &>/dev/null; then DISTRO=openSUSE
      elif command -v dnf    &>/dev/null; then DISTRO=Fedora
      else DISTRO=${id:+Unknown ($id)}; : "${DISTRO:=Unknown}"
      fi
      ;;
  esac

  export DISTRO; readonly DISTRO
}

cpu_vendor_id() {
  VENDOR_ID=$(
    LC_ALL=C lscpu 2>/dev/null | awk -F': +' '/^Vendor ID:/ {print $2; exit}'
  )
  [[ -n $VENDOR_ID ]] || VENDOR_ID=$(awk -F': +' '/vendor_id/ {print $2; exit}' /proc/cpuinfo)
  VENDOR_ID=${VENDOR_ID//[[:space:]]/}; : "${VENDOR_ID:=Unknown}"
  export VENDOR_ID; readonly VENDOR_ID
}

print_system_info() {
  local out="" show=0 virt iommu
  case "$VENDOR_ID" in
    GenuineIntel) virt="VT-x";  iommu="VT-d"  ;;
    AuthenticAMD) virt="AMD-V"; iommu="AMD-Vi" ;;
    *) virt="Unknown"; iommu="Unknown" ;;
  esac

  if grep -qE 'vmx|svm' /proc/cpuinfo; then
    out+="\n  [✅] $virt (Virtualization): Supported"
  else
    out+="\n  [❌] $virt (Virtualization): Not supported"; show=1
  fi

  if [[ -d /sys/kernel/iommu_groups && -n $(ls -A /sys/kernel/iommu_groups 2>/dev/null) ]]; then
    out+="\n  [✅] $iommu (IOMMU): Enabled"
  else
    out+="\n  [❌] $iommu (IOMMU): Not enabled"; show=1
  fi

  if lsmod | grep -q kvm; then
    out+="\n  [✅] KVM Kernel Module: Loaded"
  else
    out+="\n  [❌] KVM Kernel Module: Not loaded"; show=1
  fi

  ((show)) && echo -e "$out\n\n  ──────────────────────────────\n" || echo ""
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

  while :; do
    clear
    fmtr::box_text " >> Hypervisor Phantom << " && print_system_info

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
  cpu_vendor_id
  main_menu
}

main
