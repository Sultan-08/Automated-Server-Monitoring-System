#!/bin/bash

# ============================================================
# Automated Server Monitoring & Alert System
# Email Alert Module
# ============================================================
#
# Purpose:
#   Provides a reusable send_alert() function for sending
#   server monitoring alerts by email.
#
# This module:
#   - Loads the administrator email from configuration
#   - Gets the hostname
#   - Gets the current date/time
#   - Creates an email subject and body
#   - Sends the email using the Linux mail command
#   - Logs alert activity to logs/alerts.log
#
# This module does not perform CPU, memory, disk, service,
# or network monitoring.
# ============================================================


# ------------------------------------------------------------
# Determine the project root directory
# ------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"


# ------------------------------------------------------------
# Configuration and log paths
# ------------------------------------------------------------

CONFIG_FILE="$PROJECT_ROOT/config/threshold.conf"

ALERT_LOG_DIR="$PROJECT_ROOT/logs"
ALERT_LOG_FILE="$ALERT_LOG_DIR/alerts.log"


# ------------------------------------------------------------
# Load configuration
# ------------------------------------------------------------

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Configuration file not found: $CONFIG_FILE" >&2
    return 1 2>/dev/null || exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"


# ------------------------------------------------------------
# send_alert()
# ------------------------------------------------------------
#
# Sends an alert email to the administrator.
#
# Usage:
#   send_alert "High CPU Usage Detected: 92%"
#
# ------------------------------------------------------------

send_alert() {

    # Check that an alert message was provided.
    if [[ $# -eq 0 ]]; then
        echo "ERROR: send_alert requires an alert message." >&2
        return 1
    fi


    # --------------------------------------------------------
    # Check that ADMIN_EMAIL is configured.
    # --------------------------------------------------------

    if [[ -z "${ADMIN_EMAIL:-}" ]]; then
        echo "ERROR: ADMIN_EMAIL is not configured." >&2
        return 1
    fi


    # --------------------------------------------------------
    # Get server hostname.
    # --------------------------------------------------------

    local hostname
    hostname="$(hostname)"


    # --------------------------------------------------------
    # Get current date and time.
    # --------------------------------------------------------

    local current_datetime
    current_datetime="$(date '+%Y-%m-%d %H:%M:%S')"


    # --------------------------------------------------------
    # Store the alert message.
    # --------------------------------------------------------

    local alert_message="$*"


    # --------------------------------------------------------
    # Create email subject.
    # --------------------------------------------------------

    local subject
    subject="[Server Alert] $hostname - Monitoring Alert"


    # --------------------------------------------------------
    # Create email body.
    # --------------------------------------------------------

    local email_body
    email_body=$(cat <<EOF
Automated Server Monitoring Alert
=================================

Server       : $hostname
Date & Time  : $current_datetime

Alert:
$alert_message

Please investigate the server.

---------------------------------
Automated Server Monitoring System
EOF
)


    # --------------------------------------------------------
    # Create the alert log directory if necessary.
    # --------------------------------------------------------

    if ! mkdir -p "$ALERT_LOG_DIR"; then
        echo "ERROR: Unable to create alert log directory: $ALERT_LOG_DIR" >&2
        return 1
    fi


    # --------------------------------------------------------
    # Create alerts.log if necessary.
    # --------------------------------------------------------

    if ! touch "$ALERT_LOG_FILE"; then
        echo "ERROR: Unable to create alert log file: $ALERT_LOG_FILE" >&2
        return 1
    fi


    # --------------------------------------------------------
    # Log the alert.
    # --------------------------------------------------------

    printf '[%s] Alert: %s\n' \
        "$current_datetime" \
        "$alert_message" >> "$ALERT_LOG_FILE"


    # --------------------------------------------------------
    # Check that the mail command exists.
    # --------------------------------------------------------

    if ! command -v mail >/dev/null 2>&1; then
        echo "ERROR: 'mail' command is not installed or not available." >&2
        printf '[%s] Email sending failed: mail command not found\n' \
            "$current_datetime" >> "$ALERT_LOG_FILE"
        return 1
    fi


    # --------------------------------------------------------
    # Send the email.
    # --------------------------------------------------------

    if printf '%s\n' "$email_body" | mail -s "$subject" "$ADMIN_EMAIL"; then

        printf '[%s] Email alert sent to %s\n' \
            "$current_datetime" \
            "$ADMIN_EMAIL" >> "$ALERT_LOG_FILE"

        echo "ALERT EMAIL SENT"
        echo "Recipient : $ADMIN_EMAIL"
        echo "Subject   : $subject"

        return 0

    else

        printf '[%s] Email sending failed for %s\n' \
            "$current_datetime" \
            "$ADMIN_EMAIL" >> "$ALERT_LOG_FILE"

        echo "ERROR: Failed to send alert email to $ADMIN_EMAIL" >&2
        echo "Check Postfix status and /var/log/mail.log." >&2

        return 1
    fi
}
