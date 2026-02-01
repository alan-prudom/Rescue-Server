#!/bin/bash
# PC Rescue Station: Comprehensive System Audit
# Task: CPU, RAM, PCI, Storage, Software, Network
# Trigger: 20260124-0122 (Full Audit)

echo "=================================================="
echo "🚑 PC RESCUE: COMPREHENSIVE SYSTEM AUDIT"
echo "Timestamp: $(date)"
echo "=================================================="

echo -e "\n[1/8] Linux OS & Kernel Info..."
uname -a
if command -v lsb_release >/dev/null 2>&1; then
    lsb_release -a
else
    cat /etc/os-release | grep -E '^(NAME|VERSION|ID)='
fi

echo -e "\n[2/8] CPU Architecture..."
if command -v lscpu >/dev/null 2>&1; then
    lscpu | grep -E 'Model name|Socket|Core\(s\) per socket|Thread\(s\) per core|Max MHz'
else
    grep -m 1 "model name" /proc/cpuinfo
fi

echo -e "\n[3/8] Memory (RAM) Analysis..."
free -h
if command -v dmidecode >/dev/null 2>&1; then
    echo "--- Hardware Dimms ---"
    sudo -n dmidecode -t memory 2>/dev/null | grep -E 'Size|Type|Speed|Manufacturer' | grep -v 'No Module'
fi

echo -e "\n[4/8] Motherboard & BIOS..."
if command -v dmidecode >/dev/null 2>&1; then
    sudo -n dmidecode -t system -t baseboard -t bios 2>/dev/null | grep -E 'Manufacturer|Product Name|Version|Release Date'
fi

echo -e "\n[5/8] PCI Devices (GPU, Network, etc.)..."
lspci -vmm | grep -E 'Vendor|Device|Class' | sed 's/Vendor:/-- Vendor:/'

echo -e "\n[6/8] USB Devices..."
lsusb

echo -e "\n[7/8] Network Interfaces..."
ip -brief addr show

echo -e "\n[8/8] Storage & Partition Sweep..."
echo "--- Physical Disks ---"
lsblk -d -o NAME,SIZE,MODEL,TYPE,TRAN | grep -E "disk|usb"
echo "--- Logical Partitions ---"
lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT,LABEL

echo -e "\n[*] Scanning for & Mounting Available Partitions..."
# Identify unmounted partitions (excluding loop devices, swap, and zram)
UNMOUNTED_DISKS=$(lsblk -rn -o NAME,TYPE,MOUNTPOINT,FSTYPE | grep 'part' | awk '$3 == "" && $4 != "swap" {print $1}')

if [ -z "$UNMOUNTED_DISKS" ]; then
    echo "[!] No unmounted partitions found to sweep."
else
    for dev in $UNMOUNTED_DISKS; do
        MOUNT_POINT="/mnt/rescue_$dev"
        echo "[*] Found: /dev/$dev. Attempting to mount at $MOUNT_POINT..."
        sudo -n mkdir -p "$MOUNT_POINT" 2>/dev/null
        # Try read-only first for safety
        if sudo -n mount -o ro "/dev/$dev" "$MOUNT_POINT" 2>/dev/null; then
            echo "    ✅ SUCCESS: Mounted (Read-Only) at $MOUNT_POINT"
            ls -lh "$MOUNT_POINT" | head -n 10
        else
            echo "    ❌ FAIL: Could not mount /dev/$dev (Requires Sudo Interaction)"
            sudo -n rmdir "$MOUNT_POINT" 2>/dev/null
        fi
    done
fi

# Determine Mac Server IP (Heuristic)
MAC_URL="http://192.168.1.61:8000"

echo -e "\n[*] Running supplemental Disk Health Probe (LITE)..."
if [ ! -f "disk_health_probe_lite.sh" ]; then
    if command -v curl >/dev/null 2>&1; then curl -s -O "$MAC_URL/scripts/disk_health_probe_lite.sh"; 
    else wget -q "$MAC_URL/scripts/disk_health_probe_lite.sh" -O disk_health_probe_lite.sh; fi
fi
[ -f "disk_health_probe_lite.sh" ] && bash disk_health_probe_lite.sh

echo -e "\n[*] Running Tailscale Provisioning Check..."
if [ ! -f "tailscale_setup.sh" ]; then
    if command -v curl >/dev/null 2>&1; then curl -s -O "$MAC_URL/scripts/tailscale_setup.sh";
    else wget -q "$MAC_URL/scripts/tailscale_setup.sh" -O tailscale_setup.sh; fi
fi
[ -f "tailscale_setup.sh" ] && bash tailscale_setup.sh

echo -e "\n[*] Refreshing System Capabilities Profile..."
if [ ! -f "capabilities_profiler.sh" ]; then
    if command -v curl >/dev/null 2>&1; then curl -s -O "$MAC_URL/scripts/capabilities_profiler.sh";
    else wget -q "$MAC_URL/scripts/capabilities_profiler.sh" -O capabilities_profiler.sh; fi
fi
if [ -f "capabilities_profiler.sh" ]; then
    chmod +x capabilities_profiler.sh
    MAC_IP_ONLY=$(echo "$MAC_URL" | sed 's|http://||' | sed 's|:.*||')
    ./capabilities_profiler.sh "$MAC_IP_ONLY"
fi

echo -e "\n=================================================="
echo "✅ Comprehensive Audit & Provisioning Complete."
echo "=================================================="
