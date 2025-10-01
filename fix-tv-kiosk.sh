#!/bin/bash

echo "Checking what's installed..."
which startx
which xinit
which chromium-browser
which chromium

echo ""
echo "Installing missing packages..."
apt-get update
apt-get install -y xinit xserver-xorg xserver-xorg-core xserver-xorg-video-fbdev chromium chromium-browser 2>/dev/null

echo ""
echo "Creating kiosk start script..."
cat > /usr/local/bin/start-tv-kiosk.sh << 'INNER_EOF'
#!/bin/bash
export DISPLAY=:0
xset -dpms
xset s off
xset s noblank

# Try different chromium names
if command -v chromium-browser &> /dev/null; then
    chromium-browser --kiosk --noerrdialogs --disable-infobars --incognito --no-first-run http://localhost:8000
elif command -v chromium &> /dev/null; then
    chromium --kiosk --noerrdialogs --disable-infobars --incognito --no-first-run http://localhost:8000
else
    echo "Chromium not found!"
    exit 1
fi
INNER_EOF

chmod +x /usr/local/bin/start-tv-kiosk.sh

echo ""
echo "Creating X startup config..."
mkdir -p /home/root/.config
cat > /home/root/.xinitrc << 'INNER_EOF'
#!/bin/sh
xset -dpms
xset s off
xset s noblank
/usr/local/bin/start-tv-kiosk.sh
INNER_EOF

chmod +x /home/root/.xinitrc

echo ""
echo "Updating systemd service..."
cat > /etc/systemd/system/tv-kiosk.service << 'INNER_EOF'
[Unit]
Description=TV Kiosk Mode Display
After=network.target

[Service]
Type=simple
User=root
Environment=DISPLAY=:0
ExecStart=/usr/bin/xinit /home/root/.xinitrc -- :0 vt1
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
INNER_EOF

systemctl daemon-reload
systemctl enable tv-kiosk

echo ""
echo "Setup complete! Now run: sudo systemctl start tv-kiosk"
