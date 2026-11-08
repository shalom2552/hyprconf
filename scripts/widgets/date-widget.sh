#!/usr/bin/env bash

COLS=20
ROWS=8
TOP=30
LEFT=30
CMD=(watch -tcn1 'printf "      \033[1;35m%s\033[0m\n" "$(date +%T)"; cal --color=always')

FILL='#1e1e2e'
BORDER='#b4befe'
RADIUS=20
STROKE=3
PAD=12
CELL_W=11
CELL_H=22

name=$(basename "$0" .sh)
w=$((COLS * CELL_W + 2 * PAD))
h=$((ROWS * CELL_H + 2 * PAD))
bg="${XDG_CACHE_HOME:-$HOME/.cache}/widgets/$name.png"
mkdir -p "${bg%/*}"
magick -size "${w}x$h" xc:none -fill "$FILL" -stroke "$BORDER" -strokewidth "$STROKE" \
  -draw "roundrectangle 2,2 $((w - 3)),$((h - 3)) $RADIUS,$RADIUS" "$bg"

exec kitten panel \
  --edge=none \
  --layer=bottom \
  --columns="$COLS" \
  --lines="$ROWS" \
  --margin-top="$TOP" \
  --margin-left="$LEFT" \
  --focus-policy=not-allowed \
  --exclusive-zone=0 --override-exclusive-zone \
  --single-instance --instance-group=widgets \
  -o background_opacity=0 \
  -o background_image="$bg" \
  -o background_image_layout=scaled \
  -o window_padding_width="$PAD" \
  "${CMD[@]}"
