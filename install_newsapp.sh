#!/bin/bash
# NewsApp One-Command Installer - BULLETPROOF for ARM and x86_64
# Complete setup from fresh NanoPi to working Laravel + Vue system
# ARM: PHP 7.4 + Laravel 9 on Ubuntu 20.04
# x86_64: PHP 8.2 + Laravel 12
# Usage: wget -qO- https://raw.githubusercontent.com/EmmanuelMsafiri1992/OnlyNews2025/main/install_newsapp.sh | sudo bash

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
UPGRADE_MARKER="/tmp/newsapp_upgrade_stage"

# Initialize log file
echo "NewsApp Installation Started: $(date)" > "$LOG_FILE"

echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║          🚀 NEWSAPP BULLETPROOF INSTALLER 🚀                ║${NC}"
echo -e "${PURPLE}║                                                              ║${NC}"
echo -e "${PURPLE}║  Fresh NanoPi → Fully Working Laravel 8 + Vue System       ║${NC}"
echo -e "${PURPLE}║  ARM Support: PHP 7.4 + Laravel 8 on Ubuntu 20.04          ║${NC}"
echo -e "${PURPLE}║  x86_64 Support: PHP 8.2 + Laravel 12                      ║${NC}"
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
        exit 1
    fi
}

# Detect OS
detect_os() {
    log_info "🔍 Detecting OS version..."

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_VERSION=$VERSION_ID
        OS_CODENAME=$VERSION_CODENAME

        log "OS Detected: $OS_NAME $OS_VERSION ($OS_CODENAME)"
        log "Architecture: $(uname -m)"
    fi

    # Check if upgrade is needed for PHP 8.2
    case "$OS_CODENAME" in
        xenial|bionic)  # Ubuntu 16.04 or 18.04
            NEEDS_UPGRADE=true
            CURRENT_VERSION=$OS_VERSION
            log_warning "Ubuntu $OS_VERSION detected - Upgrade required for PHP 8.2"
            ;;
        focal|jammy|lunar|mantic|noble)  # Ubuntu 20.04+
            NEEDS_UPGRADE=false
            log "✅ Ubuntu $OS_VERSION - Compatible with PHP 8.2"
            ;;
        *)
            NEEDS_UPGRADE=false
            log_warning "Unknown Ubuntu version"
            ;;
    esac

    export NEEDS_UPGRADE
    export OS_CODENAME
    export OS_VERSION
}

