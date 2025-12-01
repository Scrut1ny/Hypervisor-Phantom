#!/usr/bin/env bash

# =============================================================================
# LOGGING INITIALIZATION
# =============================================================================

log::init() {
  # Set default log path and file if not defined
  LOG_PATH="${LOG_PATH:=$(pwd)/logs}"
  LOG_FILE="${LOG_FILE:=${LOG_PATH}/$(date +%s).log}"

  readonly LOG_PATH LOG_FILE
  export LOG_PATH LOG_FILE

  # Create log directory and file
  mkdir -p "$LOG_PATH" || { echo "Failed to create log directory." >&2; exit 1; }
  touch "$LOG_FILE" || { echo "Failed to create log file." >&2; exit 1; }
}

# Initialize logging on module load
log::init

# =============================================================================
# ANSI ESCAPE CODES - Text Styles, Colors, Backgrounds
# =============================================================================

readonly RESET="\033[0m"
readonly TEXT_BOLD="\033[1m"
readonly TEXT_DIM="\033[2m"
readonly TEXT_ITALIC="\033[3m"
readonly TEXT_UNDER="\033[4m"
readonly TEXT_BLINK="\033[5m"
readonly TEXT_REVERSE="\033[7m"
readonly TEXT_HIDDEN="\033[8m"
readonly TEXT_STRIKE="\033[9m"

# Foreground colors
readonly TEXT_BLACK="\033[30m"       TEXT_GRAY="\033[90m"
readonly TEXT_RED="\033[31m"         TEXT_BRIGHT_RED="\033[91m"
readonly TEXT_GREEN="\033[32m"       TEXT_BRIGHT_GREEN="\033[92m"
readonly TEXT_YELLOW="\033[33m"      TEXT_BRIGHT_YELLOW="\033[93m"
readonly TEXT_BLUE="\033[34m"        TEXT_BRIGHT_BLUE="\033[94m"
readonly TEXT_MAGENTA="\033[35m"     TEXT_BRIGHT_MAGENTA="\033[95m"
readonly TEXT_CYAN="\033[36m"        TEXT_BRIGHT_CYAN="\033[96m"
readonly TEXT_WHITE="\033[37m"       TEXT_BRIGHT_WHITE="\033[97m"

# Background colors
readonly BACK_BLACK="\033[40m"       BACK_GRAY="\033[100m"
readonly BACK_RED="\033[41m"         BACK_BRIGHT_RED="\033[101m"
readonly BACK_GREEN="\033[42m"       BACK_BRIGHT_GREEN="\033[102m"
readonly BACK_YELLOW="\033[43m"      BACK_BRIGHT_YELLOW="\033[103m"
readonly BACK_BLUE="\033[44m"        BACK_BRIGHT_BLUE="\033[104m"
readonly BACK_MAGENTA="\033[45m"     BACK_BRIGHT_MAGENTA="\033[105m"
readonly BACK_CYAN="\033[46m"        BACK_BRIGHT_CYAN="\033[106m"
readonly BACK_WHITE="\033[47m"       BACK_BRIGHT_WHITE="\033[107m"

# =============================================================================
# FORMATTER FUNCTIONS
# =============================================================================

# Format text with ANSI styles
fmtr::format_text() {
  local prefix="$1" text="$2" suffix="$3"
  shift 3
  echo -e "${prefix}${*// }${text}${RESET}${suffix}"
}

# Internal unified logging function
__fmtr::log() {
  local icon="$1" color="$2" stream="$3"
  shift 3
  local message
  message="$(fmtr::format_text '\n  ' "$icon" " $*" "$color")"

  if [[ "$stream" == "stderr" ]]; then
    echo "$message" >&2
    echo "$message" >> "$LOG_FILE"
  else
    echo "$message" | tee -a "$LOG_FILE"
  fi
}

# Logging wrappers
fmtr::log()   { __fmtr::log "[+]" "$TEXT_BRIGHT_GREEN" "stdout" "$@"; }
fmtr::info()  { __fmtr::log "[i]" "$TEXT_BRIGHT_CYAN" "stdout" "$@"; }
fmtr::warn()  { __fmtr::log "[!]" "$TEXT_BRIGHT_YELLOW" "stdout" "$@"; }
fmtr::error() { __fmtr::log "[-]" "$TEXT_BRIGHT_RED" "stderr" "$@"; }

