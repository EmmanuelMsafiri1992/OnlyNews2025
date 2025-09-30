#!/bin/bash
# IP Change Detection and Auto-Update Script
# This script checks if the IP has changed and updates the configuration

INSTALL_DIR="/opt/newsapp"
IP_CACHE_FILE="$INSTALL_DIR/.current_ip"
LOG_FILE="$INSTALL_DIR/storage/logs/ip-monitor.log"

# Function to get current IP
get_current_ip() {
    ip addr show | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}' | cut -d'/' -f1
}

# Function to log with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Get current IP
CURRENT_IP=$(get_current_ip)

if [ -z "$CURRENT_IP" ]; then
    log_message "⚠️  Could not detect IP address"
    exit 1
fi

# Check if IP has changed
if [ -f "$IP_CACHE_FILE" ]; then
    CACHED_IP=$(cat "$IP_CACHE_FILE")

    if [ "$CURRENT_IP" != "$CACHED_IP" ]; then
        log_message "🔄 IP changed from $CACHED_IP to $CURRENT_IP - Updating configuration..."

        # Update .env file
        cd "$INSTALL_DIR" || exit 1

        # Update APP_URL
        sed -i "s|APP_URL=.*|APP_URL=http://$CURRENT_IP:8000|" .env

        # Update VITE_API_BASE_URL
        if grep -q "^VITE_API_BASE_URL=" .env; then
            sed -i "s|VITE_API_BASE_URL=.*|VITE_API_BASE_URL=http://$CURRENT_IP:8000|" .env
        else
            echo "VITE_API_BASE_URL=http://$CURRENT_IP:8000" >> .env
        fi

        # Clear Laravel cache
        php artisan config:clear 2>/dev/null || true
        php artisan cache:clear 2>/dev/null || true

        # Restart services
        systemctl restart newsapp 2>/dev/null || true
        systemctl restart newsapp-vite 2>/dev/null || true

        # Update cached IP
        echo "$CURRENT_IP" > "$IP_CACHE_FILE"

        log_message "✅ Configuration updated and services restarted with new IP: $CURRENT_IP"
    else
        log_message "ℹ️  IP unchanged: $CURRENT_IP"
    fi
else
    # First run - cache the IP
    echo "$CURRENT_IP" > "$IP_CACHE_FILE"
    log_message "ℹ️  IP cached: $CURRENT_IP"
fi

exit 0
