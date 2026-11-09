# hyprland-quickshell-rice

Мой слой поверх [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)
(шелл illogical-impulse, «ii») на Fedora + Hyprland 0.57 (Lua-конфиг).

Сам end-4 тут не хранится — только то, что я поменял или добавил.
Старый самописный шелл на Quickshell — в ветке `legacy`.

## Что где

| в репо | в системе | что это |
| --- | --- | --- |
| `home/.config/hypr/custom/*.lua` | `~/.config/hypr/custom/` | мои настройки поверх end-4: ввод, рамки/тени/анимации, бинды, правила, hyprexpo |
| `home/.config/hypr/*.conf`, `lock/`, `scripts/` | `~/.config/hypr/` | hyprlock, hypridle, hyprpaper, свои скрипты |
| `home/.config/matugen/` | `~/.config/matugen/` | шаблоны палитры из обоев |
| `home/.config/kitty/kitty.conf`, `mako/config` | `~/.config/…` | терминал и уведомления |
| `home/.config/quickshell/{cava,chaldea-glyph}` | `~/.config/quickshell/` | десктоп-виджеты |
| `home/.local/bin/` | `~/.local/bin/` | `fedora-slim`, `hyprexpo-rebuild` |
| `ii/config.json` | `~/.config/illogical-impulse/config.json` | настройки ii (копией, не симлинком) |

В репо **нет** файлов, которые генерирует matugen: `kitty/theme.conf`,
`fuzzel/fuzzel_theme.ini`, `hypr/hyprland/colors.lua`, `hypr/hyprlock/colors.conf`,
`gtk-*/gtk.css`, `btop/themes/matugen.theme`, `fastfetch/config.jsonc`,
`starship.toml`. Они пересоздаются из шаблонов при смене обоев — править надо
шаблон в `matugen/templates/`, а не результат.

## Тема

- Палитра: ii, схема `scheme-content` (`ii/config.json` → `appearance.palette.type`).
  `auto` на малонасыщенных обоях уходит в `scheme-neutral`, и всё становится серым.
- Перегенерировать без смены обоев:
  `~/.config/quickshell/ii/scripts/colors/switchwall.sh --noswitch`.
- Курсор `Bibata-Modern-Classic` 24 — в env Hyprland, GTK `settings.ini`,
  gsettings и `~/.icons/default`. Иконки `Papirus` (GTK, gsettings, kdeglobals).

Отдельные репозитории (не здесь): `~/.config/quickshell/chaldea`,
`~/.config/quickshell/music-player`.

## Установка на чистую систему

1. Поставить end-4 по его инструкции (установлен 2026-10-19).
2. `./rice link` — симлинки из `home/` в `$HOME`. Всё, что было на этих местах,
   уезжает в `~/.local/state/rice-backup/<дата>/`.
3. `./rice restore` — вернуть настройки ii.
4. `hyprexpo-rebuild` — собрать плагин под текущую версию Hyprland.

## Повседневно

- Правки в `~/.config/hypr/custom/…` и прочем из таблицы сразу попадают в репо
  (это симлинки) — остаётся `git commit`.
- Поменял настройки в GUI ii → `./rice snapshot`, потом коммит.
- `./rice status` — показать, что не связано или разошлось.
- Hyprland может не заметить правку через симлинк — тогда `hyprctl reload`.

## Обновление end-4

end-4 не трогает `hypr/custom/`, но может перезаписать `hypridle.conf` и
`hyprlock.conf`. После обновления — `./rice status` и `git diff`: если файл стал
обычным, `./rice link` вернёт симлинк, а diff покажет, что принёс апстрим.
