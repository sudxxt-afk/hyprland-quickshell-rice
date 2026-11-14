# hyprland-quickshell-rice

Мой слой поверх [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)
(шелл illogical-impulse, «ii») на Fedora + Hyprland 0.57 (Lua-конфиг).

Сам end-4 тут не хранится — только то, что я поменял или добавил.

## Что где

| в репо | в системе | что это |
| --- | --- | --- |
| `home/.config/hypr/custom/*.lua` | `~/.config/hypr/custom/` | мои настройки поверх end-4: ввод, рамки/тени/анимации, бинды, правила, hyprexpo |
| `home/.config/hypr/*.conf`, `hyprlock/`, `scripts/` | `~/.config/hypr/` | hyprlock (и его скрипты), hypridle, свои скрипты |
| `home/.config/matugen/` | `~/.config/matugen/` | шаблоны палитры из обоев |
| `home/.config/kitty/kitty.conf`, `mako/config` | `~/.config/…` | терминал и запасные уведомления |
| `home/.config/quickshell/{cava,chaldea-glyph}` | `~/.config/quickshell/` | десктоп-виджеты |
| `home/.local/bin/` | `~/.local/bin/` | `rice-*` (`launcher`, `cava`, `cava-watch`, `gamemode`, `telegram-theme`), `fedora-slim`, `greetd-setup`, `hyprexpo-rebuild` |
| `ii/config.json` | `~/.config/illogical-impulse/config.json` | настройки ii (копией, не симлинком) |

В репо **нет** файлов, которые генерирует matugen: `kitty/theme.conf`,
`fuzzel/fuzzel_theme.ini`, `hypr/hyprland/colors.lua`, `hypr/hyprlock/colors.conf`,
`mako/colors.conf`, `gtk-*/gtk.css`, `btop/themes/matugen.theme`, `fastfetch/config.jsonc`,
`starship.toml`, тема VS Code. Они пересоздаются из шаблонов при смене обоев — править надо
шаблон в `matugen/templates/`, а не результат.

## Тема

- Палитра: ii, схема `scheme-monochrome` — серо-белая, без оттенка от обоев
  (`ii/config.json` → `appearance.palette.type`). Цветные варианты:
  `scheme-content` (оттенок обоев), `scheme-fidelity` (контрастнее).
- Рамка окна: градиент `primary` → `outline` (в монохроме белый → серый), снаружи
  плотное тёмное кольцо (тень range 4, offset 0) — «двойная рамка» как в lilith.
- Перегенерировать без смены обоев:
  `~/.config/quickshell/ii/scripts/colors/switchwall.sh --noswitch`.
- Курсор `Bibata-Modern-Classic` 24 — в env Hyprland, GTK `settings.ini`,
  gsettings и `~/.icons/default`. Иконки `Papirus` (GTK, gsettings, kdeglobals).

## Визуал и хоткеи

| хоткей | что |
| --- | --- |
| `Super + `` ` `` | обзор рабочих столов (hyprexpo) |
| `Super + Z` | выпадающий терминал (scratchpad) |
| `Super + Alt + S` | выпадающий btop (свой special-воркспейс) |
| `Super + Alt + T` | выбор обоев с превью (селектор ii; палитра пересчитывается сама) |
| `Super + Alt + C` | cava-виджет на столе: вкл/выкл |
| `Super + Shift + G` | игровой режим: анимации, блюр и тени выкл/вкл |
| `Alt + Tab` | к предыдущему окну (через столы), повторно — обратно |
| `Alt + `` ` `` | список окон (rofi) |
| одиночный `Super` | ничего (поиск/обзор ii отключён; лаунчер — `Super + Space`) |
| щипок 4 пальцами | обзор рабочих столов (hyprexpo) |

- end-4 выключает блюр у всех окон; в `custom/rules.lua` он возвращён только
  полупрозрачным: терминалы всегда, редакторы и Nautilus — когда не в фокусе.
- Одно окно на столе — без отступов, рамки и скругления; два и больше — как обычно.
- Выпадающий терминал запускается при первом нажатии и дальше только прячется/показывается.
- Ночной режим — в ii (`light.night`: авто с 19:00 до 06:30, 5000K).

### Память

