#!/usr/bin/env bash
# ~/.config/hypr/scripts/popups/launch.sh
# Fuzzy application launcher popup for Hyprland.

set -uo pipefail

SCRIPT="$(realpath "$0")"
WINDOW_CLASS="fzf-popup-launch"

CACHE_FILE="/tmp/launch-cache"
CACHE_TTL=$((60 * 60 * 24))

# ==== INNER: runs inside kitty ====

if [[ "${1:-}" == "--inner" ]]; then
    RESULT_FILE="${2:-}"

    cache_is_stale() {
        [[ ! -f "$CACHE_FILE" ]] && return 0
        local age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") ))
        (( age > CACHE_TTL ))
    }

    if cache_is_stale; then
        IFS=':' read -ra dirs <<< "${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
        {
            for dir in "${dirs[@]}"; do
                app_dir="$dir/applications"
                [[ -d "$app_dir" ]] || continue
                while IFS= read -r -d '' file; do
                    grep -q "^NoDisplay=true" "$file" && continue
                    grep -q "^Hidden=true"    "$file" && continue
                    name=$(grep -m1 "^Name=" "$file" | cut -d= -f2- | tr -d '\t')
                    comment=$(grep -m1 "^Comment=" "$file" | cut -d= -f2- | tr -d '\t' || true)
                    [[ -n "$name" ]] || continue
                    printf '\x1b[38;2;158;206;106m%s\x1b[0m\t%s\t%s\n' "$name" "${comment:-}" "$file"
                done < <(find "$app_dir" -name "*.desktop" -print0 2>/dev/null)
            done
        } | sort -u -t$'\t' -k1,1 > "$CACHE_FILE"
    fi

    PREVIEW_CMD='desc={2}; [ -n "$desc" ] && echo "$desc" || echo "No description"'

    selected=$(fzf --ansi \
        --delimiter=$'\t' \
        --nth=1 \
        --with-nth=1 \
        --prompt="launch > " \
        --pointer="▶" \
        --marker="✓" \
        --select-1 \
        --border-label=" Application Launcher " \
        --bind="ctrl-r:execute(rm -f '$CACHE_FILE')+abort" \
        --preview="$PREVIEW_CMD" \
        --preview-window="top:1:wrap:noinfo" \
        --no-info \
        --border=rounded \
        --height=100% \
        --color=fg:#c0caf5,bg:-1,hl:#bb9af7 \
        --color=fg+:#c0caf5,bg+:-1,hl+:#7dcfff \
        --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff \
        < "$CACHE_FILE"
    ) || exit 0

    printf "%s" "$selected" | cut -f3 > "$RESULT_FILE"
    exit 0
fi

# ==== OUTER: launched by keybind ====

existing=$(hyprctl clients -j 2>/dev/null \
    | jq -r '.[] | select(.class | startswith("fzf-popup")) | .class' \
    | head -1)

if [[ -n "$existing" ]]; then
    hyprctl dispatch killwindow "class:${existing}"
    [[ "$existing" == "$WINDOW_CLASS" ]] && exit 0
    sleep 0.05
fi

RESULT_FILE=$(mktemp /tmp/launch-XXXXXX)
kitty --class "$WINDOW_CLASS" -e "$SCRIPT" --inner "$RESULT_FILE"

desktop_file=$(cat "$RESULT_FILE")
rm -f "$RESULT_FILE"
[[ -z "$desktop_file" ]] && exit 0

app_id="$(basename "$desktop_file" .desktop)"
exec_cmd=$(grep -m1 "^Exec=" "$desktop_file" | cut -d= -f2- | sed 's/ %[a-zA-Z]//g')

if grep -q "^Terminal=true" "$desktop_file"; then
    hyprctl dispatch exec -- kitty -e bash -c "$exec_cmd"
else
    (gtk-launch "$app_id" > /dev/null 2>&1 &)
fi
