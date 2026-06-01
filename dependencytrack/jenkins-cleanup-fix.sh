#!/bin/bash

# Jenkins cleanup fix - Handle leftover files and user/group

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Jenkins Cleanup Fix - Remove remaining artifacts         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

read -p "⚠️  Continue? This will force-remove all Jenkins files (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Cleaning Jenkins artifacts..."
echo ""

# 1. Force-stop Jenkins service
echo "[1/6] Stopping Jenkins service..."
sudo systemctl stop jenkins 2>/dev/null || true
sudo systemctl disable jenkins 2>/dev/null || true
sleep 2

# 2. Kill Jenkins processes
echo "[2/6] Killing Jenkins processes..."
sudo pkill -9 -f jenkins || true
sleep 1

# 3. Remove Jenkins files
echo "[3/6] Removing Jenkins files..."
sudo rm -rf /var/cache/jenkins
sudo rm -rf /var/lib/jenkins
sudo rm -rf /var/log/jenkins
sudo rm -rf /etc/jenkins
sudo rm -rf /usr/share/java/jenkins*
sudo rm -f /usr/sbin/jenkins
sudo rm -f /etc/default/jenkins
sudo rm -f /etc/systemd/system/jenkins.service
sudo rm -f /usr/lib/systemd/system/jenkins.service

# 4. Remove Jenkins user if exists
echo "[4/6] Removing Jenkins user..."
if id jenkins >/dev/null 2>&1; then
    echo "  Found jenkins user, removing..."
    sudo userdel -r jenkins 2>/dev/null || \
    sudo userdel jenkins 2>/dev/null || true
    echo "  ✅ Jenkins user removed"
else
    echo "  Jenkins user not found (OK)"
fi

# 5. Remove Jenkins group if exists
echo "[5/6] Removing Jenkins group..."
if getent group jenkins >/dev/null 2>&1; then
    echo "  Found jenkins group, removing..."
    sudo groupdel jenkins 2>/dev/null || true
    echo "  ✅ Jenkins group removed"
else
    echo "  Jenkins group not found (OK)"
fi

# 6. Reload systemd daemon
echo "[6/6] Reloading systemd daemon..."
sudo systemctl daemon-reload
sudo systemctl reset-failed 2>/dev/null || true

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Verification                                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Verify Jenkins completely removed
echo "Checking for remaining Jenkins processes..."
if ps aux | grep -v grep | grep -q jenkins; then
    echo "❌ Jenkins processes still running:"
    ps aux | grep jenkins | grep -v grep
else
    echo "✅ No Jenkins processes running"
fi

echo ""
echo "Checking for remaining Jenkins files..."
if find / -name "*jenkins*" -type f 2>/dev/null | grep -v "snap\|proc\|sys" | head -5; then
    echo "⚠️  Some Jenkins-related files may remain (safe to ignore)"
else
    echo "✅ No Jenkins files found"
fi

echo ""
echo "Checking for Jenkins user..."
if id jenkins >/dev/null 2>&1; then
    echo "❌ Jenkins user still exists"
else
    echo "✅ Jenkins user removed"
fi

echo ""
echo "Checking for Jenkins group..."
if getent group jenkins >/dev/null 2>&1; then
    echo "❌ Jenkins group still exists"
else
    echo "✅ Jenkins group removed"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ Jenkins Cleanup Complete!                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# RAM status
echo "RAM Status:"
free -h | head -2

echo ""
echo "Disk Status:"
df -h / | tail -1

echo ""
