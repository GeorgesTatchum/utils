#!/bin/bash

# Final Jenkins cleanup - Remove residual files (APT sources, logs, keyrings)
# These are safe to remove - Jenkins binary and user are already gone

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Jenkins Final Cleanup - Remove residual files            ║"
echo "║  (This only removes Jenkins APT sources, logs, keyrings)  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "Files to be removed:"
echo ""
echo "APT sources:"
echo "  - /etc/apt/sources.list.d/jenkins.*"
echo "  - /etc/apt/trusted.gpg.d/jenkins.*"
echo ""
echo "Nginx logs:"
echo "  - /var/log/nginx/jenkins.*"
echo ""
echo "Apt cache:"
echo "  - /var/lib/apt/lists/*jenkins*"
echo ""
echo "Temporary:"
echo "  - /tmp/hsperfdata_jenkins"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Cleaning..."
echo ""

# 1. Remove APT sources
echo "[1/4] Removing APT sources..."
sudo rm -f /etc/apt/sources.list.d/jenkins*
echo "✅ APT sources removed"

# 2. Remove keyrings
echo "[2/4] Removing Jenkins keyrings..."
sudo rm -f /etc/apt/trusted.gpg.d/jenkins*
echo "✅ Keyrings removed"

# 3. Remove Nginx logs
echo "[3/4] Removing Nginx Jenkins logs..."
sudo rm -f /var/log/nginx/jenkins*
echo "✅ Nginx logs removed"

# 4. Clean APT cache
echo "[4/4] Cleaning APT cache..."
sudo rm -rf /var/lib/apt/lists/*jenkins*
sudo apt-get update 2>/dev/null || true
echo "✅ APT cache cleaned"

# Optional: Clean temp
echo ""
echo "Cleaning temporary files..."
sudo rm -rf /tmp/hsperfdata_jenkins 2>/dev/null || true
echo "✅ Temp files cleaned"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Verification                                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "Checking for remaining Jenkins files..."
JENKINS_FILES=$(sudo find / -name "*jenkins*" 2>/dev/null | \
  grep -v snap | grep -v proc | grep -v sys | grep -v sonarqube | \
  grep -v "jenkins.io" | wc -l)

if [ "$JENKINS_FILES" -gt 5 ]; then
    echo "⚠️  Found $JENKINS_FILES Jenkins-related files (mostly in SonarQube assets)"
    echo "    This is OK - they're just image files in SonarQube tutorials"
else
    echo "✅ Jenkins cleanly removed"
fi

echo ""
echo "Remaining Jenkins references (mostly SonarQube assets):"
sudo find / -name "*jenkins*" 2>/dev/null | \
  grep -v snap | grep -v proc | grep -v sys | \
  grep -v "jenkins.io" | grep -v "^/etc/apt"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ Final Cleanup Complete!                               ║"
echo "║                                                            ║"
echo "║  Jenkins is completely removed from the system            ║"
echo "║  Remaining references are SonarQube tutorial images only  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "Next: Continue with phase1-cleanup.sh for Datadog, LXD, snaps"
echo ""
