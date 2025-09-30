# Setup Guide - NewsApp

This guide will help you set up and run the NewsApp on a new computer.

## Prerequisites

- PHP 8.1 or higher
- Composer
- Node.js 16+ and npm
- Git (optional)

## Installation Steps

### 1. Install Dependencies

```bash
# Install PHP dependencies
composer install

# Install Node.js dependencies
npm install
```

### 2. Environment Configuration

```bash
# Copy the environment file
cp .env.example .env

# Generate application key
php artisan key:generate
```

### 3. Configure Environment Variables

Open `.env` file and update the following:

```env
APP_NAME=NewsApp
APP_ENV=local
APP_DEBUG=true

# Get your local IP address (see step 4)
APP_URL=http://YOUR_LOCAL_IP:8000
VITE_API_BASE_URL=http://YOUR_LOCAL_IP:8000

# Database (using SQLite by default)
DB_CONNECTION=sqlite
DB_DATABASE=database/database.sqlite
```

### 4. Find Your Local IP Address

**Windows:**
```bash
ipconfig
```
Look for "IPv4 Address" (e.g., `192.168.1.100` or `10.1.5.56`)

**Mac/Linux:**
```bash
ifconfig
# or
ip addr show
```

Update `APP_URL` and `VITE_API_BASE_URL` in `.env` with your local IP:
```env
APP_URL=http://192.168.1.100:8000
VITE_API_BASE_URL=http://192.168.1.100:8000
```

### 5. Database Setup

```bash
# Create SQLite database file
touch database/database.sqlite

# Run migrations
php artisan migrate

# (Optional) Seed database with sample data
php artisan db:seed
```

### 6. Configure Windows Firewall

**Option A - Using Command Prompt (Run as Administrator):**
```powershell
netsh advfirewall firewall add rule name="Laravel Dev Server" dir=in action=allow protocol=TCP localport=8000
```

**Option B - Using Windows Firewall GUI:**
1. Press `Win + R`, type `wf.msc`, press Enter
2. Click "Inbound Rules" → "New Rule"
3. Select "Port" → Next
4. Select "TCP", enter "8000" → Next
5. Select "Allow the connection" → Next
6. Check all profiles (Domain, Private, Public) → Next
7. Name it "Laravel Dev Server" → Finish

### 7. Build Frontend Assets

```bash
# Build for production
npm run build

# OR run development server with hot reload
npm run dev
```

### 8. Start Laravel Server

```bash
# Start server on all network interfaces
php artisan serve --host=0.0.0.0 --port=8000
```

**Important:** Use `--host=0.0.0.0` to allow connections from other devices on your network.

### 9. Access the Application

Open your browser and navigate to:
- **Same computer:** `http://localhost:8000` or `http://127.0.0.1:8000`
- **Other devices on network:** `http://YOUR_LOCAL_IP:8000`

Example: `http://192.168.1.100:8000`

## Troubleshooting

### Connection Refused Error

**Problem:** Frontend shows `ERR_CONNECTION_REFUSED` when trying to fetch API data.

**Solutions:**

1. **Check if Laravel server is running:**
   ```bash
   netstat -ano | findstr :8000
   ```

2. **Verify server is bound to 0.0.0.0:**
   - Make sure you started the server with `--host=0.0.0.0`
   - Kill any existing PHP processes and restart

3. **Check firewall rules:**
   ```bash
   netsh advfirewall firewall show rule name="Laravel Dev Server"
   ```

4. **Verify correct IP in .env:**
   - Use your **local IP** (e.g., `192.168.1.100`), not public IP
   - Must match the IP where Laravel server is running

5. **Test API endpoint:**
   ```bash
   curl http://127.0.0.1:8000/api/settings
   ```

### CORS Errors

If you see CORS errors in browser console:

1. Check `config/cors.php`:
   ```php
   'allowed_origins' => ['*'],
   ```

2. Clear Laravel config cache:
   ```bash
   php artisan config:clear
   php artisan cache:clear
   ```

### Vue 3 Compatibility Issues

If you see errors like `this.$set is not a function`:

- This project uses Vue 3
- Replace `this.$set(obj, key, value)` with `obj[key] = value`
- Rebuild frontend: `npm run build`

### Port Already in Use

If port 8000 is already in use:

```bash
# Windows - Find process using port
netstat -ano | findstr :8000

# Kill process (replace PID with actual process ID)
taskkill //F //PID <PID>
```

## Development Workflow

### For Frontend Development

```bash
# Terminal 1 - Start Laravel API server
php artisan serve --host=0.0.0.0 --port=8000

# Terminal 2 - Start Vite dev server with hot reload
npm run dev
```

### For Production Build

```bash
# Build optimized assets
npm run build

# Start Laravel server (serves built assets)
php artisan serve --host=0.0.0.0 --port=8000
```

## Common Commands

```bash
# Clear all caches
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Run migrations
php artisan migrate

# Reset database (WARNING: deletes all data)
php artisan migrate:fresh --seed

# Build frontend
npm run build

# Development mode with hot reload
npm run dev

# Run tests (if available)
php artisan test
```

## Network Access

### Access from Same Computer
Use `localhost`, `127.0.0.1`, or your local IP

### Access from Other Devices on Same Network
1. Find your computer's local IP (e.g., `192.168.1.100`)
2. Update `.env` with this IP
3. Ensure firewall allows port 8000
4. Start server with `--host=0.0.0.0`
5. Access from other device: `http://192.168.1.100:8000`

### Access from Internet (Not Recommended for Development)
For production deployment, use proper hosting with:
- Web server (nginx/Apache)
- SSL certificate
- Proper security configuration
- Environment variables set to production

## Additional Notes

- **SQLite Database:** The default database file is at `database/database.sqlite`
- **Storage Permissions:** Ensure `storage/` and `bootstrap/cache/` are writable
- **Public Directory:** Built assets are in `public/build/`
- **Logs:** Check `storage/logs/laravel.log` for errors

## Support

If you encounter issues:
1. Check Laravel logs: `storage/logs/laravel.log`
2. Check browser console for JavaScript errors
3. Verify all environment variables are set correctly
4. Ensure all dependencies are installed