- cava-виджет (`qs -c cava`) запускается только когда играет музыка:
  `rice-cava-watch` опрашивает MPRIS раз в 2 с, на паузе гасит виджет через 10 с.
  Ручное управление — `rice cava on|off|auto|status` (или `Super+Alt+C`).
- chaldea-glyph и music-player по умолчанию выключены (~160 и ~180 МБ).
  Тумблер — `rice widget glyph|music on|off|status`; он правит строки между
  маркерами `rice:widgets` в `custom/execs.lua`, так что состояние видно в `git diff`.
- Игровой режим — `rice-gamemode` или `Super+Shift+G`: анимации, блюр и тени
  выключаются на лету; повторное нажатие делает `hyprctl reload` и возвращает всё.

### Проверка

`./rice doctor` — симлинки, `hyprctl configerrors`, версия hyprexpo, сгенерированные
файлы matugen и зависимости. Систему не меняет; код возврата 1, если есть FAIL.

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
- `./rice doctor` — полная проверка (связи, Hyprland, matugen, зависимости).
- `./rice widget glyph|music on|off` — десктоп-виджеты; `./rice cava on|off|auto` — cava.
- Hyprland может не заметить правку через симлинк — тогда `hyprctl reload`.

## Обновление end-4

end-4 не трогает `hypr/custom/`, но может перезаписать `hypridle.conf` и
`hyprlock.conf`. После обновления — `./rice status` и `git diff`: если файл стал
обычным, `./rice link` вернёт симлинк, а diff покажет, что принёс апстрим.

## Вход и блокировка

- Блокировка — локскрин ii (`quickshell:lock`), в цветах палитры. hyprlock —
  запасной, если quickshell упал; его цвета тоже из matugen.
- Экран входа: `greetd-setup` меняет gdm на greetd + tuigreet (монохромная тема,
  Terminus 22 в консоли, gnome-keyring разблокируется при входе). Запускать
  **после** перезагрузки в Fedora 45, не раньше. F3 в tuigreet — выбор сессии.
- Не входит после перезагрузки: `Ctrl+Alt+F3` → логин в консоли →
  `sudo greetd-setup --rollback && sudo reboot`.

## VS Code

Тема «Rice Matugen» — серо-белый интерфейс из палитры, синтаксис в тех же
фиксированных цветах, что терминал. Шаблон: `matugen/templates/vscode/`, основан
на dux-shell (MIT, см. `third_party/dux-shell.LICENSE`).

- Поставить/переставить расширение: `./rice vscode`.
- После смены обоев новые цвета видны после `Developer: Reload Window`.

## Telegram

matugen пишет роли палитры в `~/.local/state/rice/telegram-palette.json`, его
post_hook `rice-telegram-theme` собирает `~/.local/share/rice/rice.tdesktop-theme`.
Ключи Telegram — из walogram (MIT, `third_party/walogram.LICENSE`).

Применить (и заново после каждой смены палитры — Telegram хранит копию, а не
ссылку на файл): Настройки → Настройки чатов → ⋮ → «Выбрать из файла» →
`~/.local/share/rice/rice.tdesktop-theme` → «Применить».
Через командную строку Telegram 7 файл темы не открывает — ни запущенный, ни при старте.

## Обои

Лежат в `~/Pictures/Wallpapers`. Селектор ii открывает `<папка картинок>/Wallpapers`,
а при русской локали это `~/Изображения/Wallpapers` — там симлинк на `~/Pictures/Wallpapers`.
Новые обои просто кидать туда; превью ii генерирует сам при открытии папки.

## Лаунчер (rofi)

| хоткей | режим |
| --- | --- |
| `Super + Space` | приложения; повторное нажатие закрывает |
| `Super + R` | запуск команды |
| `Super + V` | история буфера (cliphist) |

Внутри `Tab` / `Shift + Tab` переключают режимы: apps · run · windows · files ·
calc · emoji · clip · power. Строки — стрелками.

- **calc** — `qalc`: выражения, единицы, валюты (`100 usd to rub`); Enter на результате копирует.
- **emoji** — список из end-4; выбор копирует и сразу вставляет в окно.
- **power** — блокировка, сон, выход, перезагрузка, выключение.

Тема `rofi/rice.rasi` (стекло, скругления как у окон), цвета `rofi/colors.rasi` генерирует
matugen. Скрипты режимов — `rofi/scripts/`. Из терминала: `rice-launcher <режим>`.
