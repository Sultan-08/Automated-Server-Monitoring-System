#!/bin/bash

# ============================================================
# Automated Server Monitoring & Alert System
# CPU Monitoring Module
# ============================================================
#
# Purpose:
#   Monitors current CPU usage and compares it with the
#   configured CPU_THRESHOLD value.
#
# This module:
#   - Loads configuration
#   - Loads the logging module
#   - Loads the email alert module
#   - Gets CPU usage using top
#   - Calculates CPU usage from CPU idle percentage
#   - Logs normal CPU usage
#   - Sends an alert when CPU usage exceeds the threshold
#
# This module does not monitor memory, disk, services,
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
# Validate CPU_THRESHOLD
# ------------------------------------------------------------

if [[ -z "${CPU_THRESHOLD:-}" ]]; then
    echo "ERROR: CPU_THRESHOLD is not configured."
    return 1 2>/dev/null || exit 1
fi

if ! [[ "$CPU_THRESHOLD" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "ERROR: CPU_THRESHOLD must be a numeric value."
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
# monitor_cpu()
# ------------------------------------------------------------
#
# Gets the current CPU usage and compares it against
# CPU_THRESHOLD.
#
# Usage:
#   monitor_cpu
#
# ------------------------------------------------------------

monitor_cpu() {

    local cpu_idle
    local cpu_usage


    # --------------------------------------------------------
    # Check whether top is available
    # --------------------------------------------------------

    if ! command -v top >/dev/null 2>&1; then

        echo "ERROR: 'top' command is not available." >&2

        log_message "CPU Monitoring Error: top command not found"

        return 1
    fi


    # --------------------------------------------------------
    # Obtain CPU idle percentage
    # --------------------------------------------------------
    #
    # Example top output:
    #
    # %Cpu(s): 12.5 us, 3.2 sy, 0.0 ni, 83.8 id, ...
    #
    # awk searches for the field ending with "id,"
    # and removes the "id," text.
    #
    # --------------------------------------------------------

    cpu_idle="$(
    top -bn1 2>/dev/null |
    awk '
        /Cpu/ {
            for (i = 1; i <= NF; i++) {
                if ($i == "id," || $i == "id") {
                    value = $(i - 1)
                    gsub(",", "", value)

                    if (value ~ /^[0-9]+([.][0-9]+)?$/) {
                        print value
                        exit
                      }
                  }
              }
          }
       '
    )"


    # --------------------------------------------------------
    # Check whether CPU idle value was obtained
    # --------------------------------------------------------
    if [[ -z "$cpu_idle" ]]; then

        echo "ERROR: Unable to obtain CPU usage from top." >&2

        log_message "CPU Monitoring Error: Unable to obtain CPU idle percentage"

        return 1
    fi


    # --------------------------------------------------------
    # Validate CPU idle value
    # --------------------------------------------------------

    if ! [[ "$cpu_idle" =~ ^[0-9]+([.][0-9]+)?$ ]]; then

        echo "ERROR: Invalid CPU idle value received: $cpu_idle" >&2

        log_message "CPU Monitoring Error: Invalid CPU idle value: $cpu_idle"

        return 1
    fi


    # --------------------------------------------------------
    # Calculate CPU usage
    # --------------------------------------------------------
    #
    # CPU Usage = 100 - CPU Idle
    #
    # awk is used here because CPU values can contain
    # decimal numbers.
    #
    # --------------------------------------------------------

    cpu_usage="$(
        awk -v idle="$cpu_idle" 'BEGIN {
            usage = 100 - idle

            if (usage < 0)
                usage = 0

            printf "%.2f", usage
        }'
    )"


    # --------------------------------------------------------
    # Compare CPU usage with configured threshold
    # --------------------------------------------------------

    if awk -v usage="$cpu_usage" -v threshold="$CPU_THRESHOLD" \
        'BEGIN { exit !(usage > threshold) }'
    then

        # ----------------------------------------------------
        # CPU threshold exceeded
        # ----------------------------------------------------

        local alert_message

        alert_message="High CPU Usage Detected: ${cpu_usage}% (Threshold: ${CPU_THRESHOLD}%)"

        echo "CPU ALERT"
        echo "CPU Usage : ${cpu_usage}%"
        echo "Threshold : ${CPU_THRESHOLD}%"

        log_message "$alert_message"

        # send_alert() also records the alert in alerts.log.
        if ! send_alert "$alert_message"; then
            echo "WARNING: CPU alert email could not be sent." >&2
            return 1
        fi

        return 0

    else

        # ----------------------------------------------------
        # CPU usage is within the configured threshold
        # ----------------------------------------------------

        local normal_message

        normal_message="CPU Usage: ${cpu_usage}% (Threshold: ${CPU_THRESHOLD}%)"

        echo "CPU OK"
        echo "CPU Usage : ${cpu_usage}%"
        echo "Threshold : ${CPU_THRESHOLD}%"

        log_message "$normal_message"

        return 0
    fi
}


# ------------------------------------------------------------
# Run CPU monitoring
# ------------------------------------------------------------

monitor_cpu
