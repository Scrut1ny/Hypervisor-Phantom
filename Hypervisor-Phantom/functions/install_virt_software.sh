#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && exit 1

source "./utils/formatter.sh"

install_req_pkgs() {
  fmtr::log "Checking for missing packages"

  case "$DISTRO" in
    Arch)
      REQUIRED_PKGS=("qemu-base" "edk2-ovmf" "libvirt" "dnsmasq" "virt-manager")
      PKG_MANAGER="pacman"
      INSTALL_CMD="sudo pacman -S --noconfirm"
      CHECK_CMD="pacman -Q"
      ;;
    Debian)
      REQUIRED_PKGS=("qemu-system-x86" "ovmf" "virt-manager" "libvirt-clients" \
        "libvirt-daemon-system" "libvirt-daemon-config-network"
      )
      PKG_MANAGER="apt"
      INSTALL_CMD="sudo apt -y install"
      CHECK_CMD="dpkg -l"
      ;;
    Fedora)
      REQUIRED_PKGS=("@virtualization")
      PKG_MANAGER="dnf"
      INSTALL_CMD="sudo dnf -y install"
      CHECK_CMD="rpm -q"
      ;;
    *)
      fmtr::error "Distribution not recognized or not supported by this script."
      exit 1
      ;;
  esac

  # List to store missing packages
  MISSING_PKGS=()

  # Check each required package
  for PKG in "${REQUIRED_PKGS[@]}"; do
    if ! $CHECK_CMD $PKG &>/dev/null; then
      MISSING_PKGS+=("$PKG")
    fi
  done

  # If no packages are missing, notify the user
  if [ ${#MISSING_PKGS[@]} -eq 0 ]; then
    fmtr::log "All virt software is already installed."
    return 0
  fi

  fmtr::warn "The required packages are missing: ${MISSING_PKGS[@]}"
  if prmt::yes_or_no "$(fmtr::ask 'Install the missing virt packages?')"; then
    # Install missing packages
    $INSTALL_CMD "${MISSING_PKGS[@]}" &>> "$LOG_FILE"
    if [ $? -eq 0 ]; then
      fmtr::log "Successfully installed missing packages: ${MISSING_PKGS[@]}"
    else
      fmtr::error "Failed to install some packages. Check the log for details."
      exit 1
    fi
  else
    fmtr::log "The missing packages are required to continue; Exiting."
    exit 1
  fi
}

configure_firewall_arch() {
  fmtr::log "Trying to configure firewall..."
  if pacman -Qs "iptables-nft" &>> "$LOG_FILE"; then
    sudo sed -i '/firewall_backend \=/s/^#//g' '/etc/libvirt/network.conf'
    sudo sed -i '/etc/libvirt/network.conf' -e 's/\(firewall_backend \= *\).*/\1\"iptables\"/'
    sudo systemctl enable --now nftables.service &>> "$LOG_FILE"
    fmtr::info "firewall_backend=iptables compatibility layer"
  elif pacman -Qs "iptables" &>> "$LOG_FILE"; then
    git clone https://aur.archlinux.org/ebtables.git &>> "$LOG_FILE"
    cd ebtables || exit
    makepkg -sirc --noconfirm &>> "$LOG_FILE"
    rm -rf ../ebtables
    sudo systemctl enable --now iptables.service &>> "$LOG_FILE"
    fmtr::info "firewall_backend is iptables"
  elif pacman -Qs "nftables" &>> "$LOG_FILE"; then
    fmtr::warn "Nftables without the iptables compatibility layer isn't configured correctly by the libvirt package"
    echo "More info here: https://bbs.archlinux.org/viewtopic.php?id=284664"
    sudo systemctl enable --now nftables.service &>> "$LOG_FILE"
  else
    fmtr::error "Firewall implementation unsupported by this script, but may still work with Libvirt. Make sure forwarding is configured properly!"
  fi
}

configure_system_installation() {
  fmtr::log "Configuring Libvirt"
  local libvirtd_conf='/etc/libvirt/libvirtd.conf'
  sudo sed -i '/unix_sock_group/s/^#//g' "$libvirtd_conf"
  sudo sed -i '/unix_sock_rw_perms/s/^#//g' "$libvirtd_conf"

  fmtr::log "Setting up QEMU/KVM driver"
  local qemu_conf='/etc/libvirt/qemu.conf'
  sudo sed -i "s/#user = \"root\"/user = \"$(whoami)\"/" "$qemu_conf"
  sudo sed -i "s/#group = \"root\"/group = \"$(whoami)\"/" "$qemu_conf"

  {
    sudo usermod -aG kvm,libvirt "$(whoami)"
    sudo systemctl enable --now libvirtd.socket
    sudo virsh net-autostart default
  } &>> "$LOG_FILE"
}

main() {
  install_req_pkgs
  configure_firewall_arch
  configure_system_installation
  fmtr::warn "Logout for changes to take effect."
}

main
