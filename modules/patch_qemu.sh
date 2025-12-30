#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && { echo "Required environment variables not set."; exit 1; }

source "./utils.sh"

declare -r CPU_VENDOR=$(case "$VENDOR_ID" in
  *AuthenticAMD*) echo "amd" ;;
  *GenuineIntel*) echo "intel" ;;
  *) fmtr::error "Unknown CPU Vendor ID."; exit 1 ;;
esac)

readonly SRC_DIR="$(pwd)/src"
readonly OUT_DIR="/opt/Hypervisor-Phantom"

readonly QEMU_VERSION="10.2.0"
readonly QEMU_DIR="qemu-${QEMU_VERSION}"
readonly QEMU_ARCHIVE="${QEMU_DIR}.tar.xz"
readonly QEMU_URL="https://download.qemu.org/${QEMU_ARCHIVE}"
readonly PATCH_DIR="../../patches/QEMU"
readonly QEMU_PATCH="${CPU_VENDOR}-${QEMU_DIR}.patch"

REQUIRED_PKGS_Arch=(
  # Basic Build Dependencie(s)
  acpica base-devel dmidecode glib2 ninja python-packaging
  python-sphinx python-sphinx_rtd_theme gnupg patch curl libevdev

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
  python3-sphinx python3-sphinx-rtd-theme patch curl

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
  libpixman-1-0-devel patch python3-Sphinx ninja curl

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
  pixman-devel python3 zlib-ng-devel gnupg2 patch curl

  # Spice Dependencie(s)
  spice-server-devel

  # USB passthrough Dependencie(s)
  libusb1-devel

  # USB redirection Dependencie(s)
  usbredir-devel
)

acquire_qemu_source() {
  $ROOT_ESC mkdir -p "$OUT_DIR"/{emulator,firmware}
  mkdir -p "$SRC_DIR" && cd "$SRC_DIR"

  if [ -d "$QEMU_DIR" ]; then
    fmtr::warn "Directory $QEMU_DIR already exists."
    if ! prmt::yes_or_no "$(fmtr::ask 'Purge the QEMU directory?')"; then
      fmtr::info "Keeping existing directory. Skipping re-download."
      cd "$QEMU_DIR" || { fmtr::fatal "Failed to change to QEMU directory: $QEMU_DIR"; exit 1; }
      return
    fi
    rm -rf "$QEMU_DIR/" "$QEMU_ARCHIVE" || { fmtr::fatal "Failed to remove existing directory: $QEMU_DIR"; exit 1; }
    fmtr::info "Directory purged."
  fi

  fmtr::info "Downloading QEMU source archive..."
  curl -sSO "$QEMU_URL" || { fmtr::fatal "Failed to download QEMU source archive."; exit 1; }

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

  fmtr::info "Applying patches to QEMU..."

  patch -fsp1 < "${PATCH_DIR}/${QEMU_PATCH}" &>> "$LOG_FILE" || {
    fmtr::error "Failed to apply patch ${QEMU_PATCH}!"
    fmtr::fatal "Patch application failed. Please check the log for errors."
    exit 1
  }

  fmtr::log "Spoofing all unique hardcoded QEMU identifiers..."

  spoof_serials
  spoof_models
  spoof_smbios
  spoof_acpi
}












