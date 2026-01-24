#!/bin/bash
# VNC Diagnostic Tool
# Constitution: Principal III (Test-First)
VERSION="20260123-1115"
echo "[*] PC Rescue Station: VNC Diagnostic (v$VERSION)"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG="vnc_diag.log"
echo "--- VNC Diagnostic Report ($(date)) ---" > $LOG

log_check() {
    local label="$1"
    local cmd="$2"
    echo -n "[*] Checking $label... "
    if eval "$cmd" >> $LOG 2>&1; then
        echo -e "${GREEN}OK${NC}"
        echo "RESULT: $label OK" >> $LOG
    else
        echo -e "${RED}FAIL${NC}"
        echo "RESULT: $label FAIL" >> $LOG
    fi
}

# 1. Binary checks
log_check "x11vnc binary" "command -v x11vnc"
log_check "netstat" "command -v netstat"
log_check "curl/wget" "command -v curl || command -v wget"

# 2. X Server checks
log_check "Display Variable" "[ -n \"$DISPLAY\" ]"
log_check "X Server Running" "pgrep Xorg || pgrep X"

# 3. Permission checks
log_check "Xauthority readable" "[ -f \"$HOME/.Xauthority\" ] && [ -r \"$HOME/.Xauthority\" ]"

# 4. Port checks
log_check "Port 5900 free" "! netstat -tan | grep LISTEN | grep :5900"

echo -e "\n${BLUE}[*] Diagnostic Complete.${NC}"
echo "Summary saved to $LOG"

if [ -f "./push_evidence.sh" ]; then
    echo "[*] Uploading diagnostic results..."
    ./push_evidence.sh "$LOG"
fi
