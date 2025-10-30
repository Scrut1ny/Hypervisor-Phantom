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

  validate_bmp() {
    local -a h
    readarray -t h < <(od -An -v -j0 -N54 -t u1 -w1 "$1")

    local wh=$(( h[18] + (h[19]<<8) + (h[20]<<16) + (h[21]<<24) ))
    local ht=$(( h[22] + (h[23]<<8) + (h[24]<<16) + (h[25]<<24) ))
    local bd=$(( h[28] + (h[29]<<8) ))
    local cn=$(( h[30] + (h[31]<<8) + (h[32]<<16) + (h[33]<<24) ))

    width=$wh; height=$ht; bit_depth=$bd; compression=$cn

    if (( h[0] != 66 || h[1] != 77 || bd != 1 && bd != 4 && bd != 8 && bd != 24 || cn != 0 || wh > 65535 || ht > 65535 )); then
      fmtr::error "INVALID: ${width}×${height} (≤65535×65535), ${bit_depth}-bit (1/4/8/24-bit), ${compression} (0 compression)"
      return 1
    fi
  }

  while :; do
    read -rp "$(fmtr::ask 'Enter choice [1-2]: ')" logo_choice && : "${logo_choice:=1}"
    case "$logo_choice" in
      1)
        if [ -f /sys/firmware/acpi/bgrt/image ]; then
          cp /sys/firmware/acpi/bgrt/image MdeModulePkg/Logo/Logo.bmp \
            && fmtr::info "Image replaced successfully." \
            || fmtr::error "Image not found or failed to copy."
        else
          fmtr::error "Host BMP image not found."
        fi
        break
        ;;
      2)
        while :; do
          read -rp "$(fmtr::ask 'Enter absolute path to your BMP image: ')" custom_bmp
          if [ ! -f "$custom_bmp" ]; then
            fmtr::error "File does not exist. Try again."
            continue
          fi

          if validate_bmp "$custom_bmp"; then
            fmtr::info "VALID: ${width}×${height} (≤65535×65535), ${bit_depth}-bit (1/4/8/24-bit), ${compression} (0 compression)"
            cp "$custom_bmp" MdeModulePkg/Logo/Logo.bmp \
              && fmtr::info "Custom BMP copied successfully." \
              || fmtr::error "Failed to copy custom BMP."
            break 2
          fi
        done
        ;;
      *)
        fmtr::error "Invalid choice, try again."
        ;;
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
  build -a X64 -p OvmfPkg/OvmfPkgX64.dsc -b RELEASE -t GCC5 -n 0 -s \
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
    qemu-img convert -f raw -O qcow2 "$src" "$dest" || { fmtr::fatal "Failed to convert $src"; exit 1; }
  done
}

