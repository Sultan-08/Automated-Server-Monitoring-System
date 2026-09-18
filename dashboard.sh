#!/bin/bash

while true

do

CHOICE=$(whiptail --title "Server Monitoring Dashboard" \
--menu "Choose an option" 20 60 10 \
"1" "View CPU Usage" \
"2" "View Memory Usage" \
"3" "View Disk Usage" \
"4" "View Service Status" \
"5" "View Logs" \
"6" "Exit" \
3>&1 1>&2 2>&3)

case $CHOICE in

1)
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
    whiptail --msgbox "CPU Usage: $CPU%" 10 40
    ;;

2)
    MEMORY=$(free -m)
    whiptail --msgbox "$MEMORY" 15 60
    ;;

3)
    DISK=$(df -h)
    whiptail --msgbox "$DISK" 20 70
    ;;

4)
    STATUS=$(systemctl status apache2 ssh --no-pager)
    whiptail --msgbox "$STATUS" 20 80
    ;;

5)
    LOGS=$(tail -20 logs/system.log)
    whiptail --msgbox "$LOGS" 20 80
    ;;

6)
    exit
    ;;

esac

done
