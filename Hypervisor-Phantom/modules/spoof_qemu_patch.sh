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
readonly QEMU_VERSION="10.0.2"
readonly QEMU_DIR="qemu-${QEMU_VERSION}"
readonly QEMU_ARCHIVE="${QEMU_DIR}.tar.xz"
readonly QEMU_SIG="${QEMU_ARCHIVE}.sig"
readonly QEMU_URL="https://download.qemu.org/${QEMU_ARCHIVE}"
readonly QEMU_SIG_URL="${QEMU_URL}.sig"
readonly PATCH_DIR="../../patches/QEMU"
readonly QEMU_PATCH="${CPU_VENDOR}-${QEMU_DIR}.patch"
readonly QEMU_LIBNFS_PATCH="libnfs6-${QEMU_DIR}.patch"
readonly GPG_KEY="CEACC9E15534EBABB82D3FA03353C9CEF108B584"
readonly FAKE_BATTERY_ACPITABLE="${PATCH_DIR}/fake_battery.dsl"

REQUIRED_PKGS_Arch=(
  # Basic Build Dependencie(s)
  acpica base-devel dmidecode glib2 ninja python-packaging
  python-sphinx python-sphinx_rtd_theme gnupg

  # Spice Dependencie(s)
  spice gtk3

  # USB passthrough Dependencie(s)
  libusb

  # USB redirection Dependencie(s)
  usbredir
)

REQUIRED_PKGS_Debian=(
  # Basic Build Dependencie(s)
  acpica-tools build-essential libfdt-dev libglib2.0-dev
  libpixman-1-dev ninja-build python3-venv zlib1g-dev gnupg
  python3-sphinx python3-sphinx-rtd-theme

  # Spice Dependencie(s)
  libspice-server-dev

  # USB passthrough Dependencie(s)
  libusb-1.0-0-dev

  # USB redirection Dependencie(s)
  libusbredirhost-dev libusbredirparser-dev
)

REQUIRED_PKGS_openSUSE=(
  # Basic Build Dependencie(s)
  acpica bzip2 gcc-c++ gpg2 glib2-devel make qemu  
  libpixman-1-0-devel patch python3-Sphinx ninja

  # Spice Dependencie(s)
  spice-server

  # USB passthrough Dependencie(s)
  libusb-1_0-devel

  # USB redirection Dependencie(s)
  libusbredir-devel
)

REQUIRED_PKGS_Fedora=(
  # Basic Build Dependencie(s)
  acpica-tools bzip2 glib2-devel libfdt-devel ninja-build
  pixman-devel python3 zlib-ng-devel gnupg2

  # Spice Dependencie(s)
  spice-server

  # USB passthrough Dependencie(s)
  libusb1-devel

  # USB redirection Dependencie(s)
  usbredir-devel
)

acquire_qemu_source() {
  mkdir -p "$SRC_DIR" && cd "$SRC_DIR"

  if [ -d "$QEMU_DIR" ]; then
    fmtr::warn "Directory $QEMU_DIR already exists."
    if ! prmt::yes_or_no "$(fmtr::ask 'Purge the QEMU directory?')"; then
      fmtr::info "Keeping existing directory. Skipping re-download."
      cd "$QEMU_DIR" || { fmtr::fatal "Failed to change to QEMU directory: $QEMU_DIR"; exit 1; }
      return
    fi
    sudo rm -rf "$QEMU_DIR/" "$QEMU_ARCHIVE" "$QEMU_SIG" || { fmtr::fatal "Failed to remove existing directory: $QEMU_DIR"; exit 1; }
    fmtr::info "Directory purged."
  fi

  fmtr::info "Downloading QEMU source archive and signature..."
  curl -sSO "$QEMU_URL" || { fmtr::fatal "Failed to download QEMU source archive."; exit 1; }
  curl -sSO "$QEMU_SIG_URL" || { fmtr::fatal "Failed to download QEMU signature file."; exit 1; }

  fmtr::log "Verifying source authenticity..."
  if ! gpg --keyserver keys.openpgp.org --recv-keys "$GPG_KEY" &>> "$LOG_FILE"; then
    fmtr::warn "Failed to import QEMU signing key."
    if ! prmt::yes_or_no "$(fmtr::ask 'Continue anyway despite key import failure?'))"; then
      fmtr::fatal "Aborting due to key import failure."
      exit 1
    fi
    fmtr::warn "Continuing despite failed key import..."
  fi

  if ! gpg --verify "$QEMU_SIG" "$QEMU_ARCHIVE" &>> "$LOG_FILE"; then
    fmtr::warn "Signature verification FAILED! Archive may be compromised."
    if ! prmt::yes_or_no "$(fmtr::ask 'Continue anyway despite failed signature verification?'))"; then
      fmtr::fatal "Aborting due to failed signature verification."
      exit 1
    fi
    fmtr::warn "Continuing despite signature verification failure..."
  else
    fmtr::log "Signature verification successful."
  fi

  fmtr::info "Extracting QEMU source archive..."
  tar xJf "$QEMU_ARCHIVE" || { fmtr::fatal "Failed to extract QEMU archive."; exit 1; }

  cd "$QEMU_DIR" || { fmtr::fatal "Failed to change to QEMU directory: $QEMU_DIR"; exit 1; }
  fmtr::info "QEMU source successfully acquired and extracted."
  patch_qemu
}

