#!/usr/bin/env bash
set -uo pipefail

WINDOW_CLASS="fzf-popup-wall"
WALL_DIR="$HOME/Pictures/wallpapers"

if [[ ! -t 0 ]]; then
    read -r existing_pid existing_class < <(hyprctl clients -j 2>/dev/null \
        | jq -r '.[] | select(.class | startswith("fzf-popup")) | "\(.pid) \(.class)"' \
        | head -1)

    if [[ -n "$existing_pid" ]]; then
        kill "$existing_pid" 2>/dev/null || true
        [[ "$existing_class" == "$WINDOW_CLASS" ]] && exit 0
        sleep 0.15
    fi

    kitty --class "$WINDOW_CLASS" -e "$0"
    exit 0
fi

selected=$(
    find "$WALL_DIR" -maxdepth 1 \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | sort \
    | awk -F/ '{print $NF"\t"$0}' \
    | fzf \
        --delimiter=$'\t' --with-nth=1 \
        --prompt="Search > " --pointer="▶" --marker="✓" \
        --preview='printf "\033_Ga=d;\033\\\\"; chafa --format=kitty --size=${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES} {2} 2>/dev/null' \
        --preview-window=right:70%:wrap \
        --style=full \
        --preview-label=" Preview " \
        --border-label=" Wallpaper Picker " \
        --no-info --border=rounded --height=100% \
        --color=fg:#c0caf5,bg:-1,hl:#bb9af7 \
        --color=fg+:#c0caf5,bg+:-1,hl+:#7dcfff \
        --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff \
        --bind "ctrl-r:execute-silent(find $WALL_DIR -maxdepth 1 \\( -iname *.jpg -o -iname *.jpeg -o -iname *.png \\) | shuf -n1 | xargs $HOME/.config/hypr/scripts/set-wallpaper.sh)+abort"
) || exit 0

path=$(printf "%s" "$selected" | cut -f2)
[[ -n "$path" ]] && "$HOME/.config/hypr/scripts/set-wallpaper.sh" "$path"
