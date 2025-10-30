#!/usr/bin/env bash

# A library to format text in the terminal using ANSI codes.
# Provides styled functions for logs, errors, prompts, and boxed titles.

[[ -z "$LOG_FILE" ]] && exit 1

# -----------------------------------------------------------------------------
# ANSI Escape Codes - Text Styles, Colors, Backgrounds
# -----------------------------------------------------------------------------

# Reset
readonly RESET="\033[0m"

# Text styles
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

# -----------------------------------------------------------------------------
# Format text with ANSI styles
# Usage: fmtr::format_text <prefix> <highlighted_text> <suffix> <style...>
# -----------------------------------------------------------------------------
fmtr::format_text() {
  local prefix="$1"
  local text="$2"
  local suffix="$3"
  shift 3
  local styles="$*"

  echo -e "${prefix}${styles// /}${text}${RESET}${suffix}"
}

# -----------------------------------------------------------------------------
# Logging wrappers with stylized prefixes
# -----------------------------------------------------------------------------
__fmtr::styled_log() {
  local prefix="$1"
  local icon="$2"
  local color="$3"
  local stream="${4:-stdout}" # default: stdout
  shift 4
  local text="$*"

  local message
  message="$(fmtr::format_text '\n  ' "$icon" " $text" "$color")"

  if [[ "$stream" == "stderr" ]]; then
    echo "$message" >&2
    echo "$message" >> "$LOG_FILE"
  else
    echo "$message" | tee -a "$LOG_FILE"
  fi
}

fmtr::log()   { __fmtr::styled_log "LOG"   "[+]" "$TEXT_BRIGHT_GREEN" stdout "$@"; }
fmtr::info()  { __fmtr::styled_log "INFO"  "[i]" "$TEXT_BRIGHT_CYAN"  stdout "$@"; }
fmtr::warn()  { __fmtr::styled_log "WARN"  "[!]" "$TEXT_BRIGHT_YELLOW" stdout "$@"; }
fmtr::error() { __fmtr::styled_log "ERROR" "[-]" "$TEXT_BRIGHT_RED"   stderr "$@"; }
fmtr::fatal() {
  local message
  message="$(fmtr::format_text '\n  ' "[X] $*" "" "$TEXT_RED" "$TEXT_BOLD")"
  echo "$message" >&2
  echo "$message" >> "$LOG_FILE"
}

# -----------------------------------------------------------------------------
# Draws a stylized box around a given string
# -----------------------------------------------------------------------------
fmtr::box_text() {
  local text="$1"
  local width=$(( ${#text} + 2 ))

  printf "\n  ╔"
  printf '═%.0s' $(seq 1 "$width")
  printf "╗\n"

  printf "  ║ %s ║\n" "$text"

  printf "  ╚"
  printf '═%.0s' $(seq 1 "$width")
  printf "╝\n"
}
