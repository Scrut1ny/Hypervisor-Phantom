#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && { echo "Required environment variables not set."; exit 1; }

source ./utils.sh || { echo "Failed to load utilities module!"; exit 1; }

readonly SRC_DIR="$(pwd)/src"
readonly OUT_DIR="/opt/Hypervisor-Phantom/firmware"

readonly EDK2_TAG="edk2-stable202511"
readonly EDK2_URL="https://github.com/tianocore/edk2.git"

readonly OVMF_PATCH="$(pwd)/patches/EDK2/${CPU_MANUFACTURER}-${EDK2_TAG}.patch"

REQUIRED_PKGS_Arch=(base-devel acpica git nasm python patch virt-firmware wget)
REQUIRED_PKGS_Debian=(build-essential uuid-dev acpica-tools git nasm python-is-python3 patch python3-virt-firmware wget)
REQUIRED_PKGS_openSUSE=(gcc gcc-c++ make acpica git nasm python3 libuuid-devel patch virt-firmware wget)
REQUIRED_PKGS_Fedora=(gcc gcc-c++ make acpica-tools git nasm python3 libuuid-devel patch python3-virt-firmware wget)

################################################################################
# Acquire EDK2 source
################################################################################
acquire_edk2_source() {
  mkdir -p "$SRC_DIR" && cd "$SRC_DIR" || { fmtr::fatal "Failed to enter source dir: $SRC_DIR"; exit 1; }

  clone_repo() {
    fmtr::info "Cloning '$EDK2_URL' repository..."
    git clone --depth=1 --branch "$EDK2_TAG" "$EDK2_URL" "$EDK2_TAG" &>>"$LOG_FILE" \
      || { fmtr::fatal "Failed to clone repository!"; exit 1; }
    cd "$EDK2_TAG" || { fmtr::fatal "Missing '$EDK2_TAG' directory!"; exit 1; }
    fmtr::info "Initializing repository submodules... (be patient!)"
    git submodule update --init &>>"$LOG_FILE" \
      || { fmtr::fatal "Failed to initialize all repository submodules!"; exit 1; }
    patch_ovmf
  }

  if [ -d "$EDK2_TAG" ]; then
    fmtr::warn "Repository directory '$EDK2_TAG' found."
    if prmt::yes_or_no "$(fmtr::ask "Purge '$EDK2_TAG' directory?")"; then
      rm -rf "$EDK2_TAG" || { fmtr::fatal "Failed to purge '$EDK2_TAG' directory!"; exit 1; }
      fmtr::info "Directory purged successfully."
      if prmt::yes_or_no "$(fmtr::ask "Clone '$EDK2_URL' repository again?")"; then
        clone_repo
      else
        fmtr::info "Skipping..."
      fi
    else
      fmtr::info "Skipping..."
      cd "$EDK2_TAG" || { fmtr::fatal "Missing '$EDK2_TAG' directory!"; exit 1; }
    fi
  else
    clone_repo
  fi
}

