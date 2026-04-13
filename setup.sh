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
