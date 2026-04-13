# keenetic-setup

Скрипт первоначальной настройки роутеров Keenetic с Entware. Настраивает репозитории пакетов, устанавливает инструменты управления сетью и разворачивает автоматическое обновление по расписанию.

> [English version below](#english)

## Возможности

- **Автоопределение** архитектуры роутера (aarch64, mipsel, mips)
- **AWG-Manager** — менеджер AmneziaWG-туннелей, настройка репозитория и установка
- **HydraRoute Neo + Web** — маршрутизация трафика на основе политик с веб-интерфейсом
- **Автообновление** — ежедневный cron-скрипт для обновления пакетов Entware с ротацией логов
- **Интерактивный и тихий режимы** — по умолчанию спрашивает, с флагами работает без вопросов
- **Идемпотентность** — можно запускать повторно, обновляет существующие пакеты

## Требования

- Роутер Keenetic с установленным **Entware** (через USB-накопитель)
- SSH-доступ к роутеру (обычно порт 222, dropbear)
- `wget-ssl` или `curl` для скачивания скрипта (на большинстве установок уже есть)

**Протестировано:**
| Модель | Архитектура | Прошивка |
|--------|-------------|----------|
| Keenetic Giga (KN-1011) | aarch64 | KeeneticOS 4.x |

## Установка

Подключитесь к роутеру по SSH и выполните:

```sh
wget -O /tmp/setup.sh https://raw.githubusercontent.com/Jkaotlic/keenetic-setup/main/setup.sh
sh /tmp/setup.sh
```

Если `wget-ssl` не установлен:

```sh
opkg update && opkg install wget-ssl
```

## Использование

### Интерактивный режим (по умолчанию)

```sh
sh /tmp/setup.sh
```

Скрипт спросит по каждому компоненту:

```
=== Keenetic Setup ===

Install AWG-Manager? [Y/n]:
Install HydraRoute (Neo + Web)? [y/N]:
Setup auto-update (cron, daily 4:30)? [Y/n]:
```

### Тихий режим (флаги)

```sh
sh /tmp/setup.sh --all              # установить всё
sh /tmp/setup.sh --awg              # только AWG-Manager
sh /tmp/setup.sh --awg --autoupdate # AWG-Manager + автообновление
sh /tmp/setup.sh --hydra            # только HydraRoute
sh /tmp/setup.sh --help             # справка
```

| Флаг | Компонент |
|------|-----------|
| `--awg` | AWG-Manager + репозиторий |
| `--hydra` | HydraRoute Neo + Web + репозиторий |
| `--autoupdate` | Скрипт автообновления + cron (ежедневно в 4:30) |
| `--all` | Всё вышеперечисленное |

## Что делает скрипт

1. **PATH-фикс** — приоритет бинарников Entware над системными
2. **Обновление пакетов** — `opkg update` + обновление всех установленных пакетов
3. **Базовые зависимости** — установка `ca-certificates`, `wget-ssl`, `curl` при отсутствии
4. **AWG-Manager** — добавление репозитория [repo.hoaxisr.ru](http://repo.hoaxisr.ru), установка `awg-manager`
5. **HydraRoute** — добавление репозитория ground-zerro, установка `hrneo` + `hrweb`
6. **Автообновление** — размещение скрипта `/opt/bin/entware-autoupdate`, установка и настройка `cron`

### Скрипт автообновления

Размещается в `/opt/bin/entware-autoupdate`, запускается ежедневно в 4:30:

- Обновляет списки пакетов
- Обновляет каждый доступный пакет по отдельности
- Логирует в `/opt/var/log/autoupdate.log`
- Ротация лога при 100 КБ

### Настраиваемые репозитории

| Компонент | Репозиторий |
|-----------|-------------|
| AWG-Manager | `http://repo.hoaxisr.ru/{arch}` |
| HydraRoute | `https://ground-zerro.github.io/release/keenetic/{arch}` |

Суффикс архитектуры определяется автоматически (`aarch64-k3.10`, `mipsel-k3.4`, `mips-k3.4`).

## Решение проблем

**`wget: not an http or ftp url`** — системный `wget` не поддерживает HTTPS. Установите `wget-ssl`:
```sh
opkg update && opkg install wget-ssl
```

**`Entware not found`** — Entware не установлен. Включите OPKG в веб-интерфейсе Keenetic: *Управление > OPKG*.

**`Unknown architecture`** — модель роутера может не поддерживаться. Проверьте:
```sh
opkg print-architecture
```

**Пакеты не обновляются** — проверьте сетевое подключение роутера:
```sh
ping -c 3 bin.entware.net
```

## Отказ от ответственности

Проект предоставляется как есть для личного использования в домашней сети. Используйте на свой страх и риск. Всегда проверяйте скрипты перед запуском на вашем оборудовании. Автор не несёт ответственности за неправильно настроенные устройства.

## Благодарности

Этот проект — обёртка для установки отличных инструментов, созданных их авторами:

- **[Entware](https://github.com/Entware/Entware)** — пакетный менеджер для встраиваемых Linux-устройств (2500+ пакетов). Фундамент, на котором всё строится.
- **[AWG-Manager](https://github.com/hoaxisr/awg-manager)** от [@hoaxisr](https://github.com/hoaxisr) — менеджер AmneziaWG-туннелей с веб-интерфейсом для Keenetic
- **[HydraRoute](https://github.com/Ground-Zerro/HydraRoute)** от [@Ground-Zerro](https://github.com/Ground-Zerro) — маршрутизация трафика на основе политик с веб-интерфейсом для Keenetic
- **[AmneziaWG](https://github.com/amnezia-vpn/amneziawg-go)** от [Amnezia VPN](https://github.com/amnezia-vpn) — высокопроизводительный VPN-протокол на базе WireGuard

Спасибо всем разработчикам и контрибьюторам, которые делают экосистему Keenetic лучше.

---

<a name="english"></a>

## English

One-command initial setup for Keenetic routers with Entware. Configures package repositories, installs network management tools, and deploys automatic update scheduling.

### Features

- **Auto-detection** of router architecture (aarch64, mipsel, mips)
- **AWG-Manager** — AmneziaWG tunnel manager, repo configuration and install
- **HydraRoute Neo + Web** — policy-based routing with web interface
- **Automatic updates** — daily cron job for Entware package upgrades with log rotation
- **Interactive & silent modes** — prompts by default, CLI flags for automation
- **Idempotent** — safe to re-run, upgrades existing packages instead of reinstalling

### Requirements

- Keenetic router with **Entware** installed (via USB storage)
- SSH access to the router (typically port 222, dropbear)
- `wget-ssl` or `curl` for downloading the script

### Installation

```sh
wget -O /tmp/setup.sh https://raw.githubusercontent.com/Jkaotlic/keenetic-setup/main/setup.sh
sh /tmp/setup.sh
```

### Usage

```sh
sh /tmp/setup.sh              # interactive mode
sh /tmp/setup.sh --all        # install everything (silent)
sh /tmp/setup.sh --awg        # AWG-Manager only
sh /tmp/setup.sh --hydra      # HydraRoute only
sh /tmp/setup.sh --autoupdate # auto-update cron only
sh /tmp/setup.sh --help       # show usage
```

| Flag | Component |
|------|-----------|
| `--awg` | AWG-Manager + repository |
| `--hydra` | HydraRoute Neo + Web + repository |
| `--autoupdate` | Auto-update script + cron (daily 4:30 AM) |
| `--all` | All of the above |

### What it does

1. **PATH fix** — ensures Entware binaries take priority over system ones
2. **Package update** — `opkg update` + upgrade all installed packages
3. **Base dependencies** — installs `ca-certificates`, `wget-ssl`, `curl` if missing
4. **AWG-Manager** — adds [repo.hoaxisr.ru](http://repo.hoaxisr.ru) repository, installs `awg-manager`
5. **HydraRoute** — adds ground-zerro repository, installs `hrneo` + `hrweb`
6. **Auto-update** — deploys `/opt/bin/entware-autoupdate` script, installs and configures `cron`

### Disclaimer

Provided as-is for personal home network use. Use at your own risk. Always review scripts before running them on your hardware.

### Acknowledgements

This project is a setup wrapper around tools built by their respective authors:

- **[Entware](https://github.com/Entware/Entware)** — package manager for embedded Linux devices (2500+ packages)
- **[AWG-Manager](https://github.com/hoaxisr/awg-manager)** by [@hoaxisr](https://github.com/hoaxisr) — AmneziaWG tunnel manager for Keenetic
- **[HydraRoute](https://github.com/Ground-Zerro/HydraRoute)** by [@Ground-Zerro](https://github.com/Ground-Zerro) — policy-based traffic routing for Keenetic
- **[AmneziaWG](https://github.com/amnezia-vpn/amneziawg-go)** by [Amnezia VPN](https://github.com/amnezia-vpn) — high-performance WireGuard-based VPN protocol

Thanks to all the developers and contributors who make the Keenetic ecosystem great.

## License

MIT
