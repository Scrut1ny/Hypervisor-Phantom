#!/usr/bin/env bash

# https://github.com/Frogging-Family/linux-tkg

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && exit 1

source "./utils/prompter.sh"
source "./utils/formatter.sh"
source "./utils/packages.sh"

declare -r CPU_VENDOR=$(case "$VENDOR_ID" in
  *AuthenticAMD*) echo "svm" ;;
  *GenuineIntel*) echo "vmx" ;;
  *) fmtr::error "Unknown CPU vendor."; exit 1 ;;
esac)

readonly SRC_DIR="src"
readonly TKG_URL="https://github.com/Frogging-Family/linux-tkg.git"
readonly TKG_DIR="linux-tkg"
readonly TKG_CFG_DIR="../../$SRC_DIR/linux-tkg/customization.cfg"
readonly PATCH_DIR="../../patches/Kernel"
readonly KERNEL_MAJOR="6"
readonly KERNEL_MINOR="14"
readonly KERNEL_PATCH="latest" # Set as "-latest" for linux-tkg
readonly KERNEL_VERSION="${KERNEL_MAJOR}.${KERNEL_MINOR}-${KERNEL_PATCH}"
readonly KERNEL_USER_PATCH="../../patches/Kernel/zen-kernel-${KERNEL_MAJOR}.${KERNEL_MINOR}-${KERNEL_PATCH}-${CPU_VENDOR}.mypatch"

acquire_tkg_source() {
  mkdir -p "$SRC_DIR" && cd "$SRC_DIR"

  if [ -d "$TKG_DIR" ]; then
    if [ -d "$TKG_DIR/.git" ]; then
      fmtr::warn "Directory $TKG_DIR already exists and is a valid Git repository."
      if ! prmt::yes_or_no "$(fmtr::ask 'Delete and re-clone the linux-tkg source?')"; then
        fmtr::info "Keeping existing directory; Skipping re-clone."
        cd "$TKG_DIR" || { fmtr::fatal "Failed to change to TKG directory after cloning: $TKG_DIR"; exit 1; }
        return
      fi
    else
      fmtr::warn "Directory $TKG_DIR exists but is not a valid Git repository."
      if ! prmt::yes_or_no "$(fmtr::ask 'Delete and re-clone the linux-tkg source?')"; then
        fmtr::info "Keeping existing directory; Skipping re-clone."
        cd "$TKG_DIR" || { fmtr::fatal "Failed to change to TKG directory after cloning: $TKG_DIR"; exit 1; }
        return
      fi
    fi
    rm -rf "$TKG_DIR" || { fmtr::fatal "Failed to remove existing directory: $TKG_DIR"; exit 1; }
    fmtr::info "Directory purged; re-cloning repository..."
  fi

  git clone --single-branch --depth=1 "$TKG_URL" "$TKG_DIR" &>> "$LOG_FILE" || { fmtr::fatal "Failed to clone repository."; exit 1; }
  cd "$TKG_DIR" || { fmtr::fatal "Failed to change to TKG directory after cloning: $TKG_DIR"; exit 1; }
  fmtr::info "TKG source successfully acquired."
}


select_distro() {
  while true; do
    clear; fmtr::info "Please select your Linux distribution:

  1) Arch    3) Debian  5) Suse    7) Generic
  2) Ubuntu  4) Fedora  6) Gentoo
    "

    local choice="$(prmt::quick_prompt '  Enter your choice [1-7]: ')"

    case "$choice" in
        1) distro="Arch" ;;
        2) distro="Ubuntu" ;;
        3) distro="Debian" ;;
        4) distro="Fedora" ;;
        5) distro="Suse" ;;
        6) distro="Gentoo" ;;
        7) distro="Generic" ;;
        *)
            clear; fmtr::error "Invalid option, please try again."
            prmt::quick_prompt "$(fmtr::info 'Press any key to continue...')"
            continue
            ;;
    esac

    echo ""; fmtr::info "Selected Linux distribution: ${distro}"
    break
  done
}


