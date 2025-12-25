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
  local target_user="${SUDO_USER:-$USER}"

  # Set "key value" in libvirtd.conf (uncomment/replace if present; append if missing)
  set_kv_conf() {
    local file="$1" key="$2" value="$3"

    if $ROOT_ESC grep -Eq "^[[:space:]]*#?[[:space:]]*${key}[[:space:]]+" "$file"; then
      $ROOT_ESC sed -Ei \
        "s|^[[:space:]]*#?[[:space:]]*(${key})[[:space:]]+.*|\1 ${value}|" \
        "$file"
      fmtr::info "$file: Set $key $value"
    else
      printf '%s %s\n' "$key" "$value" | $ROOT_ESC tee -a "$file" > /dev/null
      fmtr::info "$file: Added $key $value"
    fi
  }

  # Set key = "value" in qemu.conf (uncomment/replace if present; append if missing)
  set_qemu_kv() {
    local file="$1" key="$2" value="$3"

    if $ROOT_ESC grep -Eq "^[[:space:]]*#?[[:space:]]*${key}[[:space:]]*=" "$file"; then
      $ROOT_ESC sed -Ei \
        "s|^[[:space:]]*#?[[:space:]]*(${key})[[:space:]]*=.*|\1 = \"${value}\"|" \
        "$file"
      fmtr::info "$file: Set $key = \"$value\""
    else
      printf '%s = "%s"\n' "$key" "$value" | $ROOT_ESC tee -a "$file" > /dev/null
      fmtr::info "$file: Added $key = \"$value\""
    fi
  }

  # Ensure configs (explicit values)
  set_kv_conf "$libvirtd_conf" "unix_sock_group"    "\"libvirt\""
  set_kv_conf "$libvirtd_conf" "unix_sock_rw_perms" "\"0770\""
  set_qemu_kv "$qemu_conf" "user"  "$target_user"
  set_qemu_kv "$qemu_conf" "group" "$target_user"

  # Groups: input, kvm, libvirt (no grep; avoid repeated `id` calls)
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
