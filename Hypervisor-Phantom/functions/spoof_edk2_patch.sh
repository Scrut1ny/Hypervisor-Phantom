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
readonly PATCH_DIR="../../patches/EDK2"
readonly PATCH_OVMF="${CPU_VENDOR}-${EDK2_VERSION}.patch"
readonly OVMF_CODE_DEST_DIR="/usr/share/edk2/x64"

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

    sudo chown '0:0' "$OVMF_CODE_DEST_DIR/OVMF_CODE.secboot.4m.qcow2"
    sudo chmod '755' "$OVMF_CODE_DEST_DIR/OVMF_CODE.secboot.4m.qcow2"

}







cert_injection () {

    local UUID
    local TEMP_DIR="secboot_tmp"
    local VM_NAME
    local VARS_FILE
    local NVRAM_DIR="/var/lib/libvirt/qemu/nvram"

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
    mkdir -p "$TMP_DIR" && cd "$TMP_DIR" || exit 1

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
      --output "$NVRAM_DIR/${VM_NAME}_VARS.secboot.fd" \
      --secure-boot \
      --set-pk "$UUID" "WindowsOEMDevicesPK.pem" \
      --add-kek "$UUID" "MicCorKEKCA2011_2011-06-24.pem" \
      --add-kek "$UUID" "microsoft%20corporation%20kek%202k%20ca%202023.pem" \
      --add-db "$UUID" "MicCorUEFCA2011_2011-06-27.pem" \
      --add-db "$UUID" "MicWinProPCA2011_2011-10-19.pem" \
      --add-db "$UUID" "microsoft%20option%20rom%20uefi%20ca%202023.pem" \
      --add-db "$UUID" "microsoft%20uefi%20ca%202023.pem" \
      --add-db "$UUID" "windows%20uefi%20ca%202023.pem" \
      --set-dbx dbxupdate_x64.bin &>> "$LOG_FILE"

    fmtr::info "Secure Boot NVRAM generated at: $NVRAM_DIR/${VM_NAME}_VARS.secboot.fd"

    fmtr::log "Converting OVMF firmware to .qcow2 format..."
    sudo qemu-img convert -f raw -O qcow2 "$VARS_FILE" "$NVRAM_DIR/${VM_NAME}_VARS.secboot.qcow2"

}





cleanup() {

  fmtr::log "Cleaning up"
  cd ../.. && rm -rf "$EDK2_VERSION"
  cd .. && rmdir --ignore-fail-on-non-empty "$SRC_DIR"
  
}

main() {

  install_req_pkgs "EDK2/OVMF"
  acquire_edk2_source
  prmt::yes_or_no "$(fmtr::ask 'Build and install OVMF now?')" && compile_ovmf
  ! prmt::yes_or_no "$(fmtr::ask 'Keep the sources to make re-patching quicker?')" && cleanup
  
}

main "$@"
