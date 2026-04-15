#!/usr/bin/env bash
set -e

HYPR_DIR="$HOME/.config/hypr"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

on_error() {
    error "Setup failed at line $LINENO."
    info "Try running the script again:"
    echo ""
    echo "    cd ~/.config/hypr && ./setup.sh"
    echo ""
}
trap on_error ERR

# ---------------------------------------------------
# 1. Check we're in the right place
# ---------------------------------------------------
if [ ! -d "$HYPR_DIR/.git" ]; then
    error "Expected hyprconf repo at $HYPR_DIR. Clone it first:\n  git clone https://github.com/shalom2552/hyprconf.git ~/.config/hypr"
fi

cd "$HYPR_DIR"

# ---------------------------------------------------
# 2. Install yay if not present
# ---------------------------------------------------
if ! command -v yay &>/dev/null; then
    info "Installing yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm git base-devel
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    cd "$tmpdir/yay"
    makepkg -si --noconfirm
    cd "$HYPR_DIR"
    rm -rf "$tmpdir"
fi

# ---------------------------------------------------
# 3. Install packages (pacman)
# ---------------------------------------------------
info "Installing Hyprland packages (pacman)..."
sudo pacman -S --needed --noconfirm \
    hyprland hyprlock hypridle \
    swaync swayosd \
    loupe \
    playerctl \
    grim slurp wl-clipboard \
    network-manager-applet \
    wlogout \
    matugen \
    stow \
    xdg-desktop-portal-hyprland \
    polkit-gnome \
    adw-gtk-theme \
    imagemagick ffmpeg python jq \
    dolphin

# ---------------------------------------------------
# 4. Install AUR packages
# ---------------------------------------------------
info "Installing AUR packages (yay)..."
yay -S --needed --noconfirm --sudoloop \
    quickshell-git \
    walker-bin \
    elephant-bin \
    awww

# ---------------------------------------------------
# 5. Deploy extra configs (swayosd, mimeapps)
# ---------------------------------------------------
info "Deploying extra configs (swayosd, mimeapps)..."
for f in $(find "$HYPR_DIR/extra" -type f | sed "s|$HYPR_DIR/extra/||"); do
    target="$HOME/$f"
    [ -f "$target" ] && [ ! -L "$target" ] && rm "$target"
done
stow -R -t ~ -d "$HYPR_DIR" extra

# ---------------------------------------------------
# 6. Monitor layout
# ---------------------------------------------------
if [ ! -f "$HYPR_DIR/monitors.conf" ]; then
    echo ""
    info "No monitors.conf found. Choose your machine type:"
    echo "  1) Desktop"
    echo "  2) Laptop"
    read -rp "  Enter choice [1/2]: " MONITOR_CHOICE
    case "$MONITOR_CHOICE" in
        1)
            cp "$HYPR_DIR/monitors.conf.desktop" "$HYPR_DIR/monitors.conf"
            info "Copied desktop monitor config."
            ;;
        2)
            cp "$HYPR_DIR/monitors.conf.laptop" "$HYPR_DIR/monitors.conf"
            info "Copied laptop monitor config."
            ;;
        *)
            warn "Invalid choice. Skipping — create monitors.conf manually."
            warn "Templates: monitors.conf.desktop, monitors.conf.laptop"
            ;;
    esac
    if [ -f "$HYPR_DIR/monitors.conf" ]; then
        info "Edit monitors.conf to match your displays (run 'hyprctl monitors' to list them)."
    fi
else
    info "monitors.conf already exists, skipping."
fi

# ---------------------------------------------------
# 7. Wallpapers
# ---------------------------------------------------
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
if [ ! -d "$WALLPAPER_DIR/.git" ]; then
    info "Cloning wallpapers..."
    mkdir -p "$HOME/Pictures"
    git clone https://github.com/shalom2552/wallpapers-bank.git "$WALLPAPER_DIR"
else
    info "Wallpapers already cloned, pulling latest..."
    cd "$WALLPAPER_DIR"
    git pull
    cd "$HYPR_DIR"
fi

# ---------------------------------------------------
# 8. GTK dark mode
# ---------------------------------------------------
info "Setting GTK dark mode..."
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" 2>/dev/null || true

# ---------------------------------------------------
# Done
# ---------------------------------------------------
echo ""
info "Hyprland setup complete!"
info "Reload Hyprland config: hyprctl reload"
info "Or log out and back in to start fresh."
echo ""
