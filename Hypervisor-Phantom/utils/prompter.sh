#!/usr/bin/env bash
#
# A Library to create prompts to the user.
# Yes and no questions can be asked in a format compatible with if statements
# for quick and clean prompts. The prmt::quick_prompt function allows for a
# standardized way of letting the user make a choice in the code because it
# returns the answer in STDOUT.
#

if [[ -z "$LOG_FILE" ]]; then
  exit 1
fi

#############################################################################
# Asks the user a yes or no question and returns the answer for if statements
# Arguments:
#   $*: The question to ask which can consist of multiple strings
# Outputs:
#   Writes the question with formatting (if present) to STDOUT
# Returns:
#   0 if the answer was yes, 1 if they answered no
#############################################################################
function prmt::yes_or_no() {
  local text="$*"
  while true; do
    read -rp "$(echo -e "${text} [y/n]: ")" answer
    echo "$answer" &>> "$LOG_FILE" # logging
    case "$answer" in
      [Yy]*) echo ""; return 0 ;; # Yes
      [Nn]*) echo ""; return 1 ;; # No
      *) echo -e "\n  [!] Please answer y/n" ;;
    esac
  done
}

###############################################################
# Prompts the user and accepts input after 1 character.
# Then returns answer.
# Can be used for "Press any button to continue" screens
# Arguments:
#   $*: All arguments are used for `read`` prompt as one string
# Outputs:
#   Prompt provided and then the answer to STDOUT
###############################################################
function prmt::quick_prompt() {
  local text="$*"
  read -n1 -srp "$(echo -e "$text")" response
  echo "$response"

  echo "$response" &>> "$LOG_FILE" # logging
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
