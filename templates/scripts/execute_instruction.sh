#!/bin/bash
# PC Rescue Station: Instruction Executor
# This script downloads an instruction from the Mac server, executes it,
# captures output, and uploads the results back to the server.
#
# Usage: ./execute_instruction.sh <MAC_IP> <INSTRUCTION_NAME>

MAC_IP="$1"
INSTRUCTION_NAME="$2"

if [ -z "$MAC_IP" ] || [ -z "$INSTRUCTION_NAME" ]; then
    echo "Usage: $0 <MAC_IP> <INSTRUCTION_NAME>"
    echo "Example: $0 192.168.1.61 vnc_discovery.sh"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
WORK_DIR="rescue_output_${TIMESTAMP}"
mkdir -p "$WORK_DIR"

echo "=================================================="
echo "🚑 PC RESCUE: INSTRUCTION EXECUTOR"
echo "Timestamp: $(date)"
echo "Mac Server: $MAC_IP"
echo "Instruction: $INSTRUCTION_NAME"
echo "Working Directory: $WORK_DIR"
echo "=================================================="

# Download the instruction script
echo "[*] Downloading instruction from server..."
SCRIPT_URL="http://$MAC_IP:8000/scripts/$INSTRUCTION_NAME"
SCRIPT_PATH="$WORK_DIR/$INSTRUCTION_NAME"

if wget -q -O "$SCRIPT_PATH" "$SCRIPT_URL"; then
    echo "✅ Downloaded: $INSTRUCTION_NAME"
    chmod +x "$SCRIPT_PATH"
else
    echo "❌ Failed to download instruction from $SCRIPT_URL"
    exit 1
fi

# Execute the instruction with output capture
echo "[*] Executing instruction..."
EXEC_LOG="$WORK_DIR/execution.log"

{
    echo "=== EXECUTION START ==="
    echo "Timestamp: $(date)"
    echo "Instruction: $INSTRUCTION_NAME"
    echo "========================"
    echo ""
    
    # Run the script, passing MAC_IP as first argument
    bash "$SCRIPT_PATH" "$MAC_IP" 2>&1
    EXIT_CODE=$?
    
    echo ""
    echo "========================"
    echo "Exit Code: $EXIT_CODE"
    echo "Timestamp: $(date)"
    echo "=== EXECUTION END ==="
} | tee "$EXEC_LOG"

# Create a tarball of all output
echo "[*] Packaging results..."
ARCHIVE_NAME="${TIMESTAMP}_${INSTRUCTION_NAME%.sh}_results.tar.gz"
tar -czf "$ARCHIVE_NAME" "$WORK_DIR" 2>/dev/null

if [ -f "$ARCHIVE_NAME" ]; then
    echo "✅ Created archive: $ARCHIVE_NAME"
    
    # Upload the archive to the server
    echo "[*] Uploading results to server..."
    
    if curl -F "file=@$ARCHIVE_NAME" "http://$MAC_IP:8000/" 2>/dev/null; then
        echo "✅ Results uploaded successfully"
    else
        echo "⚠️  Upload failed, but results are saved locally: $ARCHIVE_NAME"
    fi
else
    echo "❌ Failed to create archive"
fi

# Also send a status update
STATUS_MSG="[INSTRUCTION] Executed: $INSTRUCTION_NAME | Exit: $EXIT_CODE | Archive: $ARCHIVE_NAME"
curl -s -X POST -d "content=$STATUS_MSG" "http://$MAC_IP:8000/paste" >/dev/null 2>&1

echo "=================================================="
echo "✅ Instruction execution complete"
echo "=================================================="