modify_customization_cfg() {

  sed -i 's/_distro="[^"]*"/_distro="'"$distro"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"
  sed -i 's/_version="[^"]*"/_version="'"$KERNEL_VERSION"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"
  sed -i 's/_menunconfig="[^"]*"/_menunconfig="'"false"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"
  sed -i 's/_diffconfig="[^"]*"/_diffconfig="'"false"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"
  sed -i 's/_cpusched="[^"]*"/_cpusched="'"eevdf"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"
  sed -i 's/_compiler="[^"]*"/_compiler="'"gcc"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"
  sed -i 's/_sched_yield_type="[^"]*"/_sched_yield_type="'"0"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"
  sed -i 's/_rr_interval="[^"]*"/_rr_interval="'"2"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"
  sed -i 's/_tickless="[^"]*"/_tickless="'"1"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"

  ####################################################################################################
  ####################################################################################################

  fmtr::info "This patch enables corrected IOMMU grouping on
      motherboards with poor PCIe IOMMU grouping."
  if prmt::yes_or_no "$(fmtr::ask 'Apply ACS override bypass Kernel patch?')"; then
      sed -i 's/_acs_override="[^"]*"/_acs_override="'"true"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"
  else
      sed -i 's/_acs_override="[^"]*"/_acs_override="'"false"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"
  fi

  ####################################################################################################
  ####################################################################################################

  while true; do

    if [[ "$CPU_VENDOR" == "svm" ]]; then
      vendor="AMD"
      fmtr::info "Detected CPU Vendor: ${vendor}

  Please select your Intel CPU microarchitecture code name:

  1) k8         5) bobcat      9) steamroller  13) zen3
  2) k8sse3     6) jaguar      10) excavator   14) zen4
  3) k10        7) bulldozer   11) zen         15) zen5
  4) barcelona  8) piledriver  12) zen2        16) Automated (not recommended)
      "
      read -p "  Enter your choice [1-16]: " choice
      case "$choice" in
        1) selected="k8" ;;
        2) selected="k8sse3" ;;
        3) selected="k10" ;;
        4) selected="barcelona" ;;
        5) selected="bobcat" ;;
        6) selected="jaguar" ;;
        7) selected="bulldozer" ;;
        8) selected="piledriver" ;;
        9) selected="steamroller" ;;
        10) selected="excavator" ;;
        11) selected="zen" ;;
        12) selected="zen2" ;;
        13) selected="zen3" ;;
        14) selected="zen4" ;;
        15) selected="zen5" ;;
        16) selected="native_amd" ;;
        *)
          clear; fmtr::error "Invalid option, please try again."
          prmt::quick_prompt "$(fmtr::info 'Press any key to continue...')"
          continue
          ;;
      esac

    elif [[ "$CPU_VENDOR" == "vmx" ]]; then
      vendor="Intel"
      fmtr::info "Detected CPU Vendor: ${vendor}

  Please select your Intel CPU microarchitecture code name:

  1) mpsc         8) ivybridge    15) icelake_server  22) rocketlake
  2) atom         9) haswell      16) goldmont        23) alderlake
  3) core2        10) broadwell   17) goldmontplus    24) raptorlake
  4) nehalem      11) skylake     18) cascadelake     25) meteorlake
  5) westmere     12) skylakex    19) cooperlake      26) automated (not recommended)
  6) silvermont   13) cannonlake  20) tigerlake
  7) sandybridge  14) icelake     21) sapphirerapids
      "
      read -p "  Enter your choice [1-26]: " choice
      case "$choice" in
        1) selected="mpsc" ;;
        2) selected="atom" ;;
        3) selected="core2" ;;
        4) selected="nehalem" ;;
        5) selected="westmere" ;;
        6) selected="silvermont" ;;
        7) selected="sandybridge" ;;
        8) selected="ivybridge" ;;
        9) selected="haswell" ;;
        10) selected="broadwell" ;;
        11) selected="skylake" ;;
        12) selected="skylakex" ;;
        13) selected="cannonlake" ;;
        14) selected="icelake" ;;
        15) selected="icelake_server" ;;
        16) selected="goldmont" ;;
        17) selected="goldmontplus" ;;
        18) selected="cascadelake" ;;
        19) selected="cooperlake" ;;
        20) selected="tigerlake" ;;
        21) selected="sapphirerapids" ;;
        22) selected="rocketlake" ;;
        23) selected="alderlake" ;;
        24) selected="raptorlake" ;;
        25) selected="meteorlake" ;;
        26) selected="native_intel" ;;
        *)
          clear; fmtr::error "Invalid option, please try again."
          prmt::quick_prompt "$(fmtr::info 'Press any key to continue...')"
          ;;
      esac

    else
      fmtr::warn "Unsupported or undefined CPU_VENDOR: $CPU_VENDOR"
      exit 1
    fi

    break
  done

  sed -i 's/_processor_opt="[^"]*"/_processor_opt="'"$selected"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"

  ####################################################################################################
  ####################################################################################################

  if output=$(/lib/ld-linux-x86-64.so.2 --help 2>/dev/null | grep supported); then
      :
  elif output=$(/lib64/ld-linux-x86-64.so.2 --help 2>/dev/null | grep supported); then
      :
  fi

  highest=0

  while IFS= read -r line; do
      if [[ $line =~ x86-64-v([123]) ]]; then
          version="${BASH_REMATCH[1]}"
          if (( version > highest )); then
              highest=$version
          fi
      fi
  done <<< "$output"

  x86_version=$highest

  sed -i 's/_x86_64_isalvl="[^"]*"/_x86_64_isalvl="'"$highest"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"

  ####################################################################################################
  ####################################################################################################

  sed -i 's/_timer_freq="[^"]*"/_timer_freq="'"1000"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"
  sed -i 's/_user_patches_no_confirm="[^"]*"/_user_patches_no_confirm="'"true"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"

}

