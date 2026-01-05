#!/bin/bash
set -e

# Log file on the Mac host
LOG_FILE="/var/log/unattended_install_mac.log"

# Redirect stdout and stderr to log
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=============================="
echo "MacOS Installation started: $(date)"
echo "=============================="

# Check if Homebrew is installed
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found, installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "Running brew update..."
brew update

echo "Running brew upgrade..."
brew upgrade

# Mark completion
touch /opt/mac_system_upgraded

echo "MacOS Installation finished: $(date)"
