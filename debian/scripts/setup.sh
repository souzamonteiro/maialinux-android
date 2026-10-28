#!/usr/bin/env bash
# MaiaLinux-Android - Debian 13 (Trixie) & LXQt Setup Script
# Configures Debian 13, installs LXQt desktop, on-screen keyboard, tablet wallpapers, and MaiaLinux theme.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "=== [1/7] Configuring Debian 13 (Trixie) Repositories ==="
cat << 'EOF' > /etc/apt/sources.list
deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb http://deb.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
EOF

apt update -y
apt dist-upgrade -y

echo "=== [2/7] Removing legacy XFCE packages (if present) ==="
apt remove --purge -y xfce4 xfce4-* xfwm4 lightdm 2>/dev/null || true
apt autoremove --purge -y 2>/dev/null || true

echo "=== [3/7] Installing LXQt Desktop, Virtual Keyboard, and Utilities ==="
apt install -y --no-install-recommends \
    lxqt-core \
    lxqt-panel \
    lxqt-session \
    lxqt-runner \
    lxqt-qtplugin \
    lxqt-policykit \
    lxqt-notificationd \
    openbox \
    pcmanfm-qt \
    qterminal \
    dbus-x11 \
    x11-xserver-utils \
    x11-utils \
    papirus-icon-theme \
    fonts-dejavu \
    fonts-noto-core \
    fonts-noto-cjk \
    ca-certificates \
    curl \
    wget \
    git \
    vim \
    sudo \
    locales \
    matchbox-keyboard \
    onboard \
    geany \
    firefox-esr \
    mesa-utils \
    pulseaudio-utils \
    file-roller \
    build-essential

echo "=== [4/7] Configuring Locales, Timezone, and User Accounts ==="
ln -sf /usr/share/zoneinfo/America/Bahia /etc/localtime

# Configure locales (pt_BR and en_US)
sed -i -E 's/#[[:space:]]?(pt_BR.UTF-8[[:space:]]+UTF-8)/\1/g' /etc/locale.gen
sed -i -E 's/#[[:space:]]?(en_US.UTF-8[[:space:]]+UTF-8)/\1/g' /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf
echo "LANG=pt_BR.UTF-8" > /etc/default/locale

# Default root password (for PRoot environment)
echo "root:root" | chpasswd 2>/dev/null || true

# Create required groups
groupadd -f storage
groupadd -f wheel

# Configure users (maia as default MaiaLinux user, and user for backward compatibility)
for TARGET_USER in maia user; do
    if ! id -u "$TARGET_USER" >/dev/null 2>&1; then
        useradd -m -g users -G audio,storage,sudo,wheel,video -s /bin/bash "$TARGET_USER"
        echo "${TARGET_USER}:${TARGET_USER}" | chpasswd
    else
        usermod -a -G audio,storage,sudo,wheel,video,users "$TARGET_USER" 2>/dev/null || true
    fi
    mkdir -p "/home/${TARGET_USER}/Desktop" "/home/${TARGET_USER}/bin" "/home/${TARGET_USER}/projects"
done

# Passwordless sudo for PRoot container users
cat << 'EOF' > /etc/sudoers.d/maialinux
%sudo ALL=(ALL:ALL) NOPASSWD: ALL
maia ALL=(ALL:ALL) NOPASSWD: ALL
user ALL=(ALL:ALL) NOPASSWD: ALL
EOF
chmod 0440 /etc/sudoers.d/maialinux

echo "=== [5/7] Installing Tablet Wallpapers ==="
WP_DIR="/usr/share/wallpapers/maialinux"
mkdir -p "$WP_DIR"

