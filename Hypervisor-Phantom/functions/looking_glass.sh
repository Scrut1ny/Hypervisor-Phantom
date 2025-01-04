#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && exit 1

source "./utils/formatter.sh"
source "./utils/prompter.sh"

readonly SRC_DIR="src"
readonly LG_URL="https://looking-glass.io/artifact/stable/source"
readonly LG_ARCHIVE="looking-glass-B6.tar.gz"

install_req_pkgs() {
  fmtr::log "Checking for missing packages"

  case "$DISTRO" in
    Arch)
      REQUIRED_PKGS=("cmake" "gcc" "libegl" "libgl" "fontconfig" "spice-protocol" \
        "pkgconf" "binutils" "libxi" "libxinerama" "libxss" "libxcursor" "libxpresent" "make" \
        "libxkbcommon" "wayland-protocols" "ttf-dejavu" "libsamplerate" "nettle" \
        "linux-headers" "dkms"
      )
      PKG_MANAGER="pacman"
      INSTALL_CMD="sudo pacman -S --noconfirm"
      CHECK_CMD="pacman -Q"
      ;;
    Debian)
      REQUIRED_PKGS=("binutils-dev" "cmake" "fonts-dejavu-core" "libfontconfig-dev" \
        "gcc" "g++" "pkg-config" "libegl-dev" "libgl-dev" "libgles-dev" "libspice-protocol-dev" \
        "nettle-dev" "libx11-dev" "libxcursor-dev" "libxi-dev" "libxinerama-dev" \
        "libxpresent-dev" "libxss-dev" "libxkbcommon-dev" "libwayland-dev" "wayland-protocols" \
        "libpipewire-0.3-dev" "libpulse-dev" "libsamplerate0-dev"
      )
      PKG_MANAGER="apt"
      INSTALL_CMD="sudo apt -y install"
      CHECK_CMD="dpkg -l"
      ;;
    Fedora)
      REQUIRED_PKGS=("cmake" "gcc" "gcc-c++" "libglvnd-devel" "fontconfig-devel" \
        "spice-protocol" "make" "nettle-devel" "pkgconf-pkg-config" "binutils-devel" \
        "libXi-devel" "libXinerama-devel" "libXcursor-devel" "libXpresent-devel" \
        "libxkbcommon-x11-devel" "wayland-devel" "wayland-protocols-devel" \
        "libXScrnSaver-devel" "libXrandr-devel" "dejavu-sans-mono-fonts" \
        "libdecor-devel" "pipewire-devel" "libsamplerate-devel" \
        "pulseaudio-libs-devel" "dkms" "kernel-devel" "kernel-headers"
      )
      PKG_MANAGER="dnf"
      INSTALL_CMD="sudo dnf -y install"
      CHECK_CMD="rpm -q"
      ;;
    *)
      fmtr::error "Distribution not recognized or not supported by this script."
      exit 1
      ;;
  esac

  # List to store missing packages
  MISSING_PKGS=()

  # Check each required package
  for PKG in "${REQUIRED_PKGS[@]}"; do
    if ! $CHECK_CMD $PKG &>/dev/null; then
      MISSING_PKGS+=("$PKG")
    fi
  done

  # If no packages are missing, notify the user
  if [ ${#MISSING_PKGS[@]} -eq 0 ]; then
    fmtr::log "All required packages for LG are already installed."
    return 0
  fi

  fmtr::warn "The required packages are missing: ${MISSING_PKGS[@]}"
  if prmt::yes_or_no "$(fmtr::ask 'Install the missing packages for LG?')"; then
    # Install missing packages
    $INSTALL_CMD "${MISSING_PKGS[@]}" &>> "$LOG_FILE"
    if [ $? -eq 0 ]; then
      fmtr::log "Successfully installed missing packages: ${MISSING_PKGS[@]}"
    else
      fmtr::error "Failed to install some packages. Check the log for details."
      exit 1
    fi
  else
    fmtr::error "The missing packages are required to continue; Exiting."
    exit 1
  fi
}

install_looking_glass() {
  mkdir -p "$SRC_DIR" && cd "$SRC_DIR"

  fmtr::log "Downloading Looking Glass"
  curl -sSLo "$LG_ARCHIVE" "$LG_URL" && tar -zxf "$LG_ARCHIVE" && rm -rf "$LG_ARCHIVE"

  fmtr::log "Building & Installing Looking Glass"
  {
    cd looking-glass-* && mkdir client/build && cd client/build
    cmake ../
    sudo make install -j"$(nproc)"
  } &>> "$LOG_FILE"

  fmtr::log "Cleaning up"
  cd ../../../ && sudo rm -rf ./looking-glass-*
}

configure_looking_glass() {
  fmtr::log "Creating '10-looking-glass.conf'"
  local conf_file="/etc/tmpfiles.d/10-looking-glass.conf"
  local username=${SUDO_USER:-$(whoami)}

  echo "f /dev/shm/looking-glass 0660 ${username} kvm -" | sudo tee "$conf_file" &>> "$LOG_FILE"

  fmtr::log "Granting Looking Glass Permissions"
  {
    touch /dev/shm/looking-glass
    sudo chown "${username}:kvm" /dev/shm/looking-glass
    chmod 660 /dev/shm/looking-glass
  } &>> "$LOG_FILE"

  local entry_to_add="$(cat <<- 'EOF'
# Alias lg for Looking Glass shared memory setup
alias lg='if [ ! -e /dev/shm/looking-glass ]; then \
  touch /dev/shm/looking-glass; \
  sudo chown $USER:kvm /dev/shm/looking-glass; \
  chmod 660 /dev/shm/looking-glass; \
  /usr/local/bin/looking-glass-client -S -K -1; \
else \
  /usr/local/bin/looking-glass-client -S -K -1; \
fi'
EOF
  )"

  if ! grep -q "alias lg=" ~/.bashrc; then
    echo "$entry_to_add" >> ~/.bashrc
    fmtr::log "A new bashrc entry was made for launching Looking Glass."
  else
    fmtr::info "The lg alias already exists in .bashrc."
  fi

  source "${HOME}/.bashrc"
  fmtr::info "Just type 'lg' in the terminal to launch Looking Glass"
}

main() {
  install_req_pkgs
  install_looking_glass
  configure_looking_glass
}

main