spoof_serials() {
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











spoof_models() {
    local ide="hw/ide/core.c"
    local nvme="hw/nvme/ctrl.c"

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

    sed -i "$ide" -Ee "s/\"HL-DT-ST BD-RE WH16NS60\"/\"${new_ide_cd_model}\"/"
    sed -i "$ide" -Ee "s/\"Hitachi HMS360404D5CF00\"/\"${new_ide_cfata_model}\"/"
    sed -i "$ide" -Ee "s/\"Samsung SSD 980 500GB\"/\"${new_default_model}\"/"
    sed -i "$nvme" -Ee "s/\"NVMe Ctrl\"/\"${new_default_model}\"/"
}








spoof_acpi() {
  local t=/sys/firmware/acpi/tables/FACP

  local h=include/hw/acpi/aml-build.h
  local c=hw/acpi/aml-build.c

  # https://uefi.org/sites/default/files/resources/ACPI_Spec_6.6.pdf#subsection.5.2.9

  local OEMID OEM_TABLE_ID chassis_type ssdt out

  OEMID="$(LC_ALL=C $ROOT_ESC dd if="$t" bs=1 skip=10 count=6 status=none | tr '\0' ' ')"
  OEM_TABLE_ID="$(LC_ALL=C $ROOT_ESC dd if="$t" bs=1 skip=16 count=8 status=none | tr '\0' ' ')"

  sed -i \
    -e 's/^\(#define ACPI_BUILD_APPNAME6 "\)[^"]*\("\)/\1'"$OEMID"'\2/' \
    -e 's/^\(#define ACPI_BUILD_APPNAME8 "\)[^"]*\("\)/\1'"$OEM_TABLE_ID"'\2/' \
    "$h"


  # https://uefi.org/sites/default/files/resources/ACPI_Spec_6.6.pdf#subsubsection.5.2.9.1
  # https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.9.0.pdf#%5B%7B%22num%22%3A266%2C%22gen%22%3A0%7D%2C%7B%22name%22%3A%22XYZ%22%7D%2C70%2C302%2C0%5D

  chassis_type="$(< /sys/class/dmi/id/chassis_type)"
  sed -i 's/\(build_append_int_noprefix(tbl, \)0\( \/\* Unspecified \*\/, 1);\)/\1'"$chassis_type"'\2/' "$c"

  if [[ $chassis_type =~ ^(9|10)$ ]]; then
    fmtr::warn "Host Chassis Type equals '$chassis_type' (Mobile)"

    ssdt="$($ROOT_ESC find /sys/firmware/acpi/tables/ -type f ! -name DSDT -exec grep -il battery {} + | head -n1)"
    if [[ -z $ssdt ]]; then
      fmtr::warn "No SSDT containing 'battery' found"
      return 0
    fi

    out="$OUT_DIR/firmware/$(basename "$ssdt")-battery.aml"
    $ROOT_ESC cp -- "$ssdt" "$out"

    $ROOT_ESC chmod 0644 -- "$out"
    $ROOT_ESC chown -- "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" "$out" 2>/dev/null || true

    fmtr::info "Copied '$ssdt' to '$out'"
  fi
}











spoof_smbios() {
  local chipset_file

  case "$QEMU_VERSION" in
    "8.2.6")
      chipset_file="hw/i386/pc_q35.c"
      ;;
    9.*|10.*.*)
      chipset_file="hw/i386/fw_cfg.c"
      ;;
    *)
      fmtr::warn "Unsupported QEMU version: $QEMU_VERSION"
      ;;
  esac

  local manufacturer=$($ROOT_ESC dmidecode --string processor-manufacturer)
  sed -i "$chipset_file" -e "s/smbios_set_defaults(\"[^\"]*\",/smbios_set_defaults(\"${manufacturer}\",/"

  # TODO: Implement smbios.bin spoofer
}
















compile_qemu() {
  fmtr::log "Configuring build environment"

  ./configure --target-list=x86_64-softmmu \
              --prefix="$OUT_DIR/emulator" \
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

  fmtr::log "Installing QEMU to '$OUT_DIR/emulator'"
  $ROOT_ESC make install &>> "$LOG_FILE"
  if [[ $? -ne 0 ]]; then
    fmtr::error "Install failed. Check $LOG_FILE"
    return 1
  fi

  fmtr::info "Compilation finished!"
}











cleanup() {
  fmtr::info "Cleaning up..."
  rm -rf "$SRC_DIR"/{"$QEMU_ARCHIVE","$QEMU_DIR"}
  rmdir --ignore-fail-on-non-empty "$SRC_DIR" 2>/dev/null || true
}











main() {
  install_req_pkgs "QEMU"
  acquire_qemu_source
  prmt::yes_or_no "$(fmtr::ask 'Build & install QEMU?')" && compile_qemu
  ! prmt::yes_or_no "$(fmtr::ask 'Keep QEMU source to make repatching quicker')" && cleanup
}

main
