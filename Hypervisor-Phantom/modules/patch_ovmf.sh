#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && { echo "Required environment variables not set."; exit 1; }

source "./utils/formatter.sh"
source "./utils/prompter.sh"
source "./utils/packages.sh"

declare -r CPU_VENDOR=$(case "$VENDOR_ID" in
  *AuthenticAMD*) echo "amd" ;;
  *GenuineIntel*) echo "intel" ;;
  *) fmtr::error "Unknown CPU Vendor ID."; exit 1 ;;
esac)

readonly SRC_DIR="src"
readonly EDK2_URL="https://github.com/tianocore/edk2.git"
readonly EDK2_TAG="edk2-stable202508"
readonly PATCH_DIR="../../patches/EDK2"
readonly OVMF_PATCH="${CPU_VENDOR}-${EDK2_TAG}.patch"












REQUIRED_PKGS_Arch=(
  base-devel acpica git nasm python patch

  # Includes virt-fw-vars tool
  virt-firmware
)

REQUIRED_PKGS_Debian=(
  build-essential uuid-dev acpica-tools git nasm python-is-python3 patch

  # Includes virt-fw-vars tool
  python3-virt-firmware
)

REQUIRED_PKGS_openSUSE=(
  gcc gcc-c++ make acpica git nasm python3 libuuid-devel patch

  # Includes virt-fw-vars tool
  virt-firmware
)

REQUIRED_PKGS_Fedora=(
  gcc gcc-c++ make acpica-tools git nasm python3 libuuid-devel patch

  # Includes virt-fw-vars tool
  python3-virt-firmware
)












acquire_edk2_source() {
  mkdir -p "$SRC_DIR" && cd "$SRC_DIR"

  if [ -d "$EDK2_TAG" ]; then

    fmtr::warn "EDK2 source directory '$EDK2_TAG' detected."
    if prmt::yes_or_no "$(fmtr::ask 'Purge EDK2 source directory?')"; then
      rm -rf "$EDK2_TAG" || { fmtr::fatal "Failed to remove existing directory: $EDK2_TAG"; exit 1; }
      fmtr::info "Directory purged successfully."

      if prmt::yes_or_no "$(fmtr::ask 'Clone the EDK2 repository?')"; then
        git clone --single-branch --depth=1 --branch "$EDK2_TAG" "$EDK2_URL" "$EDK2_TAG" &>> "$LOG_FILE" || { fmtr::fatal "Failed to clone repository."; exit 1; }
        cd "$EDK2_TAG" || { fmtr::fatal "Failed to change to EDK2 directory after cloning: $EDK2_TAG"; exit 1; }
        fmtr::info "Initializing submodules... (be patient)"
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
      fmtr::info "Kept existing directory; Skipping deletion."
      cd "$EDK2_TAG" || { fmtr::fatal "Failed to change to EDK2 directory: $EDK2_TAG"; exit 1; }
    fi
  else
    git clone --single-branch --depth=1 --branch "$EDK2_TAG" "$EDK2_URL" "$EDK2_TAG" &>> "$LOG_FILE" || { fmtr::fatal "Failed to clone repository."; exit 1; }
    cd "$EDK2_TAG" || { fmtr::fatal "Failed to change to EDK2 directory after cloning: $EDK2_TAG"; exit 1; }
    fmtr::info "Initializing submodules... (be patient)"
    git submodule update --init &>> "$LOG_FILE" || { fmtr::fatal "Failed to initialize submodules."; exit 1; }
    fmtr::info "EDK2 source successfully acquired and submodules initialized."
    patch_ovmf
  fi
}














