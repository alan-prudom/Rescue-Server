#!/usr/bin/env bash
# Bridge Test for Paste Evidence (Feature 003)
# Goal: Verify that the custom server handles urlencoded POSTs from the browser.

TEST_PORT=8002
TEST_DIR="/tmp/rescue-paste-test"
SERVER_SCRIPT="./server/rescue_server.py"

# --- Setup ---
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR/server"
cp "$SERVER_SCRIPT" "$TEST_DIR/server/rescue_server.py"

echo "[*] Ensuring port $TEST_PORT is free..."
lsof -ti :$TEST_PORT | xargs kill -9 > /dev/null 2>&1

echo "[*] Starting test server..."
(cd "$TEST_DIR" && uv run python server/rescue_server.py "$TEST_PORT") > "$TEST_DIR/server.log" 2>&1 &
SERVER_PID=$!
sleep 2

# --- Test Execution ---

# B005: Paste Text via form-urlencoded
echo "Testing B005: Paste Text via browser form..."
curl -s -X POST \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "content=This+is+a+pasted+log+from+the+bridge+test" \
     http://localhost:$TEST_PORT/ > "$TEST_DIR/response.html"

if grep -q "✅ Success" "$TEST_DIR/response.html"; then
    # Verify file exists
    paste_file=$(ls "$TEST_DIR/evidence/" | grep "paste.txt")
    if [ -f "$TEST_DIR/evidence/$paste_file" ]; then
        if grep -q "This is a pasted log" "$TEST_DIR/evidence/$paste_file"; then
             echo "B005: PASS"
        else
             echo "B005: FAIL (Content mismatch)"
             exit 1
        fi
    else
        echo "B005: FAIL (Paste file not created)"
        exit 1
    fi
else
    echo "B005: FAIL (Server did not return success page)"
    cat "$TEST_DIR/response.html"
    exit 1
fi

# --- Teardown ---
kill "$SERVER_PID"
echo "Paste Bridge Test Passed."
