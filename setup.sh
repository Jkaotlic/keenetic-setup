#!/bin/sh
# keenetic-setup.sh — Keenetic router initial setup
# Usage: sh setup.sh [--awg] [--hydra] [--autoupdate] [--all] [--help]

# ── Colors ──────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { printf "${GREEN}[✓]${NC} %s\n" "$1"; }
err()  { printf "${RED}[✗]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[!]${NC} %s\n" "$1"; }
info() { printf "${BOLD}[*]${NC} %s\n" "$1"; }

# ── Flag parsing ────────────────────────────────
INSTALL_AWG=""
INSTALL_HYDRA=""
INSTALL_AUTOUPDATE=""
INTERACTIVE=1

usage() {
    printf "Usage: sh setup.sh [OPTIONS]\n\n"
    printf "Options:\n"
    printf "  --awg          Install AWG-Manager + repo\n"
    printf "  --hydra        Install HydraRoute Neo + Web + repo\n"
    printf "  --autoupdate   Deploy auto-update script + cron\n"
    printf "  --all          Install everything\n"
    printf "  --help         Show this help\n\n"
    printf "No flags = interactive mode (asks what to install)\n"
    exit 0
}

while [ $# -gt 0 ]; do
    case "$1" in
        --awg)        INSTALL_AWG=1; INTERACTIVE=0 ;;
        --hydra)      INSTALL_HYDRA=1; INTERACTIVE=0 ;;
        --autoupdate) INSTALL_AUTOUPDATE=1; INTERACTIVE=0 ;;
        --all)        INSTALL_AWG=1; INSTALL_HYDRA=1; INSTALL_AUTOUPDATE=1; INTERACTIVE=0 ;;
        --help|-h)    usage ;;
        *)            err "Unknown option: $1"; usage ;;
    esac
    shift
done

# ── PATH fix ────────────────────────────────────
export PATH=/opt/bin:/opt/sbin:/usr/sbin:/usr/bin:/sbin:/bin

# ── Entware check ──────────────────────────────
if [ ! -x /opt/bin/opkg ]; then
    err "Entware not found (/opt/bin/opkg missing)"
    err "Install Entware first via Keenetic web UI"
    exit 1
fi
ok "Entware found"

# ── Arch detection ──────────────────────────────
DETECTED_ARCH=$(opkg print-architecture 2>/dev/null | sort -k3 -nr | awk '$2 != "all" {print $2; exit}')

case "$DETECTED_ARCH" in
    aarch64*)
        AWG_REPO="http://repo.hoaxisr.ru/aarch64-k3.10"
        HYDRA_REPO="https://ground-zerro.github.io/release/keenetic/aarch64-k3.10"
        ;;
    mipsel*)
        AWG_REPO="http://repo.hoaxisr.ru/mipsel-k3.4"
        HYDRA_REPO="https://ground-zerro.github.io/release/keenetic/mipsel-k3.4"
        ;;
    mips*)
        AWG_REPO="http://repo.hoaxisr.ru/mips-k3.4"
        HYDRA_REPO="https://ground-zerro.github.io/release/keenetic/mips-k3.4"
        ;;
    *)
        err "Unknown architecture: $DETECTED_ARCH"
        exit 1
        ;;
esac
ok "Architecture: $DETECTED_ARCH"

# ── Update Entware ──────────────────────────────
info "Updating package lists..."
opkg update 2>&1 | grep -v 'has no valid architecture'
ok "Package lists updated"

info "Upgrading installed packages..."
UPGRADABLE=$(opkg list-upgradable 2>/dev/null | grep ' - .* - ' | grep -v 'has no valid architecture')
if [ -z "$UPGRADABLE" ]; then
    ok "All packages up to date"
else
    echo "$UPGRADABLE" | awk '{print $1}' | while read pkg; do
        info "  Upgrading $pkg..."
        opkg upgrade "$pkg" 2>&1 | grep -v 'has no valid architecture'
    done
    ok "Packages upgraded"
fi

# ── Base dependencies ───────────────────────────
for dep in ca-certificates wget-ssl curl; do
    if opkg list-installed | grep -q "^${dep} "; then
        ok "$dep already installed"
    else
        info "Installing $dep..."
        if opkg install "$dep" 2>&1 | grep -v 'has no valid architecture'; then
            ok "$dep installed"
        else
            warn "Failed to install $dep (non-critical, continuing)"
        fi
    fi
done

# ── Interactive prompts ─────────────────────────
ask() {
    # ask "prompt" "default" → sets REPLY to y or n
    # default: y = [Y/n], n = [y/N]
    _prompt="$1"
    _default="$2"
    if [ "$_default" = "y" ]; then
        printf "${BOLD}%s [Y/n]:${NC} " "$_prompt"
    else
        printf "${BOLD}%s [y/N]:${NC} " "$_prompt"
    fi
    read REPLY
    REPLY=$(echo "$REPLY" | tr '[:upper:]' '[:lower:]')
    [ -z "$REPLY" ] && REPLY="$_default"
}

if [ "$INTERACTIVE" = "1" ]; then
    printf "\n${BOLD}=== Keenetic Setup ===${NC}\n\n"

    ask "Install AWG-Manager?" "y"
    [ "$REPLY" = "y" ] && INSTALL_AWG=1

    ask "Install HydraRoute (Neo + Web)?" "n"
    [ "$REPLY" = "y" ] && INSTALL_HYDRA=1

    ask "Setup auto-update (cron, daily 4:30)?" "y"
    [ "$REPLY" = "y" ] && INSTALL_AUTOUPDATE=1

    printf "\n"
fi
