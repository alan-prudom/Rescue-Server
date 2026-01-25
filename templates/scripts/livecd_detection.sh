#!/bin/bash
# PC Rescue Station: Live CD vs Installed OS Detection
# Task: Determine if the system is running from Live CD/USB or installed
# Output: livecd_detection/

MAC_IP="$1"
OUTPUT_DIR="livecd_detection"
mkdir -p "$OUTPUT_DIR"
REPORT="$OUTPUT_DIR/livecd_report.txt"

{
echo "=================================================="
echo "💿 LIVE CD vs INSTALLED OS DETECTION"
echo "Timestamp: $(date)"
echo "Hostname: $(hostname)"
echo "=================================================="

# Initialize detection score (higher = more likely Live CD)
LIVECD_SCORE=0
EVIDENCE=()

echo -e "\n[1/8] Checking root filesystem type..."
ROOT_FS=$(df / | tail -1 | awk '{print $1}')
ROOT_FSTYPE=$(df -T / | tail -1 | awk '{print $2}')
echo "Root filesystem: $ROOT_FS"
echo "Filesystem type: $ROOT_FSTYPE"

if echo "$ROOT_FSTYPE" | grep -qi "overlay\|tmpfs\|squashfs\|aufs"; then
    echo "✓ LIVE CD INDICATOR: Overlay/temporary filesystem detected"
    LIVECD_SCORE=$((LIVECD_SCORE + 3))
    EVIDENCE+=("Root uses overlay/tmpfs filesystem ($ROOT_FSTYPE)")
fi

echo -e "\n[2/8] Checking for Live CD mount points..."
if mount | grep -qi "live\|casper\|overlay"; then
    echo "✓ LIVE CD INDICATOR: Live CD mount points found"
    mount | grep -i "live\|casper\|overlay"
    LIVECD_SCORE=$((LIVECD_SCORE + 3))
    EVIDENCE+=("Live CD mount points detected")
else
    echo "✗ No Live CD mount points found"
fi

echo -e "\n[3/8] Checking /proc/cmdline for boot parameters..."
CMDLINE=$(cat /proc/cmdline)
echo "Boot parameters: $CMDLINE"

if echo "$CMDLINE" | grep -qi "boot=live\|boot=casper\|toram\|live-media"; then
    echo "✓ LIVE CD INDICATOR: Live boot parameters detected"
    LIVECD_SCORE=$((LIVECD_SCORE + 4))
    EVIDENCE+=("Live boot parameters in kernel command line")
fi

echo -e "\n[4/8] Checking for persistence..."
if [ -d "/cdrom" ] || [ -d "/lib/live/mount" ]; then
    echo "✓ LIVE CD INDICATOR: Live CD directories present"
    LIVECD_SCORE=$((LIVECD_SCORE + 2))
    EVIDENCE+=("Live CD directories (/cdrom or /lib/live/mount) exist")
fi

echo -e "\n[5/8] Checking writable status of root..."
if touch /test_write_root 2>/dev/null; then
    rm -f /test_write_root
    echo "Root is writable (could be persistent live or installed)"
else
    echo "✓ LIVE CD INDICATOR: Root is read-only"
    LIVECD_SCORE=$((LIVECD_SCORE + 3))
    EVIDENCE+=("Root filesystem is read-only")
fi

echo -e "\n[6/8] Checking /etc/fstab for real partitions..."
if [ -f /etc/fstab ]; then
    echo "--- /etc/fstab contents ---"
    cat /etc/fstab | grep -v "^#" | grep -v "^$"
    
    if grep -q "^UUID=\|^/dev/" /etc/fstab 2>/dev/null; then
        echo "✗ INSTALLED INDICATOR: Real partition entries in fstab"
    else
        echo "✓ LIVE CD INDICATOR: No real partitions in fstab"
        LIVECD_SCORE=$((LIVECD_SCORE + 2))
        EVIDENCE+=("No real partition entries in /etc/fstab")
    fi
fi

echo -e "\n[7/8] Checking for bootloader installation..."
if [ -d /boot/grub ] && [ -f /boot/grub/grub.cfg ]; then
    echo "GRUB bootloader found at /boot/grub"
    if grep -q "menuentry" /boot/grub/grub.cfg 2>/dev/null; then
        echo "✗ INSTALLED INDICATOR: GRUB appears to be installed"
    fi
else
    echo "✓ LIVE CD INDICATOR: No GRUB installation found"
    LIVECD_SCORE=$((LIVECD_SCORE + 2))
    EVIDENCE+=("No GRUB bootloader installation")
fi

echo -e "\n[8/8] Checking system uptime and user home..."
echo "System uptime: $(uptime -p 2>/dev/null || uptime)"

if [ -d /home ] && [ "$(ls -A /home 2>/dev/null)" ]; then
    USER_COUNT=$(ls /home | wc -l)
    echo "User home directories: $USER_COUNT"
    if [ "$USER_COUNT" -gt 1 ]; then
        echo "✗ INSTALLED INDICATOR: Multiple user homes suggest installed system"
    fi
else
    echo "✓ LIVE CD INDICATOR: No persistent user homes"
    LIVECD_SCORE=$((LIVECD_SCORE + 1))
    EVIDENCE+=("No persistent user home directories")
fi

echo -e "\n=================================================="
echo "📊 DETECTION SUMMARY"
echo "=================================================="
echo "Live CD Score: $LIVECD_SCORE / 20"
echo ""

if [ "$LIVECD_SCORE" -ge 10 ]; then
    echo "🔴 VERDICT: LIVE CD / LIVE USB"
    echo "Confidence: HIGH"
elif [ "$LIVECD_SCORE" -ge 5 ]; then
    echo "🟡 VERDICT: POSSIBLY LIVE CD (or persistent live)"
    echo "Confidence: MEDIUM"
else
    echo "🟢 VERDICT: INSTALLED OPERATING SYSTEM"
    echo "Confidence: HIGH"
fi

echo ""
echo "Evidence collected:"
for item in "${EVIDENCE[@]}"; do
    echo "  • $item"
done

echo -e "\n=================================================="
echo "✅ Live CD Detection Complete"
echo "=================================================="
} | tee "$REPORT"

echo "[*] Report saved to: $REPORT"
