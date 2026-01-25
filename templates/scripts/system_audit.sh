#!/bin/bash
# PC Rescue Station: Comprehensive System Audit
# Task: CPU, RAM, PCI, Storage, Software, Network
# Output: system_audit/

MAC_IP="$1"
OUTPUT_DIR="system_audit"
mkdir -p "$OUTPUT_DIR"
REPORT="$OUTPUT_DIR/audit_report.txt"

{
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
    sudo dmidecode -t memory | grep -E 'Size|Type|Speed|Manufacturer' | grep -v 'No Module'
fi

echo -e "\n[4/8] Motherboard & BIOS..."
if command -v dmidecode >/dev/null 2>&1; then
    sudo dmidecode -t system -t baseboard -t bios | grep -E 'Manufacturer|Product Name|Version|Release Date'
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
UNMOUNTED_DISKS=$(lsblk -rn -o NAME,TYPE,MOUNTPOINT,FSTYPE | grep 'part' | awk '$3 == "" && $4 != "swap" {print $1}')

if [ -z "$UNMOUNTED_DISKS" ]; then
    echo "[!] No unmounted partitions found to sweep."
else
    for dev in $UNMOUNTED_DISKS; do
        MOUNT_POINT="/mnt/rescue_$dev"
        echo "[*] Found: /dev/$dev. Attempting to mount at $MOUNT_POINT..."
        sudo mkdir -p "$MOUNT_POINT"
        if sudo mount -o ro "/dev/$dev" "$MOUNT_POINT" 2>/dev/null; then
            echo "    ✅ SUCCESS: Mounted (Read-Only) at $MOUNT_POINT"
            ls -lh "$MOUNT_POINT" | head -n 10
        else
            echo "    ❌ FAIL: Could not mount /dev/$dev"
            sudo rmdir "$MOUNT_POINT" 2>/dev/null
        fi
    done
fi

echo -e "\n=================================================="
echo "✅ Comprehensive Audit Complete."
echo "=================================================="
} | tee "$REPORT"

echo "[*] Report saved to: $REPORT"
