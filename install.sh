#!/bin/bash

# ============================================================
# Automated Server Monitoring & Alert System
# Installation Script
# ============================================================
#
# Purpose:
#   Prepare the monitoring project on an Ubuntu/Linux system.
#
# This installer:
#   - Verifies the operating system
#   - Checks administrator privileges
#   - Updates package information
#   - Installs required dependencies
#   - Creates required directories
#   - Creates required log files
#   - Sets executable permissions
#   - Verifies important project files
#   - Displays post-installation instructions
#
# ============================================================


# ------------------------------------------------------------
# Determine the project directory safely
# ------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"


# ------------------------------------------------------------
# Project directories
# ------------------------------------------------------------
CONFIG_DIR="$PROJECT_ROOT/config"
MODULES_DIR="$PROJECT_ROOT/modules"
LOGS_DIR="$PROJECT_ROOT/logs"
REPORTS_DIR="$PROJECT_ROOT/reports"


# ------------------------------------------------------------
# Required project files
# ------------------------------------------------------------
CONFIG_FILE="$CONFIG_DIR/threshold.conf"
MONITOR_FILE="$PROJECT_ROOT/monitor.sh"
DASHBOARD_FILE="$PROJECT_ROOT/dashboard.sh"


# ------------------------------------------------------------
# Required packages
# ------------------------------------------------------------
REQUIRED_PACKAGES=(
    mailutils
    postfix
    sysstat
    curl
    whiptail
    net-tools
)


# ------------------------------------------------------------
# Display functions
# ------------------------------------------------------------
print_header() {

    echo
    echo "=========================================="
    echo " Automated Server Monitoring System"
    echo " Installation"
    echo "=========================================="
    echo
}


print_step() {

    echo
    echo "------------------------------------------"
    echo "$1"
    echo "------------------------------------------"
}


print_success() {

    echo "SUCCESS: $1"
}


print_warning() {

    echo "WARNING: $1"
}


print_error() {

    echo "ERROR: $1" >&2
}


# ------------------------------------------------------------
# Installation header
# ------------------------------------------------------------
print_header

echo "Project Directory:"
echo "$PROJECT_ROOT"


# ============================================================
# STEP 1 — Verify operating system
# ============================================================

print_step "Step 1: Checking operating system"


if [[ ! -f /etc/os-release ]]; then

    print_error "/etc/os-release was not found."
    print_error "Unable to determine the operating system."

    exit 1

fi


# Load operating system information.
# shellcheck source=/dev/null
source /etc/os-release


echo "Operating System: ${PRETTY_NAME:-Unknown}"


if [[ "${ID:-}" != "ubuntu" ]]; then

    print_warning "This installer was designed for Ubuntu."

    echo "Detected OS ID: ${ID:-Unknown}"
    echo

    read -r -p "Continue anyway? [y/N]: " continue_install

    if [[ ! "$continue_install" =~ ^[Yy]$ ]]; then

        echo "Installation cancelled."

        exit 1

    fi

else

    print_success "Ubuntu detected."

fi


# ============================================================
# STEP 2 — Verify required commands
# ============================================================

print_step "Step 2: Checking basic system commands"


BASIC_COMMANDS=(
    bash
    apt
    dpkg
)

for command_name in "${BASIC_COMMANDS[@]}"; do

    if ! command -v "$command_name" >/dev/null 2>&1; then

        print_error "Required command not found: $command_name"
        exit 1

    fi

done


print_success "Basic system commands are available."


# ============================================================
# STEP 3 — Check administrator privileges
# ============================================================

print_step "Step 3: Checking administrator privileges"


if [[ "$EUID" -ne 0 ]]; then

    print_error "This installer must be run with administrator privileges."

    echo
    echo "Run it using:"
    echo
    echo "sudo ./install.sh"
    echo

    exit 1

fi


print_success "Administrator privileges confirmed."


# ============================================================
# STEP 4 — Update package information
# ============================================================

print_step "Step 4: Updating package information"

echo "Running apt update..."
echo

if apt update; then

    print_success "Package information updated."

else

    print_error "apt update failed."
    exit 1

fi


# ============================================================
# STEP 5 — Install required packages
# ============================================================

print_step "Step 5: Installing required dependencies"

echo "The following packages will be installed:"
echo

for package in "${REQUIRED_PACKAGES[@]}"; do
    echo "  - $package"
done

echo

if apt install -y "${REQUIRED_PACKAGES[@]}"; then

    print_success "Required packages installed."

else

    print_error "One or more required packages could not be installed."
    exit 1

fi


# ============================================================
# STEP 6 — Create required directories
# ============================================================

print_step "Step 6: Creating project directories"


REQUIRED_DIRECTORIES=(
    "$CONFIG_DIR"
    "$MODULES_DIR"
    "$LOGS_DIR"
    "$REPORTS_DIR"
)