patch_qemu() {
  if [ ! -f "${PATCH_DIR}/${QEMU_PATCH}" ]; then
    fmtr::error "Patch file \"${PATCH_DIR}/${QEMU_PATCH}\" not found!"
    fmtr::fatal "Cannot proceed without the patch file. Exiting."
    exit 1
  fi

  if [ ! -f "${PATCH_DIR}/${QEMU_LIBNFS_PATCH}" ]; then
    fmtr::error "Patch file \"${PATCH_DIR}/${QEMU_LIBNFS_PATCH}\" not found!"
    fmtr::fatal "Cannot proceed without the libnfs patch file. Exiting."
    exit 1
  fi

  fmtr::info "Applying patches to QEMU..."

  patch -fsp1 < "${PATCH_DIR}/${QEMU_PATCH}" &>> "$LOG_FILE" || {
    fmtr::error "Failed to apply patch ${QEMU_PATCH}!"
    fmtr::fatal "Patch application failed. Please check the log for errors."
    exit 1
  }

  patch -fsp1 < "${PATCH_DIR}/${QEMU_LIBNFS_PATCH}" &>> "$LOG_FILE" || {
    fmtr::error "Failed to apply patch ${QEMU_LIBNFS_PATCH}!"
    fmtr::fatal "libNFS patch application failed. Please check the log for errors."
    exit 1
  }

  fmtr::log "Spoofing all unique hardcoded QEMU identifiers..."

  spoof_serial_numbers
  spoof_drive_serial_number
  spoof_smbios_processor_data
  spoof_acpi_table_data
}












