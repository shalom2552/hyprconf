# Hyprland Config Review — 2026-05-29
## Branch: `lua-migration` | Host: CachyOS (Arch) | Hyprland ≥ 0.55

---

## A. INVENTORY

### Live Lua Config (`~/.config/hypr/*.lua`)

| File | Purpose |
|------|---------|
| `hyprland.lua` | Entry point; 10 `require()` calls |
| `config.lua` | Shared program vars (terminal, fileManager, internetBrowser) |
| `env.lua` | `hl.env()` for Wayland/XDG environment |
| `autostart.lua` | `hl.on("hyprland.start")` block |
| `appearance.lua` | `hl.config()` for general, decoration, shadow, blur |
| `animations.lua` | `hl.curve()` + `hl.animation()` |
| `layouts.lua` | `hl.config()` for dwindle, master, misc |
| `input.lua` | `hl.config()` for kb/mouse/touchpad + `hl.gesture()` |
| `keybinds.lua` | All `hl.bind()` calls; requires config.lua |
| `window-rules.lua` | All `hl.window_rule()` calls |
| `monitors.lua` | Desktop dual-monitor config (**tracked in git — should not be**) |
| `monitors.lua.dual` | Template: HDMI-A-1 + DP-3 desktop |
| `monitors.lua.single` | Template: eDP-1 laptop |
| `machine.lua` | Empty machine-specific stub (**tracked in git — should not be**) |
| `.luarc.json` | lua_ls: stubs path + `hl` global declaration |

### Legacy Reference (`~/.config/hypr/legacy_conf/`)

All `.conf` files; **not loaded by Hyprland** — `hyprland.lua` is present so the `.conf` parser
never runs. These are reference only.

### Scripts (`scripts/`)

| File | Notes |
|------|-------|
| `smart_focus.sh` | `hyprctl` IPC; sophisticated jq window geometry logic |
| `workspace_switch.sh` | **Hardcodes desktop odd/even scheme** |
| `window_to_workspace.sh` | **Hardcodes desktop odd/even scheme** |
| `toggle_float.sh` | Toggles float, auto-resizes to 2/3 monitor |
| `get_monitor_offset.sh` | Writes primary monitor geometry to `/tmp/qs_monitor_offset` |
| `screenshot.sh` | grim + slurp → ~/Pictures/Screenshots |
| `set-wallpaper.sh` | **Hardcodes DP-3 + HDMI-A-1** — desktop only |
| `slideshow.sh` | Random wallpaper + matugen theming |
| `qs_manager.sh` | Quickshell wallpaper picker IPC — **binary name bug** |
| `popups/popup.sh` | Generic fzf popup wrapper (**not called by any keybind**) |
| `popups/launch.sh` | fzf app launcher (own outer guard) |
| `popups/alttab.sh` | fzf window switcher (own outer guard) |
| `popups/clip.sh`, `power.sh` | Clipboard, power menu (assumed similar structure) |
| `quickshell/matugen_reload.sh` | Reloads kitty, nvim, CAVA after matugen run |

### Ecosystem

| File | Status |
|------|--------|
| `/usr/share/hypr/hyprlock.conf` | **Sample only** — no user hyprlock.conf exists anywhere in `~/.config/` |
| `/usr/share/hypr/hypridle.conf` | **Sample only** — same |
| `hyprlock/colors.conf` | Catppuccin Mocha vars — **orphaned, nothing sources it** |
| `hyprlock/scripts/battery.sh`, `layout.sh` | **Orphaned** — no hyprlock.conf references them |
| `extra/.config/walker/` | Walker config — deployed via stow, **no keybind calls walker** |
| `extra/.config/swayosd/style.css` | SwayOSD theme — deployed via stow, active |

### Dotfiles Repo (`~/dotfiles/`)

Separate repo, stowed flat to `~` (`--target=~` in `.stowrc`). Manages: zsh, bash aliases,
Neovim (git submodule), kitty, tmux, yazi, btop, starship, fastfetch, dolphinrc, local bin
scripts, `.desktop` entries, icons. No overlap with hypr repo contents.

