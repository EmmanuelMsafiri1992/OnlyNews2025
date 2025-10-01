#!/bin/bash
# Fix permissions for Laravel on Nano Pi

echo "=== Fixing Laravel Permissions ==="

# Get current user
CURRENT_USER=$(whoami)
echo "Current user: $CURRENT_USER"

# Fix storage directory permissions
echo "Fixing storage permissions..."
chmod -R 775 storage
chmod -R 775 bootstrap/cache

# Set ownership (if running as root)
if [ "$EUID" -eq 0 ]; then
    echo "Running as root, setting ownership to www-data..."
    chown -R www-data:www-data storage bootstrap/cache
else
    echo "Not running as root, setting ownership to $CURRENT_USER..."
    chown -R $CURRENT_USER:$CURRENT_USER storage bootstrap/cache
fi

# Ensure database directory exists and is writable
echo "Fixing database permissions..."
mkdir -p database
chmod 775 database

# Set database directory ownership
if [ "$EUID" -eq 0 ]; then
    chown www-data:www-data database
fi

# If database file exists, make it writable
if [ -f database/database.sqlite ]; then
    chmod 664 database/database.sqlite
    if [ "$EUID" -eq 0 ]; then
        chown www-data:www-data database/database.sqlite
    fi
    echo "database.sqlite permissions fixed"
else
    echo "Creating database.sqlite..."
    touch database/database.sqlite
    chmod 664 database/database.sqlite
    if [ "$EUID" -eq 0 ]; then
        chown www-data:www-data database/database.sqlite
    fi
fi

# Clear and recreate cache
echo "Clearing caches..."
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear

echo -e "\n=== Permissions Fixed ==="
echo "Run the debug script to verify: bash debug-nanopi.sh"
