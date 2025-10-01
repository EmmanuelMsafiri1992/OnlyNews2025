#!/bin/bash
# Complete setup script for Nano Pi deployment

set -e  # Exit on error

echo "==================================="
echo "  OnlyNews2025 - Nano Pi Setup"
echo "==================================="

# Check if running in correct directory
if [ ! -f "artisan" ]; then
    echo "ERROR: Must run from Laravel project root directory"
    exit 1
fi

echo ""
echo "[1/8] Setting correct file ownership..."
if [ "$EUID" -eq 0 ]; then
    chown -R www-data:www-data storage bootstrap/cache database
    echo "✓ Files owned by www-data"
else
    echo "⚠ Not running as root, skipping ownership change"
fi

echo ""
echo "[2/8] Setting correct permissions..."
chmod -R 775 storage bootstrap/cache database
chmod 664 database/database.sqlite
echo "✓ Permissions set correctly"

echo ""
echo "[3/8] Fixing database path in .env..."
if grep -q "DB_DATABASE=database/database.sqlite" .env; then
    sed -i "s|DB_DATABASE=database/database.sqlite|DB_DATABASE=$(pwd)/database/database.sqlite|" .env
    echo "✓ Database path updated to absolute path"
else
    echo "✓ Database path already correct"
fi

echo ""
echo "[4/8] Clearing all Laravel caches..."
php artisan config:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || echo "⚠ No views to clear (normal)"
echo "✓ Caches cleared"

echo ""
echo "[5/8] Checking database file..."
if [ ! -f database/database.sqlite ]; then
    echo "Creating database file..."
    touch database/database.sqlite
    chmod 664 database/database.sqlite
    if [ "$EUID" -eq 0 ]; then
        chown www-data:www-data database/database.sqlite
    fi
fi
echo "✓ Database file exists"

echo ""
echo "[6/8] Verifying database tables..."
TABLE_COUNT=$(php artisan tinker --execute="echo DB::table('migrations')->count();" 2>/dev/null || echo "0")
if [ "$TABLE_COUNT" = "0" ]; then
    echo "⚠ Database empty, you may need to run: php artisan migrate"
else
    echo "✓ Database has tables"
fi

echo ""
echo "[7/8] Testing configuration..."
php artisan config:cache
echo "✓ Configuration cached successfully"

echo ""
echo "[8/8] Final verification..."
php artisan --version
echo ""

echo "==================================="
echo "  Setup Complete!"
echo "==================================="
echo ""
echo "To start the server:"
echo "  php artisan serve --host=0.0.0.0 --port=8000"
echo ""
echo "Or use systemd service:"
echo "  sudo systemctl start onlynews"
echo ""
