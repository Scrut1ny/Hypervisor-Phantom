#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && exit 1

source "./utils/debugger.sh"
source "./utils/prompter.sh"
source "./utils/formatter.sh"
source "./utils/packages.sh"

readonly SRC_DIR="src"
readonly KERNEL_MAJOR="6"
readonly KERNEL_VERSION="${KERNEL_MAJOR}.13"
readonly KERNEL_DIR="linux-${KERNEL_VERSION}"
readonly KERNEL_ARCHIVE="${KERNEL_DIR}.tar.xz"
readonly KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_MAJOR}.x/${KERNEL_ARCHIVE}"
readonly PATCH_DIR="../../patches/Kernel"
readonly LINUX_PATCH="${KERNEL_DIR}.patch"

REQUIRED_PKGS_Arch=(
  base-devel ncurses bison flex openssl elfutils
)

REQUIRED_PKGS_Debian=(
  build-essential libncurses-dev bison flex libssl-dev libelf-dev
)

REQUIRED_PKGS_Fedora=(
  gcc gcc-c++ make ncurses-devel bison flex elfutils-libelf-devel openssl-devel
)

acquire_linux_source() {
  mkdir -p "$SRC_DIR" && cd "$SRC_DIR"

  if [[ ! -d "$KERNEL_DIR" ]]; then
    if [[ ! -f "$KERNEL_ARCHIVE" ]]; then
      fmtr::log "Downloading Linux Kernel Source"
      curl -sSO "$KERNEL_URL" || dbg::fail "Couldn't download Linux"
    fi

    fmtr::log "Extracting archive"
    tar xJf "$KERNEL_ARCHIVE" || dbg::fail "Couldn't extract Linux"
  fi

  cd "$KERNEL_DIR" || dbg::fail "Couldn't cd into Linux source"
}

patch_kernel() {
  if [[ ! -f "${PATCH_DIR}/${LINUX_PATCH}" ]]; then
    fmtr::log "ERROR: Patch file ${PATCH_DIR}/${LINUX_PATCH} not found!"
    exit 1
  fi

  fmtr::log "Patching Linux"
  patch -fsp1 < "${PATCH_DIR}/${LINUX_PATCH}" || dbg::fail "Failed to apply patch ${LINUX_PATCH}"
}

compile_kernel() {
  fmtr::log "Copying current kernel config"
  cp "/boot/config-$(uname -r)" ".config" || dbg::fail "Failed to copy current kernel config"

  if [[ "${DISTRO}" == "Debian" ]]; then
    fmtr::log "Disabling SYSTEM_TRUSTED_KEYS and SYSTEM_REVOCATION_KEYS"
    scripts/config --disable SYSTEM_TRUSTED_KEYS || dbg::fail "Failed to disable SYSTEM_TRUSTED_KEYS"
    scripts/config --disable SYSTEM_REVOCATION_KEYS || dbg::fail "Failed to disable SYSTEM_REVOCATION_KEYS"
  fi

  fmtr::log "Building the Kernel"
  make olddefconfig &>> "${LOG_FILE}" || dbg::fail "Failed to run make olddefconfig"
  make -j"$(nproc)" &>> "${LOG_FILE}" || dbg::fail "Failed to build the kernel"

  fmtr::log "Done. Restart and select patched kernel version in grub to boot into new kernel"
}

install_kernel() {
  fmtr::log "Installing Kernel modules and applying kernel patches"
  sudo make modules_install &>> "${LOG_FILE}" || dbg::fail "Failed to install kernel modules"
  sudo make install &>> "${LOG_FILE}" || dbg::fail "Failed to install the kernel"
  sudo update-initramfs -c -k "${KERNEL_VERSION}" &>> "$LOG_FILE" || dbg::fail "Failed to update initramfs"
}

update_grub() {
  fmtr::log "Updating GRUB to set patched kernel as default"
  sudo cp /etc/default/grub /etc/default/grub.old || dbg::fail "Failed to backup grub config"

  sudo sed -i "s/^GRUB_DEFAULT=0/GRUB_DEFAULT='Advanced options for Ubuntu>Ubuntu, with Linux ${KERNEL_VERSION}'/" /etc/default/grub || dbg::fail "Failed to update grub config"
  sudo update-grub || dbg::fail "Failed to update grub"

  fmtr::info "GRUB has been updated to boot the patched kernel by default."
}

install_req_pkgs "Linux Kernel"
acquire_linux_source
patch_kernel
compile_kernel

if prmt::yes_or_no "$(fmtr::ask 'Would you like to install the patched Kernel')"; then
  install_kernel
fi

if prmt::yes_or_no "$(fmtr::ask 'Would you like to update GRUB to set the patched kernel as the default')"; then
  update_grub
else
  fmtr::info "Skipping GRUB update"
fi
