#!/bin/bash

# OnlyNews2025 - Automated Installation Script for NanoPi
# Run with: curl -fsSL https://raw.githubusercontent.com/EmmanuelMsafiri1992/OnlyNews2025/main/install.sh | sudo bash

set -e  # Exit on any error

echo "=========================================="
echo "OnlyNews2025 - Installation Script"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run as root (use sudo)"
    exit 1
fi

# Configuration
INSTALL_DIR="/opt/newsapp"
REPO_URL="https://github.com/EmmanuelMsafiri1992/OnlyNews2025.git"
DB_NAME="newsapp"
DB_USER="newsapp_user"
DB_PASS=$(openssl rand -base64 12)

echo "Step 1/10: Updating system packages..."
apt update && apt upgrade -y

echo "Step 2/10: Installing required packages..."
apt install -y php php-cli php-fpm php-mysql php-mbstring php-xml php-curl php-zip \
    git composer nginx mysql-server curl unzip

echo "Step 3/10: Cloning repository..."
if [ -d "$INSTALL_DIR" ]; then
    echo "Directory $INSTALL_DIR exists. Creating backup..."
    mv "$INSTALL_DIR" "${INSTALL_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
fi
git clone "$REPO_URL" "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "Step 4/10: Setting up database..."
mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

echo "Step 5/10: Configuring environment..."
if [ ! -f .env ]; then
    cp .env.example .env
fi

# Update .env file
sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" .env
sed -i "s/APP_ENV=.*/APP_ENV=production/" .env
sed -i "s/APP_DEBUG=.*/APP_DEBUG=false/" .env

echo "Step 6/10: Installing PHP dependencies..."
composer install --optimize-autoloader --no-dev

echo "Step 7/10: Generating application key..."
php artisan key:generate --force

echo "Step 8/10: Running database migrations..."
php artisan migrate --force

echo "Step 9/10: Setting up storage and permissions..."
php artisan storage:link
chown -R www-data:www-data "$INSTALL_DIR"
chmod -R 755 "$INSTALL_DIR"
chmod -R 775 "$INSTALL_DIR/storage"
chmod -R 775 "$INSTALL_DIR/bootstrap/cache"

echo "Step 10/10: Setting up systemd service..."
cat > /etc/systemd/system/newsapp.service <<EOF
[Unit]
Description=OnlyNews2025 Application
After=network.target mysql.service

[Service]
Type=simple
User=www-data
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/php $INSTALL_DIR/artisan serve --host=0.0.0.0 --port=8000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable newsapp
systemctl start newsapp

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Database Credentials (SAVE THESE!):"
echo "  Database: $DB_NAME"
echo "  Username: $DB_USER"
echo "  Password: $DB_PASS"
echo ""
echo "Application installed at: $INSTALL_DIR"
echo ""
echo "Access the application:"
echo "  http://$(hostname -I | awk '{print $1}'):8000"
echo ""
echo "Service commands:"
echo "  sudo systemctl status newsapp   # Check status"
echo "  sudo systemctl restart newsapp  # Restart"
echo "  sudo systemctl stop newsapp     # Stop"
echo ""
echo "To view logs:"
echo "  sudo journalctl -u newsapp -f"
echo ""
