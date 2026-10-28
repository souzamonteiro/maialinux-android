#!/bin/sh
# MaiaLinux-Android - Launch Full LXQt Desktop with Termux-X11 and PulseAudio

export DISPLAY=:0
export XDG_RUNTIME_DIR=${TMPDIR}

# Launch the Termux-X11 Android app activity
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity 2>/dev/null || true

sleep 2

# Terminate previous instances to avoid busy ports
killall -9 termux-x11 virgl_test_server_android pulseaudio 2>/dev/null || true

# Start PulseAudio with TCP bridge for the Debian container
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 2>/dev/null || true
pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null || true

# Start VirGL acceleration server (Vulkan / GL)
if command -v virgl_test_server_android >/dev/null 2>&1; then
    virgl_test_server_android --angle-vulkan &
    # virgl_test_server_android --angle-gl &
    # virgl_test_server_android &
fi

# Start X11 server
termux-x11 :0 -ac &

sleep 1

# Select user (maia or user)
LOGIN_USER="${MAIA_USER:-maia}"

# Launch LXQt session inside Debian 13 (Trixie)
proot-distro login debian --user "$LOGIN_USER" --shared-tmp --no-sysvipc -- bash -c \
  "export DISPLAY=:0 PULSE_SERVER=tcp:127.0.0.1 QT_QPA_PLATFORMTHEME=lxqt XDG_CURRENT_DESKTOP=LXQt XDG_SESSION_TYPE=x11; dbus-launch --exit-with-session startlxqt"
