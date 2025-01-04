#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && exit 1

source "utils/debugger.sh"
source "utils/prompter.sh"
source "utils/formatter.sh"

readonly SRC_DIR="src"
readonly KERNEL_MAJOR="6"
readonly KERNEL_VERSION="${KERNEL_MAJOR}.10.6"
readonly KERNEL_DIR="linux-${KERNEL_VERSION}"
readonly KERNEL_ARCHIVE="${KERNEL_DIR}.tar.xz"
readonly KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_MAJOR}.x/${KERNEL_ARCHIVE}"
readonly PATCH_DIR="../../patches/Kernel"
readonly LINUX_PATCH="${KERNEL_DIR}.patch"

install_req_pkgs() {
  fmtr::log "Checking for missing packages"

  case "$DISTRO" in
    Arch)
      REQUIRED_PKGS=("base-devel" "ncurses" "bison" "flex" "openssl" "elfutils")
      PKG_MANAGER="pacman"
      INSTALL_CMD="sudo pacman -S --noconfirm"
      CHECK_CMD="pacman -Q"
      ;;
    Debian)
      REQUIRED_PKGS=("build-essential" "libncurses-dev" "bison" "flex" "libssl-dev" "libelf-dev")
      PKG_MANAGER="apt"
      INSTALL_CMD="sudo apt -y install"
      CHECK_CMD="dpkg -l"
      ;;
    Fedora)
      REQUIRED_PKGS=("gcc" "gcc-c++" "make" "ncurses-devel" "bison" "flex" "elfutils-libelf-devel" "openssl-devel")
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
    fmtr::log "All required packages for the Linux Kernel are already installed."
    return 0
  fi

  fmtr::warn "The required packages are missing: ${MISSING_PKGS[@]}"
  if prmt::yes_or_no "$(fmtr::ask 'Install the missing packages for the Linux Kernel?')"; then
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

install_req_pkgs
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
