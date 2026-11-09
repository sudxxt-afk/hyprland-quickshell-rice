#!/usr/bin/env bash
# rofi script mode: питание и сессия.
case "${ROFI_INFO:-}" in
    lock)     setsid -f loginctl lock-session; exit 0 ;;
    suspend)  setsid -f systemctl suspend; exit 0 ;;
    logout)   setsid -f hyprctl dispatch 'hl.dsp.exit()'; exit 0 ;;
    reboot)   setsid -f systemctl reboot; exit 0 ;;
    poweroff) setsid -f systemctl poweroff; exit 0 ;;
esac
printf '\0no-custom\x1ftrue\n'
printf 'Заблокировать\0icon\x1fsystem-lock-screen\x1finfo\x1flock\n'
printf 'Сон\0icon\x1fsystem-suspend\x1finfo\x1fsuspend\n'
printf 'Выйти из Hyprland\0icon\x1fsystem-log-out\x1finfo\x1flogout\n'
printf 'Перезагрузить\0icon\x1fsystem-reboot\x1finfo\x1freboot\n'
printf 'Выключить\0icon\x1fsystem-shutdown\x1finfo\x1fpoweroff\n'
