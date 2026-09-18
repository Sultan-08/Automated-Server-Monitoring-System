#!/bin/bash

# Log file path
LOG_FILE="logs/system.log"

# Function to write logs with timestamp
log_message() {
    MESSAGE=$1

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $MESSAGE" >> "$LOG_FILE"
}
