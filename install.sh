#!/bin/bash

# Update packages
sudo apt update

# Install required packages
sudo apt install mailutils net-tools sysstat curl whiptail -y

# Give executable permissions
chmod +x monitor.sh
chmod +x dashboard.sh
chmod +x modules/*.sh

# Create cron job
(crontab -l 2>/dev/null; echo "* * * * * $(pwd)/monitor.sh") | crontab -

# Success message
echo "Installation Completed Successfully"
