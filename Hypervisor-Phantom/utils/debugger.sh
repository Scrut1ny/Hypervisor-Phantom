#!/usr/bin/env bash

log::init() {
  # Set default log path and file if not defined
  if [[ -z "$LOG_PATH" ]]; then
    readonly LOG_PATH="$(pwd)/logs"
    export LOG_PATH
  fi

  if [[ -z "$LOG_FILE" ]]; then
    readonly LOG_FILE="${LOG_PATH}/$(date +%s).log"
    export LOG_FILE
  fi

  # Create log directory and file
  if ! mkdir -p "$LOG_PATH" || ! touch "$LOG_FILE"; then
    echo "Failed to create log directory or log file." >&2
    exit 1
  fi
}

log::init

source "utils/formatter.sh"

dbg::fail() {
  fmtr::fatal "$1"
  exit 1
}
