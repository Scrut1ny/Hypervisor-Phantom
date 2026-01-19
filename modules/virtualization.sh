#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && { echo "Required environment variables not set."; exit 1; }

source ./utils.sh || { echo "Failed to load utilities module!"; exit 1; }

REQUIRED_PKGS_Arch=(
  qemu-base edk2-ovmf libvirt dnsmasq virt-manager swtpm
)

REQUIRED_PKGS_Debian=(
  qemu-system-x86 ovmf virt-manager libvirt-clients swtpm
  libvirt-daemon-system libvirt-daemon-config-network
)

REQUIRED_PKGS_openSUSE=(
  libvirt libvirt-client libvirt-daemon virt-manager
  qemu qemu-kvm ovmf qemu-tools swtpm
)

REQUIRED_PKGS_Fedora=(
  @virtualization swtpm
)

configure_system_installation() {
  local target_user="${SUDO_USER:-$USER}"
  local user_groups=" $(id -nG "$target_user") "

  # Groups: input, kvm, and libvirt
  for grp in input kvm libvirt; do
    if [[ "$user_groups" == *" $grp "* ]]; then
      fmtr::info "User $target_user already in $grp group"
    else
      $ROOT_ESC usermod -aG "$grp" "$target_user"
      fmtr::info "Added $target_user to $grp group"
    fi
  done

  # Modify defaults for default (virbr0) libvirt network
  # *IMPORTANT* Patches 52:54:00:XX:XX:XX and DHCP range 192.168.122.2-254
  # This appears in ARP cache and needs to be modified.
  OUI="b0:4e:26"
  RANDOM_MAC="$OUI:$(printf '%02x:%02x:%02x' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))"
  XML_PATH="/etc/libvirt/qemu/networks/default.xml"

  $ROOT_ESC sed -i \
    -e "s|<mac address='[0-9A-Fa-f:]\{17\}'|<mac address='$RANDOM_MAC'|g" \
    -e "s|192\.168\.122\.|192.168.1.|g" \
    "$XML_PATH"

  # Enable (autostart) & start libvirtd.socket
  $ROOT_ESC systemctl enable --now libvirtd.socket &>> "$LOG_FILE" \
    && fmtr::info "Ensured libvirtd.socket is enabled and started" \
    || fmtr::warn "Failed to enable/start libvirtd.socket (see $LOG_FILE)"

  # Autostart & start default (virbr0) libvirt network
  $ROOT_ESC virsh net-autostart default &>>"$LOG_FILE" || true
  $ROOT_ESC virsh net-start default &>>"$LOG_FILE" \
    && fmtr::info "Started and enabled default libvirt network" \
    || fmtr::warn "Failed to start default libvirt network (see $LOG_FILE)"
}

main() {
  install_req_pkgs "virt"
  configure_system_installation
  fmtr::warn "Logout or reboot for all group and service changes to take effect."
}

main
