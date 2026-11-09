#!/usr/bin/env bash
# rofi script mode: эмодзи. Список берётся из скрипта end-4; выбор — копия в буфер и вставка в окно.
SRC="$HOME/.config/hypr/hyprland/scripts/fuzzel-emoji.sh"
if [[ -n "${1:-}" ]]; then
    e="${1%% *}"
    printf '%s' "$e" | wl-copy
    setsid -f sh -c "sleep 0.15; wtype '$e'" >/dev/null 2>&1
    exit 0
fi
printf '\0no-custom\x1ftrue\n'
grep -P '^[^\x00-\x7F]' "$SRC"
