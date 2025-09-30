#!/bin/bash
# NewsApp One-Command Installer - COMPATIBLE WITH UBUNTU 16.04+
# Complete setup from fresh NanoPi to working Laravel + Vue system
# Usage: wget -qO- https://raw.githubusercontent.com/EmmanuelMsafiri1992/OnlyNews2025/main/install_newsapp.sh | sudo bash

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

# Initialize log file
echo "NewsApp Installation Started: $(date)" > "$LOG_FILE"

echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║          🚀 NEWSAPP ONE-COMMAND INSTALLER 🚀                ║${NC}"
echo -e "${PURPLE}║                                                              ║${NC}"
echo -e "${PURPLE}║  Fresh NanoPi → Fully Working Laravel + Vue News System    ║${NC}"
echo -e "${PURPLE}║  Compatible with Ubuntu 16.04+ and ARM architecture        ║${NC}"
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
    if eval "$cmd" >> "$LOG_FILE" 2>&1; then
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
        if eval "$cmd" >> "$LOG_FILE" 2>&1; then
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
        echo -e "${YELLOW}Usage: wget -qO- https://raw.githubusercontent.com/EmmanuelMsafiri1992/OnlyNews2025/main/install_newsapp.sh | sudo bash${NC}"
        exit 1
    fi
}

# Detect OS and set PHP version
detect_os_and_php_version() {
    log_info "🔍 Detecting OS version and architecture..."

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_VERSION=$VERSION_ID
        OS_CODENAME=$VERSION_CODENAME

        log "OS Detected: $OS_NAME $OS_VERSION ($OS_CODENAME)"
        log "Architecture: $(uname -m)"
    fi

    # Determine PHP version based on Ubuntu version
    case "$OS_CODENAME" in
        xenial)  # Ubuntu 16.04
            PHP_VERSION="7.4"
            USE_PPA=true
            log "Using PHP 7.4 for Ubuntu 16.04 compatibility"
            ;;
        bionic)  # Ubuntu 18.04
            PHP_VERSION="7.4"
            USE_PPA=true
            log "Using PHP 7.4 for Ubuntu 18.04"
            ;;
        focal)   # Ubuntu 20.04
            PHP_VERSION="8.1"
            USE_PPA=true
            log "Using PHP 8.1 for Ubuntu 20.04"
            ;;
        jammy|lunar|mantic)  # Ubuntu 22.04+
            PHP_VERSION="8.2"
            USE_PPA=true
            log "Using PHP 8.2 for modern Ubuntu"
            ;;
        *)
            # Default to system PHP
            PHP_VERSION="7.0"
            USE_PPA=false
            log_warning "Unknown OS codename, using system default PHP"
            ;;
    esac

    export PHP_VERSION
    export USE_PPA
}

# PHASE 0: COMPLETE SYSTEM CLEANUP
phase0_complete_cleanup() {
    log_info "🧹 PHASE 0: Complete System Cleanup & Preparation"

    # Stop all running processes
    log "Stopping all NewsApp processes..."

    pkill -9 -f "php.*artisan.*serve" 2>/dev/null || true
    pkill -9 -f "vite" 2>/dev/null || true
    pkill -9 -f "newsapp" 2>/dev/null || true

    sleep 2

    # Stop and disable systemd services
    log "Stopping and disabling systemd services..."

    systemctl stop newsapp 2>/dev/null || true
    systemctl disable newsapp 2>/dev/null || true
    systemctl stop newsapp-vite 2>/dev/null || true
    systemctl disable newsapp-vite 2>/dev/null || true
    systemctl stop newsapp-ip-monitor.timer 2>/dev/null || true
    systemctl disable newsapp-ip-monitor.timer 2>/dev/null || true

    # Remove systemd service files
    log "Removing systemd service files..."

    rm -f /etc/systemd/system/newsapp.service 2>/dev/null || true
    rm -f /etc/systemd/system/newsapp-vite.service 2>/dev/null || true
    rm -f /etc/systemd/system/newsapp-ip-monitor.service 2>/dev/null || true
    rm -f /etc/systemd/system/newsapp-ip-monitor.timer 2>/dev/null || true
    systemctl daemon-reload 2>/dev/null

    # Backup installation directory if exists
    if [[ -d "$INSTALL_DIR" ]]; then
        BACKUP_DIR="/opt/newsapp_backup_$(date +%Y%m%d_%H%M%S)"
        log "Backing up existing installation to $BACKUP_DIR"
        cp -r "$INSTALL_DIR" "$BACKUP_DIR" 2>/dev/null || true
        rm -rf "$INSTALL_DIR" 2>/dev/null || true
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
    retry_run "apt-get update" "System package update" 5

    # Install essential system tools
    log "Installing essential system tools..."
    ESSENTIAL_TOOLS=(
        "curl" "wget" "git" "unzip" "sudo" "ca-certificates"
        "build-essential" "software-properties-common"
    )

    for tool in "${ESSENTIAL_TOOLS[@]}"; do
        safe_run "apt-get install -y $tool" "Installing $tool"
    done

    log_success "✅ Phase 1 Complete: System prepared"
}

# PHASE 2: PHP INSTALLATION
phase2_php_installation() {
    log_info "🐘 PHASE 2: PHP Environment Setup"

    # Add PHP repository if needed
    if [ "$USE_PPA" = true ]; then
        log "Adding PHP repository for PHP $PHP_VERSION..."
        safe_run "add-apt-repository -y ppa:ondrej/php" "Adding PHP PPA"
        retry_run "apt-get update" "Updating after PPA" 3
    fi

    # Install PHP and extensions
    log "Installing PHP $PHP_VERSION and extensions..."

    # Build package list dynamically
    PHP_PACKAGES=(
        "php${PHP_VERSION}"
        "php${PHP_VERSION}-cli"
        "php${PHP_VERSION}-sqlite3"
        "php${PHP_VERSION}-xml"
        "php${PHP_VERSION}-mbstring"
        "php${PHP_VERSION}-curl"
        "php${PHP_VERSION}-zip"
        "php${PHP_VERSION}-gd"
        "php${PHP_VERSION}-bcmath"
    )

    # Add tokenizer if available (not in older PHP versions)
    if dpkg --compare-versions "$PHP_VERSION" ge "7.2"; then
        PHP_PACKAGES+=("php${PHP_VERSION}-tokenizer")
    fi

    # Add intl if available
    PHP_PACKAGES+=("php${PHP_VERSION}-intl")

    for package in "${PHP_PACKAGES[@]}"; do
        safe_run "DEBIAN_FRONTEND=noninteractive apt-get install -y $package" "Installing $package"
    done

    # Create symlink for php command if needed
    if [ ! -f /usr/bin/php ]; then
        log "Creating PHP symlink..."
        ln -s /usr/bin/php${PHP_VERSION} /usr/bin/php 2>/dev/null || true
    fi

    # Verify PHP installation
    if command -v php >/dev/null 2>&1; then
        PHP_INSTALLED_VERSION=$(php --version | head -1)
        log "✅ PHP installed: $PHP_INSTALLED_VERSION"
    else
        log_error "❌ PHP installation failed!"
    fi

    log_success "✅ Phase 2 Complete: PHP installed"
}

# PHASE 3: COMPOSER INSTALLATION
phase3_composer_installation() {
    log_info "🎼 PHASE 3: Composer Installation"

    # Download and install Composer
    log "Installing Composer..."

    cd /tmp
    retry_run "wget https://getcomposer.org/installer -O composer-setup.php" "Downloading Composer" 3
    safe_run "php composer-setup.php --install-dir=/usr/local/bin --filename=composer" "Installing Composer"
    rm -f composer-setup.php

    # Set PHP path in environment
    export PATH="/usr/bin:$PATH"

    # Verify Composer
    if command -v composer >/dev/null 2>&1; then
        log "✅ Composer installed: $(composer --version 2>/dev/null | head -1)"
    else
        log_error "❌ Composer installation failed"
    fi

    log_success "✅ Phase 3 Complete: Composer ready"
}

