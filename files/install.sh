#!/bin/bash

set -e

LOG_FILE="/var/log/unattended_install.log"

# Redirect stdout and stderr to log
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=============================="
echo "Installation started: $(date)"
echo "=============================="

export DEBIAN_FRONTEND=noninteractive

echo "Running apt update..."
apt update -y

echo "Running apt upgrade..."
apt upgrade -y

echo "Installation completed successfully."

touch /opt/system_upgraded

echo "Finished at: $(date)"
