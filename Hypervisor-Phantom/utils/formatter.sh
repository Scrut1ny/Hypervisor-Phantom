#!/usr/bin/env bash
#
# A library to format text in the terminal.
# The ANSI text color and style codes are all provided as environment variables
# and can be easily used in the standardized function "format_text".
# For messages to the user use the
# ask, log, info, warn, error and fatal wrapper functions.
# And for important information and titles, you may use box_text
#

if [[ -z "$LOG_FILE" ]]; then
  exit 1
fi

# exports ANSI codes as read-only variables
declare -xr RESET="\033[0m"
# text styles
declare -xr BOLD="\033[1m"
declare -xr DIM="\033[2m"
declare -xr ITALIC="\033[3m"
declare -xr UNDER="\033[4m"
declare -xr BLINK="\033[5m"
declare -xr REVERSE="\033[7m"
declare -xr HIDDEN="\033[8m"
declare -xr STRIKE="\033[9m"
# text colors
declare -xr TEXT_BLACK="\033[30m"; declare -xr TEXT_GRAY="\033[90m"
declare -xr TEXT_RED="\033[31m"; declare -xr TEXT_BRIGHT_RED="\033[91m"
declare -xr TEXT_GREEN="\033[32m"; declare -xr TEXT_BRIGHT_GREEN="\033[92m"
declare -xr TEXT_YELLOW="\033[33m"; declare -xr TEXT_BRIGHT_YELLOW="\033[93m"
declare -xr TEXT_BLUE="\033[34m"; declare -xr TEXT_BRIGHT_BLUE="\033[94m"
declare -xr TEXT_MAGENTA="\033[35m"; declare -xr TEXT_BRIGHT_MAGENTA="\033[95m"
declare -xr TEXT_CYAN="\033[36m"; declare -xr TEXT_BRIGHT_CYAN="\033[96m"
declare -xr TEXT_WHITE="\033[37m"; declare -xr TEXT_BRIGHT_WHITE="\033[97m"
# background colors
declare -xr BACK_BLACK="\033[40m"; declare -xr BACK_GRAY="\033[100m"
declare -xr BACK_RED="\033[41m"; declare -xr BACK_BRIGHT_RED="\033[101m"
declare -xr BACK_GREEN="\033[42m"; declare -xr BACK_BRIGHT_GREEN="\033[102m"
declare -xr BACK_YELLOW="\033[43m"; declare -xr BACK_BRIGHT_YELLOW="\033[103m"
declare -xr BACK_BLUE="\033[44m"; declare -xr BACK_BRIGHT_BLUE="\033[104m"
declare -xr BACK_MAGENTA="\033[45m"; declare -xr BACK_BRIGHT_MAGENTA="\033[105m"
declare -xr BACK_CYAN="\033[46m"; declare -xr BACK_BRIGHT_CYAN="\033[106m"
declare -xr BACK_WHITE="\033[47m"; declare -xr BACK_BRIGHT_WHITE="\033[107m"

###############################################################
# Formats a part of the provided string using ANSI escape codes
# Globals:
#   RESET: The escape code that resets formatting
# Arguments:
#   $1: Unformatted text before $2
#   $2: The text to be formatted
#   $3: Unformatted text after $2
#   ${*:4}: ANSI codes to set on $2
# Outputs:
#   Writes complete string with ANSI codes to STDOUT
###############################################################
function fmtr::format_text() {
  local prefix="$1"
  local text="$2"
  local suffix="$3"
  local codes="${*:4}"
  echo -e "${prefix}${codes// /}${text}${RESET}${suffix}"
}

#######################################################
# Provides stylized decorations for prompts to the user
# Globals:
#   TEXT_BLACK
#   BACK_BRIGHT_GREEN
# Arguments:
#   Question to ask to the user
# Outputs:
#   Formatted question for the user to STDOUT
#######################################################
function fmtr::ask() {
  local text="$1"
  local message="$(fmtr::format_text \
    '\n  ' "[?]" " ${text}" "$TEXT_BLACK" "$BACK_BRIGHT_GREEN")"
  echo "$message" | tee -a "$LOG_FILE"
}

################################################
# Provides stylized decorations for log messages
# Globals:
#   TEXT_BRIGHT_GREEN
# Arguments:
#   Message to log
# Outputs:
#   Formatted log message to STDOUT
################################################
function fmtr::log() {
  local text="$1"
  local message="$(fmtr::format_text \
    '\n  ' "[+]" " ${text}" "$TEXT_BRIGHT_GREEN")"
  echo "$message" | tee -a "$LOG_FILE"
}

########################################################
# Provides stylized decorations for messages to the user
# Globals:
#   TEXT_BRIGHT_CYAN
# Arguments:
#   The message to the user
# Outputs:
#   Formatted info message
########################################################
function fmtr::info() {
  local text="$1"
  local message="$(fmtr::format_text \
    '\n  ' "[i]" " ${text}" "$TEXT_BRIGHT_CYAN")"
  echo "$message" | tee -a "$LOG_FILE"
}

########################################################
# Provides stylized decorations for warnings to the user
# Globals:
#   TEXT_BRIGHT_YELLOW
# Arguments:
#   The important message to the user
# Outputs:
#   Formatted warning
########################################################
function fmtr::warn() {
  local text="$1"
  local message="$(fmtr::format_text \
    '\n  ' "[!]" " ${text}" "$TEXT_BRIGHT_YELLOW")"
  echo "$message" | tee -a "$LOG_FILE"
}

##############################################################
# Provides stylized decorations for recoverable error messages
# Globals:
#   TEXT_BRIGHT_RED
# Arguments:
#   The error to print
# Outputs:
#   Formatted error message
########################################################
function fmtr::error() {
  local text="$1"
  local message="$(fmtr::format_text \
    '\n  ' "[-]" " ${text}" "$TEXT_BRIGHT_RED")"
  echo "$message" >&2
  echo "$message" &>> "$LOG_FILE"
}

##############################################################
# Provides stylized decorations for fatal/unrecoverable errors
# Globals:
#   TEXT_BRIGHT_CYAN
#   BOLD
# Arguments:
#   The fatal error message
# Outputs:
#   Formatted error message
##############################################################
function fmtr::fatal() {
  local text="$1"
  local message="$(fmtr::format_text \
    '\n  ' "[X] ${text}" '' "$TEXT_RED" "$BOLD")"
  echo "$message" >&2
  echo "$message" &>> "$LOG_FILE"
}

#################################################
# Draws a beautiful box around a provided string
# Arguments:
#   String to format
# Outputs:
#   Writes text box to STDOUT in multiple strings
#################################################
function fmtr::box_text() {
  local text="$1"
  local width=$((${#text} + 2))

  # top decoration
  printf "\n  ╔"
  printf "═%.0s" $(seq 1 $width)
  printf "╗\n"

  # pastes text into middle
  printf "  ║ %s ║\n" "$text"

  # bottom decoration
  printf "  ╚"
  printf "═%.0s" $(seq 1 $width)
  printf "╝\n"
}
