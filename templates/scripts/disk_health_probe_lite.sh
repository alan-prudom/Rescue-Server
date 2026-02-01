#!/bin/bash
# PC Rescue Station: Disk Health & Usage Probe (LITE)
# No sudo version to avoid hanging on password prompt

echo "=================================================="
echo "💽 DISK HEALTH & USAGE PROBE (LITE)"
echo "Timestamp: $(date)"
echo "=================================================="

echo -e "\n[1/2] Disk Usage (df -h)..."
df -h | grep -E 'Filesystem|sda|total'

echo -e "\n[2/2] Partition Info (/proc/partitions)..."
cat /proc/partitions | grep sda

echo -e "\n[*] Sudo-less fallback complete. 深 deep analysis requires SMART tools and sudo."
echo "=================================================="
