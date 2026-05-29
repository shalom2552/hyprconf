-- ~/.config/hypr/keybinds.lua
--===========================
-- KEYBINDS
--===========================
local cfg = require("config")
local mainMod = "SUPER"

-- APPLICATIONS
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(cfg.terminal))
hl.bind(mainMod .. " + T",      hl.dsp.exec_cmd(cfg.terminal))
hl.bind(mainMod .. " + F",      hl.dsp.exec_cmd(cfg.fileManager))
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd(cfg.internetBrowser))

-- LAUNCHERS & UI
hl.bind("ALT + TAB",       hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/popups/alttab.sh"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle wallpaper"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/popups/launch.sh"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/popups/clip.sh"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/popups/power.sh"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("hyprland-run"))

-- WINDOW MANAGEMENT
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/toggle_float.sh"))
hl.bind(mainMod .. " + S", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + Z", hl.dsp.window.fullscreen({ mode = 0 }))

-- FOCUS & NAVIGATION
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/smart_focus.sh up"))
hl.bind(mainMod .. " + down",  hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/smart_focus.sh down"))
hl.bind(mainMod .. " + H",     hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L",     hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K",     hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/smart_focus.sh up"))
hl.bind(mainMod .. " + J",     hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/smart_focus.sh down"))

-- MOVE WINDOWS
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/window_to_workspace.sh prev"))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/window_to_workspace.sh next"))
hl.bind(mainMod .. " + SHIFT + K",     hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/window_to_workspace.sh prev"))
hl.bind(mainMod .. " + SHIFT + J",     hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/window_to_workspace.sh next"))

hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ monitor = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ monitor = "r" }))
hl.bind(mainMod .. " + CTRL + left",   hl.dsp.window.move({ monitor = "l" }))
hl.bind(mainMod .. " + CTRL + right",  hl.dsp.window.move({ monitor = "r" }))
hl.bind(mainMod .. " + SHIFT + H",     hl.dsp.window.move({ monitor = "l" }))
hl.bind(mainMod .. " + SHIFT + L",     hl.dsp.window.move({ monitor = "r" }))
hl.bind(mainMod .. " + CTRL + H",      hl.dsp.window.move({ monitor = "l" }))
hl.bind(mainMod .. " + CTRL + L",      hl.dsp.window.move({ monitor = "r" }))

-- MOUSE MOVE/RESIZE
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- WORKSPACES
for i = 1, 10 do
    local key = tostring(i % 10)  -- maps 10 → "0"
    hl.bind(mainMod .. " + " .. key,              hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,      hl.dsp.window.move({ workspace = i }))
end

-- MOUSE SCROLL WORKSPACES
hl.bind(mainMod .. " + mouse_down", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/workspace_switch.sh next"))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/workspace_switch.sh prev"))

-- SCREENSHOTS
hl.bind("Print",       hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/screenshot.sh region"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/screenshot.sh full"))

-- VOLUME & BRIGHTNESS
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("swayosd-client --output-volume raise"),  { repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("swayosd-client --output-volume lower"),  { repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"),  { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("swayosd-client --brightness raise"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), { repeating = true })

-- MEDIA KEYS
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),        { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),    { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
