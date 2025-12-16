#!/usr/bin/env bash

# =============================================================================
# LOGGING
# =============================================================================

log::init() {
  : "${LOG_PATH:=$(pwd)/logs}"
  : "${LOG_FILE:=$LOG_PATH/$(date +%s).log}"

  export LOG_PATH LOG_FILE
  mkdir -p -- "$LOG_PATH" || { printf 'Failed to create log directory.\n' >&2; exit 1; }
  : >"$LOG_FILE"          || { printf 'Failed to create log file.\n' >&2; exit 1; }
}
log::init

# =============================================================================
# ANSI ESCAPE CODES - Text Styles, Colors, Backgrounds
# =============================================================================

# Styles
readonly RESET=$'\033[0m'
readonly TEXT_BOLD=$'\033[1m'
readonly TEXT_DIM=$'\033[2m'
readonly TEXT_ITALIC=$'\033[3m'
readonly TEXT_UNDER=$'\033[4m'
readonly TEXT_BLINK=$'\033[5m'
readonly TEXT_REVERSE=$'\033[7m'
readonly TEXT_HIDDEN=$'\033[8m'
readonly TEXT_STRIKE=$'\033[9m'

# Foreground colors
readonly TEXT_BLACK=$'\033[30m'       TEXT_GRAY=$'\033[90m'
readonly TEXT_RED=$'\033[31m'         TEXT_BRIGHT_RED=$'\033[91m'
readonly TEXT_GREEN=$'\033[32m'       TEXT_BRIGHT_GREEN=$'\033[92m'
readonly TEXT_YELLOW=$'\033[33m'      TEXT_BRIGHT_YELLOW=$'\033[93m'
readonly TEXT_BLUE=$'\033[34m'        TEXT_BRIGHT_BLUE=$'\033[94m'
readonly TEXT_MAGENTA=$'\033[35m'     TEXT_BRIGHT_MAGENTA=$'\033[95m'
readonly TEXT_CYAN=$'\033[36m'        TEXT_BRIGHT_CYAN=$'\033[96m'
readonly TEXT_WHITE=$'\033[37m'       TEXT_BRIGHT_WHITE=$'\033[97m'

# Background colors
readonly BACK_BLACK=$'\033[40m'       BACK_GRAY=$'\033[100m'
readonly BACK_RED=$'\033[41m'         BACK_BRIGHT_RED=$'\033[101m'
readonly BACK_GREEN=$'\033[42m'       BACK_BRIGHT_GREEN=$'\033[102m'
readonly BACK_YELLOW=$'\033[43m'      BACK_BRIGHT_YELLOW=$'\033[103m'
readonly BACK_BLUE=$'\033[44m'        BACK_BRIGHT_BLUE=$'\033[104m'
readonly BACK_MAGENTA=$'\033[45m'     BACK_BRIGHT_MAGENTA=$'\033[105m'
readonly BACK_CYAN=$'\033[46m'        BACK_BRIGHT_CYAN=$'\033[106m'
readonly BACK_WHITE=$'\033[47m'       BACK_BRIGHT_WHITE=$'\033[107m'

# =============================================================================
# FORMAT / LOG HELPERS
# =============================================================================

__log::write() {
  local stream=$1; shift
  if [[ $stream == stderr ]]; then
    printf '%b\n' "$*" >&2
  else
    printf '%b\n' "$*"
  fi
  printf '%b\n' "$*" >>"$LOG_FILE"
}

__fmtr::line() {
  local icon=$1 color=$2; shift 2
  printf '\n  %b%s%b %s' "$color" "$icon" "$RESET" "$*"
}

fmtr::log()   { __log::write stdout "$(__fmtr::line '[+]' "$TEXT_BRIGHT_GREEN"  "$@")"; }
fmtr::info()  { __log::write stdout "$(__fmtr::line '[i]' "$TEXT_BRIGHT_CYAN"   "$@")"; }
fmtr::warn()  { __log::write stdout "$(__fmtr::line '[!]' "$TEXT_BRIGHT_YELLOW" "$@")"; }
fmtr::error() { __log::write stderr "$(__fmtr::line '[-]' "$TEXT_BRIGHT_RED"    "$@")"; }

fmtr::fatal() {
  __log::write stderr "$(printf '\n  %b%s %s%b' "$TEXT_RED$TEXT_BOLD" '[X]' "$*" "$RESET")"
}

fmtr::box_text() {
  local text=$1 pad border
  printf -v pad '%*s' $(( ${#text} + 2 )) ''
  border=${pad// /═}
  printf '\n  ╔%s╗\n  ║ %s ║\n  ╚%s╝\n' "$border" "$text" "$border"
}

fmtr::ask() {
  __log::write stdout "$(printf '\n  %b[?]%b %s' "$TEXT_BLACK$BACK_BRIGHT_GREEN" "$RESET" "$1")"
}

fmtr::ask_inline() {
  printf '\n  %b[?]%b %s' "$TEXT_BLACK$BACK_BRIGHT_GREEN" "$RESET" "$1"
}

# =============================================================================
# PROMPTS
# =============================================================================

prmt::yes_or_no() {
  local prompt=$* ans
  while :; do
    read -rp "$prompt [y/n]: " ans
    printf '%s\n' "$ans" >>"$LOG_FILE"
    case ${ans,,} in
      y*) printf '\n'; return 0 ;;
      n*) printf '\n'; return 1 ;;
      *)  printf '\n  [!] Please answer y/n\n' ;;
    esac
  done
}

prmt::quick_prompt() {
  local response
  read -n1 -srp "$1" response
  printf '%s\n' "$response"
  printf '%s\n' "$response" >>"$LOG_FILE"
}

# =============================================================================
# PACKAGES
# =============================================================================

install_req_pkgs() {
  local component=$1
  [[ -n $component ]] || { fmtr::error "Component name not specified!"; exit 1; }

  fmtr::log "Checking for required missing $component packages..."

  local mgr install_flags check_cmd
  case $DISTRO in
    Arch)     mgr=pacman; install_flags='-S --noconfirm'; check_cmd='pacman -Q' ;;
    Debian)   mgr=apt;    install_flags='-y install';     check_cmd='dpkg -s'   ;;
    openSUSE) mgr=zypper; install_flags='install -y';     check_cmd='rpm -q'    ;;
    Fedora)   mgr=dnf;    install_flags='-yq install';    check_cmd='rpm -q'    ;;
    *) fmtr::error "Unsupported distribution: $DISTRO."; exit 1 ;;
  esac

  local pkg_var="REQUIRED_PKGS_${DISTRO}"
  declare -n req="$pkg_var" 2>/dev/null || { fmtr::error "$component packages undefined for $DISTRO."; exit 1; }

  local -a missing=()
  local pkg
  for pkg in "${req[@]}"; do
    $check_cmd "$pkg" &>/dev/null || missing+=("$pkg")
  done

  (( ${#missing[@]} )) || { fmtr::log "All required $component packages already installed."; return 0; }

  fmtr::warn "Missing required $component packages: ${missing[*]}"
  if prmt::yes_or_no "$(fmtr::ask_inline "Install required missing $component packages?")"; then
    sudo "$mgr" $install_flags "${missing[@]}" &>>"$LOG_FILE" || { fmtr::error "Failed to install required $component packages"; exit 1; }
    fmtr::log "Installed: ${missing[*]}"
  else
    fmtr::log "Exiting due to required missing $component packages."
    exit 1
  fi
}

# =============================================================================
# DEBUG
# =============================================================================

dbg::fail() { fmtr::fatal "$1"; exit 1; }
