#!/bin/bash
set -e

# Ensure brew is in PATH
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

echo "Running brew update..."
brew update

echo "Running brew upgrade..."
brew upgrade
brew upgrade --cask --greedy || true
