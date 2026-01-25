#!/bin/bash
# PC Rescue Station: Server Terminator
# Finds and kills all rescue_server process instances

echo "[*] PC Rescue Station: Server Cleanup"
echo "=================================================="

# 1. Identify processes
PIDS=$(ps aux | grep -i "rescue_server.py" | grep -v grep | awk '{print $2}')

if [ -z "$PIDS" ]; then
    echo "✅ No running rescue_server processes found."
    exit 0
fi

echo "[!] Found processes: $PIDS"
ps aux | grep -i "rescue_server.py" | grep -v grep

# 2. Kill them
echo -e "\n[*] Terminating processes..."
for PID in $PIDS; do
    echo "    Stopping PID $PID..."
    kill -15 "$PID" 2>/dev/null
done

# Wait a moment
sleep 2

# 3. Force Kill if still alive
REMAINING=$(ps aux | grep -i "rescue_server.py" | grep -v grep | awk '{print $2}')
if [ -n "$REMAINING" ]; then
    echo "[!] Some processes are stubborn. Using Force Kill..."
    for PID in $REMAINING; do
        echo "    Forcing PID $PID to exit..."
        kill -9 "$PID" 2>/dev/null
    done
fi

# 4. Final check
ps aux | grep -i "rescue_server.py" | grep -v grep >/dev/null
if [ $? -eq 0 ]; then
    echo "❌ ERROR: Failed to kill all processes. You may need to use 'sudo'."
else
    echo "✅ Success: All rescue_server processes terminated."
fi
echo "=================================================="