**Files not found / not applicable:** No `CLAUDE.md` (gitignored). `popups/clip.sh`,
`popups/power.sh` not read (not critical path).

---

## B. LIVE-CONFIG HEALTH

The live config is **Lua** — all `.conf` files are in `legacy_conf/` and are not loaded.

### B1. `keybinds.lua` — `Super + M` lock screen bind is missing [CRITICAL]

`legacy_conf/keybinds.conf` had:
```conf
bindel = $mainMod, M,    exec, hyprlock
```
No equivalent in `keybinds.lua`. The README documents `Super + M — Lock Screen`. The bind
doesn't exist right now. Fix (and correct the accidental `bindel` → `repeating` from the original):
```lua
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("hyprlock"))
```

### B2. Wrong comment headers in six Lua files [LOW]

| File | Wrong header |
|------|-------------|
| `autostart.lua` | `-- ~/.config/hypr/autostart.conf` |
| `appearance.lua` | `-- ~/.config/hypr/appearance.conf` |
| `env.lua` | `-- ~/.config/hypr/env.conf` |
| `input.lua` | `-- ~/.config/hypr/input.conf` |
| `layouts.lua` | `-- ~/.config/hypr/layouts.conf` |
| `machine.lua` | `-- ~/.config/hypr/local.conf` (wrong filename too) |

### B3. `monitors.lua` and `machine.lua` tracked in git [HIGH]

`git ls-files monitors.lua machine.lua` confirms both are committed. Both are machine-specific.
Current `monitors.lua` is the desktop dual-monitor config. On a laptop after `git clone`, Hyprland
starts with the Lua parser (because `hyprland.lua` exists), loads `monitors.lua`, and tries to
configure HDMI-A-1 + DP-3 on a display that has neither. Session will be degraded or broken.

Fix — add to `.gitignore` and untrack:
```
monitors.lua
machine.lua
```
```bash
git rm --cached monitors.lua machine.lua
```

### B4. `install.sh` doesn't provision Lua machine-specific files [HIGH]

Step 8 copies only `monitors.conf.{desktop,laptop}`, not `.lua` equivalents. Step 9 creates only
`local.conf`, not `machine.lua`. After full cutover, fresh install → Hyprland starts →
`require("machine")` fails (file not found) → startup error. Similarly `require("monitors")` once
`monitors.lua` is gitignored.

Required additions to `install.sh`:
```bash
# Step 8 — add alongside monitors.conf copy
case "$MONITOR_CHOICE" in
    2) cp "$HYPR_DIR/monitors.lua.dual"   "$HYPR_DIR/monitors.lua" ;;
    *) cp "$HYPR_DIR/monitors.lua.single" "$HYPR_DIR/monitors.lua" ;;
esac

# Step 8 — update existence check
if [ ! -f "$HYPR_DIR/monitors.conf" ] || [ ! -f "$HYPR_DIR/monitors.lua" ]; then

# Step 9 — add machine.lua creation
if [ ! -f "$HYPR_DIR/machine.lua" ]; then
    printf "-- ~/.config/hypr/machine.lua\n-- Machine-specific config.\n" \
        > "$HYPR_DIR/machine.lua"
fi
```

### B5. Monitor template naming inconsistency [LOW]

Legacy conf templates: `monitors.conf.desktop` / `monitors.conf.laptop`
Lua templates: `monitors.lua.dual` / `monitors.lua.single`

The `lua-migration.md` plan references `.desktop`/`.laptop` for the Lua templates — wrong names.
Pick one convention. Recommend renaming Lua templates to match:
- `monitors.lua.dual` → `monitors.lua.desktop`
- `monitors.lua.single` → `monitors.lua.laptop`

### B6. `set-wallpaper.sh` hardcodes desktop monitors [MEDIUM]

```bash
awww img --outputs DP-3 "$WALL"
awww img --outputs HDMI-A-1 "$WALL"
```

Fails silently on laptop (awww outputs warnings, no wallpaper set). Fix: query monitors
dynamically:
```bash
MONITORS=$(hyprctl monitors -j | jq -r '.[].name')
for MON in $MONITORS; do
    awww img --outputs "$MON" "$WALL"
done
```

