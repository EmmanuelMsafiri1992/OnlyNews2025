#!/bin/bash
# Manual Ubuntu 16.04 → 18.04 → 20.04 Upgrade Script
# This script manually upgrades Ubuntu when do-release-upgrade fails

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Manual Ubuntu 16.04 → 20.04 Upgrade Script              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# Detect current version
. /etc/os-release
echo -e "${GREEN}Current OS: $PRETTY_NAME${NC}"
echo

if [ "$VERSION_ID" = "16.04" ]; then
    echo -e "${YELLOW}Upgrading from 16.04 to 18.04 first...${NC}"
    TARGET="bionic"
elif [ "$VERSION_ID" = "18.04" ]; then
    echo -e "${YELLOW}Upgrading from 18.04 to 20.04...${NC}"
    TARGET="focal"
elif [ "$VERSION_ID" = "20.04" ]; then
    echo -e "${GREEN}Already on Ubuntu 20.04! No upgrade needed.${NC}"
    exit 0
else
    echo -e "${GREEN}Ubuntu $VERSION_ID - No upgrade needed.${NC}"
    exit 0
fi

echo -e "${RED}WARNING: This will modify your system repositories!${NC}"
echo -e "${CYAN}Press Ctrl+C within 10 seconds to cancel...${NC}"
sleep 10

# Backup sources list
echo -e "${CYAN}Backing up sources.list...${NC}"
cp /etc/apt/sources.list /etc/apt/sources.list.backup-$(date +%Y%m%d)

# Update sources.list to target version
echo -e "${CYAN}Updating repository sources to $TARGET...${NC}"
sed -i "s/xenial/$TARGET/g" /etc/apt/sources.list
sed -i "s/bionic/$TARGET/g" /etc/apt/sources.list

# Update package lists
echo -e "${CYAN}Updating package lists...${NC}"
apt-get update

# Upgrade packages
echo -e "${CYAN}Upgrading all packages (this will take 20-40 minutes)...${NC}"
DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y

# Clean up
echo -e "${CYAN}Cleaning up...${NC}"
apt-get autoremove -y
apt-get autoclean

echo
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                 Upgrade Complete!                            ║${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}║  Please REBOOT your system now:                             ║${NC}"
echo -e "${GREEN}║  ${CYAN}sudo reboot${GREEN}                                               ║${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}║  After reboot, run this script again if upgrading to 20.04  ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo
