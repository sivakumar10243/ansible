#!/bin/bash
set -e

# Log file on the target host
LOG_FILE="/var/log/unattended_install_rhel.log"

# Redirect stdout + stderr to log
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=============================="
echo "RHEL Installation started: $(date)"
echo "=============================="

# Unattended package manager
export DEBIAN_FRONTEND=noninteractive

echo "Running yum update..."
yum -y update

echo "Running yum upgrade..."
yum -y upgrade

# Mark completion
touch /opt/rhel_system_upgraded

echo "RHEL Installation finished: $(date)"
