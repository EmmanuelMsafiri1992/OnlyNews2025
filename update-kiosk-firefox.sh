#!/bin/bash

echo "Updating kiosk script to use Firefox..."

# Create the Firefox kiosk startup script
cat > /usr/local/bin/start-tv-kiosk.sh << 'EOF'
#!/bin/bash
export DISPLAY=:0

# Disable screen blanking
xset -dpms
xset s off
xset s noblank

# Hide cursor
unclutter -idle 0 &

# Start Firefox in kiosk mode
firefox --kiosk http://localhost:8000
EOF

chmod +x /usr/local/bin/start-tv-kiosk.sh

# Create .xinitrc
cat > /home/root/.xinitrc << 'EOF'
#!/bin/sh
xset -dpms
xset s off
xset s noblank
/usr/local/bin/start-tv-kiosk.sh
EOF

chmod +x /home/root/.xinitrc

# Update systemd service
cat > /etc/systemd/system/tv-kiosk.service << 'EOF'
[Unit]
Description=TV Kiosk Mode Display
After=network.target

[Service]
Type=simple
User=root
Environment=DISPLAY=:0
ExecStart=/usr/bin/xinit /home/root/.xinitrc -- :0 -nolisten tcp vt1
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload and enable
systemctl daemon-reload
systemctl enable tv-kiosk

echo ""
echo "✓ Kiosk script updated to use Firefox!"
echo ""
echo "Now run:"
echo "  sudo systemctl start tv-kiosk"
echo ""
echo "Or reboot to start automatically:"
echo "  sudo reboot"