spoof_serial_numbers() {
  local patterns=(STRING_SERIALNUMBER STR_SERIALNUMBER STR_SERIAL_MOUSE \
                  STR_SERIAL_TABLET STR_SERIAL_KEYBOARD STR_SERIAL_COMPAT)
  for file in ./hw/usb/*.c; do
    for pat in "${patterns[@]}"; do
      grep -n "\[\s*${pat}\s*\]\s*=\s*\"[^\"]*\"" "$file" | cut -d: -f1 | while read -r lineno; do
        serial=$(tr -dc 'A-Z0-9' </dev/urandom | head -c10)
        sed -r -i "${lineno}s/(\[\s*${pat}\s*\]\s*=\s*\")[^\"]*(\")/\1${serial}\2/" "$file"
      done
    done
  done
}














spoof_drive_serial_number() {
  local core_file="hw/ide/core.c"

  local ide_cd_models=(
    "HL-DT-ST BD-RE WH16NS60" "HL-DT-ST DVDRAM GH24NSC0"
    "HL-DT-ST BD-RE BH16NS40" "HL-DT-ST DVD+-RW GT80N"
    "HL-DT-ST DVD-RAM GH22NS30" "HL-DT-ST DVD+RW GCA-4040N"
    "Pioneer BDR-XD07B" "Pioneer DVR-221LBK" "Pioneer BDR-209DBK"
    "Pioneer DVR-S21WBK" "Pioneer BDR-XD05B" "ASUS BW-16D1HT"
    "ASUS DRW-24B1ST" "ASUS SDRW-08D2S-U" "ASUS BC-12D2HT"
    "ASUS SBW-06D2X-U" "Samsung SH-224FB" "Samsung SE-506BB"
    "Samsung SH-B123L" "Samsung SE-208GB" "Samsung SN-208DB"
    "Sony NEC Optiarc AD-5280S" "Sony DRU-870S" "Sony BWU-500S"
    "Sony NEC Optiarc AD-7261S" "Sony AD-7200S" "Lite-On iHAS124-14"
    "Lite-On iHBS112-04" "Lite-On eTAU108" "Lite-On iHAS324-17"
    "Lite-On eBAU108" "HP DVD1260i" "HP DVD640"
    "HP BD-RE BH30L" "HP DVD Writer 300n" "HP DVD Writer 1265i"
  )

  local ide_cfata_models=(
    "SanDisk Ultra microSDXC UHS-I" "SanDisk Extreme microSDXC UHS-I"
    "SanDisk High Endurance microSDXC" "SanDisk Industrial microSD"
    "SanDisk Mobile Ultra microSDHC" "Samsung EVO Select microSDXC"
    "Samsung PRO Endurance microSDHC" "Samsung PRO Plus microSDXC"
    "Samsung EVO Plus microSDXC" "Samsung PRO Ultimate microSDHC"
    "Kingston Canvas React Plus microSD" "Kingston Canvas Go! Plus microSD"
    "Kingston Canvas Select Plus microSD" "Kingston Industrial microSD"
    "Kingston Endurance microSD" "Lexar Professional 1066x microSDXC"
    "Lexar High-Performance 633x microSDHC" "Lexar PLAY microSDXC"
    "Lexar Endurance microSD" "Lexar Professional 1000x microSDHC"
    "PNY Elite-X microSD" "PNY PRO Elite microSD"
    "PNY High Performance microSD" "PNY Turbo Performance microSD"
    "PNY Premier-X microSD" "Transcend High Endurance microSDXC"
    "Transcend Ultimate microSDXC" "Transcend Industrial Temp microSD"
    "Transcend Premium microSDHC" "Transcend Superior microSD"
    "ADATA Premier Pro microSDXC" "ADATA XPG microSDXC"
    "ADATA High Endurance microSDXC" "ADATA Premier microSDHC"
    "ADATA Industrial microSD" "Toshiba Exceria Pro microSDXC"
    "Toshiba Exceria microSDHC" "Toshiba M203 microSD"
    "Toshiba N203 microSD" "Toshiba High Endurance microSD"
  )

  local default_models=(
    "Samsung SSD 970 EVO 1TB" "Samsung SSD 860 QVO 1TB"
    "Samsung SSD 850 PRO 1TB" "Samsung SSD T7 Touch 1TB"
    "Samsung SSD 840 EVO 1TB" "WD Blue SN570 NVMe SSD 1TB"
    "WD Black SN850 NVMe SSD 1TB" "WD Green 1TB SSD"
    "WD Blue 3D NAND 1TB SSD" "Crucial P3 1TB PCIe 3.0 3D NAND NVMe SSD"
    "Seagate BarraCuda SSD 1TB" "Seagate FireCuda 520 SSD 1TB"
    "Seagate IronWolf 110 SSD 1TB" "SanDisk Ultra 3D NAND SSD 1TB"
    "Seagate Fast SSD 1TB" "Crucial MX500 1TB 3D NAND SSD"
    "Crucial P5 Plus NVMe SSD 1TB" "Crucial BX500 1TB 3D NAND SSD"
    "Crucial P3 1TB PCIe 3.0 3D NAND NVMe SSD"
    "Kingston A2000 NVMe SSD 1TB" "Kingston KC2500 NVMe SSD 1TB"
    "Kingston A400 SSD 1TB" "Kingston HyperX Savage SSD 1TB"
    "SanDisk SSD PLUS 1TB" "SanDisk Ultra 3D 1TB NAND SSD"
  )

  get_random_element() {
    local array=("$@")
    echo "${array[RANDOM % ${#array[@]}]}"
  }

  local new_ide_cd_model=$(get_random_element "${ide_cd_models[@]}")
  local new_ide_cfata_model=$(get_random_element "${ide_cfata_models[@]}")
  local new_default_model=$(get_random_element "${default_models[@]}")

  sed -i "$core_file" -Ee "s/\"HL-DT-ST BD-RE WH16NS60\"/\"${new_ide_cd_model}\"/"
  sed -i "$core_file" -Ee "s/\"Hitachi HMS360404D5CF00\"/\"${new_ide_cfata_model}\"/"
  sed -i "$core_file" -Ee "s/\"Samsung SSD 980 500GB\"/\"${new_default_model}\"/"

}















spoof_acpi_table_data() {

  ##################################################
  ##################################################

  # Spoofs 'OEM ID' and 'OEM Table ID' for ACPI tables.

  local oem_pairs=(
    'DELL  ' 'Dell Inc' ' ASUS ' 'Notebook'
    'MSI NB' 'MEGABOOK' 'LENOVO' 'TC-O5Z  '
    'LENOVO' 'CB-01   ' 'SECCSD' 'LH43STAR'
    'LGE   ' 'ICL     '
  )

  if [[ "$CPU_VENDOR" == "amd" ]]; then
    oem_pairs+=('ALASKA' 'A M I ')
  elif [[ "$CPU_VENDOR" == "intel" ]]; then
    oem_pairs+=('INTEL ' 'U Rvp   ')
  fi

  local total_pairs=$(( ${#oem_pairs[@]} / 2 ))
  local random_index=$(( RANDOM % total_pairs * 2 ))
  local appname6=${oem_pairs[$random_index]}
  local appname8=${oem_pairs[$random_index + 1]}
  local h_file="include/hw/acpi/aml-build.h"

  sed -i "$h_file" -e "s/^#define ACPI_BUILD_APPNAME6 \".*\"/#define ACPI_BUILD_APPNAME6 \"${appname6}\"/"
  sed -i "$h_file" -e "s/^#define ACPI_BUILD_APPNAME8 \".*\"/#define ACPI_BUILD_APPNAME8 \"${appname8}\"/"

  ##################################################
  ##################################################

  # Default QEMU has an unspecified PM type in the FACP ACPI table.
  # On baremetal normally vendors specify either 1 (Desktop) or 2 (Notebook).
  # We patch the PM type integer based on the chassis type output from dmidecode.

  fmtr::info "Obtaining machine's chassis-type..."

  local c_file="hw/acpi/aml-build.c"
  local pm_type="1" # Desktop
  local chassis_type=$(sudo dmidecode --string chassis-type)

  if [[ "$chassis_type" = "Notebook" ]]; then
    pm_type="2" # Notebook/Laptop/Mobile
  fi

  sed -i 's/build_append_int_noprefix(tbl, 0 \/\* Unspecified \*\//build_append_int_noprefix(tbl, '"$pm_type"' \/\* '"$chassis_type"' \*\//g' "$c_file"

  if [[ "$chassis_type" = "Notebook" ]]; then    
    fmtr::warn "Host PM type equals '$pm_type' ($chassis_type)"
    fmtr::info "Generating fake battery SSDT ACPI table..."

    cat "${FAKE_BATTERY_ACPITABLE}" \
      | sed "s/BOCHS/$appname6/" \
      | sed "s/BXPCSSDT/$appname8/" > "$HOME/fake_battery.dsl"
    iasl -tc "$HOME/fake_battery.dsl" &>> "$LOG_FILE"

    fmtr::info "ACPI table saved to '$HOME/fake_battery.aml'"
    fmtr::info "It's highly recommended to passthrough the ACPI Table via QEMU's args/xml:
      qemu-system-x86_64 -acpitable '$HOME/fake_battery.aml'"
  fi

  ##################################################
  ##################################################

}















spoof_smbios_processor_data() {

  ##################################################
  ##################################################

  local chipset_file
  case "$QEMU_VERSION" in
    "8.2.6") chipset_file="hw/i386/pc_q35.c" ;;
    "9.2.4"|"10.0.2") chipset_file="hw/i386/fw_cfg.c" ;;
    *) fmtr::warn "Unsupported QEMU version: $QEMU_VERSION" ;;
  esac

  local manufacturer=$(sudo dmidecode --string processor-manufacturer)
  sed -i "$chipset_file" -e "s/smbios_set_defaults(\"[^\"]*\",/smbios_set_defaults(\"${manufacturer}\",/"

  ##################################################
  ##################################################

  # Handle 0x0004, DMI type 4

  local smbios_file="hw/smbios/smbios.c"
  local t4_raw="/sys/firmware/dmi/entries/4-0/raw"

  [[ -e $t4_raw ]] || sudo modprobe dmi_sysfs >>"$LOG_FILE"

  local data=$(sudo hexdump -v -e '/1 "%02X"' "$t4_raw")

  local processor_type="${data:10:2}"
  local processor_family="${data:12:2}"
  local voltage="${data:34:2}"
  local external_clock="${data:38:2}${data:36:2}"
  local max_speed="${data:42:2}${data:40:2}"
  local current_speed="${data:46:2}${data:44:2}"
  local status="${data:48:2}"
  local processor_upgrade="${data:50:2}"
  local l1_cache_handle="${data:54:2}${data:52:2}"
  local l2_cache_handle="${data:58:2}${data:56:2}"
  local l3_cache_handle="${data:62:2}${data:60:2}"
  local processor_characteristics="${data:78:2}${data:76:2}"
  local processor_family2="${data:82:2}${data:80:2}"

  sed -i -E "s/(t->processor_family[[:space:]]*=[[:space:]]*)0x[0-9A-Fa-f]+;/\10x${processor_family};/" "$smbios_file"
  sed -i -E "s/(t->voltage[[:space:]]*=[[:space:]]*)0;/\1${voltage};/" "$smbios_file"
  sed -i -E "s/(t->external_clock[[:space:]]*=[[:space:]]*cpu_to_le16\()0x[0-9A-Fa-f]+(\);)/\10x${external_clock}\2/" "$smbios_file"
  sed -i -E "s/(t->l1_cache_handle[[:space:]]*=[[:space:]]*cpu_to_le16\()0x[0-9A-Fa-f]+(\);)/\10x${l1_cache_handle}\2/" "$smbios_file"
  sed -i -E "s/(t->l2_cache_handle[[:space:]]*=[[:space:]]*cpu_to_le16\()0x[0-9A-Fa-f]+(\);)/\10x${l2_cache_handle}\2/" "$smbios_file"
  sed -i -E "s/(t->l3_cache_handle[[:space:]]*=[[:space:]]*cpu_to_le16\()0x[0-9A-Fa-f]+(\);)/\10x${l3_cache_handle}\2/" "$smbios_file"
  sed -i -E "s/(t->processor_upgrade[[:space:]]*=[[:space:]]*)0x[0-9A-Fa-f]+;/\10x${processor_upgrade};/" "$smbios_file"
  sed -i -E "s/(t->processor_characteristics[[:space:]]*=[[:space:]]*cpu_to_le16\()0x[0-9A-Fa-f]+(\);)/\10x${processor_characteristics}\2/" "$smbios_file"
  sed -i -E "s/(t->processor_family2[[:space:]]*=[[:space:]]*cpu_to_le16\()0x[0-9A-Fa-f]+(\);)/\10x${processor_family2}\2/" "$smbios_file"

  ##################################################
  ##################################################

}
















compile_qemu() {
  fmtr::log "Configuring build environment"

  ./configure --target-list=x86_64-softmmu \
              --enable-libusb \
              --enable-usb-redir \
              --enable-spice \
              --enable-spice-protocol \
              --disable-werror &>> "$LOG_FILE"

  if [[ $? -ne 0 ]]; then
    fmtr::error "Configure failed. Check $LOG_FILE"
    return 1
  fi

  fmtr::log "Building QEMU"
  make -j"$(nproc)" &>> "$LOG_FILE"
  if [[ $? -ne 0 ]]; then
    fmtr::error "Build failed. Check $LOG_FILE"
    return 1
  fi

  fmtr::log "Installing QEMU"
  sudo make install &>> "$LOG_FILE"
  if [[ $? -ne 0 ]]; then
    fmtr::error "Install failed. Check $LOG_FILE"
    return 1
  fi

  fmtr::info "Compilation finished!"
}

cleanup() {

  fmtr::log "Cleaning up"
  cd .. && sudo rm -rf "$QEMU_ARCHIVE" "$QEMU_DIR" "$QEMU_SIG"
  cd .. && sudo rmdir --ignore-fail-on-non-empty "$SRC_DIR"

}

main() {

  install_req_pkgs "QEMU"
  acquire_qemu_source
  prmt::yes_or_no "$(fmtr::ask 'Build & install QEMU to /usr/local/bin')" && compile_qemu
  ! prmt::yes_or_no "$(fmtr::ask 'Keep QEMU source to make repatching quicker')" && cleanup

}

main
