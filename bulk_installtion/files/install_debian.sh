#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

echo "Running apt update..."
apt update -y

echo "Running apt upgrade..."
apt upgrade -y

touch /opt/system_upgraded