patch_ovmf() {
  # Apply custom OVMF patches
  [ -d "$PATCH_DIR" ] || fmtr::fatal "Patch directory $PATCH_DIR not found!"
  [ -f "${PATCH_DIR}/${OVMF_PATCH}" ] || { fmtr::error "Patch file ${PATCH_DIR}/${OVMF_PATCH} not found!"; return 1; }
  fmtr::log "Patching OVMF with ${OVMF_PATCH}..."
  git apply < "${PATCH_DIR}/${OVMF_PATCH}" &>> "$LOG_FILE" || { fmtr::error "Failed to apply patch ${OVMF_PATCH}!"; return 1; }
  fmtr::info "Patch ${OVMF_PATCH} applied successfully."

  # Apply custom BGRT BMP boot logo image
  fmtr::log "Choose BGRT BMP boot logo image option for OVMF:"
  fmtr::format_text '\n  ' "[1]" " Apply host's (default)" "$TEXT_BRIGHT_YELLOW"
  fmtr::format_text '  ' "[2]" " Apply custom (provide path)" "$TEXT_BRIGHT_YELLOW"

  while true; do
    read -rp "$(fmtr::ask 'Enter choice [1-2]: ')" logo_choice
    logo_choice=${logo_choice:-1} # default to 1 if empty
    case "$logo_choice" in
      1)
        image_file=$(find /sys/firmware/acpi/bgrt/ -type f -exec file {} \; | grep -i 'bitmap' | cut -d: -f1)
        if [ -n "$image_file" ]; then
          cp -f "$image_file" "MdeModulePkg/Logo/Logo.bmp"
          fmtr::info "Image replaced successfully."
        else
          fmtr::error "Image not found."
        fi
        break
        ;;
      2)
        while true; do
          read -rp "$(fmtr::ask 'Enter full path to your BMP image: ')" custom_bmp
          if [ ! -f "$custom_bmp" ]; then
            fmtr::error "File does not exist. Please try again."
            continue
          fi
          # Check file is BMP using the 'file' command
          file_type=$(file -b --mime-type "$custom_bmp")
          if [[ "$file_type" != "image/bmp" && "$file_type" != "application/octet-stream" ]]; then
            fmtr::error "File is not a BMP image (detected: $file_type). Please provide a valid BMP file."
            continue
          fi
          cp -f "$custom_bmp" "MdeModulePkg/Logo/Logo.bmp"
          fmtr::info "Custom BMP logo image copied successfully."
          break
        done
        break
        ;;
      *)
        fmtr::error "Invalid choice, please try again."
        ;;
    esac
  done
}

















compile_ovmf() {
    export WORKSPACE="$(pwd)"
    export EDK_TOOLS_PATH="${WORKSPACE}/BaseTools"
    export CONF_PATH="${WORKSPACE}/Conf"

    fmtr::log "Building BaseTools (EDK II build tools)..."
    { make -C BaseTools; source edksetup.sh; } &>> "$LOG_FILE"

    fmtr::log "Compiling OVMF with SB and TPM support..."
    build -a X64 -p OvmfPkg/OvmfPkgX64.dsc -b RELEASE -t GCC5 -n 0 -s -q \
        --define SECURE_BOOT_ENABLE=TRUE \
        --define TPM_CONFIG_ENABLE=TRUE \
        --define TPM_ENABLE=TRUE \
        --define TPM1_ENABLE=TRUE \
        --define TPM2_ENABLE=TRUE \
        &>> "$LOG_FILE"

    fmtr::log "Converting compiled OVMF to .qcow2 format..."
    mkdir -p "../output/firmware"
    sudo qemu-img convert -f raw -O qcow2 "Build/OvmfX64/RELEASE_GCC5/FV/OVMF_CODE.fd" "../output/firmware/OVMF_CODE.secboot.4m.qcow2"
    sudo qemu-img convert -f raw -O qcow2 "Build/OvmfX64/RELEASE_GCC5/FV/OVMF_VARS.fd" "../output/firmware/OVMF_VARS.4m.qcow2"
}














