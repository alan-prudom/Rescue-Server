#!/bin/sh
# PC Rescue Station: Dependency Installer
# Automatically installs missing critical dependencies based on detected OS
# POSIX-compliant for maximum compatibility

echo "[*] PC Rescue Station: Dependency Installer"
echo "[*] Detecting system and installing missing dependencies..."

# Detect package manager
if command -v apt-get >/dev/null 2>&1; then
    PKG_MGR="apt"
    echo "[*] Detected: Debian/Ubuntu (apt)"
elif command -v yum >/dev/null 2>&1; then
    PKG_MGR="yum"
    echo "[*] Detected: RHEL/CentOS (yum)"
elif command -v dnf >/dev/null 2>&1; then
    PKG_MGR="dnf"
    echo "[*] Detected: Fedora/RHEL 8+ (dnf)"
elif command -v pacman >/dev/null 2>&1; then
    PKG_MGR="pacman"
    echo "[*] Detected: Arch Linux (pacman)"
elif command -v zypper >/dev/null 2>&1; then
    PKG_MGR="zypper"
    echo "[*] Detected: openSUSE (zypper)"
else
    echo "[!] ERROR: No supported package manager found"
    echo "[!] Supported: apt, yum, dnf, pacman, zypper"
    exit 1
fi

# Check for sudo/root
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
        echo "[*] Using sudo for installations"
    else
        echo "[!] ERROR: Not running as root and sudo not available"
        echo "[!] Please run as root or install sudo"
        exit 1
    fi
else
    SUDO=""
    echo "[*] Running as root"
fi

# Define critical dependencies
DEPS_NETWORK="curl wget"
DEPS_VNC="x11vnc"
DEPS_PYTHON="python3"
DEPS_TOOLS="git"

INSTALL_LIST=""

# Check and queue missing dependencies
echo ""
echo "[*] Checking dependencies..."

for dep in $DEPS_NETWORK $DEPS_VNC $DEPS_PYTHON $DEPS_TOOLS; do
    if command -v "$dep" >/dev/null 2>&1; then
        echo "  ✓ $dep (installed)"
    else
        echo "  ✗ $dep (missing)"
        INSTALL_LIST="$INSTALL_LIST $dep"
    fi
done

# If nothing to install, exit
if [ -z "$INSTALL_LIST" ]; then
    echo ""
    echo "✅ All dependencies are already installed!"
    exit 0
fi

echo ""
echo "[*] Dependencies to install:$INSTALL_LIST"
echo ""

# Install based on package manager
case "$PKG_MGR" in
    apt)
        echo "[*] Updating package lists..."
        $SUDO apt-get update -qq
        
        echo "[*] Installing dependencies..."
        # shellcheck disable=SC2086
        $SUDO apt-get install -y $INSTALL_LIST
        ;;
    
    yum)
        echo "[*] Installing dependencies..."
        # shellcheck disable=SC2086
        $SUDO yum install -y $INSTALL_LIST
        ;;
    
    dnf)
        echo "[*] Installing dependencies..."
        # shellcheck disable=SC2086
        $SUDO dnf install -y $INSTALL_LIST
        ;;
    
    pacman)
        echo "[*] Updating package database..."
        $SUDO pacman -Sy
        
        echo "[*] Installing dependencies..."
        # shellcheck disable=SC2086
        $SUDO pacman -S --noconfirm $INSTALL_LIST
        ;;
    
    zypper)
        echo "[*] Refreshing repositories..."
        $SUDO zypper refresh
        
        echo "[*] Installing dependencies..."
        # shellcheck disable=SC2086
        $SUDO zypper install -y $INSTALL_LIST
        ;;
esac

# Verify installation
echo ""
echo "[*] Verifying installations..."
FAILED=""

for dep in $INSTALL_LIST; do
    if command -v "$dep" >/dev/null 2>&1; then
        echo "  ✓ $dep (successfully installed)"
    else
        echo "  ✗ $dep (installation failed)"
        FAILED="$FAILED $dep"
    fi
done

echo ""
if [ -z "$FAILED" ]; then
    echo "✅ All dependencies installed successfully!"
    exit 0
else
    echo "⚠️  Some dependencies failed to install:$FAILED"
    echo "Please install them manually"
    exit 1
fi
