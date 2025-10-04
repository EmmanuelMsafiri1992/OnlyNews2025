# OnlyNews2025 - NanoPi Installation Guide

## Quick Install (One Command)

Run this single command on your new NanoPi:

```bash
curl -fsSL https://raw.githubusercontent.com/EmmanuelMsafiri1992/OnlyNews2025/main/install.sh | sudo bash
```

This will automatically:
- Update system packages
- Install all required dependencies (PHP, MySQL, Nginx, etc.)
- Clone the repository to `/opt/newsapp`
- Set up the database
- Configure the application
- Create and start the systemd service

## After Installation

The script will display:
- Database credentials (save these!)
- Application URL
- Service management commands

### Access the Application

```
http://YOUR_NANOPI_IP:8000
```

### Default Admin Login

After installation, create an admin user:

```bash
cd /opt/newsapp
php artisan tinker
```

Then in tinker:
```php
$user = new App\Models\User();
$user->name = 'Admin';
$user->email = 'admin@example.com';
$user->password = bcrypt('password');
$user->role = 'superadmin';
$user->save();
exit
```

### Service Management

```bash
# Check status
sudo systemctl status newsapp

# Restart
sudo systemctl restart newsapp

# Stop
sudo systemctl stop newsapp

# View logs
sudo journalctl -u newsapp -f
```

### Update Application

```bash
cd /opt/newsapp
git pull origin main
composer install --optimize-autoloader --no-dev
php artisan migrate --force
php artisan cache:clear
php artisan view:clear
sudo systemctl restart newsapp
```

### TV Display

Access TV view by adding `?tv=1` to the URL:
```
http://YOUR_NANOPI_IP:8000?tv=1
```

Or it will auto-detect old browsers (Chrome < 49) and serve the TV view automatically.

## Manual Installation

If you prefer manual installation, see the detailed steps in the `install.sh` script.

## Troubleshooting

### Check if service is running
```bash
sudo systemctl status newsapp
```

### Check application logs
```bash
sudo journalctl -u newsapp -f
tail -f /opt/newsapp/storage/logs/laravel.log
```

### Permissions issues
```bash
cd /opt/newsapp
sudo chown -R www-data:www-data .
sudo chmod -R 755 .
sudo chmod -R 775 storage bootstrap/cache
```

### Database connection issues
Check your `.env` file:
```bash
nano /opt/newsapp/.env
```

## Support

For issues, please create an issue on GitHub.