cert_injection() {
    local UUID="77fa9abd-0359-4d32-bd60-28f4e78f784b" TEMP_DIR=$(mktemp -d) VM_NAME VARS_FILE NVRAM_DIR="/var/lib/libvirt/qemu/nvram"

    cd "$TEMP_DIR" || exit 1

    # Prompt user to select VM
    fmtr::log "Available domains:"; echo ""

    VMS=($(sudo virsh list --all --name))
    if [ ${#VMS[@]} -eq 0 ]; then
      fmtr::fatal "No domains found!"
      rm -rf "/tmp/$TEMP_DIR"
      exit 1
    fi

    # Display VMs with formatting and two-space spacing
    for i in "${!VMS[@]}"; do
      index=$((i + 1))
      fmtr::format_text '  ' "[$index]" "  ${VMS[$i]}  " "$TEXT_BRIGHT_YELLOW"
    done
    fmtr::format_text '\n  ' "[0]" "  Cancel  " "$TEXT_BRIGHT_RED"

    while true; do
      read -rp "$(fmtr::ask 'Enter your choice [0-'"${#VMS[@]}"']: ')" vm_choice
      if [[ "$vm_choice" == "0" ]]; then
        fmtr::log "Exiting Secure Boot setup."
        return
      elif [[ "$vm_choice" =~ ^[0-9]+$ ]] && (( vm_choice >= 1 && vm_choice <= ${#VMS[@]} )); then
        VM_NAME="${VMS[$((vm_choice - 1))]}"
        VARS_FILE="$NVRAM_DIR/${VM_NAME}_VARS.qcow2"
        if [ ! -f "$VARS_FILE" ]; then
          fmtr::fatal "File not found: $VARS_FILE"
          exit 1
        fi
        fmtr::log "Using '$VARS_FILE' as the base VARS file."
        break
      else
        fmtr::error "Invalid selection, please try again."
      fi
    done

    fmtr::info "Downloading Microsoft Secure Boot certificates..."
    declare -A CERTS=(
        # PK Certificates
        ["ms_pk_oem.der"]="https://raw.githubusercontent.com/microsoft/secureboot_objects/main/PreSignedObjects/PK/Certificate/WindowsOEMDevicesPK.der"
      
        # KEK Certificates
        ["ms_kek_2023.der"]="https://raw.githubusercontent.com/microsoft/secureboot_objects/main/PreSignedObjects/KEK/Certificates/microsoft%20corporation%20kek%202k%20ca%202023.der"
      
        # DB Certificates
        ["ms_db_optionrom_2023.der"]="https://raw.githubusercontent.com/microsoft/secureboot_objects/main/PreSignedObjects/DB/Certificates/microsoft%20option%20rom%20uefi%20ca%202023.der"
        ["ms_db_uefi_2023.der"]="https://raw.githubusercontent.com/microsoft/secureboot_objects/main/PreSignedObjects/DB/Certificates/microsoft%20uefi%20ca%202023.der"
        ["ms_db_windows_2023.der"]="https://raw.githubusercontent.com/microsoft/secureboot_objects/main/PreSignedObjects/DB/Certificates/windows%20uefi%20ca%202023.der"
      
        # DBX
        ["dbxupdate_x64.bin"]="https://uefi.org/sites/default/files/resources/dbxupdate_x64.bin"
    )
    
    for filename in "${!CERTS[@]}"; do
        url="${CERTS[$filename]}"
        wget -q -O "$filename" "$url"
    done

    fmtr::info "Injecting Secure Boot certs into '$VARS_FILE'..."

    sudo virt-fw-vars \
      --input "$VARS_FILE" \
      --output "$NVRAM_DIR/${VM_NAME}_SECURE_VARS.qcow2" \
      --secure-boot \
      --set-pk "$UUID" "ms_pk_oem.der" \
      --add-kek "$UUID" "ms_kek_2023.der" \
      --add-db "$UUID" "ms_db_optionrom_2023.der" \
      --add-db "$UUID" "ms_db_uefi_2023.der" \
      --add-db "$UUID" "ms_db_windows_2023.der" \
      --set-dbx dbxupdate_x64.bin &>> "$LOG_FILE"

    fmtr::log "Secure VARS generated at '${NVRAM_DIR}/${VM_NAME}_SECURE_VARS.qcow2'"

    fmtr::info "Cleaning up..."
    rm -rf "/tmp/$TEMP_DIR"
}









cleanup() {
    fmtr::log "Cleaning up"
    cd .. && rm -rf "$EDK2_TAG"
    cd .. && rmdir --ignore-fail-on-non-empty "$SRC_DIR"
}











main() {
    install_req_pkgs "EDK2"

    while true; do

      fmtr::format_text '\n  ' "[1]" " Create patched OVMF" "$TEXT_BRIGHT_YELLOW"
      fmtr::format_text '  ' "[2]" " VARS SB cert injection" "$TEXT_BRIGHT_YELLOW"
      fmtr::format_text '\n  ' "[0]" " Exit" "$TEXT_BRIGHT_RED"

      read -rp "$(fmtr::ask 'Enter choice [0-2]: ')" user_choice
      case "$user_choice" in
        1)
          acquire_edk2_source
          if prmt::yes_or_no "$(fmtr::ask 'Create patched OVMF now?')"; then
            compile_ovmf
          fi
          ! prmt::yes_or_no "$(fmtr::ask 'Keep EDK2 source for faster re-patching?')" && cleanup
          exit 0
          ;;
        2)
          cert_injection
          exit 0
          ;;
        0)
          fmtr::info "Exiting."
          exit 0
          ;;
        *)
          fmtr::error "Invalid option, please try again."
          ;;
      esac
      prmt::quick_prompt "$(fmtr::info 'Press any key to continue...')"
    done
}

main "$@"
