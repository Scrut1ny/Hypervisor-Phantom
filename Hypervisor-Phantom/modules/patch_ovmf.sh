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

readonly SRC_DIR="$(pwd)/src"
readonly EDK2_URL="https://github.com/tianocore/edk2.git"
readonly EDK2_TAG="edk2-stable202508"
readonly PATCH_DIR="$(pwd)/patches/EDK2"
readonly OVMF_PATCH="${CPU_VENDOR}-${EDK2_TAG}.patch"

REQUIRED_PKGS_Arch=(base-devel acpica git nasm python patch virt-firmware)
REQUIRED_PKGS_Debian=(build-essential uuid-dev acpica-tools git nasm python-is-python3 patch python3-virt-firmware)
REQUIRED_PKGS_openSUSE=(gcc gcc-c++ make acpica git nasm python3 libuuid-devel patch virt-firmware)
REQUIRED_PKGS_Fedora=(gcc gcc-c++ make acpica-tools git nasm python3 libuuid-devel patch python3-virt-firmware)

################################################################################
# Acquire EDK2 source
################################################################################
acquire_edk2_source() {
  mkdir -p "$SRC_DIR" && cd "$SRC_DIR" || { fmtr::fatal "Failed to enter source dir: $SRC_DIR"; exit 1; }

  clone_init() {
    git clone --single-branch --depth=1 --branch "$EDK2_TAG" "$EDK2_URL" "$EDK2_TAG" &>>"$LOG_FILE" \
      || { fmtr::fatal "Failed to clone repository."; exit 1; }
    cd "$EDK2_TAG" || { fmtr::fatal "Failed to enter EDK2 directory: $EDK2_TAG"; exit 1; }
    fmtr::info "Initializing submodules... (be patient)"
    git submodule update --init &>>"$LOG_FILE" \
      || { fmtr::fatal "Failed to initialize submodules."; exit 1; }
    fmtr::info "EDK2 source successfully acquired and submodules initialized."
    patch_ovmf
  }

  if [ -d "$EDK2_TAG" ]; then
    fmtr::warn "EDK2 source directory '$EDK2_TAG' detected."
    if prmt::yes_or_no "$(fmtr::ask 'Purge EDK2 source directory?')"; then
      rm -rf "$EDK2_TAG" || { fmtr::fatal "Failed to remove existing directory: $EDK2_TAG"; exit 1; }
      fmtr::info "Directory purged successfully."
      if prmt::yes_or_no "$(fmtr::ask 'Clone the EDK2 repository?')"; then
        clone_init
      else
        fmtr::info "Skipping clone; nothing to patch since source was purged."
      fi
    else
      fmtr::info "Kept existing directory; skipping deletion."
      cd "$EDK2_TAG" || { fmtr::fatal "Failed to enter EDK2 directory: $EDK2_TAG"; exit 1; }
      if prmt::yes_or_no "$(fmtr::ask 'Patch EDK2?')"; then
        patch_ovmf
      else
        fmtr::info "Skipping patch."
      fi
    fi
  else
    clone_init
  fi
}

################################################################################
# Patch OVMF
################################################################################
patch_ovmf() {
  [ -d "$PATCH_DIR" ] || fmtr::fatal "Patch directory $PATCH_DIR not found!"
  [ -f "$PATCH_DIR/$OVMF_PATCH" ] || { fmtr::error "Patch file $PATCH_DIR/$OVMF_PATCH not found!"; return 1; }

  fmtr::log "Patching OVMF with '$OVMF_PATCH'..."
  git apply < "$PATCH_DIR/$OVMF_PATCH" &>>"$LOG_FILE" || { fmtr::error "Failed to apply patch '$OVMF_PATCH'!"; return 1; }
  fmtr::info "Patch '$OVMF_PATCH' applied successfully."

  fmtr::log "Choose BGRT BMP boot logo image option for OVMF:"
  fmtr::format_text '\n  ' "[1]" " Apply host's (default)" "$TEXT_BRIGHT_YELLOW"
  fmtr::format_text '  ' "[2]" " Apply custom (provide path)" "$TEXT_BRIGHT_YELLOW"

  while :; do
    read -rp "$(fmtr::ask 'Enter choice [1-2]: ')" logo_choice && : "${logo_choice:=1}"
    case "$logo_choice" in
      1)
        [ -f /sys/firmware/acpi/bgrt/image ] && cp /sys/firmware/acpi/bgrt/image MdeModulePkg/Logo/Logo.bmp \
          && fmtr::info "Image replaced successfully." \
          || fmtr::error "Image not found or failed to copy."
        break
        ;;
      2)
        while :; do
          read -rp "$(fmtr::ask 'Enter full path to your BMP image: ')" custom_bmp
          if [ ! -f "$custom_bmp" ]; then
            fmtr::error "File does not exist. Try again."
            continue
          fi

          # Validate BMP
          file_type=$(file -b --mime-type "$custom_bmp")
          head_magic=$(head -c2 "$custom_bmp")
          file_info=$(file "$custom_bmp")

          if ! case "$file_type" in image/bmp|image/x-bmp|image/x-ms-bmp|application/octet-stream) true;; *) false;; esac \
             || [ "$head_magic" != "BM" ] \
             || echo "$file_info" | grep -qi 'compressed' \
             || ! echo "$file_info" | grep -qE '24-bit|32-bit'; then
            fmtr::error "Invalid BMP: must be uncompressed 24/32-bit BMP with BM signature."
            continue
          fi

          # Dimension check (parse BMP header)
          width=$(od -An -t u4 -j 18 -N 4 "$custom_bmp" | tr -d ' ')
          height=$(od -An -t u4 -j 22 -N 4 "$custom_bmp" | tr -d ' ')
          if [ -n "$width" ] && [ -n "$height" ] && ([ "$width" -gt 1024 ] || [ "$height" -gt 768 ]); then
            fmtr::error "BMP too large: ${width}×${height}, must be ≤1024×768."
            continue
          fi

          cp "$custom_bmp" MdeModulePkg/Logo/Logo.bmp && fmtr::info "Custom BMP copied successfully."
          break 2
        done
        ;;
      *) fmtr::error "Invalid choice, try again." ;;
    esac
  done
}

