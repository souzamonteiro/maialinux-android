#!/usr/bin/env bash
# MaiaLinux-Android - Debian 13 (Trixie) & LXQt Setup Script
# Configures Debian 13, installs LXQt desktop, on-screen keyboard, tablet wallpapers, and MaiaLinux theme.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "=== [1/7] Configurando Repositórios do Debian 13 (Trixie) ==="
cat << 'EOF' > /etc/apt/sources.list
deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb http://deb.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
EOF

apt update -y
apt dist-upgrade -y

echo "=== [2/7] Removendo XFCE legado (se presente) ==="
apt remove --purge -y xfce4 xfce4-* xfwm4 lightdm 2>/dev/null || true
apt autoremove --purge -y 2>/dev/null || true

echo "=== [3/7] Instalando Ambiente LXQt, Teclado Virtual e Utilitários ==="
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

echo "=== [4/7] Configurando Localização, Fuso Horário e Usuários ==="
ln -sf /usr/share/zoneinfo/America/Bahia /etc/localtime

# Configurar locales pt_BR e en_US
sed -i -E 's/#[[:space:]]?(pt_BR.UTF-8[[:space:]]+UTF-8)/\1/g' /etc/locale.gen
sed -i -E 's/#[[:space:]]?(en_US.UTF-8[[:space:]]+UTF-8)/\1/g' /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf
echo "LANG=pt_BR.UTF-8" > /etc/default/locale

# Senha de root padrão (para ambiente proot)
echo "root:root" | chpasswd 2>/dev/null || true

# Criar grupos necessários
groupadd -f storage
groupadd -f wheel

# Configurar usuários (maia como principal do MaiaLinux, e user para retrocompatibilidade)
for TARGET_USER in maia user; do
    if ! id -u "$TARGET_USER" >/dev/null 2>&1; then
        useradd -m -g users -G audio,storage,sudo,wheel,video -s /bin/bash "$TARGET_USER"
        echo "${TARGET_USER}:${TARGET_USER}" | chpasswd
    else
        usermod -a -G audio,storage,sudo,wheel,video,users "$TARGET_USER" 2>/dev/null || true
    fi
    mkdir -p "/home/${TARGET_USER}/Desktop" "/home/${TARGET_USER}/bin" "/home/${TARGET_USER}/projects"
done

# Permissão sudo sem senha para usuários do proot
cat << 'EOF' > /etc/sudoers.d/maialinux
%sudo ALL=(ALL:ALL) NOPASSWD: ALL
maia ALL=(ALL:ALL) NOPASSWD: ALL
user ALL=(ALL:ALL) NOPASSWD: ALL
EOF
chmod 0440 /etc/sudoers.d/maialinux

echo "=== [5/7] Instalando Papéis de Parede para Tablet ==="
WP_DIR="/usr/share/wallpapers/maialinux"
mkdir -p "$WP_DIR"

if [[ -d "${REPO_DIR}/debian/wallpapers" ]]; then
    cp -f "${REPO_DIR}"/debian/wallpapers/* "$WP_DIR/" 2>/dev/null || true
fi
if [[ -d "${REPO_DIR}/images" ]]; then
    cp -f "${REPO_DIR}"/images/*.png "$WP_DIR/" 2>/dev/null || true
fi

# Garantir nomes padronizados e link simbólico para o papel de parede ativo
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

echo "=== [6/7] Instalando Utilitários e Atalhos Desktop ==="
# Scripts executáveis
if [[ -d "${REPO_DIR}/debian/bin" ]]; then
    cp -f "${REPO_DIR}"/debian/bin/* /usr/local/bin/
    chmod +x /usr/local/bin/*
    ln -sf /usr/local/bin/wings-virgl.sh /usr/local/bin/wings3d-virgl.sh 2>/dev/null || true
fi

# Atalhos .desktop para sistema e área de trabalho
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

echo "=== [7/7] Configurando Perfil Visual do LXQt (Dark / Tablet) ==="
CFG_SRC="${REPO_DIR}/debian/config"
SHARE_MAIA="/usr/local/share/maialinux"
mkdir -p "$SHARE_MAIA"

if [[ -f "${CFG_SRC}/keyboard/keyboard.xml" ]]; then
    cp -f "${CFG_SRC}/keyboard/keyboard.xml" "${SHARE_MAIA}/keyboard.xml"
fi

# Instalar configurações no /etc/skel e nas contas dos usuários
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

echo "=== Configuração do MaiaLinux (Debian 13 + LXQt) Concluída com Sucesso! ==="
