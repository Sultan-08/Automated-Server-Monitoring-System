#!/bin/bash

# ============================================================
# Automated Server Monitoring & Alert System
# Memory Monitoring Module
# ============================================================
#
# Purpose:
#   Monitors current memory usage and compares it with the
#   configured MEMORY_THRESHOLD value.
#
# This module:
#   - Loads configuration
#   - Loads the logging module
#   - Loads the email alert module
#   - Gets memory information using free
#   - Calculates memory usage percentage using awk
#   - Logs normal memory usage
#   - Sends an alert when memory usage exceeds the threshold
#
# This module does not monitor CPU, disk, services,
# or network usage.
# ============================================================


# ------------------------------------------------------------
# Determine the project root directory
# ------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"


# ------------------------------------------------------------
# Important project files
# ------------------------------------------------------------

CONFIG_FILE="$PROJECT_ROOT/config/threshold.conf"
LOGGER_FILE="$PROJECT_ROOT/modules/logger.sh"
ALERT_FILE="$PROJECT_ROOT/modules/alert.sh"


# ------------------------------------------------------------
# Check configuration file
# ------------------------------------------------------------

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Configuration file not found:"
    echo "$CONFIG_FILE"
    return 1 2>/dev/null || exit 1
fi


# ------------------------------------------------------------
# Load configuration
# ------------------------------------------------------------

# shellcheck source=/dev/null
source "$CONFIG_FILE"


# ------------------------------------------------------------
# Validate MEMORY_THRESHOLD
# ------------------------------------------------------------

if [[ -z "${MEMORY_THRESHOLD:-}" ]]; then
    echo "ERROR: MEMORY_THRESHOLD is not configured."
    return 1 2>/dev/null || exit 1
fi


if ! [[ "$MEMORY_THRESHOLD" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "ERROR: MEMORY_THRESHOLD must be a numeric value."
    return 1 2>/dev/null || exit 1
fi


# ------------------------------------------------------------
# Load logging module
# ------------------------------------------------------------

if [[ ! -f "$LOGGER_FILE" ]]; then
    echo "ERROR: Logger module not found:"
    echo "$LOGGER_FILE"
    return 1 2>/dev/null || exit 1
fi

# shellcheck source=/dev/null
source "$LOGGER_FILE"


# ------------------------------------------------------------
# Load alert module
# ------------------------------------------------------------

if [[ ! -f "$ALERT_FILE" ]]; then
    echo "ERROR: Alert module not found:"
    echo "$ALERT_FILE"
    return 1 2>/dev/null || exit 1
fi

# shellcheck source=/dev/null
source "$ALERT_FILE"


# ------------------------------------------------------------
# monitor_memory()
# ------------------------------------------------------------
#
# Gets total and used memory, calculates memory usage
# percentage, and compares it against MEMORY_THRESHOLD.
#
# Usage:
#   monitor_memory
#
# ------------------------------------------------------------

monitor_memory() {

    local memory_values
    local total_memory
    local used_memory
    local memory_usage


    # --------------------------------------------------------
    # Check whether free is available
    # --------------------------------------------------------

    if ! command -v free >/dev/null 2>&1; then

        echo "ERROR: 'free' command is not available." >&2

        log_message "Memory Monitoring Error: free command not found"

        return 1
    fi


    # --------------------------------------------------------
    # Obtain total and used memory
    # --------------------------------------------------------
    #
    # free output contains a row beginning with "Mem:".
    #
    # Example:
    #
    # Mem:  16276556  5234567  1234567 ...
    #
    # $2 = total memory
    # $3 = used memory
    #
    # --------------------------------------------------------

    memory_values="$(
        free |
        awk '/^Mem:/ {
            print $2, $3
            exit
        }'
    )"


    # --------------------------------------------------------
    # Check whether memory information was obtained
    # --------------------------------------------------------

    if [[ -z "$memory_values" ]]; then

        echo "ERROR: Unable to obtain memory information from free." >&2

        log_message "Memory Monitoring Error: Unable to obtain memory information"

        return 1
    fi


    # --------------------------------------------------------
    # Separate total and used memory
    # --------------------------------------------------------

    read -r total_memory used_memory <<< "$memory_values"


    # --------------------------------------------------------
    # Validate memory values
    # --------------------------------------------------------

    if ! [[ "$total_memory" =~ ^[0-9]+$ ]]; then

        echo "ERROR: Invalid total memory value: $total_memory" >&2

        log_message "Memory Monitoring Error: Invalid total memory value: $total_memory"

        return 1
    fi


    if ! [[ "$used_memory" =~ ^[0-9]+$ ]]; then

        echo "ERROR: Invalid used memory value: $used_memory" >&2

        log_message "Memory Monitoring Error: Invalid used memory value: $used_memory"

        return 1
    fi


    # --------------------------------------------------------
    # Make sure total memory is greater than zero
    # --------------------------------------------------------

    if [[ "$total_memory" -eq 0 ]]; then

        echo "ERROR: Total memory is zero." >&2

        log_message "Memory Monitoring Error: Total memory is zero"

        return 1
    fi


    # --------------------------------------------------------
    # Calculate memory usage percentage
    # --------------------------------------------------------
    #
    # Memory Usage % =
    #     Used Memory / Total Memory * 100
    #
    # awk is used because it supports decimal calculations.
    #
    # --------------------------------------------------------

    memory_usage="$(
        awk -v used="$used_memory" -v total="$total_memory" '
            BEGIN {
                usage = (used / total) * 100
                printf "%.2f", usage
            }
        '
    )"


    # --------------------------------------------------------
    # Compare memory usage with configured threshold
    # --------------------------------------------------------

    if awk -v usage="$memory_usage" -v threshold="$MEMORY_THRESHOLD" \
        'BEGIN { exit !(usage > threshold) }'
    then

        # ----------------------------------------------------
        # Memory threshold exceeded
        # ----------------------------------------------------

        local alert_message

        alert_message="High Memory Usage Detected: ${memory_usage}% (Threshold: ${MEMORY_THRESHOLD}%)"

        echo "MEMORY ALERT"
        echo "Memory Usage : ${memory_usage}%"
        echo "Threshold    : ${MEMORY_THRESHOLD}%"

        log_message "$alert_message"


        # ----------------------------------------------------
        # Send email alert
        # ----------------------------------------------------

        if ! send_alert "$alert_message"; then

            echo "WARNING: Memory alert email could not be sent." >&2

            return 1
        fi

        return 0

    else

        # ----------------------------------------------------
        # Memory usage is within threshold
        # ----------------------------------------------------

        local normal_message

        normal_message="Memory Usage: ${memory_usage}% (Threshold: ${MEMORY_THRESHOLD}%)"

        echo "MEMORY OK"
        echo "Memory Usage : ${memory_usage}%"
        echo "Threshold    : ${MEMORY_THRESHOLD}%"

        log_message "$normal_message"

        return 0
    fi
}


# ------------------------------------------------------------
# Run memory monitoring
# ------------------------------------------------------------

monitor_memory
