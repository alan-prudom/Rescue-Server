#!/bin/bash
# Rescue Server Setup Utility
# Standard: Bash 3.2+
# Constitution: Principal I (Simplicity), III (Test-First), V (Auditing)

# Self-chmod to ensure the script is executable
chmod +x "$0"

# --- Constants ---
BASE_DIR="${BASE_DIR:-$HOME/Desktop/rescue-site}"
AUDIT_LOG_FILE="${AUDIT_LOG_FILE:-$BASE_DIR/audit_logs/server_audit.log}"

# --- Utility Functions ---

# FR-005: Get the Mac's IP address (prioritizing en0 then en1)
get_ip_address() {
    local ip=""
    ip=$(ipconfig getifaddr en0)
    if [ -z "$ip" ]; then
        ip=$(ipconfig getifaddr en1)
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
    echo "Generating start_vnc.sh script..."
cat << 'EOF' > "$BASE_DIR/scripts/start_vnc.sh"
#!/bin/bash
# One-Click VNC Bootstrap for Rescue Operations
# Compatible with Ubuntu, Fedora, Debian, SystemRescue
# Target: macOS Screen Sharing.app

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[*] PC Rescue Station: Remote Desktop Bootstrap${NC}"

# 1. Disable Firewall (Common blocker on Fedora/RHEL)
if command -v systemctl >/dev/null 2>&1; then
    echo "  -> Stopping firewalld/ufw to allow VNC..."
    sudo systemctl stop firewalld 2>/dev/null
    sudo systemctl stop ufw 2>/dev/null
fi

# 2. Detect Environment & Choose Server
VNC_BIN=""
USE_WAYLAND=0

if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
    echo -e "${BLUE}[*] Wayland detected. Preferring tigervnc (x0vncserver).${NC}"
    USE_WAYLAND=1
else
    # Ensure DISPLAY is set for X11
    if [ -z "$DISPLAY" ]; then
        export DISPLAY=:0
    fi
fi

# 3. Check/Install Dependencies
if [ "$USE_WAYLAND" -eq 1 ]; then
    # Wayland Path: Try x0vncserver
    if ! command -v x0vncserver >/dev/null 2>&1; then
        echo "  -> Installing tigervnc-server for Wayland support..."
        if command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y tigervnc-server
        elif command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y tigervnc-scraping-server
        fi
    fi
    VNC_BIN="x0vncserver"
else
    # X11 Path: Prefer x11vnc
    if ! command -v x11vnc >/dev/null 2>&1; then
        echo "  -> Installing x11vnc..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y x11vnc net-tools
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y x11vnc
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm x11vnc
        fi
    fi
    VNC_BIN="x11vnc"
fi

# 4. Launch VNC
MY_IP=$(hostname -I | cut -d' ' -f1)
echo -e "${GREEN}[*] Starting VNC Server ($VNC_BIN)...${NC}"

if [ "$VNC_BIN" == "x0vncserver" ]; then
    # TigerVNC logic (Works on Wayland/X11)
    # create password file manually
    mkdir -p ~/.vnc
    echo "rescue" | vncpasswd -f > ~/.vnc/passwd
    chmod 600 ~/.vnc/passwd
    
    # Launch with Mac compatibility flags
    x0vncserver -passwordfile ~/.vnc/passwd -display :0 &
    
    echo ""
    echo -e "✅  ${GREEN}SUCCESS: Wayland VNC Ready!${NC}"

elif [ "$VNC_BIN" == "x11vnc" ]; then
    # Legacy X11 logic
    mkdir -p ~/.vnc
    x11vnc -storepasswd "rescue" ~/.vnc/passwd
    x11vnc -display :0 -auth guess -forever -shared -rfbauth ~/.vnc/passwd -bg -o ~/.vnc/x11vnc.log
    
    echo ""
    echo -e "✅  ${GREEN}SUCCESS: X11 VNC Ready!${NC}"
fi

echo -e "    Connect from Mac using:  ${BLUE}vnc://${MY_IP}:5900${NC}"
echo -e "    Password:               ${BLUE}rescue${NC}"
EOF
    chmod +x "$BASE_DIR/scripts/start_vnc.sh"
}

# US3: Client-side evidence uploader (Feature 002)
create_push_evidence_script() {
    local ip="$1"
    cat << EOF > "$BASE_DIR/scripts/push_evidence.sh"
#!/bin/bash
# Client Evidence Uploader
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
    echo "To start the server manually:"
    echo "cd $BASE_DIR && uv run python server/rescue_server.py 8000"
    echo ""
    echo "Then visit on your PC:"
    if [ -n "$ip" ]; then
        echo "http://$ip:8000"
    else
        echo "http://[YOUR-IP-ADDRESS]:8000 (Could not auto-detect IP)"
    fi
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
    
    log_audit_event "SETUP" "Directories and scripts generated."
    
    init_git_repo
    
    print_manual_instructions "$ip"
    prompt_and_launch
}

# If not being sourced, run main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi