#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
#  check.sh — сторож палитры
#
#  Ловит две вещи:
#   1. конфиги разъехались с theme/palette.toml (рендерер не прогнан);
#   2. в конфигах появился цвет вне палитры или след чужой темы.
#
#  Запуск:  ./theme/check.sh              # проверить все конфиги риса
#           ./theme/check.sh путь …       # проверить указанные файлы/папки
#  Код возврата: 0 — чисто, 1 — есть находки.
# ═══════════════════════════════════════════════════════════════════════
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Чужие темы, которые уже наследили в этом конфиге: их ищем по имени,
# чтобы сообщение было понятнее, чем «посторонний цвет».
FOREIGN_THEMES='tokyo ?night|tokyonight|7aa2f7|bb9af7|1a1b26|24283b|1f2335|394b70|565f89|414868|c0caf5|e0af68|f7768e'

DEFAULT_PATHS=(
  "$HOME/.config/kitty"
  "$HOME/.config/wofi/style.css"
  "$HOME/.config/btop"
  "$HOME/.config/cava/config"
  "$HOME/.config/starship.toml"
  "$HOME/.config/fastfetch"
  "$HOME/.config/gtk-3.0/settings.ini"
  "$HOME/.config/gtk-4.0/settings.ini"
  "$HOME/.config/wayle/config.toml"
  "$HOME/.config/hypr/hyprland.lua"
  "$HOME/.config/hypr/hyprlock.conf"
  "$ROOT/quickshell/widgets"
  "$ROOT/theme/templates"
)

status=0

# ── 1. Конфиги против палитры ────────────────────────────────────────
if ! python3 "$ROOT/theme/render.py" --check; then
  status=1
fi

# Разрешённые цвета — из самой палитры, без решётки.
ALLOWED="$(python3 - "$ROOT" <<'PY'
import pathlib, sys
sys.path.insert(0, sys.argv[1])
from theme import render
print("\n".join(c.lstrip("#").lower() for c in render.load_palette().colors.values()))
PY
)"

paths=("$@")
if [ ${#paths[@]} -eq 0 ]; then
  paths=("${DEFAULT_PATHS[@]}")
fi

files=()
for path in "${paths[@]}"; do
  if [ -d "$path" ]; then
    while IFS= read -r found; do files+=("$found"); done < <(find "$path" -type f ! -name '*.bak-*' ! -name '*.render-tmp')
  elif [ -f "$path" ]; then
    files+=("$path")
  fi
done

for file in "${files[@]}"; do
  # Посторонний цвет: hex вне палитры. У восьмизначных #aarrggbb
  # значение цвета — последние шесть цифр.
  while IFS= read -r hex; do
    color="${hex: -6}"
    if ! grep -qix -- "$color" <<<"$ALLOWED"; then
      echo "$file: посторонний цвет $hex — нет в theme/palette.toml"
      status=1
    fi
  done < <(grep -ohIE '#[0-9a-fA-F]{6,8}' "$file" 2>/dev/null | sort -u)

  # След чужой темы
  if match="$(grep -inIE "$FOREIGN_THEMES" "$file" 2>/dev/null | head -1)"; then
    echo "$file: след чужой темы — $match"
    status=1
  fi
done

if [ "$status" -eq 0 ]; then
  echo "палитра чиста: посторонних цветов нет"
fi

exit "$status"
