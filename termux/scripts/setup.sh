#!/bin/sh
# MaiaLinux-Android - Termux Environment Setup
# Prepares Termux packages, audio, X11, and installs Debian 13 (Trixie) via PRoot Distro.

set -e

echo "=== [1/5] Updating Termux Packages ==="
pkg update -y
pkg upgrade -y

echo "=== [2/5] Setting Up Device Storage Access ==="
termux-setup-storage

echo "=== [3/5] Installing Termux Dependencies (X11, Audio, Acceleration) ==="
pkg install -y vim curl wget git pulseaudio dbus
pkg install -y x11-repo
pkg install -y termux-x11-nightly
pkg install -y angle-android virglrenderer-android proot-distro

echo "=== [4/5] Installing Debian Container in PRoot Distro ==="
if proot-distro list | grep -q "debian (installed)"; then
    echo "Debian is already installed in PRoot Distro."
else
    echo "Installing Debian via proot-distro..."
    proot-distro install debian
fi

echo "=== [5/5] Done! Next steps: ==="
echo "To complete the MaiaLinux (Debian 13 + LXQt) installation, run:"
echo "  proot-distro login debian --shared-tmp"
echo "And inside Debian, run:"
echo "  cd ~/maialinux-android/debian/scripts && ./setup.sh"
echo ""
echo "Then launch the graphical desktop with:"
echo "  ./Debian.sh or ./startdebian.sh"