if [[ -d "${REPO_DIR}/debian/wallpapers" ]]; then
    cp -f "${REPO_DIR}"/debian/wallpapers/* "$WP_DIR/" 2>/dev/null || true
fi
if [[ -d "${REPO_DIR}/images" ]]; then
    cp -f "${REPO_DIR}"/images/*.png "$WP_DIR/" 2>/dev/null || true
fi

# Ensure standardized names and active wallpaper symlink
if [[ -f "$WP_DIR/Paisagem Neon com Logo Maialinux.png" && ! -f "$WP_DIR/maialinux-tablet-neon.png" ]]; then
    cp -f "$WP_DIR/Paisagem Neon com Logo Maialinux.png" "$WP_DIR/maialinux-tablet-neon.png"
fi
if [[ -f "$WP_DIR/Paisagem Roxa com Logo MAIALINUX.png" && ! -f "$WP_DIR/maialinux-tablet-purple.png" ]]; then
    cp -f "$WP_DIR/Paisagem Roxa com Logo MAIALINUX.png" "$WP_DIR/maialinux-tablet-purple.png"
fi
if [[ -f "$WP_DIR/Pôster neon do MaiaLinux com Tux e Android.png" && ! -f "$WP_DIR/maialinux-tablet-tux-android.png" ]]; then
    cp -f "$WP_DIR/Pôster neon do MaiaLinux com Tux e Android.png" "$WP_DIR/maialinux-tablet-tux-android.png"
fi

ln -sf "$WP_DIR/maialinux-tablet-neon.png" "$WP_DIR/current.png" 2>/dev/null || true

echo "=== [6/7] Installing Utilities and Desktop Shortcuts ==="
# Executable binaries
if [[ -d "${REPO_DIR}/debian/bin" ]]; then
    cp -f "${REPO_DIR}"/debian/bin/* /usr/local/bin/
    chmod +x /usr/local/bin/*
    ln -sf /usr/local/bin/wings-virgl.sh /usr/local/bin/wings3d-virgl.sh 2>/dev/null || true
fi

# Desktop shortcuts
mkdir -p /usr/local/share/applications /etc/skel/Desktop
if [[ -d "${REPO_DIR}/debian/desktop" ]]; then
    cp -f "${REPO_DIR}"/debian/desktop/*.desktop /usr/local/share/applications/
    cp -f "${REPO_DIR}"/debian/desktop/*.desktop /etc/skel/Desktop/
fi

for TARGET_USER in maia user; do
    if [[ -d "/home/${TARGET_USER}" ]]; then
        cp -f "${REPO_DIR}"/debian/desktop/*.desktop "/home/${TARGET_USER}/Desktop/" 2>/dev/null || true
        chmod +x "/home/${TARGET_USER}/Desktop/"*.desktop 2>/dev/null || true
    fi
done

echo "=== [7/7] Applying LXQt Visual Theme (Dark Catppuccin / Tablet) ==="
CFG_SRC="${REPO_DIR}/debian/config"
SHARE_MAIA="/usr/local/share/maialinux"
mkdir -p "$SHARE_MAIA"

if [[ -f "${CFG_SRC}/keyboard/keyboard.xml" ]]; then
    cp -f "${CFG_SRC}/keyboard/keyboard.xml" "${SHARE_MAIA}/keyboard.xml"
fi

# Deploy configs to /etc/skel and user home directories
for TARGET_DIR in /etc/skel /home/maia /home/user; do
    [[ -d "$TARGET_DIR" ]] || continue
    mkdir -p "${TARGET_DIR}/.config/lxqt" \
             "${TARGET_DIR}/.config/openbox" \
             "${TARGET_DIR}/.config/pcmanfm-qt/lxqt" \
             "${TARGET_DIR}/.matchbox"

    if [[ -f "${CFG_SRC}/lxqt/lxqt.conf" ]]; then
        cp -f "${CFG_SRC}/lxqt/lxqt.conf" "${TARGET_DIR}/.config/lxqt/lxqt.conf"
    fi
    if [[ -f "${CFG_SRC}/lxqt/panel.conf" ]]; then
        cp -f "${CFG_SRC}/lxqt/panel.conf" "${TARGET_DIR}/.config/lxqt/panel.conf"
    fi
    if [[ -f "${CFG_SRC}/lxqt/session.conf" ]]; then
        cp -f "${CFG_SRC}/lxqt/session.conf" "${TARGET_DIR}/.config/lxqt/session.conf"
    fi
    if [[ -f "${CFG_SRC}/openbox/lxqt-rc.xml" ]]; then
        cp -f "${CFG_SRC}/openbox/lxqt-rc.xml" "${TARGET_DIR}/.config/openbox/lxqt-rc.xml"
    fi
    if [[ -f "${CFG_SRC}/lxqt/pcmanfm-qt-settings.conf" ]]; then
        cp -f "${CFG_SRC}/lxqt/pcmanfm-qt-settings.conf" "${TARGET_DIR}/.config/pcmanfm-qt/lxqt/settings.conf"
    fi
    if [[ -f "${CFG_SRC}/keyboard/keyboard.xml" ]]; then
        cp -f "${CFG_SRC}/keyboard/keyboard.xml" "${TARGET_DIR}/.matchbox/keyboard.xml"
    fi
done

chown -R maia:users /home/maia 2>/dev/null || true
chown -R user:users /home/user 2>/dev/null || true

echo "=== MaiaLinux (Debian 13 + LXQt) Setup Completed Successfully! ==="
