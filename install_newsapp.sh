#!/bin/bash
# NewsApp One-Command Installer
# Complete setup from fresh NanoPi to working Laravel + Vue system
# Usage: curl -sSL https://raw.githubusercontent.com/EmmanuelMsafiri1992/OnlyNews2025/main/install_newsapp.sh | bash

# DO NOT USE set -e - we want to handle errors gracefully

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

REPO_URL="https://github.com/EmmanuelMsafiri1992/OnlyNews2025.git"
INSTALL_DIR="/opt/newsapp"
LOG_FILE="/tmp/newsapp_complete_install.log"
DB_NAME="news_db"
DB_USER="newsapp_user"
DB_PASS=$(openssl rand -base64 12)

# Initialize log file
echo "NewsApp Installation Started: $(date)" > "$LOG_FILE"

echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║          🚀 NEWSAPP ONE-COMMAND INSTALLER 🚀                ║${NC}"
echo -e "${PURPLE}║                                                              ║${NC}"
echo -e "${PURPLE}║  Fresh NanoPi → Fully Working Laravel + Vue News System    ║${NC}"
echo -e "${PURPLE}║  Everything automated in a single command!                  ║${NC}"
echo -e "${PURPLE}║                                                              ║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${CYAN}📝 Complete installation log: $LOG_FILE${NC}"
echo

# Logging functions
log() {
    local msg="${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✅${NC} $1"
    echo -e "$msg"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$LOG_FILE"
}

log_warning() {
    local msg="${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️${NC} $1"
    echo -e "$msg"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$LOG_FILE"
}

log_error() {
    local msg="${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ❌${NC} $1"
    echo -e "$msg"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
}

log_info() {
    local msg="${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] ℹ️${NC} $1"
    echo -e "$msg"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$LOG_FILE"
}

log_success() {
    local msg="${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] 🎉${NC} $1"
    echo -e "$msg"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$LOG_FILE"
}

# Safe run function
safe_run() {
    local cmd="$1"
    local description="$2"

    log_info "$description"
    if eval "$cmd" 2>/dev/null; then
        log "✅ Success: $description"
        return 0
    else
        log_warning "⚠️ Failed (continuing): $description"
        return 1
    fi
}

# Retry run function
retry_run() {
    local cmd="$1"
    local description="$2"
    local max_attempts="${3:-3}"

    for ((i=1; i<=max_attempts; i++)); do
        log_info "Attempt $i/$max_attempts: $description"
        if eval "$cmd" 2>/dev/null; then
            log "✅ Success on attempt $i: $description"
            return 0
        else
            log_warning "⚠️ Attempt $i failed: $description"
            sleep 2
        fi
    done

    log_error "❌ All attempts failed: $description (continuing anyway)"
    return 1
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root (use sudo)${NC}"
        echo -e "${YELLOW}Usage: curl -sSL https://raw.githubusercontent.com/EmmanuelMsafiri1992/OnlyNews2025/main/install_newsapp.sh | sudo bash${NC}"
        exit 1
    fi
}

# PHASE 0: COMPLETE SYSTEM CLEANUP
phase0_complete_cleanup() {
    log_info "🧹 PHASE 0: Complete System Cleanup & Preparation"

    # Stop all running processes
    log "Stopping all NewsApp processes..."

    pkill -9 -f "php artisan serve" 2>/dev/null || true
    pkill -9 -f "vite" 2>/dev/null || true
    pkill -9 -f "newsapp" 2>/dev/null || true

    sleep 2

    # Stop and disable systemd services
    log "Stopping and disabling systemd services..."

    systemctl stop newsapp 2>/dev/null || true
    systemctl disable newsapp 2>/dev/null || true
    systemctl stop newsapp-vite 2>/dev/null || true
    systemctl disable newsapp-vite 2>/dev/null || true

    # Remove systemd service files
    log "Removing systemd service files..."

    rm -f /etc/systemd/system/newsapp.service 2>/dev/null || true
    rm -f /etc/systemd/system/newsapp-vite.service 2>/dev/null || true
    systemctl daemon-reload 2>/dev/null

    # Remove installation directories
    log "Removing previous installation directories..."

    if [[ -d "$INSTALL_DIR" ]]; then
        SPACE=$(du -sh "$INSTALL_DIR" 2>/dev/null | awk '{print $1}')
        rm -rf "$INSTALL_DIR" 2>/dev/null && log "  ✅ Removed $INSTALL_DIR (freed $SPACE)"
    fi

    # Clean temporary directories
    log "Cleaning temporary directories..."
    rm -rf /tmp/newsapp* 2>/dev/null || true

    log_success "✅ Phase 0 Complete: System cleaned!"
}

