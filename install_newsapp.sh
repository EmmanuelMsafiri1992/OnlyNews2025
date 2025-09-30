#!/bin/bash
# NewsApp One-Command Installer - AUTOMATIC UBUNTU UPGRADE + PHP 8.2
# Complete setup from fresh NanoPi to working Laravel + Vue system
# Automatically upgrades Ubuntu 16.04 → 20.04 → 22.04 if needed
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
UPGRADE_MARKER="/tmp/newsapp_upgrade_in_progress"

# Initialize log file
echo "NewsApp Installation Started: $(date)" > "$LOG_FILE"

echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║          🚀 NEWSAPP ONE-COMMAND INSTALLER 🚀                ║${NC}"
echo -e "${PURPLE}║                                                              ║${NC}"
echo -e "${PURPLE}║  Fresh NanoPi → Fully Working Laravel + Vue News System    ║${NC}"
echo -e "${PURPLE}║  Auto-upgrades Ubuntu + Installs PHP 8.2 for Laravel 12    ║${NC}"
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

# Detect OS and determine if upgrade is needed
detect_os_and_requirements() {
    log_info "🔍 Detecting OS version and requirements..."

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_VERSION=$VERSION_ID
        OS_CODENAME=$VERSION_CODENAME

        log "OS Detected: $OS_NAME $OS_VERSION ($OS_CODENAME)"
        log "Architecture: $(uname -m)"
        log "Kernel: $(uname -r)"
    fi

    # Check Laravel requirements: PHP 8.0+ (Laravel 11)
    REQUIRES_PHP="8.0"
    REQUIRES_UBUNTU_MIN="16.04"

    # Determine PHP version based on Ubuntu version (no upgrade needed!)
    case "$OS_CODENAME" in
        xenial)  # Ubuntu 16.04 - Use PHP 7.4 (maximum available)
            NEEDS_UPGRADE=false
            PHP_VERSION="7.4"
            log "✅ Ubuntu 16.04 - Using PHP 7.4 (maximum available)"
            ;;
        bionic)  # Ubuntu 18.04 - Use PHP 8.0
            NEEDS_UPGRADE=false
            PHP_VERSION="8.0"
            log "✅ Ubuntu 18.04 - Compatible with PHP 8.0"
            ;;
        focal)   # Ubuntu 20.04 - Use PHP 8.1
            NEEDS_UPGRADE=false
            PHP_VERSION="8.1"
            log "✅ Ubuntu 20.04 - Compatible with PHP 8.1"
            ;;
        jammy|lunar|mantic|noble)  # Ubuntu 22.04+ - Use PHP 8.2
            NEEDS_UPGRADE=false
            PHP_VERSION="8.2"
            log "✅ Modern Ubuntu detected - Compatible with PHP 8.2"
            ;;
        *)
            NEEDS_UPGRADE=false
            PHP_VERSION="7.4"
            log_warning "Unknown Ubuntu version - Will attempt PHP 7.4 installation"
            ;;
    esac

    export NEEDS_UPGRADE
    export TARGET_VERSION
    export PHP_VERSION
    export OS_CODENAME
}

