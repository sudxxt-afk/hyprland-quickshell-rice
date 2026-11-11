#!/usr/bin/env bash
#
# status.sh — одна строка статуса для hyprlock: батарея · громкость · Wi-Fi.
# Если данных нет — соответствующая часть просто не печатается.
#
set -uo pipefail

parts=()

# ── батарея ───────────────────────────────────────────────────────────
bat=/sys/class/power_supply/BAT0
if [[ -r "$bat/capacity" && -r "$bat/status" ]]; then
    cap=$(<"$bat/capacity")
    st=$(<"$bat/status")
    icon=$'\uf0079'                       # 󰁹
    [[ "$st" == "Charging" ]] && icon=$'\uf0084'   # 󰂄
    parts+=("$icon ${cap}%")
fi

# ── громкость ─────────────────────────────────────────────────────────
if command -v wpctl >/dev/null 2>&1; then
    line=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)
    if [[ -n "$line" ]]; then
        vol=$(awk '{print $2}' <<<"$line")
        pct=$(awk -v v="$vol" 'BEGIN { printf "%d", v * 100 }')
        icon=$'\uf057f'                   # 󰕿
        [[ "$line" == *MUTED* ]] && icon=$'\uf0580'    # 󰖀
        parts+=("$icon ${pct}%")
    fi
fi

# ── Wi-Fi ─────────────────────────────────────────────────────────────
if command -v nmcli >/dev/null 2>&1; then
    ssid=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1 == "yes" { print $2; exit }')
    [[ -n "$ssid" ]] && parts+=("$ssid")
fi

out=""
for p in "${parts[@]}"; do
    out+="${out:+  ·  }$p"
done
[[ -n "$out" ]] && printf '%s\n' "$out"
exit 0