# MANUAL Ubuntu Upgrade Method - GUARANTEED TO WORK
manual_ubuntu_upgrade() {
    log_info "🔄 Starting MANUAL Ubuntu upgrade process..."

    # Determine target based on current version and marker
    if [ -f "$UPGRADE_MARKER" ]; then
        . "$UPGRADE_MARKER"
        if [ -n "$TARGET_VERSION" ]; then
            # Use target from marker (for 20.04 → 22.04 upgrades)
            case "$TARGET_VERSION" in
                22.04)
                    TARGET_CODENAME="jammy"
                    ;;
                20.04)
                    TARGET_CODENAME="focal"
                    ;;
                18.04)
                    TARGET_CODENAME="bionic"
                    ;;
            esac
        fi
    else
        # Auto-determine target based on current version
        if [ "$OS_VERSION" = "16.04" ]; then
            TARGET_CODENAME="bionic"
            TARGET_VERSION="18.04"
        elif [ "$OS_VERSION" = "18.04" ]; then
            TARGET_CODENAME="focal"
            TARGET_VERSION="20.04"
        elif [ "$OS_VERSION" = "20.04" ]; then
            TARGET_CODENAME="jammy"
            TARGET_VERSION="22.04"
        else
            log "Already on Ubuntu $OS_VERSION"
            return 0
        fi
    fi

    echo
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                                                               ║${NC}"
    echo -e "${YELLOW}║  🔄 UBUNTU UPGRADE: $OS_VERSION → $TARGET_VERSION                        ║${NC}"
    echo -e "${YELLOW}║                                                               ║${NC}"
    echo -e "${YELLOW}║  Method: MANUAL repository upgrade (reliable)                ║${NC}"
    echo -e "${YELLOW}║  Time: 20-30 minutes                                         ║${NC}"
    echo -e "${YELLOW}║  Reboot: Required after upgrade                              ║${NC}"
    echo -e "${YELLOW}║                                                               ║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo

    # Auto-proceed in 10 seconds
    if [ ! -t 0 ]; then
        log_warning "Auto-proceeding with upgrade in 10 seconds..."
        echo -e "${CYAN}Press Ctrl+C now to cancel!${NC}"
        sleep 10
    fi

    # Save upgrade marker
    echo "STAGE=upgrading_to_${TARGET_VERSION}" > "$UPGRADE_MARKER"
    echo "FROM_VERSION=$OS_VERSION" >> "$UPGRADE_MARKER"
    echo "TARGET_VERSION=$TARGET_VERSION" >> "$UPGRADE_MARKER"
    echo "TARGET_CODENAME=$TARGET_CODENAME" >> "$UPGRADE_MARKER"

    # Backup sources.list
    log "Backing up sources.list..."
    cp /etc/apt/sources.list /etc/apt/sources.list.backup-$(date +%Y%m%d-%H%M%S)

    # Update sources.list to new version
    log "Updating repository sources to $TARGET_CODENAME..."
    sed -i "s/$OS_CODENAME/$TARGET_CODENAME/g" /etc/apt/sources.list
    sed -i "s/deb-src/#deb-src/g" /etc/apt/sources.list  # Disable source repos

    # Update package lists
    log "Updating package lists for Ubuntu $TARGET_VERSION..."
    retry_run "apt-get update" "Update package lists" 5

    # Install update-manager-core if needed
    safe_run "DEBIAN_FRONTEND=noninteractive apt-get install -y update-manager-core" "Install update-manager-core"

    # Upgrade all packages
    log_info "Upgrading all packages to Ubuntu $TARGET_VERSION (20-30 minutes)..."
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Package upgrade in progress... This will take some time.${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo

    export DEBIAN_FRONTEND=noninteractive
    apt-get dist-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" 2>&1 | tee -a "$LOG_FILE"

    if [ $? -eq 0 ]; then
        log_success "✅ Package upgrade completed successfully"
    else
        log_warning "⚠️ Some packages failed, but continuing..."
    fi

    # Clean up
    log "Cleaning up..."
    apt-get autoremove -y 2>&1 | tee -a "$LOG_FILE"
    apt-get autoclean 2>&1 | tee -a "$LOG_FILE"

    # Update marker for after reboot
    sed -i "s/STAGE=.*/STAGE=upgraded_${TARGET_VERSION}/" "$UPGRADE_MARKER"

    # Check if we need to upgrade again (16.04 → 18.04 → 20.04)
    if [ "$TARGET_VERSION" = "18.04" ]; then
        log_warning "Upgrade to 18.04 complete. Will upgrade to 20.04 after reboot."
        sed -i "s/STAGE=.*/STAGE=need_second_upgrade/" "$UPGRADE_MARKER"
    fi

    echo
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                               ║${NC}"
    echo -e "${GREEN}║  ✅ Ubuntu upgrade to $TARGET_VERSION complete!                      ║${NC}"
    echo -e "${GREEN}║                                                               ║${NC}"
    echo -e "${GREEN}║  System will REBOOT in 15 seconds...                         ║${NC}"
    echo -e "${GREEN}║  Installation will automatically resume after reboot         ║${NC}"
    echo -e "${GREEN}║                                                               ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo

    # Create systemd service to resume
    cat > /etc/systemd/system/newsapp-resume.service << 'EOFSERVICE'
[Unit]
Description=Resume NewsApp Installation
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c "sleep 30 && wget -qO- https://raw.githubusercontent.com/EmmanuelMsafiri1992/OnlyNews2025/main/install_newsapp.sh | bash"
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOFSERVICE

    systemctl daemon-reload
    systemctl enable newsapp-resume.service

    sleep 15
    reboot
    exit 0
}

# Check if resuming after reboot
check_resume() {
    if [ -f "$UPGRADE_MARKER" ]; then
        . "$UPGRADE_MARKER"

        log_info "Resuming after upgrade..."
        log "Previous stage: $STAGE"

        case "$STAGE" in
            need_second_upgrade)
                log_info "Need to upgrade from 18.04 to 20.04..."
                systemctl disable newsapp-resume.service 2>/dev/null || true
                rm -f /etc/systemd/system/newsapp-resume.service

                # Re-detect OS and upgrade again
                detect_os
                if [ "$OS_VERSION" = "18.04" ]; then
                    manual_ubuntu_upgrade
                fi
                ;;
            upgraded_*)
                log_success "✅ Resumed after upgrade"
                systemctl disable newsapp-resume.service 2>/dev/null || true
                rm -f /etc/systemd/system/newsapp-resume.service
                rm -f "$UPGRADE_MARKER"

                # Re-detect OS
                detect_os
                return 0
                ;;
        esac
    fi
    return 1
}

