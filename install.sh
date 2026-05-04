#!/usr/bin/env bash
set -e

HYPR_DIR="$HOME/.config/hypr"
VERSION="1.4.3"
SDDM_THEME="catppuccin-mocha-blue"
SDDM_THEME_PKG="sddm-theme-catppuccin"

# Ensure ~/.local/bin is on PATH (tools like zoxide, fnm, yazi land here)
export PATH="$HOME/.local/bin:$PATH"

# ---------------------------------------------------
# Helpers
# ---------------------------------------------------
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

on_error() {
    echo -e "\n${RED}[ERROR]${NC} Setup failed at line $LINENO.\n"
    echo -e "  Try run setup manually:\n"
    echo -e "    cd ~/.config/hypr && ./install.sh\n"
    exit 1
}
trap on_error ERR

# ---------------------------------------------------
# Welcome
# ---------------------------------------------------
if [ "${REEXECED:-0}" != "1" ]; then
echo -e "${CYAN}"
echo "  ██╗  ██╗██╗   ██╗██████╗ ██████╗ "
echo "  ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗"
echo "  ███████║ ╚████╔╝ ██████╔╝██████╔╝"
echo "  ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗"
echo "  ██║  ██║   ██║   ██║     ██║  ██║"
echo "  ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝"
echo -e "${NC}"
echo -e "  ${BOLD}Shalom's Hyprland Config${NC}  ${CYAN}v${VERSION}${NC}"
echo -e "  ${CYAN}github.com/shalom2552/hyprconf${NC}"
echo ""
echo -e "  Installing to: ${GREEN}$HYPR_DIR${NC}"
echo -e "  Requires:      ${GREEN}Arch-based${NC}"
echo -e "  Est. time:     ${GREEN}~5-10 min${NC}"
echo ""
echo -e "  ${BOLD}── What's included ──${NC}"
echo "    • Hyprland, Hyprlock, Hypridle"
echo "    • SwayNC, SwayOSD"
echo "    • Bluetooth + audio (pipewire, bluez)"
echo "    • Wallpapers + Matugen theming"
echo "    • Quickshell wallpaper picker (QML)"
echo "    • fzf popups: launcher, power, clipboard"
echo "    • Monitor layout selection"
echo ""
read -r -p "  Proceed? [n/Y] " confirm
echo ""
if [[ "$confirm" =~ ^[Nn]$ ]]; then
    echo "  Aborted."
    exit 0
fi
fi

# ---------------------------------------------------
# Pre-install checks
# ---------------------------------------------------
if ! command -v pacman &>/dev/null; then
    log_error "Arch-based system required."
fi

log_info "Starting installation..."

if ! command -v git &>/dev/null; then
    log_info "Installing git..."
    sudo pacman -S --noconfirm git
else
    log_info "git already installed, skipping."
fi

# ---------------------------------------------------
# Clone/Pull Repo
# ---------------------------------------------------
IS_UPDATE=false
if [ "${REEXECED:-0}" = "1" ]; then
    # Running as re-exec after self-update; skip pull
    IS_UPDATE=true
elif [ -d "$HYPR_DIR/.git" ]; then
    log_info "~/.config/hypr already cloned, checking for updates..."
    cd "$HYPR_DIR"
    pull_out=$(git pull --rebase 2>&1) || log_error "Pull failed."
    if echo "$pull_out" | grep -q "Already up to date\|Current branch.*is up to date"; then
        log_info "Config already up to date."
    else
        log_info "Config updated."
    fi
    log_info "Re-launching updated script..."
    exec env REEXECED=1 bash "$HYPR_DIR/install.sh"
else
    if [ -d "$HYPR_DIR" ]; then
        log_warn "~/.config/hypr exists. Backing up to ~/.config/hypr.bak..."
        mv "$HYPR_DIR" "$HOME/.config/hypr.bak"
    fi
    log_info "Cloning hyprconf repository..."
    git clone https://github.com/shalom2552/hyprconf.git "$HYPR_DIR"