patch_kernel() {

  mkdir -p "linux${KERNEL_MAJOR}${KERNEL_MINOR}-tkg-userpatches"
  cp "${KERNEL_USER_PATCH}" "linux${KERNEL_MAJOR}${KERNEL_MINOR}-tkg-userpatches"

}

arch_distro() {

  clear; makepkg -C -si --noconfirm

}

other_distro() {

  clear; sudo ./install.sh install

}

systemd-boot_boot_entry_maker() {

  declare -a SDBOOT_CONF_LOCATIONS=(
    "/boot/loader/entries"
    "/boot/efi/loader/entries"
    "/efi/loader/entries"
  )

  local ENTRY_NAME="HvP-RDTSC.conf"
  local TIMESTAMP; TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
  local ROOT_DEVICE; ROOT_DEVICE=$(findmnt -no SOURCE /)
  local PARTUUID; PARTUUID=$(blkid -s PARTUUID -o value "$ROOT_DEVICE")
  ROOTFSTYPE=$(findmnt -no FSTYPE /)

  if [[ -z "$PARTUUID" ]]; then
    fmtr::error "Unable to determine PARTUUID for root device ($ROOT_DEVICE)."
    return 1
  fi

  local BOOT_ENTRY_CONTENT=$(cat <<EOF
# Created by: Hypervisor-Phantom
# Created on: $TIMESTAMP
title   HvP (RDTSC Patch)
linux   /vmlinuz-linux$KERNEL_MAJOR$KERNEL_MINOR-tkg-eevdf
initrd  /initramfs-linux$KERNEL_MAJOR$KERNEL_MINOR-tkg-eevdf.img
options root=PARTUUID=$PARTUUID rw rootfstype=$ROOTFSTYPE
EOF
)

  local FALLBACK_BOOT_ENTRY_CONTENT=$(cat <<EOF
# Created by: Hypervisor-Phantom
# Created on: $TIMESTAMP
title   HvP (RDTSC Patch - Fallback)
linux   /vmlinuz-linux$KERNEL_MAJOR$KERNEL_MINOR-tkg-eevdf
initrd  /initramfs-linux$KERNEL_MAJOR$KERNEL_MINOR-tkg-eevdf-fallback.img
options root=PARTUUID=$PARTUUID rw rootfstype=$ROOTFSTYPE
EOF
)

  for ENTRY_DIR in "${SDBOOT_CONF_LOCATIONS[@]}"; do
    if [[ -d "$ENTRY_DIR" ]]; then
      echo "$BOOT_ENTRY_CONTENT" > "$ENTRY_DIR/$ENTRY_NAME"
      echo "$FALLBACK_BOOT_ENTRY_CONTENT" > "$ENTRY_DIR/FALLBACK_$ENTRY_NAME"
      fmtr::info "Boot entries written to: $ENTRY_DIR/$ENTRY_NAME and $ENTRY_DIR/FALLBACK_$ENTRY_NAME"
      return 0
    fi
  done

  fmtr::error "No valid systemd-boot entry directory found."
  return 1

}

acquire_tkg_source
select_distro
modify_customization_cfg
patch_kernel

if [ "$distro" == "Arch" ]; then
    arch_distro
else
    other_distro
fi

systemd-boot_boot_entry_maker
