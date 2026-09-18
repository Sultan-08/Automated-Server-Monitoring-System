#!/bin/bash

# Load configuration and modules
source config/threshold.conf
source modules/alert.sh
source modules/logger.sh

# Loop through services
for SERVICE in $SERVICES

do

    # Check service status
    systemctl is-active --quiet "$SERVICE"

    # If service is inactive
    if [ $? -ne 0 ]
    then
        send_alert "$SERVICE service is DOWN"

        # Restart the service automatically
        systemctl restart "$SERVICE"

        # Log restart event
        log_message "$SERVICE restarted automatically"
    else
        log_message "$SERVICE service is running"
    fi

done
