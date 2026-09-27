#!/bin/bash

# ============================================================
# Automated Server Monitoring & Alert System
# Logging Module
# ============================================================
#
# Purpose:
#   Provides a reusable log_message() function for writing
#   timestamped messages to logs/system.log.
#
# This module does not perform monitoring or send alerts.
# ============================================================


# ------------------------------------------------------------
# Determine the project root directory
# ------------------------------------------------------------
# BASH_SOURCE[0] contains the path of this script.
# dirname gets the modules directory.
# The second dirname gets the project root directory.
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"


# ------------------------------------------------------------
# Log directory and log file
# ------------------------------------------------------------
LOG_DIR="$PROJECT_ROOT/logs"
LOG_FILE="$LOG_DIR/system.log"


# ------------------------------------------------------------
# log_message()
# ------------------------------------------------------------
# Writes a timestamped message to logs/system.log.
#
# Usage:
#   log_message "CPU Usage: 45%"
#
# Output:
#   [2026-09-21 16:45:00] CPU Usage: 45%
# ------------------------------------------------------------
log_message() {

    # Create the log directory if it does not exist.
    if ! mkdir -p "$LOG_DIR"; then
        echo "ERROR: Unable to create log directory: $LOG_DIR" >&2
        return 1
    fi

    # Create the log file if it does not exist.
    if ! touch "$LOG_FILE"; then
        echo "ERROR: Unable to create log file: $LOG_FILE" >&2
        return 1
    fi

    # Generate the current date and time.
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    # Write the timestamped message to the log file.
    printf '[%s] %s\n' "$timestamp" "$*" >> "$LOG_FILE"
}
