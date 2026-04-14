#!/usr/bin/env bash

# Ensure qs is running - else run it
pgrep -x qs > /dev/null || { qs -p ~/.config/hypr/scripts/quickshell/Main.qml & sleep 0.4; }

# -----------------------------------------------------------------------------
# CONSTANTS & ARGUMENTS
# -----------------------------------------------------------------------------
QS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$HOME/Pictures/wallpapers"
THUMB_DIR="$HOME/.cache/wallpaper_picker/thumbs"
IPC_FILE="/tmp/qs_widget_state"

ACTION="$1"
TARGET="$2"

# -----------------------------------------------------------------------------
# PREP FUNCTIONS
# -----------------------------------------------------------------------------
handle_wallpaper_prep() {
    mkdir -p "$THUMB_DIR"
    (
        for thumb in "$THUMB_DIR"/*; do
            [ -e "$thumb" ] || continue
            filename=$(basename "$thumb")
            clean_name="${filename#000_}"
            if [ ! -f "$SRC_DIR/$clean_name" ]; then
                rm -f "$thumb"
            fi
        done

        for img in "$SRC_DIR"/*.{jpg,jpeg,png,webp,gif,mp4,mkv,mov,webm}; do
            [ -e "$img" ] || continue
            filename=$(basename "$img")
            extension="${filename##*.}"

            # Intercept WebP files dropped into the folder and convert them
            if [[ "${extension,,}" == "webp" ]]; then
                new_img="${img%.*}.jpg"
                magick "$img" "$new_img"
                rm -f "$img"
                img="$new_img"
                filename=$(basename "$img")
                extension="jpg"
            fi

            if [[ "${extension,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
                thumb="$THUMB_DIR/000_$filename"
                [ -f "$THUMB_DIR/$filename" ] && rm -f "$THUMB_DIR/$filename"
                if [ ! -f "$thumb" ]; then
                     ffmpeg -y -ss 00:00:05 -i "$img" -vframes 1 -f image2 -q:v 2 "$thumb" > /dev/null 2>&1
                fi
            else
                thumb="$THUMB_DIR/$filename"
                if [ ! -f "$thumb" ]; then
                    magick "$img" -resize x420 -quality 70 "$thumb"
                fi
            fi
        done
    ) &

    TARGET_THUMB=""
    CURRENT_SRC=""

    if pgrep -a "mpvpaper" > /dev/null; then
        CURRENT_SRC=$(pgrep -a mpvpaper | grep -o "$SRC_DIR/[^' ]*" | head -n1)
        CURRENT_SRC=$(basename "$CURRENT_SRC")
    fi

    if [ -z "$CURRENT_SRC" ] && command -v swww >/dev/null; then
        CURRENT_SRC=$(swww query 2>/dev/null | grep -o "$SRC_DIR/[^ ]*" | head -n1)
        CURRENT_SRC=$(basename "$CURRENT_SRC")
    fi

    if [ -n "$CURRENT_SRC" ]; then
        EXT="${CURRENT_SRC##*.}"
        if [[ "${EXT,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
            TARGET_THUMB="000_$CURRENT_SRC"
        else
            TARGET_THUMB="$CURRENT_SRC"
        fi
    fi

    export WALLPAPER_THUMB="$TARGET_THUMB"
}

# -----------------------------------------------------------------------------
# ENSURE MASTER WINDOW IS ALIVE (ZOMBIE WATCHDOG)
# -----------------------------------------------------------------------------
QS_PID=$(pgrep -f "quickshell.*Main\.qml")

if [[ -z "$QS_PID" ]]; then
    quickshell -p "$QS_DIR/Main.qml" >/dev/null 2>&1 &
    disown
    sleep 0.4
elif ! hyprctl clients -j 2>/dev/null | grep -q "qs-master"; then
    kill -9 $QS_PID 2>/dev/null
    quickshell -p "$QS_DIR/Main.qml" >/dev/null 2>&1 &
    disown
    sleep 0.4
fi

# -----------------------------------------------------------------------------
# ACTIONS
# -----------------------------------------------------------------------------
if [[ "$ACTION" == "close" ]]; then
    echo "close" > "$IPC_FILE"
    exit 0
fi

if [[ "$ACTION" == "open" || "$ACTION" == "toggle" ]]; then
    PRIMARY_X=$(cut -d' ' -f1 /tmp/qs_monitor_offset 2>/dev/null || echo 0)
    PRIMARY_WS=$(hyprctl monitors -j | jq -r --argjson x "$PRIMARY_X" '.[] | select(.x == ($x | tonumber)) | .activeWorkspace.id')
    hyprctl dispatch movetoworkspacesilent "$PRIMARY_WS,title:^(qs-master)$" >/dev/null 2>&1

    handle_wallpaper_prep
    echo "wallpaper:$WALLPAPER_THUMB" > "$IPC_FILE"
    exit 0
fi
