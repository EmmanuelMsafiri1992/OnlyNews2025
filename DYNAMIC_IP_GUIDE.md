# 🌐 Dynamic IP Configuration Guide

## Overview

This NewsApp system includes **automatic IP detection and configuration** that works seamlessly whether the NanoPi is using DHCP (dynamic IP) or Static IP configuration.

## ✨ Features

### 1. **Automatic IP Detection**
- The system automatically detects the current NanoPi IP address
- Works with both DHCP and Static IP configurations
- No manual configuration needed

### 2. **Automatic Configuration Update**
- IP changes are detected every 5 minutes
- Configuration files are automatically updated
- Services are automatically restarted with new IP

### 3. **Frontend Dynamic URLs**
- Frontend uses `window.location.origin` as fallback
- No hardcoded IP addresses in Vue components
- Works on any network without code changes

### 4. **Background IP Monitoring**
- Systemd timer runs every 5 minutes
- Checks for IP changes automatically
- Updates `.env` file and restarts services when IP changes

## 🔧 How It Works

### Components

1. **NetworkHelper.php** - Backend PHP helper for IP detection
   - Location: `app/Helpers/NetworkHelper.php`
   - Detects server IP dynamically
   - Updates `.env` file with current IP

2. **check-and-update-ip.sh** - IP monitoring script
   - Location: `/opt/newsapp/check-and-update-ip.sh`
   - Runs every 5 minutes via systemd timer
   - Compares current IP with cached IP
   - Updates configuration if IP changes

3. **newsapp-ip-monitor.timer** - Systemd timer
   - Runs on boot (1 minute after)
   - Runs every 5 minutes thereafter
   - Ensures IP is always up-to-date

4. **Frontend Dynamic API Calls**
   - Uses `window.location.origin` as fallback
   - No hardcoded IPs in JavaScript/Vue code

### IP Change Flow

```
┌─────────────────────────────────────────────┐
│  IP Monitor Timer (every 5 minutes)         │
└────────────────┬────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│  check-and-update-ip.sh                     │
│  - Detects current IP                       │
│  - Compares with cached IP                  │
└────────────────┬────────────────────────────┘
                 │
                 ▼
         ┌───────┴────────┐
         │  IP Changed?    │
         └───────┬────────┘
                 │
        ┌────────┴─────────┐
        │ YES              │ NO
        ▼                  ▼
┌──────────────────┐  ┌─────────────┐
│ Update .env      │  │ Do nothing  │
│ - APP_URL        │  └─────────────┘
│ - VITE_API_...   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Restart Services │
│ - newsapp        │
│ - newsapp-vite   │
└──────────────────┘
```

## 📋 Usage

### Automatic (Recommended)

The IP monitor runs automatically. **No manual intervention needed!**

```bash
# Check IP monitor status
sudo systemctl status newsapp-ip-monitor.timer

# View IP monitor logs
sudo journalctl -u newsapp-ip-monitor.service -f
```

### Manual IP Update

If you need to force an immediate IP update:

```bash
sudo /opt/newsapp/check-and-update-ip.sh
```

### Check Current IP Configuration

View the IP monitoring log:

```bash
cat /opt/newsapp/storage/logs/ip-monitor.log
```

View current cached IP:

```bash
cat /opt/newsapp/.current_ip
```

View current .env configuration:

```bash
grep -E 'APP_URL|VITE_API_BASE_URL' /opt/newsapp/.env
```

## 🔄 Network Configuration Changes

### Switching from DHCP to Static IP

1. Go to Admin Settings → General → Network Settings
2. Select "Static IP"
3. Enter IP address, subnet mask, gateway, DNS
4. Click "Update Network Settings"
5. The IP monitor will detect the change within 5 minutes
6. Configuration will be automatically updated

### Switching from Static IP to DHCP

1. Go to Admin Settings → General → Network Settings
2. Select "Dynamic IP (DHCP)"
3. Click "Update Network Settings"
4. Reboot NanoPi to get new DHCP IP
5. The IP monitor will detect the new IP within 5 minutes

