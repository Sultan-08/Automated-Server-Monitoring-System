#!/bin/bash

# Main monitoring controller script

# Move to project directory
cd "$(dirname "$0")"

# Execute all monitoring modules
bash modules/cpu_monitor.sh
bash modules/memory_monitor.sh
bash modules/disk_monitor.sh
bash modules/service_monitor.sh
bash modules/network_monitor.sh