################################################################################
# Compile OVMF
################################################################################
compile_ovmf() {
  export WORKSPACE=$(pwd)
  export EDK_TOOLS_PATH="$WORKSPACE/BaseTools"
  export CONF_PATH="$WORKSPACE/Conf"

  fmtr::log "Building BaseTools (EDK II build tools)..."
  [ -d BaseTools/Build ] || { make -C BaseTools && source edksetup.sh; } &>>"$LOG_FILE" || { fmtr::fatal "Failed to build BaseTools"; exit 1; }

  fmtr::log "Compiling OVMF with SB and TPM support..."
  build -a X64 -p OvmfPkg/OvmfPkgX64.dsc -b RELEASE -t GCC5 -n 0 -s -q \
    --define SECURE_BOOT_ENABLE=TRUE \
    --define TPM_CONFIG_ENABLE=TRUE \
    --define TPM_ENABLE=TRUE \
    --define TPM1_ENABLE=TRUE \
    --define TPM2_ENABLE=TRUE &>>"$LOG_FILE" || { fmtr::fatal "OVMF build failed"; exit 1; }

  fmtr::log "Converting compiled OVMF to .qcow2 format..."
  out_dir="../output/firmware"
  mkdir -p "$out_dir"
  for f in CODE.secboot.4m VARS.4m; do
    src="Build/OvmfX64/RELEASE_GCC5/FV/OVMF_${f%%.*}.fd"
    dest="$out_dir/OVMF_${f}.qcow2"
    sudo qemu-img convert -f raw -O qcow2 "$src" "$dest" || { fmtr::fatal "Failed to convert $src"; exit 1; }
  done
}

