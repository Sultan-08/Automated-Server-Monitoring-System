#!/bin/bash

# ============================================================
# Automated Server Monitoring & Alert System
# Main Monitoring Controller
# ============================================================
#
# Purpose:
#   Central controller for the server monitoring system.
#
# This script:
#   - Determines the project directory dynamically
#   - Loads the monitoring configuration
#   - Verifies required directories and files
#   - Verifies required commands
#   - Verifies log directory writability
#   - Executes all monitoring modules
#   - Continues if an individual monitoring module fails
#   - Displays a final monitoring summary
#
# ============================================================


# ------------------------------------------------------------
# Determine the project directory safely
# ------------------------------------------------------------
#
# BASH_SOURCE[0] contains the path of this script.
#
# dirname finds the directory containing monitor.sh.
#
# cd + pwd converts it into an absolute project path.
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"


# ------------------------------------------------------------
# Define important project paths
# ------------------------------------------------------------
CONFIG_DIR="$PROJECT_ROOT/config"
MODULES_DIR="$PROJECT_ROOT/modules"
LOGS_DIR="$PROJECT_ROOT/logs"

CONFIG_FILE="$CONFIG_DIR/threshold.conf"

CPU_MODULE="$MODULES_DIR/cpu_monitor.sh"
MEMORY_MODULE="$MODULES_DIR/memory_monitor.sh"
DISK_MODULE="$MODULES_DIR/disk_monitor.sh"
SERVICE_MODULE="$MODULES_DIR/service_monitor.sh"
NETWORK_MODULE="$MODULES_DIR/network_monitor.sh"


# ------------------------------------------------------------
# Display controller header
# ------------------------------------------------------------
echo "=========================================="
echo " Automated Server Monitoring System"
echo "=========================================="
echo
echo "Project Directory:"
echo "$PROJECT_ROOT"
echo


# ------------------------------------------------------------
# Verify required directories
# ------------------------------------------------------------
required_directories=(
    "$CONFIG_DIR"
    "$MODULES_DIR"
    "$LOGS_DIR"
)

for directory in "${required_directories[@]}"; do

    if [[ ! -d "$directory" ]]; then

        echo "ERROR: Required directory not found:"
        echo "$directory"
        exit 1

    fi

done


# ------------------------------------------------------------
# Verify configuration file
# ------------------------------------------------------------
if [[ ! -f "$CONFIG_FILE" ]]; then

    echo "ERROR: Configuration file not found:"
    echo "$CONFIG_FILE"
    exit 1

fi


# ------------------------------------------------------------
# Load configuration
# ------------------------------------------------------------
#
# The configuration contains values such as:
#
# CPU_THRESHOLD
# MEMORY_THRESHOLD
# DISK_THRESHOLD
# ADMIN_EMAIL
# SERVICES
#
# shellcheck source=/dev/null
source "$CONFIG_FILE"


# ------------------------------------------------------------
# Verify required configuration values
# ------------------------------------------------------------

configuration_valid=true


if [[ -z "${CPU_THRESHOLD:-}" ]]; then
    echo "ERROR: CPU_THRESHOLD is not configured."
    configuration_valid=false
fi


if [[ -z "${MEMORY_THRESHOLD:-}" ]]; then
    echo "ERROR: MEMORY_THRESHOLD is not configured."
    configuration_valid=false
fi


if [[ -z "${DISK_THRESHOLD:-}" ]]; then
    echo "ERROR: DISK_THRESHOLD is not configured."
    configuration_valid=false
fi


if [[ -z "${ADMIN_EMAIL:-}" ]]; then
    echo "ERROR: ADMIN_EMAIL is not configured."
    configuration_valid=false
fi


if [[ -z "${SERVICES:-}" ]]; then
    echo "ERROR: SERVICES is not configured."
    configuration_valid=false
fi


if [[ "$configuration_valid" != true ]]; then
    echo
    echo "ERROR: Configuration validation failed."
    exit 1
fi


# ------------------------------------------------------------
# Verify monitoring module files
# ------------------------------------------------------------
required_modules=(
    "$CPU_MODULE"
    "$MEMORY_MODULE"
    "$DISK_MODULE"
    "$SERVICE_MODULE"
    "$NETWORK_MODULE"
)

modules_valid=true

for module in "${required_modules[@]}"; do

    if [[ ! -f "$module" ]]; then

        echo "ERROR: Required monitoring module not found:"
        echo "$module"

        modules_valid=false

    fi

done


if [[ "$modules_valid" != true ]]; then
    echo
    echo "ERROR: Required monitoring modules are missing."
    exit 1
fi


# ------------------------------------------------------------
# Verify required commands
# ------------------------------------------------------------
#
# These commands are used directly by the monitoring system
# or by the modules.
# ------------------------------------------------------------

required_commands=(
    bash
    awk
    sed
    date
    ping
    systemctl
    sudo
)

commands_valid=true

for command_name in "${required_commands[@]}"; do

    if ! command -v "$command_name" >/dev/null 2>&1; then

        echo "ERROR: Required command not found:"
        echo "$command_name"

        commands_valid=false

    fi

done


if [[ "$commands_valid" != true ]]; then
    echo
    echo "ERROR: Required command validation failed."
    exit 1
fi


# ------------------------------------------------------------
# Verify log directory is writable
# ------------------------------------------------------------
#
# The controller needs to be able to write monitoring logs.
# ------------------------------------------------------------

if [[ ! -w "$LOGS_DIR" ]]; then

    echo "ERROR: Log directory is not writable:"
    echo "$LOGS_DIR"

    exit 1

fi


# ------------------------------------------------------------
# Verify monitoring scripts are executable
# ------------------------------------------------------------
#
# If a script is not executable, the controller will attempt
# to run it through Bash instead.
#
# However, we report the permission problem so it can be fixed.
# ------------------------------------------------------------

scripts_executable=true

for module in "${required_modules[@]}"; do

    if [[ ! -x "$module" ]]; then

        echo "WARNING: Module is not executable:"
        echo "$module"

        scripts_executable=false

    fi

done


if [[ "$scripts_executable" != true ]]; then

    echo
    echo "WARNING: Some monitoring modules do not have execute permission."
    echo "The controller will execute them using Bash."
    echo

fi


# ------------------------------------------------------------
# Log controller start
# ------------------------------------------------------------
#
# We use the existing logger module.
# ------------------------------------------------------------

LOGGER_FILE="$MODULES_DIR/logger.sh"

if [[ -f "$LOGGER_FILE" ]]; then

    # shellcheck source=/dev/null
    source "$LOGGER_FILE"

    log_message "Monitoring Controller: Started"

else

    echo "WARNING: Logger module not found."
fi


# ------------------------------------------------------------
# Monitoring counters
# ------------------------------------------------------------
total_checks=0
successful_checks=0
failed_checks=0


# ------------------------------------------------------------
# Run a monitoring module
# ------------------------------------------------------------
#
# This function allows the controller to execute every module
# in the same way.
#
# If a module returns a non-zero exit status, the controller
# records the failure but continues to the next module.
# ------------------------------------------------------------

run_monitoring_module() {

    local module_name="$1"
    local module_path="$2"

    echo
    echo "------------------------------------------"
    echo "Running: $module_name"
    echo "------------------------------------------"

    total_checks=$((total_checks + 1))

    if bash "$module_path"; then

        echo "$module_name: COMPLETED"

        successful_checks=$((successful_checks + 1))

        if declare -F log_message >/dev/null 2>&1; then
            log_message "Monitoring Controller: $module_name completed successfully"
        fi

        return 0

    else

        echo "$module_name: FAILED"

        failed_checks=$((failed_checks + 1))

        if declare -F log_message >/dev/null 2>&1; then
            log_message "Monitoring Controller: $module_name failed"
        fi

        return 1

    fi
}


# ------------------------------------------------------------
# Execute monitoring modules
# ------------------------------------------------------------

run_monitoring_module "CPU Monitoring" "$CPU_MODULE"

run_monitoring_module "Memory Monitoring" "$MEMORY_MODULE"

run_monitoring_module "Disk Monitoring" "$DISK_MODULE"

run_monitoring_module "Service Monitoring" "$SERVICE_MODULE"

run_monitoring_module "Network Monitoring" "$NETWORK_MODULE"


# ------------------------------------------------------------
# Final monitoring summary
# ------------------------------------------------------------

echo
echo
echo "=========================================="
echo " Monitoring Summary"
echo "=========================================="

echo "Total Checks      : $total_checks"
echo "Successful Checks : $successful_checks"
echo "Failed Checks     : $failed_checks"

echo "=========================================="


# ------------------------------------------------------------
# Log final summary
# ------------------------------------------------------------

if declare -F log_message >/dev/null 2>&1; then

    log_message \
        "Monitoring Controller Summary: Total=$total_checks Successful=$successful_checks Failed=$failed_checks"

    log_message "Monitoring Controller: Completed"

fi


# ------------------------------------------------------------
# Controller completed
# ------------------------------------------------------------
#
# Always finish normally after attempting all checks.
#
# Individual monitoring failures are already recorded above.
# ------------------------------------------------------------

exit 0
