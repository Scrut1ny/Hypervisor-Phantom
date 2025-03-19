#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && exit 1

source "./utils/formatter.sh"
source "./utils/prompter.sh"
source "./utils/packages.sh"

readonly SRC_DIR="src"
readonly LG_URL="https://looking-glass.io/artifact/stable/source"
readonly LG_ARCHIVE="looking-glass-B7.tar.gz"

# https://looking-glass.io/docs/B7/build/#host
# https://looking-glass.io/wiki/Installation_on_other_distributions

REQUIRED_PKGS_Arch=(
  cmake gcc libgl libegl fontconfig spice-protocol make nettle pkgconf binutils libxi libxinerama
  libxss libxcursor libxpresent libxkbcommon wayland-protocols ttf-dejavu libsamplerate
)

REQUIRED_PKGS_Debian=(
  # https://looking-glass.io/docs/B7/build/#fetching-with-apt
  
  binutils-dev cmake fonts-dejavu-core libfontconfig-dev
  gcc g++ pkg-config libegl-dev libgl-dev libgles-dev libspice-protocol-dev
  nettle-dev libx11-dev libxcursor-dev libxi-dev libxinerama-dev
  libxpresent-dev libxss-dev libxkbcommon-dev libwayland-dev wayland-protocols
  libpipewire-0.3-dev libsamplerate0-dev

  # Add "libpulse-devel" and remove "pipewire-devel" if you use PulseAudio!
  # Not recommended though because LG doesn't support PulseAudio.
)

REQUIRED_PKGS_openSUSE=(
  binutils-devel clang cmake dejavu-fonts fontconfig-devel gcc gcc-c++ glibc-locale 
  libdecor-devel libglvnd-devel libnettle-devel libsamplerate-devel libSDL2-2_0-0
  libSDL2_ttf-2_0-0 libvulkan1 libwayland-egl1 libxkbcommon-devel libXpresent-devel
  libXrandr-devel libXss-devel libXss-devel make Mesa-libGLESv3-devel pipewire-devel
  pkgconf-pkg-config pkgconf spice-protocol-devel vulkan-devel wayland-devel
  zlib-devel-static libXi-devel libXinerama-devel libXcursor-devel dkms Mesa-libGL-devel
  Mesa-libGLESv2-devel libzstd-devel-static libconfig++-devel SDL2-devel

  # Add "libpulse-devel" and remove "pipewire-devel" if you use PulseAudio!
  # Not recommended though because LG doesn't support PulseAudio.
)

REQUIRED_PKGS_Fedora=(
  cmake gcc gcc-c++ libglvnd-devel fontconfig-devel spice-protocol make nettle-devel
  pkgconf-pkg-config binutils-devel libXi-devel libXinerama-devel libXcursor-devel
  libXpresent-devel libxkbcommon-x11-devel wayland-devel wayland-protocols-devel
  libXScrnSaver-devel libXrandr-devel dejavu-sans-mono-fonts libdecor-devel
  pipewire-devel libsamplerate-devel dkms kernel-devel kernel-headers

  # Add "pulseaudio-libs-devel" and remove "pipewire-devel" if you use PulseAudio!
  # Not recommended though because LG doesn't support PulseAudio.
)

install_looking_glass() {
  if [[ "$DISTRO" -eq "openSUSE" && ! $((find /usr/lib64/libbfd.so) 2>/dev/null) ]]; then
    fmtr::log "Configuring packages to ensure Looking Glass build completion"
    {
      LIBBFD_OLD=$(find /usr -name "libbfd*.so*" 2>/dev/null)
      sudo ln -sv $LIBBFD_OLD /usr/lib64/libbfd.so
    } &>> "$LOG_FILE"
  fi
  
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
  install_req_pkgs "Looking Glass"
  install_looking_glass
  configure_looking_glass
}

main
