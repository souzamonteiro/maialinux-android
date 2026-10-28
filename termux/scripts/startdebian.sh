#!/bin/sh
# MaiaLinux-Android - Login and Launch LXQt in existing X11 display

LOGIN_USER="${MAIA_USER:-maia}"

proot-distro login debian --user "$LOGIN_USER" --shared-tmp -- bash -c \
  "export DISPLAY=:0 PULSE_SERVER=tcp:127.0.0.1 QT_QPA_PLATFORMTHEME=lxqt XDG_CURRENT_DESKTOP=LXQt XDG_SESSION_TYPE=x11; dbus-launch --exit-with-session startlxqt"
