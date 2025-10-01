#!/bin/bash
# Debug script for Nano Pi deployment issues

echo "=== Laravel Error Logs ==="
if [ -f storage/logs/laravel.log ]; then
    tail -50 storage/logs/laravel.log
else
    echo "No laravel.log found"
fi

echo -e "\n=== Storage Permissions ==="
ls -la storage/
ls -la storage/logs/
ls -la storage/framework/
ls -la storage/framework/cache/
ls -la storage/framework/sessions/
ls -la storage/framework/views/

echo -e "\n=== Database Permissions ==="
ls -la database/
ls -la database/database.sqlite 2>/dev/null || echo "database.sqlite not found"

echo -e "\n=== Bootstrap Cache Permissions ==="
ls -la bootstrap/cache/

echo -e "\n=== Current User ==="
whoami
id

echo -e "\n=== PHP Extensions ==="
php -m | grep -E "(sqlite3|pdo_sqlite|mbstring|openssl|tokenizer|xml|ctype|json)"

echo -e "\n=== Environment Check ==="
php artisan --version
php --version | head -1
