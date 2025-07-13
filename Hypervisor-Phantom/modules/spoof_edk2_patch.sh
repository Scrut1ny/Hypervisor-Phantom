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
readonly EDK2_VERSION="edk2-stable202505"
readonly PATCH_DIR="../../patches/EDK2"
readonly OVMF_PATCH="${CPU_VENDOR}-${EDK2_VERSION}.patch"
readonly OVMF_CODE_DEST_DIR="/usr/share/edk2/x64"

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

  if [ -d "$EDK2_VERSION" ]; then

    fmtr::warn "EDK2 source directory '$EDK2_VERSION' detected."
    if prmt::yes_or_no "$(fmtr::ask 'Purge EDK2 source directory?')"; then
      rm -rf "$EDK2_VERSION" || { fmtr::fatal "Failed to remove existing directory: $EDK2_VERSION"; exit 1; }
      fmtr::info "Directory purged successfully."

      if prmt::yes_or_no "$(fmtr::ask 'Clone the EDK2 repository?')"; then
        git clone --single-branch --depth=1 --branch "$EDK2_VERSION" "$EDK2_URL" "$EDK2_VERSION" &>> "$LOG_FILE" || { fmtr::fatal "Failed to clone repository."; exit 1; }
        cd "$EDK2_VERSION" || { fmtr::fatal "Failed to change to EDK2 directory after cloning: $EDK2_VERSION"; exit 1; }
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
      fmtr::info "Kept existing directory; Skipping deletion."
      cd "$EDK2_VERSION" || { fmtr::fatal "Failed to change to EDK2 directory: $EDK2_VERSION"; exit 1; }
    fi
  else
    git clone --single-branch --depth=1 --branch "$EDK2_VERSION" "$EDK2_URL" "$EDK2_VERSION" &>> "$LOG_FILE" || { fmtr::fatal "Failed to clone repository."; exit 1; }
    cd "$EDK2_VERSION" || { fmtr::fatal "Failed to change to EDK2 directory after cloning: $EDK2_VERSION"; exit 1; }
    fmtr::info "Initializing submodules..."
    git submodule update --init &>> "$LOG_FILE" || { fmtr::fatal "Failed to initialize submodules."; exit 1; }
    fmtr::info "EDK2 source successfully acquired and submodules initialized."
    patch_ovmf
  fi
}

patch_ovmf() {
  # Apply custom ovmf patches
  [ -d "$PATCH_DIR" ] || fmtr::fatal "Patch directory $PATCH_DIR not found!"
  [ -f "${PATCH_DIR}/${OVMF_PATCH}" ] || { fmtr::error "Patch file ${PATCH_DIR}/${OVMF_PATCH} not found!"; return 1; }
  fmtr::log "Patching OVMF with ${OVMF_PATCH}..."
  git apply < "${PATCH_DIR}/${OVMF_PATCH}" &>> "$LOG_FILE" || { fmtr::error "Failed to apply patch ${OVMF_PATCH}!"; return 1; }
  fmtr::info "Patch ${OVMF_PATCH} applied successfully."

  # Apply hosts Boot Graphics Resource Table (BGRT) image
  fmtr::log "Choose BGRT logo image option for OVMF:"
  fmtr::format_text '\n  ' "[1]" " Use host's BGRT image (from /sys/firmware/acpi/bgrt/)" "$TEXT_BRIGHT_YELLOW"
  fmtr::format_text '  ' "[2]" " Use a custom BMP image (provide file path)" "$TEXT_BRIGHT_YELLOW"
  fmtr::format_text '  ' "[3]" " No logo (delete Logo.bmp)" "$TEXT_BRIGHT_YELLOW"
  fmtr::format_text '\n  ' "[0]" " Skip (keep current Logo.bmp, if present)" "$TEXT_BRIGHT_RED"

  while true; do
    read -rp "$(fmtr::ask 'Enter choice [0-3]: ')" logo_choice
    case "$logo_choice" in
      1)
        image_file=$(find /sys/firmware/acpi/bgrt/ -type f -exec file {} \; | grep -i 'bitmap' | cut -d: -f1)
        if [ -n "$image_file" ]; then
          cp -f "$image_file" "MdeModulePkg/Logo/Logo.bmp"
          fmtr::info "Host BGRT logo image copied successfully."
        else
          fmtr::info "No host BGRT bitmap image found."
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
      3)
        if [ -f "MdeModulePkg/Logo/Logo.bmp" ]; then
          rm -f "MdeModulePkg/Logo/Logo.bmp"
          fmtr::info "Logo.bmp deleted (no logo will be used)."
        else
          fmtr::info "Logo.bmp not present, nothing to delete."
        fi
        break
        ;;
      0)
        fmtr::info "Skipping BGRT logo modification."
        break
        ;;
      *)
        fmtr::error "Invalid choice, please try again."
        ;;
    esac
  done
}

