#!/bin/sh
# MaiaLinux-Android - Terminate all X11, audio, and container sessions cleanly

pkill -f termux-x11
pkill -f virgl_test_server_android
pkill -f pulseaudio
pkill -f proot

echo "All MaiaLinux-Android instances have been terminated."
