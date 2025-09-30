#!/bin/bash
# NanoPi Diagnostics Script
# Run this on NanoPi to diagnose connection issues

echo "=========================================="
echo "   NEWSAPP DIAGNOSTICS"
echo "=========================================="
echo ""

echo "1. SERVICE STATUS:"
echo "-------------------"
systemctl status newsapp --no-pager | head -15
echo ""
systemctl status newsapp-vite --no-pager | head -15
echo ""

echo "2. PORT LISTENING:"
echo "-------------------"
echo "Checking if port 8000 is listening..."
netstat -tuln | grep :8000 || ss -tuln | grep :8000
echo ""

echo "3. CURRENT IP ADDRESS:"
echo "-------------------"
ip addr show | grep "inet " | grep -v 127.0.0.1
echo ""

echo "4. .ENV CONFIGURATION:"
echo "-------------------"
cd /opt/newsapp 2>/dev/null && grep -E "APP_URL|VITE_API" .env
echo ""

echo "5. PROCESS CHECK:"
echo "-------------------"
ps aux | grep -E "php.*artisan.*serve|node.*vite" | grep -v grep
echo ""

echo "6. RECENT LOGS (Last 20 lines):"
echo "-------------------"
journalctl -u newsapp -n 20 --no-pager
echo ""

echo "7. FIREWALL STATUS:"
echo "-------------------"
ufw status 2>/dev/null || iptables -L -n | head -10
echo ""

echo "8. DATABASE CHECK:"
echo "-------------------"
ls -lh /opt/newsapp/database/database.sqlite 2>/dev/null || echo "Database not found"
echo ""

echo "=========================================="
echo "DIAGNOSTICS COMPLETE"
echo "=========================================="
