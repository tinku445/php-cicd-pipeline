#!/usr/bin/env bash
set -e

if ! command -v docker &> /dev/null
then
    echo "Docker not found. Installing..."
    sudo dnf install -y docker
    sudo systemctl enable --now docker
    sudo usermod -aG docker ec2-user
fi

echo "Docker ready on build server."