# Fatal error logging
fmtr::fatal() {
  local message
  message="$(fmtr::format_text '\n  ' "[X] $*" "" "$TEXT_RED" "$TEXT_BOLD")"
  echo "$message" >&2
  echo "$message" >> "$LOG_FILE"
}

# Box drawing
fmtr::box_text() {
  local text=$1 pad border
  printf -v pad '%*s' $((${#text} + 2))
  border=${pad// /═}
  printf '\n  ╔%s╗\n  ║ %s ║\n  ╚%s╝\n' "$border" "$text" "$border"
}

# Question prompt
fmtr::ask() {
  local message
  message="$(fmtr::format_text '\n  ' "[?]" " $1" "$TEXT_BLACK" "$BACK_BRIGHT_GREEN")"
  echo "$message" | tee -a "$LOG_FILE"
}

# =============================================================================
# PROMPTER FUNCTIONS
# =============================================================================

# Yes/No prompt
prmt::yes_or_no() {
  local answer
  while true; do
    read -rp "$(echo -e "$* [y/n]: ")" answer
    echo "$answer" >> "$LOG_FILE"
    case "${answer,,}" in
      y*) echo; return 0 ;;
      n*) echo; return 1 ;;
      *) echo -e "\n  [!] Please answer y/n" ;;
    esac
  done
}

# Quick keypress capture
prmt::quick_prompt() {
  local response
  read -n1 -srp "$(echo -e "$1")" response
  echo "$response"
  echo "$response" >> "$LOG_FILE"
}

# =============================================================================
# PACKAGE MANAGEMENT FUNCTIONS
# =============================================================================

# Install required packages
install_req_pkgs() {
  local component="$1"
  [[ -z "$component" ]] && { fmtr::error "Component name not specified! "; exit 1; }

  fmtr::log "Checking for required missing $component packages..."

  # Package manager configuration
  local -A PKG_MANAGERS=(
    [Arch]="pacman|-S --noconfirm|pacman -Q"
    [Debian]="apt|-y install|dpkg -s"
    [openSUSE]="zypper|install -y|rpm -q"
    [Fedora]="dnf|-yq install|rpm -q"
  )

  local config="${PKG_MANAGERS[$DISTRO]}"
  [[ -z "$config" ]] && { fmtr::error "Unsupported distribution: $DISTRO. "; exit 1; }

  # Parse manager configuration
  IFS='|' read -r PKG_MANAGER INSTALL_FLAGS CHECK_CMD <<< "$config"
  INSTALL_CMD="sudo $PKG_MANAGER $INSTALL_FLAGS"

  # Get required packages from caller's array
  local pkg_var="REQUIRED_PKGS_${DISTRO}"
  declare -n REQUIRED_PKGS_REF="$pkg_var" 2>/dev/null || {
    fmtr::error "$component packages undefined for $DISTRO."
    exit 1
  }

  # Identify missing packages
  local -a MISSING_PKGS=()
  local pkg
  for pkg in "${REQUIRED_PKGS_REF[@]}"; do
    $CHECK_CMD "$pkg" &>/dev/null || MISSING_PKGS+=("$pkg")
  done

  # Exit if all packages installed
  [[ ${#MISSING_PKGS[@]} -eq 0 ]] && {
    fmtr::log "All required $component packages already installed."
    return 0
  }

  # Prompt for installation
  fmtr::warn "Missing required $component packages: ${MISSING_PKGS[*]}"
  if prmt::yes_or_no "$(fmtr::ask "Install required missing $component packages? ")"; then
    $INSTALL_CMD "${MISSING_PKGS[@]}" &>> "$LOG_FILE" || {
      fmtr::error "Failed to install required $component packages"
      exit 1
    }
    fmtr::log "Installed: ${MISSING_PKGS[*]}"
  else
    fmtr::log "Exiting due to required missing $component packages."
    exit 1
  fi
}

# =============================================================================
# DEBUGGER FUNCTIONS
# =============================================================================

# Fatal error handler
dbg::fail() {
  fmtr::fatal "$1"
  exit 1
}
