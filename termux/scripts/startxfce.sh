#!/bin/sh
# MaiaLinux-Android - Compatibility wrapper: redirects to startlxqt.sh
echo "MaiaLinux now uses the LXQt desktop on Debian 13 (Trixie)."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "${SCRIPT_DIR}/startlxqt.sh" "$@"
