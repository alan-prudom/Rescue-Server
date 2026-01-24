#!/bin/bash
# One-Click VNC Bootstrap
# Target: macOS Screen Sharing.app
# VERSION="{{VERSION}}"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# MAC_SERVER_URL set by setup provisioner
MAC_SERVER_URL="{{MAC_SERVER_URL}}"

log_status() {
    local msg="$1"
    printf "%s\n" "$msg"
    if command -v curl >/dev/null 2>&1; then
        curl -s -d "content=[VNC-STATUS] $msg" "$MAC_SERVER_URL/" >/dev/null &
    elif command -v wget >/dev/null 2>&1; then
        wget --quiet --post-data="content=[VNC-STATUS] $msg" "$MAC_SERVER_URL/" -O /dev/null &
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
    # Diagnostics: Check if x11vnc is even there (US: Auto-Remediation)
    if ! command -v x11vnc >/dev/null 2>&1; then
        log_status "x11vnc is missing. Attempting auto-installation..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update -y >/dev/null 2>&1
            sudo apt-get install -y x11vnc tigervnc-standalone-server >/dev/null 2>&1
        fi
        
        if ! command -v x11vnc >/dev/null 2>&1; then
            log_status "ERROR: x11vnc installation failed. VNC cannot start."
            exit 1
        fi
        log_status "x11vnc installed successfully."
    fi

    mkdir -p "$HOME/.vnc"
    chmod 700 "$HOME/.vnc"
    
    # Search multiple common locations for Xauthority
    POTENTIAL_XAUTH=(
        "/run/user/$(id -u)/gdm/Xauthority"
        "/run/user/$(id -u)/Xauthority"
        "$HOME/.Xauthority"
        "/var/run/lightdm/root/:0"
        "/var/lib/gdm/:0.Xauth"
    )
    
    for path in "${POTENTIAL_XAUTH[@]}"; do
        if [ -f "$path" ]; then
            XAUTH="$path"
            # Attempt to make it readable if we have sudo
            sudo chmod 644 "$XAUTH" 2>/dev/null || true
            break
        fi
    done

    # If still not found, try a generic find but limited to /run/user
    if [ -z "$XAUTH" ]; then
        XAUTH=$(find /run/user/$(id -u) -name Xauthority 2>/dev/null | head -n 1)
        [ -n "$XAUTH" ] && sudo chmod 644 "$XAUTH" 2>/dev/null
    fi
    
    # Kill any existing
    sudo killall x11vnc 2>/dev/null || true
    
    # Common flags for stability
    # Use -nopw for easiest connection from Mac Screen Sharing.app
    VNC_FLAGS="-listen 0.0.0.0 -forever -shared -nopw -noshm -noxdamage -noxfixes -nowf -visual TrueColor"
    
    LAUNCH_USER() {
        local disp="$1"
        local auth="$2"
        log_status "Attempting user launch on $disp..."
        x11vnc -display "$disp" -auth "$auth" $VNC_FLAGS -bg -o "$HOME/.vnc/x11vnc.log" 2>>"$HOME/.vnc/vnc_stderr.log"
    }

    LAUNCH_SUDO() {
        local disp="$1"
        local auth="$2"
        log_status "Attempting sudo launch on $disp..."
        sudo x11vnc -display "$disp" -auth "$auth" $VNC_FLAGS -bg -o "$HOME/.vnc/x11vnc.log" 2>>"$HOME/.vnc/vnc_stderr.log"
    }

    if [ -n "$XAUTH" ]; then
        log_status "Using XAuth: $XAUTH"
        LAUNCH_USER :0 "$XAUTH"
        sleep 2
        if ! pgrep x11vnc >/dev/null; then
             LAUNCH_SUDO :0 "$XAUTH"
        fi
    else
        log_status "XAuth not found, guessing..."
        LAUNCH_USER :0 guess
        sleep 2
        if ! pgrep x11vnc >/dev/null; then
             LAUNCH_SUDO :0 guess
        fi
    fi
    
    sleep 3
    if ! pgrep x11vnc >/dev/null; then
        log_status "Display :0 failed. Trying :1..."
        LAUNCH_SUDO :1 guess
        sleep 3
        
        if ! pgrep x11vnc >/dev/null; then
            log_status "Still failed. Trying 'blind' mode with noauth..."
            sudo x11vnc -forever -shared -nopw -bg -noshm -noxdamage -noxfixes -o "$HOME/.vnc/x11vnc.log" 2>>"$HOME/.vnc/vnc_stderr.log"
            sleep 3
        fi
    fi

    if pgrep x11vnc >/dev/null; then
        log_status "x11vnc is running."
    else
        log_status "ERROR: x11vnc failed to start."
        # Upload whatever we have
        for logfile in "$HOME/.vnc/x11vnc.log" "$HOME/.vnc/vnc_stderr.log"; do
            if [ -s "$logfile" ]; then
                log_status "Uploading log: $(basename "$logfile")..."
                if [ -f ./push_evidence.sh ]; then
                    ./push_evidence.sh "$logfile"
                else
                    if command -v curl >/dev/null 2>&1; then
                        curl -s -X POST -F "file=@$logfile" "$MAC_SERVER_URL/" >/dev/null
                    elif command -v wget >/dev/null 2>&1; then
                        wget --quiet --post-file="$logfile" "$MAC_SERVER_URL/" -O /dev/null
                    fi
                fi
            fi
        done
        log_status "Diagnostics complete. Check server evidence/ folder."
    fi
fi

sleep 2
log_status "READY: vnc://$MY_IP:5900"
printf "${GREEN}--------------------------------------------------${NC}\n"
printf "✅  ${GREEN}SUCCESS: VNC Ready!${NC}\n"
printf "    Connect using:  ${BLUE}vnc://$MY_IP:5900${NC}\n"
printf "${GREEN}--------------------------------------------------${NC}\n"
