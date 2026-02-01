#!/bin/bash
# PC Rescue Station: System Capabilities & Identification Profiler
# Creates a comprehensive JSON profile of the system's capabilities and hardware
# Output: capabilities.json uploaded to evidence/<IP>/

MAC_IP="$1"
OUTPUT_FILE="capabilities.json"

echo "[*] PC Rescue Station: Capabilities Profiler"
echo "[*] Collecting system identification and capabilities..."

# Initialize JSON structure
cat > "$OUTPUT_FILE" << 'EOF_INIT'
{
  "profile_version": "1.0",
  "timestamp": "",
  "system": {},
  "hardware": {},
  "network": {},
  "capabilities": {},
  "software": {}
}
EOF_INIT

# Helper function to safely get command output
safe_cmd() {
    local full_cmd="$1"
    local base_cmd=$(echo "$full_cmd" | awk '{print $1}')
    # If using sudo, check if sudo exists, then check the actual command
    if [ "$base_cmd" = "sudo" ]; then
        base_cmd=$(echo "$full_cmd" | awk '{print $2}')
        if ! command -v sudo >/dev/null 2>&1; then echo "N/A"; return; fi
    fi

    if command -v "$base_cmd" >/dev/null 2>&1; then
        eval "$full_cmd" 2>/dev/null || echo "N/A"
    else
        echo "N/A"
    fi
}

# Timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%d %H:%M:%S")

# === SYSTEM IDENTIFICATION ===
echo "[1/6] System Identification..."

OS_NAME=$(safe_cmd "lsb_release -si")
[ "$OS_NAME" = "N/A" ] && OS_NAME=$(grep "^NAME=" /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "Unknown")

OS_VERSION=$(safe_cmd "lsb_release -sr")
[ "$OS_VERSION" = "N/A" ] && OS_VERSION=$(grep "^VERSION_ID=" /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "Unknown")

OS_CODENAME=$(safe_cmd "lsb_release -sc")
KERNEL=$(uname -r)
ARCH=$(uname -m)
HOSTNAME=$(hostname)

# === HARDWARE IDENTIFICATION ===
echo "[2/6] Hardware Identification..."

# System Identification
SYS_VENDOR=$(safe_cmd "sudo dmidecode -s system-manufacturer")
[ "$SYS_VENDOR" = "N/A" ] && SYS_VENDOR=$(safe_cmd "cat /sys/class/dmi/id/sys_vendor")

SYS_MODEL=$(safe_cmd "sudo dmidecode -s system-product-name")
[ "$SYS_MODEL" = "N/A" ] && SYS_MODEL=$(safe_cmd "cat /sys/class/dmi/id/product_name")

# System Serial Number
SYS_SERIAL=$(safe_cmd "sudo dmidecode -s system-serial-number")
[ "$SYS_SERIAL" = "N/A" ] && SYS_SERIAL=$(safe_cmd "cat /sys/class/dmi/id/product_serial")

# System UUID
SYS_UUID=$(safe_cmd "sudo dmidecode -s system-uuid")
[ "$SYS_UUID" = "N/A" ] && SYS_UUID=$(safe_cmd "cat /sys/class/dmi/id/product_uuid")

# Motherboard Info
MB_VENDOR=$(safe_cmd "sudo dmidecode -s baseboard-manufacturer")
MB_PRODUCT=$(safe_cmd "sudo dmidecode -s baseboard-product-name")
MB_SERIAL=$(safe_cmd "sudo dmidecode -s baseboard-serial-number")

# CPU Info
CPU_MODEL=$(grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | cut -d: -f2 | xargs || echo "Unknown")
CPU_CORES=$(nproc 2>/dev/null || grep -c processor /proc/cpuinfo 2>/dev/null || echo "Unknown")

# Memory
MEM_TOTAL=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || echo "Unknown")

# === NETWORK IDENTIFICATION ===
echo "[3/6] Network Identification..."

# Get all MAC addresses
MACS=$(ip link show 2>/dev/null | grep "link/ether" | awk '{print $2}' | tr '\n' ',' | sed 's/,$//' || echo "Unknown")

# Primary IP
PRIMARY_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || ip -4 addr show | grep inet | grep -v 127.0.0.1 | head -1 | awk '{print $2}' | cut -d/ -f1 || echo "Unknown")

# Network interfaces
INTERFACES=$(ip -br link show 2>/dev/null | awk '{print $1}' | tr '\n' ',' | sed 's/,$//' || echo "Unknown")

# Tailscale IP (if installed and connected)
TAILSCALE_IP="N/A"
if command -v tailscale >/dev/null 2>&1; then
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "Not connected")
fi

# === CAPABILITIES DETECTION ===
echo "[4/6] Detecting capabilities..."

# Package managers
HAS_APT=$(command -v apt-get >/dev/null 2>&1 && echo "true" || echo "false")
HAS_YUM=$(command -v yum >/dev/null 2>&1 && echo "true" || echo "false")
HAS_DNF=$(command -v dnf >/dev/null 2>&1 && echo "true" || echo "false")
HAS_PACMAN=$(command -v pacman >/dev/null 2>&1 && echo "true" || echo "false")
HAS_ZYPPER=$(command -v zypper >/dev/null 2>&1 && echo "true" || echo "false")