## 🛠️ System Management Commands

```bash
# View all NewsApp services
sudo systemctl status newsapp
sudo systemctl status newsapp-vite
sudo systemctl status newsapp-ip-monitor.timer

# Restart services
sudo systemctl restart newsapp
sudo systemctl restart newsapp-vite

# View logs
sudo journalctl -u newsapp -f
sudo journalctl -u newsapp-vite -f
sudo journalctl -u newsapp-ip-monitor.service -f

# Manual IP update
sudo /opt/newsapp/check-and-update-ip.sh

# Check IP monitor timer schedule
sudo systemctl list-timers newsapp-ip-monitor.timer
```

## 🐛 Troubleshooting

### IP not updating automatically

```bash
# Check if timer is running
sudo systemctl status newsapp-ip-monitor.timer

# If not running, start it
sudo systemctl start newsapp-ip-monitor.timer
sudo systemctl enable newsapp-ip-monitor.timer

# Run manual update
sudo /opt/newsapp/check-and-update-ip.sh
```

### Frontend not connecting to backend

```bash
# Check current IP in .env
grep -E 'APP_URL|VITE_API_BASE_URL' /opt/newsapp/.env

# Get actual server IP
ip addr show | grep "inet " | grep -v 127.0.0.1

# If they don't match, run manual update
sudo /opt/newsapp/check-and-update-ip.sh

# Restart services
sudo systemctl restart newsapp
sudo systemctl restart newsapp-vite
```

### Services not restarting after IP change

```bash
# Check IP monitor logs for errors
sudo journalctl -u newsapp-ip-monitor.service --no-pager

# Verify script has execute permissions
ls -l /opt/newsapp/check-and-update-ip.sh

# If not executable
sudo chmod +x /opt/newsapp/check-and-update-ip.sh
```

## 📝 Configuration Files

### .env file (auto-updated)
```
APP_URL=http://192.168.1.100:8000
VITE_API_BASE_URL=http://192.168.1.100:8000
```

### IP Cache file
- Location: `/opt/newsapp/.current_ip`
- Contains: Current detected IP address
- Used for: Detecting IP changes

### IP Monitor Log
- Location: `/opt/newsapp/storage/logs/ip-monitor.log`
- Contains: Timestamped IP change events
- Useful for: Troubleshooting and monitoring

## 🎯 Best Practices

1. **Don't hardcode IPs** - The system handles this automatically
2. **Monitor logs regularly** - Check `/opt/newsapp/storage/logs/ip-monitor.log`
3. **Keep timer enabled** - Ensure `newsapp-ip-monitor.timer` is always running
4. **Test after network changes** - Run manual update after changing network settings

## ⚡ Advanced Usage

### Change IP Monitor Frequency

Edit the timer unit file:

```bash
sudo nano /etc/systemd/system/newsapp-ip-monitor.timer
```

Change `OnUnitActiveSec=5min` to desired interval (e.g., `1min`, `10min`)

Reload systemd:

```bash
sudo systemctl daemon-reload
sudo systemctl restart newsapp-ip-monitor.timer
```

### Disable IP Monitoring

```bash
sudo systemctl stop newsapp-ip-monitor.timer
sudo systemctl disable newsapp-ip-monitor.timer
```

### Re-enable IP Monitoring

```bash
sudo systemctl enable newsapp-ip-monitor.timer
sudo systemctl start newsapp-ip-monitor.timer
```

## 📊 Monitoring Dashboard

Check IP monitor status in real-time:

```bash
watch -n 2 'echo "=== Current IP ===" && cat /opt/newsapp/.current_ip && echo "" && echo "=== .env Configuration ===" && grep -E "APP_URL|VITE_API" /opt/newsapp/.env && echo "" && echo "=== Timer Status ===" && systemctl status newsapp-ip-monitor.timer --no-pager | head -5'
```

---

**✅ With this system, your NewsApp will always work correctly regardless of IP changes!**
