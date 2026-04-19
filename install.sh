#!/usr/bin/env bash
set -e

HYPR_DIR="$HOME/.config/hypr"
VERSION="1.4.2"

# ---------------------------------------------------
# Helpers
# ---------------------------------------------------
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ---------------------------------------------------
# Welcome
# ---------------------------------------------------
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
echo "    • Wallpapers + Matugen theming"
echo "    • AUR packages (quickshell, awww, ...)"
echo "    • Monitor layout selection"
echo ""
read -r -p "  Proceed? [n/Y] " confirm
echo ""
if [[ "$confirm" =~ ^[Nn]$ ]]; then
    echo "  Aborted."
    exit 0
fi

# ---------------------------------------------------
# Pre-install checks
# ---------------------------------------------------
if ! command -v pacman &>/dev/null; then
    error "Arch-based system required."
fi

info "Starting installation..."
echo ""

if ! command -v git &>/dev/null; then
    info "Installing git..."
    sudo pacman -S --noconfirm git
fi

# ---------------------------------------------------
# Clone and hand off
# ---------------------------------------------------
if [ -d "$HYPR_DIR/.git" ]; then
    warn "~/.config/hypr already cloned. Pulling..."
    cd "$HYPR_DIR"
    git pull --rebase || error "Pull failed."
else
    if [ -d "$HYPR_DIR" ]; then
        warn "~/.config/hypr exists. Backing up to ~/.config/hypr.bak..."
        mv "$HYPR_DIR" "$HOME/.config/hypr.bak"
    fi
    info "Cloning hyprconf repository..."
    git clone https://github.com/shalom2552/hyprconf.git "$HYPR_DIR"
fi

cd "$HYPR_DIR"
chmod +x setup.sh
info "Handing off to setup.sh..."
exec ./setup.sh
