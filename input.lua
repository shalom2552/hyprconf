-- ~/.config/hypr/input.conf
--===========================
-- INPUT
--===========================

hl.config({
    input = {

        kb_layout = "us,il",
        kb_variant = "",
        kb_model = "",
        kb_options = "caps:escape, grp:win_space_toggle",
        kb_rules = "",

        follow_mouse = 1,

        repeat_rate = 50,
        repeat_delay = 250,
        numlock_by_default = true,

        sensitivity = 0,

        natural_scroll = true,

        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
        },

    },
})

-- Touchpad
hl.gesture({
    fingers = 3,
    direction = "vertical",
    action = "workspace",    -- 3 fingers swipe workspaces
})

