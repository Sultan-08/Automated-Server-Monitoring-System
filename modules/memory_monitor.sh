#!/bin/bash

# Load configuration and modules
source config/threshold.conf
source modules/alert.sh
source modules/logger.sh

# Get memory usage percentage
MEMORY_USAGE=$(free | grep Mem | awk '{print ($3/$2) * 100.0}')

# Remove decimal value
MEMORY_USAGE_INT=${MEMORY_USAGE%.*}

# Log memory usage
log_message "Memory Usage: $MEMORY_USAGE_INT%"

# Check threshold
if [ "$MEMORY_USAGE_INT" -gt "$MEMORY_THRESHOLD" ]
then
    send_alert "High Memory Usage Detected: $MEMORY_USAGE_INT%"
fi