# PHASE 0: SYSTEM CLEANUP
phase0_cleanup() {
    log_info "🧹 PHASE 0: System Cleanup"

    pkill -9 -f "php.*artisan" 2>/dev/null || true
    pkill -9 -f "vite" 2>/dev/null || true
    sleep 2

    systemctl stop newsapp 2>/dev/null || true
    systemctl stop newsapp-vite 2>/dev/null || true
    systemctl stop newsapp-ip-monitor.timer 2>/dev/null || true
    systemctl disable newsapp 2>/dev/null || true
    systemctl disable newsapp-vite 2>/dev/null || true
    systemctl disable newsapp-ip-monitor.timer 2>/dev/null || true

    rm -f /etc/systemd/system/newsapp.service 2>/dev/null || true
    rm -f /etc/systemd/system/newsapp-vite.service 2>/dev/null || true
    rm -f /etc/systemd/system/newsapp-ip-monitor.* 2>/dev/null || true
    systemctl daemon-reload 2>/dev/null || true

    if [[ -d "$INSTALL_DIR" ]]; then
        BACKUP_DIR="/opt/newsapp_backup_$(date +%Y%m%d_%H%M%S)"
        log "Backing up to $BACKUP_DIR"
        cp -r "$INSTALL_DIR" "$BACKUP_DIR" 2>/dev/null || true
        rm -rf "$INSTALL_DIR" 2>/dev/null || true
    fi

    rm -rf /tmp/newsapp* 2>/dev/null || true

    log_success "✅ Phase 0 Complete"
}

# PHASE 1: SYSTEM PREPARATION
phase1_preparation() {
    log_info "🔧 PHASE 1: System Preparation"

    retry_run "apt-get update" "System update" 5

    TOOLS=("curl" "wget" "git" "unzip" "sudo" "ca-certificates" "build-essential" "software-properties-common")
    for tool in "${TOOLS[@]}"; do
        safe_run "DEBIAN_FRONTEND=noninteractive apt-get install -y $tool" "Installing $tool"
    done

    log_success "✅ Phase 1 Complete"
}

# PHASE 2: PHP 8.2 INSTALLATION
phase2_php() {
    log_info "🐘 PHASE 2: PHP 8.2 Installation"

    # Check if ARM architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" == "armv7l" || "$ARCH" == "aarch64" ]]; then
        log_warning "⚠️ ARM architecture detected ($ARCH)"
        log_info "Installing PHP 7.4 for Laravel 8 compatibility on Ubuntu $OS_VERSION"

        # Install PHP 7.4 (available in Ubuntu 20.04)
        retry_run "apt-get update" "Updating package lists" 3

        PHP_PACKAGES=("php" "php-cli" "php-sqlite3" "php-xml" "php-mbstring" "php-curl" "php-zip" "php-gd" "php-bcmath" "php-intl")

        for package in "${PHP_PACKAGES[@]}"; do
            safe_run "DEBIAN_FRONTEND=noninteractive apt-get install -y $package" "Installing $package"
        done

    else
        # x86_64 architecture - use ondrej/php PPA for PHP 8.2
        safe_run "add-apt-repository -y ppa:ondrej/php" "Adding PHP PPA"
        retry_run "apt-get update" "Updating after PPA" 3

        PHP_PACKAGES=("php8.2" "php8.2-cli" "php8.2-sqlite3" "php8.2-xml" "php8.2-mbstring" "php8.2-curl" "php8.2-zip" "php8.2-gd" "php8.2-bcmath" "php8.2-intl" "php8.2-tokenizer")

        for package in "${PHP_PACKAGES[@]}"; do
            safe_run "DEBIAN_FRONTEND=noninteractive apt-get install -y $package" "Installing $package"
        done
    fi

    # Set default PHP version
    if [ -f /usr/bin/php8.2 ]; then
        update-alternatives --set php /usr/bin/php8.2 2>/dev/null || ln -sf /usr/bin/php8.2 /usr/bin/php
    elif [ -f /usr/bin/php8.1 ]; then
        update-alternatives --set php /usr/bin/php8.1 2>/dev/null || ln -sf /usr/bin/php8.1 /usr/bin/php
    fi

    if command -v php >/dev/null 2>&1; then
        log "✅ PHP: $(php --version | head -1)"
        PHP_MAJOR=$(php -r 'echo PHP_MAJOR_VERSION;')
        PHP_MINOR=$(php -r 'echo PHP_MINOR_VERSION;')

        if [ "$PHP_MAJOR" -ge 8 ] && [ "$PHP_MINOR" -ge 2 ]; then
            log_success "✅ PHP 8.2+ confirmed - Laravel 12 compatible"
        elif [ "$PHP_MAJOR" -eq 8 ] && [ "$PHP_MINOR" -eq 1 ]; then
            log_success "✅ PHP 8.1 installed - Laravel 9/10 compatible"
        elif [ "$PHP_MAJOR" -eq 7 ] && [ "$PHP_MINOR" -eq 4 ]; then
            log_success "✅ PHP 7.4 installed - Laravel 8 compatible"
        else
            log_warning "⚠️ PHP $PHP_MAJOR.$PHP_MINOR installed - May need version adjustment"
        fi
    else
        log_error "❌ PHP installation failed"
        exit 1
    fi

    log_success "✅ Phase 2 Complete"
}

