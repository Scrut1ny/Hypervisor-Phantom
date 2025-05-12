#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && exit 1

source "./utils/formatter.sh"
source "./utils/prompter.sh"
source "./utils/packages.sh"

declare -r CPU_VENDOR=$(case "$VENDOR_ID" in
  *AuthenticAMD*) echo "amd" ;;
  *GenuineIntel*) echo "intel" ;;
  *) fmtr::error "Unknown CPU vendor."; exit 1 ;;
esac)

readonly SRC_DIR="src"
readonly EDK2_URL="https://github.com/tianocore/edk2.git"
readonly EDK2_VERSION="edk2-stable202502"
readonly EDK2_DIR="$EDK2_VERSION"
readonly PATCH_DIR="../../patches/EDK2"
readonly PATCH_OVMF="${CPU_VENDOR}-${EDK2_VERSION}.patch"
readonly OVMF_CODE_DEST_DIR="/usr/share/edk2/x64"
readonly OVMF_CODE_SECBOOT_DEST="${OVMF_CODE_DEST_DIR}/OVMF_CODE.secboot.4m.fd"
readonly OVMF_CODE_VAR_DEST="${OVMF_CODE_DEST_DIR}/OVMF_VARS.4m.fd"

REQUIRED_PKGS_Arch=(
  base-devel acpica git nasm python

  # Includes virt-fw-vars tool
  virt-firmware
)

REQUIRED_PKGS_Debian=(
  build-essential uuid-dev iasl git nasm python-is-python3

  # Includes virt-fw-vars tool
  virt-firmware
)

REQUIRED_PKGS_openSUSE=(
  gcc gcc-c++ make acpica git nasm python3 libuuid-devel

  # Includes virt-fw-vars tool
  virt-firmware
)

REQUIRED_PKGS_Fedora=(
  gcc gcc-c++ make acpica-tools git nasm python3 libuuid-devel

  # Includes virt-fw-vars tool
  virt-firmware
)

acquire_edk2_source() {
  mkdir -p "$SRC_DIR" && cd "$SRC_DIR"

  if [ -d "$EDK2_DIR" ]; then
    if [ -d "$EDK2_DIR/.git" ]; then
      fmtr::warn "Directory $EDK2_DIR already exists and is a valid Git repository."
      if ! prmt::yes_or_no "$(fmtr::ask 'Delete and re-clone the EDK2 source?')"; then
        fmtr::info "Keeping existing directory; Skipping re-clone."
        cd "$EDK2_DIR" || { fmtr::fatal "Failed to change to EDK2 directory after cloning: $EDK2_DIR"; exit 1; }
        return
      fi
    else
      fmtr::warn "Directory $EDK2_DIR exists but is not a valid Git repository."
      if ! prmt::yes_or_no "$(fmtr::ask 'Delete and re-clone the EDK2 source?')"; then
        fmtr::info "Keeping existing directory; Skipping re-clone."
        cd "$EDK2_DIR" || { fmtr::fatal "Failed to change to EDK2 directory after cloning: $EDK2_DIR"; exit 1; }
        return
      fi
    fi
    rm -rf "$EDK2_DIR" || { fmtr::fatal "Failed to remove existing directory: $EDK2_DIR"; exit 1; }
    fmtr::info "Directory purged; re-cloning repository..."
  fi

  git clone --single-branch --depth=1 --branch "$EDK2_VERSION" "$EDK2_URL" "$EDK2_DIR" &>> "$LOG_FILE" || { fmtr::fatal "Failed to clone repository."; exit 1; }
  cd "$EDK2_DIR" || { fmtr::fatal "Failed to change to EDK2 directory after cloning: $EDK2_DIR"; exit 1; }
  fmtr::info "Initializing submodules..."
  git submodule update --init &>> "$LOG_FILE" || { fmtr::fatal "Failed to initialize submodules."; exit 1; }
  fmtr::info "EDK2 source successfully acquired and submodules initialized."
  patch_ovmf
}

patch_ovmf() {
  [ -d "$PATCH_DIR" ] || fmtr::fatal "Patch directory $PATCH_DIR not found!"
  [ -f "${PATCH_DIR}/${OVMF_PATCH}" ] || { fmtr::error "Patch file ${PATCH_DIR}/${OVMF_PATCH} not found!"; return 1; }
  fmtr::info "Patching OVMF with ${OVMF_PATCH}..."
  git apply < "${PATCH_DIR}/${OVMF_PATCH}" &>> "$LOG_FILE" || { fmtr::error "Failed to apply patch ${OVMF_PATCH}!"; return 1; }
  fmtr::info "Patch ${OVMF_PATCH} applied successfully."
}

