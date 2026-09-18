#!/bin/bash

# Load modules
source modules/alert.sh
source modules/logger.sh

# Ping Google DNS server
ping -c 2 8.8.8.8 > /dev/null

# Check internet connection
if [ $? -ne 0 ]
then
    send_alert "Network Connectivity Lost"
else
    log_message "Network Connectivity OK"
fi
