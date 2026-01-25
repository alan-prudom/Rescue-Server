#!/bin/bash
# Client Evidence Uploader
VERSION="20260123-1030"
echo "[*] PC Rescue Station: Evidence Uploader (v$VERSION)"
# Standard: Bash 3.2+
# Usage: ./push_evidence.sh <file_path>

FILE="$1"
if [ -z "$FILE" ]; then
    echo "Usage: $0 <file_path>"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "Error: File $FILE not found."
    exit 1
fi

echo "Uploading $FILE to Mac Server (192.168.1.61)..."
if command -v curl >/dev/null 2>&1; then
    curl -X POST -F "file=@$FILE" http://192.168.1.61:8000/
elif command -v wget >/dev/null 2>&1; then
    # Force octet-stream to avoid server trying to parse as form-urlencoded
    wget --quiet --header="Content-Type: application/octet-stream" --post-file="$FILE" http://192.168.1.61:8000/ -O /dev/null
fi