compile_ovmf() {

    # https://github.com/tianocore/tianocore.github.io/wiki/Common-instructions
    # https://github.com/tianocore/tianocore.github.io/wiki/How-to-build-OVMF

    export WORKSPACE="$(pwd)"
    export EDK_TOOLS_PATH="${WORKSPACE}/BaseTools"
    export CONF_PATH="${WORKSPACE}/Conf"

    fmtr::log "Building BaseTools (EDK II build tools)..."
    make -C BaseTools &>> "$LOG_FILE"; source edksetup.sh &>> "$LOG_FILE"

    fmtr::log "Compiling OVMF firmware with Secure Boot and TPM support..."
    build \
        -a X64 \
        -p OvmfPkg/OvmfPkgX64.dsc \
        -b RELEASE \
        -t GCC5 \
        -n 0 \
        -s \
        -q \
        --define SECURE_BOOT_ENABLE=TRUE \
        --define TPM_CONFIG_ENABLE=TRUE \
        --define TPM_ENABLE=TRUE \
        --define TPM1_ENABLE=TRUE \
        --define TPM2_ENABLE=TRUE \
        &>> "$LOG_FILE"

    fmtr::log "Converting OVMF firmware to .qcow2 format..."
    sudo qemu-img convert -f raw -O qcow2 "Build/OvmfX64/RELEASE_GCC5/FV/OVMF_CODE.fd" "$OVMF_CODE_DEST_DIR/OVMF_CODE.secboot.4m.qcow2"
    sudo qemu-img convert -f raw -O qcow2 "Build/OvmfX64/RELEASE_GCC5/FV/OVMF_VARS.fd" "$OVMF_CODE_DEST_DIR/OVMF_CODE_VARS.4m.qcow2"
compile_ovmf() {

    # https://github.com/tianocore/tianocore.github.io/wiki/Common-instructions
    # https://github.com/tianocore/tianocore.github.io/wiki/How-to-build-OVMF

    export WORKSPACE="$(pwd)"
    export EDK_TOOLS_PATH="${WORKSPACE}/BaseTools"
    export CONF_PATH="${WORKSPACE}/Conf"

    fmtr::log "Building BaseTools (EDK II build tools)..."
    make -C BaseTools &>> "$LOG_FILE"; source edksetup.sh &>> "$LOG_FILE"

    fmtr::log "Compiling OVMF firmware with Secure Boot and TPM support..."
    build \
        -a X64 \
        -p OvmfPkg/OvmfPkgX64.dsc \
        -b RELEASE \
        -t GCC5 \
        -n 0 \
        -s \
        -q \
        --define SECURE_BOOT_ENABLE=TRUE \
        --define TPM_CONFIG_ENABLE=TRUE \
        --define TPM_ENABLE=TRUE \
        --define TPM1_ENABLE=TRUE \
        --define TPM2_ENABLE=TRUE \
        &>> "$LOG_FILE"

    fmtr::log "Converting OVMF firmware to .qcow2 format..."
    sudo qemu-img convert -f raw -O qcow2 "Build/OvmfX64/RELEASE_GCC5/FV/OVMF_CODE.fd" "$OVMF_CODE_DEST_DIR/OVMF_CODE.secboot.4m.qcow2"
    sudo qemu-img convert -f raw -O qcow2 "Build/OvmfX64/RELEASE_GCC5/FV/OVMF_VARS.fd" "$OVMF_CODE_DEST_DIR/OVMF_CODE_VARS.4m.qcow2"

    sudo chown '0:0' "$OVMF_CODE_DEST_DIR/OVMF_CODE.secboot.4m.qcow2"
    sudo chmod '755' "$OVMF_CODE_DEST_DIR/OVMF_CODE.secboot.4m.qcow2"

}
    sudo chown '0:0' "$OVMF_CODE_DEST_DIR/OVMF_CODE.secboot.4m.qcow2"
    sudo chmod '755' "$OVMF_CODE_DEST_DIR/OVMF_CODE.secboot.4m.qcow2"

}

cleanup() {
  fmtr::log "Cleaning up"
  cd .. && rm -rf "$EDK2_DIR"
  cd .. && rmdir --ignore-fail-on-non-empty "$SRC_DIR"
}

main() {
  install_req_pkgs "EDK2/OVMF"
  acquire_edk2_source
  prmt::yes_or_no "$(fmtr::ask 'Build and install OVMF now?')" && compile_ovmf
  ! prmt::yes_or_no "$(fmtr::ask 'Keep the sources to make re-patching quicker?')" && cleanup
}

main "$@"
