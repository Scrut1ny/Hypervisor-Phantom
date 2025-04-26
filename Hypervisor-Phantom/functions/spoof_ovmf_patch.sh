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
readonly OVMF_PATCH="${CPU_VENDOR}-${EDK2_VERSION}.patch"
readonly DEST_DIR="/usr/share/edk2/x64/"
readonly CODE_DEST_SECBOOT="${DEST_DIR}/OVMF_CODE.secboot.4m.fd"
readonly CODE_DEST="${DEST_DIR}/OVMF_CODE.4m.fd"
readonly VAR_DEST="${DEST_DIR}/OVMF_VARS.4m.fd"

REQUIRED_PKGS_Arch=(
  base-devel acpica git nasm python
)

REQUIRED_PKGS_Debian=(
  build-essential uuid-dev iasl git nasm python-is-python3
)

REQUIRED_PKGS_openSUSE=(
  gcc gcc-c++ make acpica git nasm python3 libuuid-devel
)
REQUIRED_PKGS_Fedora=(
  gcc gcc-c++ make acpica-tools git nasm python3 libuuid-devel
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
  fmtr::log "Configuring build environment"
  local path="$(pwd)"
  export WORKSPACE="$path"
  export EDK_TOOLS_PATH="${path}/BaseTools"
  export CONF_PATH="${path}/Conf"

  # Common build defines for TPM and network features
  local common_defines=(
    "--define=NETWORK_HTTP_BOOT_ENABLE=TRUE"
    "--define=NETWORK_IP6_ENABLE=TRUE"
    "--define=TPM_CONFIG_ENABLE=TRUE"
    "--define=TPM_ENABLE=TRUE"
    "--define=TPM1_ENABLE=TRUE"
    "--define=TPM2_ENABLE=TRUE"
    "--define=NETWORK_TLS_ENABLE=TRUE"
  )

  make -C BaseTools &>> "$LOG_FILE"; source edksetup.sh &>> "$LOG_FILE"

  fmtr::log "Compiling OVMF with secure boot"
  build \
    --platform='OvmfPkg/OvmfPkgX64.dsc' \
    --arch='X64' \
    --define='SECURE_BOOT_ENABLE=TRUE' \
    "${common_defines[@]}" \
    --buildtarget='RELEASE' \
    --tagname='GCC5' \
    -n0 \
    -sq \
    &>> "$LOG_FILE"

  sudo mkdir -p "$DEST_DIR"
  sudo cp "Build/OvmfX64/RELEASE_GCC5/FV/OVMF_CODE.fd" "$CODE_DEST_SECBOOT"
  sudo cp "Build/OvmfX64/RELEASE_GCC5/FV/OVMF_VARS.fd" "$VAR_DEST"

  fmtr::log "Compiling OVMF without secure boot"
  build \
    --platform='OvmfPkg/OvmfPkgX64.dsc' \
    --arch='X64' \
    "${common_defines[@]}" \
    --buildtarget='RELEASE' \
    --tagname='GCC5' \
    -n0 \
    -sq \
    &>> "$LOG_FILE"

  sudo cp "Build/OvmfX64/RELEASE_GCC5/FV/OVMF_CODE.fd" "$CODE_DEST"

  sudo chown '0:0' "$CODE_DEST_SECBOOT" "$CODE_DEST" "$VAR_DEST"
  sudo chmod '755' "$CODE_DEST_SECBOOT" "$CODE_DEST" "$VAR_DEST"
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