################################################################################
# Patch OVMF
################################################################################
patch_ovmf() {
  [ -f "$OVMF_PATCH" ] || { fmtr::error "Missing '$OVMF_PATCH' patch file!"; return 1; }
  git apply < "$OVMF_PATCH" &>>"$LOG_FILE" || { fmtr::error "Failed to apply '$OVMF_PATCH'!"; return 1; }
  fmtr::log "Applied '${CPU_MANUFACTURER}-${EDK2_TAG}.patch' successfully."

  fmtr::info "Applying dynamic modifications..."

  BIOS_VENDOR="$($ROOT_ESC dmidecode --string bios-vendor)"
  BIOS_VERSION="$($ROOT_ESC dmidecode --string bios-version)"
  BIOS_RELEASE_DATE="$($ROOT_ESC dmidecode --string bios-release-date)"

  sed -i \
    -e 's|VendStr = L"unknown";|VendStr = L"'"$BIOS_VENDOR"'";|' \
    -e 's|VersStr = L"unknown";|VersStr = L"'"$BIOS_VERSION"'";|' \
    -e 's|DateStr = L"02/02/2022";|DateStr = L"'"$BIOS_RELEASE_DATE"'";|' \
    OvmfPkg/SmbiosPlatformDxe/SmbiosPlatformDxe.c

  sed -i \
    -e 's|EFI Development Kit II / OVMF|'"$BIOS_VENDOR"'|' \
    -e 's|"0\.0\.0\\0"|"'"$BIOS_VERSION"'\\0"|' \
    -e 's|"02/06/2015\\0"|"'"$BIOS_RELEASE_DATE"'\\0"|' \
    OvmfPkg/Bhyve/SmbiosPlatformDxe/SmbiosPlatformDxe.c

  fmtr::info "Choose BGRT BMP boot logo image option for OVMF:"
  printf '\n  %b[%d]%b %s\n' "$TEXT_BRIGHT_YELLOW" 1 "$RESET" "Apply host's (default)"
  printf '  %b[%d]%b %s\n' "$TEXT_BRIGHT_YELLOW" 2 "$RESET" "Apply custom (provide path)"
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
            && fmtr::log "Image replaced successfully." \
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
              && fmtr::log "Custom BMP image copied successfully." \
              || fmtr::error "Failed to copy custom BMP image."
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
# Compile OVMF and inject Secure Boot certs into template VARS
################################################################################
compile_and_inject_ovmf() {
  local WORKSPACE EDK_TOOLS_PATH CONF_PATH TEMP_DIR URL UUID

  fmtr::info "Configuring build environment..."

  export WORKSPACE="$(pwd)"
  export EDK_TOOLS_PATH="$WORKSPACE/BaseTools"
  export CONF_PATH="$WORKSPACE/Conf"

  [ -d BaseTools/Build ] || { make -C BaseTools -j"$(nproc)" && source edksetup.sh; } &>>"$LOG_FILE" || { fmtr::fatal "Failed to build BaseTools"; return 1; }

  build -a X64 -p OvmfPkg/OvmfPkgX64.dsc -b RELEASE -t GCC5 -n 0 -s \
    --define SECURE_BOOT_ENABLE=TRUE \
    --define TPM1_ENABLE=TRUE \
    --define TPM2_ENABLE=TRUE \
    --define SMM_REQUIRE=TRUE &>>"$LOG_FILE" || { fmtr::fatal "Failed to build OVMF"; return 1; }

  $ROOT_ESC mkdir -p "$OUT_DIR"

  for f in CODE VARS; do
    $ROOT_ESC qemu-img convert -f raw -O qcow2 "Build/OvmfX64/RELEASE_GCC5/FV/OVMF_${f}.fd" "$OUT_DIR/OVMF_${f}.qcow2" || return 1
  done

  TEMP_DIR="$(mktemp -d)" || return 1
  trap 'rm -rf "$TEMP_DIR"' RETURN

  URL="https://raw.githubusercontent.com/microsoft/secureboot_objects/main"
  UUID="77fa9abd-0359-4d32-bd60-28f4e78f784b"

  local -A certs=(
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

  for c in "${!certs[@]}"; do
    wget -q -O "$TEMP_DIR/$c" "${certs[$c]}" &
  done
  wait || { fmtr::fatal "Failed to download one or more certificates"; return 1; }

  # Generate efivars.json
  local efivars_json="$TEMP_DIR/efivars.json"
  local -A guids=(
    ["dbDefault"]="8be4df61-93ca-11d2-aa0d-00e098032b8c"
    ["dbxDefault"]="8be4df61-93ca-11d2-aa0d-00e098032b8c"
    ["KEKDefault"]="8be4df61-93ca-11d2-aa0d-00e098032b8c"
    ["PKDefault"]="8be4df61-93ca-11d2-aa0d-00e098032b8c"
  )

  {
    local entries=() var path hex attr data entry

    for var in "${!guids[@]}"; do
      path="/sys/firmware/efi/efivars/${var}-${guids[$var]}"
      [[ -f "$path" ]] || continue

      hex=$(hexdump -ve '1/1 "%.2x"' "$path" 2>/dev/null)
      [[ ${#hex} -ge 8 ]] || continue

      # Parse attribute (little-endian 4 bytes) and data
      attr=$(( 16#${hex:6:2}${hex:4:2}${hex:2:2}${hex:0:2} ))
      data=${hex:8}

      # Build JSON entry
      entry=$(printf '        {
              "name": "%s",
              "guid": "%s",
              "attr": %d,' "$var" "${guids[$var]}" "$attr")

      # Handle EFI_VARIABLE_TIME_BASED_AUTHENTICATED_WRITE_ACCESS (0x20)
      if (( attr & 0x20 )) && [[ ${#data} -ge 32 ]]; then
        entry+=$(printf '
              "data": "%s",
              "time": "%s"
          }' "${data:32}" "${data:0:32}")
      else
        entry+=$(printf '
              "data": "%s"
          }' "$data")
      fi

      entries+=("$entry")
    done

    # Output complete JSON
    printf '{\n    "version": 2,\n    "variables": [\n'
    local IFS=','$'\n'
    echo "${entries[*]}"
    printf '    ]\n}\n'
  } > "$efivars_json"

  $ROOT_ESC virt-fw-vars --input "$OUT_DIR/OVMF_VARS.qcow2" --output "$OUT_DIR/OVMF_VARS.qcow2" \
    --secure-boot \
    --set-pk "$UUID" "$TEMP_DIR/ms_pk_oem.der" \
    --add-kek "$UUID" "$TEMP_DIR/ms_kek_2011.der" \
    --add-kek "$UUID" "$TEMP_DIR/ms_kek_2023.der" \
    --add-db "$UUID" "$TEMP_DIR/ms_db_uefi_2011.der" \
    --add-db "$UUID" "$TEMP_DIR/ms_db_pro_2011.der" \
    --add-db "$UUID" "$TEMP_DIR/ms_db_optionrom_2023.der" \
    --add-db "$UUID" "$TEMP_DIR/ms_db_uefi_2023.der" \
    --add-db "$UUID" "$TEMP_DIR/ms_db_windows_2023.der" \
    --set-dbx "$TEMP_DIR/dbxupdate.bin" \
    --set-json "$efivars_json" &>>"$LOG_FILE" || { fmtr::fatal "Failed to inject"; return 1; }
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
  acquire_edk2_source
  prmt::yes_or_no "$(fmtr::ask "Build & install OVMF?")" && compile_and_inject_ovmf
  ! prmt::yes_or_no "$(fmtr::ask "Keep repository directory?")" && cleanup
}

main
