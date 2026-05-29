# Hyprland .conf → .lua Migration Plan

> Reference: Hyprland ≥ 0.55. Verified against source:
> `src/config/supplementary/jeremy/Jeremy.cpp`,
> `src/config/lua/bindings/LuaBindings*.cpp`,
> `src/config/lua/LuaEventHandler.cpp`,
> `example/hyprland.lua`.

---

## 1. Inventory

### Files needing Lua equivalents

| Current file           | Lua target            | Machine-specific? | Gitignored? | Notes |
|------------------------|-----------------------|:-----------------:|:-----------:|-------|
| `hyprland.conf`        | `hyprland.lua`        | No  | No  | Main entry; `source` → `require` |
| `env.conf`             | `env.lua`             | No  | No  | |
| `autostart.conf`       | `autostart.lua`       | No  | No  | |
| `appearance.conf`      | `appearance.lua`      | No  | No  | |
| `animations.conf`      | `animations.lua`      | No  | No  | |
| `layouts.conf`         | `layouts.lua`         | No  | No  | |
| `input.conf`           | `input.lua`           | No  | No  | |
| `keybinds.conf`        | `keybinds.lua`        | No  | No  | |
| `window-rules.conf`    | `window-rules.lua`    | No  | No  | |
| `monitors.conf`        | `monitors.lua`        | Yes | Yes | Created at install time from template |
| `monitors.conf.desktop`| `monitors.lua.desktop`| Yes | No  | Template kept in git |
| `monitors.conf.laptop` | `monitors.lua.laptop` | Yes | No  | Template kept in git |
| `local.conf`           | `machine.lua`         | Yes | Yes | Renamed — `local` is a Lua reserved word |

### Files NOT migrating

- `hyprlock.conf`, `hypridle.conf` — separate tools with independent hyprlang parsers
- `scripts/*.sh`, `hyprlock/scripts/*.sh` — shell scripts, unchanged
- `extra/` — stow package for non-hypr configs, unaffected

---

## 2. Conversion notes per file

### `hyprland.conf` → `hyprland.lua`

```conf
$terminal = kitty
source = ~/.config/hypr/env.conf
```
```lua
local cfg = require("config")   -- NEW: shared vars module

require("env")
require("autostart")
require("appearance")
require("animations")
require("layouts")
require("input")
require("keybinds")
require("monitors")
require("window-rules")         -- hyphen in name is valid
require("machine")              -- was local.conf; "local" is a reserved keyword
```

**Scope issue:** `$terminal` / `$fileManager` / `$internetBrowser` are hyprlang globals visible
across all sourced files. In Lua, `require()` modules have isolated scope. **Fix:** create a
`config.lua` module that returns a table:

```lua
-- config.lua
return {
    terminal        = "kitty",
    fileManager     = "thunar",
    internetBrowser = "zen-browser",
}
```

Then in `keybinds.lua`: `local cfg = require("config")` and use `cfg.terminal`.

`require()` path (source-verified): `~/.config/hypr/?.lua` and `~/.config/hypr/?/init.lua`.

---

### `env.conf` → `env.lua`

Straightforward 1:1:

```conf
env = XCURSOR_SIZE,24
```
```lua
hl.env("XCURSOR_SIZE", "24")
```

Second argument must be a string. No unknowns.

---

### `autostart.conf` → `autostart.lua`

No `exec-once` keyword in Lua. All startup commands go inside a single `hl.on` handler:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("pkill -x awww-daemon; sleep 0.1; awww-daemon")
    hl.exec_cmd("bash ~/.config/hypr/scripts/set-wallpaper.sh")
    hl.exec_cmd("swaync")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme \"prefer-dark\"")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme \"adw-gtk3-dark\"")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("swayosd-server")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("bash ~/.config/hypr/scripts/get_monitor_offset.sh")
