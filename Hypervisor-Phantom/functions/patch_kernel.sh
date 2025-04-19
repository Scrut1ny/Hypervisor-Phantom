#!/usr/bin/env bash

# https://github.com/Frogging-Family/linux-tkg

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && exit 1


source "./utils/prompter.sh"
source "./utils/formatter.sh"
source "./utils/packages.sh"


# Variables
readonly SRC_DIR="src"
readonly TKG_URL="https://github.com/Frogging-Family/linux-tkg.git"
readonly TKG_DIR="linux-tkg"
readonly TKG_CFG_DIR="../../$SRC_DIR/linux-tkg/customization.cfg"
readonly PATCH_DIR="../../patches/Kernel"
readonly KERNEL_PATCH="*.mypatch"
readonly KERNEL_MAJOR="6"
readonly KERNEL_MINOR="14"
readonly KERNEL_PATCH="2"
readonly KERNEL_VERSION="${KERNEL_MAJOR}.${KERNEL_MINOR}.${KERNEL_PATCH}"


acquire_tkg_source() {
  mkdir -p "$SRC_DIR" && cd "$SRC_DIR"

  if [ -d "$TKG_DIR" ]; then
    if [ -d "$TKG_DIR/.git" ]; then
      fmtr::warn "Directory $TKG_DIR already exists and is a valid Git repository."
      if ! prmt::yes_or_no "$(fmtr::ask 'Delete and re-clone the linux-tkg source?')"; then
        fmtr::info "Keeping existing directory. Skipping re-clone."
        cd "$TKG_DIR" || { fmtr::fatal "Failed to change to TKG directory after cloning: $TKG_DIR"; exit 1; }
        return
      fi
    else
      fmtr::warn "Directory $TKG_DIR exists but is not a valid Git repository."
      if ! prmt::yes_or_no "$(fmtr::ask 'Delete and re-clone the EDK2 source?')"; then
        fmtr::info "Keeping existing directory. Skipping re-clone."
        cd "$TKG_DIR" || { fmtr::fatal "Failed to change to TKG directory after cloning: $TKG_DIR"; exit 1; }
        return
      fi
    fi
    rm -rf "$TKG_DIR" || { fmtr::fatal "Failed to remove existing directory: $TKG_DIR"; exit 1; }
    fmtr::info "Old directory deleted. Re-cloning..."
  fi

  fmtr::info "Downloading TKG source from GitHub..."
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

    local choice
    choice="$(prmt::quick_prompt '  Enter your choice [1-7]: ')"

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

    echo ""
    break
  done
}


modify_customization_cfg() {

  sed -i 's/_distro="[^"]*"/_distro="'"$distro"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"
  sed -i 's/_version="[^"]*"/_version="'"$KERNEL_VERSION"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"
  sed -i 's/_cpusched="[^"]*"/_cpusched="'"pds"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"
  sed -i 's/_compiler="[^"]*"/_compiler="'"gcc"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"
  sed -i 's/_sched_yield_type="[^"]*"/_sched_yield_type="'"0"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"
  sed -i 's/_rr_interval="[^"]*"/_rr_interval="'"2"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"
  sed -i 's/_tickless="[^"]*"/_tickless="'"1"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"

  ###

  fmtr::info "This patch enables corrected IOMMU grouping on
      motherboards with poor PCIe IOMMU grouping."
  if prmt::yes_or_no "$(fmtr::ask 'Apply ACS override bypass Kernel patch?')"; then
      sed -i 's/_acs_override="[^"]*"/_acs_override="'"true"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"
  else
      sed -i 's/_acs_override="[^"]*"/_acs_override="'"false"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"
  fi

  ###

  sed -i 's/_processor_opt="[^"]*"/_processor_opt="'""'"/' $TKG_CFG_DIR &>> "$LOG_FILE"

  ###

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

  ###

  sed -i 's/_smt_nice="[^"]*"/_smt_nice="'"true"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"

  ###

  sed -i 's/_timer_freq="[^"]*"/_timer_freq="'""'"/' $TKG_CFG_DIR &>> "$LOG_FILE"

  ###

  sed -i 's/_default_cpu_gov="[^"]*"/_default_cpu_gov="'"performance"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"

}

patch_kernel() {

  mkdir -p "linux${KERNEL_MAJOR}${KERNEL_MINOR}-tkg-userpatches" && cd "linux${KERNEL_MAJOR}${KERNEL_MINOR}-tkg-userpatches"

}



arch_distro() {

makepkg -si

}


other_distro() {

./install.sh install

}


acquire_tkg_source
select_distro
modify_customization_cfg
