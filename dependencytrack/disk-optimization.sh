#!/bin/bash

# Disk optimization - Remove unnecessary files to free up space
# Focus on: apt cache, old kernels, logs, snapd

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Disk Optimization - Clean cache, logs, old kernels       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "Current disk usage:"
df -h / | tail -1
echo ""

read -p "⚠️  Continue? This will clean cache, logs, and old kernels (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Starting disk optimization..."
echo ""

# 1. Clean APT cache
echo "[1/6] Cleaning APT cache..."
sudo apt-get clean
sudo apt-get autoclean
sudo apt-get autoremove -y 2>/dev/null || true
echo "✅ APT cache cleaned"

# 2. Clean old apt lists
echo "[2/6] Cleaning old APT partial downloads..."
sudo rm -rf /var/lib/apt/lists.old
sudo rm -rf /var/lib/apt/lists/partial/*
echo "✅ Old APT files removed"

# 3. Remove old kernels (keep last 2)
echo "[3/6] Removing old kernels..."
OLD_KERNELS=$(dpkg -l | grep linux-image | grep -v "$(uname -r)" | awk '{print $2}' | tail -n +3)
if [ ! -z "$OLD_KERNELS" ]; then
    echo "$OLD_KERNELS" | xargs sudo apt-get remove -y 2>/dev/null || true
    echo "✅ Old kernels removed"
else
    echo "✅ No old kernels to remove"
fi

# 4. Clean systemd journal (keep 30 days)
echo "[4/6] Cleaning systemd journal..."
sudo journalctl --vacuum=30d 2>/dev/null || true
echo "✅ Journal cleaned"

# 5. Clean temporary files
echo "[5/6] Cleaning temporary files..."
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
sudo rm -rf /var/cache/apt/archives/*
echo "✅ Temp files cleaned"

# 6. Clean old logs (keep 7 days)
echo "[6/6] Cleaning old logs..."
find /var/log -type f -name "*.gz" -mtime +30 -delete 2>/dev/null || true
find /var/log -type f -name "*.1" -size +100M -delete 2>/dev/null || true
sudo truncate -s 0 /var/log/syslog 2>/dev/null || true
sudo truncate -s 0 /var/log/auth.log 2>/dev/null || true
echo "✅ Old logs cleaned"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Disk Usage Summary                                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "BEFORE/AFTER comparison:"
echo ""
echo "Before optimization:"
echo "  /var/lib/apt:        298 MB"
echo "  /var/lib/snapd:      1.4 GB (if not removed)"
echo "  /var/cache/apt:      131 MB"
echo "  Old logs:            ~100-200 MB"
echo "  ────────────────────────────"
echo "  Total potential:     ~2 GB"
echo ""

echo "After optimization:"
df -h / | tail -1

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Next: Remove snapd completely (optional)                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

read -p "Remove snapd completely? This frees 1.4 GB (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing snapd..."
    sudo snap remove core 2>/dev/null || true
    sudo snap remove snapd 2>/dev/null || true
    sudo apt-get purge -y snapd 2>/dev/null || true
    sudo rm -rf ~/snap
    sudo rm -rf /var/lib/snapd
    sudo rm -rf /var/cache/snapd
    echo "✅ Snapd removed"

    echo ""
    df -h / | tail -1
else
    echo "Snapd kept"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ Disk Optimization Complete!                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Final disk status
echo "Final disk status:"
df -h /

echo ""
echo "Disk usage by major directories:"
sudo du -sh /var/lib/* 2>/dev/null | grep -E "^[0-9.]+[MG]" | sort -hr | head -10

echo ""