for directory in "${REQUIRED_DIRECTORIES[@]}"; do

    if mkdir -p "$directory"; then

        echo "Directory ready: $directory"

    else

        print_error "Unable to create directory:"
        print_error "$directory"

        exit 1

    fi

done


print_success "Required directories are ready."


# ============================================================
# STEP 7 — Create required log files
# ============================================================

print_step "Step 7: Creating log files"


SYSTEM_LOG="$LOGS_DIR/system.log"
ALERT_LOG="$LOGS_DIR/alerts.log"
CRON_LOG="$LOGS_DIR/cron.log"


for log_file in "$SYSTEM_LOG" "$ALERT_LOG" "$CRON_LOG"; do

    if touch "$log_file"; then

        echo "Log file ready: $log_file"

    else

        print_error "Unable to create log file:"
        print_error "$log_file"

        exit 1

    fi

done


print_success "Required log files are ready."


# ============================================================
# STEP 8 — Set executable permissions
# ============================================================

print_step "Step 8: Setting executable permissions"


EXECUTABLE_FILES=(
    "$MONITOR_FILE"
    "$DASHBOARD_FILE"
    "$PROJECT_ROOT/install.sh"
    "$MODULES_DIR/cpu_monitor.sh"
    "$MODULES_DIR/memory_monitor.sh"
    "$MODULES_DIR/disk_monitor.sh"
    "$MODULES_DIR/service_monitor.sh"
    "$MODULES_DIR/network_monitor.sh"
)


for file in "${EXECUTABLE_FILES[@]}"; do

    if [[ -f "$file" ]]; then

        chmod +x "$file"

        echo "Executable permission set: $file"

    else

        print_warning "File not found, skipping permission change:"
        echo "$file"

    fi

done


print_success "Executable permissions processed."


# ============================================================
# STEP 9 — Verify important project files
# ============================================================

print_step "Step 9: Verifying project files"


IMPORTANT_FILES=(
    "$CONFIG_FILE"
    "$MONITOR_FILE"
    "$DASHBOARD_FILE"
    "$MODULES_DIR/cpu_monitor.sh"
    "$MODULES_DIR/memory_monitor.sh"
    "$MODULES_DIR/disk_monitor.sh"
    "$MODULES_DIR/service_monitor.sh"
    "$MODULES_DIR/network_monitor.sh"
    "$MODULES_DIR/logger.sh"
    "$MODULES_DIR/alert.sh"
)


missing_files=0


for file in "${IMPORTANT_FILES[@]}"; do

    if [[ -f "$file" ]]; then

        echo "FOUND: $file"

    else

        echo "MISSING: $file"

        missing_files=$((missing_files + 1))

    fi

done


if [[ "$missing_files" -gt 0 ]]; then

    print_warning "$missing_files required project file(s) are missing."

else

    print_success "All important project files were found."

fi


# ============================================================
# STEP 10 — Check installed dependencies
# ============================================================

print_step "Step 10: Verifying installed dependencies"


missing_packages=0


for package in "${REQUIRED_PACKAGES[@]}"; do

    if dpkg -s "$package" >/dev/null 2>&1; then

        echo "INSTALLED: $package"

    else

        echo "MISSING: $package"

        missing_packages=$((missing_packages + 1))

    fi

done


if [[ "$missing_packages" -gt 0 ]]; then

    print_error "$missing_packages required package(s) are missing."

    exit 1

fi


print_success "All required packages are installed."


# ============================================================
# STEP 11 — Installation summary
# ============================================================

print_step "Installation Summary"


echo "Project Directory : $PROJECT_ROOT"
echo "Configuration     : $CONFIG_FILE"
echo "Modules Directory : $MODULES_DIR"
echo "Logs Directory    : $LOGS_DIR"
echo "Reports Directory : $REPORTS_DIR"
echo


print_success "Installation preparation completed."


# ============================================================
# POST-INSTALLATION CONFIGURATION
# ============================================================

echo
echo "=========================================="
echo " Post-Installation Configuration"
echo "=========================================="
echo

echo "Before using the monitoring system, review:"
echo
echo "$CONFIG_FILE"
echo

echo "Important settings include:"
echo
echo "  CPU_THRESHOLD"
echo "  MEMORY_THRESHOLD"
echo "  DISK_THRESHOLD"
echo "  ADMIN_EMAIL"
echo "  SERVICES"
echo

echo "Example:"
echo
echo '  SERVICES="cron"'
echo

echo "Make sure ADMIN_EMAIL contains the administrator's"
echo "actual email address before relying on email alerts."
echo

echo "The mail system should also be tested separately."
echo

echo "Example test:"
echo
echo '  echo "Test email" | mail -s "Monitoring Test" your@email.com'
echo

echo "Dashboard:"
echo
echo "  ./dashboard.sh"
echo

echo "Main monitoring controller:"
echo
echo "  ./monitor.sh"
echo

echo "=========================================="
echo " Installation Complete"
echo "=========================================="
echo


exit 0
