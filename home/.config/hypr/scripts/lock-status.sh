#!/usr/bin/env bash
# lock-status.sh — динамика для hyprlock (glass card).
# Использование: lock-status.sh {greeting|battery|track|layout}
# Печатает одну короткую строку; если данных нет — ничего (метка прячется).

set -uo pipefail

case "${1:-}" in

  # ── приветствие по времени суток ──────────────────────────────────
  greeting)
    h=$((10#$(date +%H)))
    if   (( h < 5 ));  then echo "Доброй ночи"
    elif (( h < 12 )); then echo "Доброе утро"
    elif (( h < 18 )); then echo "Добрый день"
    else                    echo "Добрый вечер"
    fi
    ;;

  # ── батарея: иконка + процент ─────────────────────────────────────
  battery)
    bat="/sys/class/power_supply/BAT0"
    [[ -r "$bat/capacity" && -r "$bat/status" ]] || exit 0
    cap=$(<"$bat/capacity")
    st=$(<"$bat/status")
    case "$st" in
      Charging)    icon=$'\uf0084' ;;   # 󰂄  зарядка
      *)           icon=$'\uf0079' ;;   # 󰁹  разряд / полный
    esac
    printf '%s %s%%\n' "$icon" "$cap"
    ;;

  # ── сейчас играет (обрезаем) ──────────────────────────────────────
  track)
    command -v playerctl >/dev/null 2>&1 || exit 0
    artist=$(playerctl metadata artist 2>/dev/null) || artist=""
    title=$(playerctl metadata title  2>/dev/null) || title=""
    # прячем пустого/неизвестного артиста
    case "$artist" in ""|"<unknown>"|Unknown) artist="" ;; esac
    if [[ -n "$artist" && -n "$title" ]]; then
      raw="$artist — $title"
    else
      raw="$title"
    fi
    [[ -n "$raw" ]] || exit 0
    printf '%s %s\n' $'\uf0388' "$(printf '%s' "$raw" | cut -c1-22)"
    ;;

  # ── раскладка клавиатуры ──────────────────────────────────────────
  layout)
    command -v hyprctl >/dev/null 2>&1 || exit 0
    key=$(hyprctl -j devices 2>/dev/null \
          | jq -r 'first(.keyboards[] | select(.main == true) | .active_keymap) // empty' 2>/dev/null)
    [[ -n "$key" ]] || exit 0
    case "$key" in
      *Russian*|*russian*)       code=RU ;;
      *English*|*english*|*"US"*) code=EN ;;
      *)                          code=${key:0:2} ;;
    esac
    printf '%s %s\n' $'\uf030c' "$(printf '%s' "$code" | tr '[:lower:]' '[:upper:]')"
    ;;

esac
