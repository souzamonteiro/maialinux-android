#!/bin/sh
# MaiaLinux-Android - Termux Environment Setup
# Prepares Termux packages, audio, X11, and installs Debian 13 (Trixie) via PRoot Distro.

set -e

echo "=== [1/5] Atualizando Termux ==="
pkg update -y
pkg upgrade -y

echo "=== [2/5] Configurando Armazenamento do Dispositivo ==="
termux-setup-storage

echo "=== [3/5] Instalando Dependências do Termux (X11, Áudio, Aceleração) ==="
pkg install -y vim curl wget git pulseaudio dbus
pkg install -y x11-repo
pkg install -y termux-x11-nightly
pkg install -y angle-android virglrenderer-android proot-distro

echo "=== [4/5] Instalando Container Debian no PRoot Distro ==="
if proot-distro list | grep -q "debian (installed)"; then
    echo "Debian já está instalado no PRoot Distro."
else
    echo "Instalando Debian via proot-distro..."
    proot-distro install debian
fi

echo "=== [5/5] Concluído! Próximo passo: ==="
echo "Para concluir a instalação do MaiaLinux (Debian 13 + LXQt), execute:"
echo "  proot-distro login debian --shared-tmp"
echo "E dentro do Debian, execute:"
echo "  cd /home/roberto/projects/maialinux-android/debian/scripts && ./setup.sh"
echo ""
echo "Depois inicie o ambiente gráfico com:"
echo "  ./Debian.sh ou ./startdebian.sh"