compile_ovmf() {
    # https://github.com/tianocore/tianocore.github.io/wiki/Common-instructions
    # https://github.com/tianocore/tianocore.github.io/wiki/How-to-build-OVMF

    export WORKSPACE="$(pwd)"
    export EDK_TOOLS_PATH="${WORKSPACE}/BaseTools"
    export CONF_PATH="${WORKSPACE}/Conf"

    fmtr::log "Building BaseTools (EDK II build tools)..."
    {
      make -C BaseTools; source edksetup.sh
    } &>> "$LOG_FILE"

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

    sudo mkdir -p "$OVMF_CODE_DEST_DIR"

    fmtr::log "Converting compiled OVMF firmware to .qcow2 format..."
    sudo qemu-img convert -f raw -O qcow2 "Build/OvmfX64/RELEASE_GCC5/FV/OVMF_CODE.fd" "$OVMF_CODE_DEST_DIR/OVMF_CODE.secboot.4m.qcow2"
    sudo qemu-img convert -f raw -O qcow2 "Build/OvmfX64/RELEASE_GCC5/FV/OVMF_VARS.fd" "$OVMF_CODE_DEST_DIR/OVMF_VARS.4m.qcow2"

    sudo chown root:root /usr/share/edk2/x64/*
    sudo chmod 644 /usr/share/edk2/x64/*
}

cert_injection () {
    local UUID
    local TEMP_DIR=$(mktemp -d)
    local VM_NAME
    local VARS_FILE
    local NVRAM_DIR="/var/lib/libvirt/qemu/nvram"

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

    # Prompt the user to select the UUID type
    fmtr::log "Select the UUID type to use for Secure Boot:"
    fmtr::format_text '\n  ' "[1]" " Randomly generated UUID" "$TEXT_BRIGHT_YELLOW"
    fmtr::format_text '  ' "[2]" " UEFI Global Variable UUID (EFI_GLOBAL_VARIABLE)" "$TEXT_BRIGHT_YELLOW"
    fmtr::format_text '  ' "[3]" " Microsoft Vendor UUID (Microsoft Corporation)" "$TEXT_BRIGHT_YELLOW"
    fmtr::format_text '\n  ' "[0]" " Exit" "$TEXT_BRIGHT_RED"

    read -rp "$(fmtr::ask 'Enter choice [1-3]: ')" uuid_choice
    case "$uuid_choice" in
      0) exit 0 ;;
      1) UUID=$(uuidgen) ;;
      2) UUID="8be4df61-93ca-11d2-aa0d-00e098032b8c" ;;
      3) UUID="77fa9abd-0359-4d32-bd60-28f4e78f784b" ;;
      *) fmtr::error "Invalid choice. Defaulting to random UUID."; UUID=$(uuidgen) ;;
    esac

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

    fmtr::info "Injecting Secure Boot certs into '$VARS_FILE'..."

    sudo virt-fw-vars \
      --input "$VARS_FILE" \
      --output "$NVRAM_DIR/${VM_NAME}_SECURE_VARS.qcow2" \
      --secure-boot \
      --set-pk "$UUID" "WindowsOEMDevicesPK.der" \
      --add-kek "$UUID" "MicCorKEKCA2011_2011-06-24.der" \
      --add-kek "$UUID" "microsoft%20corporation%20kek%202k%20ca%202023.der" \
      --add-db "$UUID" "MicCorUEFCA2011_2011-06-27.der" \
      --add-db "$UUID" "MicWinProPCA2011_2011-10-19.der" \
      --add-db "$UUID" "microsoft%20option%20rom%20uefi%20ca%202023.der" \
      --add-db "$UUID" "microsoft%20uefi%20ca%202023.der" \
      --add-db "$UUID" "windows%20uefi%20ca%202023.der" \
      --set-dbx dbxupdate_x64.bin &>> "$LOG_FILE"

    fmtr::log "Secure VARS generated at '${NVRAM_DIR}/${VM_NAME}_SECURE_VARS.qcow2'"

    fmtr::info "Cleaning up..."
    rm -rf "/tmp/$TEMP_DIR"
}

cleanup() {
    fmtr::log "Cleaning up"
    cd .. && rm -rf "$EDK2_VERSION"
    cd .. && rmdir --ignore-fail-on-non-empty "$SRC_DIR"
}

main() {
    install_req_pkgs "EDK2"

    while true; do

      fmtr::format_text '\n  ' "[1]" " Install patched OVMF firmware" "$TEXT_BRIGHT_YELLOW"
      fmtr::format_text '  ' "[2]" " Inject Secure Boot certificates into a VARS file" "$TEXT_BRIGHT_YELLOW"
      fmtr::format_text '\n  ' "[0]" " Exit" "$TEXT_BRIGHT_RED"

      read -rp "$(fmtr::ask 'Enter choice [0-2]: ')" user_choice
      case "$user_choice" in
        1)
          acquire_edk2_source
          if prmt::yes_or_no "$(fmtr::ask 'Build, compile, and install OVMF now?')"; then
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
