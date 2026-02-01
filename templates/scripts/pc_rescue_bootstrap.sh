#!/bin/bash
# Consolidated Rescue Bootstrap (VNC + X11 Forwarding)
VERSION="20260123-1123"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# MAC_SERVER_URL set by setup provisioner
MAC_SERVER_URL="http://192.168.1.61:8000"

log_status() {
    printf "${BLUE}[*] %s${NC}\n" "$1"
    if command -v curl >/dev/null 2>&1; then
        curl -s -d "content=[BOOTSTRAP] $1" "$MAC_SERVER_URL/" >/dev/null &
    elif command -v wget >/dev/null 2>&1; then
        wget --quiet --post-data="content=[BOOTSTRAP] $1" "$MAC_SERVER_URL/" -O /dev/null &
    fi
}

printf "${BLUE}==================================================${NC}\n"
printf "${BLUE}    PC RESCUE STATION: MASTER BOOTSTRAP (v$VERSION)${NC}\n"
printf "${BLUE}==================================================${NC}\n"

# 0. Lock Buster (Required for Chromebook/Crostini stability)
printf "${BLUE}[*] Breaking package manager locks...${NC}\n"
sudo killall apt apt-get dpkg 2>/dev/null || true
sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock 2>/dev/null
sudo dpkg --configure -a 2>/dev/null

# 1. System Prep
log_status "Checking dependencies (x11vnc, ssh, curl)..."
if command -v apt-get >/dev/null 2>&1; then
    # Break locks again just in case background task started
    sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock 2>/dev/null
    
    # Enable universe repository (Required for x11vnc on Ubuntu Live)
    if ! grep -q "universe" /etc/apt/sources.list; then
        sudo add-apt-repository -y universe >/dev/null 2>&1 || \
        echo "deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -sc) universe" | sudo tee -a /etc/apt/sources.list >/dev/null
    fi
    sudo apt-get update -y >/dev/null 2>&1
    # Try multiple packages for VNC
    sudo apt-get install -y x11vnc openssh-server curl net-tools tigervnc-standalone-server >/dev/null 2>&1
fi

# Fallback check
if ! command -v x11vnc >/dev/null 2>&1 && ! command -v Xvnc >/dev/null 2>&1; then
    log_status "WARNING: VNC server installation failed. VNC may not start."
fi

# 2. X11 Forwarding (The "Easy" Fallback)
log_status "Configuring SSH/X11 Forwarding..."
sudo sed -i 's/^#X11Forwarding.*/X11Forwarding yes/' /etc/ssh/sshd_config 2>/dev/null
sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config 2>/dev/null

# Force a password for SSH access (Required on many Live CDs)
echo "$(whoami):rescue" | sudo chpasswd 2>/dev/null

# Try both service names
sudo systemctl enable ssh 2>/dev/null
sudo systemctl enable sshd 2>/dev/null
sudo systemctl restart ssh 2>/dev/null || sudo systemctl restart sshd 2>/dev/null

# 3. Network/Firewall
log_status "Killing Firewalls (UFW/Firewalld/IPtables)..."
if command -v ufw >/dev/null 2>&1; then sudo ufw disable >/dev/null 2>&1; fi
if command -v systemctl >/dev/null 2>&1; then 
    sudo systemctl stop firewalld 2>/dev/null
    sudo systemctl disable firewalld 2>/dev/null
fi
sudo iptables -F 2>/dev/null

# 4. Launch VNC (The "Full Desktop" Primary)
MY_IP=$(hostname -I | cut -d' ' -f1)
log_status "Downloading helper scripts..."
if command -v curl >/dev/null 2>&1; then
    curl -s -O "$MAC_SERVER_URL/scripts/start_vnc.sh"
    curl -s -O "$MAC_SERVER_URL/scripts/push_evidence.sh"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$MAC_SERVER_URL/scripts/start_vnc.sh" -O start_vnc.sh
    wget -q "$MAC_SERVER_URL/scripts/push_evidence.sh" -O push_evidence.sh
fi
chmod +x start_vnc.sh push_evidence.sh 2>/dev/null

log_status "Launching VNC Desktop Mirror..."
./start_vnc.sh >/dev/null 2>&1 &

# 4.5. Generate and Upload Capabilities Profile (NEW)
log_status "Generating system capabilities profile..."
if command -v curl >/dev/null 2>&1; then
    curl -s -O "$MAC_SERVER_URL/scripts/capabilities_profiler.sh"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$MAC_SERVER_URL/scripts/capabilities_profiler.sh" -O capabilities_profiler.sh
fi

if [ -f "capabilities_profiler.sh" ]; then
    chmod +x capabilities_profiler.sh
    MAC_IP_ONLY=$(echo "$MAC_SERVER_URL" | sed 's|http://||' | sed 's|:.*||')
    ./capabilities_profiler.sh "$MAC_IP_ONLY" >/dev/null 2>&1 &
fi

sleep 5
printf "\n${GREEN}✅  PC PREPPED FOR RESCUE!${NC}\n"
printf "%s\n" "--------------------------------------------------"
printf "${BLUE}OPTION A (Full Desktop - Primary):${NC}\n"
printf "   Connect using Mac Screen Sharing app:\n"
printf "   ${GREEN}vnc://$MY_IP:5900${NC}\n\n"

printf "${BLUE}OPTION B (Single App - Fallback):${NC}\n"
printf "   Connect via Mac Terminal (requires XQuartz):\n"
printf "${BLUE}OPTION C (Chromebook Smoother Experience):${NC}\n"
printf "   Run the Python-based intelligent agent:\n"
printf "   ${GREEN}wget -q -O - http://$MY_IP:8000/scripts/rescue_agent.py | python3${NC}\n"
printf "%s\n" "--------------------------------------------------"

