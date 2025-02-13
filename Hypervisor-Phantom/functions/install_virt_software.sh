#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && exit 1

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

REQUIRED_PKGS_Fedora=(
  @virtualization
)

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
    sudo virsh net-autostart default # Enable autostart for virtual default network on boot
    sudo virsh net-start default # Start the virtual default network
  } &>> "$LOG_FILE"
}

main() {
  install_req_pkgs "virt"
  configure_firewall_arch
  configure_system_installation
  fmtr::warn "Logout for changes to take effect."
}

main
