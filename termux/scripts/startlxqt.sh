#!/bin/sh
# MaiaLinux-Android - Launch LXQt session via Termux-X11

export DISPLAY=:0
export XDG_RUNTIME_DIR=${TMPDIR}

killall -9 termux-x11 virgl_test_server_android pulseaudio 2>/dev/null || true

pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 2>/dev/null || true
pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null || true

if command -v virgl_test_server_android >/dev/null 2>&1; then
    virgl_test_server_android --angle-vulkan &
fi

LOGIN_USER="${MAIA_USER:-maia}"

termux-x11 :0 -xstartup "proot-distro login debian --user $LOGIN_USER --shared-tmp -- bash -c 'export DISPLAY=:0 PULSE_SERVER=tcp:127.0.0.1 QT_QPA_PLATFORMTHEME=lxqt XDG_CURRENT_DESKTOP=LXQt; dbus-launch --exit-with-session startlxqt'"