################################################################################
# Certificate injection
################################################################################
cert_injection() {
  readonly URL="https://raw.githubusercontent.com/microsoft/secureboot_objects/main/PreSignedObjects"
  readonly UUID="77fa9abd-0359-4d32-bd60-28f4e78f784b"
  local TEMP_DIR VM_NAME VARS_FILE NVRAM_DIR="/var/lib/libvirt/qemu/nvram"

  TEMP_DIR=$(mktemp -d)
  cd "$TEMP_DIR" || { fmtr::fatal "Failed to enter temp dir"; exit 1; }

  fmtr::log "Available domains:"; echo ""
  mapfile -t VMS < <(sudo virsh list --all --name | grep -v '^$')
  [ ${#VMS[@]} -gt 0 ] || { fmtr::fatal "No domains found!"; rm -rf "$TEMP_DIR"; exit 1; }

  for i in "${!VMS[@]}"; do
    fmtr::format_text '  ' "[$((i+1))]" " ${VMS[$i]}" "$TEXT_BRIGHT_YELLOW"
  done
  fmtr::format_text '\n  ' "[0]" " Cancel" "$TEXT_BRIGHT_RED"

  while :; do
    read -rp "$(fmtr::ask "Enter your choice [0-${#VMS[@]}]: ")" vm_choice
    case "$vm_choice" in
      0) fmtr::log "Exiting Secure Boot certification injection setup."; rm -rf "$TEMP_DIR"; return ;;
      ''|*[!0-9]*) fmtr::error "Invalid selection, try again." ;;
      *)
        (( vm_choice >= 1 && vm_choice <= ${#VMS[@]} )) || { fmtr::error "Invalid selection, try again."; continue; }
        VM_NAME="${VMS[$((vm_choice-1))]}"
        VARS_FILE="$NVRAM_DIR/${VM_NAME}_VARS.qcow2"
        [ -f "$VARS_FILE" ] || { fmtr::fatal "File not found: $VARS_FILE"; exit 1; }
        fmtr::log "Using '$VARS_FILE' as the base VARS file."
        break
        ;;
    esac
  done

  fmtr::info "Downloading Microsoft's Secure Boot certifications..."
  declare -A CERTS=(
    ["ms_pk_oem.der"]="$URL/PK/Certificate/WindowsOEMDevicesPK.der"
    ["ms_kek_2011.der"]="$URL/KEK/Certificates/MicCorKEKCA2011_2011-06-24.der"
    ["ms_kek_2023.der"]="$URL/KEK/Certificates/microsoft%20corporation%20kek%202k%20ca%202023.der"
    ["ms_db_uef_2011.der"]="$URL/DB/Certificates/MicCorUEFCA2011_2011-06-27.der"
    ["ms_db_pro_2011.der"]="$URL/DB/Certificates/MicWinProPCA2011_2011-10-19.der"
    ["ms_db_optionrom_2023.der"]="$URL/DB/Certificates/microsoft%20option%20rom%20uefi%20ca%202023.der"
    ["ms_db_uefi_2023.der"]="$URL/DB/Certificates/microsoft%20uefi%20ca%202023.der"
    ["ms_db_windows_2023.der"]="$URL/DB/Certificates/windows%20uefi%20ca%202023.der"
    ["dbxupdate_x64.bin"]="https://uefi.org/sites/default/files/resources/dbxupdate_x64.bin"
  )

  for file in "${!CERTS[@]}"; do
    wget -q -O "$file" "${CERTS[$file]}" &
  done
  wait || { fmtr::fatal "Failed to download one or more certs"; exit 1; }

  fmtr::info "Injecting MS SB certs into '$VARS_FILE'..."
  sudo virt-fw-vars --input "$VARS_FILE" --output "$NVRAM_DIR/${VM_NAME}_SECURE_VARS.qcow2" \
    --secure-boot \
    --set-pk "$UUID" ms_pk_oem.der \
    --add-kek "$UUID" ms_kek_2011.der \
    --add-kek "$UUID" ms_kek_2023.der \
    --add-db "$UUID" ms_db_uef_2011.der \
    --add-db "$UUID" ms_db_pro_2011.der \
    --add-db "$UUID" ms_db_optionrom_2023.der \
    --add-db "$UUID" ms_db_uefi_2023.der \
    --add-db "$UUID" ms_db_windows_2023.der \
    --set-dbx dbxupdate_x64.bin &>>"$LOG_FILE" || { fmtr::fatal "Failed to inject SB certs"; exit 1; }

  fmtr::log "Secure VARS generated at '$NVRAM_DIR/${VM_NAME}_SECURE_VARS.qcow2'"
  fmtr::info "Cleaning up..."
  rm -rf "$TEMP_DIR"
}

################################################################################
# Cleanup
################################################################################
cleanup() {
  fmtr::info "Cleaning up..."
  rm -rf "$SRC_DIR/$EDK2_TAG"
  rmdir --ignore-fail-on-non-empty "$SRC_DIR" 2>/dev/null || true
}

################################################################################
# Main menu
################################################################################
main() {
  install_req_pkgs "EDK2"

  while :; do
    fmtr::format_text '\n  ' "[1]" " Create patched OVMF" "$TEXT_BRIGHT_YELLOW"
    fmtr::format_text '  ' "[2]" " VARS SB cert injection" "$TEXT_BRIGHT_YELLOW"
    fmtr::format_text '\n  ' "[0]" " Exit" "$TEXT_BRIGHT_RED"

    read -rp "$(fmtr::ask 'Enter choice [0-2]: ')" user_choice
    case "$user_choice" in
      1)
        acquire_edk2_source
        prmt::yes_or_no "$(fmtr::ask 'Create patched OVMF now?')" && compile_ovmf
        ! prmt::yes_or_no "$(fmtr::ask 'Keep EDK2 source for faster re-patching?')" && cleanup
        exit 0
        ;;
      2) cert_injection; exit 0 ;;
      0) fmtr::info "Exiting."; exit 0 ;;
      *) fmtr::error "Invalid option, please try again." ;;
    esac

    prmt::quick_prompt "$(fmtr::info 'Press any key to continue...')"
  done
}

main "$@"
