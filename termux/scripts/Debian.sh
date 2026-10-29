
#!/data/data/com.termux/files/usr/bin/sh
# MaiaLinux Android - Debian 13 / LXQt / Termux-X11

export DISPLAY=:0
export XDG_RUNTIME_DIR="${TMPDIR}"

# Launch Android X11 activity
am start --user 0 \
  -n com.termux.x11/com.termux.x11.MainActivity \
  2>/dev/null || true

sleep 2

# Stop previous graphics/audio services
killall termux-x11 virgl_test_server_android \
  pulseaudio 2>/dev/null || true

# Start PulseAudio
pulseaudio --start \
  --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" \
  --exit-idle-time=-1 2>/dev/null || true

# Start VirGL
if command -v virgl_test_server_android >/dev/null 2>&1; then
    virgl_test_server_android --angle-vulkan &
fi

# Start Termux-X11
termux-x11 :0 -ac &
sleep 2

LOGIN_USER="${MAIA_USER:-maia}"

# Start Debian LXQt
proot-distro login debian \
  --user "$LOGIN_USER" \
  --shared-tmp \
  --no-sysvipc \
  -- /bin/bash -c '
    export DISPLAY=:0
    export PULSE_SERVER=tcp:127.0.0.1
    export QT_QPA_PLATFORMTHEME=lxqt
    export XDG_CURRENT_DESKTOP=LXQt
    export XDG_SESSION_TYPE=x11
    export SHELL=/bin/bash

    # Conservative Firefox rendering
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
    export MOZ_X11_EGL=0
    export MOZ_ENABLE_WAYLAND=0

    # Start LXQt session
    dbus-launch --exit-with-session startlxqt
  '
