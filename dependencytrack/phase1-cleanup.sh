#!/bin/bash

# Phase 1: Server Cleanup - Remove Jenkins, Datadog, LXD, etc.
# Keep: SonarQube, PostgreSQL, Docker, Nginx
# Duration: ~30 minutes
# Gain: ~900 MB RAM + 1.5 GB disque

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Phase 1: Server Cleanup (Jenkins, Datadog, LXD)           ║"
echo "║  Duration: ~30 minutes                                     ║"
echo "║  Gain: ~900 MB RAM + 1.5 GB disque                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

read -p "⚠️  Continue? This will stop Jenkins, Datadog, and LXD (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Starting cleanup..."
echo ""

# 1. Jenkins
echo "[1/8] Stopping Jenkins..."
sudo systemctl stop jenkins 2>/dev/null || true
sudo systemctl disable jenkins 2>/dev/null || true
sudo apt-get purge -y jenkins 2>/dev/null || true
sudo rm -rf /var/cache/jenkins /var/lib/jenkins
echo "✅ Jenkins removed"
echo ""

# 2. Datadog Agent
echo "[2/8] Stopping Datadog Agent..."
sudo systemctl stop datadog-agent 2>/dev/null || true
sudo systemctl stop datadog-agent-trace 2>/dev/null || true
sudo systemctl disable datadog-agent 2>/dev/null || true
sudo systemctl disable datadog-agent-trace 2>/dev/null || true
sudo apt-get purge -y datadog-agent 2>/dev/null || true
sudo rm -rf /opt/datadog-agent
echo "✅ Datadog removed"
echo ""

# 3. ModemManager
echo "[3/8] Stopping ModemManager..."
sudo systemctl stop ModemManager 2>/dev/null || true
sudo systemctl disable ModemManager 2>/dev/null || true
sudo apt-get purge -y modemmanager 2>/dev/null || true
echo "✅ ModemManager removed"
echo ""

# 4. LXD
echo "[4/8] Removing LXD..."
sudo snap remove lxd --purge 2>/dev/null || true
echo "✅ LXD removed"
echo ""

# 5. Clean old snaps
echo "[5/8] Cleaning old snaps..."
sudo snap list --all 2>/dev/null | grep disabled | while read -r snap rev rest; do
    if [ ! -z "$snap" ]; then
        echo "  Removing $snap (rev $rev)..."
        sudo snap remove "$snap" --revision="$rev" 2>/dev/null || true
    fi
done
echo "✅ Old snaps cleaned"
echo ""

# 6. APT cleanup
echo "[6/8] Cleaning APT cache..."
sudo apt-get clean
sudo apt-get autoclean
sudo apt-get autoremove -y
echo "✅ APT cache cleaned"
echo ""

# 7. Temp files
echo "[7/8] Cleaning temporary files..."
sudo rm -rf /tmp/* /var/tmp/* 2>/dev/null || true
sudo journalctl --vacuum=30d 2>/dev/null || true
echo "✅ Temp files cleaned"
echo ""

# 8. Verify critical services
echo "[8/8] Verifying critical services..."
echo ""

# Check SonarQube
if sudo systemctl is-active sonarqube >/dev/null 2>&1; then
    echo "✅ SonarQube: RUNNING"
else
    echo "⚠️  SonarQube: NOT RUNNING (expected if not auto-start)"
fi

# Check PostgreSQL
if sudo systemctl is-active postgresql >/dev/null 2>&1; then
    echo "✅ PostgreSQL: RUNNING"
else
    echo "❌ PostgreSQL: NOT RUNNING (error)"
fi

# Check Docker
if sudo systemctl is-active docker >/dev/null 2>&1; then
    echo "✅ Docker: RUNNING"
else
    echo "❌ Docker: NOT RUNNING (error)"
fi

# Check Nginx
if sudo systemctl is-active nginx >/dev/null 2>&1; then
    echo "✅ Nginx: RUNNING"
else
    echo "⚠️  Nginx: NOT RUNNING (expected if not needed)"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Cleanup Statistics                                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# RAM
echo "RAM Status:"
free -h | head -2

echo ""
echo "Disk Status:"
df -h / | tail -1

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ Phase 1 Complete!                                      ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "║  Next step: Wait for OVH RAM upgrade (4 GB → 8 GB)        ║"
echo "║                                                            ║"
echo "║  After upgrade, run: phase2-verify.sh                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
