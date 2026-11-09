#!/usr/bin/env sh
# ═══════════════════════════════════════════════════════════════════
#  uninstall.sh — откат quickshell-rice обратно на waybar
#
#  Что делает:
#    1. останавливает и выключает quickshell.service;
#    2. возвращает hl.exec_cmd("waybar") в автозапуск hyprland.lua;
#    3. возвращает хоткей SUPER+W на waybar;
#    4. перечитывает конфиг Hyprland и поднимает waybar.
#
#  Конфиги waybar не трогались, поэтому всё возвращается как было.
#  Скрипт идемпотентен.
# ═══════════════════════════════════════════════════════════════════
set -eu

HYPR_DIR="$HOME/.config/hypr"
HYPR_LUA="$HYPR_DIR/hyprland.lua"
UNIT_NAME="quickshell.service"
STAMP=$(date +%Y%m%d-%H%M%S)

say()  { printf '==> %s\n' "$*"; }
warn() { printf 'предупреждение: %s\n' "$*" >&2; }

backup() {
    if [ ! -e "$1.bak-$STAMP" ]; then
        cp -p "$1" "$1.bak-$STAMP"
        say "бэкап: $1.bak-$STAMP"
    fi
}

# ── 1. Остановить сервис ───────────────────────────────────────────
if command -v systemctl >/dev/null 2>&1; then
    if systemctl --user is-active --quiet "$UNIT_NAME" 2>/dev/null; then
        systemctl --user stop "$UNIT_NAME" || warn "не удалось остановить $UNIT_NAME"
        say "сервис остановлен: $UNIT_NAME"
    else
        say "сервис уже не запущен"
    fi
    systemctl --user disable "$UNIT_NAME" >/dev/null 2>&1 || true
fi

# ── 2. Вернуть waybar в hyprland.lua ───────────────────────────────
if [ -f "$HYPR_LUA" ]; then
    # автозапуск
    if grep -q 'hl\.exec_cmd("waybar")' "$HYPR_LUA"; then
        say "автозапуск уже waybar"
    elif grep -q 'qs-session\.sh' "$HYPR_LUA"; then
        backup "$HYPR_LUA"
        sed -i 's|^\([[:space:]]*\)hl\.exec_cmd(".*qs-session\.sh").*$|\1hl.exec_cmd("waybar") -- бар|' "$HYPR_LUA"
        say "автозапуск возвращён на waybar"
    else
        warn "строка с qs-session.sh не найдена в $HYPR_LUA"
        warn "верните автозапуск вручную: hl.exec_cmd(\"waybar\")"
    fi

    # хоткей SUPER+W
    if grep -q 'pkill -SIGUSR1 waybar' "$HYPR_LUA"; then
        say "хоткей уже waybar"
    elif grep -q 'systemctl --user restart quickshell\.service' "$HYPR_LUA"; then
        backup "$HYPR_LUA"
        sed -i 's|systemctl --user restart quickshell\.service|pkill -SIGUSR1 waybar|' "$HYPR_LUA"
        say "хоткей SUPER+W возвращён на waybar"
    else
        warn "хоткей quickshell не найден в $HYPR_LUA"
        warn "верните вручную: pkill -SIGUSR1 waybar"
    fi
else
    warn "$HYPR_LUA не найден — верните автозапуск waybar вручную"
fi

# ── 3. Перечитать конфиг и поднять waybar ──────────────────────────
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || warn "hyprctl reload не удался"
    say "Hyprland перечитал конфиг"
fi

if command -v pgrep >/dev/null 2>&1 && pgrep -x waybar >/dev/null 2>&1; then
    say "waybar уже запущен"
elif command -v waybar >/dev/null 2>&1; then
    say "запускаю waybar"
    if command -v setsid >/dev/null 2>&1; then
        setsid waybar >/dev/null 2>&1 &
    else
        waybar >/dev/null 2>&1 &
    fi
else
    warn "waybar не найден в PATH — запустите его вручную"
fi

say "готово. Quickshell остановлен, waybar возвращён."
say "Полное удаление (необязательно): rm $HOME/.config/systemd/user/$UNIT_NAME $HOME/.config/quickshell"
