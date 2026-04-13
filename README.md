# keenetic-setup

One-command initial setup for Keenetic routers with Entware. Configures package repositories, installs network management tools, and deploys automatic update scheduling.

## Features

- **Auto-detection** of router architecture (aarch64, mipsel, mips)
- **AWG-Manager** — AmneziaWG tunnel manager, repo configuration and install
- **HydraRoute Neo + Web** — policy-based routing with web interface
- **Automatic updates** — daily cron job for Entware package upgrades with log rotation
- **Interactive & silent modes** — prompts by default, CLI flags for automation
- **Idempotent** — safe to re-run, upgrades existing packages instead of reinstalling

## Requirements

- Keenetic router with **Entware** installed (via USB storage)
- SSH access to the router (typically port 222, dropbear)
- `wget-ssl` or `curl` for downloading the script (pre-installed on most setups)

**Tested on:**
| Model | Arch | Firmware |
|-------|------|----------|
| Keenetic Giga (KN-1011) | aarch64 | KeeneticOS 4.x |

## Installation

SSH into the router and run:

```sh
wget -O /tmp/setup.sh https://raw.githubusercontent.com/Jkaotlic/keenetic-setup/main/setup.sh
sh /tmp/setup.sh
```

If `wget-ssl` is not installed:

```sh
opkg update && opkg install wget-ssl
```

## Usage

### Interactive mode (default)

```sh
sh /tmp/setup.sh
```

The script will prompt for each component:

```
=== Keenetic Setup ===

Install AWG-Manager? [Y/n]:
Install HydraRoute (Neo + Web)? [y/N]:
Setup auto-update (cron, daily 4:30)? [Y/n]:
```

### Silent mode (flags)

```sh
sh /tmp/setup.sh --all              # install everything
sh /tmp/setup.sh --awg              # AWG-Manager only
sh /tmp/setup.sh --awg --autoupdate # AWG-Manager + auto-update
sh /tmp/setup.sh --hydra            # HydraRoute only
sh /tmp/setup.sh --help             # show usage
```

| Flag | Component |
|------|-----------|
| `--awg` | AWG-Manager + repository |
| `--hydra` | HydraRoute Neo + Web + repository |
| `--autoupdate` | Auto-update script + cron (daily 4:30 AM) |
| `--all` | All of the above |

## What it does

1. **PATH fix** — ensures Entware binaries take priority over system ones
2. **Package update** — `opkg update` + upgrade all installed packages
3. **Base dependencies** — installs `ca-certificates`, `wget-ssl`, `curl` if missing
4. **AWG-Manager** — adds [repo.hoaxisr.ru](http://repo.hoaxisr.ru) repository, installs `awg-manager`
5. **HydraRoute** — adds ground-zerro repository, installs `hrneo` + `hrweb`
6. **Auto-update** — deploys `/opt/bin/entware-autoupdate` script, installs and configures `cron`

### Auto-update script

Deployed to `/opt/bin/entware-autoupdate`, runs daily at 4:30 AM:

- Updates package lists
- Upgrades all available packages individually
- Logs to `/opt/var/log/autoupdate.log`
- Rotates log at 100 KB

### Repositories configured

| Component | Repository |
|-----------|-----------|
| AWG-Manager | `http://repo.hoaxisr.ru/{arch}` |
| HydraRoute | `https://ground-zerro.github.io/release/keenetic/{arch}` |

Architecture suffix is detected automatically (`aarch64-k3.10`, `mipsel-k3.4`, `mips-k3.4`).

## Troubleshooting

**`wget: not an http or ftp url`** — system `wget` doesn't support HTTPS. Install `wget-ssl`:
```sh
opkg update && opkg install wget-ssl
```

**`Entware not found`** — Entware is not installed. Enable OPKG in Keenetic web UI under *Management > OPKG*.

**`Unknown architecture`** — your router model may not be supported. Check with:
```sh
opkg print-architecture
```

**Packages not updating** — verify network connectivity from the router:
```sh
ping -c 3 bin.entware.net
```

## Disclaimer

This project is provided as-is for personal home network use. Use at your own risk. Always review scripts before running them on your hardware. Not responsible for misconfigured devices.

## License

MIT
