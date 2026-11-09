#!/usr/bin/env bash
# Выдать root доступ к X :0, чтобы GUI-приложения под sudo могли подключиться
# (иначе Qt падает: could not connect to display :0).
#
# Hyprland ведёт Xwayland по ACL «локальный пользователь», куки XAUTHORITY
# не используются, поэтому root надо просто дописать в список доступа.
# Xwayland может подниматься позже автозапуска — поэтому пробуем с повторами.
set -u

for _ in $(seq 20); do
    if xhost +SI:localuser:root >/dev/null 2>&1; then
        exit 0
    fi
    sleep 0.5
done

# Не смогли — не мешаем сессии, просто ничего не делаем.
exit 1
