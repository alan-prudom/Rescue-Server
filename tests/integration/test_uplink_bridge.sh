#!/usr/bin/env bash
# Bridge Test for Evidence Uplink 
# Constitution IV: Verified Network Bridging
# Standard: Bash 3.2+

TEST_PORT=8001
TEST_DIR="/tmp/rescue-bridge-test"
SCRIPT_UNDER_TEST="./setup_rescue_server.sh"
SERVER_SCRIPT="./server/rescue_server.py"

# --- Setup ---
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# 1. Run setup to generate the uploader script
export BASE_DIR="$TEST_DIR"
bash "$SCRIPT_UNDER_TEST" << 'EOF'
n
EOF

# 2. Start the custom server in the background
echo "[*] Ensuring port $TEST_PORT is free..."
lsof -ti :$TEST_PORT | xargs kill -9 > /dev/null 2>&1

echo "[*] Starting test server on port $TEST_PORT..."
(cd "$TEST_DIR" && uv run python "$SERVER_SCRIPT" "$TEST_PORT") > "$TEST_DIR/server.log" 2>&1 &
SERVER_PID=$!

# Wait for server to be ready
sleep 2

# --- Test Execution ---

# B001: Text Log Upload
echo "Testing B001: Text Log Upload..."
echo "Bridge test log content" > "$TEST_DIR/test.log"
# We need to point the uploader to the test port
# The uploader script hardcodes the port, so we temporarily patch it or use env
# For bridge test, we'll use a direct curl to simulate the client tool accurately
response=$(curl -s -X POST -F "file=@$TEST_DIR/test.log" http://localhost:$TEST_PORT/)

if [[ "$response" == *"Success"* ]]; then
    # Verify file exists in evidence/
    uploaded_file=$(ls "$TEST_DIR/evidence/" | grep "test.log")
    if [ -f "$TEST_DIR/evidence/$uploaded_file" ]; then
        echo "B001: PASS"
    else
        echo "B001: FAIL (File not found on disk)"
        exit 1
    fi
else
    echo "B001: FAIL (Server response: $response)"
    exit 1
fi

# B002: Image Binary Upload (Simulated with random data)
echo "Testing B002: Binary Integrity..."
dd if=/dev/urandom of="$TEST_DIR/image.bin" bs=1k count=100 2>/dev/null
ORIGINAL_HASH=$(md5 -q "$TEST_DIR/image.bin" 2>/dev/null || md5sum "$TEST_DIR/image.bin" | awk '{print $1}')

curl -s -X POST -F "file=@$TEST_DIR/image.bin" http://localhost:$TEST_PORT/ > /dev/null

uploaded_bin=$(ls "$TEST_DIR/evidence/" | grep "image.bin")
UPLOADED_HASH=$(md5 -q "$TEST_DIR/evidence/$uploaded_bin" 2>/dev/null || md5sum "$TEST_DIR/evidence/$uploaded_bin" | awk '{print $1}')

if [ "$ORIGINAL_HASH" == "$UPLOADED_HASH" ]; then
    echo "B002: PASS"
else
    echo "B002: FAIL (Hash mismatch! Original: $ORIGINAL_HASH, Uploaded: $UPLOADED_HASH)"
    exit 1
fi

# B003: Path Traversal Check
echo "Testing B003: Path Traversal..."
# Attempt to upload with a malicious name (CURL often strips this, but our server should handle basename)
curl -s -X POST -F "file=@$TEST_DIR/test.log;filename=../../evil.txt" http://localhost:$TEST_PORT/ > /dev/null

if [ -f "$TEST_DIR/evil.txt" ]; then
    echo "B003: FAIL (Path traversal vulnerability detected!)"
    exit 1
else
    echo "B003: PASS"
fi

# --- Teardown ---
echo "[*] Cleaning up..."
kill "$SERVER_PID"
rm -rf "$TEST_DIR"

echo "All Bridge Tests Completed Successfully."
