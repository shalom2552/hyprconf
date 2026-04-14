#!/bin/bash
# Moves focus up/down if a window exists in that direction.
# Falls back to workspace switch if there is none.
# Usage: smart_focus.sh up | down
#
# Uses focuswindow by address instead of movefocus dispatcher to avoid
# a Hyprland v0.54.3 crash in CReservedArea::CReservedArea triggered by
# getWindowInDirection when windows have unusual geometry.

DIR="$1"

CURRENT=$(hyprctl activewindow -j)
read -r CURRENT_ADDR CURRENT_WS CURRENT_CY CURRENT_CX CURRENT_LX CURRENT_RX < <(
    jq -r '[.address, (.workspace.id|tostring),
            (.at[1]+.size[1]/2|tostring), (.at[0]+.size[0]/2|tostring),
            (.at[0]|tostring), (.at[0]+.size[0]|tostring)] | @tsv' <<< "$CURRENT"
)

if [[ "$CURRENT_ADDR" == "null" || -z "$CURRENT_ADDR" ]]; then
    bash ~/.config/hypr/scripts/workspace_switch.sh "$( [[ $DIR == up ]] && echo prev || echo next )"
    exit 0
fi

CLIENTS=$(hyprctl clients -j)

# Strategy:
#   1. Collect all candidates in the right direction (by center Y).
#   2. Prefer candidates that overlap in X with the current window (same column).
#   3. Among the preferred set, pick the closest one by Y; break ties by X proximity.
#   4. If no X-overlapping candidates exist, fall back to all candidates with the same tie-breaking.

[[ "$DIR" == "up" ]] && AGGR='max' || AGGR='min'

TARGET_ADDR=$(echo "$CLIENTS" | jq -r \
    --argjson ws "$CURRENT_WS" \
    --argjson cy "$CURRENT_CY" \
    --argjson cx "$CURRENT_CX" \
    --argjson lx "$CURRENT_LX" \
    --argjson rx "$CURRENT_RX" \
    --arg addr "$CURRENT_ADDR" \
    --arg aggr "$AGGR" \
    '
    def pick_best:
        (map(.at[1] + .size[1] / 2) | if $aggr == "max" then max else min end) as $closest_cy |
        [.[] | select((.at[1] + .size[1] / 2) == $closest_cy)] |
        sort_by((.at[0] + .size[0] / 2 - $cx) * (.at[0] + .size[0] / 2 - $cx)) |
        first | .address;

    [.[] | select(
        .workspace.id == $ws and
        .address != $addr and
        (if $aggr == "max" then .at[1] + .size[1] / 2 < $cy
                           else .at[1] + .size[1] / 2 > $cy end)
    )] |
    if length == 0 then empty
    else
        . as $all |
        ($all | [.[] | select(.at[0] < $rx and (.at[0] + .size[0]) > $lx)]) as $overlap |
        (if ($overlap | length) > 0 then $overlap else $all end) |
        pick_best
    end // empty')

if [[ -n "$TARGET_ADDR" ]]; then
    hyprctl dispatch focuswindow "address:$TARGET_ADDR"
else
    bash ~/.config/hypr/scripts/workspace_switch.sh "$( [[ $DIR == up ]] && echo prev || echo next )"
fi
