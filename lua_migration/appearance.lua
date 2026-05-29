-- ~/.config/hypr/appearance.conf

--===========================
-- APPEARANCE
--===========================

hl.config({

    -- General
    general = {

        gaps_in = 5,
        gaps_out = 10,
        border_size = 1,

        col = {
            active_border = {
                colors = {"rgba(33ccffee)", "rgba(00ff99ee)"},
                angle = 45
            },
            inactive_border = "rgba(595959aa)"
        },

        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    -- Decoration
    decoration = {

        rounding = 10,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = true,
            range = 30,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },

        blur = {
            enabled = true,
            size = 9,
            passes = 3,
            vibrancy = 0.1696,
        },
    }
})

