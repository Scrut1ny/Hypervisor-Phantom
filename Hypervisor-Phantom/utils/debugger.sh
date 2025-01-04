#!/usr/bin/env bash
#
# Defines and creates the log file.
# Should be sourced at the beginning of main.
# Also don't forget to check for non-zero exit codes
# as the log file creation could fail 
#

if [[ -z "$LOG_PATH" || -z "$LOG_FILE" ]]; then

  readonly LOG_PATH="$(pwd)/logs"
  export LOG_PATH

  readonly LOG_FILE="${LOG_PATH}/$(date +%s).log"
  export LOG_FILE

  # makes sure the log file is created successfully
  if ! ( mkdir -p "$LOG_PATH" && touch "$LOG_FILE" ); then
    exit 1
  fi

fi

source "utils/formatter.sh"

function dbg::fail() {
  fmtr::fatal "$1"
  exit 1
}
