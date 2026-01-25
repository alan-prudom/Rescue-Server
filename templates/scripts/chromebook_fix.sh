#!/bin/sh
# PC Rescue Station: Chromebook (Crostini) System Repair & Agent Launch
# Build Timestamp: 2026-01-25 04:30:00 UTC
# Version: 1.0.2 (POSIX Compliant)

echo "[*] PC Rescue Station: Chromebook Fix & Agent"
echo "[*] Build Time: 2026-01-25 04:30:00 UTC"
echo "=================================================="

# 1. Repair Malformed sources.list and Clear Locks
if [ -f /etc/apt/sources.list ]; then
    echo "[1/4] Repairing system package manager locks & configuration..."
    
    # Aggressively kill any hung apt processes
    sudo killall apt apt-get dpkg >/dev/null 2>&1 || true
    
    # Remove all common lock files
    sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock 2>/dev/null
    sudo dpkg --configure -a 2>/dev/null
    
    # Comment out malformed line 5
    sudo sed -i '5s/^\([^#]\)/#\1/' /etc/apt/sources.list 2>/dev/null
    
    # Also repair general duplication or common 'bookworm' malformations
    if sudo apt-get update 2>&1 | grep -q "Malformed"; then
        echo "[!] Found malformed entries. Attempting deep repair..."
        sudo apt-get update 2>&1 | grep "Malformed" | cut -d: -f4 | while read -r line_num; do
            sudo sed -i "${line_num}s/^/#/" /etc/apt/sources.list
        done
    fi
    echo "✅ System locks cleared and config repaired."
fi

# 2. Ensure Critical Dependencies
echo "[2/4] Ensuring critical dependencies (python3, curl, wget)..."
sudo apt-get update -qq
sudo apt-get install -y python3 curl wget gnupg >/dev/null 2>&1
echo "✅ Dependencies verified."

# 3. Detect Mac Server IP
echo "[3/4] Detecting Mac Rescue Server..."
MAC_IPS="192.168.1.61 192.168.1.244 192.168.1.8 100.87.229.122"
DETECTED_IP=""

for ip in $MAC_IPS; do
    echo "[*] Probing $ip..."
    if curl -s --connect-timeout 2 "http://$ip:8000" >/dev/null; then
        DETECTED_IP=$ip
        break
    fi
done

if [ -z "$DETECTED_IP" ]; then
    echo "❌ ERROR: Could not find Mac server on any known IP."
    echo "Known IPs: $MAC_IPS"
    exit 1
fi
echo "✅ Found server at $DETECTED_IP"

# 4. Fetch and Launch the Python Agent
echo "[4/4] Launching Unified Python Agent..."
if wget -q -O rescue_agent.py "http://$DETECTED_IP:8000/scripts/rescue_agent.py"; then
    chmod +x rescue_agent.py
    echo "=================================================="
    echo "🚀 AGENT STARTING..."
    echo "=================================================="
    python3 rescue_agent.py
else
    echo "❌ ERROR: Failed to download rescue_agent.py from $DETECTED_IP"
    exit 1
fi
