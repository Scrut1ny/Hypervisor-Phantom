#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && { echo "Required environment variables not set."; exit 1; }

source ./utils.sh || { echo "Failed to load utilities module!"; exit 1; }





readonly SRC_DIR="$(pwd)/src"
readonly OUT_DIR="/opt/AutoVirt"

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
  $ROOT_ESC mkdir -p "$OUT_DIR/firmware"
  mkdir -p "$SRC_DIR" && cd "$SRC_DIR" || { fmtr::fatal "Failed to enter source dir: $SRC_DIR"; exit 1; }

  clone_repo() {
    fmtr::info "Cloning '$EDK2_TAG' from '$EDK2_URL'..."
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
  local BIOS_VENDOR BIOS_VERSION BIOS_RELEASE_DATE
  local logo_choice custom_bmp width height bit_depth compression





  # --- Phase 1: Source Patching ---
  [ -f "$OVMF_PATCH" ] || { fmtr::error "Patch file missing"; return 1; }

  git apply < "$OVMF_PATCH" &>>"$LOG_FILE" || {
    fmtr::error "Patch application failed"; return 1;
  }
  fmtr::log "Source code patched."





  # --- Phase 2: SMBIOS Spoofing ---
  fmtr::info "Spoofing SMBIOS metadata..."

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





  # --- Phase 3: Boot Logo Replacement ---
  fmtr::info "Select boot logo source:"
  printf '\n  %b[%d]%b %s\n' "$TEXT_BRIGHT_YELLOW" 1 "$RESET" "Host System (Default)"
  printf '  %b[%d]%b %s\n' "$TEXT_BRIGHT_YELLOW" 2 "$RESET" "Custom Image (BMP)"

  validate_bmp() {
    local -a h
    readarray -t h < <(od -An -v -j0 -N54 -t u1 -w1 "$1")

    # Parse Little Endian headers
    width=$(( h[18] + (h[19]<<8) + (h[20]<<16) + (h[21]<<24) ))
    height=$(( h[22] + (h[23]<<8) + (h[24]<<16) + (h[25]<<24) ))
    bit_depth=$(( h[28] + (h[29]<<8) ))
    compression=$(( h[30] + (h[31]<<8) + (h[32]<<16) + (h[33]<<24) ))

    # Validate: Magic BM, Depth 1/4/8/24, No Compression, Max 65535px
    if (( h[0] != 66 || h[1] != 77 || (bit_depth != 1 && bit_depth != 4 && bit_depth != 8 && bit_depth != 24) || compression != 0 || width > 65535 || height > 65535 )); then
      fmtr::error "Invalid BMP: ${width}x${height} @ ${bit_depth}bpp (Comp: ${compression})"
      return 1
    fi
  }

  while :; do
    read -rp "$(fmtr::ask 'Enter choice [1-2]: ')" logo_choice && : "${logo_choice:=1}"

    case "$logo_choice" in
      1)
        if [ -f /sys/firmware/acpi/bgrt/image ]; then
          cp /sys/firmware/acpi/bgrt/image MdeModulePkg/Logo/Logo.bmp \
            && fmtr::log "Host logo injected." \
            || fmtr::error "Copy failed."
        else
          fmtr::error "Host BGRT image missing."
        fi
        break
        ;;
      2)
        while :; do
          read -rp "$(fmtr::ask 'Path to BMP: ')" custom_bmp
          [ -f "$custom_bmp" ] || { fmtr::error "File not found."; continue; }

          if validate_bmp "$custom_bmp"; then
            fmtr::info "Valid BMP detected (${width}x${height})."
            cp "$custom_bmp" MdeModulePkg/Logo/Logo.bmp \
              && fmtr::log "Custom logo injected." \
              || fmtr::error "Copy failed."
            break 2
          fi
        done
        ;;
      *)
        fmtr::error "Invalid selection."
        ;;
    esac
  done
}





