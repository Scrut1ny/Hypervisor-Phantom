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
  local libvirtd_conf='/etc/libvirt/libvirtd.conf'
  local qemu_conf='/etc/libvirt/qemu.conf'
  local current_user
  current_user="$(whoami)"

  # Helper to uncomment or append config
  ensure_config() {
    local file="$1"
    local key="$2"
    local value="$3"
    if grep -q "^${key}" "$file"; then
      fmtr::info "$file: $key already set"
    else
      $ROOT_ESC sed -i "/${key}/s/^#//g" "$file" || echo "${key} ${value}" | tee -a "$file" > /dev/null
      fmtr::info "$file: Enabled $key"
    fi
  }

  # Helper to set qemu.conf user/group
  set_qemu_conf() {
    local conf="$1" key="$2" val="$3"
    if grep -q "^${key} = \"${val}\"" "$conf"; then
      fmtr::info "$conf: $key already set to $val"
    else
      $ROOT_ESC sed -i "s/#${key} = \".*\"/${key} = \"${val}\"/" "$conf" || echo "${key} = \"${val}\"" | tee -a "$conf" > /dev/null
      fmtr::info "$conf: Set $key = $val"
    fi
  }

  # Ensure configs
  ensure_config "$libvirtd_conf" "unix_sock_group"
  ensure_config "$libvirtd_conf" "unix_sock_rw_perms"
  set_qemu_conf "$qemu_conf" "user" "$current_user"
  set_qemu_conf "$qemu_conf" "group" "$current_user"

  # Groups: input, kvm, libvirt
  for grp in input input kvm libvirt; do
    if id -nG "$current_user" | grep -qw "$grp"; then
      fmtr::info "User $current_user already in $grp group"
    else
      $ROOT_ESC usermod -aG "$grp" "$current_user"
      fmtr::info "Added $current_user to $grp group"
    fi
  done

  # Enable libvirtd.socket if not enabled
  if ! systemctl is-enabled libvirtd.socket &> /dev/null; then
    $ROOT_ESC systemctl enable --now libvirtd.socket &>> "$LOG_FILE"
    fmtr::info "Enabled and started libvirtd.socket"
  else
    fmtr::info "libvirtd.socket already enabled"
  fi

  # Ensure default network is running
  if ! virsh net-info default &> /dev/null; then
    $ROOT_ESC virsh net-autostart default &>> "$LOG_FILE"
    $ROOT_ESC virsh net-start default &>> "$LOG_FILE"
    fmtr::info "Started and enabled default libvirt network"
  else
    fmtr::info "Default libvirt network already exists and is active"
  fi
}

main() {
  install_req_pkgs "virt"
  configure_system_installation
  fmtr::warn "Logout or reboot for all group and service changes to take effect."
}

main
