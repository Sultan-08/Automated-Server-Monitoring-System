#!/bin/bash

# ============================================================
# Automated Server Monitoring & Alert System
# Network Monitoring Module
# ============================================================
#
# Purpose:
#   Checks whether the server has network connectivity by
#   sending a ping to a reliable public IP address.
#
# This module:
#   - Tests connectivity using ping
#   - Logs successful connectivity
#   - Logs connectivity failures
#   - Sends an email alert when connectivity fails
#   - Handles ping failures safely
#
# This module does not configure or modify the network.
# ============================================================


# ------------------------------------------------------------
# Determine project directories
# ------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"


# ------------------------------------------------------------
# Module paths
# ------------------------------------------------------------
LOGGER_FILE="$PROJECT_ROOT/modules/logger.sh"
ALERT_FILE="$PROJECT_ROOT/modules/alert.sh"


# ------------------------------------------------------------
# Connectivity target
# ------------------------------------------------------------
# Google Public DNS IPv4 address.
PING_TARGET="8.8.8.8"

# ------------------------------------------------------------
# Verify logger module
# ------------------------------------------------------------
if [[ ! -f "$LOGGER_FILE" ]]; then
    echo "ERROR: Logger module not found:"
    echo "$LOGGER_FILE"
    exit 1
fi


# Load the reusable logging function.
# shellcheck source=/dev/null
source "$LOGGER_FILE"


# ------------------------------------------------------------
# Verify alert module
# ------------------------------------------------------------
if [[ ! -f "$ALERT_FILE" ]]; then
    echo "ERROR: Alert module not found:"
    echo "$ALERT_FILE"
    exit 1
fi


# Load the reusable email alert function.
# shellcheck source=/dev/null
source "$ALERT_FILE"


# ------------------------------------------------------------
# Verify ping command
# ------------------------------------------------------------
if ! command -v ping >/dev/null 2>&1; then

    echo "ERROR: 'ping' command is not available." >&2

    log_message "Network Monitoring Error: ping command not found"

    exit 1
fi


# ------------------------------------------------------------
# Test network connectivity
# ------------------------------------------------------------
#
# -c 1
#   Send only one ping packet.
#
# -W 2
#   Wait a maximum of 2 seconds for a response.
#
# Output is redirected to /dev/null because we only need
# the success/failure result.
#
if ping -c 1 -W 2 "$PING_TARGET" >/dev/null 2>&1; then

    # --------------------------------------------------------
    # Connectivity successful
    # --------------------------------------------------------

    echo "Network connectivity: OK"

    log_message "Network Connectivity: OK - $PING_TARGET is reachable"

else

    # --------------------------------------------------------
    # Connectivity failed
    # --------------------------------------------------------

    echo "Network connectivity: FAILED"

    log_message "Network Connectivity Failure: $PING_TARGET is unreachable"

    alert_message="Network Connectivity Failure: Unable to reach $PING_TARGET"

    # --------------------------------------------------------
    # Send email alert
    # --------------------------------------------------------
    #
    # If email sending fails, do not terminate the monitoring
    # system. The network failure has already been logged.
    #
    if ! send_alert "$alert_message"; then
        echo "WARNING: Network failure alert email could not be sent." >&2

        log_message "Network Alert Error: Failed to send connectivity alert email"
    fi

fi


# ------------------------------------------------------------
# Finish safely
# ------------------------------------------------------------
#
# A failed ping is treated as a monitoring event, not as a
# script crash.
#
exit 0
