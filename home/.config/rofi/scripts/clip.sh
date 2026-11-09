#!/usr/bin/env bash
# rofi script mode: история буфера (cliphist). Выбор — вернуть в буфер.
if [[ -n "${ROFI_INFO:-}" ]]; then
    printf '%s\t\n' "$ROFI_INFO" | cliphist decode | wl-copy
    exit 0
fi
printf '\0no-custom\x1ftrue\n'
cliphist list | while IFS=$'\t' read -r id text; do
    printf '%s\0info\x1f%s\n' "${text//$'\n'/ }" "$id"
done
