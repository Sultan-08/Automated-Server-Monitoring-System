#!/bin/bash

# Load configuration and modules
source config/threshold.conf
source modules/alert.sh
source modules/logger.sh

# Get CPU usage percentage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')

# Remove decimal value
CPU_USAGE_INT=${CPU_USAGE%.*}

# Log CPU usage
log_message "CPU Usage: $CPU_USAGE_INT%"

# Check threshold
if [ "$CPU_USAGE_INT" -gt "$CPU_THRESHOLD" ]
then
    send_alert "High CPU Usage Detected: $CPU_USAGE_INT%"
fi
