#!/bin/bash

# Load configuration
source config/threshold.conf

# Alert log file
ALERT_LOG="logs/alerts.log"

# Email Body to be written
# Function to send alerts
send_alert() {

    ALERT_MESSAGE=$1

    # Save alert in log file
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $ALERT_MESSAGE" >> "$ALERT_LOG"

    # Display alert in terminal
    echo "ALERT: $ALERT_MESSAGE"

    # Telegram notification
    echo "$ALERT_MESSAGE" | mail \
    -s "SERVER ALERT - $(hostname)" \
    "$ADMIN_EMAIL"
}