# PHASE -1: UBUNTU UPGRADE (if needed)
phase_ubuntu_upgrade() {
    if [ "$NEEDS_UPGRADE" != "true" ]; then
        log "✅ Ubuntu version is compatible, skipping upgrade"
        return 0
    fi

    log_info "🔄 PHASE -1: Ubuntu System Upgrade"

    echo
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                                                               ║${NC}"
    echo -e "${YELLOW}║  ⚠️  UBUNTU UPGRADE REQUIRED                                 ║${NC}"
    echo -e "${YELLOW}║                                                               ║${NC}"
    echo -e "${YELLOW}║  Your system needs to upgrade from Ubuntu $OS_VERSION to $TARGET_VERSION   ║${NC}"
    echo -e "${YELLOW}║  This is required for PHP 8.2 (Laravel 12 requirement)       ║${NC}"
    echo -e "${YELLOW}║                                                               ║${NC}"
    echo -e "${YELLOW}║  The upgrade will:                                           ║${NC}"
    echo -e "${YELLOW}║  - Take 30-60 minutes                                        ║${NC}"
    echo -e "${YELLOW}║  - Require internet connection                               ║${NC}"
    echo -e "${YELLOW}║  - May require system reboot                                 ║${NC}"
    echo -e "${YELLOW}║  - Automatically resume installation after reboot            ║${NC}"
    echo -e "${YELLOW}║                                                               ║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo

    # Check if running in interactive mode
    if [ -t 0 ]; then
        # Interactive - ask for confirmation
        read -p "$(echo -e ${CYAN}Continue with Ubuntu upgrade? [y/N]: ${NC})" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "Ubuntu upgrade cancelled by user"
            echo -e "${RED}Installation cannot continue without Ubuntu upgrade.${NC}"
            echo -e "${YELLOW}Laravel 12 requires PHP 8.2, which needs Ubuntu 20.04+${NC}"
            exit 1
        fi
    else
        # Non-interactive (piped from wget/curl) - auto-proceed
        log_warning "Non-interactive mode detected - proceeding with automatic Ubuntu upgrade..."
        echo -e "${CYAN}Automatically proceeding with Ubuntu upgrade in 10 seconds...${NC}"
        echo -e "${CYAN}Press Ctrl+C now to cancel!${NC}"
        sleep 10
    fi

    # Create upgrade marker for resuming after reboot
    cat > "$UPGRADE_MARKER" << EOF
STAGE=upgrade_complete
REPO_URL=$REPO_URL
INSTALL_DIR=$INSTALL_DIR
LOG_FILE=$LOG_FILE
EOF

    # Install update-manager-core if not present
    log "Installing update-manager-core..."
    safe_run "DEBIAN_FRONTEND=noninteractive apt-get update" "Updating package list"
    safe_run "DEBIAN_FRONTEND=noninteractive apt-get install -y update-manager-core" "Installing update-manager-core"

    # Configure for non-interactive upgrade
    log "Configuring non-interactive upgrade..."
    sed -i 's/Prompt=.*/Prompt=normal/' /etc/update-manager/release-upgrades 2>/dev/null || true

    # Set environment for non-interactive
    export DEBIAN_FRONTEND=noninteractive
    export DEBIAN_PRIORITY=critical

    # Perform upgrade
    log_info "Starting Ubuntu upgrade to $TARGET_VERSION (this will take 30-60 minutes)..."
    echo
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Starting OS upgrade... You can monitor progress below.${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo

    # Run upgrade with auto-confirmation
    do-release-upgrade -f DistUpgradeViewNonInteractive 2>&1 | tee -a "$LOG_FILE"

    UPGRADE_RESULT=$?

    if [ $UPGRADE_RESULT -eq 0 ]; then
        log_success "✅ Ubuntu upgrade completed successfully!"

        # Update marker
        sed -i 's/STAGE=.*/STAGE=after_upgrade/' "$UPGRADE_MARKER"

        # Check if reboot is needed
        if [ -f /var/run/reboot-required ]; then
            log_warning "System reboot required to complete upgrade"

            # Create systemd service to resume installation after reboot
            cat > /etc/systemd/system/newsapp-resume-install.service << 'EOFSERVICE'
[Unit]
Description=Resume NewsApp Installation After Upgrade
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c "wget -qO- https://raw.githubusercontent.com/EmmanuelMsafiri1992/OnlyNews2025/main/install_newsapp.sh | bash"
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOFSERVICE

            systemctl enable newsapp-resume-install.service

            echo
            echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║                                                               ║${NC}"
            echo -e "${GREEN}║  ✅ Ubuntu upgrade successful!                               ║${NC}"
            echo -e "${GREEN}║                                                               ║${NC}"
            echo -e "${GREEN}║  System will reboot in 10 seconds...                         ║${NC}"
            echo -e "${GREEN}║  Installation will automatically resume after reboot          ║${NC}"
            echo -e "${GREEN}║                                                               ║${NC}"
            echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
            echo

            sleep 10
            reboot
            exit 0
        else
            log_success "✅ Upgrade complete, no reboot required"
            rm -f "$UPGRADE_MARKER"
        fi
    else
        log_error "Ubuntu upgrade failed or was cancelled"
        echo -e "${RED}Upgrade failed. Please check $LOG_FILE for details.${NC}"
        exit 1
    fi
}

# Check if resuming after upgrade
check_resume_after_upgrade() {
    if [ -f "$UPGRADE_MARKER" ]; then
        . "$UPGRADE_MARKER"

        if [ "$STAGE" = "after_upgrade" ]; then
            log_info "Resuming installation after Ubuntu upgrade..."

            # Disable the resume service
            systemctl disable newsapp-resume-install.service 2>/dev/null || true
            rm -f /etc/systemd/system/newsapp-resume-install.service
            rm -f "$UPGRADE_MARKER"

            # Re-detect OS
            detect_os_and_requirements

            log_success "✅ Resumed after upgrade - Now on Ubuntu $(lsb_release -rs)"
            return 0
        fi
    fi
    return 1
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
        safe_run "DEBIAN_FRONTEND=noninteractive apt-get install -y $tool" "Installing $tool"
    done

    log_success "✅ Phase 1 Complete: System prepared"
}

# PHASE 2: PHP INSTALLATION
phase2_php_installation() {
    log_info "🐘 PHASE 2: PHP $PHP_VERSION Environment Setup"

    # Add PHP repository
    log "Adding PHP repository..."
    safe_run "add-apt-repository -y ppa:ondrej/php" "Adding PHP PPA"
    retry_run "apt-get update" "Updating after PPA" 3

    # Install PHP and extensions
    log "Installing PHP $PHP_VERSION and required extensions..."

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
        "php${PHP_VERSION}-intl"
    )

    # Add tokenizer if PHP 7.2+
    if dpkg --compare-versions "$PHP_VERSION" ge "7.2"; then
        PHP_PACKAGES+=("php${PHP_VERSION}-tokenizer")
    fi

    for package in "${PHP_PACKAGES[@]}"; do
        safe_run "DEBIAN_FRONTEND=noninteractive apt-get install -y $package" "Installing $package"
    done

    # Create symlink for php command if needed
    if [ ! -f /usr/bin/php ]; then
        log "Creating PHP $PHP_VERSION symlink..."
        update-alternatives --set php /usr/bin/php${PHP_VERSION} 2>/dev/null || ln -sf /usr/bin/php${PHP_VERSION} /usr/bin/php
    fi

    # Verify PHP installation
    if command -v php >/dev/null 2>&1; then
        PHP_INSTALLED_VERSION=$(php --version | head -1)
        log "✅ PHP installed: $PHP_INSTALLED_VERSION"

        # Verify it's 7.4+
        PHP_MAJOR=$(php -r 'echo PHP_MAJOR_VERSION;')
        PHP_MINOR=$(php -r 'echo PHP_MINOR_VERSION;')

        if [ "$PHP_MAJOR" -eq 7 ] && [ "$PHP_MINOR" -ge 4 ]; then
            log_success "✅ PHP 7.4+ confirmed - Laravel 9+ compatible"
        elif [ "$PHP_MAJOR" -ge 8 ]; then
            log_success "✅ PHP 8.0+ confirmed - Laravel 9+ compatible"
        else
            log_error "❌ PHP version too old (requires PHP 7.4+)"
            exit 1
        fi
    else
        log_error "❌ PHP installation failed!"
        exit 1
    fi

    log_success "✅ Phase 2 Complete: PHP $PHP_VERSION installed"
}

