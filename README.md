# Hyprconf

A personal Hyprland configuration for Arch Linux. Minimal, keyboard-driven and terminal-first.

> **Shell and tool configs** are maintained in a [separate repository](https://github.com/shalom2552/dotfiles).

| Main Desktop |
| :---: |
| <img width="700" alt="desktop" src="https://github.com/user-attachments/assets/227a7f76-486b-48dc-a8d1-e4ba06ff8a0f" /> |


## Tracked Configurations

* **WM:** Hyprland
* **Notifications:** SwayNC
* **Lock Screen:** Hyprlock
* **Idle Daemon:** Hypridle
* **OSD:** SwayOSD
* **Wallpaper:** awww + Quickshell (QML)
* **Extras:** mimeapps.list (default applications)

## Quick Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/shalom2552/hyprconf/main/install.sh)
```

> Installs all dependencies (pacman + AUR), deploys extra configs, sets up wallpapers, and configures monitors interactively.

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
    dolphin kitty
```

```bash
# AUR packages (using yay)
yay -S --needed quickshell-git walker-bin \
    elephant-bin elephant-clipboard-bin elephant-windows-bin \
    elephant-desktopapplications-bin elephant-providerlist-bin \
    awww
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

## Credits

* **Wallpaper Picker** — inspired by [ilyamiro/nixos-configuration](https://github.com/ilyamiro/nixos-configuration)
 
 
