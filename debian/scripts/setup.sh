#!/usr/bin/env bash
# MaiaLinux Android: Debian 13 + LXQt + Termux-X11
# Run as root INSIDE Debian PRoot.
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

log() { printf '[MaiaLinux] %s\n' "$*"; }
fail() { printf '[MaiaLinux] ERROR: %s\n' "$*" >&2; exit 1; }
trap 'printf "[MaiaLinux] Failed at line %s\n" "$LINENO" >&2' ERR

(( EUID == 0 )) || fail 'Run as root inside Debian (not in Termux).'
[[ -r /etc/os-release ]] || fail 'Missing /etc/os-release.'
. /etc/os-release
[[ "${ID:-}" == debian && "${VERSION_ID:-}" == 13 ]] || fail 'Requires Debian 13.'

# Do not rewrite APT sources or perform dist-upgrade.
log 'Updating APT package lists'
apt-get update

log 'Installing LXQt desktop and supporting packages'
apt-get install -y --no-install-recommends \
  lxqt-core lxqt-panel lxqt-session lxqt-runner lxqt-qtplugin \
  lxqt-policykit lxqt-notificationd openbox pcmanfm-qt qterminal \
  dbus-x11 x11-xserver-utils x11-utils \
  matchbox-keyboard fonts-dejavu-core fonts-noto-core \
  papirus-icon-theme ca-certificates curl wget git sudo locales \
  firefox-esr mesa-utils pulseaudio-utils file-roller

log 'Creating MaiaLinux launchers'
install -d -m 0755 /usr/local/bin /usr/local/share/applications
cat > /usr/local/bin/maialinux-keyboard <<'KEYBOARD'
#!/usr/bin/env bash
exec /usr/bin/matchbox-keyboard --fontfamily 'DejaVu Sans' --fontptsize 14 "$@"
KEYBOARD
chmod 0755 /usr/local/bin/maialinux-keyboard

cat > /usr/local/share/applications/maialinux-keyboard.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=MaiaLinux Virtual Keyboard
Exec=/usr/local/bin/maialinux-keyboard
Icon=input-keyboard
Terminal=false
Categories=Utility;Accessibility;
DESKTOP

cat > /usr/local/bin/maialinux-firefox <<'FIREFOX'
#!/usr/bin/env bash
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export MOZ_X11_EGL=0
export MOZ_ENABLE_WAYLAND=0
exec /usr/bin/firefox-esr "$@"
FIREFOX
chmod 0755 /usr/local/bin/maialinux-firefox

cat > /usr/local/share/applications/maialinux-firefox.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Firefox ESR (MaiaLinux)
Exec=/usr/local/bin/maialinux-firefox %u
Icon=firefox-esr
Terminal=false
Categories=Network;WebBrowser;
DESKTOP

# Preserve existing sessions, desktop settings, user accounts and passwords.
# If this script is in <repository>/debian/scripts/setup.sh, copy optional
# wallpapers and application launchers from the repository.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
if [[ -d "$REPO_DIR/debian/wallpapers" ]]; then
  install -d -m 0755 /usr/share/wallpapers/maialinux
  find "$REPO_DIR/debian/wallpapers" -maxdepth 1 -type f \
    -exec cp -n -- {} /usr/share/wallpapers/maialinux/ \;
fi
if [[ -d "$REPO_DIR/debian/desktop" ]]; then
  find "$REPO_DIR/debian/desktop" -maxdepth 1 -type f -name '*.desktop' \
    -exec install -m 0644 {} /usr/local/share/applications/ \;
fi

log 'Completed. Keyboard: maialinux-keyboard'
log 'Browser: maialinux-firefox'
log 'Existing LXQt autostart was not modified.'
