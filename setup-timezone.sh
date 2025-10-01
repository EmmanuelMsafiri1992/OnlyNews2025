#!/bin/bash

# NanoPi Timezone and NTP Setup Script
# This script configures the system timezone and enables NTP time synchronization

echo "=========================================="
echo "NanoPi Timezone & Time Synchronization Setup"
echo "=========================================="
echo ""

# Set timezone to Asia/Jerusalem (Israel)
echo "Setting timezone to Asia/Jerusalem..."
sudo timedatectl set-timezone Asia/Jerusalem

# Check if NTP is available
if command -v systemd-timesyncd &> /dev/null; then
    echo "Enabling systemd-timesyncd for automatic time synchronization..."
    sudo systemctl enable systemd-timesyncd
    sudo systemctl start systemd-timesyncd
elif command -v ntpd &> /dev/null; then
    echo "Enabling ntpd for automatic time synchronization..."
    sudo systemctl enable ntp
    sudo systemctl start ntp
else
    echo "Installing NTP for time synchronization..."
    sudo apt-get update
    sudo apt-get install -y systemd-timesyncd
    sudo systemctl enable systemd-timesyncd
    sudo systemctl start systemd-timesyncd
fi

# Enable NTP synchronization
echo "Enabling NTP synchronization..."
sudo timedatectl set-ntp true

# Force immediate synchronization
echo "Forcing immediate time synchronization..."
if command -v systemd-timesyncd &> /dev/null; then
    sudo systemctl restart systemd-timesyncd
elif command -v ntpd &> /dev/null; then
    sudo systemctl restart ntp
fi

# Wait a moment for sync
sleep 2

echo ""
echo "=========================================="
echo "Current System Time Configuration:"
echo "=========================================="
timedatectl status
echo ""
echo "Current date and time:"
date
echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="
echo ""
echo "Note: Laravel application timezone is set to Asia/Jerusalem"
echo "You may need to restart php-fpm/apache/nginx for changes to take effect:"
echo "  sudo systemctl restart php7.4-fpm  # or your PHP version"
echo ""