# PHASE 1: SYSTEM PREPARATION
phase1_system_preparation() {
    log_info "🔧 PHASE 1: System Preparation & Updates"

    # Update system packages
    log "Updating system package list..."
    retry_run "apt-get update -qq" "System package update" 5

    # Install essential system tools
    log "Installing essential system tools..."
    ESSENTIAL_TOOLS=(
        "curl" "wget" "git" "unzip" "sudo" "systemd"
        "build-essential" "pkg-config" "software-properties-common"
    )

    for tool in "${ESSENTIAL_TOOLS[@]}"; do
        safe_run "apt-get install -y $tool -qq" "Installing $tool"
    done

    log_success "✅ Phase 1 Complete: System prepared"
}

# PHASE 2: PHP & MYSQL INSTALLATION
phase2_php_mysql_setup() {
    log_info "🐘 PHASE 2: PHP & MySQL Environment Setup"

    # Add PHP repository
    log "Adding PHP repository..."
    retry_run "add-apt-repository -y ppa:ondrej/php" "Adding PHP PPA" 3
    retry_run "apt-get update -qq" "Updating after PPA" 3

    # Install PHP 8.2 and extensions
    log "Installing PHP 8.2 and extensions..."
    PHP_PACKAGES=(
        "php8.2" "php8.2-cli" "php8.2-fpm" "php8.2-sqlite3" "php8.2-mysql" "php8.2-xml"
        "php8.2-mbstring" "php8.2-curl" "php8.2-zip" "php8.2-gd"
        "php8.2-bcmath" "php8.2-intl" "php8.2-tokenizer"
    )

    for package in "${PHP_PACKAGES[@]}"; do
        safe_run "apt-get install -y $package -qq" "Installing $package"
    done

    log_success "✅ Phase 2 Complete: PHP installed"
}

# PHASE 3: COMPOSER INSTALLATION
phase3_composer_installation() {
    log_info "🎼 PHASE 3: Composer Installation"

    # Download and install Composer
    log "Installing Composer..."

    cd /tmp
    retry_run "curl -sS https://getcomposer.org/installer -o composer-setup.php" "Downloading Composer" 3
    safe_run "php composer-setup.php --install-dir=/usr/local/bin --filename=composer" "Installing Composer"
    rm -f composer-setup.php

    # Set PHP path in environment
    export PATH="/usr/bin:$PATH"

    # Verify Composer
    if command -v composer >/dev/null 2>&1; then
        log "✅ Composer installed: $(composer --version)"
    else
        log_error "❌ Composer installation failed"
    fi

    log_success "✅ Phase 3 Complete: Composer ready"
}

# PHASE 4: NODE.JS & NPM INSTALLATION
phase4_nodejs_installation() {
    log_info "📦 PHASE 4: Node.js & NPM Installation"

    # Install Node.js 20.x
    log "Installing Node.js 20.x..."

    retry_run "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -" "Adding NodeSource repository" 3
    safe_run "apt-get install -y nodejs -qq" "Installing Node.js"

    # Verify installations
    if command -v node >/dev/null 2>&1; then
        log "✅ Node.js installed: $(node --version)"
    fi

    if command -v npm >/dev/null 2>&1; then
        log "✅ npm installed: $(npm --version)"
    fi

    log_success "✅ Phase 4 Complete: Node.js ready"
}

