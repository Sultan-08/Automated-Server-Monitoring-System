#!/bin/bash

# ============================================================
# Automated Server Monitoring & Alert System
# Service Monitoring Module
# ============================================================
#
# Purpose:
#   Monitors configured Linux services using systemctl.
#
# This module:
#   - Loads configuration
#   - Reads SERVICES from threshold.conf
#   - Checks every configured service
#   - Logs running/stopped status
#   - Sends an email when a service is down
#   - Attempts an automatic restart
#   - Verifies the restart
#   - Logs restart success/failure
#   - Sends another email if restart fails
#
# Security:
#   - Service names are validated before being used.
#   - Restart is performed through sudo -n.
#   - sudo -n prevents the monitoring script from waiting
#     for an interactive password.
#
# This module does not monitor CPU, memory, disk, or network.
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
# Validate SERVICES configuration
# ------------------------------------------------------------

if [[ -z "${SERVICES:-}" ]]; then

    echo "ERROR: SERVICES is not configured."

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
# Check required commands
# ------------------------------------------------------------

if ! command -v systemctl >/dev/null 2>&1; then

    echo "ERROR: 'systemctl' command is not available." >&2

    log_message "Service Monitoring Error: systemctl command not found"

    return 1 2>/dev/null || exit 1
fi


if ! command -v sudo >/dev/null 2>&1; then

    echo "ERROR: 'sudo' command is not available." >&2

    log_message "Service Monitoring Error: sudo command not found"

    return 1 2>/dev/null || exit 1
fi


# ------------------------------------------------------------
# monitor_service()
# ------------------------------------------------------------
#
# Checks one configured service.
#
# Usage:
#   monitor_service "ssh"
#
# ------------------------------------------------------------

monitor_service() {

    local service="$1"
    local status
    local alert_message


    # --------------------------------------------------------
    # Validate service name
    # --------------------------------------------------------
    #
    # This prevents arbitrary shell characters from entering
    # the service command.
    #
    # Allowed:
    #   letters
    #   numbers
    #   underscore
    #   dot
    #   @
    #   hyphen
    #
    # --------------------------------------------------------

    if [[ -z "$service" ]]; then

        echo "ERROR: Empty service name." >&2

        log_message "Service Monitoring Error: Empty service name"

        return 1
    fi


    if ! [[ "$service" =~ ^[a-zA-Z0-9_.@-]+$ ]]; then

        echo "ERROR: Invalid service name: $service" >&2

        log_message "Service Monitoring Error: Invalid service name: $service"

        return 1
    fi


    # --------------------------------------------------------
    # Check current service status
    # --------------------------------------------------------

    status="$(systemctl is-active "$service" 2>/dev/null)"


    # --------------------------------------------------------
    # Service is running
    # --------------------------------------------------------

    if [[ "$status" == "active" ]]; then

        echo "SERVICE OK"
        echo "Service : $service"
        echo "Status  : active"

        log_message "Service Status: $service is active"

        return 0
    fi


    # --------------------------------------------------------
    # Service is not running
    # --------------------------------------------------------

    echo "SERVICE DOWN"
    echo "Service : $service"
    echo "Status  : ${status:-unknown}"


    # --------------------------------------------------------
    # Log service failure
    # --------------------------------------------------------

    log_message "Service Failure: $service is not active (status: ${status:-unknown})"


    # --------------------------------------------------------
    # Send initial service-down alert
    # --------------------------------------------------------

    alert_message="Service Down: $service is not active (status: ${status:-unknown})"

    if ! send_alert "$alert_message"; then

        echo "WARNING: Initial service-down alert email could not be sent." >&2
    fi


    # --------------------------------------------------------
    # Attempt automatic restart
    # --------------------------------------------------------
    #
    # sudo -n:
    #   - Uses sudo without prompting for a password.
    #   - Prevents the monitoring script from hanging.
    #
    # The sudoers configuration should allow ONLY the required
    # systemctl restart command for the configured service.
    #
    # --------------------------------------------------------

    echo "Attempting restart of service: $service"

    if sudo -n systemctl restart "$service" 2>/dev/null; then

        # ----------------------------------------------------
        # Give systemd a moment to update service state.
        # ----------------------------------------------------

        sleep 1

        status="$(systemctl is-active "$service" 2>/dev/null)"


        # ----------------------------------------------------
        # Restart succeeded
        # ----------------------------------------------------

        if [[ "$status" == "active" ]]; then

            echo "RESTART SUCCESS"
            echo "Service : $service"
            echo "Status  : active"

            log_message "Service Restart Success: $service is active after restart"

            return 0
        fi
    fi


    # --------------------------------------------------------
    # Restart failed
    # --------------------------------------------------------

    echo "RESTART FAILED"
    echo "Service : $service"
    echo "Status  : ${status:-unknown}"

    log_message "Service Restart Failure: $service could not be restored"


    # --------------------------------------------------------
    # Send second failure alert
    # --------------------------------------------------------

    alert_message="Service Restart Failed: $service could not be restored. Current status: ${status:-unknown}"

    if ! send_alert "$alert_message"; then

        echo "WARNING: Service restart failure email could not be sent." >&2
    fi


    return 1
}


# ------------------------------------------------------------
# monitor_services()
# ------------------------------------------------------------
#
# Checks every service listed in SERVICES.
#
# ------------------------------------------------------------

monitor_services() {

    local service
    local overall_status=0


    echo "=========================================="
    echo " Service Monitoring"
    echo "=========================================="


    for service in $SERVICES; do

        echo
        echo "Checking service: $service"

        if ! monitor_service "$service"; then

            overall_status=1
        fi

    done


    echo
    echo "=========================================="
    echo " Service Monitoring Complete"
    echo "=========================================="


    return "$overall_status"
}


# ------------------------------------------------------------
# Run service monitoring
# ------------------------------------------------------------

monitor_services
