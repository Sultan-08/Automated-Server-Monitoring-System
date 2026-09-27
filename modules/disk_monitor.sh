#!/bin/bash

# ============================================================
# Automated Server Monitoring & Alert System
# Disk Monitoring Module
# ============================================================
#
# Purpose:
#   Monitors disk usage of the root filesystem (/).
#
# This module:
#   - Loads configuration
#   - Loads the logging module
#   - Loads the email alert module
#   - Gets root filesystem usage using df
#   - Extracts the usage percentage using awk
#   - Removes the % character using sed
#   - Compares usage with DISK_THRESHOLD
#   - Logs normal disk usage
#   - Sends an email alert when the threshold is exceeded
#
# This module monitors ONLY:
#   /
#
# It does not monitor CPU, memory, services, or network usage.
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
# Filesystem to monitor
# ------------------------------------------------------------

FILESYSTEM="/"


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
# Validate DISK_THRESHOLD
# ------------------------------------------------------------

if [[ -z "${DISK_THRESHOLD:-}" ]]; then
    echo "ERROR: DISK_THRESHOLD is not configured."

    return 1 2>/dev/null || exit 1
fi


if ! [[ "$DISK_THRESHOLD" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "ERROR: DISK_THRESHOLD must be a numeric value."

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
# monitor_disk()
# ------------------------------------------------------------
#
# Monitors disk usage of the root filesystem.
#
# Usage:
#   monitor_disk
#
# ------------------------------------------------------------

monitor_disk() {

    local disk_usage
    local df_output


    # --------------------------------------------------------
    # Check whether df is available
    # --------------------------------------------------------

    if ! command -v df >/dev/null 2>&1; then

        echo "ERROR: 'df' command is not available." >&2

        log_message "Disk Monitoring Error: df command not found"

        return 1
    fi


    # --------------------------------------------------------
    # Check whether awk is available
    # --------------------------------------------------------

    if ! command -v awk >/dev/null 2>&1; then

        echo "ERROR: 'awk' command is not available." >&2

        log_message "Disk Monitoring Error: awk command not found"

        return 1
    fi


    # --------------------------------------------------------
    # Check whether sed is available
    # --------------------------------------------------------

    if ! command -v sed >/dev/null 2>&1; then

        echo "ERROR: 'sed' command is not available." >&2

        log_message "Disk Monitoring Error: sed command not found"

        return 1
    fi


    # --------------------------------------------------------
    # Obtain root filesystem information
    # --------------------------------------------------------

    df_output="$(df -P "$FILESYSTEM" 2>/dev/null)"


    # --------------------------------------------------------
    # Check whether df returned information
    # --------------------------------------------------------

    if [[ -z "$df_output" ]]; then

        echo "ERROR: Unable to obtain disk information for $FILESYSTEM." >&2

        log_message "Disk Monitoring Error: Unable to obtain disk information for $FILESYSTEM"

        return 1
    fi


    # --------------------------------------------------------
    # Extract disk usage percentage
    # --------------------------------------------------------
    #
    # Example:
    #
    # df -P /
    #
    # Filesystem ... Use% Mounted on
    # /dev/...    ... 44%  /
    #
    # awk extracts the fifth field:
    #
    # 44%
    #
    # sed removes the % character:
    #
    # 44
    #
    # --------------------------------------------------------

    disk_usage="$(
        printf '%s\n' "$df_output" |
        awk 'NR == 2 {print $5}' |
        sed 's/%//'
    )"


    # --------------------------------------------------------
    # Check whether disk usage was obtained
    # --------------------------------------------------------

    if [[ -z "$disk_usage" ]]; then

        echo "ERROR: Unable to determine disk usage for $FILESYSTEM." >&2

        log_message "Disk Monitoring Error: Unable to determine disk usage for $FILESYSTEM"

        return 1
    fi


    # --------------------------------------------------------
    # Validate disk usage
    # --------------------------------------------------------

    if ! [[ "$disk_usage" =~ ^[0-9]+$ ]]; then

        echo "ERROR: Invalid disk usage value: $disk_usage" >&2

        log_message "Disk Monitoring Error: Invalid disk usage value: $disk_usage"

        return 1
    fi


    # --------------------------------------------------------
    # Validate disk usage range
    # --------------------------------------------------------

    if (( disk_usage < 0 || disk_usage > 100 )); then

        echo "ERROR: Disk usage value is outside valid range: $disk_usage%" >&2

        log_message "Disk Monitoring Error: Invalid disk usage range: $disk_usage%"

        return 1
    fi


    # --------------------------------------------------------
    # Compare disk usage with configured threshold
    # --------------------------------------------------------

    if awk -v usage="$disk_usage" -v threshold="$DISK_THRESHOLD" \
        'BEGIN { exit !(usage > threshold) }'
    then

        # ----------------------------------------------------
        # Disk threshold exceeded
        # ----------------------------------------------------

        local alert_message

        alert_message="High Disk Usage Detected: ${disk_usage}% on ${FILESYSTEM} (Threshold: ${DISK_THRESHOLD}%)"


        echo "DISK ALERT"
        echo "Filesystem : $FILESYSTEM"
        echo "Disk Usage : ${disk_usage}%"
        echo "Threshold  : ${DISK_THRESHOLD}%"


        # ----------------------------------------------------
        # Log alert
        # ----------------------------------------------------

        log_message "$alert_message"


        # ----------------------------------------------------
        # Send email alert
        # ----------------------------------------------------

        if ! send_alert "$alert_message"; then

            echo "WARNING: Disk alert email could not be sent." >&2

            return 1
        fi


        return 0


    else

        # ----------------------------------------------------
        # Disk usage is within threshold
        # ----------------------------------------------------

        local normal_message

        normal_message="Disk Usage: ${disk_usage}% on ${FILESYSTEM} (Threshold: ${DISK_THRESHOLD}%)"


        echo "DISK OK"
        echo "Filesystem : $FILESYSTEM"
        echo "Disk Usage : ${disk_usage}%"
        echo "Threshold  : ${DISK_THRESHOLD}%"


        # ----------------------------------------------------
        # Log normal usage
        # ----------------------------------------------------

        log_message "$normal_message"


        return 0
    fi
}


# ------------------------------------------------------------
# Run disk monitoring
# ------------------------------------------------------------

monitor_disk