fi

cd "$HYPR_DIR"

# ---------------------------------------------------
# 1. Install yay if not present
# ---------------------------------------------------
if ! command -v yay &>/dev/null; then
    log_info "Installing yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm git base-devel
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    cd "$tmpdir/yay"
    makepkg -si --noconfirm
    cd "$HYPR_DIR"
    rm -rf "$tmpdir"
fi

# ---------------------------------------------------
# 2. Install packages (pacman)
# ---------------------------------------------------
log_info "Installing Hyprland packages (pacman)..."

packages=(
    hyprland hyprlock hypridle
    swaync swayosd
    sddm
    loupe
    playerctl
    grim slurp wl-clipboard
    network-manager-applet
    matugen
    stow
    xdg-desktop-portal-hyprland
    polkit-gnome
    adw-gtk-theme
    cliphist fzf
    imagemagick ffmpeg python jq
    thunar kitty
    pipewire pipewire-pulse pipewire-alsa wireplumber
    pulsemixer
    bluez bluez-utils
)

for pkg in "${packages[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        log_info "Installing $pkg..."
        sudo pacman -S --needed --noconfirm "$pkg" \
            || log_warn "Failed to install $pkg, skipping..."
    else
        log_info "$pkg already installed, skipping."
    fi
done

# ---------------------------------------------------
# 3. Install AUR packages
# ---------------------------------------------------
log_info "Installing AUR packages (yay)..."

aur_packages=(
    quickshell-git
    awww
    bluetuith
    zen-browser-bin
)

for pkg in "${aur_packages[@]}"; do
    if ! yay -Q "$pkg" &>/dev/null; then
        log_info "Installing $pkg..."
        yay -S --needed --noconfirm --sudoloop "$pkg" \
            || log_warn "Failed to install $pkg, skipping..."
    else
        log_info "$pkg already installed, skipping."
    fi
done

# ---------------------------------------------------
# 3b. Enable services
# ---------------------------------------------------
if ! systemctl is-enabled bluetooth.service &>/dev/null; then
    log_info "Enabling bluetooth..."
    sudo systemctl enable --now bluetooth.service || log_warn "Failed to enable bluetooth."
else
    log_info "bluetooth already enabled, skipping."
fi

# ---------------------------------------------------
# 4. SDDM Theme Setup
# ---------------------------------------------------
log_info "Configuring SDDM..."

SDDM_CONF="/etc/sddm.conf.d/theme.conf"

if ! pacman -Q "$SDDM_THEME_PKG" &>/dev/null; then
    log_info "Installing $SDDM_THEME_PKG..."
    yay -S --needed --noconfirm --sudoloop "$SDDM_THEME_PKG" \
        || log_warn "Failed to install SDDM theme, skipping..."
else
    log_info "$SDDM_THEME_PKG already installed, skipping."
fi

CURRENT_DM=$(basename "$(readlink /etc/systemd/system/display-manager.service 2>/dev/null)" .service 2>/dev/null)
if [ -n "$CURRENT_DM" ] && [ "$CURRENT_DM" != "sddm" ]; then
    log_info "Disabling existing display manager: $CURRENT_DM"
    sudo systemctl disable "$CURRENT_DM" || log_warn "Failed to disable $CURRENT_DM."
fi

SDDM_CONF_OK=false
SDDM_ENABLED=false
grep -q "Current=$SDDM_THEME" "$SDDM_CONF" 2>/dev/null && SDDM_CONF_OK=true
[ -L /etc/systemd/system/display-manager.service ] && \
    [ "$(basename "$(readlink /etc/systemd/system/display-manager.service)" .service)" = "sddm" ] && \
    SDDM_ENABLED=true

if [ "$SDDM_CONF_OK" = false ] || [ "$SDDM_ENABLED" = false ]; then
    sudo mkdir -p /etc/sddm.conf.d
    sudo tee "$SDDM_CONF" > /dev/null <<EOF
[Theme]
Current=$SDDM_THEME

