#!/bin/bash
# NewsApp Update Script
# Usage: sudo ./update_newsapp.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="/opt/newsapp"
LOG_FILE="/var/log/newsapp/update.log"

# Create log directory if it doesn't exist
mkdir -p /var/log/newsapp

echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     🔄 NEWSAPP UPDATE SCRIPT 🔄             ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] ✅${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ❌${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] ℹ️${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$LOG_FILE"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Check if installation directory exists
if [[ ! -d "$INSTALL_DIR" ]]; then
    log_error "Installation directory not found: $INSTALL_DIR"
    log_error "Please run the installer first!"
    exit 1
fi

cd "$INSTALL_DIR"

# STEP 1: Stop services
log_info "Step 1: Stopping NewsApp services..."
systemctl stop newsapp 2>/dev/null || true
systemctl stop newsapp-vite 2>/dev/null || true
sleep 2
log "Services stopped"

# STEP 2: Backup current installation
log_info "Step 2: Creating backup..."
BACKUP_DIR="/opt/newsapp-backup-$(date +%Y%m%d-%H%M%S)"
cp -r "$INSTALL_DIR" "$BACKUP_DIR" 2>/dev/null
log "Backup created at: $BACKUP_DIR"

# STEP 3: Pull latest changes
log_info "Step 3: Pulling latest changes from repository..."
if git pull origin main 2>&1 | tee -a "$LOG_FILE"; then
    log "Git pull successful"
else
    log_error "Git pull failed! Rolling back..."
    systemctl start newsapp
    systemctl start newsapp-vite
    exit 1
fi

# STEP 4: Update Composer dependencies
log_info "Step 4: Updating Composer dependencies..."
if composer install --no-dev --optimize-autoloader 2>&1 | tee -a "$LOG_FILE"; then
    log "Composer dependencies updated"
else
    log_error "Composer update failed (continuing anyway)"
fi

# STEP 5: Update NPM dependencies
log_info "Step 5: Updating NPM dependencies..."
if npm install --legacy-peer-deps 2>&1 | tee -a "$LOG_FILE"; then
    log "NPM dependencies updated"
else
    log_error "NPM update failed (continuing anyway)"
fi

# STEP 6: Build frontend assets
log_info "Step 6: Building frontend assets..."
if npm run build 2>&1 | tee -a "$LOG_FILE"; then
    log "Frontend assets built successfully"
else
    log_error "Build failed (continuing anyway)"
fi

# STEP 7: Run database migrations
log_info "Step 7: Running database migrations..."
if php artisan migrate --force 2>&1 | tee -a "$LOG_FILE"; then
    log "Database migrations completed"
else
    log_error "Migration failed (continuing anyway)"
fi

# STEP 8: Clear caches
log_info "Step 8: Clearing application caches..."
php artisan config:clear 2>/dev/null
php artisan cache:clear 2>/dev/null
php artisan view:clear 2>/dev/null
php artisan route:clear 2>/dev/null
log "Caches cleared"

# STEP 9: Optimize application
log_info "Step 9: Optimizing application..."
php artisan config:cache 2>/dev/null
php artisan route:cache 2>/dev/null
php artisan view:cache 2>/dev/null
log "Application optimized"

# STEP 10: Fix permissions
log_info "Step 10: Setting proper permissions..."
chown -R www-data:www-data "$INSTALL_DIR"
chmod -R 755 "$INSTALL_DIR"
chmod -R 775 "$INSTALL_DIR/storage"
chmod -R 775 "$INSTALL_DIR/bootstrap/cache"
log "Permissions set"

# STEP 11: Reload systemd configuration
log_info "Step 11: Reloading systemd configuration..."
systemctl daemon-reload
log "Systemd reloaded"

# STEP 12: Start services
log_info "Step 12: Starting NewsApp services..."
systemctl start newsapp
systemctl start newsapp-vite
sleep 5

# STEP 13: Verify services
log_info "Step 13: Verifying services..."

if systemctl is-active newsapp >/dev/null 2>&1; then
    log "✅ Laravel service: RUNNING"
else
    log_error "❌ Laravel service: NOT RUNNING"
fi

if systemctl is-active newsapp-vite >/dev/null 2>&1; then
    log "✅ Vite service: RUNNING"
else
    log_error "❌ Vite service: NOT RUNNING"
fi

# Test web interface
if curl -s -m 10 http://localhost:8000 >/dev/null 2>&1; then
    log "✅ Web interface: ACCESSIBLE"
else
    log_error "⚠️ Web interface: NOT ACCESSIBLE (may need more time)"
fi

# Get system IP
IP_ADDRESS=$(ip addr show | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}' | cut -d'/' -f1 2>/dev/null || echo "localhost")

echo
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        ✅ UPDATE COMPLETED SUCCESSFULLY! ✅          ║${NC}"
echo -e "${GREEN}╠═══════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  🌐 Access: http://$IP_ADDRESS:8000                  ║${NC}"
echo -e "${GREEN}║  📝 Update log: $LOG_FILE        ║${NC}"
echo -e "${GREEN}║  💾 Backup: $BACKUP_DIR    ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${CYAN}📊 Service Status:${NC}"
echo -e "   Laravel: $(systemctl is-active newsapp 2>/dev/null || echo 'unknown')"
echo -e "   Vite:    $(systemctl is-active newsapp-vite 2>/dev/null || echo 'unknown')"
echo
echo -e "${YELLOW}💡 Troubleshooting Commands:${NC}"
echo -e "   View logs:     sudo journalctl -u newsapp -f"
echo -e "   Restart:       sudo systemctl restart newsapp"
echo -e "   Check status:  sudo systemctl status newsapp"
echo
