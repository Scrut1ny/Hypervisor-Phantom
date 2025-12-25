#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && { echo "Required environment variables not set."; exit 1; }

source "./utils.sh"

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
  # Sets "unix_sock_group" and "unix_sock_rw_perms"
  $ROOT_ESC sed -Ei \
    -e 's/^[[:space:]]*#?[[:space:]]*(unix_sock_group)[[:space:]]+.*/\1 "libvirt"/' \
    -e 's/^[[:space:]]*#?[[:space:]]*(unix_sock_rw_perms)[[:space:]]+.*/\1 "0770"/' \
    /etc/libvirt/libvirtd.conf

  # Sets "user" and "group"
  $ROOT_ESC sed -Ei \
    -e 's/^[[:space:]]*#?[[:space:]]*(user)[[:space:]]*=.*/\1 = "null"/' \
    -e 's/^[[:space:]]*#?[[:space:]]*(group)[[:space:]]*=.*/\1 = "null"/' \
    /etc/libvirt/qemu.conf

  # Groups: input, kvm, and libvirt
  local target_user="${SUDO_USER:-$USER}"
  local user_groups=" $(id -nG "$target_user") "
  for grp in input kvm libvirt; do
    if [[ "$user_groups" == *" $grp "* ]]; then
      fmtr::info "User $target_user already in $grp group"
    else
      $ROOT_ESC usermod -aG "$grp" "$target_user"
      fmtr::info "Added $target_user to $grp group"
    fi
  done

  # Ensure libvirtd.socket is enabled and running (idempotent)
  $ROOT_ESC systemctl enable --now libvirtd.socket &>> "$LOG_FILE" \
    && fmtr::info "Ensured libvirtd.socket is enabled and started" \
    || fmtr::warn "Failed to enable/start libvirtd.socket (see $LOG_FILE)"

  # Ensure default libvirt network exists, autostarts, and is active
  if ! $ROOT_ESC virsh net-list --all --name 2>>"$LOG_FILE" | grep -qx default; then
    fmtr::warn "Libvirt network 'default' is not defined; skipping (you may need to define it)."
  else
    $ROOT_ESC virsh net-autostart default &>>"$LOG_FILE" || true

    if $ROOT_ESC virsh net-list --inactive --name 2>>"$LOG_FILE" | grep -qx default; then
      $ROOT_ESC virsh net-start default &>>"$LOG_FILE" \
        && fmtr::info "Started and enabled default libvirt network" \
        || fmtr::warn "Failed to start default libvirt network (see $LOG_FILE)"
    else
      fmtr::info "Default libvirt network already active"
    fi
  fi
}

main() {
  install_req_pkgs "virt"
  configure_system_installation
  fmtr::warn "Logout or reboot for all group and service changes to take effect."
}

main
