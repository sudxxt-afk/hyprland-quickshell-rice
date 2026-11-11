#!/usr/bin/env bash
# Печатает «Caps Lock», если он включён; иначе ничего. Для hyprlock.
set -uo pipefail
for f in /sys/class/leds/*capslock*/brightness; do
    [[ -r "$f" ]] || continue
    if [[ "$(<"$f")" == "1" ]]; then
        printf 'Caps Lock'
        exit 0
    fi
done
exit 0
