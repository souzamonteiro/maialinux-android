#!/usr/bin/env bash
# maialinux-wallpaper.sh
# Switches or cycles between MaiaLinux tablet wallpapers for LXQt / PCManFM-Qt.

set -uo pipefail

WALLPAPER_DIR="/usr/share/wallpapers/maialinux"
STATE_FILE="${HOME}/.config/maialinux-wallpaper-current"
ACTIVE_WP="${WALLPAPER_DIR}/current.png"

# Candidate wallpapers in cycle order
WP_LIST=(
    "${WALLPAPER_DIR}/maialinux-tablet-neon.png"
    "${WALLPAPER_DIR}/maialinux-tablet-purple.png"
    "${WALLPAPER_DIR}/maialinux-tablet-tux-android.png"
)

# Fallback paths if not yet installed in /usr/share/wallpapers/maialinux
if [[ ! -f "${WP_LIST[0]}" ]]; then
    FALLBACK_DIR="/home/roberto/projects/maialinux-android/images"
    if [[ -d "$FALLBACK_DIR" ]]; then
        WP_LIST=(
            "${FALLBACK_DIR}/Paisagem Neon com Logo Maialinux.png"
            "${FALLBACK_DIR}/Paisagem Roxa com Logo MAIALINUX.png"
            "${FALLBACK_DIR}/Pôster neon do MaiaLinux com Tux e Android.png"
        )
    fi
fi

TOTAL=${#WP_LIST[@]}
CURRENT_IDX=0

if [[ -f "$STATE_FILE" ]]; then
    SAVED_IDX="$(cat "$STATE_FILE" 2>/dev/null || echo 0)"
    if [[ "$SAVED_IDX" =~ ^[0-9]+$ ]] && (( SAVED_IDX >= 0 && SAVED_IDX < TOTAL )); then
        CURRENT_IDX="$SAVED_IDX"
    fi
fi

TARGET_IDX=0
MODE="${1:-next}"

case "$MODE" in
    next|cycle|toggle)
        TARGET_IDX=$(( (CURRENT_IDX + 1) % TOTAL ))
        ;;
    neon|1)
        TARGET_IDX=0
        ;;
    purple|roxa|2)
        TARGET_IDX=1
        ;;
    tux|android|3)
        TARGET_IDX=2
        ;;
    *)
        TARGET_IDX=0
        ;;
esac

CHOSEN_WP="${WP_LIST[$TARGET_IDX]}"

if [[ -f "$CHOSEN_WP" ]]; then
    echo "$TARGET_IDX" > "$STATE_FILE" 2>/dev/null || true
    
    # Try updating system current symlink if writable
    mkdir -p "$WALLPAPER_DIR" 2>/dev/null || true
    ln -sf "$CHOSEN_WP" "$ACTIVE_WP" 2>/dev/null || true

    # Live update pcmanfm-qt desktop wallpaper
    if command -v pcmanfm-qt >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
        pcmanfm-qt --set-wallpaper="$CHOSEN_WP" --wallpaper-mode=zoom 2>/dev/null || \
        pcmanfm-qt --set-wallpaper="$CHOSEN_WP" --wallpaper-mode=stretch 2>/dev/null || true
    fi

    # Update pcmanfm-qt settings file for persistence
    CONF_FILE="${HOME}/.config/pcmanfm-qt/lxqt/settings.conf"
    if [[ -f "$CONF_FILE" ]]; then
        sed -i "s|^Wallpaper=.*|Wallpaper=${CHOSEN_WP}|" "$CONF_FILE" 2>/dev/null || true
    fi

    echo "Wallpaper set to: $(basename "$CHOSEN_WP")"
else
    echo "Warning: Wallpaper file not found: $CHOSEN_WP" >&2
fi
