# Hyprconf

My personal Hyprland desktop configuration for Arch Linux. This repo lives directly at `~/.config/hypr/`.

> **Shell, terminal, and tool configs** (Zsh, Kitty, tmux, yazi, btop, etc.) are maintained in a [separate repository](https://github.com/shalom2552/dotfiles).

## Tracked Configurations

* **WM:** Hyprland
* **App Launcher:** Walker
* **Notifications:** SwayNC
* **Lock Screen:** Hyprlock
* **Idle Daemon:** Hypridle
* **OSD:** SwayOSD
* **Wallpaper:** awww + Matugen (dynamic color theming)
* **Extras:** mimeapps.list (default applications)

## Quick Install

```bash
[ -d ~/.config/hypr ] && mv ~/.config/hypr ~/.config/hypr.bak
git clone https://github.com/shalom2552/hyprconf.git ~/.config/hypr
cd ~/.config/hypr
chmod +x setup.sh
./setup.sh
```

> The script installs all dependencies (pacman + AUR), deploys extra configs, sets up wallpapers, and configures monitors interactively.

## Manual Installation

### 1. Dependencies

```bash
sudo pacman -S --needed --noconfirm \
    hyprland hyprlock hypridle \
    swaync swayosd loupe \
    playerctl grim slurp wl-clipboard \
    network-manager-applet \
    wlogout matugen stow \
    xdg-desktop-portal-hyprland \
    polkit-gnome adw-gtk-theme \
    imagemagick ffmpeg python jq \
    dolphin
```

```bash
# AUR packages (using yay)
yay -S --needed quickshell-git walker-bin elephant-all-bin awww
```

### 2. Clone

Back up any existing Hyprland config, then clone directly into `~/.config/hypr/`:

```bash
[ -d ~/.config/hypr ] && mv ~/.config/hypr ~/.config/hypr.bak
git clone https://github.com/shalom2552/hyprconf.git ~/.config/hypr
```

### 3. Deploy Extra Configs

SwayOSD and mimeapps.list live outside `~/.config/hypr/`, so they're deployed via Stow:

```bash
cd ~/.config/hypr
stow -t ~ extra
```
> If stow reports conflicts, remove or backup the existing files first.

### 4. Monitor Layout

Copy the appropriate monitor template for your machine:

```bash
# Desktop
cp ~/.config/hypr/monitors.conf.desktop ~/.config/hypr/monitors.conf

# Laptop
cp ~/.config/hypr/monitors.conf.laptop ~/.config/hypr/monitors.conf
```

Then edit `monitors.conf` to match your actual monitor names (`hyprctl monitors` to list them).

### 5. Wallpapers

```bash
git clone https://github.com/shalom2552/wallpapers-bank.git ~/Pictures/wallpapers
```

Supported formats: jpg, jpeg, png.

## Usage

Since the repo is the config directory itself, just edit and commit:

```bash
cd ~/.config/hypr
nvim keybinds.conf

git add keybinds.conf
git commit -m "update keybinds"
git push
```
