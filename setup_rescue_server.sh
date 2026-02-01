#!/bin/bash
# Rescue Server Setup Utility
# Standard: Bash 3.2+
# Constitution: Principal I (Simplicity), III (Test-First), V (Auditing)

VERSION="20260123-1123"
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

# Principal I (Simplicity): Modular template provisioner
provision_template() {
    local template_path="$1"
    local dest_path="$2"
    local ip="$3"
    local version="${4:-$VERSION}"
    local server_url="http://${ip:-localhost}:8000"

    if [ ! -f "$template_path" ]; then
        echo "⚠️  Error: Template not found at $template_path"
        return 1
    fi

    # Replace placeholders and write to destination
    sed "s|{{MAC_IP}}|$ip|g" "$template_path" | \
    sed "s|{{VERSION}}|$version|g" | \
    sed "s|{{MAC_SERVER_URL}}|$server_url|g" > "$dest_path"

    return 0
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
    mkdir -p "$BASE_DIR/templates/web"

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
    provision_template "$(dirname "$0")/templates/web/index.html" "$BASE_DIR/index.html" "$ip"
}

# US1: Create Help Documentation (Feature 004)
create_help_docs() {
    echo "Generating help documents..."
    provision_template "$(dirname "$0")/templates/web/manuals/system_help.html" "$BASE_DIR/manuals/system_help.html" "$ip"
}

# Phase 4/FR-017: Create UI Templates
create_ui_templates() {
    echo "Generating real-time UI templates..."
    provision_template "$(dirname "$0")/templates/web/command_output.html" "$BASE_DIR/templates/web/command_output.html" "$ip"
    provision_template "$(dirname "$0")/templates/web/live_feed.html" "$BASE_DIR/templates/web/live_feed.html" "$ip"
    provision_template "$(dirname "$0")/templates/web/instructions.html" "$BASE_DIR/templates/web/instructions.html" "$ip"
}

# US1: Create sample scripts (FR-004, FR-007)
create_test_script() {
    echo "Generating test_connection.sh..."
    provision_template "$(dirname "$0")/templates/scripts/test_connection.sh" "$BASE_DIR/scripts/test_connection.sh" "$ip"
    chmod +x "$BASE_DIR/scripts/test_connection.sh"
}

# Feature 004: Proxy Download Cache (Client Tool)
create_fetch_tool_script() {
    local ip="$1"
    echo "Generating fetch_tool.sh script..."
    provision_template "$(dirname "$0")/templates/scripts/fetch_tool.sh" "$BASE_DIR/scripts/fetch_tool.sh" "$ip"
    chmod +x "$BASE_DIR/scripts/fetch_tool.sh"
}

# Feature 002: Dynamic Instructions (Placeholder)
create_dynamic_instructions() {
    provision_template "$(dirname "$0")/templates/scripts/instructions.sh" "$BASE_DIR/scripts/instructions.sh" "$ip"
    chmod +x "$BASE_DIR/scripts/instructions.sh"
}

# Phase 4: Diagnostic & Advanced Collection
create_diagnostic_scripts() {
    echo "Generating diagnostic tools..."
    provision_template "$(dirname "$0")/templates/scripts/diag_vnc.sh" "$BASE_DIR/scripts/diag_vnc.sh" "$ip"
    chmod +x "$BASE_DIR/scripts/diag_vnc.sh"
    
    provision_template "$(dirname "$0")/templates/scripts/vnc_diag.py" "$BASE_DIR/scripts/vnc_diag.py" "$ip"
    provision_template "$(dirname "$0")/templates/scripts/capabilities_profiler.sh" "$BASE_DIR/scripts/capabilities_profiler.sh" "$ip"
    chmod +x "$BASE_DIR/scripts/capabilities_profiler.sh"
}

# Phase 5: Smart Sync & Agent Integration
create_agent_scripts() {
    echo "Generating intelligent agent and sync helpers..."
    provision_template "$(dirname "$0")/templates/scripts/render_output.py" "$BASE_DIR/scripts/render_output.py" "$ip"
    provision_template "$(dirname "$0")/templates/scripts/handshake_server.py" "$BASE_DIR/scripts/handshake_server.py" "$ip"
    provision_template "$(dirname "$0")/templates/scripts/rescue_agent.py" "$BASE_DIR/scripts/rescue_agent.py" "$ip"
    provision_template "$(dirname "$0")/templates/scripts/execute_instruction.sh" "$BASE_DIR/scripts/execute_instruction.sh" "$ip"
    chmod +x "$BASE_DIR/scripts/execute_instruction.sh"
}

# Feature 003: Remote Desktop Bootstrap (Mac <-> Linux VNC)
create_remote_desktop_script() {
    local ip="$1"
    local build_version="$(date "+%Y%m%d-%H%M%S")"
    echo "Generating start_vnc.sh script (v$build_version)..."
    
    provision_template "$(dirname "$0")/templates/scripts/start_vnc.sh" "$BASE_DIR/scripts/start_vnc.sh" "$ip" "$build_version"
    chmod +x "$BASE_DIR/scripts/start_vnc.sh"
}

# Feature 003/Fallback: Consolidated Master Bootstrap (VNC + X11)
create_master_bootstrap_script() {
    local ip="$1"
    echo "Generating pc_rescue_bootstrap.sh..."
    
    provision_template "$(dirname "$0")/templates/scripts/pc_rescue_bootstrap.sh" "$BASE_DIR/scripts/pc_rescue_bootstrap.sh" "$ip"
    chmod +x "$BASE_DIR/scripts/pc_rescue_bootstrap.sh"
}

# Feature 007: Chromebook Specialized Fixes
create_chromebook_scripts() {
    echo "Generating Chromebook specialized tools..."
    provision_template "$(dirname "$0")/templates/scripts/chromebook_fix.sh" "$BASE_DIR/scripts/chromebook_fix.sh" "$ip"
    chmod +x "$BASE_DIR/scripts/chromebook_fix.sh"
    provision_template "$(dirname "$0")/templates/scripts/cb_power_pack.sh" "$BASE_DIR/scripts/cb_power_pack.sh" "$ip"
    chmod +x "$BASE_DIR/scripts/cb_power_pack.sh"
}

# US3: Client-side evidence uploader (Feature 002)
create_push_evidence_script() {
    local ip="$1"
    echo "Generating push_evidence.sh uploader..."
    provision_template "$(dirname "$0")/templates/scripts/push_evidence.sh" "$BASE_DIR/scripts/push_evidence.sh" "$ip"
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
    create_dynamic_instructions "$ip"
    create_diagnostic_scripts "$ip"
    create_agent_scripts "$ip"
    create_ui_templates "$ip"
    create_chromebook_scripts "$ip"
    
    log_audit_event "SETUP" "Directories and scripts generated."
    
    init_git_repo
    
    print_manual_instructions "$ip"
    prompt_and_launch
}

# If not being sourced, run main
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main
fi