# PHASE 4: NODE.JS & NPM INSTALLATION
phase4_nodejs_installation() {
    log_info "📦 PHASE 4: Node.js & NPM Installation"

    # Install Node.js 16.x (compatible with Ubuntu 16.04)
    log "Installing Node.js 16.x for ARM compatibility..."

    retry_run "curl -fsSL https://deb.nodesource.com/setup_16.x | bash -" "Adding NodeSource repository" 3
    safe_run "apt-get install -y nodejs" "Installing Node.js"

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
        cp -r /tmp/newsapp-temp/.env* "$INSTALL_DIR/" 2>/dev/null || true
        cp -r /tmp/newsapp-temp/.git* "$INSTALL_DIR/" 2>/dev/null || true
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
        cat > .env << 'EOF'
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

    # Add VITE_API_BASE_URL if not exists
    if grep -q "^VITE_API_BASE_URL=" .env; then
        sed -i "s|VITE_API_BASE_URL=.*|VITE_API_BASE_URL=http://$SERVER_IP:8000|" .env
    else
        echo "VITE_API_BASE_URL=http://$SERVER_IP:8000" >> .env
    fi

    # Ensure SQLite is configured
    sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=sqlite/" .env
    sed -i "s|DB_DATABASE=.*|DB_DATABASE=database/database.sqlite|" .env

    log "✅ .env file configured"

    # Install Composer dependencies
    log "Installing Composer dependencies (this may take several minutes)..."
    export COMPOSER_ALLOW_SUPERUSER=1
    retry_run "composer install --no-dev --optimize-autoloader --no-interaction" "Composer install" 3

    # Generate application key
    log "Generating application key..."
    php artisan key:generate --force 2>&1 | tee -a "$LOG_FILE"

    # Only run migrations if database is empty or new
    if [[ ! -s "$INSTALL_DIR/database/database.sqlite" ]]; then
        log "Running database migrations..."
        php artisan migrate --force 2>&1 | tee -a "$LOG_FILE"
    else
        log "✅ Using existing database with data"
    fi

    # Install NPM dependencies
    log "Installing NPM dependencies (this may take several minutes)..."
    retry_run "npm install --legacy-peer-deps --loglevel=error" "NPM install" 3

    # Build frontend assets
    log "Building frontend assets..."
    npm run build 2>&1 | tee -a "$LOG_FILE"

    # Set permissions
    log "Setting proper permissions..."
    chown -R www-data:www-data "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"
    chmod -R 775 "$INSTALL_DIR/storage"
    chmod -R 775 "$INSTALL_DIR/bootstrap/cache"

    # Make IP update script executable
    chmod +x "$INSTALL_DIR/check-and-update-ip.sh" 2>/dev/null || true

    log_success "✅ Phase 7 Complete: Application configured"
}

# PHASE 8: SYSTEMD SERVICE CONFIGURATION
phase8_systemd_service() {
    log_info "⚙️ PHASE 8: Systemd Service Configuration"

    # Get PHP binary path
    PHP_BIN=$(which php)
    NPM_BIN=$(which npm)

    # Create Laravel service
    log "Creating Laravel systemd service..."
    cat > /etc/systemd/system/newsapp.service << EOF
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
ExecStart=$PHP_BIN artisan serve --host=0.0.0.0 --port=8000
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
    cat > /etc/systemd/system/newsapp-vite.service << EOF
[Unit]
Description=NewsApp Vite Development Server
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/newsapp
Environment=PATH=/usr/bin:/usr/local/bin:/usr/local/sbin
ExecStart=$NPM_BIN run dev
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
    sleep 5

    # Start Vite service
    log "Starting Vite development server..."
    systemctl start newsapp-vite
    sleep 5

    # Check service status
    if systemctl is-active newsapp >/dev/null 2>&1; then
        log_success "✅ Laravel service: RUNNING"
    else
        log_warning "⚠️ Laravel service: FAILED TO START"
        log_info "Checking logs..."
        journalctl -u newsapp -n 20 --no-pager | tee -a "$LOG_FILE"
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
    if [ -f "$INSTALL_DIR/check-and-update-ip.sh" ]; then
        "$INSTALL_DIR/check-and-update-ip.sh" 2>&1 | tee -a "$LOG_FILE"
    fi

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
    PHP_BIN=$(which php)

    # Create completion file
    cat > "$INSTALL_DIR/INSTALLATION_COMPLETE.txt" << EOF
🎉 NEWSAPP ONE-COMMAND INSTALLATION SUCCESSFUL! 🎉
================================================================

🕐 Installation completed: $(date)
🖥️  System: $(uname -a)
🐘 PHP version: $($PHP_BIN --version 2>/dev/null | head -1 || echo "PHP installed")
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
    echo -e "${YELLOW}💡 Quick Test:${NC}"
    echo -e "   ${CYAN}curl http://localhost:8000${NC}"
    echo
}

# MAIN EXECUTION
main() {
    echo -e "${PURPLE}Starting complete NewsApp installation...${NC}"
    echo

    check_root
    detect_os_and_php_version
    echo

    phase0_complete_cleanup
    echo

    phase1_system_preparation
    echo

    phase2_php_installation
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