### B7. `workspace_switch.sh` and `window_to_workspace.sh` hardcode dual-monitor scheme [MEDIUM]

Both scripts use:
```bash
(( CURRENT_WS % 2 == 1 )) && SET=(1 3 5 7) || SET=(2 4 6 8)
```

This is a desktop-only convention. On the laptop (single monitor, all 8 workspaces on eDP-1),
`Super + Shift + J/K` and mouse scroll will only cycle through odd or even workspaces depending on
which one you're on. Effectively, half the workspaces become unreachable via these binds.

Fix: detect whether the current workspace has a paired monitor. If only one monitor is active, use
`SET=(1 2 3 4 5 6 7 8)` unconditionally. Or pass the set as a parameter driven by `machine.lua`
via a file or env var.

### B8. Popup toggle race condition — `sleep 0.05` insufficient [HIGH]

Every popup script:
```bash
hyprctl dispatch killwindow "class:${existing}"
sleep 0.05   # Hyprland may not have processed kill yet
kitty --class "$WINDOW_CLASS" -e ...
```

50ms is often too short. Hyprland hasn't closed the window before the new kitty spawns. Both
windows exist simultaneously, both have `stay_focused = true` from the `fzf-popup-base` rule,
and they fight for focus. The old popup appears on top of the new one.

Fix: poll until the old window is gone before spawning:
```bash
hyprctl dispatch killwindow "class:${existing}"
timeout 1 bash -c \
    'until ! hyprctl clients -j 2>/dev/null | jq -e "[.[] | select(.class | startswith(\"fzf-popup\"))] | length == 0" > /dev/null; do sleep 0.02; done'
```
Or simpler: increase to `sleep 0.15` (less elegant but usually works).

Also: `popup.sh` exists as a generic wrapper but **no keybind calls it**. `launch.sh` and
`alttab.sh` each have their own duplicate guard logic. So fixing `popup.sh` alone doesn't help
those two.

### B9. `qs_manager.sh` — binary name mismatch [HIGH]

Line 4: `pgrep -x qs > /dev/null || { qs -p ... }`
Line 93: `quickshell -p "$QS_DIR/Main.qml"`

Two different binary names. `quickshell-git` from AUR installs as `qs`. The zombie watchdog on
line 93 uses `quickshell` which may not be in PATH. If quickshell dies and the watchdog tries to
restart it, it silently fails. Fix: use one name consistently:
```bash
QS_BIN=$(command -v qs || command -v quickshell)
```

Also: `qs_manager.sh` checks `pgrep -f "quickshell.*Main\.qml"` (line 90) but line 4 uses
`pgrep -x qs`. These two pgrep patterns don't match the same process name. If the binary is `qs`,
`pgrep -f "quickshell.*Main\.qml"` will never match → watchdog always thinks quickshell is dead →
kills and restarts on every `Super + W` press.

### B10. `hyprlock/colors.conf` and `hyprlock/scripts/` are orphaned [MEDIUM]

No `hyprlock.conf` exists in `~/.config/hypr/`. Hyprlock falls back to the sample at
`/usr/share/hypr/hyprlock.conf`, which does not source `hyprlock/colors.conf`. The Catppuccin
colors and the battery/layout scripts are never used.

Fix: create `~/.config/hypr/hyprlock.conf` and add it to the repo. The existing `colors.conf` and
scripts are already the right approach — just need the main file that sources them.

### B11. `hyprlock.conf` layout label uses wrong keyboard languages [LOW]

The sample `hyprlock.conf` (the one actually running) has:
```conf
text = $LAYOUT[en,ru]
```
Your keyboard layout in `input.lua` is `"us,il"` (English + Hebrew). The lock screen shows `en/ru`
not `en/il`. When you create a real `hyprlock.conf`, use `$LAYOUT[en,he]` or `$LAYOUT[en,il]`
depending on hyprlock's language naming.

### B12. `env.lua` sets XDG base directories redundantly [INFO]

```lua
hl.env("XDG_CONFIG_HOME", home .. "/.config")
hl.env("XDG_DATA_HOME",   home .. "/.local/share")
-- etc.
```

These are the XDG defaults. Setting them explicitly is harmless but redundant. Leave as-is if you
want them guaranteed for all Wayland clients.

### B13. Walker installed and configured but unbound [INFO]

`walker` is in the AUR package list. `extra/.config/walker/` is deployed via stow. No keybind in
`keybinds.lua` (or the legacy `.conf`) calls walker. `Super + D` goes to `launch.sh` (fzf).
Walker is dead weight unless you plan to switch to it. Either wire a bind or remove it from the
package list and stow package.

---

## C. LUA MIGRATION REVIEW

### Status

The migration is **live and complete in structure**. `hyprland.lua` is present, all 10 modules
exist, the `.conf` files are moved to `legacy_conf/`. Hyprland is running on Lua now. The
remaining gaps are correctness issues within the already-running Lua files, not incomplete
migration.

### Per-file review

**`hyprland.lua`** — Clean. 10 `require()` calls in a logical order. Does not itself
`require("config")` — that's handled by `keybinds.lua` directly, which is fine (Lua caches
modules). Minor: the migration plan showed `local _cfg = require("config")` at the top; the
actual file omits it. No functional difference.

**`config.lua`** — Correct. Returns a plain table. `keybinds.lua` does `local cfg =
require("config")` and uses `cfg.terminal` etc. Works as intended.

**`env.lua`** — Correct syntax. `hl.env(key, value)` with string values throughout. Uses
`os.getenv("HOME")` for XDG paths — correct Lua approach (`~` does NOT expand in Lua string
literals; only in shell). Wrong comment header (B2).

**`autostart.lua`** — Correct. `hl.on("hyprland.start", function() ... end)` is the right
pattern (confirmed by wiki autostart page). Compound shell commands (`pkill -x awww-daemon; sleep
0.1; awww-daemon`) work because `hl.exec_cmd` invokes a shell. No `exec` (re-run-on-reload)
equivalent is needed since the original used only `exec-once`. Wrong comment header (B2).

**`appearance.lua`** — Correct. Gradient syntax properly converted:
```conf
col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
```
→
```lua
col = { active_border = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 } }
```
Single colors stay as strings. Nested blocks (`shadow`, `blur`) become nested tables. Wrong
comment header (B2).

**`animations.lua`** — Correct. `hl.curve()` control-point format (two `{x,y}` pairs) is right.
`hl.animation()` fields (`leaf`, `enabled`, `speed`, `bezier`, `style`) match the API. All
animation nodes from the original are present.

**`layouts.lua`** — Correct. `dwindle`, `master`, `misc` in one `hl.config()` call. String values
properly quoted (`"master"` vs unquoted in hyprlang). Wrong comment header (B2).

**`input.lua`** — Correct. `tap-to-click` → `tap_to_click` (hyphen to underscore) is handled.
`hl.gesture({ fingers=3, direction="vertical", action="workspace" })` replaces the
`gesture = 3, vertical, workspace` hyprlang line. Wrong comment header (B2).

**`keybinds.lua`** — **Two confirmed issues, two to verify:**

1. `Super + M` → hyprlock **missing** (see B1). Regression.

2. Bind flag mapping looks correct: `bindel` → `{ repeating = true }`, `bindl` → `{ locked =
   true }`, `bindm` → `{ mouse = true }`. The original `bindel = $mainMod, M, exec, hyprlock`
   using a repeat-flag for a lock screen was an error; good that it's not present in Lua (but it's
   not present at all — needs to be added as a plain bind).

3. ⚠ **Verify:** `hl.dsp.window.fullscreen({ mode = 0 })` — the migration plan flagged this.
   The wiki dispatcher page for `fullscreen` shows mode 0 = real fullscreen, 1 = maximize. The
   Lua API may use `mode = 0` or may be `hl.dsp.window.maximize()` for mode 1. Test after next
   `Super + Z` press.

4. ⚠ **Verify:** `hl.dsp.layout("togglesplit")` — replacing `layoutmsg, togglesplit`. Test
   `Super + S` after restart.

5. Workspace loop is cleaner than the original 20 lines. `tostring(i % 10)` correctly maps 10 →
   `"0"` for workspace 10.

**`window-rules.lua`** — Correct. Match table keys (`class`, `title`, `xwayland`, `float`,
`fullscreen`, `pin`) are correct. `yes`/`on` → `true`, `no`/`off` → `false`. `opacity`, `size`,
`move` as strings (correct for `CLuaConfigString` / `CLuaConfigExpressionVec2`). `stay_focused`,
`dim_around`, `center`, `float`, `pin` as booleans. No issues.

**`monitors.lua`** — Correct syntax. `hl.monitor()` fields match the API. `transform = 1` is an
integer (correct). Workspace IDs as strings (`"1"` through `"8"`) correct. `default = true` as
boolean correct. But: **tracked in git** (B3), and the dual-monitor `monitors.lua.dual` template
is identical to `monitors.lua` — the template is redundant while `monitors.lua` is tracked.

**`machine.lua`** — Empty stub. Wrong comment header says `local.conf`. **Tracked in git** (B3).
Functionally fine (empty Lua file loads without error), wrong on principle.

---

## D. ECOSYSTEM IMPACT

| Tool | Config format | Changes needed for Lua cutover |
|------|--------------|-------------------------------|
| **Hyprland** | Lua (live now) | — |
| **hyprlock** | hyprlang (.conf) | None — separate parser, stays `.conf` forever |
| **hypridle** | hyprlang (.conf) | None — same |
| **swaync** | JSON/CSS | None |
| **swayosd** | CSS | None |
| **walker** | TOML | None |
| **kitty** | kitty.conf | None |
| **All scripts** | bash + `hyprctl` | None — `hyprctl` IPC socket survives the Lua migration |
| **quickshell / QML** | QML | None |

The wiki news post confirms: "Other hypr* tools continue using hyprlang because they are simple in
nature and work totally fine with a simple syntax, and do not need a turing-complete scripting
language." This is reflected in the current setup — hyprlock and hypridle remain `.conf`.

The hyprctl socket (`$HYPRLAND_INSTANCE_SIGNATURE`) is unaffected by the config format change.
All scripts that use `hyprctl dispatch`, `hyprctl clients -j`, `hyprctl monitors -j`, etc. continue
to work unchanged.

---

## E. STOW & REPO HYGIENE

### Repo structure

The hypr repo is cloned directly to `~/.config/hypr/` — it is **not** managed by stow. Stow is
used only for the `extra/` sub-package within the repo, deployed with:
```bash
stow --adopt -R --no-folding -t ~ -d "$HYPR_DIR" extra
```
This is correct and documented in `install.sh`. The `extra/` package deploys:
- `~/.config/swayosd/style.css`
- `~/.config/mimeapps.list`
- `~/.config/walker/config.toml` and themes

The dotfiles repo (`~/dotfiles/`) is entirely separate and covers non-Hyprland tools. No
conflicts or overlaps between the two repos.

### `.gitignore` gaps

Current `.gitignore`:
```
monitors.conf
local.conf
.claude/
CLAUDE.md
```

Missing:
```
monitors.lua     # machine-specific — will break laptop installs
machine.lua      # machine-specific — should not be committed
```

After adding those, also clean migration artifacts once stable:
```
legacy_conf/     # when .conf files are no longer needed as reference
```

### `install.sh` accuracy

The script correctly: clones the repo, installs packages, configures SDDM, deploys the stow
`extra/` package, clones wallpapers, sets GTK dark mode, creates `local.conf`, runs the dotfiles
installer. Gaps: doesn't provision `monitors.lua` or `machine.lua` (B4). The monitor config
section (Step 8) only checks for `monitors.conf`, not `monitors.lua`.

The `git pull --rebase` self-update path (`REEXECED=1`) is clean. The stow `--adopt` +
`git checkout extra/` pattern (adopt local files then reset to repo state) is correct.

### `README.md` accuracy

The README correctly describes all components and keybinds. Missing: no mention of Hyprland ≥ 0.55
requirement. After cutover this matters — a user on 0.54 would get `hyprland.lua` from the repo
but their Hyprland binary doesn't understand it.

