#!/usr/bin/env sh
# ═══════════════════════════════════════════════════════════════════
#  install.sh — установка quickshell-rice вместо waybar
#
#  Что делает:
#    1. ставит пакет quickshell, если его нет;
#    2. делает ~/.config/quickshell симлинком на quickshell/ репозитория
#       (если путь занят чем-то другим — останавливается, ничего не перезаписывая);
#    3. копирует hypr/* в ~/.config/hypr (с бэкапом *.bak-<дата>);
#    4. ставит user-unit quickshell.service, daemon-reload, enable;
#    5. убирает waybar из автозапуска и хоткей SUPER+W переводит на quickshell;
#    6. перечитывает конфиг Hyprland и запускает сервис.
#
#  Скрипт идемпотентен: повторный запуск ничего не ломает.
#  Откат: ./uninstall.sh
# ═══════════════════════════════════════════════════════════════════
set -eu

REPO_DIR=$(cd "$(dirname "$0")" && pwd)

QS_DIR="$REPO_DIR/quickshell"
HYPR_DIR="$HOME/.config/hypr"
HYPR_LUA="$HYPR_DIR/hyprland.lua"
QS_LINK="$HOME/.config/quickshell"
UNIT_DIR="$HOME/.config/systemd/user"
UNIT_NAME="quickshell.service"
STAMP=$(date +%Y%m%d-%H%M%S)

say()  { printf '==> %s\n' "$*"; }
warn() { printf 'предупреждение: %s\n' "$*" >&2; }
die()  { printf 'ОШИБКА: %s\n' "$*" >&2; exit 1; }

# Бэкап файла: не чаще одного раза за запуск, чтобы сохранить оригинал.
backup() {
    if [ ! -e "$1.bak-$STAMP" ]; then
        cp -p "$1" "$1.bak-$STAMP"
        say "бэкап: $1.bak-$STAMP"
    fi
}

# copy_file <src> <dst> — копирует, бэкапя существующий dst; пропускает идентичный.
copy_file() {
    src=$1
    dst=$2
    if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
        say "$dst уже актуален"
        return 0
    fi
    if [ -e "$dst" ]; then
        backup "$dst"
    fi
    cp -p "$src" "$dst"
    say "установлен: $dst"
}

# ── 1. Пакет ───────────────────────────────────────────────────────
if command -v qs >/dev/null 2>&1 || command -v quickshell >/dev/null 2>&1; then
    say "quickshell уже установлен"
else
    say "ставлю quickshell (sudo dnf install -y quickshell)"
    sudo dnf install -y quickshell
fi

# Имя бинарника в пакете Fedora может отличаться от `qs` в документации.
if ! command -v qs >/dev/null 2>&1; then
    warn "бинарник 'qs' не найден в PATH — проверьте 'rpm -ql quickshell | grep bin/'"
    warn "и, если он называется иначе, поправьте ExecStart в $UNIT_DIR/$UNIT_NAME"
fi

# ── 2. Конфиг Quickshell: симлинк ──────────────────────────────────
# Существующий путь НЕ перезаписывается. Исключение — уже наш симлинк:
# это делает повторный запуск идемпотентным.
if [ -e "$QS_LINK" ] || [ -L "$QS_LINK" ]; then
    if [ -L "$QS_LINK" ] && [ "$(readlink -f "$QS_LINK")" = "$QS_DIR" ]; then
        say "$QS_LINK уже указывает на репозиторий"
    else
        die "$QS_LINK уже существует и не является симлинком на $QS_DIR — ничего не перезаписываю (переименуйте или уберите этот путь вручную и запустите скрипт снова)"
    fi
else
    mkdir -p "$(dirname "$QS_LINK")"
    ln -s "$QS_DIR" "$QS_LINK"
    say "симлинк: $QS_LINK -> $QS_DIR"
fi

# ── 3. Конфиги Hyprland ────────────────────────────────────────────
mkdir -p "$HYPR_DIR/scripts"

for f in "$REPO_DIR"/hypr/*.lua "$REPO_DIR"/hypr/*.conf; do
    [ -e "$f" ] || continue
    copy_file "$f" "$HYPR_DIR/$(basename "$f")"
done

for f in "$REPO_DIR"/hypr/scripts/*; do
    [ -e "$f" ] || continue
    copy_file "$f" "$HYPR_DIR/scripts/$(basename "$f")"
done

chmod +x "$HYPR_DIR"/scripts/*.sh 2>/dev/null || true

# ── 4. systemd user-unit ───────────────────────────────────────────
mkdir -p "$UNIT_DIR"
copy_file "$REPO_DIR/systemd/$UNIT_NAME" "$UNIT_DIR/$UNIT_NAME"
systemctl --user daemon-reload
systemctl --user enable "$UNIT_NAME" >/dev/null 2>&1 || warn "не удалось enable $UNIT_NAME"
say "сервис установлен и включён: $UNIT_NAME"

# ── 5. Автозапуск и хоткей в hyprland.lua ──────────────────────────
if [ -f "$HYPR_LUA" ]; then
    if grep -q 'qs-session\.sh' "$HYPR_LUA"; then
        say "автозапуск уже идёт через qs-session.sh"
    elif grep -q 'hl\.exec_cmd("waybar")' "$HYPR_LUA"; then
        backup "$HYPR_LUA"
        sed -i 's|^\([[:space:]]*\)hl\.exec_cmd("waybar").*$|\1hl.exec_cmd("$HOME/.config/hypr/scripts/qs-session.sh")|' "$HYPR_LUA"
        say "автозапуск waybar заменён на qs-session.sh"
    else
        warn "строка hl.exec_cmd(\"waybar\") не найдена в $HYPR_LUA — поправьте автозапуск вручную"
    fi

    if grep -q 'systemctl --user restart quickshell\.service' "$HYPR_LUA"; then
        say "хоткей SUPER+W уже перезапускает quickshell"
    elif grep -q 'pkill -SIGUSR1 waybar' "$HYPR_LUA"; then
        backup "$HYPR_LUA"
        sed -i 's|pkill -SIGUSR1 waybar|systemctl --user restart quickshell.service|' "$HYPR_LUA"
        say "хоткей SUPER+W переведён на перезапуск quickshell"
    else
        warn "хоткей waybar (pkill -SIGUSR1 waybar) не найден в $HYPR_LUA — поправьте вручную"
    fi
else
    warn "$HYPR_LUA не найден — правки автозапуска пропущены"
fi

# ── 6. Перечитать конфиг и заменить работающий waybar ──────────────
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || warn "hyprctl reload не удался"
    say "Hyprland перечитал конфиг"
fi

# waybar мог быть запущен в текущей сессии — заменяем его на Quickshell
if command -v pgrep >/dev/null 2>&1 && pgrep -x waybar >/dev/null 2>&1; then
    say "останавливаю работающий waybar"
    pkill -x waybar || warn "не удалось остановить waybar"
fi

# Импортирует Wayland-переменные в user-manager и стартует сервис
"$HYPR_DIR/scripts/qs-session.sh" || warn "не удалось запустить сервис вручную: systemctl --user start $UNIT_NAME"

say "готово. Проверка: hyprctl layers | grep qs-bar"
