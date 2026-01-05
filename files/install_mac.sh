#!/bin/bash
set -e

LOG_FILE="$HOME/unattended_install_mac.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=============================="
echo "MacOS Installation started: $(date)"
echo "=============================="

# Fix Homebrew ownership
if [ -d "/opt/homebrew" ]; then
    echo "Fixing Homebrew directory permissions..."
    sudo chown -R $(whoami) /opt/homebrew
fi

# Install Homebrew if missing
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found, installing..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "Running brew update..."
brew update --quiet

echo "Running brew upgrade..."
brew upgrade --quiet
brew upgrade --cask --greedy --quiet || true

echo "Running brew cleanup..."
brew cleanup -s --quiet

# Mark completion
touch "$HOME/mac_system_upgraded"

echo "MacOS Installation finished: $(date)"
echo "Log file: $LOG_FILE"