Add to README:
```markdown
**Requires:** Hyprland ≥ 0.55 (Lua config)
```

---

## F. LSP / EDITOR

### `.luarc.json` — correct path, correct globals

```json
{
  "workspace.library": ["/usr/share/hypr/stubs"],
  "diagnostics.globals": ["hl"],
  "workspace.checkThirdParty": false
}
```

`/usr/share/hypr/stubs/hl.meta.lua` **exists** (confirmed via `find`). The path is correct.
`"hl"` declared as a global means no "undefined global" diagnostics on `hl.bind(...)` etc.

### lua_ls root detection

`~/.config/hypr/` is a git repo (`.git` present). When you open any `.lua` file under this
directory in Neovim, lua_ls detects the workspace root as `~/.config/hypr/` and loads
`.luarc.json` from there. This is the standard lua_ls discovery mechanism — no extra Neovim
config is needed.

### Neovim `lsp.lua` interaction

`lsp.lua` configures lua_ls with `diagnostics.globals = { "vim" }`. This is the server-level
fallback. When lua_ls opens files under `~/.config/hypr/`, the `.luarc.json` there takes
precedence for workspace-specific settings. The `"hl"` global and stubs path in `.luarc.json`
override/extend the server-level config for this workspace.

### neodev

`.neoconf.json` enables `neodev` which injects Neovim runtime type info into lua_ls. `neodev`
applies only when the file path is inside Neovim's runtime/config directories — it won't pollute
hypr Lua files with `vim.*` globals.

### What you actually get

When editing `keybinds.lua` in Neovim:
- `hl` recognized as a valid global (no red underline)
- `hl.bind`, `hl.dsp`, `hl.window_rule`, etc. get completions and type info from `hl.meta.lua`
- Lua syntax errors caught in real time

### One gap

`lsp.lua` sets `diagnostics.globals = { "vim" }` globally. If you ever open a hypr Lua file in a
Neovim session where `.luarc.json` isn't picked up (e.g., opening a single file without a project
root), `hl` will be flagged as undefined. Not blocking, but worth knowing.

---

## G. RISKS & GOTCHAS

### G1. All-or-nothing, `hyprctl reload` doesn't re-evaluate parser

`hyprland.lua` presence is checked once at Hyprland process start via a C++ `static` local
variable in `Jeremy.cpp`. `hyprctl reload` does NOT re-check which parser to use. Consequences:

| Situation | What happens |
|-----------|-------------|
| `hyprland.lua` has a syntax error at startup | Emergency mode: `Super+Q` opens terminal |
| Create `hyprland.lua`, run `hyprctl reload` | Nothing — still uses `.conf` until restart |
| `hyprland.lua` loads but no binds register | Emergency mode automatically |
| Remove `hyprland.lua`, run `hyprctl reload` | Still Lua — restart required to revert to `.conf` |

You are already past the point of no return on this machine — `hyprland.lua` is live. The `.conf`
files in `legacy_conf/` are not at the path Hyprland would look for (`~/.config/hypr/hyprland.conf`
at the root). If you need to roll back:
```bash
# From a TTY (Ctrl+Alt+F2)
mv ~/.config/hypr/hyprland.lua ~/.config/hypr/hyprland.lua.broken
cp ~/.config/hypr/legacy_conf/hyprland.conf ~/.config/hypr/hyprland.conf
# (also restore the sourced .conf files to root)
# restart Hyprland
```

### G2. `require("machine")` will fail on fresh laptop install until B4 is fixed

Until `install.sh` creates `machine.lua`, any fresh install exits with a Lua error on startup.
The `machine.lua` currently in git is the only reason this doesn't already break — but once B3
(gitignore) is fixed without also fixing B4 (install.sh), installs break.

**Fix B3 and B4 together, not separately.**

### G3. `monitors.lua` in git is a ticking bomb for laptop use

Same dependency as G2. Fix B3 + B4 atomically.

### G4. Popup race condition breaks UX now (B8)

The `sleep 0.05` in popup scripts is actively causing the "opens on top" behavior reported.
This existed in the `.conf` era too. It's the most user-visible bug right now.

### G5. `Super + W` quickshell likely broken by binary name mismatch (B9)

