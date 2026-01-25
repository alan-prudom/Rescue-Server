#!/bin/bash
# PC Rescue Station: Chromebook Power Pack (v1.0)
# Targeted utilities for the Crostini (penguin) environment

echo "=================================================="
echo "🚀 CHROMEBOOK POWER PACK"
echo "=================================================="

# 1. Performance Optimization
echo "[1/4] Optimizing Crostini Performance..."
# Disable background MOTD and noise
echo 5 > "$HOME/.local/share/cros-motd" 2>/dev/null
# Clean up old packages
sudo apt-get autoremove -y >/dev/null 2>&1
echo "✅ Terminal noise reduced."

# 2. Browser Integration Fix
echo "[2/4] Ensuring Browser Integration..."
if command -v garcon-url-handler >/dev/null 2>&1; then
    xdg-settings set default-web-browser garcon-url-handler.desktop
    echo "✅ ChromeOS Browser set as default for Linux."
else
    echo "⚠️  garcon-url-handler not found. Are you in Crostini?"
fi

# 3. Path Shortcuts
echo "[3/4] Creating Storage Shortcuts..."
# Link ChromeOS Downloads to home for easy access
DOWNLOADS="/mnt/chromeos/MyFiles/Downloads"
if [ -d "$DOWNLOADS" ]; then
    ln -s "$DOWNLOADS" "$HOME/Download-Folder" 2>/dev/null
    echo "✅ Linked ChromeOS Downloads to ~/Download-Folder"
else
    echo "⚠️  ChromeOS Downloads not shared with Linux. (Right-click Downloads > Share with Linux)"
fi

# 4. Agent Persistence
echo "[4/4] Setting up Agent Auto-Start (Experimental)..."
# Add to .bashrc if not present
if ! grep -q "rescue_agent.py" "$HOME/.bashrc"; then
    echo "# PC Rescue Agent Auto-Start" >> "$HOME/.bashrc"
    echo "# pgrep -f rescue_agent.py >/dev/null || python3 $HOME/rescue_agent.py &" >> "$HOME/.bashrc"
    echo "✅ Added (commented) auto-start to .bashrc"
fi

echo "=================================================="
echo "✅ Power Pack Installed!"
echo "=================================================="
