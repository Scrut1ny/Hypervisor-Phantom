#!/usr/bin/env bash

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
readonly KERNEL_VERSION="6.14.2"


acquire_tkg_source() {
  mkdir -p "$SRC_DIR" && cd "$SRC_DIR"

  if [ -d "$TKG_DIR" ]; then
    if [ -d "$TKG_DIR/.git" ]; then
      fmtr::warn "Directory $TKG_DIR already exists and is a valid Git repository."
      if ! prmt::yes_or_no "$(fmtr::ask 'Delete and re-clone the TKG source?')"; then
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
            clear
            fmtr::error "Invalid option, please try again."
            prmt::quick_prompt "$(fmtr::info 'Press any key to continue...')"
            continue
            ;;
    esac

    echo ""; fmtr::info "You selected: $distro"
    break
  done
}


modify_customization_cfg() {

  sed -i 's/_distro=""/_distro="'"$distro"'"/' $TKG_CFG_DIR &>> "$LOG_FILE"

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
