#!/bin/bash
# PC Rescue Station: VNC Server Discovery
# Task: Scan for all running VNC servers on this machine
# Output: vnc_discovery/

MAC_IP="$1"
OUTPUT_DIR="vnc_discovery"
mkdir -p "$OUTPUT_DIR"
REPORT="$OUTPUT_DIR/vnc_report.txt"

{
echo "=================================================="
echo "🔍 VNC SERVER DISCOVERY SCAN"
echo "Timestamp: $(date)"
echo "Hostname: $(hostname)"
echo "IP Addresses: $(hostname -I 2>/dev/null || ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}')"
echo "=================================================="

echo -e "\n[1/4] Checking for VNC processes..."
ps aux | grep -iE 'vnc|x11vnc|tightvnc|tigervnc|realvnc|vino' | grep -v grep

echo -e "\n[2/4] Scanning listening ports (5900-5910)..."
for port in {5900..5910}; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo "✅ Port $port is LISTENING (Display :$((port - 5900)))"
    elif ss -tuln 2>/dev/null | grep -q ":$port "; then
        echo "✅ Port $port is LISTENING (Display :$((port - 5900)))"
    fi
done

echo -e "\n[3/4] Active X11 displays..."
if command -v w >/dev/null 2>&1; then
    w | grep -E 'tty|:0|:1'
fi

echo -e "\n[4/4] Attempting VNC handshake probe..."
if [ -n "$MAC_IP" ]; then
    echo "[*] Mac Server IP: $MAC_IP"
    echo "[*] Fetching VNC diagnostic tool..."
    
    if wget -q -O "$OUTPUT_DIR/vnc_diag.py" "http://$MAC_IP:8000/scripts/vnc_diag.py" 2>/dev/null; then
        echo "[*] Running local VNC probe..."
        python3 "$OUTPUT_DIR/vnc_diag.py" 127.0.0.1 2>&1 || echo "[!] Python probe failed"
    else
        echo "[!] Could not fetch diagnostic tool from Mac server at $MAC_IP"
    fi
else
    echo "[!] Mac server IP not provided as argument"
fi

echo -e "\n=================================================="
echo "✅ VNC Discovery Scan Complete"
echo "=================================================="
} | tee "$REPORT"

echo "[*] Report saved to: $REPORT"
