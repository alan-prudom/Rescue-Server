#!/bin/bash
# Rescue Server Setup Utility
# Standard: Bash 3.2+
# Constitution: Principal I (Simplicity), III (Test-First), V (Auditing)

VERSION="20260122-2307"
echo "[*] Rescue Server Setup Utility (v$VERSION)"

# Self-chmod to ensure the script is executable
chmod +x "$0"

# --- Constants ---
BASE_DIR="${BASE_DIR:-$HOME/Desktop/rescue-site}"
AUDIT_LOG_FILE="${AUDIT_LOG_FILE:-$BASE_DIR/audit_logs/server_audit.log}"

# --- Utility Functions ---

# FR-005: Get the Mac's IP address (prioritizing en0 then en1)
get_ip_address() {
    local ip=""
    # Primary: Apple's ipconfig
    ip=$(ipconfig getifaddr en0 2>/dev/null)
    [ -z "$ip" ] && ip=$(ipconfig getifaddr en1 2>/dev/null)
    
    # Secondary: Generic ifconfig search for private IPs
    if [ -z "$ip" ]; then
        ip=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | grep -E '^(192\.168|10\.|172\.(1[6-9]|2[0-9]|3[0-1]))' | head -n 1)
    fi
    echo "$ip"
}

# Edge Case: Check if git is installed
check_git_installed() {
    if command -v git >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# FR-014: Format and append audit logs
log_audit_event() {
    local action="$1"
    local description="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    mkdir -p "$(dirname "$AUDIT_LOG_FILE")"
    echo "[$timestamp] $action: $description" >> "$AUDIT_LOG_FILE"
}

# --- Implementation Functions ---

# US1: Create the directory structure (FR-001, FR-002)
create_directories() {
    echo "Creating directory structure at $BASE_DIR..."
    mkdir -p "$BASE_DIR/scripts"
    mkdir -p "$BASE_DIR/manuals"
    mkdir -p "$BASE_DIR/drivers"
    mkdir -p "$BASE_DIR/audit_logs"
    mkdir -p "$BASE_DIR/evidence"

    # Copy custom server to base dir for portability
    mkdir -p "$BASE_DIR/server"
    cp "$(dirname "$0")/server/rescue_server.py" "$BASE_DIR/server/rescue_server.py"

    # Rule: For python projects use the uv command and a virtual environment
    if [ ! -d "$BASE_DIR/.venv" ]; then
        echo "Initializing virtual environment..."
        uv venv "$BASE_DIR/.venv" > /dev/null
    fi
}

# US1: Generate the index.html file (FR-003)
create_index_html() {
    local ip="$1"
    echo "Generating index.html..."
    cat << EOF > "$BASE_DIR/index.html"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rescue Dashboard</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; max-width: 800px; margin: 2rem auto; padding: 0 1rem; background: #f0f2f5; color: #333; }
        .container { background: white; padding: 2rem; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        h1 { margin-top: 0; color: #1a1a1a; border-bottom: 2px solid #007aff; padding-bottom: 1rem; display: flex; justify-content: space-between; align-items: center; }
        .help-link { font-size: 0.9rem; background: #34c759; color: white; padding: 0.4rem 0.8rem; border-radius: 20px; text-decoration: none; font-weight: normal; }
        .help-link:hover { opacity: 0.8; }
        h2 { margin-top: 2rem; font-size: 1.25rem; color: #444; display: flex; align-items: center; }
        ul { list-style: none; padding: 0; }
        li { margin: 0.5rem 0; padding: 0.75rem; background: #f8f9fa; border-radius: 6px; border: 1px solid #e9ecef; transition: transform 0.1s; }
        li:hover { transform: translateX(5px); border-color: #007aff; }
        a { text-decoration: none; color: #007aff; font-weight: 600; display: block; }
        .ip-placeholder { background: #fff3cd; color: #856404; padding: 1rem; border-radius: 6px; margin-bottom: 2rem; border-left: 4px solid #ffc107; }
        code { background: rgba(0,0,0,0.05); padding: 0.2rem 0.4rem; border-radius: 4px; font-family: monospace; }
    </style>
</head>
<body>

<div class="container">
    <h1>
        <span>🚑 PC Rescue Station</span>
        <a href="manuals/system_help.html" class="help-link">❓ Help Guide</a>
    </h1>
    
    <div class="ip-placeholder">
        <strong>💡 Tip:</strong> To download a file to the PC terminal, type:<br>
        <code>wget http://${ip:-[YOUR-MAC-IP]}:8000/scripts/filename.sh</code>
    </div>

    <h2>📂 Scripts & Tools</h2>
    <ul>
        <li><a href="scripts/">Browse Scripts Directory</a></li>
        <li><a href="archive/fetch_tool.sh" onclick="alert('Run this to use the proxy:\n wget http://'+window.location.host+'/scripts/fetch_tool.sh'); return false;">⬇️ Get Proxy Downloader Tool</a></li>
    </ul>

    <h2>📚 Manuals & PDFs</h2>
    <ul>
        <li><a href="manuals/">Browse Manuals Directory</a></li>
    </ul>

    <h2>💾 Drivers</h2>
    <ul>
        <li><a href="drivers/">Browse Drivers Directory</a></li>
    </ul>

    <h2>🖼️ Evidence (Uploaded from PC)</h2>
    <ul>
        <li><a href="evidence/">Browse Uploaded Evidence</a></li>
    </ul>

    <h2>📝 Instant Evidence (Paste Logs/Text)</h2>
    <form action="/" method="POST" enctype="application/x-www-form-urlencoded">
        <textarea name="content" style="width: 100%; height: 150px; border-radius: 8px; border: 1px solid #ddd; padding: 10px; font-family: monospace;" placeholder="Paste crash logs, command output, or notes here..."></textarea>
        <button type="submit" style="margin-top: 10px; background: #007aff; color: white; border: none; padding: 10px 20px; border-radius: 6px; cursor: pointer; font-weight: 600;">Save Evidence</button>
    </form>
</div>

</body>
</html>
EOF
}

# US1: Create Help Documentation (Feature 004)
create_help_docs() {
    echo "Generating help documents..."
    cat << 'EOF' > "$BASE_DIR/manuals/system_help.html"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rescue System Help</title>
    <style>
        body { font-family: sans-serif; max-width: 800px; margin: 2rem auto; line-height: 1.6; color: #333; background: #fdfdfd; padding: 0 1rem; }
        h1 { color: #007aff; border-bottom: 2px solid #eee; padding-bottom: 0.5rem; }
        h2 { color: #1d1d1f; margin-top: 2rem; border-left: 4px solid #007aff; padding-left: 1rem; }
        code { background: #f4f4f4; padding: 0.2rem 0.4rem; border-radius: 4px; font-family: monospace; }
        pre { background: #1e1e1e; color: #d4d4d4; padding: 1rem; border-radius: 8px; overflow-x: auto; }
        .note { background: #e1f5fe; padding: 1rem; border-radius: 8px; border-left: 4px solid #03a9f4; }
    </style>
</head>
<body>
    <h1>🚑 Rescue Station Help Guide</h1>
    <p>This station is designed to provide tools and a repository for PC recovery when the PC is isolated on the LAN.</p>

    <h2>📂 Using the Directories</h2>
    <ul>
        <li><strong>scripts/</strong>: Contains executable Bash scripts for automation.</li>
        <li><strong>manuals/</strong>: PDF and HTML guides for recovery procedures.</li>
        <li><strong>drivers/</strong>: Essential hardware drivers for the clean-up process.</li>
        <li><strong>evidence/</strong>: Repository for incoming logs and screenshots from the PC.</li>
    </ul>

    <h2>📜 Included Scripts</h2>
    
    <h3>1. <code>test_connection.sh</code></h3>
    <p>Verify that the PC can successfully communicate with the Mac server.</p>
    <pre>wget http://[MAC-IP]:8000/scripts/test_connection.sh<br>bash test_connection.sh</pre>

    <h3>2. <code>push_evidence.sh</code></h3>
    <p>Upload a file (log, image, screenshot) from the PC back to the Mac evidence folder.</p>
    <pre>bash push_evidence.sh my_error_log.txt</pre>

    <h2>📝 Web Dashboard Features</h2>
    <ul>
        <li><strong>Auto-indexing</strong>: All files added to the folders on the Mac appear instantly in the lists.</li>
        <li><strong>Instant Evidence</strong>: Use the text area to paste terminal output or notes. Click "Save Evidence" to create a timestamped <code>.txt</code> file on the Mac.</li>
    </ul>

    <div class="note">
        <strong>Pro Tip:</strong> Ensure you are on the same Wi-Fi or Ethernet network as the Mac for the IP address to be reachable.
    </div>

    <h3>⚠️ VNC Troubleshooting</h3>
    <p>If you see a black screen or cannot connect:</p>
    <ol>
        <li>Log out of the Linux PC.</li>
        <li>On the login screen, click the <strong>Gear Icon</strong> (⚙️).</li>
        <li>Select <strong>"GNOME on Xorg"</strong> (or "Ubuntu on Xorg").</li>
        <li>Log back in and run <code>start_vnc.sh</code> again.</li>
    </ol>
    
    <p><br><a href="../index.html">⬅️ Back to Dashboard</a></p>
</body>
</html>
EOF
}

# US1: Create sample scripts (FR-004, FR-007)
create_test_script() {
    cat << 'EOF' > "$BASE_DIR/scripts/test_connection.sh"
#!/bin/bash
# Rescue Server Connection Test
# Standard: Bash 3.2+
echo "Success! The PC can read files from the Mac server."
echo "Current Date: $(date)"
EOF
    chmod +x "$BASE_DIR/scripts/test_connection.sh"
}

# Feature 004: Proxy Download Cache (Client Tool)
create_fetch_tool_script() {
    local ip="$1"
    echo "Generating fetch_tool.sh script..."
cat << EOF > "$BASE_DIR/scripts/fetch_tool.sh"
#!/bin/bash
# Fetch Tool - Download files via Mac Proxy Cache
VERSION="20260122-2255"
echo "[*] PC Rescue Station: Fetch Tool (v\$VERSION)"
# Usage: bash fetch_tool.sh <URL> [OUTPUT_FILENAME]

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

TARGET_URL="\$1"
OUTPUT_NAME="\$2"

if [ -z "\$TARGET_URL" ]; then
    echo "Usage: \$0 <URL> [OUTPUT_FILENAME]"
    exit 1
fi

# Determine output filename if not provided
if [ -z "\$OUTPUT_NAME" ]; then
    OUTPUT_NAME=\$(basename "\$TARGET_URL")
fi

echo -e "\${BLUE}[*] Requesting: \$TARGET_URL\${NC}"
echo "    Via Proxy: http://${ip:-[MAC-IP]}:8000/proxy"

# Use curl to hit the proxy endpoint
# -J: Use Content-Disposition filename
# -O: Modify to write to file
# -L: Follow redirects (though proxy handles them usually)

if command -v curl >/dev/null 2>&1; then
    curl -f -L "http://${ip:-[MAC-IP]}:8000/proxy?url=\$TARGET_URL" -o "\$OUTPUT_NAME"
    
    if [ \$? -eq 0 ]; then
        echo -e "✅  \${GREEN}Download Complete: \$OUTPUT_NAME\${NC}"
        ls -lh "\$OUTPUT_NAME"
    else
        echo -e "\${RED}[!] Download Failed.\${NC}"
        exit 1
    fi
elif command -v wget >/dev/null 2>&1; then
    wget -O "\$OUTPUT_NAME" "http://${ip:-[MAC-IP]}:8000/proxy?url=\$TARGET_URL"
    
     if [ \$? -eq 0 ]; then
        echo -e "✅  \${GREEN}Download Complete: \$OUTPUT_NAME\${NC}"
        ls -lh "\$OUTPUT_NAME"
    else
        echo -e "\${RED}[!] Download Failed.\${NC}"
        exit 1
    fi
else
    echo "Error: Neither curl nor wget found."
    exit 1
fi
EOF
    chmod +x "$BASE_DIR/scripts/fetch_tool.sh"
}

# Feature 003: Remote Desktop Bootstrap (Mac <-> Linux VNC)
create_remote_desktop_script() {
    local ip="$1"
    local build_version="$(date "+%Y%m%d-%H%M%S")"
    echo "Generating start_vnc.sh script (v$build_version)..."
    
    # Use a quoted heredoc to avoid any expansion/escaping issues during generation
    cat << 'VNC_EOF' > "$BASE_DIR/scripts/start_vnc.sh"
#!/bin/bash
# One-Click VNC Bootstrap
# Target: macOS Screen Sharing.app
# BUILD_VERSION_PLACEHOLDER

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
# MAC_SERVER_URL placeholder will be replaced by sed

log_status() {
    local msg="$1"
    printf "%s\n" "$msg"
    if command -v curl >/dev/null 2>&1; then
        curl -s -d "content=[VNC-STATUS] $msg" "$MAC_SERVER_URL/" >/dev/null &
    fi
}

printf "${BLUE}[*] PC Rescue Station: Remote Desktop Bootstrap (v$VERSION)${NC}\n"
log_status "Bootstrapping VNC (v$VERSION) on $(hostname)..."

# 0. Cleanup
sudo killall x11vnc x0vncserver vino-server gnome-remote-desktop-daemon 2>/dev/null || true
sleep 1

# 1. Firewall
if command -v ufw >/dev/null 2>&1; then sudo ufw disable >/dev/null 2>&1; fi
if command -v systemctl >/dev/null 2>&1; then sudo systemctl stop firewalld 2>/dev/null; fi

# 2. Environment
VNC_BIN="x11vnc"
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    if command -v grdctl >/dev/null 2>&1 || [ -f "/usr/bin/grdctl" ]; then
        VNC_BIN="gnome-remote-desktop"
    fi
fi

# 3. Launch
MY_IP=$(hostname -I | cut -d' ' -f1)
log_status "Starting $VNC_BIN on $MY_IP:5900..."

if [ "$VNC_BIN" = "gnome-remote-desktop" ]; then
    grdctl --system vnc enable 2>/dev/null
    grdctl --system vnc set-auth-method password
    grdctl --system vnc set-password "rescue"
    systemctl --user restart gnome-remote-desktop
    log_status "GNOME Remote Desktop started."
else
    mkdir -p ~/.vnc
    XAUTH=$(find /run/user/$(id -u) -name Xauthority 2>/dev/null | head -n 1)
    
    # Kill any existing
    sudo killall x11vnc 2>/dev/null || true
    
    if [ -n "$XAUTH" ]; then
        log_status "Using XAuth: $XAUTH"
        sudo x11vnc -listen 0.0.0.0 -display :0 -auth "$XAUTH" -forever -shared -nopw -bg -noshm -o ~/.vnc/x11vnc.log 2>/dev/null
    else
        sudo x11vnc -listen 0.0.0.0 -display :0 -auth guess -forever -shared -nopw -bg -noshm -o ~/.vnc/x11vnc.log 2>/dev/null
    fi
    
    sleep 3
    if ! pgrep x11vnc >/dev/null; then
        log_status "Display :0 cold boot. Trying :1..."
        if [ -n "$XAUTH" ]; then
             sudo x11vnc -listen 0.0.0.0 -display :1 -auth "$XAUTH" -forever -shared -nopw -bg -noshm -o ~/.vnc/x11vnc.log 2>/dev/null
        else
             sudo x11vnc -listen 0.0.0.0 -display :1 -auth guess -forever -shared -nopw -bg -noshm -o ~/.vnc/x11vnc.log 2>/dev/null
        fi
        sleep 3
    fi

    if pgrep x11vnc >/dev/null; then
        log_status "x11vnc is running."
    else
        log_status "ERROR: x11vnc failed to start. Uploading log..."
        if [ -f ~/.vnc/x11vnc.log ]; then
            sudo curl -s -X POST -F "file=@$HOME/.vnc/x11vnc.log" "$MAC_SERVER_URL/" >/dev/null
            log_status "Log uploaded to Mac: evidence/ (Check x11vnc.log)"
        fi
    fi
fi

sleep 2
log_status "READY: vnc://$MY_IP:5900 (NO PASSWORD)"
printf "${GREEN}--------------------------------------------------${NC}\n"
printf "✅  ${GREEN}SUCCESS: VNC Ready!${NC}\n"
printf "    Connect using:  ${BLUE}vnc://$MY_IP:5900${NC}\n"
printf "${GREEN}--------------------------------------------------${NC}\n"
VNC_EOF

    # Replace placeholder with actual build version
    sed -i '' "s|# BUILD_VERSION_PLACEHOLDER|VERSION=\"$build_version\"|" "$BASE_DIR/scripts/start_vnc.sh" 2>/dev/null || \
    sed -i "s|# BUILD_VERSION_PLACEHOLDER|VERSION=\"$build_version\"|" "$BASE_DIR/scripts/start_vnc.sh"
    
    # Replace placeholder with actual IP
    local server_url="http://${ip:-localhost}:8000"
    sed -i '' "s|# MAC_SERVER_URL placeholder will be replaced by sed|MAC_SERVER_URL=\"$server_url\"|" "$BASE_DIR/scripts/start_vnc.sh" 2>/dev/null || \
    sed -i "s|# MAC_SERVER_URL placeholder will be replaced by sed|MAC_SERVER_URL=\"$server_url\"|" "$BASE_DIR/scripts/start_vnc.sh"

    chmod +x "$BASE_DIR/scripts/start_vnc.sh"
}

# Feature 003/Fallback: Consolidated Master Bootstrap (VNC + X11)
create_master_bootstrap_script() {
    local ip="$1"
    local build_version="$(date "+%Y%m%d-%H%M%S")"
    echo "Generating pc_rescue_bootstrap.sh..."
    
    cat << 'BOOT_EOF' > "$BASE_DIR/scripts/pc_rescue_bootstrap.sh"
#!/bin/bash
# Consolidated Rescue Bootstrap (VNC + X11 Forwarding)
VERSION="20260122-2320"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
# MAC_SERVER_URL placeholder replaced by sed

log_status() {
    printf "${BLUE}[*] %s${NC}\n" "$1"
    if command -v curl >/dev/null 2>&1; then
        curl -s -d "content=[BOOTSTRAP] $1" "$MAC_SERVER_URL/" >/dev/null &
    fi
}

printf "${BLUE}==================================================${NC}\n"
printf "${BLUE}    PC RESCUE STATION: MASTER BOOTSTRAP (v$VERSION)${NC}\n"
printf "${BLUE}==================================================${NC}\n"

# 1. System Prep
log_status "Checking dependencies..."
if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y >/dev/null 2>&1
    sudo apt-get install -y x11vnc openssh-server curl net-tools >/dev/null 2>&1
fi

# 2. X11 Forwarding (The "Easy" Fallback)
log_status "Configuring SSH/X11 Forwarding..."
sudo sed -i 's/^#X11Forwarding.*/X11Forwarding yes/' /etc/ssh/sshd_config 2>/dev/null
sudo systemctl enable ssh >/dev/null 2>&1
sudo systemctl restart ssh >/dev/null 2>&1

# 3. Network/Firewall
log_status "Opening Ports (VNC/SSH/Web)..."
if command -v ufw >/dev/null 2>&1; then
    sudo ufw allow 5900/tcp >/dev/null 2>&1
    sudo ufw allow 22/tcp >/dev/null 2>&1
    sudo ufw disable >/dev/null 2>&1
fi

# 4. Launch VNC (The "Full Desktop" Primary)
MY_IP=$(hostname -I | cut -d' ' -f1)
log_status "Downloading helper scripts..."
curl -s -O "$MAC_SERVER_URL/scripts/start_vnc.sh"
curl -s -O "$MAC_SERVER_URL/scripts/push_evidence.sh"
chmod +x start_vnc.sh push_evidence.sh

log_status "Launching VNC Desktop Mirror..."
./start_vnc.sh >/dev/null 2>&1 &

sleep 5
printf "\n${GREEN}✅  PC PREPPED FOR RESCUE!${NC}\n"
printf "%s\n" "--------------------------------------------------"
printf "${BLUE}OPTION A (Full Desktop - Primary):${NC}\n"
printf "   Connect using Mac Screen Sharing app:\n"
printf "   ${GREEN}vnc://$MY_IP:5900${NC}\n\n"

printf "${BLUE}OPTION B (Single App - Fallback):${NC}\n"
printf "   Connect via Mac Terminal (requires XQuartz):\n"
printf "   ${GREEN}ssh -X $(whoami)@$MY_IP \"firefox\"${NC}\n"
printf "%s\n" "--------------------------------------------------"

# 5. Heartbeat Loop (FR-015: Periodic Status Updates)
log_status "Entering heartbeat loop (2m interval)..."
while true; do
  VNC_STATE="STOPPED"
  if pgrep x11vnc >/dev/null || pgrep gnome-remote-desktop >/dev/null; then
    VNC_STATE="RUNNING"
  fi
  
  # Status includes connection commands as requested
  HEARTBEAT="[HEARTBEAT] VNC: $VNC_STATE | Connect: vnc://$MY_IP:5900 | SSH: ssh -X $(whoami)@$MY_IP"
  log_status "$HEARTBEAT"
  sleep 120
done
BOOT_EOF

    # Replace placeholder
    local server_url="http://${ip:-localhost}:8000"
    sed -i '' "s|# MAC_SERVER_URL placeholder replaced by sed|MAC_SERVER_URL=\"$server_url\"|" "$BASE_DIR/scripts/pc_rescue_bootstrap.sh" 2>/dev/null || \
    sed -i "s|# MAC_SERVER_URL placeholder replaced by sed|MAC_SERVER_URL=\"$server_url\"|" "$BASE_DIR/scripts/pc_rescue_bootstrap.sh"

    chmod +x "$BASE_DIR/scripts/pc_rescue_bootstrap.sh"
}

# US3: Client-side evidence uploader (Feature 002)
create_push_evidence_script() {
    local ip="$1"
    cat << EOF > "$BASE_DIR/scripts/push_evidence.sh"
#!/bin/bash
# Client Evidence Uploader
VERSION="20260122-2253"
echo "[*] PC Rescue Station: Evidence Uploader (v\$VERSION)"
# Standard: Bash 3.2+
# Usage: ./push_evidence.sh <file_path>

FILE="\$1"
if [ -z "\$FILE" ]; then
    echo "Usage: \$0 <file_path>"
    exit 1
fi

if [ ! -f "\$FILE" ]; then
    echo "Error: File \$FILE not found."
    exit 1
fi

echo "Uploading \$FILE to Mac Server (${ip:-[YOUR-MAC-IP]})..."
curl -X POST -F "file=@\$FILE" http://${ip:-localhost}:8000/
EOF
    chmod +x "$BASE_DIR/scripts/push_evidence.sh"
}

# US3: Git initialization (FR-009, FR-010, FR-011)
init_git_repo() {
    if ! check_git_installed; then
        echo "⚠️ Warning: Git not found. Skipping versioning initialization."
        return 0
    fi
    
    echo "Initializing Git repository..."
    (
        cd "$BASE_DIR" || exit 1
        git init > /dev/null
        
        # FR-010: .gitignore
        cat << EOF > .gitignore
.DS_Store
Thumbs.db
*.tmp
EOF

        git add .
        git commit -m "Initial commit: Rescue Server Setup" --quiet
    )
}

# US2: Manual instructions (FR-006)
print_manual_instructions() {
    local ip="$1"
    echo "-------------------------------------------------------"
    echo "✅ Setup Complete!"
    echo ""
    echo "Files are located at: $BASE_DIR"
    echo ""
    echo "🚀 ONE-CLICK PC SETUP:"
    if [ -n "$ip" ]; then
        echo "   wget http://$ip:8000/scripts/pc_rescue_bootstrap.sh"
        echo "   sh pc_rescue_bootstrap.sh"
    else
        echo "   wget http://[MAC-IP]:8000/scripts/pc_rescue_bootstrap.sh"
        echo "   sh pc_rescue_bootstrap.sh"
    fi
    echo ""
    echo "To start the Mac server manually:"
    echo "cd $BASE_DIR && uv run python server/rescue_server.py 8000"
    echo ""
    echo "🛠️  TO TEST PROXY DOWNLOADER (On PC):"
    echo "   ./scripts/fetch_tool.sh https://www.google.com google.html"
    echo "-------------------------------------------------------"
}

# US2: Interactive launch (FR-008)
prompt_and_launch() {
    # Check if inside a TTY
    if [ ! -t 0 ]; then
        return 0
    fi
    
    read -p "Do you want to start the server now? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Starting server on port 8000..."
        cd "$BASE_DIR" && uv run python server/rescue_server.py 8000
    fi
}

# --- Main Execution ---

main() {
    local ip=$(get_ip_address)
    
    create_directories
    create_index_html "$ip"
    create_help_docs
    create_test_script
    create_push_evidence_script "$ip"
    create_remote_desktop_script "$ip"
    create_master_bootstrap_script "$ip"
    create_fetch_tool_script "$ip"
    
    log_audit_event "SETUP" "Directories and scripts generated."
    
    init_git_repo
    
    print_manual_instructions "$ip"
    prompt_and_launch
}

# If not being sourced, run main
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main
fi