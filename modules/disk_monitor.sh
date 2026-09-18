#!/bin/bash

# Load configuration and modules
source config/threshold.conf
source modules/alert.sh
source modules/logger.sh

# Get disk usage percentage of root partition
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

# Log disk usage
log_message "Disk Usage: $DISK_USAGE%"

# Check threshold
if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]
then
    send_alert "High Disk Usage Detected: $DISK_USAGE%"
fi