# PHASE 3: COMPOSER INSTALLATION
phase3_composer_installation() {
    log_info "🎼 PHASE 3: Composer Installation"

    log "Installing Composer..."
    cd /tmp
    retry_run "wget https://getcomposer.org/installer -O composer-setup.php" "Downloading Composer" 3
    safe_run "php composer-setup.php --install-dir=/usr/local/bin --filename=composer" "Installing Composer"
    rm -f composer-setup.php

    export PATH="/usr/bin:$PATH"

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

    log "Installing Node.js 18.x LTS..."
    retry_run "curl -fsSL https://deb.nodesource.com/setup_18.x | bash -" "Adding NodeSource repository" 3
    safe_run "apt-get install -y nodejs" "Installing Node.js"

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

    log "Cloning NewsApp repository..."
    cd /tmp
    retry_run "git clone $REPO_URL newsapp-temp" "Cloning repository" 3

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

    if [[ -f "$INSTALL_DIR/database/database.sqlite" ]]; then
        log "✅ SQLite database found in repository"
        log "✅ Using SQLite database from repository"
        chmod 664 "$INSTALL_DIR/database/database.sqlite"
    else
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
    export PATH="/usr/bin:/usr/local/bin:$PATH"

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

    SERVER_IP=$(ip addr show | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}' | cut -d'/' -f1 2>/dev/null || echo "localhost")

    sed -i "s|APP_URL=.*|APP_URL=http://$SERVER_IP:8000|" .env

    if grep -q "^VITE_API_BASE_URL=" .env; then
        sed -i "s|VITE_API_BASE_URL=.*|VITE_API_BASE_URL=http://$SERVER_IP:8000|" .env
    else
        echo "VITE_API_BASE_URL=http://$SERVER_IP:8000" >> .env
    fi

    sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=sqlite/" .env
    sed -i "s|DB_DATABASE=.*|DB_DATABASE=database/database.sqlite|" .env

    log "✅ .env file configured"

    log "Installing Composer dependencies (this may take several minutes)..."
    export COMPOSER_ALLOW_SUPERUSER=1
    retry_run "composer install --no-dev --optimize-autoloader --no-interaction" "Composer install" 3

    log "Generating application key..."
    php artisan key:generate --force 2>&1 | tee -a "$LOG_FILE"

    if [[ ! -s "$INSTALL_DIR/database/database.sqlite" ]]; then
        log "Running database migrations..."
        php artisan migrate --force 2>&1 | tee -a "$LOG_FILE"
    else
        log "✅ Using existing database with data"
    fi

    log "Installing NPM dependencies (this may take several minutes)..."
    retry_run "npm install --legacy-peer-deps --loglevel=error" "NPM install" 3

    log "Building frontend assets..."
    npm run build 2>&1 | tee -a "$LOG_FILE"

    log "Setting proper permissions..."
    chown -R www-data:www-data "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"
    chmod -R 775 "$INSTALL_DIR/storage"
    chmod -R 775 "$INSTALL_DIR/bootstrap/cache"
    chmod +x "$INSTALL_DIR/check-and-update-ip.sh" 2>/dev/null || true

    log_success "✅ Phase 7 Complete: Application configured"
}

