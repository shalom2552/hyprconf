#!/usr/bin/env bash
set -e

HYPR_DIR="$HOME/.config/hypr"

# Ensure ~/.local/bin is on PATH (tools like zoxide, fnm, yazi land here)
export PATH="$HOME/.local/bin:$PATH"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

on_error() {
    echo -e "\n${RED}[ERROR]${NC} Setup failed at line $LINENO.\n"
    echo -e "  Try run setup manually:\n"
    echo -e "    cd ~/.config/hypr && ./setup.sh\n"
    exit 1
}
trap on_error ERR

# ---------------------------------------------------
# 1. Check git repo exist and update
# ---------------------------------------------------
if [ ! -d "$HYPR_DIR/.git" ]; then
    error "Expected hyprconf repo at $HYPR_DIR. Clone it first:\n  git clone https://github.com/shalom2552/hyprconf.git ~/.config/hypr"
fi

cd "$HYPR_DIR"
info "Pulling latest hyprconf..."
git pull --rebase || error "Pulling failed."

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

packages=(
    hyprland hyprlock hypridle
    swaync swayosd
    loupe
    playerctl
    grim slurp wl-clipboard
    network-manager-applet
    wlogout
    matugen
    stow
    xdg-desktop-portal-hyprland
    polkit-gnome
    adw-gtk-theme
    cliphist fzf
    imagemagick ffmpeg python jq
    thunar kitty
)

for pkg in "${packages[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        info "Installing $pkg..."
        sudo pacman -S --needed --noconfirm "$pkg" \
            || warn "Failed to install $pkg, skipping..."
    else
        info "$pkg already installed, skipping."
    fi
done

# ---------------------------------------------------
# 4. Install AUR packages
# ---------------------------------------------------
info "Installing AUR packages (yay)..."

aur_packages=(
    quickshell-git
    awww
    zen-browser-bin
)

for pkg in "${aur_packages[@]}"; do
    if ! yay -Q "$pkg" &>/dev/null; then
        info "Installing $pkg..."
        yay -S --needed --noconfirm --sudoloop "$pkg" \
            || warn "Failed to install $pkg, skipping..."
    else
        info "$pkg already installed, skipping."
    fi
done

# ---------------------------------------------------
# 5. Deploy extra configs (swayosd, mimeapps)
# ---------------------------------------------------
info "Deploying extra configs (swayosd, mimeapps)..."
stow --adopt -R --no-folding -t ~ -d "$HYPR_DIR" extra
git -C "$HYPR_DIR" checkout extra/

# ---------------------------------------------------
# 6. Wallpapers
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
# 7. GTK dark mode
# ---------------------------------------------------
info "Setting GTK dark mode..."
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" 2>/dev/null || true

# ---------------------------------------------------
# 8. Monitor layout (after all installs — safe to skip/timeout)
# ---------------------------------------------------
if [ ! -f "$HYPR_DIR/monitors.conf" ]; then
    echo ""
    info "No monitors.conf found. How many monitors do you have?"
    echo "  1) 1 monitor  (Laptop)"
    echo "  2) 2 monitors (Desktop)"
    MONITOR_CHOICE=""
    read -t 30 -rp "  Enter choice [1/2, default=1]: " MONITOR_CHOICE || true
    [ -z "$MONITOR_CHOICE" ] && info "No input — defaulting to 1-monitor (Laptop)."
    case "$MONITOR_CHOICE" in
        2)
            cp "$HYPR_DIR/monitors.conf.desktop" "$HYPR_DIR/monitors.conf"
            info "Copied 2-monitor (Desktop) config."
            ;;
        *)
            cp "$HYPR_DIR/monitors.conf.laptop" "$HYPR_DIR/monitors.conf"
            info "Copied 1-monitor (Laptop) config."
            ;;
    esac
    info "Edit monitors.conf to match your displays (run 'hyprctl monitors' to list them)."
else
    info "monitors.conf already exists, skipping."
fi

# ---------------------------------------------------
# 9. Local config
# ---------------------------------------------------
if [ ! -f "$HYPR_DIR/local.conf" ]; then
    info "Creating local.conf..."
    printf "# ~/.config/hypr/local.conf\n# Machine-specific config — not tracked in git.\n" \
        > "$HYPR_DIR/local.conf"
fi

# ---------------------------------------------------
# 10. Dotfiles setup
# ---------------------------------------------------
info "Hyprland setup complete!"
info "Running dotfiles setup..."
if [ -d "$HOME/dotfiles/.git" ]; then
    bash "$HOME/dotfiles/setup.sh"
else
    bash <(curl -fSsL https://raw.githubusercontent.com/shalom2552/dotfiles/main/install.sh)
fi

# ---------------------------------------------------
# Done
# ---------------------------------------------------
echo ""
info "Reload Hyprland config: hyprctl reload"
info "Or log out and back in to start fresh."
echo ""
