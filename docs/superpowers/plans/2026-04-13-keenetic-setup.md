# keenetic-setup.sh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Single shell script that bootstraps a Keenetic router with AWG-Manager, HydraRoute, and auto-update cron — interactively or via CLI flags.

**Architecture:** One `setup.sh` file, no dependencies beyond what Entware provides. Modular functions for each feature block, flag parsing at the top, execution flow at the bottom.

**Tech Stack:** POSIX sh (BusyBox ash compatible), opkg, cron

---

## File Structure

| File | Purpose |
|------|---------|
| `setup.sh` | Main script — all logic in one file |

No additional files needed. The auto-update script is written inline by `setup.sh` onto the router at `/opt/bin/entware-autoupdate`.

---

### Task 1: Skeleton — flag parsing, help, color helpers

**Files:**
- Create: `setup.sh`

- [ ] **Step 1: Create `setup.sh` with shebang, color helpers, and flag parsing**

```sh
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
```

- [ ] **Step 2: Verify syntax locally**

Run: `bash -n setup.sh`
Expected: no output (no syntax errors)

- [ ] **Step 3: Commit**

```bash
git add setup.sh
git commit -m "feat: skeleton with flag parsing, color helpers, usage"
```

---

### Task 2: Entware checks, arch detection, PATH fix

**Files:**
- Modify: `setup.sh` (append after flag parsing block)

- [ ] **Step 1: Add Entware check and arch detection**

Append to `setup.sh` after the flag parsing `done`:

```sh
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
```

- [ ] **Step 2: Verify syntax**

Run: `bash -n setup.sh`
Expected: no output

- [ ] **Step 3: Commit**

```bash
git add setup.sh
git commit -m "feat: Entware check, arch detection, PATH fix"
```

---

### Task 3: Entware update + base dependencies

**Files:**
- Modify: `setup.sh` (append after arch detection)

- [ ] **Step 1: Add update and dependency install logic**

Append to `setup.sh`:

```sh
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
```

- [ ] **Step 2: Verify syntax**

Run: `bash -n setup.sh`
Expected: no output

- [ ] **Step 3: Commit**

```bash
git add setup.sh
git commit -m "feat: Entware update, package upgrade, base deps"
```

---

### Task 4: Interactive prompts

**Files:**
- Modify: `setup.sh` (append after base dependencies)

- [ ] **Step 1: Add interactive prompt logic**

Append to `setup.sh`:

```sh
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
```

- [ ] **Step 2: Verify syntax**

Run: `bash -n setup.sh`
Expected: no output

- [ ] **Step 3: Commit**

```bash
git add setup.sh
git commit -m "feat: interactive prompts with defaults"
```

---

### Task 5: AWG-Manager install

**Files:**
- Modify: `setup.sh` (append after prompts)

- [ ] **Step 1: Add AWG-Manager install function**

Append to `setup.sh`:

```sh
# ── AWG-Manager ─────────────────────────────────
SUMMARY_AWG="skipped"

if [ "$INSTALL_AWG" = "1" ]; then
    info "Configuring AWG-Manager repo..."
    echo "src/gz hoaxisr $AWG_REPO" > /opt/etc/opkg/awg_manager.conf
    ok "AWG repo: $AWG_REPO"

    info "Updating package lists..."
    opkg update 2>&1 | grep -v 'has no valid architecture' > /dev/null

    if opkg list-installed | grep -q "^awg-manager "; then
        info "AWG-Manager already installed, upgrading..."
        opkg upgrade awg-manager 2>&1 | grep -v 'has no valid architecture'
    else
        info "Installing AWG-Manager..."
        opkg install awg-manager 2>&1 | grep -v 'has no valid architecture'
    fi

    if opkg list-installed | grep -q "^awg-manager "; then
        AWG_VER=$(opkg list-installed | grep "^awg-manager " | awk '{print $3}')
        ok "AWG-Manager $AWG_VER installed"
        SUMMARY_AWG="installed ($AWG_VER)"
    else
        err "AWG-Manager installation failed"
        SUMMARY_AWG="FAILED"
    fi
fi
```

- [ ] **Step 2: Verify syntax**

Run: `bash -n setup.sh`
Expected: no output

- [ ] **Step 3: Commit**

```bash
git add setup.sh
git commit -m "feat: AWG-Manager repo config and install"
```

---

### Task 6: HydraRoute install

**Files:**
- Modify: `setup.sh` (append after AWG block)

- [ ] **Step 1: Add HydraRoute install function**

Append to `setup.sh`:

```sh
# ── HydraRoute ──────────────────────────────────
SUMMARY_HYDRA="skipped"

if [ "$INSTALL_HYDRA" = "1" ]; then
    info "Configuring HydraRoute repo..."
    echo "src/gz ground-zerro $HYDRA_REPO" > /opt/etc/opkg/customfeeds.conf
    ok "HydraRoute repo: $HYDRA_REPO"

    info "Updating package lists..."
    opkg update 2>&1 | grep -v 'has no valid architecture' > /dev/null

    for pkg in hrneo hrweb; do
        if opkg list-installed | grep -q "^${pkg} "; then
            info "$pkg already installed, upgrading..."
            opkg upgrade "$pkg" 2>&1 | grep -v 'has no valid architecture'
        else
            info "Installing $pkg..."
            opkg install "$pkg" 2>&1 | grep -v 'has no valid architecture'
        fi
    done

    if opkg list-installed | grep -q "^hrneo "; then
        HRNEO_VER=$(opkg list-installed | grep "^hrneo " | awk '{print $3}')
        HRWEB_VER=$(opkg list-installed | grep "^hrweb " | awk '{print $3}')
        ok "HydraRoute Neo $HRNEO_VER + Web $HRWEB_VER installed"
        SUMMARY_HYDRA="installed (neo $HRNEO_VER, web $HRWEB_VER)"
    else
        err "HydraRoute installation failed"
        SUMMARY_HYDRA="FAILED"
    fi
fi
```

