# keenetic-setup.sh — Design Spec

## Overview

Shell-скрипт для первоначальной настройки Keenetic роутера с Entware. Обновляет пакеты, ставит AWG-Manager, опционально HydraRoute, деплоит скрипт автообновления с cron.

**Хостинг:** GitHub (публичный репозиторий)
**Запуск:** `wget -O /tmp/setup.sh <url> && sh /tmp/setup.sh`
**Требование:** Entware уже установлен на роутере

## Режимы работы

### Интерактивный (по умолчанию)
Скрипт спрашивает у пользователя что устанавливать:
- "Установить AWG-Manager? [Y/n]"
- "Установить HydraRoute? [y/N]"
- "Настроить автообновление? [Y/n]"

### Silent (флаги)
- `--awg` — AWG-Manager + repo
- `--hydra` — HydraRoute Neo + Web + repo
- `--autoupdate` — скрипт автообновления + cron
- `--all` — всё вышеперечисленное
- `--help` — справка

При передаче любого флага (кроме `--help`) скрипт работает без вопросов. Компоненты, не указанные флагами, пропускаются.

## Порядок выполнения

### 1. Проверки
- Наличие `/opt/bin/opkg` (Entware установлен?)
- Определение архитектуры через `opkg print-architecture`
- Поддерживаемые: aarch64, mipsel, mips
- При неизвестной архитектуре — exit 1

### 2. PATH-фикс
```sh
export PATH=/opt/bin:/opt/sbin:/usr/sbin:/usr/bin:/sbin:/bin
```
Критично: без этого opkg может использовать системный wget без SSL.

### 3. Обновление Entware
- `opkg update` — обновить списки пакетов
- `opkg upgrade <pkg>` — обновить все установленные пакеты
- Фильтр `has no valid architecture` в выводе

### 4. Базовые зависимости
Установить если отсутствуют:
- `ca-certificates`
- `wget-ssl`
- `curl`

### 5. AWG-Manager (опционально)
- Записать repo в `/opt/etc/opkg/awg_manager.conf`:
  - aarch64: `src/gz hoaxisr http://repo.hoaxisr.ru/aarch64-k3.10`
  - mipsel: `src/gz hoaxisr http://repo.hoaxisr.ru/mipsel-k3.4`
  - mips: `src/gz hoaxisr http://repo.hoaxisr.ru/mips-k3.4`
- `opkg update`
- `opkg install awg-manager`

### 6. HydraRoute (опционально)
- Записать repo в `/opt/etc/opkg/customfeeds.conf`:
  - aarch64: `src/gz ground-zerro https://ground-zerro.github.io/release/keenetic/aarch64-k3.10`
  - mipsel: `src/gz ground-zerro https://ground-zerro.github.io/release/keenetic/mipsel-k3.4`
  - mips: `src/gz ground-zerro https://ground-zerro.github.io/release/keenetic/mips-k3.4`
- `opkg update`
- `opkg install hrneo hrweb`

### 7. Автообновление (опционально)
- Создать `/opt/bin/entware-autoupdate`:
  - PATH-фикс
  - `opkg update` → `opkg list-upgradable` (фильтр invalid arch) → `opkg upgrade` по каждому пакету
  - Логирование в `/opt/var/log/autoupdate.log`
  - Ротация лога при >100KB
- `chmod +x /opt/bin/entware-autoupdate`
- Установить пакет `cron` если нет
- Запустить crond если не запущен
- Добавить в crontab: `30 4 * * * /opt/bin/entware-autoupdate`

## Обработка ошибок

- Цветной вывод: зелёный (успех), красный (ошибка), жёлтый (предупреждение)
- Формат: `[✓] Сообщение`, `[✗] Ошибка`, `[*] Действие...`
- Критические ошибки (нет Entware, неизвестная архитектура) — `exit 1` с описанием
- Некритические (пакет уже установлен) — предупреждение, продолжаем
- В конце — summary: что установлено, что пропущено

## Архитектурная таблица

| Архитектура | AWG-Manager repo | HydraRoute repo |
|-------------|-----------------|-----------------|
| aarch64 | `http://repo.hoaxisr.ru/aarch64-k3.10` | `https://ground-zerro.github.io/release/keenetic/aarch64-k3.10` |
| mipsel | `http://repo.hoaxisr.ru/mipsel-k3.4` | `https://ground-zerro.github.io/release/keenetic/mipsel-k3.4` |
| mips | `http://repo.hoaxisr.ru/mips-k3.4` | `https://ground-zerro.github.io/release/keenetic/mips-k3.4` |

## Структура репозитория

```
keenetic-setup/
  setup.sh          — основной скрипт
  README.md         — инструкция по использованию (будет при публикации)
  docs/             — спека и документация
```
