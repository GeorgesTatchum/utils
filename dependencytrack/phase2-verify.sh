#!/bin/bash

# Phase 2: Verify RAM upgrade and services
# Run this AFTER OVH upgrades RAM from 4 GB to 8 GB
# Duration: ~5 minutes

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Phase 2: Verify RAM Upgrade (After OVH)                  ║"
echo "║  Duration: ~5 minutes                                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "⏳ Waiting 10 seconds for system to stabilize..."
sleep 10

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  1. RAM Verification                                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

RAM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
RAM_USED=$(free -h | grep Mem | awk '{print $3}')
RAM_FREE=$(free -h | grep Mem | awk '{print $4}')

echo "Total RAM: $RAM_TOTAL"
echo "Used RAM:  $RAM_USED"
echo "Free RAM:  $RAM_FREE"
echo ""

# Check if upgrade successful (should be ~8 GB)
RAM_GB=$(free -h | grep Mem | awk '{print $2}' | sed 's/Gi//')
if (( $(echo "$RAM_GB >= 7.5" | bc -l) )); then
    echo "✅ RAM upgrade verified ($RAM_GB GB detected)"
else
    echo "❌ WARNING: RAM appears to be $RAM_GB GB (expected ~8 GB)"
    echo "   Please verify with OVH or contact support"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  2. Services Verification                                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

ERROR_COUNT=0

# Check SonarQube
echo -n "SonarQube... "
if sudo systemctl is-active sonarqube >/dev/null 2>&1; then
    echo "✅ RUNNING"
else
    echo "⚠️  NOT RUNNING (normal if disabled)"
fi

# Check PostgreSQL
echo -n "PostgreSQL... "
if sudo systemctl is-active postgresql >/dev/null 2>&1; then
    echo "✅ RUNNING"
else
    echo "❌ NOT RUNNING (ERROR)"
    ERROR_COUNT=$((ERROR_COUNT+1))
fi

# Check Docker
echo -n "Docker... "
if sudo systemctl is-active docker >/dev/null 2>&1; then
    echo "✅ RUNNING"
else
    echo "❌ NOT RUNNING (ERROR)"
    ERROR_COUNT=$((ERROR_COUNT+1))
fi

# Check SSH
echo -n "SSH... "
if sudo systemctl is-active ssh >/dev/null 2>&1; then
    echo "✅ RUNNING"
else
    echo "⚠️  NOT RUNNING"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  3. Database Verification                                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo -n "PostgreSQL connectivity... "
if sudo -u postgres psql -l >/dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ FAILED"
    ERROR_COUNT=$((ERROR_COUNT+1))
fi

echo -n "PostgreSQL sonarqube database... "
if sudo -u postgres psql -lqt | grep -q sonarqube; then
    echo "✅ EXISTS"
else
    echo "⚠️  NOT FOUND (may be OK)"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  4. Disk Status                                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

df -h / | awk 'NR==1 {print $1" "$2" "$3" "$4" "$5"%; "} NR==2 {printf "%s (free) / %s (total) / %s (used)\n", $4, $2, $3}'

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  5. System Load                                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

UPTIME=$(uptime)
echo "$UPTIME"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Summary                                                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

if [ $ERROR_COUNT -eq 0 ]; then
    echo "✅ All critical services operational"
    echo ""
    echo "RAM Distribution (after upgrade):"
    ps aux --sort=-%mem | head -6 | tail -5 | awk '{printf "  %s: %.0f MB\n", $11, $6/1024}'
    echo ""
    echo "📚 Next step: Deploy DependencyTrack"
    echo "   Read: 00-pre-deployment-analysis.md (section 5-7)"
    echo "   Then: 01-deployment-dependencytrack.md"
else
    echo "❌ Some services have issues:"
    echo "   - Check PostgreSQL: sudo systemctl status postgresql"
    echo "   - Check Docker: sudo systemctl status docker"
    echo "   - Restart if needed: sudo systemctl restart <service>"
fi

echo ""
echo "Timestamp: $(date)"
echo ""
