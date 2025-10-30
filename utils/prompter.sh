#!/usr/bin/env bash

[[ -z "$LOG_FILE" ]] && exit 1

#############################################################################
# Ask the user a yes or no question and return the answer
# Arguments:
#   $@: The question to ask
# Returns:
#   0 if yes, 1 if no
#############################################################################
prmt::yes_or_no() {
  local question="$*"
  local answer

  while true; do
    read -rp "$(echo -e "${question} [y/n]: ")" answer
    echo "$answer" >> "$LOG_FILE"
    case "${answer,,}" in  # lowercase comparison
      y*) echo; return 0 ;;
      n*) echo; return 1 ;;
      *) echo -e "\n  [!] Please answer y/n" ;;
    esac
  done
}

#############################################################################
# Prompt the user and capture a single keypress
# Arguments:
#   $@: Prompt message
# Returns:
#   Echoes the captured key
#############################################################################
prmt::quick_prompt() {
  local prompt="$*"
  local response

  read -n1 -srp "$(echo -e "$prompt")" response
  echo "$response"
  echo "$response" >> "$LOG_FILE"
}

#############################################################################
# Stylized prompt for user questions
# Globals:
#   TEXT_BLACK
#   BACK_BRIGHT_GREEN
# Arguments:
#   $1: Question text
# Outputs:
#   Stylized message to STDOUT and log file
#############################################################################
fmtr::ask() {
  local text="$1"
  local message

  message="$(fmtr::format_text '\n  ' "[?]" " ${text}" "$TEXT_BLACK" "$BACK_BRIGHT_GREEN")"
  echo "$message" | tee -a "$LOG_FILE"
}
