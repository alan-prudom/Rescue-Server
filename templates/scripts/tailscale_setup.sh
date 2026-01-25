#!/bin/bash
# PC Rescue Station: Tailscale VPN Setup & Status
# Task: Check, install, and configure Tailscale VPN
# Output: tailscale_status/

MAC_IP="$1"
OUTPUT_DIR="tailscale_status"
mkdir -p "$OUTPUT_DIR"
REPORT="$OUTPUT_DIR/tailscale_report.txt"

{
echo "=================================================="
echo "🔐 TAILSCALE VPN SETUP & STATUS"
echo "Timestamp: $(date)"
echo "Hostname: $(hostname)"
echo "=================================================="

# Check if Tailscale is installed
echo -e "\n[1/5] Checking for Tailscale installation..."
if command -v tailscale >/dev/null 2>&1; then
    TAILSCALE_VERSION=$(tailscale version 2>/dev/null | head -1)
    echo "✅ Tailscale is installed: $TAILSCALE_VERSION"
    INSTALLED=true
else
    echo "❌ Tailscale is NOT installed"
    INSTALLED=false
fi

# Install if not present
if [ "$INSTALLED" = "false" ]; then
    echo -e "\n[2/5] Installing Tailscale..."
    
    # Detect package manager and install
    if command -v apt-get >/dev/null 2>&1; then
        echo "[*] Using apt (Debian/Ubuntu)..."
        echo "[*] Ensuring curl and gnupg are present..."
        sudo apt-get update -qq
        sudo apt-get install -y curl gnupg >/dev/null 2>&1
        
        # Specific fix for Chromebook penguin environment
        if [ "$(hostname)" = "penguin" ]; then
            echo "[*] Detected Chromebook environment, applying pre-install fixes..."
            sudo apt-get update || true
        fi
        
        echo "[*] Running official Tailscale installer..."
        if curl -fsSL https://tailscale.com/install.sh | sh; then
            echo "✅ Official installer successful"
        else
            echo "⚠️  Official installer failed, trying manual apt-get method..."
            # Manual fallback for Debian/Ubuntu
            . /etc/os-release
            sudo mkdir -p --mode=0755 /usr/share/keyrings
            curl -fsSL "https://pkgs.tailscale.com/stable/$ID/$VERSION_CODENAME.noarmor.gpg" | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
            curl -fsSL "https://pkgs.tailscale.com/stable/$ID/$VERSION_CODENAME.tailscale-keyring.list" | sudo tee /etc/apt/sources.list.d/tailscale.list
            sudo apt-get update
            sudo apt-get install -y tailscale
        fi
    elif command -v yum >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
        echo "[*] Using yum/dnf (RHEL/CentOS/Fedora)..."
        curl -fsSL https://tailscale.com/install.sh | sh
    elif command -v pacman >/dev/null 2>&1; then
        echo "[*] Using pacman (Arch)..."
        sudo pacman -S tailscale --noconfirm
    else
        echo "❌ ERROR: No supported package manager found"
        echo "Please install Tailscale manually from: https://tailscale.com/download"
        exit 1
    fi
    
    # Verify installation
    if command -v tailscale >/dev/null 2>&1; then
        echo "✅ Tailscale installed successfully"
        TAILSCALE_VERSION=$(tailscale version 2>/dev/null | head -1)
        echo "   Version: $TAILSCALE_VERSION"
    else
        echo "❌ ERROR: Tailscale installation failed"
        exit 1
    fi
else
    echo "[2/5] Skipping installation (already installed)"
fi

# Check if tailscaled daemon is running
echo -e "\n[3/5] Checking Tailscale daemon status..."
if systemctl is-active --quiet tailscaled 2>/dev/null; then
    echo "✅ tailscaled daemon is running"
elif pgrep tailscaled >/dev/null 2>&1; then
    echo "✅ tailscaled process is running"
else
    echo "⚠️  tailscaled daemon is not running. Starting..."
    sudo systemctl enable --now tailscaled 2>/dev/null || sudo tailscaled &
    sleep 2
    
    if pgrep tailscaled >/dev/null 2>&1; then
        echo "✅ tailscaled started successfully"
    else
        echo "❌ ERROR: Could not start tailscaled"
    fi
fi

# Check connection status
echo -e "\n[4/5] Checking Tailscale connection status..."
TAILSCALE_STATUS=$(tailscale status 2>&1)

if echo "$TAILSCALE_STATUS" | grep -q "Logged out"; then
    echo "⚠️  Tailscale is installed but NOT logged in"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔑 LOGIN REQUIRED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "To connect this PC to your Tailscale network:"
    echo ""
    echo "1. Run the following command:"
    echo "   sudo tailscale up"
    echo ""
    echo "2. You will receive a login URL"
    echo "3. Open the URL in a browser"
    echo "4. Login with your Gmail account linked to Tailscale"
    echo "5. Authorize this device"
    echo ""
    echo "Attempting to start login process now..."
    echo ""
    
    # Start the login process (will output URL)
    sudo tailscale up 2>&1 | tee "$OUTPUT_DIR/login_url.txt"
    
    echo ""
    echo "⚠️  Login URL saved to: $OUTPUT_DIR/login_url.txt"
    echo "⚠️  Please complete the login in a browser"
    echo ""
    
    LOGGED_IN=false
    TAILSCALE_IP="Not connected (login required)"
    
elif echo "$TAILSCALE_STATUS" | grep -q "100\."; then
    echo "✅ Tailscale is connected and running"
    LOGGED_IN=true
    
    # Extract Tailscale IP
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null)
    if [ -z "$TAILSCALE_IP" ]; then
        TAILSCALE_IP=$(echo "$TAILSCALE_STATUS" | grep -oE '100\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    fi
    
    echo "   Tailscale IP: $TAILSCALE_IP"
else
    echo "⚠️  Tailscale status unclear"
    LOGGED_IN=false
    TAILSCALE_IP="Unknown"
fi

# Get detailed status
echo -e "\n[5/5] Tailscale network details..."
if [ "$LOGGED_IN" = "true" ]; then
    echo "--- Full Status ---"
    tailscale status
    
    echo -e "\n--- Network Information ---"
    echo "Tailscale IPv4: $(tailscale ip -4 2>/dev/null || echo 'N/A')"
    echo "Tailscale IPv6: $(tailscale ip -6 2>/dev/null || echo 'N/A')"
    
    echo -e "\n--- Peer Connections ---"
    tailscale status | grep -v "^#" | tail -n +2
    
    echo -e "\n--- Network Routes ---"
    ip route | grep tailscale || echo "No Tailscale routes found"
else
    echo "Cannot retrieve network details (not logged in)"
fi

# Summary
echo -e "\n=================================================="
echo "📊 TAILSCALE STATUS SUMMARY"
echo "=================================================="
echo "Installed: $([ "$INSTALLED" = "true" ] && echo "✅ Yes" || echo "❌ No")"
echo "Version: ${TAILSCALE_VERSION:-N/A}"
echo "Daemon Running: $(pgrep tailscaled >/dev/null && echo "✅ Yes" || echo "❌ No")"
echo "Logged In: $([ "$LOGGED_IN" = "true" ] && echo "✅ Yes" || echo "⚠️  No - Login Required")"
echo "Tailscale IP: $TAILSCALE_IP"

if [ "$LOGGED_IN" = "false" ]; then
    echo ""
    echo "⚠️  ACTION REQUIRED:"
    echo "   1. Check $OUTPUT_DIR/login_url.txt for the login URL"
    echo "   2. Open the URL in a browser"
    echo "   3. Login with your Gmail account"
    echo "   4. Re-run this script to verify connection"
fi

echo "=================================================="
echo "✅ Tailscale Check Complete"
echo "=================================================="

# Create JSON output for capabilities
cat > "$OUTPUT_DIR/tailscale_info.json" << EOF
{
  "installed": $INSTALLED,
  "version": "${TAILSCALE_VERSION:-N/A}",
  "daemon_running": $(pgrep tailscaled >/dev/null && echo "true" || echo "false"),
  "logged_in": $LOGGED_IN,
  "tailscale_ip": "$TAILSCALE_IP",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date)"
}
EOF

echo ""
echo "[*] JSON output saved to: $OUTPUT_DIR/tailscale_info.json"

} | tee "$REPORT"

echo "[*] Full report saved to: $REPORT"