[Users]
RememberLastUser=true
RememberLastSession=true
EOF
    [ "$SDDM_ENABLED" = false ] && sudo systemctl enable sddm
    log_info "SDDM configured with theme: $SDDM_THEME"
else
    log_info "SDDM already configured, skipping."
fi

# ---------------------------------------------------
# 5. Deploy extra configs (swayosd, mimeapps)
# ---------------------------------------------------
log_info "Deploying extra configs (swayosd, mimeapps)..."
stow --adopt -R --no-folding -t ~ -d "$HYPR_DIR" extra
checkout_out=$(git -C "$HYPR_DIR" checkout extra/ 2>&1)
if [ -n "$checkout_out" ] && ! echo "$checkout_out" | grep -q "Updated 0"; then
    log_info "Extra configs updated."
fi

# ---------------------------------------------------
# 6. Wallpapers
# ---------------------------------------------------
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
if [ ! -d "$WALLPAPER_DIR/.git" ]; then
    log_info "Cloning wallpapers..."
    mkdir -p "$HOME/Pictures"
    git clone https://github.com/shalom2552/wallpapers-bank.git "$WALLPAPER_DIR"
else
    log_info "Wallpapers already cloned, checking for updates..."
    cd "$WALLPAPER_DIR"
    pull_out=$(git pull 2>&1)
    if echo "$pull_out" | grep -q "Already up to date"; then
        log_info "Wallpapers already up to date."
    else
        log_info "Wallpapers updated."
    fi
    cd "$HYPR_DIR"
fi

# ---------------------------------------------------
# 7. GTK dark mode
# ---------------------------------------------------
log_info "Setting GTK dark mode..."
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" 2>/dev/null || true

# ---------------------------------------------------
# 8. Monitor layout (after all installs — safe to skip/timeout)
# ---------------------------------------------------
if [ ! -f "$HYPR_DIR/monitors.conf" ]; then
    echo ""
    log_info "No monitors.conf found. How many monitors do you have?"
    echo "  1) 1 monitor  (Laptop)"
    echo "  2) 2 monitors (Desktop)"
    MONITOR_CHOICE=""
    read -t 30 -rp "  Enter choice [1/2, default=1]: " MONITOR_CHOICE || true
    [ -z "$MONITOR_CHOICE" ] && log_info "No input — defaulting to 1-monitor (Laptop)."
    case "$MONITOR_CHOICE" in
        2)
            cp "$HYPR_DIR/monitors.conf.desktop" "$HYPR_DIR/monitors.conf"
            log_info "Copied 2-monitor (Desktop) config."
            ;;
        *)
            cp "$HYPR_DIR/monitors.conf.laptop" "$HYPR_DIR/monitors.conf"
            log_info "Copied 1-monitor (Laptop) config."
            ;;
    esac
    log_info "Edit monitors.conf to match your displays (run 'hyprctl monitors' to list them)."
else
    log_info "monitors.conf already exists, skipping."
fi

# ---------------------------------------------------
# 9. Local config
# ---------------------------------------------------
if [ ! -f "$HYPR_DIR/local.conf" ]; then
    log_info "Creating local.conf..."
    printf "# ~/.config/hypr/local.conf\n# Machine-specific config — not tracked in git.\n" \
        > "$HYPR_DIR/local.conf"
fi

# ---------------------------------------------------
# 10. Dotfiles setup
# ---------------------------------------------------
log_info "Running dotfiles setup..."
if [ -d "$HOME/dotfiles/.git" ]; then
    SKIP_WELCOME=1 bash "$HOME/dotfiles/install.sh"
else
    bash <(curl -fSsL https://raw.githubusercontent.com/shalom2552/dotfiles/main/install.sh)
fi

# ---------------------------------------------------
# Done
# ---------------------------------------------------
if [ "$IS_UPDATE" = true ]; then
    log_info "Hyprconf update complete!"
else
    log_info "Hyprconf setup complete!"
    log_info "Reload Hyprland config: hyprctl reload"
fi
echo ""
