#!/bin/bash
set -e

echo "Running yum update..."
yum -y update

echo "Running yum upgrade..."
yum -y upgrade
