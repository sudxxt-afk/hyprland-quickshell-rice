#!/usr/bin/env bash
# rofi script mode: калькулятор на qalc. Ввести выражение → Enter; Enter на результате — копировать.
if [[ "${ROFI_INFO:-}" == copy:* ]]; then
    printf '%s' "${ROFI_INFO#copy:}" | wl-copy
    exit 0
fi
printf '\0no-custom\x1ffalse\n'
if [[ -n "${1:-}" ]]; then
    res="$(qalc -t -- "$1" 2>/dev/null | tail -n 1)"
    printf '\0message\x1f%s = <b>%s</b>\n' "$1" "$res"
    printf '%s\0icon\x1faccessories-calculator\x1finfo\x1fcopy:%s\n' "$res" "$res"
else
    printf '\0message\x1fВыражение, единицы, валюты: <i>2^10</i>, <i>5 km to mi</i>, <i>100 usd to rub</i>\n'
fi
