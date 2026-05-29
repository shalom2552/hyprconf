# ~/.config/hypr/input.conf

##############################
# INPUT
##############################

input {
    kb_layout = us,il
    kb_variant =
    kb_model =
    kb_options = caps:escape, grp:win_space_toggle
    kb_rules =

    follow_mouse = 1

    repeat_rate = 50
    repeat_delay = 250
    numlock_by_default = true

    sensitivity = 0 # -1.0 - 1.0, 0 means no modification.

    natural_scroll = true

    touchpad {
        natural_scroll = true
        tap-to-click = true
    }
}

# Touchpad
gesture = 3, vertical, workspace    # 3 fingers swipe workspaces

