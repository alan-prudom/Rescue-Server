#!/bin/sh
# PC Rescue Station: Chromebook Agent Terminator

echo "🛑 Stopping Rescue Agent..."
pkill -f rescue_agent.py
sleep 1

if pgrep -f rescue_agent.py >/dev/null; then
    echo "[!] Agent still running. Force killing..."
    pkill -9 -f rescue_agent.py
fi

echo "✅ Agent terminated."