# PHASE 8: SYSTEMD SERVICE CONFIGURATION
phase8_systemd_service() {
    log_info "⚙️ PHASE 8: Systemd Service Configuration"

    PHP_BIN=$(which php)
    NPM_BIN=$(which npm)

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

    log "Starting NewsApp Laravel service..."
    systemctl start newsapp
    sleep 5

    log "Starting Vite development server..."
    systemctl start newsapp-vite
    sleep 5

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

    log "Running initial IP configuration..."
    if [ -f "$INSTALL_DIR/check-and-update-ip.sh" ]; then
        "$INSTALL_DIR/check-and-update-ip.sh" 2>&1 | tee -a "$LOG_FILE"
    fi

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

    IP_ADDRESS=$(ip addr show | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}' | cut -d'/' -f1 2>/dev/null || echo "localhost")
    export PATH="/usr/bin:/usr/local/bin:$PATH"
    PHP_BIN=$(which php)

    cat > "$INSTALL_DIR/INSTALLATION_COMPLETE.txt" << EOF
🎉 NEWSAPP ONE-COMMAND INSTALLATION SUCCESSFUL! 🎉
================================================================

🕐 Installation completed: $(date)
🖥️  System: $(uname -a)
💿 OS Version: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
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

    echo
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                           ║${NC}"
    echo -e "${GREEN}║                    🎉 INSTALLATION COMPLETED! 🎉                        ║${NC}"
    echo -e "${GREEN}║                                                                           ║${NC}"
    echo -e "${GREEN}║  NewsApp system is now fully installed and ready to use!                ║${NC}"
    echo -e "${GREEN}║                                                                           ║${NC}"
    echo -e "${GREEN}║  🌐 Access your system at: ${CYAN}http://$IP_ADDRESS:8000${GREEN}                       ║${NC}"
    echo -e "${GREEN}║                                                                           ║${NC}"
    echo -e "${GREEN}║  🐘 PHP Version: $(php -r 'echo PHP_VERSION;')                                                ║${NC}"
    echo -e "${GREEN}║  💿 OS Version: $(lsb_release -rs 2>/dev/null || echo 'Linux')                                                  ║${NC}"
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

    # Check if resuming after reboot
    if check_resume_after_upgrade; then
        log_info "Continuing installation after OS upgrade..."
    else
        detect_os_and_requirements
        echo

        # Perform Ubuntu upgrade if needed
        if [ "$NEEDS_UPGRADE" = "true" ]; then
            phase_ubuntu_upgrade
            # After upgrade, script will either reboot or continue
        fi
    fi

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