The `pgrep -x qs` / `pgrep -f "quickshell.*Main\.qml"` inconsistency means the watchdog always
sees quickshell as dead. Every `Super + W` press: kills the running instance, re-spawns it, then
opens the wallpaper picker. So it "works" once per press but with a 0.4s delay and QML state
resets. If the AUR package installs as `qs`, replace all occurrences of `quickshell` in the script
with `qs` and use a single consistent `pgrep -x qs` check.

### G6. `hl.exec_cmd` with compound shell commands

`hl.exec_cmd("pkill -x awww-daemon; sleep 0.1; awww-daemon")` relies on `hl.exec_cmd` invoking
a shell. The Hyprland source (`LuaEventHandler.cpp`) confirms it spawns via `fork`+`exec` of a
shell, so `;`-chained commands and `sleep` work. No action needed — document this in
`lua-migration.md` as verified.

---

## H. ORDERED ACTION LIST

### Immediate (things broken right now)

1. **Add `Super + M` → hyprlock to `keybinds.lua`**
   One line. Lock screen is completely unreachable. (B1)

2. **Fix popup race condition in all popup scripts**
   Replace `sleep 0.05` with a poll loop or increase to `sleep 0.15`. Apply to `launch.sh`,
   `alttab.sh`, `clip.sh`, `power.sh`. (B8)

3. **Fix `qs_manager.sh` binary name**
   Pick one (`qs` or `quickshell`), replace all occurrences, unify the pgrep patterns. (B9)

### Before next git push / laptop use

4. **Add `monitors.lua` and `machine.lua` to `.gitignore`, then `git rm --cached` both**
   Do before pushing. Otherwise any push overwrites the correct laptop config for anyone who
   clones. (B3)

5. **Update `install.sh` to provision `monitors.lua` and `machine.lua`**
   Must be done in the same commit as step 4 — fix B3 and B4 atomically. (B4)

### Soon

6. **Create `~/.config/hypr/hyprlock.conf` and add it to the repo**
   Source `hyprlock/colors.conf`. Add the battery/layout labels from `hyprlock/scripts/` if
   desired. Fix `$LAYOUT[en,ru]` → `$LAYOUT[en,he]`. (B10, B11)

7. **Fix `set-wallpaper.sh` to detect monitors dynamically**
   One loop over `hyprctl monitors -j`. (B6)

8. **Fix `workspace_switch.sh` and `window_to_workspace.sh` for single-monitor**
   Detect monitor count; use a flat workspace set on single-monitor. (B7)

9. **Normalize monitor template naming** — rename `monitors.lua.dual` / `monitors.lua.single` to
   `monitors.lua.desktop` / `monitors.lua.laptop` to match the legacy conf templates. Update
   `install.sh` accordingly. (B5)

### Cleanup (can wait)

10. **Fix comment headers** in `autostart.lua`, `appearance.lua`, `env.lua`, `input.lua`,
    `layouts.lua`, `machine.lua`. Six one-line changes. (B2)

11. **Add `Requires: Hyprland ≥ 0.55` to `README.md`**. (E)

12. **Verify `hl.dsp.window.fullscreen({mode=0})` and `hl.dsp.layout("togglesplit")`** after a
    clean restart — press `Super + Z` and `Super + S` and confirm behavior. (C, keybinds.lua)

13. **Decide on walker** — bind it or remove it from the package list and stow package. (B13)

14. **Consolidate popup guard logic** — move the outer duplicate-kill guard into `popup.sh` and
    have `launch.sh` / `alttab.sh` call it instead of re-implementing it. (B8 follow-up)

15. **Delete `legacy_conf/`** once the Lua config has survived one upgrade and one cold boot.
    Update `.gitignore` to remove the now-deleted `.conf` entries. (G1)

---

*Sources: direct file reads of all config files; https://hypr.land/news/26_lua/;
https://wiki.hypr.land/Configuring/; https://wiki.hypr.land/Configuring/Basics/Autostart/;
`/usr/share/hypr/stubs/hl.meta.lua` confirmed present; `lua-migration.md` (source-verified
migration plan).*
