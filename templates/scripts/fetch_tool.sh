#!/bin/bash
# Fetch Tool - Download files via Mac Proxy Cache
VERSION="20260123-1030"
echo "[*] PC Rescue Station: Fetch Tool (v$VERSION)"
# Usage: bash fetch_tool.sh <URL> [OUTPUT_FILENAME]

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

TARGET_URL="$1"
OUTPUT_NAME="$2"

if [ -z "$TARGET_URL" ]; then
    echo "Usage: $0 <URL> [OUTPUT_FILENAME]"
    exit 1
fi

# Determine output filename if not provided
if [ -z "$OUTPUT_NAME" ]; then
    OUTPUT_NAME=$(basename "$TARGET_URL")
fi

echo -e "${BLUE}[*] Requesting: $TARGET_URL${NC}"
echo "    Via Proxy: http://192.168.1.61:8000/proxy"

# Use curl to hit the proxy endpoint
if command -v curl >/dev/null 2>&1; then
    curl -f -L "http://192.168.1.61:8000/proxy?url=$TARGET_URL" -o "$OUTPUT_NAME"
    
    if [ $? -eq 0 ]; then
        echo -e "✅  ${GREEN}Download Complete: $OUTPUT_NAME${NC}"
        ls -lh "$OUTPUT_NAME"
    else
        echo -e "${RED}[!] Download Failed.${NC}"
        exit 1
    fi
elif command -v wget >/dev/null 2>&1; then
    wget -O "$OUTPUT_NAME" "http://192.168.1.61:8000/proxy?url=$TARGET_URL"
    
     if [ $? -eq 0 ]; then
        echo -e "✅  ${GREEN}Download Complete: $OUTPUT_NAME${NC}"
        ls -lh "$OUTPUT_NAME"
    else
        echo -e "${RED}[!] Download Failed.${NC}"
        exit 1
    fi
else
    echo "Error: Neither curl nor wget found."
    exit 1
fi