################################################################################
# Build OVMF w/SB & TPM
################################################################################
compile_and_inject_ovmf() {
  local WORKSPACE EDK_TOOLS_PATH CONF_PATH TEMP_DIR
  local efivars_json EFI_GLOBAL_VARIABLE_GUID EFI_IMAGE_SECURITY_DATABASE_GUID





  # --- Phase 1: Build Environment & Compilation ---
  fmtr::info "Initializing build environment..."

  export WORKSPACE="$(pwd)"
  export EDK_TOOLS_PATH="$WORKSPACE/BaseTools"
  export CONF_PATH="$WORKSPACE/Conf"

  # Ensure BaseTools are built
  if [ ! -d "BaseTools/Build" ]; then
    { make -C BaseTools -j"$(nproc)" && source edksetup.sh; } &>>"$LOG_FILE" || {
      fmtr::fatal "BaseTools build failed"; return 1;
    }
  fi

  # Build OVMF (Release, X64)
  build -p OvmfPkg/OvmfPkgX64.dsc -a X64 -t GCC5 -b RELEASE -n 0 -s \
    --define SECURE_BOOT_ENABLE=TRUE \
    --define TPM1_ENABLE=TRUE \
    --define TPM2_ENABLE=TRUE \
    --define SMM_REQUIRE=TRUE &>>"$LOG_FILE" || {
      fmtr::fatal "OVMF build failed"; return 1;
    }





  # --- Phase 2: Artifact Conversion ---
  # Convert raw firmware volumes to qcow2
  for f in CODE VARS; do
    $ROOT_ESC "$OUT_DIR/emulator/bin/qemu-img" convert -f raw -O qcow2 \
      "Build/OvmfX64/RELEASE_GCC5/FV/OVMF_${f}.fd" \
      "$OUT_DIR/firmware/OVMF_${f}.qcow2" || return 1
  done





  # --- Phase 3: Variable Extraction ---
  TEMP_DIR="$(mktemp -d)" || return 1
  trap 'rm -rf "$TEMP_DIR"' RETURN

  fmtr::info "Extracting host EFI keys..."

  efivars_json="$TEMP_DIR/efivars.json"
  EFI_GLOBAL_VARIABLE_GUID="8be4df61-93ca-11d2-aa0d-00e098032b8c"
  EFI_IMAGE_SECURITY_DATABASE_GUID="d719b2cb-3d3a-4596-a3bc-dad00e67656f"

  # Map OVMF variable names to Host sysfs paths and target GUIDs
  local -A key_mappings=(
    ["PK"]="PK-${EFI_GLOBAL_VARIABLE_GUID}|${EFI_GLOBAL_VARIABLE_GUID}"
    ["KEK"]="KEK-${EFI_GLOBAL_VARIABLE_GUID}|${EFI_GLOBAL_VARIABLE_GUID}"
    ["db"]="db-${EFI_IMAGE_SECURITY_DATABASE_GUID}|${EFI_IMAGE_SECURITY_DATABASE_GUID}"
    ["dbx"]="dbx-${EFI_IMAGE_SECURITY_DATABASE_GUID}|${EFI_IMAGE_SECURITY_DATABASE_GUID}"
    ["PKDefault"]="PKDefault-${EFI_GLOBAL_VARIABLE_GUID}|${EFI_GLOBAL_VARIABLE_GUID}"
    ["KEKDefault"]="KEKDefault-${EFI_GLOBAL_VARIABLE_GUID}|${EFI_GLOBAL_VARIABLE_GUID}"
    ["dbDefault"]="dbDefault-${EFI_GLOBAL_VARIABLE_GUID}|${EFI_GLOBAL_VARIABLE_GUID}"
    ["dbxDefault"]="dbxDefault-${EFI_GLOBAL_VARIABLE_GUID}|${EFI_GLOBAL_VARIABLE_GUID}"
  )

  # Generate JSON payload from host NVRAM
  {
    printf '{\n    "version": 2,\n    "variables": [\n'

    local first_entry=true target_name target_guid host_file path full_hex header_hex data_hex attr

    for target_name in "${!key_mappings[@]}"; do
      IFS='|' read -r host_file target_guid <<< "${key_mappings[$target_name]}"
      path="/sys/firmware/efi/efivars/${host_file}"

      [ -f "$path" ] || continue

      # Dump hex: Header (4 bytes) + Data
      full_hex=$(hexdump -ve '1/1 "%.2x"' "$path" 2>/dev/null)
      header_hex="${full_hex:0:8}"
      data_hex="${full_hex:8}"

      # Parse attributes (Little Endian 32-bit int)
      attr=$(( 16#${header_hex:6:2}${header_hex:4:2}${header_hex:2:2}${header_hex:0:2} ))

      "$first_entry" && first_entry=false || printf ',\n'

      printf '        { "name": "%s", "guid": "%s", "attr": %d, "data": "%s" }' \
        "$target_name" "$target_guid" "$attr" "$data_hex"
    done

    printf '\n    ]\n}\n'
  } > "$efivars_json"





  # --- Phase 4: NVRAM Injection ---
  fmtr::info "Populating OVMF NVRAM..."

  $ROOT_ESC virt-fw-vars \
    --input "$OUT_DIR/firmware/OVMF_VARS.qcow2" \
    --output "$OUT_DIR/firmware/OVMF_VARS.qcow2" \
    --secure-boot \
    --set-json "$efivars_json" &>>"$LOG_FILE" || {
      fmtr::fatal "NVRAM injection failed"; return 1;
    }

  fmtr::log "Secure Boot provisioning complete."
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