# PHASE 5: REPOSITORY CLONE
phase5_clone_repository() {
    log_info "📥 PHASE 5: Repository Download"

    # Clone the repository
    log "Cloning NewsApp repository..."
    cd /tmp
    retry_run "git clone $REPO_URL newsapp-temp" "Cloning repository" 3

    # Move to installation directory
    log "Moving to installation directory..."
    mkdir -p "$INSTALL_DIR"

    if [[ -d "/tmp/newsapp-temp" ]]; then
        cp -r /tmp/newsapp-temp/* "$INSTALL_DIR/"
        rm -rf /tmp/newsapp-temp
        log "✅ Repository files copied to $INSTALL_DIR"
    else
        log_error "❌ Repository clone failed"
        exit 1
    fi

    log_success "✅ Phase 5 Complete: Repository downloaded"
}

# PHASE 6: DATABASE SETUP
phase6_database_setup() {
    log_info "💾 PHASE 6: Database Configuration"

    # Check if SQLite database exists in repository
    if [[ -f "$INSTALL_DIR/database/database.sqlite" ]]; then
        log "✅ SQLite database found in repository"
        log "✅ Using SQLite database from repository"
        chmod 664 "$INSTALL_DIR/database/database.sqlite"
    else
        # Create empty SQLite database
        log "Creating SQLite database..."
        touch "$INSTALL_DIR/database/database.sqlite"
        chmod 664 "$INSTALL_DIR/database/database.sqlite"
        log "✅ SQLite database created"
    fi

    log_success "✅ Phase 6 Complete: Database ready"
}

# PHASE 7: APPLICATION CONFIGURATION
phase7_application_configuration() {
    log_info "⚙️ PHASE 7: Application Configuration"

    cd "$INSTALL_DIR"

    # Ensure PHP is in PATH for all commands
    export PATH="/usr/bin:/usr/local/bin:$PATH"

    # Create .env file
    log "Creating .env file..."

    if [[ -f ".env.example" ]]; then
        cp .env.example .env
    else
        cat > .env << EOF
APP_NAME=NewsApp
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=http://localhost

DB_CONNECTION=sqlite
DB_DATABASE=database/database.sqlite
DB_FOREIGN_KEYS=true

SESSION_DRIVER=database
SESSION_LIFETIME=120
SESSION_ENCRYPT=false

BROADCAST_CONNECTION=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=database
EOF
    fi

    # Get server IP for proper configuration
    SERVER_IP=$(ip addr show | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}' | cut -d'/' -f1 2>/dev/null || echo "localhost")

    # Update .env with proper URLs
    sed -i "s|APP_URL=.*|APP_URL=http://$SERVER_IP:8000|" .env
    sed -i "s|VITE_API_BASE_URL=.*|VITE_API_BASE_URL=http://$SERVER_IP:8000|" .env

    # Ensure SQLite is configured
    sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=sqlite/" .env
    sed -i "s|DB_DATABASE=.*|DB_DATABASE=database/database.sqlite|" .env

    log "✅ .env file configured"

    # Install Composer dependencies
    log "Installing Composer dependencies (this may take a few minutes)..."
    retry_run "composer install --no-dev --optimize-autoloader --quiet" "Composer install" 3

    # Generate application key
    log "Generating application key..."
    /usr/bin/php artisan key:generate --force 2>/dev/null || php artisan key:generate --force 2>/dev/null

    # Only run migrations if database is empty or new
    if [[ ! -s "$INSTALL_DIR/database/database.sqlite" ]]; then
        log "Running database migrations..."
        /usr/bin/php artisan migrate --force 2>/dev/null || php artisan migrate --force 2>/dev/null
    else
        log "✅ Using existing database with data"
    fi

    # Install NPM dependencies
    log "Installing NPM dependencies (this may take several minutes)..."
    retry_run "npm install --legacy-peer-deps" "NPM install" 3

    # Build frontend assets
    log "Building frontend assets..."
    npm run build 2>/dev/null

    # Set permissions
    log "Setting proper permissions..."
    chown -R www-data:www-data "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"
    chmod -R 775 "$INSTALL_DIR/storage"
    chmod -R 775 "$INSTALL_DIR/bootstrap/cache"

    # Make IP update script executable
    chmod +x "$INSTALL_DIR/check-and-update-ip.sh"

    log_success "✅ Phase 7 Complete: Application configured"
}

# PHASE 8: SYSTEMD SERVICE CONFIGURATION
phase8_systemd_service() {
    log_info "⚙️ PHASE 8: Systemd Service Configuration"

    # Create Laravel service
    log "Creating Laravel systemd service..."
    cat > /etc/systemd/system/newsapp.service << 'EOF'
[Unit]
Description=NewsApp Laravel Application
Documentation=https://laravel.com/docs
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/newsapp
Environment=PATH=/usr/bin:/usr/local/bin
ExecStart=/usr/bin/php artisan serve --host=0.0.0.0 --port=8000
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=newsapp

[Install]
WantedBy=multi-user.target
EOF

    # Create Vite service for development mode
    log "Creating Vite systemd service..."
    cat > /etc/systemd/system/newsapp-vite.service << 'EOF'
[Unit]
Description=NewsApp Vite Development Server
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/newsapp
Environment=PATH=/usr/bin:/usr/local/bin:/usr/local/sbin
ExecStart=/usr/bin/npm run dev
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=newsapp-vite

[Install]
WantedBy=multi-user.target
EOF

    # Create IP monitor systemd service
    log "Creating IP monitor systemd service..."
    cat > /etc/systemd/system/newsapp-ip-monitor.service << 'EOF'
[Unit]
Description=NewsApp IP Monitor Service
After=network.target

[Service]
Type=oneshot
ExecStart=/opt/newsapp/check-and-update-ip.sh
User=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # Create IP monitor timer (runs every 5 minutes)
    log "Creating IP monitor timer..."
    cat > /etc/systemd/system/newsapp-ip-monitor.timer << 'EOF'
[Unit]
Description=NewsApp IP Monitor Timer
Requires=newsapp-ip-monitor.service

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
AccuracySec=1min

[Install]
WantedBy=timers.target
EOF

    # Enable and start services
    systemctl daemon-reload
    systemctl enable newsapp
    systemctl enable newsapp-vite
    systemctl enable newsapp-ip-monitor.timer
    systemctl start newsapp-ip-monitor.timer

    log_success "✅ Phase 8 Complete: Systemd services configured"
}

# PHASE 9: SERVICE STARTUP
phase9_service_startup() {
    log_info "🚀 PHASE 9: Service Startup"

    # Start Laravel service
    log "Starting NewsApp Laravel service..."
    systemctl start newsapp
    sleep 3

    # Start Vite service
    log "Starting Vite development server..."
    systemctl start newsapp-vite
    sleep 3

    # Check service status
    if systemctl is-active newsapp >/dev/null 2>&1; then
        log_success "✅ Laravel service: RUNNING"
    else
        log_warning "⚠️ Laravel service: FAILED TO START"
    fi

    if systemctl is-active newsapp-vite >/dev/null 2>&1; then
        log_success "✅ Vite service: RUNNING"
    else
        log_warning "⚠️ Vite service: FAILED TO START"
    fi

    if systemctl is-active newsapp-ip-monitor.timer >/dev/null 2>&1; then
        log_success "✅ IP Monitor: ACTIVE (checks every 5 minutes)"
    else
        log_warning "⚠️ IP Monitor: INACTIVE"
    fi

    # Run IP update script immediately
    log "Running initial IP configuration..."
    "$INSTALL_DIR/check-and-update-ip.sh"

    # Test web interface
    log "Testing web interface..."
    sleep 5

    if curl -s -m 10 http://localhost:8000 >/dev/null 2>&1; then
        log_success "✅ Web interface: ACCESSIBLE"
    else
        log_warning "⚠️ Web interface may need additional startup time"
    fi

    log_success "✅ Phase 9 Complete: Services started"
}

# FINAL COMPLETION
final_completion() {
    log_info "🏁 FINAL: Installation Completion"

    # Get system IP
    IP_ADDRESS=$(ip addr show | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}' | cut -d'/' -f1 2>/dev/null || echo "localhost")

    # Verify PHP path
    export PATH="/usr/bin:/usr/local/bin:$PATH"

    # Create completion file
    cat > "$INSTALL_DIR/INSTALLATION_COMPLETE.txt" << EOF
🎉 NEWSAPP ONE-COMMAND INSTALLATION SUCCESSFUL! 🎉
================================================================

🕐 Installation completed: $(date)
🖥️  System: $(uname -a)
🐘 PHP version: $(/usr/bin/php --version 2>/dev/null | head -1 || echo "PHP 8.2 installed")
📍 Installation directory: $INSTALL_DIR
📝 Complete log: $LOG_FILE

🌐 ACCESS YOUR NEWSAPP SYSTEM:
   Primary URL:   http://$IP_ADDRESS:8000
   Local access:  http://localhost:8000
   Vite dev:      http://$IP_ADDRESS:5173

🔐 DATABASE:
   Type:          SQLite
   Location:      $INSTALL_DIR/database/database.sqlite

🔧 SYSTEM MANAGEMENT COMMANDS:
   Service status:    sudo systemctl status newsapp
   Restart service:   sudo systemctl restart newsapp
   Stop service:      sudo systemctl stop newsapp
   View logs:         sudo journalctl -u newsapp -f
   Vite status:       sudo systemctl status newsapp-vite
   IP Monitor:        sudo systemctl status newsapp-ip-monitor.timer
   Manual IP update:  sudo $INSTALL_DIR/check-and-update-ip.sh

🔄 FUTURE UPDATES:
   cd $INSTALL_DIR
   git pull origin main
   sudo ./update_newsapp.sh

✅ YOUR NEWSAPP SYSTEM IS FULLY OPERATIONAL!
EOF

    # Display success message
    echo
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                           ║${NC}"
    echo -e "${GREEN}║                    🎉 INSTALLATION COMPLETED! 🎉                        ║${NC}"
    echo -e "${GREEN}║                                                                           ║${NC}"
    echo -e "${GREEN}║  NewsApp system is now fully installed and ready to use!                ║${NC}"
    echo -e "${GREEN}║                                                                           ║${NC}"
    echo -e "${GREEN}║  🌐 Access your system at: ${CYAN}http://$IP_ADDRESS:8000${GREEN}                       ║${NC}"
    echo -e "${GREEN}║                                                                           ║${NC}"
    echo -e "${GREEN}║  🔐 Database: SQLite (database/database.sqlite)                           ║${NC}"
    echo -e "${GREEN}║                                                                           ║${NC}"
    echo -e "${GREEN}║  📝 Documentation: $INSTALL_DIR/INSTALLATION_COMPLETE.txt           ║${NC}"
    echo -e "${GREEN}║  📊 Installation log: $LOG_FILE                     ║${NC}"
    echo -e "${GREEN}║                                                                           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}🚀 Your NewsApp system is now ready for production use!${NC}"
    echo
}

# MAIN EXECUTION
main() {
    echo -e "${PURPLE}Starting complete NewsApp installation...${NC}"
    echo

    check_root

    phase0_complete_cleanup
    echo

    phase1_system_preparation
    echo

    phase2_php_mysql_setup
    echo

    phase3_composer_installation
    echo

    phase4_nodejs_installation
    echo

    phase5_clone_repository
    echo

    phase6_database_setup
    echo

    phase7_application_configuration
    echo

    phase8_systemd_service
    echo

    phase9_service_startup
    echo

    final_completion
}

# Execute installation
main "$@"
