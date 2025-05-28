#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && { echo "Required environment variables not set."; exit 1; }

source "./utils/formatter.sh"
source "./utils/packages.sh"
source "./utils/prompter.sh"

REQUIRED_PKGS_Arch=(
  qemu-base edk2-ovmf libvirt dnsmasq virt-manager
)

REQUIRED_PKGS_Debian=(
  qemu-system-x86 ovmf virt-manager libvirt-clients
  libvirt-daemon-system libvirt-daemon-config-network
)

REQUIRED_PKGS_openSUSE=(
  libvirt libvirt-client libvirt-daemon virt-manager
  qemu qemu-kvm ovmf qemu-tools
)

REQUIRED_PKGS_Fedora=(
  @virtualization
)

configure_firewall_arch() {
  fmtr::log "Configuring firewall for Arch..."

  if pacman -Qs "iptables-nft" &>> "$LOG_FILE"; then
    if grep -q '^firewall_backend *= *"iptables"' /etc/libvirt/network.conf; then
      fmtr::info "firewall_backend already set to iptables (compatibility layer)"
    else
      sudo sed -i '/firewall_backend \=/s/^#//g' '/etc/libvirt/network.conf'
      sudo sed -i '/etc/libvirt/network.conf' -e 's/\(firewall_backend \= *\).*/\1"iptables"/'
      fmtr::info "Set firewall_backend to iptables (compatibility layer)"
    fi
    sudo systemctl enable --now nftables.service &>> "$LOG_FILE"
    fmtr::info "nftables service enabled"

  elif pacman -Qs "iptables" &>> "$LOG_FILE"; then
    if pacman -Qs ebtables &> /dev/null; then
      fmtr::info "ebtables already installed"
    else
      fmtr::log "Installing ebtables from AUR..."
      git clone https://aur.archlinux.org/ebtables.git &>> "$LOG_FILE"
      cd ebtables || exit
      makepkg -sirc --noconfirm &>> "$LOG_FILE"
      cd ..
      rm -rf ebtables
      fmtr::info "ebtables installed"
    fi
    sudo systemctl enable --now iptables.service &>> "$LOG_FILE"
    fmtr::info "iptables service enabled"

  elif pacman -Qs "nftables" &>> "$LOG_FILE"; then
    fmtr::warn "Nftables without iptables compatibility isn't ideal for libvirt"
    echo "See: https://bbs.archlinux.org/viewtopic.php?id=284664"
    sudo systemctl enable --now nftables.service &>> "$LOG_FILE"
    fmtr::info "nftables service enabled"

  else
    fmtr::error "Unsupported firewall implementation. Manual configuration may be required."
  fi
}

configure_system_installation() {
  local libvirtd_conf='/etc/libvirt/libvirtd.conf'
  local qemu_conf='/etc/libvirt/qemu.conf'
  local current_user
  current_user="$(whoami)"

  # Configure libvirtd.conf
  if grep -q "^unix_sock_group" "$libvirtd_conf"; then
    fmtr::info "unix_sock_group already set"
  else
    sudo sed -i '/unix_sock_group/s/^#//g' "$libvirtd_conf"
    fmtr::info "Enabled unix_sock_group"
  fi

  if grep -q "^unix_sock_rw_perms" "$libvirtd_conf"; then
    fmtr::info "unix_sock_rw_perms already set"
  else
    sudo sed -i '/unix_sock_rw_perms/s/^#//g' "$libvirtd_conf"
    fmtr::info "Enabled unix_sock_rw_perms"
  fi

  # Configure qemu.conf
  if grep -q "^user = \"$current_user\"" "$qemu_conf"; then
    fmtr::info "qemu.conf: user already set to $current_user"
  else
    sudo sed -i "s/#user = \"root\"/user = \"$current_user\"/" "$qemu_conf"
    fmtr::info "Set qemu.conf user = $current_user"
  fi

  if grep -q "^group = \"$current_user\"" "$qemu_conf"; then
    fmtr::info "qemu.conf: group already set to $current_user"
  else
    sudo sed -i "s/#group = \"root\"/group = \"$current_user\"/" "$qemu_conf"
    fmtr::info "Set qemu.conf group = $current_user"
  fi

  # Add user to required groups
  if id -nG "$current_user" | grep -qw "kvm"; then
    fmtr::info "User $current_user already in kvm group"
  else
    sudo usermod -aG kvm "$current_user"
    fmtr::info "Added $current_user to kvm group"
  fi

  if id -nG "$current_user" | grep -qw "libvirt"; then
    fmtr::info "User $current_user already in libvirt group"
  else
    sudo usermod -aG libvirt "$current_user"
    fmtr::info "Added $current_user to libvirt group"
  fi

  # Start libvirt and virtual network
  if sudo systemctl is-enabled libvirtd.socket &> /dev/null; then
    fmtr::info "libvirtd.socket already enabled"
  else
    sudo systemctl enable --now libvirtd.socket &>> "$LOG_FILE"
    fmtr::info "Enabled and started libvirtd.socket"
  fi

  if sudo virsh net-info default &> /dev/null; then
    fmtr::info "Default libvirt network already exists and is active"
  else
    sudo virsh net-autostart default &>> "$LOG_FILE"
    sudo virsh net-start default &>> "$LOG_FILE"
    fmtr::info "Started and enabled default libvirt network"
  fi
}

main() {
  install_req_pkgs "virt"

  if [[ "$DISTRO" == "arch" ]]; then
    fmtr::log "Running Arch-specific firewall configuration..."
    configure_firewall_arch
  else
    fmtr::info "No firewall configuration needed for $DISTRO"
  fi

  configure_system_installation
  fmtr::warn "Logout or reboot for all group and service changes to take effect."
}

main
