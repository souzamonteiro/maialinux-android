#!/bin/sh
# MaiaLinux-Android - Compatibility wrapper: redirects to startlxqt.sh
echo "O MaiaLinux agora utiliza o desktop LXQt sobre Debian 13 (Trixie)."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "${SCRIPT_DIR}/startlxqt.sh" "$@"