end)
```

There is no `exec` (re-run on reload) equivalent in 0.55. Current `.conf` uses only `exec-once`,
so no behavior is lost.

> **Verify:** `hl.exec_cmd` spawns via shell, so compound commands (`sleep 0.1`, `;`) work.
> Test each command individually after cutover.

---

### `appearance.conf` → `appearance.lua`

Config blocks → `hl.config({})` tables. **Gradient syntax is the main change:**

```conf
col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
```
```lua
col = {
    active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
    inactive_border = "rgba(595959aa)",
},
```

Single-color values stay as strings. Multi-color gradients use `{ colors = {...}, angle = N }`.

Nested blocks (`shadow {}`, `blur {}`) become nested tables:

```lua
hl.config({
    general = {
        gaps_in = 5, gaps_out = 10, border_size = 1,
        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },
    decoration = {
        rounding = 10, rounding_power = 2,
        active_opacity = 1.0, inactive_opacity = 1.0,
        shadow = { enabled = true, range = 30, render_power = 3, color = "rgba(1a1a1aee)" },
        blur   = { enabled = true, size = 9, passes = 3, vibrancy = 0.1696 },
    },
})
```

No unknowns.

---

### `animations.conf` → `animations.lua`

**Bezier curves:**

```conf
bezier = easeOutQuint, 0.23, 1, 0.32, 1
```
```lua
hl.curve("easeOutQuint", { type = "bezier", points = {{0.23, 1}, {0.32, 1}} })
```

`points` takes exactly 2 control points `{x, y}`. Order matches hyperlang's `X0 Y0 X1 Y1`.

**Animations:**

```conf
animation = windowsIn, 1, 4.1, easeOutQuint, popin 87%
animation = workspaces, 1, 3, easeOutQuint, slidevert
```
```lua
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3,   bezier = "easeOutQuint", style = "slidevert" })
```

- `enabled = yes` → `enabled = true`; `0` → `false`
- `style` is an optional string: `"popin 87%"`, `"fade"`, `"slidevert"`, etc.
- Use `bezier =` for bezier curves or `spring =` for spring curves

No unknowns.

---

### `layouts.conf` → `layouts.lua`

```lua
hl.config({
    dwindle = { preserve_split = true },
    master  = { new_status = "master" },
    misc    = { force_default_wallpaper = -1, disable_hyprland_logo = false },
})
```

String values in hyperlang (`new_status = master`) become Lua strings (`"master"`). No unknowns.

---

### `input.conf` → `input.lua`

```lua
hl.config({
    input = {
        kb_layout          = "us,il",
        kb_variant         = "",
        kb_model           = "",
        kb_options         = "caps:escape, grp:win_space_toggle",
        kb_rules           = "",
        follow_mouse       = 1,
        repeat_rate        = 50,
        repeat_delay       = 250,
        numlock_by_default = true,
        sensitivity        = 0,
        natural_scroll     = true,
        touchpad = {
            natural_scroll = true,
            tap_to_click   = true,  -- was tap-to-click (hyphen → underscore)
        },
    },
})

hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })
```

> **Minor:** `tap-to-click` (hyphen) → `tap_to_click` (underscore). Confirmed in device field
> descriptor list.

---

### `keybinds.conf` → `keybinds.lua`

Largest behavioral change.

**`$mainMod`:**
```lua
local mainMod = "SUPER"
```

**Bind type → options table:**

| `.conf` keyword | Lua `opts` argument    |
|-----------------|------------------------|
| `bind`          | *(omit)*               |
| `bindel`        | `{ repeating = true }` |
| `bindl`         | `{ locked = true }`    |
| `bindm`         | `{ mouse = true }`     |

**Key string format:** `"SUPER + RETURN"`, `"SUPER + SHIFT + 1"`, `"ALT + TAB"`. Modifiers first,
space around `+`.

**Dispatcher mappings:**

| `.conf` dispatcher          | Lua equivalent                                         |
|-----------------------------|--------------------------------------------------------|
| `exec, cmd`                 | `hl.dsp.exec_cmd("cmd")`                               |
| `killactive`                | `hl.dsp.window.close()`                                |
| `movefocus, l/r/u/d`        | `hl.dsp.focus({ direction = "left/right/up/down" })`   |
| `workspace, N`              | `hl.dsp.focus({ workspace = N })`                      |
| `movetoworkspace, N`        | `hl.dsp.window.move({ workspace = N })`                |
| `fullscreen, 0`             | `hl.dsp.window.fullscreen()` ⚠ verify mode arg         |
| `togglefloating`            | `hl.dsp.window.float({ action = "toggle" })`           |
| `layoutmsg, togglesplit`    | `hl.dsp.layout("togglesplit")`                         |
| `movewindow, mon:l`         | `hl.dsp.window.move({ monitor = "l" })` ⚠ verify       |
| `movewindow, mon:r`         | `hl.dsp.window.move({ monitor = "r" })` ⚠ verify       |
| mouse drag (`bindm`)        | `hl.dsp.window.drag()`                                 |
| mouse resize (`bindm`)      | `hl.dsp.window.resize()`                               |

> ⚠ **Verify before writing:**
> 1. `movewindow, mon:l/r` — exact Lua form for move-to-monitor direction.
>    Check `src/config/lua/bindings/LuaBindingsDispatchers.cpp` or wiki dispatcher page.
> 2. `fullscreen, 0` — does `hl.dsp.window.fullscreen()` accept a mode integer (0=full, 1=max)?
>    Or is it `hl.dsp.window.maximize()`?

**Workspace loop — 20 repetitive lines collapse to 4:**

```lua
for i = 1, 10 do
    local key = i % 10  -- maps 10 → key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
