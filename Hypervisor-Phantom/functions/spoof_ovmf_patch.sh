#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && exit 1

source "./utils/formatter.sh"
source "./utils/prompter.sh"

declare -r CPU_VENDOR=$(case "$VENDOR_ID" in
  *AuthenticAMD*) echo "amd" ;;
  *GenuineIntel*) echo "intel" ;;
  *) fmtr::error "Unknown CPU vendor."; exit 1 ;;
esac)

readonly SRC_DIR="src"
readonly EDK2_URL="https://github.com/tianocore/edk2.git"
readonly EDK2_VERSION="edk2-stable202411"
readonly EDK2_DIR="$EDK2_VERSION"
readonly PATCH_DIR="../../patches/EDK2"
readonly OVMF_PATCH="${CPU_VENDOR}-${EDK2_VERSION}.patch"
readonly DEST_DIR="/usr/local/share/edk2/x64"
readonly CODE_DEST="${DEST_DIR}/OVMF_CODE.${EDK2_VERSION}.secboot.fd"
readonly VAR_DEST="${DEST_DIR}/OVMF_VARS.${EDK2_VERSION}.fd"

install_req_pkgs() {
  fmtr::log "Checking for missing packages"

  case "$DISTRO" in
    Arch)
      REQUIRED_PKGS=("base-devel" "acpica" "git" "nasm" "python")
      PKG_MANAGER="pacman"
      INSTALL_CMD="sudo pacman -S --noconfirm"
      CHECK_CMD="pacman -Q"
      ;;
    Debian)
      REQUIRED_PKGS=("build-essential" "uuid-dev" "iasl" "git" "nasm" "python-is-python3")
      PKG_MANAGER="apt"
      INSTALL_CMD="sudo apt -y install"
      CHECK_CMD="dpkg -l"
      ;;
    Fedora)
      REQUIRED_PKGS=("gcc" "gcc-c++" "make" "acpica-tools" "git" "nasm" "python3")
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
    fmtr::log "All required packages for EKD2 are already installed."
    return 0
  fi

  fmtr::warn "The required packages are missing: ${MISSING_PKGS[@]}"
  if prmt::yes_or_no "$(fmtr::ask 'Install the missing packages for EDK2?')"; then
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

acquire_edk2_source() {
  mkdir -p "$SRC_DIR" && cd "$SRC_DIR"

  if [ -d "$EDK2_DIR" ]; then
    if [ -d "$EDK2_DIR/.git" ]; then
      fmtr::warn "Directory $EDK2_DIR already exists and is a valid Git repository."
      if ! prmt::yes_or_no "$(fmtr::ask 'Delete and re-clone the EDK2 source?')"; then
        fmtr::info "Keeping existing directory. Skipping re-clone."; return
      fi
    else
      fmtr::warn "Directory $EDK2_DIR exists but is not a valid Git repository."
      if ! prmt::yes_or_no "$(fmtr::ask 'Delete and re-clone the EDK2 source?')"; then
        fmtr::info "Keeping existing directory. Skipping re-clone."; return
      fi
    fi
    rm -rf "$EDK2_DIR" || { fmtr::fatal "Failed to remove existing directory: $EDK2_DIR"; exit 1; }
    fmtr::info "Old directory deleted. Re-cloning..."
  fi

  fmtr::info "Downloading EDK2 source from GitHub..."
  git clone --single-branch --depth=1 --branch "$EDK2_VERSION" "$EDK2_URL" "$EDK2_DIR" &>> "$LOG_FILE" || { fmtr::fatal "Failed to clone repository."; exit 1; }
  cd "$EDK2_DIR" || { fmtr::fatal "Failed to change to EDK2 directory after cloning: $EDK2_DIR"; exit 1; }
  fmtr::info "Initializing submodules..."
  git submodule update --init &>> "$LOG_FILE" || { fmtr::fatal "Failed to initialize submodules."; exit 1; }
  fmtr::info "EDK2 source successfully acquired and submodules initialized."
}

patch_ovmf() {
  [ -d "$PATCH_DIR" ] || fmtr::fatal "Patch directory $PATCH_DIR not found!"
  [ -f "${PATCH_DIR}/${OVMF_PATCH}" ] || { fmtr::error "Patch file ${PATCH_DIR}/${OVMF_PATCH} not found!"; return 1; }
  fmtr::info "Patching OVMF with ${OVMF_PATCH}..."
  git apply < "${PATCH_DIR}/${OVMF_PATCH}" &>> "$LOG_FILE" || { fmtr::error "Failed to apply patch ${OVMF_PATCH}!"; return 1; }
  fmtr::info "Patch ${OVMF_PATCH} applied successfully."
}

compile_ovmf() {
  fmtr::log "Configuring build environment"
  local path="$(pwd)"
  export WORKSPACE="$path"
  export EDK_TOOLS_PATH="${path}/BaseTools"
  export CONF_PATH="${path}/Conf"

  make -C BaseTools &>> "$LOG_FILE"; source edksetup.sh &>> "$LOG_FILE"

  fmtr::log "Compiling OVMF"
  build \
    --platform='OvmfPkg/OvmfPkgX64.dsc' \
    --arch='X64' \
    --define='SECURE_BOOT_ENABLE=TRUE' \
    --buildtarget='RELEASE' \
    --tagname='GCC5' \
    -n0 \
    -sq \
    &>> "$LOG_FILE"

  sudo mkdir -p "$DEST_DIR"
  sudo cp "Build/OvmfX64/RELEASE_GCC5/FV/OVMF_CODE.fd" "$CODE_DEST"
  sudo cp "Build/OvmfX64/RELEASE_GCC5/FV/OVMF_VARS.fd" "$VAR_DEST"
  sudo chown '0:0' "$CODE_DEST" "$VAR_DEST"
  sudo chmod '755' "$CODE_DEST" "$VAR_DEST"
}

cleanup() {
  fmtr::log "Cleaning up"
  cd .. && rm -rf "$EDK2_DIR"
  cd .. && rmdir --ignore-fail-on-non-empty "$SRC_DIR"
}

main() {
  install_req_pkgs
  acquire_edk2_source
  patch_ovmf
  prmt::yes_or_no "$(fmtr::ask 'Build and install OVMF now?')" && compile_ovmf
  ! prmt::yes_or_no "$(fmtr::ask 'Keep the sources to make re-patching quicker?')" && cleanup
}

main "$@"
