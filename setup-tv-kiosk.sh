#!/bin/bash

# TV Kiosk Mode Setup Script for NanoPi-NEO
# This script installs and configures Chromium browser in kiosk mode

echo "=========================================="
echo "TV Kiosk Mode Setup"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo: sudo bash setup-tv-kiosk.sh"
    exit 1
fi

echo "Step 1: Updating package list..."
apt-get update

echo ""
echo "Step 2: Installing X server and Chromium browser..."
echo "This may take 5-10 minutes depending on your internet speed..."
apt-get install -y xserver-xorg-video-fbdev xserver-xorg xinit x11-xserver-utils chromium unclutter

echo ""
echo "Step 3: Creating kiosk start script..."
cat > /home/root/start-kiosk.sh << 'KIOSK_SCRIPT'
#!/bin/bash

# Disable screen blanking and power management
xset -dpms
xset s off
xset s noblank

# Hide mouse cursor
unclutter -idle 0.1 &

# Start Chromium in kiosk mode
chromium --kiosk \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --disable-component-update \
  --incognito \
  --app=http://localhost:8000 \
  --start-fullscreen \
  --window-size=1920,1080 \
  --window-position=0,0 \
  --user-data-dir=/tmp/chromium-kiosk
KIOSK_SCRIPT

chmod +x /home/root/start-kiosk.sh

echo ""
echo "Step 4: Creating X server startup configuration..."
cat > /home/root/.xinitrc << 'XINITRC'
#!/bin/bash
exec /home/root/start-kiosk.sh
XINITRC

chmod +x /home/root/.xinitrc

echo ""
echo "Step 5: Creating systemd service for auto-start..."
cat > /etc/systemd/system/tv-kiosk.service << 'SERVICE'
[Unit]
Description=TV Kiosk Mode Display
After=network.target

[Service]
Type=simple
User=root
Environment=DISPLAY=:0
ExecStart=/usr/bin/startx
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE

echo ""
echo "Step 6: Enabling auto-start service..."
systemctl daemon-reload
systemctl enable tv-kiosk.service

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "To start the TV kiosk now, run:"
echo "  sudo systemctl start tv-kiosk"
echo ""
echo "Or simply reboot:"
echo "  sudo reboot"
echo ""
echo "The TV will automatically show the news app in fullscreen!"
echo "=========================================="
