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
readonly DEST_DIR="/usr/share/edk2/x64"
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
    else
      fmtr::warn "Directory $EDK2_DIR exists but is not a valid Git repository."
    fi

    if prmt::yes_or_no "$(fmtr::ask 'Delete the EDK2 source directory?')"; then
      rm -rf "$EDK2_DIR" || { fmtr::fatal "Failed to remove existing directory: $EDK2_DIR"; exit 1; }
      fmtr::info "Directory purged successfully."

      if prmt::yes_or_no "$(fmtr::ask 'Clone the EDK2 repository?')"; then
        git clone --single-branch --depth=1 --branch "$EDK2_VERSION" "$EDK2_URL" "$EDK2_DIR" &>> "$LOG_FILE" || { fmtr::fatal "Failed to clone repository."; exit 1; }
        cd "$EDK2_DIR" || { fmtr::fatal "Failed to change to EDK2 directory after cloning: $EDK2_DIR"; exit 1; }
        fmtr::info "Initializing submodules..."
        git submodule update --init &>> "$LOG_FILE" || { fmtr::fatal "Failed to initialize submodules."; exit 1; }
        fmtr::info "EDK2 source successfully acquired and submodules initialized."
        patch_ovmf
      else
        if prmt::yes_or_no "$(fmtr::ask 'Patch EDK2?')"; then
          patch_ovmf
        else
          fmtr::info "Skipping clone and patch."
        fi
      fi
    else
      fmtr::info "Keeping existing directory; Skipping deletion."
      cd "$EDK2_DIR" || { fmtr::fatal "Failed to change to EDK2 directory: $EDK2_DIR"; exit 1; }
    fi
  else
    git clone --single-branch --depth=1 --branch "$EDK2_VERSION" "$EDK2_URL" "$EDK2_DIR" &>> "$LOG_FILE" || { fmtr::fatal "Failed to clone repository."; exit 1; }
    cd "$EDK2_DIR" || { fmtr::fatal "Failed to change to EDK2 directory after cloning: $EDK2_DIR"; exit 1; }
    fmtr::info "Initializing submodules..."
    git submodule update --init &>> "$LOG_FILE" || { fmtr::fatal "Failed to initialize submodules."; exit 1; }
    fmtr::info "EDK2 source successfully acquired and submodules initialized."
    patch_ovmf
  fi
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

  # Convert .fd files to .qcow2 format
  fmtr::log "Converting OVMF firmware to .qcow2 format"
  sudo qemu-img convert -f raw -O qcow2 "$CODE_DEST_SECBOOT" "$DEST_DIR/OVMF_CODE.secboot.qcow2"
  sudo qemu-img convert -f raw -O qcow2 "$VAR_DEST" "$DEST_DIR/OVMF_VARS.qcow2"

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

  # Convert non-secure .fd file to .qcow2
  fmtr::log "Converting non-secure OVMF firmware to .qcow2 format"
  sudo qemu-img convert -f raw -O qcow2 "$CODE_DEST" "$DEST_DIR/OVMF_CODE.qcow2"

  sudo chown '0:0' "$CODE_DEST_SECBOOT" "$CODE_DEST" "$VAR_DEST"
  sudo chmod '755' "$CODE_DEST_SECBOOT" "$CODE_DEST" "$VAR_DEST"
}

secure_boot_setup() {
  local UUID
  local TMPDIR="secureboot_tmp"
  local OUTPUT_VARS="$1"
  local INPUT_VARS="$2"
  local VM_NAME
  local VARS_FILE

  # Prompt the user to select the UUID type
  fmtr::log "Select the UUID type to use for Secure Boot:

  1) Randomly generated UUID
  2) UEFI Global Variable UUID (EFI_GLOBAL_VARIABLE)
  3) Microsoft Vendor UUID (Microsoft Corporation)"

  read -rp "$(fmtr::ask 'Enter choice [1-3]: ')" uuid_choice
  case "$uuid_choice" in
    1) UUID=$(uuidgen) ;; # Randomized UUID
    2) UUID="8be4df61-93ca-11d2-aa0d-00e098032b8c" ;; # UEFI global variable
    3) UUID="77fa9abd-0359-4d32-bd60-28f4e78f784b" ;; # Microsoft vendor identity
    *) fmtr::error "Invalid choice. Defaulting to random UUID."; UUID=$(uuidgen) ;;
  esac

  # Create a temporary directory for downloading certificates
  mkdir -p "$TMPDIR"
  cd "$TMPDIR" || exit 1

  fmtr::info "Downloading Microsoft Secure Boot certificates..."

  declare -a URLS=(
    # PK
    "https://raw.githubusercontent.com/microsoft/secureboot_objects/main/PreSignedObjects/PK/Certificate/WindowsOEMDevicesPK.der"

    # KEK
    "https://raw.githubusercontent.com/microsoft/secureboot_objects/main/PreSignedObjects/KEK/Certificates/MicCorKEKCA2011_2011-06-24.der"
    "https://raw.githubusercontent.com/microsoft/secureboot_objects/main/PreSignedObjects/KEK/Certificates/microsoft%20corporation%20kek%202k%20ca%202023.der"

    # DB
    "https://raw.githubusercontent.com/microsoft/secureboot_objects/main/PreSignedObjects/DB/Certificates/MicCorUEFCA2011_2011-06-27.der"
    "https://raw.githubusercontent.com/microsoft/secureboot_objects/main/PreSignedObjects/DB/Certificates/MicWinProPCA2011_2011-10-19.der"
    "https://raw.githubusercontent.com/microsoft/secureboot_objects/main/PreSignedObjects/DB/Certificates/microsoft%20option%20rom%20uefi%20ca%202023.der"
    "https://raw.githubusercontent.com/microsoft/secureboot_objects/main/PreSignedObjects/DB/Certificates/microsoft%20uefi%20ca%202023.der"
    "https://raw.githubusercontent.com/microsoft/secureboot_objects/main/PreSignedObjects/DB/Certificates/windows%20uefi%20ca%202023.der"

    # DBX
    "https://uefi.org/sites/default/files/resources/dbxupdate_x64.bin"
  )

  for url in "${URLS[@]}"; do
    curl -sOL "$url"
  done

  # Convert DER certs to PEM format
  fmtr::info "Converting .der to .pem certs..."
  for der in *.der; do
    pem="${der%.der}.pem"
    openssl x509 -inform der -in "$der" -out "$pem"
  done

  # Prompt user to select the VM and corresponding VARS file
  fmtr::info "Available domains:"
  VMS=($(sudo virsh list --all --name))

  if [ ${#VMS[@]} -eq 0 ]; then
    fmtr::fatal "No VMs found!"
  fi

  # Display VM names and prompt the user
  PS3="Please select the VM to use for Secure Boot (or type 'cancel' to exit): "
  select VM_NAME in "${VMS[@]}"; do
    if [ "$VM_NAME" == "cancel" ]; then
      fmtr::info "Exiting Secure Boot setup."
      return
    fi

    if [ -n "$VM_NAME" ]; then
      VARS_FILE="/var/lib/libvirt/qemu/nvram/${VM_NAME}_VARS.fd"
      if [ ! -f "$VARS_FILE" ]; then
        fmtr::fatal "File not found: $VARS_FILE"
      fi
      fmtr::info "Using $VARS_FILE as the base VARS file."
      break
    fi
  done

  # If user has selected a VARS file, inject the certificates
  fmtr::info "Injecting Secure Boot certs into $VARS_FILE using UUID $UUID"

  sudo virt-fw-vars \
    --input "$VARS_FILE" \
    --output "$OUTPUT_VARS" \
    --secure-boot \
    --set-pk "$UUID" WindowsOEMDevicesPK.pem \
    --add-kek "$UUID" MicCorKEKCA2011_2011-06-24.pem \
    --add-kek "$UUID" microsoft\ corporation\ kek\ 2k\ ca\ 2023.pem \
    --add-db "$UUID" MicCorUEFCA2011_2011-06-27.pem \
    --add-db "$UUID" MicWinProPCA2011_2011-10-19.pem \
    --add-db "$UUID" microsoft\ option\ rom\ uefi\ ca\ 2023.pem \
    --add-db "$UUID" microsoft\ uefi\ ca\ 2023.pem \
    --add-db "$UUID" windows\ uefi\ ca\ 2023.pem \
    --set-dbx dbxupdate_x64.bin

  fmtr::info "Secure Boot NVRAM generated at: $OUTPUT_VARS"

  fmtr::info "Converting $OUTPUT_VARS to .qcow2 format..."
  sudo qemu-img convert -f raw -O qcow2 "$OUTPUT_VARS" "${OUTPUT_VARS%.fd}.qcow2"
  fmtr::info "Conversion to .qcow2 complete."

  # Clean up temporary files
  cd ..
  rm -rf "$TMPDIR"
}



cleanup() {
  fmtr::log "Cleaning up"
  cd .. && rm -rf "$EDK2_DIR"
  cd .. && rmdir --ignore-fail-on-non-empty "$SRC_DIR"
}

main() {
  install_req_pkgs "EDK2/OVMF"
  acquire_edk2_source

  if prmt::yes_or_no "$(fmtr::ask 'Build and install OVMF now?')"; then
    compile_ovmf
  fi

  if prmt::yes_or_no "$(fmtr::ask 'Generate a Secure Boot variable file now?')"; then
    local existing_vars="$VAR_DEST"
    if prmt::yes_or_no "$(fmtr::ask 'Use an existing OVMF_VARS.fd as base?')"; then
      read -rp "$(fmtr::ask 'Enter the path to the base VARS file: ')" existing_vars
      [[ ! -f "$existing_vars" ]] && fmtr::fatal "File not found: $existing_vars"
    fi
    secure_boot_setup "$DEST_DIR/OVMF_VARS.secboot.custom.fd" "$existing_vars"
  fi

  ! prmt::yes_or_no "$(fmtr::ask 'Keep the sources to make re-patching quicker?')" && cleanup
}

main "$@"