# Network tools
HAS_CURL=$(command -v curl >/dev/null 2>&1 && echo "true" || echo "false")
HAS_WGET=$(command -v wget >/dev/null 2>&1 && echo "true" || echo "false")
HAS_SSH=$(command -v ssh >/dev/null 2>&1 && echo "true" || echo "false")

# VNC capabilities
HAS_X11VNC=$(command -v x11vnc >/dev/null 2>&1 && echo "true" || echo "false")
HAS_TIGERVNC=$(command -v vncserver >/dev/null 2>&1 && echo "true" || echo "false")
HAS_GRD=$(command -v grdctl >/dev/null 2>&1 && echo "true" || echo "false")

# Display server
DISPLAY_SERVER=$(echo "$XDG_SESSION_TYPE" | tr -d '\n')
[ -z "$DISPLAY_SERVER" ] && DISPLAY_SERVER="unknown"

# Python
HAS_PYTHON3=$(command -v python3 >/dev/null 2>&1 && echo "true" || echo "false")
PYTHON_VERSION=$(python3 --version 2>/dev/null | awk '{print $2}' || echo "N/A")

# Sudo access
HAS_SUDO=$(sudo -n true 2>/dev/null && echo "true" || echo "false")

# === SOFTWARE VERSIONS ===
echo "[5/6] Software versions..."

BASH_VERSION=$(bash --version 2>/dev/null | head -1 | awk '{print $4}' || echo "N/A")
GIT_VERSION=$(git --version 2>/dev/null | awk '{print $3}' || echo "N/A")

# === BUILD JSON ===
echo "[6/6] Building JSON profile..."

cat > "$OUTPUT_FILE" << EOF
{
  "profile_version": "1.0",
  "timestamp": "$TIMESTAMP",
  "system": {
    "os_name": "$OS_NAME",
    "os_version": "$OS_VERSION",
    "os_codename": "$OS_CODENAME",
    "kernel": "$KERNEL",
    "architecture": "$ARCH",
    "hostname": "$HOSTNAME",
    "display_server": "$DISPLAY_SERVER"
  },
  "hardware": {
    "system_vendor": "$SYS_VENDOR",
    "system_model": "$SYS_MODEL",
    "system_serial": "$SYS_SERIAL",
    "system_uuid": "$SYS_UUID",
    "motherboard": {
      "vendor": "$MB_VENDOR",
      "product": "$MB_PRODUCT",
      "serial": "$MB_SERIAL"
    },
    "cpu": {
      "model": "$CPU_MODEL",
      "cores": "$CPU_CORES"
    },
    "memory": {
      "total": "$MEM_TOTAL"
    }
  },
  "network": {
    "primary_ip": "$PRIMARY_IP",
    "mac_addresses": "$MACS",
    "interfaces": "$INTERFACES",
    "tailscale_ip": "$TAILSCALE_IP"
  },
  "capabilities": {
    "package_managers": {
      "apt": $HAS_APT,
      "yum": $HAS_YUM,
      "dnf": $HAS_DNF,
      "pacman": $HAS_PACMAN,
      "zypper": $HAS_ZYPPER
    },
    "network_tools": {
      "curl": $HAS_CURL,
      "wget": $HAS_WGET,
      "ssh": $HAS_SSH
    },
    "vnc": {
      "x11vnc": $HAS_X11VNC,
      "tigervnc": $HAS_TIGERVNC,
      "gnome_remote_desktop": $HAS_GRD
    },
    "sudo_access": $HAS_SUDO,
    "python3": $HAS_PYTHON3
  },
  "software": {
    "python_version": "$PYTHON_VERSION",
    "bash_version": "$BASH_VERSION",
    "git_version": "$GIT_VERSION"
  }
}
EOF

echo "✅ Capabilities profile created: $OUTPUT_FILE"
cat "$OUTPUT_FILE"

# Upload to server
if [ -n "$MAC_IP" ]; then
    echo ""
    echo "[*] Uploading capabilities profile to server..."
    
    if command -v curl >/dev/null 2>&1; then
        if curl -s -F "file=@$OUTPUT_FILE" "http://$MAC_IP:8000/" >/dev/null 2>&1; then
            echo "✅ Upload successful"
        else
            echo "⚠️  Upload failed (curl)"
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget --quiet --post-file="$OUTPUT_FILE" "http://$MAC_IP:8000/" -O /dev/null 2>&1; then
            echo "✅ Upload successful"
        else
            echo "⚠️  Upload failed (wget)"
        fi
    else
        echo "⚠️  No upload tool available (curl/wget missing)"
    fi
    
    # Also send a status update
    STATUS_MSG="[CAPABILITIES] Profile generated: $HOSTNAME | $SYS_MODEL | OS: $OS_NAME $OS_VERSION | IP: $PRIMARY_IP"
    if command -v curl >/dev/null 2>&1; then
        curl -s -d "content=$STATUS_MSG" "http://$MAC_IP:8000/" >/dev/null 2>&1
    elif command -v wget >/dev/null 2>&1; then
        wget --quiet --post-data="content=$STATUS_MSG" "http://$MAC_IP:8000/" -O /dev/null 2>&1
    fi
fi

echo ""
echo "=================================================="
echo "✅ Capabilities Profiling Complete"
echo "=================================================="