```

**Mouse scroll workspaces:**
```conf
bind = $mainMod, mouse_down, exec, bash ~/.config/hypr/scripts/workspace_switch.sh next
bind = $mainMod, mouse_up,   exec, bash ~/.config/hypr/scripts/workspace_switch.sh prev
```
```lua
hl.bind(mainMod .. " + mouse_down", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/workspace_switch.sh next"))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/workspace_switch.sh prev"))
```

> ⚠ **Review:** `bindel = $mainMod, M, exec, hyprlock` uses `bindel` (repeat-enabled) for lock
> screen. Holding Super+M would spam hyprlock invocations. Likely unintentional — use plain
> `hl.bind(...)` with no opts.

---

### `window-rules.conf` → `window-rules.lua`

```conf
windowrule {
    name = fzf-popup-base
    match:class = ^(fzf-popup-.*)$
    float = yes
    stay_focused = on
    dim_around = on
    pin = yes
}
```
```lua
hl.window_rule({
    name  = "fzf-popup-base",
    match = { class = "^(fzf-popup-.*)$" },
    float        = true,
    stay_focused = true,
    dim_around   = true,
    pin          = true,
})
```

**match key mapping:**

| `.conf`                    | Lua `match = { ... }`                         |
|----------------------------|-----------------------------------------------|
| `match:class = ^...$`      | `class = "^...$"`                             |
| `match:title = ^...$`      | `title = "^...$"`                             |
| `match:xwayland = true`    | `xwayland = true`                             |
| `match:float = true/false` | `float = true/false`                          |
| `match:fullscreen = false` | `fullscreen = false`                          |
| `match:pin = false`        | `pin = false`                                 |

**Effect value changes:**

| `.conf`              | Lua                                              |
|----------------------|--------------------------------------------------|
| `yes` / `on`         | `true`                                           |
| `no` / `off`         | `false`                                          |
| `opacity = 1.0 1.0`  | `opacity = "1.0 1.0"` (string, active/inactive)  |
| `size = 500 500`     | `size = "500 500"` (string expression)           |
| `move = 20 monitor_h-120` | `move = "20 monitor_h-120"` (unchanged)     |
| `center = yes`       | `center = true`                                  |

`opacity` uses `CLuaConfigString` internally — the existing space-separated `"active inactive"`
format is preserved. `size` uses `CLuaConfigExpressionVec2` which accepts string expressions;
use string form to match `move` pattern.

---

### `monitors.conf` / `monitors.conf.{desktop,laptop}` → `monitors.lua.*`

```conf
monitor = HDMI-A-1, 1920x1080, 0x0, 1, transform, 1
workspace = 1, monitor:HDMI-A-1, default:true
```
```lua
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080", position = "0x0", scale = 1, transform = 1 })
hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true })
```

- `transform` is integer 0–7 (verified: `CLuaConfigInt(0, 0, 7)`)
- `default:true` → `default = true` (boolean)
- Workspace identifiers are strings: `"1"` through `"8"`
- Monitor name in workspace rule is just the output name string, no `monitor:` prefix

**Laptop template (`monitors.conf.laptop`):**
```lua
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })
for i = 1, 8 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "eDP-1", default = (i == 1) })
end
```

No unknowns.

---

### `local.conf` → `machine.lua`

```conf
# Machine-specific config — not tracked in git.
```
```lua
-- Machine-specific config — not tracked in git.
```

Renamed from `local` because `require("local")` is a syntax error in Lua (`local` is reserved).
Update `require("machine")` in `hyprland.lua` and the creation command in `install.sh`.

---

## 3. Structure

```
~/.config/hypr/
├── hyprland.lua              ← main entry (was hyprland.conf)
├── config.lua                ← NEW: shared vars (terminal, fileManager, etc.)
├── env.lua
├── autostart.lua
├── appearance.lua
├── animations.lua
├── layouts.lua
├── input.lua
├── keybinds.lua
├── window-rules.lua
├── monitors.lua              ← gitignored, machine-specific
├── monitors.lua.desktop      ← in git (template)
├── monitors.lua.laptop       ← in git (template)
├── machine.lua               ← gitignored, machine-specific
│
│   (keep all .conf files until migration is stable — rollback reference)
│
├── scripts/                  ← unchanged
├── hyprlock/                 ← unchanged
├── hypridle.conf             ← unchanged (not Hyprland's parser)
├── hyprlock.conf             ← unchanged (not Hyprland's parser)
└── extra/                    ← unchanged (stow package)
```

**`hyprland.lua` entry point:**
```lua
local _cfg = require("config")  -- loads shared vars; modules require("config") themselves

require("env")
require("autostart")
require("appearance")
require("animations")
require("layouts")
require("input")
require("keybinds")
require("monitors")
require("window-rules")
require("machine")
```

**Simplifications over `.conf`:**
1. Workspace bind loops: 20 lines → 4-line `for` loop
2. Shared variables via module — no global `$` var leakage
3. Runtime logic possible: `os.getenv("HOSTNAME")` for conditional monitor config
4. `~` in `hl.exec_cmd` strings expands correctly (shell handles it); but `~` inside Lua string
   literals (e.g. paths passed to Lua functions) does NOT expand — use `os.getenv("HOME")`

---

## 4. Cutover risks

### All-or-nothing loading

Source-verified in `src/config/supplementary/jeremy/Jeremy.cpp`:

```cpp
const auto LUA_PATHS  = findConfig("hyprland", "lua");   // → ~/.config/hypr/hyprland.lua
const auto CONF_PATHS = findConfig("hyprland", "conf");  // → ~/.config/hypr/hyprland.conf

if (LUA_PATHS.first.has_value())
    return { path = hyprland.lua };   // Lua wins unconditionally
else if (CONF_PATHS.first.has_value())
    return { path = hyprland.conf };  // fallback only if no .lua
```

The result is stored in a **C++ `static` local variable** — initialized once at Hyprland process
start, only re-evaluated on safe-mode changes. `hyprctl reload` does **not** re-run this check.

| Action | Effect |
|--------|--------|
| Create `hyprland.lua`, run `hyprctl reload` | No change — still reads `.conf` until restart |
| Start Hyprland with `hyprland.lua` present | Lua parser; `.conf` never touched |
| Remove `hyprland.lua`, run `hyprctl reload` | Still Lua — restart required to revert |
| `hyprland.lua` has a syntax error at startup | Emergency mode: `SUPER+Q` → terminal |

### Staging — where to work

`findConfig` resolves to `$XDG_CONFIG_HOME/hypr/hyprland.lua` = `~/.config/hypr/hyprland.lua`.

| Path | Safe? |
|------|-------|
| `~/hypr-lua-wip/hyprland.lua` | ✅ outside XDG scope |
| `~/.config/hypr/lua-staging/hyprland.lua` | ✅ wrong directory |
| `~/.config/hypr/hyprland.lua.wip` | ✅ wrong extension |
| `~/.config/hypr/hyprland.lua` | ❌ picked up immediately on next start |

Work entirely in staging. Copy all `.lua` files to `~/.config/hypr/` in one step, then restart.

---

## 5. Stow impact

The git repo is cloned directly to `~/.config/hypr/`. Hypr config files are **not** stow-managed
— they live at the correct location in the repo. Stow is used only for the `extra/` subdirectory:

```bash
stow --adopt -R --no-folding -t ~ -d ~/.config/hypr extra
```

This deploys `extra/.config/swayosd/`, `extra/.config/mimeapps.list`, `extra/.config/walker/`
into `~/.config/`. The Lua migration does not affect any of this.

**What changes:**
- Add `.lua` files directly to `~/.config/hypr/` (same as `.conf` files now)
- No re-stow needed for hypr configs
- Update `.gitignore` (see section 6)
- If staging inside the repo at `lua-staging/`, add `lua-staging/` to `.gitignore`

---

## 6. Supporting files

### `.gitignore`

Add:
```
monitors.lua
machine.lua
lua-staging/
```

After full migration, remove:
```
monitors.conf   ← remove after deleting .conf from repo
local.conf      ← remove after deleting .conf from repo
```

### `install.sh`

**Step 8 (monitor config)** — add parallel `.lua` copy:
```bash
case "$MONITOR_CHOICE" in
    2)
        cp "$HYPR_DIR/monitors.conf.desktop" "$HYPR_DIR/monitors.conf"
        cp "$HYPR_DIR/monitors.lua.desktop"  "$HYPR_DIR/monitors.lua"   # ADD
        ;;
    *)
        cp "$HYPR_DIR/monitors.conf.laptop" "$HYPR_DIR/monitors.conf"
        cp "$HYPR_DIR/monitors.lua.laptop"  "$HYPR_DIR/monitors.lua"    # ADD
        ;;
