#!/bin/bash

# ============================================================
# Automated Server Monitoring & Alert System
# Interactive Dashboard
# ============================================================
#
# Purpose:
#   Provides an interactive terminal dashboard using whiptail.
#
# Dashboard options:
#   1. CPU Usage
#   2. Memory Usage
#   3. Disk Usage
#   4. Service Status
#   5. Recent System Logs
#   6. Recent Alerts
#   7. Exit
#
# This dashboard uses the existing monitoring infrastructure.
# It does not modify system configuration.
# ============================================================


# ------------------------------------------------------------
# Determine the project directory safely
# ------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"


# ------------------------------------------------------------
# Project paths
# ------------------------------------------------------------
CONFIG_FILE="$PROJECT_ROOT/config/threshold.conf"

CPU_MODULE="$PROJECT_ROOT/modules/cpu_monitor.sh"
MEMORY_MODULE="$PROJECT_ROOT/modules/memory_monitor.sh"
DISK_MODULE="$PROJECT_ROOT/modules/disk_monitor.sh"
SERVICE_MODULE="$PROJECT_ROOT/modules/service_monitor.sh"

SYSTEM_LOG="$PROJECT_ROOT/logs/system.log"
ALERT_LOG="$PROJECT_ROOT/logs/alerts.log"


# ------------------------------------------------------------
# Dashboard dimensions
# ------------------------------------------------------------
MENU_HEIGHT=18
MENU_WIDTH=70
MENU_LIST_HEIGHT=10


# ------------------------------------------------------------
# Verify whiptail
# ------------------------------------------------------------
if ! command -v whiptail >/dev/null 2>&1; then

    echo "ERROR: whiptail is not installed."
    echo
    echo "Install it using:"
    echo "sudo apt update"
    echo "sudo apt install whiptail"

    exit 1
fi


# ------------------------------------------------------------
# Verify configuration file
# ------------------------------------------------------------
if [[ ! -f "$CONFIG_FILE" ]]; then

    whiptail \
        --title "Configuration Error" \
        --msgbox \
        "Configuration file not found:

$CONFIG_FILE" \
        10 70

    exit 1
fi


# ------------------------------------------------------------
# Load configuration
# ------------------------------------------------------------
#
# shellcheck source=/dev/null
source "$CONFIG_FILE"


# ------------------------------------------------------------
# Verify required directories
# ------------------------------------------------------------
if [[ ! -d "$PROJECT_ROOT/modules" ]]; then

    whiptail \
        --title "Project Error" \
        --msgbox \
        "Modules directory was not found:

$PROJECT_ROOT/modules" \
        10 70

    exit 1
fi


if [[ ! -d "$PROJECT_ROOT/logs" ]]; then

    whiptail \
        --title "Project Error" \
        --msgbox \
        "Logs directory was not found:

$PROJECT_ROOT/logs" \
        10 70

    exit 1
fi


# ============================================================
# Helper Functions
# ============================================================


# ------------------------------------------------------------
# Show CPU usage
# ------------------------------------------------------------
show_cpu_usage() {

    local cpu_output

    cpu_output="$(bash "$CPU_MODULE" 2>&1)"

    whiptail \
        --title "CPU Usage" \
        --msgbox \
        "$cpu_output" \
        12 75
}


# ------------------------------------------------------------
# Show Memory usage
# ------------------------------------------------------------
show_memory_usage() {

    local memory_output

    memory_output="$(bash "$MEMORY_MODULE" 2>&1)"

    whiptail \
        --title "Memory Usage" \
        --msgbox \
        "$memory_output" \
        12 75
}


# ------------------------------------------------------------
# Show Disk usage
# ------------------------------------------------------------
show_disk_usage() {

    local disk_output

    disk_output="$(bash "$DISK_MODULE" 2>&1)"

    whiptail \
        --title "Disk Usage" \
        --msgbox \
        "$disk_output" \
        12 75
}


# ------------------------------------------------------------
# Show Service status
# ------------------------------------------------------------
show_service_status() {

    local service_output

    service_output="$(bash "$SERVICE_MODULE" 2>&1)"

    whiptail \
        --title "Service Status" \
        --msgbox \
        "$service_output" \
        18 75
}


# ------------------------------------------------------------
# Show recent system logs
# ------------------------------------------------------------
show_system_logs() {

    local log_output

    if [[ ! -f "$SYSTEM_LOG" ]]; then

        log_output="No system log file is available yet."

    else

        log_output="$(tail -n 15 "$SYSTEM_LOG")"

        if [[ -z "$log_output" ]]; then
            log_output="The system log is currently empty."
        fi

    fi


    whiptail \
        --title "Recent System Logs" \
        --scrolltext \
        --msgbox \
        "$log_output" \
        20 90
}


# ------------------------------------------------------------
# Show recent alerts
# ------------------------------------------------------------
show_alerts() {

    local alert_output

    if [[ ! -f "$ALERT_LOG" ]]; then

        alert_output="No alert log file is available yet."

    else

        alert_output="$(tail -n 15 "$ALERT_LOG")"

        if [[ -z "$alert_output" ]]; then
            alert_output="The alert log is currently empty."
        fi

    fi


    whiptail \
        --title "Recent Alerts" \
        --scrolltext \
        --msgbox \
        "$alert_output" \
        20 90
}


# ------------------------------------------------------------
# Main dashboard menu
# ------------------------------------------------------------
while true; do

    menu_choice="$(
        whiptail \
            --title "Server Monitoring Dashboard" \
            --menu \
            "Select an option:" \
            "$MENU_HEIGHT" \
            "$MENU_WIDTH" \
            "$MENU_LIST_HEIGHT" \
            "1" "CPU Usage" \
            "2" "Memory Usage" \
            "3" "Disk Usage" \
            "4" "Service Status" \
            "5" "Recent System Logs" \
            "6" "Recent Alerts" \
            "7" "Exit" \
            3>&1 1>&2 2>&3
    )"

    # --------------------------------------------------------
    # Handle Cancel / ESC
    # --------------------------------------------------------
    if [[ $? -ne 0 ]]; then
        clear
        echo "Dashboard closed."
        exit 0
    fi


    # --------------------------------------------------------
    # Process menu selection
    # --------------------------------------------------------
    case "$menu_choice" in

        1)
            show_cpu_usage
            ;;

        2)
            show_memory_usage
            ;;

        3)
            show_disk_usage
            ;;

        4)
            show_service_status
            ;;

        5)
            show_system_logs
            ;;

        6)
            show_alerts
            ;;

        7)
            clear
            echo "Exiting Server Monitoring Dashboard."
            exit 0
            ;;

        *)
            whiptail \
                --title "Invalid Selection" \
                --msgbox \
                "The selected option is invalid.

Please choose an option from the menu." \
                10 65
            ;;

    esac

done