################################################################################
# Certificate injection
################################################################################
cert_injection() {
  readonly URL="https://raw.githubusercontent.com/microsoft/secureboot_objects/main"
  readonly UUID="77fa9abd-0359-4d32-bd60-28f4e78f784b"
  local TEMP_DIR VM_NAME VARS_FILE NVRAM_DIR="/var/lib/libvirt/qemu/nvram" DEFAULTS_JSON

  TEMP_DIR=$(mktemp -d) || { fmtr::fatal "Failed to create temp dir"; return 1; }
  cd "$TEMP_DIR" || { fmtr::fatal "Failed to enter temp dir"; rm -rf "$TEMP_DIR"; return 1; }

  fmtr::log "Available domains:"; echo ""
  mapfile -t VMS < <(virsh list --all --name | grep -v '^$')
  [ ${#VMS[@]} -gt 0 ] || { fmtr::fatal "No domains found!"; rm -rf "$TEMP_DIR"; return 1; }

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
        [ -f "$VARS_FILE" ] || { fmtr::fatal "File not found: $VARS_FILE"; rm -rf "$TEMP_DIR"; return 1; }
        fmtr::log "Using '$VARS_FILE' as the base VARS file."
        break
        ;;
    esac
  done

  fmtr::info "Downloading Microsoft's Secure Boot certifications..."
  declare -A CERTS=(
    # PK (Platform Key)
    ["ms_pk_oem.der"]="$URL/PreSignedObjects/PK/Certificate/WindowsOEMDevicesPK.der"

    # KEK (Key Exchange Key)
    ["ms_kek_2011.der"]="$URL/PreSignedObjects/KEK/Certificates/MicCorKEKCA2011_2011-06-24.der"
    ["ms_kek_2023.der"]="$URL/PreSignedObjects/KEK/Certificates/microsoft%20corporation%20kek%202k%20ca%202023.der"

    # DB (Signature Database)
    ["ms_db_uefi_2011.der"]="$URL/PreSignedObjects/DB/Certificates/MicCorUEFCA2011_2011-06-27.der"
    ["ms_db_pro_2011.der"]="$URL/PreSignedObjects/DB/Certificates/MicWinProPCA2011_2011-10-19.der"
    ["ms_db_optionrom_2023.der"]="$URL/PreSignedObjects/DB/Certificates/microsoft%20option%20rom%20uefi%20ca%202023.der"
    ["ms_db_uefi_2023.der"]="$URL/PreSignedObjects/DB/Certificates/microsoft%20uefi%20ca%202023.der"
    ["ms_db_windows_2023.der"]="$URL/PreSignedObjects/DB/Certificates/windows%20uefi%20ca%202023.der"

    # DBX (Forbidden Signatures Database)
    ["dbxupdate.bin"]="$URL/PostSignedObjects/DBX/amd64/DBXUpdate.bin"
  )

  for file in "${!CERTS[@]}"; do
    wget -q -O "$file" "${CERTS[$file]}" &
  done
  wait || { fmtr::fatal "Failed to download one or more certs"; rm -rf "$TEMP_DIR"; return 1; }

  fmtr::info "Generating defaults.json from host efivars..."
  DEFAULTS_JSON="$TEMP_DIR/defaults.json"
  EFIVAR_DIR="/sys/firmware/efi/efivars"
  VARS_LIST=("dbDefault" "dbxDefault" "KEKDefault" "PKDefault" "MemoryOverwriteRequestControlLock")
  declare -A VAR_GUIDS=(
    ["dbDefault"]="8be4df61-93ca-11d2-aa0d-00e098032b8c"
    ["dbxDefault"]="8be4df61-93ca-11d2-aa0d-00e098032b8c"
    ["KEKDefault"]="8be4df61-93ca-11d2-aa0d-00e098032b8c"
    ["PKDefault"]="8be4df61-93ca-11d2-aa0d-00e098032b8c"
    ["MemoryOverwriteRequestControlLock"]="bb983ccf-151d-40e1-a07b-4a17be168292"
  )

  {
    printf '%s\n' '{'
    printf '%s\n' '    "version": 2,'
    printf '%s\n' '    "variables": ['

    sep=""
    if [[ -d "$EFIVAR_DIR" ]]; then
      for var in "${VARS_LIST[@]}"; do
        guid="${VAR_GUIDS[$var]}"
        filepath="$EFIVAR_DIR/${var}-${guid}"
        if [[ -f "$filepath" ]]; then
          raw_data=$(hexdump -ve '1/1 "%.2x"' "$filepath" 2>/dev/null) || raw_data=""
          if [[ -n "$raw_data" && ${#raw_data} -ge 8 ]]; then
            # Parse attribute (little-endian 4 bytes)
            attr_hex="${raw_data:6:2}${raw_data:4:2}${raw_data:2:2}${raw_data:0:2}"
            if [[ "$attr_hex" =~ ^[0-9a-fA-F]+$ ]]; then
              attr=$((16#$attr_hex))
            else
              attr=0
            fi

            # Extract data after the attr field
            data_hex="${raw_data:8}"

            time_hex=""
            remaining_data="$data_hex"

            # Check for EFI_VARIABLE_TIME_BASED_AUTHENTICATED_WRITE_ACCESS (bit 0x20)
            # and ensure there’s enough data for a timestamp (16 bytes = 32 hex chars)
            if (( (attr & 0x20) != 0 )) && [[ ${#data_hex} -ge 32 ]]; then
              time_hex="${data_hex:0:32}"
              remaining_data="${data_hex:32}"
            fi

            printf '%s\n' "        $sep{"
            printf '            "name": "%s",\n' "$var"
            printf '            "guid": "%s",\n' "$guid"
            printf '            "attr": %d,\n' "$attr"
            if [[ -n "$time_hex" ]]; then
              printf '            "data": "%s",\n' "$remaining_data"
              printf '            "time": "%s"\n' "$time_hex"
            else
              printf '            "data": "%s"\n' "$remaining_data"
            fi
            sep=","
            printf '%s' "        }"
            printf '\n'
          fi
        fi
      done
    fi

    printf '%s\n' '    ]'
    printf '%s\n' '}'
  } > "$DEFAULTS_JSON"

  fmtr::info "Injecting MS SB certs and efivars into '$VARS_FILE'..."
  virt-fw-vars --input "$VARS_FILE" --output "$NVRAM_DIR/${VM_NAME}_SECURE_VARS.qcow2" \
    --secure-boot \
    --set-pk "$UUID" ms_pk_oem.der \
    --add-kek "$UUID" ms_kek_2011.der \
    --add-kek "$UUID" ms_kek_2023.der \
    --add-db "$UUID" ms_db_uefi_2011.der \
    --add-db "$UUID" ms_db_pro_2011.der \
    --add-db "$UUID" ms_db_optionrom_2023.der \
    --add-db "$UUID" ms_db_uefi_2023.der \
    --add-db "$UUID" ms_db_windows_2023.der \
    --set-dbx dbxupdate.bin \
    --set-json "$DEFAULTS_JSON" &>>"$LOG_FILE" || { fmtr::fatal "Failed to inject SB certs"; rm -rf "$TEMP_DIR"; return 1; }

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