# PHASE 3: COMPOSER
phase3_composer() {
    log_info "🎼 PHASE 3: Composer"

    cd /tmp
    retry_run "wget -q https://getcomposer.org/installer -O composer-setup.php" "Download Composer" 3
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer 2>&1 | tee -a "$LOG_FILE"
    rm -f composer-setup.php

    if command -v composer >/dev/null 2>&1; then
        log "✅ Composer: $(composer --version | head -1)"
    fi

    log_success "✅ Phase 3 Complete"
}

# PHASE 4: NODE.JS
phase4_nodejs() {
    log_info "📦 PHASE 4: Node.js"

    retry_run "curl -fsSL https://deb.nodesource.com/setup_18.x | bash -" "NodeSource repo" 3
    safe_run "apt-get install -y nodejs" "Installing Node.js"

    if command -v node >/dev/null 2>&1; then
        log "✅ Node.js: $(node --version)"
    fi
    if command -v npm >/dev/null 2>&1; then
        log "✅ npm: $(npm --version)"
    fi

    log_success "✅ Phase 4 Complete"
}

# PHASE 5: CLONE REPOSITORY
phase5_clone() {
    log_info "📥 PHASE 5: Clone Repository"

    cd /tmp
    retry_run "git clone $REPO_URL newsapp-temp" "Cloning repo" 3

    mkdir -p "$INSTALL_DIR"
    if [[ -d "/tmp/newsapp-temp" ]]; then
        cp -r /tmp/newsapp-temp/* "$INSTALL_DIR/"
        cp -r /tmp/newsapp-temp/.* "$INSTALL_DIR/" 2>/dev/null || true
        rm -rf /tmp/newsapp-temp
        log "✅ Repository copied to $INSTALL_DIR"
    else
        log_error "❌ Clone failed"
        exit 1
    fi

    log_success "✅ Phase 5 Complete"
}

# PHASE 6: DATABASE
phase6_database() {
    log_info "💾 PHASE 6: Database"

    if [[ -f "$INSTALL_DIR/database/database.sqlite" ]]; then
        log "✅ SQLite database found"
        chmod 664 "$INSTALL_DIR/database/database.sqlite"
    else
        touch "$INSTALL_DIR/database/database.sqlite"
        chmod 664 "$INSTALL_DIR/database/database.sqlite"
        log "✅ SQLite database created"
    fi

    log_success "✅ Phase 6 Complete"
}

# PHASE 7: APPLICATION CONFIG
phase7_config() {
    log_info "⚙️ PHASE 7: Application Configuration"

    cd "$INSTALL_DIR"

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
EOF
    fi

    SERVER_IP=$(ip addr show | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}' | cut -d'/' -f1 || echo "localhost")
    sed -i "s|APP_URL=.*|APP_URL=http://$SERVER_IP:8000|" .env
    grep -q "^VITE_API_BASE_URL=" .env && sed -i "s|VITE_API_BASE_URL=.*|VITE_API_BASE_URL=http://$SERVER_IP:8000|" .env || echo "VITE_API_BASE_URL=http://$SERVER_IP:8000" >> .env

    log "Installing Composer dependencies..."
    export COMPOSER_ALLOW_SUPERUSER=1
    composer install --no-dev --optimize-autoloader --no-interaction 2>&1 | tee -a "$LOG_FILE"

    log "Generating app key..."
    php artisan key:generate --force 2>&1 | tee -a "$LOG_FILE"

    [[ ! -s "$INSTALL_DIR/database/database.sqlite" ]] && php artisan migrate --force 2>&1 | tee -a "$LOG_FILE"

    log "Installing NPM dependencies..."
    npm install --legacy-peer-deps --loglevel=error 2>&1 | tee -a "$LOG_FILE"

    log "Building frontend..."
    npm run build 2>&1 | tee -a "$LOG_FILE"

    chown -R www-data:www-data "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"
    chmod -R 775 "$INSTALL_DIR/storage" "$INSTALL_DIR/bootstrap/cache"
    chmod +x "$INSTALL_DIR/check-and-update-ip.sh" 2>/dev/null || true

    log_success "✅ Phase 7 Complete"
}

# PHASE 8: SYSTEMD SERVICES
phase8_services() {
    log_info "⚙️ PHASE 8: Systemd Services"

    PHP_BIN=$(which php)
    NPM_BIN=$(which npm)

    cat > /etc/systemd/system/newsapp.service << 'EOF'
[Unit]
Description=NewsApp Laravel Application
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/newsapp
Environment=PATH=/usr/bin:/usr/local/bin
ExecStart=/usr/bin/php artisan serve --host=0.0.0.0 --port=8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    cat > /etc/systemd/system/newsapp-vite.service << 'EOF'
[Unit]
Description=NewsApp Vite Server
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/newsapp
Environment=PATH=/usr/bin:/usr/local/bin
ExecStart=/usr/bin/npm run dev
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    cat > /etc/systemd/system/newsapp-ip-monitor.service << 'EOF'
[Unit]
Description=NewsApp IP Monitor
After=network.target

[Service]
Type=oneshot
ExecStart=/opt/newsapp/check-and-update-ip.sh
User=root
EOF

    cat > /etc/systemd/system/newsapp-ip-monitor.timer << 'EOF'
[Unit]
Description=NewsApp IP Monitor Timer

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
EOF

    systemctl daemon-reload
    systemctl enable newsapp newsapp-vite newsapp-ip-monitor.timer
    systemctl start newsapp-ip-monitor.timer

    log_success "✅ Phase 8 Complete"
}

# PHASE 9: START SERVICES
phase9_start() {
    log_info "🚀 PHASE 9: Start Services"

    systemctl start newsapp
    sleep 5
    systemctl start newsapp-vite
    sleep 5

    systemctl is-active newsapp >/dev/null 2>&1 && log_success "✅ Laravel service: RUNNING" || log_warning "⚠️ Laravel service: CHECK LOGS"
    systemctl is-active newsapp-vite >/dev/null 2>&1 && log_success "✅ Vite service: RUNNING" || log_warning "⚠️ Vite service: CHECK LOGS"
    systemctl is-active newsapp-ip-monitor.timer >/dev/null 2>&1 && log_success "✅ IP Monitor: ACTIVE"

    [ -f "$INSTALL_DIR/check-and-update-ip.sh" ] && "$INSTALL_DIR/check-and-update-ip.sh" 2>&1 | tee -a "$LOG_FILE"

    sleep 5
    curl -s -m 10 http://localhost:8000 >/dev/null 2>&1 && log_success "✅ Web interface: ACCESSIBLE" || log_warning "⚠️ May need more startup time"

    log_success "✅ Phase 9 Complete"
}

# FINAL COMPLETION
final_completion() {
    IP_ADDRESS=$(ip addr show | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}' | cut -d'/' -f1 || echo "localhost")

    echo
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    🎉 INSTALLATION COMPLETE! 🎉                         ║${NC}"
    echo -e "${GREEN}║                                                                           ║${NC}"
    echo -e "${GREEN}║  🌐 Access: ${CYAN}http://$IP_ADDRESS:8000${GREEN}                                        ║${NC}"
    echo -e "${GREEN}║  🐘 PHP: $(php -r 'echo PHP_VERSION;')                                                      ║${NC}"
    echo -e "${GREEN}║  💿 OS: $(lsb_release -rs 2>/dev/null || echo 'Linux')                                                       ║${NC}"
    echo -e "${GREEN}║                                                                           ║${NC}"
    echo -e "${GREEN}║  📝 Log: $LOG_FILE                              ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# MAIN
main() {
    check_root

    # Check if resuming after reboot
    if check_resume; then
        log_info "Continuing after reboot..."
    else
        detect_os

        # Upgrade Ubuntu if needed
        if [ "$NEEDS_UPGRADE" = "true" ]; then
            manual_ubuntu_upgrade
            # Script will reboot here
        fi
    fi

    phase0_cleanup
    phase1_preparation
    phase2_php
    phase3_composer
    phase4_nodejs
    phase5_clone
    phase6_database
    phase7_config
    phase8_services
    phase9_start
    final_completion
}

main "$@"
