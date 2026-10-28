#!/bin/sh
# MaiaLinux-Android - Terminate all X11, audio, and container sessions cleanly

killall -9 termux-x11 virgl_test_server_android pulseaudio proot 2>/dev/null || true
echo "All MaiaLinux-Android instances have been terminated."