- [ ] **Step 2: Verify syntax**

Run: `bash -n setup.sh`
Expected: no output

- [ ] **Step 3: Commit**

```bash
git add setup.sh
git commit -m "feat: HydraRoute repo config and install"
```

---

### Task 7: Auto-update script + cron

**Files:**
- Modify: `setup.sh` (append after HydraRoute block)

- [ ] **Step 1: Add auto-update deployment**

Append to `setup.sh`:

```sh
# ── Auto-update ─────────────────────────────────
SUMMARY_AUTOUPDATE="skipped"

if [ "$INSTALL_AUTOUPDATE" = "1" ]; then
    info "Deploying auto-update script..."

    cat > /opt/bin/entware-autoupdate << 'AUTOUPDATE_EOF'
#!/bin/sh
# Entware auto-update script
export PATH=/opt/bin:/opt/sbin:/usr/sbin:/usr/bin:/sbin:/bin
LOG=/opt/var/log/autoupdate.log
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "===== Update started: $DATE =====" >> $LOG

echo "[*] Updating package lists..." >> $LOG
opkg update >> $LOG 2>&1

UPGRADABLE=$(opkg list-upgradable 2>/dev/null | grep ' - .* - ' | grep -v 'has no valid architecture')

if [ -z "$UPGRADABLE" ]; then
    echo "[*] All packages are up to date" >> $LOG
    echo "===== Update finished: $(date '+%Y-%m-%d %H:%M:%S') =====" >> $LOG
    echo "" >> $LOG
    exit 0
fi

echo "[*] Upgradable packages:" >> $LOG
echo "$UPGRADABLE" >> $LOG

echo "[*] Upgrading..." >> $LOG
echo "$UPGRADABLE" | awk '{print $1}' | while read pkg; do
    echo "  -> Upgrading $pkg" >> $LOG
    opkg upgrade "$pkg" >> $LOG 2>&1
done

echo "[*] Upgrade complete" >> $LOG
echo "===== Update finished: $(date '+%Y-%m-%d %H:%M:%S') =====" >> $LOG
echo "" >> $LOG

LOG_SIZE=$(wc -c < $LOG 2>/dev/null || echo 0)
if [ "$LOG_SIZE" -gt 102400 ]; then
    tail -200 $LOG > $LOG.tmp
    mv $LOG.tmp $LOG
fi
AUTOUPDATE_EOF

    chmod +x /opt/bin/entware-autoupdate
    ok "Auto-update script deployed to /opt/bin/entware-autoupdate"

    # Install cron if missing
    if ! opkg list-installed | grep -q "^cron "; then
        info "Installing cron..."
        opkg install cron 2>&1 | grep -v 'has no valid architecture'
    fi

    # Start cron if not running
    if [ -x /opt/etc/init.d/S10cron ]; then
        /opt/etc/init.d/S10cron status > /dev/null 2>&1 || /opt/etc/init.d/S10cron start > /dev/null 2>&1
    fi

    # Add crontab entry (preserve existing entries)
    EXISTING_CRON=$(crontab -l 2>/dev/null | grep -v 'entware-autoupdate' || true)
    {
        [ -n "$EXISTING_CRON" ] && echo "$EXISTING_CRON"
        echo "30 4 * * * /opt/bin/entware-autoupdate"
    } | crontab -

    ok "Cron job set: daily at 4:30 AM"
    SUMMARY_AUTOUPDATE="installed"
fi
```

- [ ] **Step 2: Verify syntax**

Run: `bash -n setup.sh`
Expected: no output

- [ ] **Step 3: Commit**

```bash
git add setup.sh
git commit -m "feat: auto-update script deployment with cron"
```

---

### Task 8: Summary output + final commit

**Files:**
- Modify: `setup.sh` (append at end)

- [ ] **Step 1: Add summary block**

Append to `setup.sh`:

```sh
# ── Summary ─────────────────────────────────────
printf "\n${BOLD}=== Setup Complete ===${NC}\n\n"
printf "  Architecture:   %s\n" "$DETECTED_ARCH"
printf "  AWG-Manager:    %s\n" "$SUMMARY_AWG"
printf "  HydraRoute:     %s\n" "$SUMMARY_HYDRA"
printf "  Auto-update:    %s\n" "$SUMMARY_AUTOUPDATE"
printf "\n"

[ "$SUMMARY_AWG" = "FAILED" ] || [ "$SUMMARY_HYDRA" = "FAILED" ] && {
    warn "Some components failed to install. Check output above."
    exit 1
}

ok "All done!"
```

- [ ] **Step 2: Verify full script syntax**

Run: `bash -n setup.sh`
Expected: no output

- [ ] **Step 3: Run shellcheck (if available)**

Run: `shellcheck setup.sh 2>/dev/null || echo "shellcheck not installed, skipping"`
Expected: clean or only minor notes (SC2059 for printf with color vars is acceptable)

- [ ] **Step 4: Final commit**

```bash
git add setup.sh
git commit -m "feat: summary output, complete keenetic-setup.sh"
```