esac
```

**Step 9 (local config)** — also create `machine.lua`:
```bash
if [ ! -f "$HYPR_DIR/machine.lua" ]; then
    printf "-- Machine-specific config — not tracked in git.\n" \
        > "$HYPR_DIR/machine.lua"
fi
```

**Step 8 existence check** — mirror the `monitors.conf` check for `monitors.lua`:
```bash
if [ ! -f "$HYPR_DIR/monitors.conf" ] || [ ! -f "$HYPR_DIR/monitors.lua" ]; then
```

### `README.md`

- Add: Hyprland ≥ 0.55 required (Lua config)
- Update config file references from `.conf` to `.lua`

---

## 7. Migration order & rollback

### Order (lowest risk first)

All work in staging. `.conf` files untouched throughout.

**Phase 1 — Pure config blocks**
1. `env.lua` — 1:1 `hl.env()` calls
2. `layouts.lua` — three simple option tables
3. `appearance.lua` — option tables + gradient color syntax

**Phase 2 — Config with mild API surface**
4. `animations.lua` — `hl.curve()` + `hl.animation()` API
5. `input.lua` — option table + one `hl.gesture()`

**Phase 3 — Rules**
6. `window-rules.lua` — verify `opacity`/`size` string format at this step

**Phase 4 — Behavior**
7. `autostart.lua` — `hl.on("hyprland.start")` pattern; test each command
8. `keybinds.lua` — **resolve the two uncertain dispatchers first** (`movewindow mon:l/r`,
   `fullscreen 0`) by checking `LuaBindingsDispatchers.cpp` or the 0.55 wiki dispatcher page

**Phase 5 — Machine-specific**
9. `monitors.lua.desktop` + `monitors.lua.laptop` — test per machine

**Phase 6 — Wiring**
10. `config.lua` — shared variables module
11. `machine.lua` — empty stub
12. `hyprland.lua` — entry point with all `require()` calls

### Cutover

```bash
cp ~/hypr-lua-wip/*.lua ~/.config/hypr/
# verify the main file is in place
ls -la ~/.config/hypr/hyprland.lua
# full restart — not just reload
```

Verify after restart: `hyprctl version`, `hyprctl monitors`, test all keybinds, test popups.

### Rollback

**During broken session (TTY):**
```bash
# Ctrl+Alt+F2
mv ~/.config/hypr/hyprland.lua ~/.config/hypr/hyprland.lua.broken
# restart Hyprland — finds hyprland.conf
```

**During development:** Nothing to roll back — staging is separate, `.conf` untouched.

**Rule:** Do not delete any `.conf` file until the Lua config has survived at least one Hyprland
upgrade and one cold boot.

**Emergency mode:** If `hyprland.lua` loads but registers no binds, Hyprland activates emergency
mode automatically. `SUPER+Q` opens a known terminal. From there: edit the file, `hyprctl reload`.
