#!/bin/bash
# PC Rescue Station: Network Diagnostic
# Task: Network connectivity, DNS, routing, firewall status
# Output: network_diagnostic/

MAC_IP="$1"
OUTPUT_DIR="network_diagnostic"
mkdir -p "$OUTPUT_DIR"
REPORT="$OUTPUT_DIR/network_report.txt"

{
echo "=================================================="
echo "🌐 NETWORK DIAGNOSTIC SCAN"
echo "Timestamp: $(date)"
echo "=================================================="

echo -e "\n[1/6] Network Interfaces & IP Addresses..."
ip addr show

echo -e "\n[2/6] Routing Table..."
ip route show

echo -e "\n[3/6] DNS Configuration..."
cat /etc/resolv.conf

echo -e "\n[4/6] Active Network Connections..."
ss -tunap 2>/dev/null || netstat -tunap 2>/dev/null

echo -e "\n[5/6] Firewall Status..."
if command -v ufw >/dev/null 2>&1; then
    sudo ufw status verbose
elif command -v firewall-cmd >/dev/null 2>&1; then
    sudo firewall-cmd --list-all
else
    echo "[!] No recognized firewall tool found"
fi

echo -e "\n[6/6] Connectivity Tests..."
echo "--- Ping Gateway ---"
GATEWAY=$(ip route | grep default | awk '{print $3}' | head -n 1)
if [ -n "$GATEWAY" ]; then
    ping -c 3 "$GATEWAY"
else
    echo "[!] No default gateway found"
fi

echo "--- Ping External (8.8.8.8) ---"
ping -c 3 8.8.8.8

if [ -n "$MAC_IP" ]; then
    echo "--- Ping Mac Server ($MAC_IP) ---"
    ping -c 3 "$MAC_IP"
fi

echo -e "\n=================================================="
echo "✅ Network Diagnostic Complete"
echo "=================================================="
} | tee "$REPORT"

echo "[*] Report saved to: $REPORT"
