#!/usr/bin/env bash
# MaiaLinux Android - Debian 13 Trixie / LXQt full setup
# Run as root inside the Debian PRoot environment, from a cloned repository.
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

log() { printf '\n=== %s ===\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
trap 'warn "Installation stopped at line ${LINENO}. Review the error above."' ERR

if [[ "$(id -u)" -ne 0 ]]; then
  echo 'Run as root (sudo bash debian/scripts/setup.sh).' >&2
  exit 1
fi
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
if [[ ! -d "${REPO_DIR}/debian" ]]; then
  echo "Repository layout not found: ${REPO_DIR}/debian" >&2
  echo 'Place this file at debian/scripts/setup.sh inside the MaiaLinux Android repository.' >&2
  exit 1
fi

log '[1/7] Checking Debian 13 repositories'
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  if [[ "${ID:-}" != debian || "${VERSION_CODENAME:-}" != trixie ]]; then
    warn "Expected Debian 13 Trixie; found ${PRETTY_NAME:-unknown}."
  fi
fi
# Debian 13 commonly ships deb822 sources in /etc/apt/sources.list.d/debian.sources.
# Do not overwrite these or create duplicate sources. If no sources exist, create a fallback.
if ! grep -RqsE '^[[:space:]]*(deb[[:space:]]|URIs:)' /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
  cat > /etc/apt/sources.list <<'EOF'
deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb http://deb.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
EOF
fi
apt-get update
# No dist-upgrade: do not replace unrelated packages during desktop setup.

log '[2/7] Preserving existing desktop packages'
# Deliberately do not purge XFCE, LightDM, or autoremove: this can break an existing install.

log '[3/7] Installing LXQt, keyboard, applications and utilities'
apt-get install -y --no-install-recommends \
  lxqt-core lxqt-panel lxqt-session lxqt-runner lxqt-qtplugin \
  lxqt-policykit lxqt-notificationd openbox pcmanfm-qt qterminal \
  dbus-x11 x11-xserver-utils x11-utils xauth \
  papirus-icon-theme fonts-dejavu fonts-noto-core fonts-noto-cjk \
  ca-certificates curl wget git vim nano sudo locales tzdata \
  matchbox-keyboard onboard geany firefox-esr mesa-utils \
  pulseaudio-utils pulseaudio file-roller build-essential \
  xdg-utils desktop-file-utils shared-mime-info \
  unzip zip p7zip-full procps file

log '[4/7] Configuring locale, timezone and user accounts'
ln -sfn /usr/share/zoneinfo/America/Bahia /etc/localtime
if [[ -f /etc/locale.gen ]]; then
  sed -i -E 's/^#[[:space:]]*(pt_BR.UTF-8[[:space:]]+UTF-8)/\1/; s/^#[[:space:]]*(en_US.UTF-8[[:space:]]+UTF-8)/\1/' /etc/locale.gen
  locale-gen
fi
printf 'LANG=pt_BR.UTF-8\n' > /etc/default/locale
printf 'LANG=pt_BR.UTF-8\n' > /etc/locale.conf
# Do not reset root password on reruns. Users created with locked passwords by default;
# set their password interactively with passwd if password authentication is needed.
for group in storage wheel audio video; do
  getent group "$group" >/dev/null || groupadd "$group"
done
for target_user in maia user; do
  if ! id "$target_user" >/dev/null 2>&1; then
    useradd -m -g users -G audio,storage,sudo,wheel,video -s /bin/bash "$target_user"
    warn "Created ${target_user} with a locked password; use 'passwd ${target_user}' if needed."
  else
    usermod -aG audio,storage,sudo,wheel,video,users "$target_user"
    usermod -s /bin/bash "$target_user"
  fi
  install -d -o "$target_user" -g users \
    "/home/${target_user}/Desktop" "/home/${target_user}/bin" "/home/${target_user}/projects"
done
# PRoot development convenience, limited to the two project accounts.
cat > /etc/sudoers.d/maialinux <<'EOF'
maia ALL=(ALL:ALL) NOPASSWD: ALL
user ALL=(ALL:ALL) NOPASSWD: ALL
EOF
chmod 0440 /etc/sudoers.d/maialinux
visudo -cf /etc/sudoers.d/maialinux

log '[5/7] Installing MaiaLinux tablet wallpapers'
WP_DIR=/usr/share/wallpapers/maialinux
install -d "$WP_DIR"
copy_glob() {
  local src_dir="$1" pattern="$2" dest="$3" f
  [[ -d "$src_dir" ]] || return 0
  while IFS= read -r -d '' f; do cp -f -- "$f" "$dest/"; done \
    < <(find "$src_dir" -maxdepth 1 -type f -name "$pattern" -print0)
}
copy_glob "${REPO_DIR}/debian/wallpapers" '*' "$WP_DIR"
copy_glob "${REPO_DIR}/images" '*.png' "$WP_DIR"
[[ ! -f "$WP_DIR/Paisagem Neon com Logo Maialinux.png" ]] || \
  cp -f "$WP_DIR/Paisagem Neon com Logo Maialinux.png" "$WP_DIR/maialinux-tablet-neon.png"
[[ ! -f "$WP_DIR/Paisagem Roxa com Logo MAIALINUX.png" ]] || \
  cp -f "$WP_DIR/Paisagem Roxa com Logo MAIALINUX.png" "$WP_DIR/maialinux-tablet-purple.png"
[[ ! -f "$WP_DIR/Pôster neon do MaiaLinux com Tux e Android.png" ]] || \
  cp -f "$WP_DIR/Pôster neon do MaiaLinux com Tux e Android.png" "$WP_DIR/maialinux-tablet-tux-android.png"
if [[ -f "$WP_DIR/maialinux-tablet-neon.png" ]]; then
  ln -sfn "$WP_DIR/maialinux-tablet-neon.png" "$WP_DIR/current.png"
else
  warn 'Neon wallpaper not found in repository; no current.png symlink created.'
fi

log '[6/7] Installing repository utilities, desktop shortcuts and safe launchers'
install -d /usr/local/bin /usr/local/share/applications /etc/skel/Desktop
if [[ -d "${REPO_DIR}/debian/bin" ]]; then
  while IFS= read -r -d '' f; do
    install -m 0755 "$f" "/usr/local/bin/$(basename "$f")"
  done < <(find "${REPO_DIR}/debian/bin" -maxdepth 1 -type f -print0)
fi
if [[ -f /usr/local/bin/wings-virgl.sh ]]; then
  ln -sfn /usr/local/bin/wings-virgl.sh /usr/local/bin/wings3d-virgl.sh
fi
if [[ -d "${REPO_DIR}/debian/desktop" ]]; then
  copy_glob "${REPO_DIR}/debian/desktop" '*.desktop' /usr/local/share/applications
  copy_glob "${REPO_DIR}/debian/desktop" '*.desktop' /etc/skel/Desktop
  for target_user in maia user; do
    copy_glob "${REPO_DIR}/debian/desktop" '*.desktop' "/home/${target_user}/Desktop"
    find "/home/${target_user}/Desktop" -maxdepth 1 -type f -name '*.desktop' -exec chmod +x {} +
  done
fi
cat > /usr/local/bin/maialinux-keyboard <<'EOF'
#!/usr/bin/env bash
exec matchbox-keyboard --fontfamily 'DejaVu Sans' --fontptsize 14 "$@"
EOF
cat > /usr/local/bin/maialinux-firefox <<'EOF'
#!/usr/bin/env bash
# Conservative software GL path validated on Termux-X11.
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export MOZ_X11_EGL=0
export MOZ_ENABLE_WAYLAND=0
exec firefox-esr "$@"
EOF
chmod 0755 /usr/local/bin/maialinux-keyboard /usr/local/bin/maialinux-firefox

log '[7/7] Applying repository LXQt / Openbox / Matchbox configuration'
CFG_SRC="${REPO_DIR}/debian/config"
SHARE_MAIA=/usr/local/share/maialinux
install -d "$SHARE_MAIA"
if [[ -f "${CFG_SRC}/keyboard/keyboard.xml" ]]; then
  install -m 0644 "${CFG_SRC}/keyboard/keyboard.xml" "${SHARE_MAIA}/keyboard.xml"
fi
for target_dir in /etc/skel /home/maia /home/user; do
  [[ -d "$target_dir" ]] || continue
  install -d "$target_dir/.config/lxqt" "$target_dir/.config/openbox" \
    "$target_dir/.config/pcmanfm-qt/lxqt" "$target_dir/.matchbox"
  for name in lxqt.conf panel.conf session.conf; do
    [[ ! -f "${CFG_SRC}/lxqt/${name}" ]] || \
      cp -f "${CFG_SRC}/lxqt/${name}" "$target_dir/.config/lxqt/${name}"
  done
  [[ ! -f "${CFG_SRC}/openbox/lxqt-rc.xml" ]] || \
    cp -f "${CFG_SRC}/openbox/lxqt-rc.xml" "$target_dir/.config/openbox/lxqt-rc.xml"
  [[ ! -f "${CFG_SRC}/lxqt/pcmanfm-qt-settings.conf" ]] || \
    cp -f "${CFG_SRC}/lxqt/pcmanfm-qt-settings.conf" \
      "$target_dir/.config/pcmanfm-qt/lxqt/settings.conf"
  [[ ! -f "${CFG_SRC}/keyboard/keyboard.xml" ]] || \
    cp -f "${CFG_SRC}/keyboard/keyboard.xml" "$target_dir/.matchbox/keyboard.xml"
done
# Own only deployed configuration and Desktop; do not recursively chown user homes.
for target_user in maia user; do
  chown -R "$target_user:users" "/home/${target_user}/.config/lxqt" \
    "/home/${target_user}/.config/openbox" \
    "/home/${target_user}/.config/pcmanfm-qt" \
    "/home/${target_user}/.matchbox" "/home/${target_user}/Desktop"
done

log 'MaiaLinux Android setup complete'
echo 'Keyboard: maialinux-keyboard (DejaVu Sans, 14 pt)'
echo 'Firefox:  maialinux-firefox (software GL fallback)'
echo 'Desktop:  LXQt + Openbox; repository configs, shortcuts and wallpapers installed.'
echo 'Note: start the LXQt session through the existing Termux-X11 launch script.'