# 5. Handover to Python Agent (Preferred for Chromebooks)
if hostname | grep -q "penguin" && command -v python3 >/dev/null 2>&1; then
    log_status "Chromebook detected. Handing over to Python Rescue Agent..."
    
    # Ensure variables are passed to the python agent
    SERVER_IP=$(echo "$MAC_SERVER_URL" | sed 's|http://||' | sed 's|:.*||')
    
    # Fix Browser Integration (prevent it opening res.html in Vim)
    if command -v xdg-settings >/dev/null 2>&1 && command -v garcon-url-handler >/dev/null 2>&1; then
        xdg-settings set default-web-browser garcon-url-handler.desktop >/dev/null 2>&1
    fi
    
    wget -q -O rescue_agent.py "$MAC_SERVER_URL/scripts/rescue_agent.py"
    # Overwrite the current process with the Python agent
    exec python3 rescue_agent.py
fi

# 6. Handshake & Smart Sync (Phase 6)
log_status "Starting PC Handshake Server..."
if command -v python3 >/dev/null 2>&1; then
    curl -s -O "$MAC_SERVER_URL/scripts/handshake_server.py"
    python3 handshake_server.py >/dev/null 2>&1 &
elif command -v python >/dev/null 2>&1; then
    wget -q "$MAC_SERVER_URL/scripts/handshake_server.py" -O handshake_server.py
    python handshake_server.py >/dev/null 2>&1 &
fi

# Heartbeat & Smart Sync Loop
DELAY=10
MAX_DELAY=120
log_status "Entering Smart Sync Loop (Snappy Polling + Backoff)..."

while true; do
    SYNC_REQUIRED=false
    
    # Check for external trigger (Handshake Server)
    if [ -f ".trigger_sync" ]; then
        log_status "Real-time trigger received!"
        rm -f ".trigger_sync"
        SYNC_REQUIRED=true
        DELAY=10
    fi

    # Fetch and Process Manifest
    if command -v curl >/dev/null 2>&1; then
        curl -s "$MAC_SERVER_URL/manifest/" > .manifest.json
    else
        wget -q "$MAC_SERVER_URL/manifest/" -O .manifest.json
    fi

    if [ -s ".manifest.json" ]; then
        # Robust hash extraction (works with both compact and pretty JSON)
        NEW_INSTR_HASH=$(grep -A 2 "scripts/instructions.sh" .manifest.json | grep "hash" | cut -d: -f2 | tr -d '", ')
        OLD_INSTR_HASH=$(cat .last_instr_hash 2>/dev/null | tr -d '", ')
        
        if [ -z "$OLD_INSTR_HASH" ]; then OLD_INSTR_HASH="none"; fi
        
        if [ -n "$NEW_INSTR_HASH" ] && [ "$NEW_INSTR_HASH" != "$OLD_INSTR_HASH" ]; then
            log_status "New instructions detected (Hash: $NEW_INSTR_HASH)"
            if command -v curl >/dev/null 2>&1; then
                curl -s -O "$MAC_SERVER_URL/scripts/instructions.sh"
            else
                wget -q "$MAC_SERVER_URL/scripts/instructions.sh" -O instructions.sh
            fi

            if [ -f "instructions.sh" ]; then
                # Phase 6: In-Browser Confirmation Flow
                # 1. Prep renderer and template
                curl -s -O "$MAC_SERVER_URL/scripts/render_output.py"
                curl -s "$MAC_SERVER_URL/templates/web/command_output.html" > result_template.html
                PY_CMD="python3"; command -v python3 >/dev/null 2>&1 || PY_CMD="python"
                
                # 2. Show PENDING state (Preview the script)
                rm -f .confirmed
                $PY_CMD render_output.py result_template.html instructions.sh "$(date)" "PENDING" > res.html
                
                if command -v garcon-url-handler >/dev/null 2>&1; then garcon-url-handler res.html &
                elif command -v firefox >/dev/null 2>&1; then firefox res.html &
                elif command -v google-chrome >/dev/null 2>&1; then google-chrome res.html &
                else xdg-open res.html & fi
                
                # 3. Wait for confirmation via Handshake Server (port 8001)
                log_status "Waiting for in-browser confirmation..."
                while [ ! -f ".confirmed" ]; do
                    sleep 2
                done
                rm -f .confirmed
                
                # 4. Show EXECUTING state
                log_status "Execution started on PC..."
                echo "⏳ Instruction executing on PC..." > instructions.log
                $PY_CMD render_output.py result_template.html instructions.log "$(date)" "EXECUTING" > res.html
                
                # 5. Run the actual script
                chmod +x instructions.sh
                ./instructions.sh > instructions.log 2>&1
                
                # 6. Show COMPLETED state
                log_status "Execution complete. Pushing results."
                $PY_CMD render_output.py result_template.html instructions.log "$(date)" "COMPLETED" > res.html
                ./push_evidence.sh instructions.log
                
                # Always update hash after execution
                echo "$NEW_INSTR_HASH" > .last_instr_hash
            fi
            SYNC_REQUIRED=true
        fi
    fi

    # VNC state check (Heartbeat)
    VNC_STATE="STOPPED"
    pgrep x11vnc >/dev/null && VNC_STATE="RUNNING"
    
    # Report Status
    HEARTBEAT="[HEARTBEAT] (v$VERSION) VNC: $VNC_STATE | Polling: ${DELAY}s"
    log_status "$HEARTBEAT"

    # Exponential Backoff logic
    if [ "$SYNC_REQUIRED" = "true" ]; then
        DELAY=10
    else
        sleep $DELAY
        DELAY=$(( DELAY * 2 ))
        [ $DELAY -gt $MAX_DELAY ] && DELAY=$MAX_DELAY
    fi
done
